import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/novel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:novel_app/services/content_review_service.dart';
import 'package:novel_app/controllers/api_config_controller.dart';
import 'package:novel_app/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NovelDetailScreen extends GetView<NovelDetailController> {
  final Novel novel;

  NovelDetailScreen({
    Key? key,
    required this.novel,
  }) : super(key: key) {
    Get.put(NovelDetailController(novel));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(novel.title),
        actions: [
          Obx(() {
            final isGenerating = controller.isGenerating.value;
            final isPaused = controller.isPaused.value;
            
            if (!isGenerating) return const SizedBox.shrink();
            
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isPaused ? '已暂停' : '生成中',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  tooltip: isPaused ? '继续生成' : '暂停生成',
                  onPressed: () {
                    if (isPaused) {
                      controller.resumeGeneration();
                    } else {
                      controller.pauseGeneration();
                    }
                  },
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _buildInfoSection(),
          const Divider(),
          _buildProgressSection(),
          Expanded(
            child: _buildChapterList(),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final hasSelectedChapters = controller.selectedChapters.isNotEmpty;
        final isGenerating = controller.isGenerating.value;
        
        if (isGenerating) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: hasSelectedChapters ? () => controller.showReviewDialog() : null,
          label: const Text('润色选中章节'),
          icon: const Icon(Icons.auto_fix_high),
        );
      }),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('标题：${novel.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('类型：${novel.genre}'),
          const SizedBox(height: 8),
          Text('创建时间：${DateFormat('yyyy-MM-dd HH:mm').format(novel.createdAt)}'),
          const SizedBox(height: 8),
          Text('章节数：${novel.chapters.length}'),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Obx(() {
      if (!controller.isGenerating.value) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('正在处理: 第${controller.currentProcessingChapter.value + 1}章'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: controller.currentProcessingChapter.value / 
                     controller.selectedChapters.length,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChapterList() {
    return ListView.builder(
      itemCount: novel.chapters.length,
      itemBuilder: (context, index) {
        final chapter = novel.chapters[index];
        return ListTile(
          title: Text('第${chapter.number}章：${chapter.title}'),
          selected: controller.selectedChapters.contains(index),
          leading: Obx(() => Checkbox(
            value: controller.selectedChapters.contains(index),
            onChanged: (bool? value) {
              if (value == true) {
                controller.selectedChapters.add(index);
              } else {
                controller.selectedChapters.remove(index);
              }
            },
          )),
          onTap: () => Get.to(() => ChapterDetailScreen(chapter: chapter)),
        );
      },
    );
  }
}

class NovelDetailController extends GetxController {
  final Novel novel;
  final RxList<int> selectedChapters = <int>[].obs;
  final RxBool isReviewing = false.obs;
  final RxBool isGenerating = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt currentProcessingChapter = 0.obs;
  final reviewRequirementsController = TextEditingController();
  final _contentReviewService = Get.find<ContentReviewService>();

  NovelDetailController(this.novel);

  @override
  void onInit() {
    super.onInit();
    checkForUnfinishedTask();
  }

  @override
  void onClose() {
    reviewRequirementsController.dispose();
    super.onClose();
  }

  Future<void> checkForUnfinishedTask() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTask = prefs.getString('unfinished_task_${novel.id}');
    
    if (savedTask != null) {
      final taskData = json.decode(savedTask);
      selectedChapters.value = List<int>.from(taskData['selected_chapters']);
      currentProcessingChapter.value = taskData['current_chapter'];
      
      if (selectedChapters.isNotEmpty) {
        Get.dialog(
          AlertDialog(
            title: const Text('发现未完成的任务'),
            content: const Text('是否继续上次未完成的润色任务？'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  clearUnfinishedTask();
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  resumeUnfinishedTask(taskData['requirements']);
                },
                child: const Text('继续'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> clearUnfinishedTask() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unfinished_task_${novel.id}');
    selectedChapters.clear();
    currentProcessingChapter.value = 0;
    isPaused.value = false;
    isGenerating.value = false;
  }

  Future<void> saveCurrentProgress() async {
    if (!isGenerating.value) return;
    
    final prefs = await SharedPreferences.getInstance();
    final taskData = {
      'selected_chapters': selectedChapters.toList(),
      'current_chapter': currentProcessingChapter.value,
      'requirements': reviewRequirementsController.text,
    };
    await prefs.setString('unfinished_task_${novel.id}', json.encode(taskData));
  }

  void pauseGeneration() {
    isPaused.value = true;
    saveCurrentProgress();
  }

  void resumeGeneration() {
    isPaused.value = false;
    continueGeneration();
  }

  Future<void> resumeUnfinishedTask(String requirements) async {
    reviewRequirementsController.text = requirements;
    isGenerating.value = true;
    await continueGeneration();
  }

  Future<void> continueGeneration() async {
    if (!isGenerating.value) return;

    try {
      for (int i = currentProcessingChapter.value; i < selectedChapters.length; i++) {
        if (isPaused.value) {
          await saveCurrentProgress();
          return;
        }

        currentProcessingChapter.value = i;
        final chapterIndex = selectedChapters[i];
        final chapter = novel.chapters[chapterIndex];
        
        final reviewedContent = await _contentReviewService.reviewContent(
          content: chapter.content,
          style: '与原文风格一致',
          model: Get.find<ApiConfigController>().selectedModel.value,
        );

        novel.chapters[chapterIndex] = chapter.copyWith(content: reviewedContent);
        await saveCurrentProgress();
      }

      Get.snackbar('成功', '章节润色完成');
      await clearUnfinishedTask();
    } catch (e) {
      Get.snackbar('错误', '章节润色失败：$e');
      isPaused.value = true;
      await saveCurrentProgress();
    }
  }

  Future<void> reviewSelectedChapters() async {
    try {
      isGenerating.value = true;
      isPaused.value = false;
      currentProcessingChapter.value = 0;
      Get.back(); // 关闭对话框

      await continueGeneration();
    } catch (e) {
      Get.snackbar('错误', '章节润色失败：$e');
    }
  }

  void showReviewDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('章节润色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text('已选择 ${selectedChapters.length} 个章节')),
            const SizedBox(height: 16),
            TextField(
              controller: reviewRequirementsController,
              decoration: const InputDecoration(
                labelText: '润色要求（可选）',
                hintText: '请输入具体的润色要求...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: reviewSelectedChapters,
            child: const Text('开始润色'),
          ),
        ],
      ),
    );
  }

  bool _areChaptersConsecutive() {
    if (selectedChapters.isEmpty) return false;
    selectedChapters.sort();
    for (int i = 1; i < selectedChapters.length; i++) {
      if (selectedChapters[i] != selectedChapters[i - 1] + 1) {
        return false;
      }
    }
    return true;
  }

  String _generateChapterSummary(String content) {
    final sentences = content.split('。');
    if (sentences.length <= 3) return content;
    return sentences.take(3).join('。') + '。';
  }
}

class ChapterDetailScreen extends StatelessWidget {
  final Chapter chapter;

  const ChapterDetailScreen({
    Key? key,
    required this.chapter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第${chapter.number}章：${chapter.title}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          chapter.content,
          style: const TextStyle(fontSize: 16.0, height: 1.6),
        ),
      ),
    );
  }
} 