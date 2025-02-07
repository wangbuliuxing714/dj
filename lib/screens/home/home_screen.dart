import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/controllers/novel_controller.dart';
import 'package:novel_app/models/novel.dart';
import 'package:novel_app/models/genre_category.dart';
import 'package:novel_app/screens/novel_detail_screen.dart';
import 'package:novel_app/screens/settings_screen.dart';
import 'package:novel_app/screens/prompt_management_screen.dart';
import 'package:novel_app/screens/help_screen.dart';
import 'package:novel_app/controllers/theme_controller.dart';
import 'package:novel_app/screens/genre_manager_screen.dart';
import 'package:novel_app/controllers/genre_controller.dart';
import 'package:novel_app/screens/module_repository_screen.dart';
import 'package:novel_app/controllers/style_controller.dart';
import 'package:novel_app/controllers/character_card_controller.dart';
import 'package:novel_app/models/character_card.dart';
import 'package:novel_app/screens/character_card_edit_screen.dart';

class HomeScreen extends GetView<NovelController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final characterController = Get.find<CharacterCardController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI小说生成器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.apps),
            tooltip: '模块仓库',
            onPressed: () => Get.to(() => const ModuleRepositoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Get.to(() => const HelpScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'AI小说生成器',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('帮助'),
              onTap: () {
                Get.back();
                Get.to(() => const HelpScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('草稿本'),
              onTap: () {
                Get.back();
                Get.toNamed('/draft');
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '阅读设置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Obx(() => Switch(
                        value: themeController.isEyeProtectionMode,
                        onChanged: (_) => themeController.toggleTheme(),
                      )),
                      const Text('护眼模式'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('背景颜色'),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        for (final color in themeController.presetColors)
                          Expanded(
                            child: Obx(() {
                              final isSelected = themeController.backgroundColor.value == color;
                              return Stack(
                                children: [
                                  InkWell(
                                    onTap: () => themeController.setBackgroundColor(color),
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(
                                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('色温调节'),
                      Obx(() => Text(
                        '${themeController.colorTemperature.round()}K',
                        style: const TextStyle(color: Colors.grey),
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                    children: [
                      Slider(
                        value: themeController.colorTemperature,
                        min: 2000,
                        max: 10000,
                        divisions: 80,
                        label: '${themeController.colorTemperature.round()}K',
                        onChanged: (value) => themeController.setColorTemperature(value),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('暖色', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const Text('标准', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const Text('冷色', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: themeController.getAdjustedBackgroundColor(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGeneratorForm(),
                const SizedBox(height: 20),
                _buildGenerationStatus(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: _buildNovelList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorForm() {
    final characterController = Get.find<CharacterCardController>();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '小说标题',
                hintText: '请输入小说标题',
              ),
              onChanged: controller.updateTitle,
            ),
            const SizedBox(height: 16),
            _buildGenreSelector(),
            const SizedBox(height: 16),
            _buildCharacterSection(controller, characterController),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '创作要求',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '故事背景',
                        hintText: '例如：大学校园，现代都市',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: controller.updateBackground,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '其他要求',
                        hintText: '其他具体要求，如情节发展、特殊设定等',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: controller.updateOtherRequirements,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GetX<NovelController>(
              builder: (controller) => DropdownButtonFormField<String>(
                value: controller.style.value,
                decoration: const InputDecoration(
                  labelText: '写作风格',
                ),
                items: Get.find<StyleController>().styles
                    .map((style) => DropdownMenuItem(
                          value: style.name,
                          child: Text(style.name),
                        ))
                    .toList(),
                onChanged: (value) => controller.updateStyle(value!),
              ),
            ),
            const SizedBox(height: 16),
            GetX<NovelController>(
              builder: (controller) => Row(
                children: [
                  const Text('章节数量：', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: controller.totalChapters.value.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: controller.totalChapters.value.toString(),
                      onChanged: (value) =>
                          controller.updateTotalChapters(value.toInt()),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${controller.totalChapters.value}章',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (controller.isGenerating.value) {
                      controller.stopGeneration();
                    } else {
                      controller.startGeneration();
                    }
                  },
                  child: Obx(() => Text(
                    controller.isGenerating.value ? '停止生成' : '开始生成',
                  )),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) => ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/storage'),
                    icon: const Icon(Icons.storage),
                    label: const Text('已生成章节'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSection(NovelController controller, CharacterCardController characterController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色设定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // 主角选择
        Obx(() => _buildCharacterSelector(
          label: '主角',
          selectedCharacter: controller.selectedMainCharacter.value,
          onTap: () => _showCharacterSelectDialog(
            title: '选择主角',
            onSelect: controller.setMainCharacter,
            currentSelected: controller.selectedMainCharacter.value,
          ),
        )),
        const SizedBox(height: 16),
        
        // 女主角选择
        Obx(() => _buildCharacterSelector(
          label: '女主角',
          selectedCharacter: controller.selectedFemaleCharacter.value,
          onTap: () => _showCharacterSelectDialog(
            title: '选择女主角',
            onSelect: controller.setFemaleCharacter,
            currentSelected: controller.selectedFemaleCharacter.value,
          ),
        )),
        const SizedBox(height: 16),
        
        // 配角选择
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('配角', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCharacterSelectDialog(
                    title: '添加配角',
                    onSelect: controller.addSupportingCharacter,
                    currentSelected: null,
                    allowMultiple: true,
                  ),
                ),
              ],
            ),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.selectedSupportingCharacters
                  .map((character) => Chip(
                    label: Text(character.name),
                    onDeleted: () => controller.removeSupportingCharacter(character),
                  ))
                  .toList(),
            )),
          ],
        ),
        const SizedBox(height: 16),
        
        // 反派选择
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('反派', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCharacterSelectDialog(
                    title: '添加反派',
                    onSelect: controller.addVillain,
                    currentSelected: null,
                    allowMultiple: true,
                  ),
                ),
              ],
            ),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.selectedVillains
                  .map((character) => Chip(
                    label: Text(character.name),
                    onDeleted: () => controller.removeVillain(character),
                  ))
                  .toList(),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterSelector({
    required String label,
    required CharacterCard? selectedCharacter,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCharacter?.name ?? '点击选择角色',
                    style: TextStyle(
                      color: selectedCharacter == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCharacterSelectDialog({
    required String title,
    required Function(CharacterCard) onSelect,
    CharacterCard? currentSelected,
    bool allowMultiple = false,
  }) async {
    final characterController = Get.find<CharacterCardController>();
    final characters = characterController.cards;
    
    if (characters.isEmpty) {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('没有角色卡片'),
          content: const Text('是否创建新的角色卡片？'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('创建'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        final newCharacter = await Get.to<CharacterCard?>(() => CharacterCardEditScreen());
        if (newCharacter != null) {
          onSelect(newCharacter);
        }
      }
      return;
    }

    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: characters.length + 1,
            itemBuilder: (context, index) {
              if (index == characters.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('创建新角色'),
                  onTap: () async {
                    Get.back();
                    final newCharacter = await Get.to<CharacterCard?>(() => CharacterCardEditScreen());
                    if (newCharacter != null) {
                      onSelect(newCharacter);
                    }
                  },
                );
              }
              
              final character = characters[index];
              return ListTile(
                title: Text(character.name),
                subtitle: Text(
                  [
                    if (character.gender != null) character.gender,
                    if (character.age != null) '${character.age}岁',
                    if (character.personality != null) character.personality,
                  ].join('，'),
                ),
                selected: currentSelected == character,
                onTap: () {
                  if (!allowMultiple) {
                    Get.back();
                  }
                  onSelect(character);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelector() {
    final genreController = Get.find<GenreController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择类型（最多5个）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
          children: genreController.categories.map((category) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.genres.map((genre) => Obx(() => FilterChip(
                  label: Text(genre.name),
                  selected: controller.selectedGenres.contains(genre.name),
                  onSelected: (_) => controller.toggleGenre(genre.name),
                ))).toList(),
              ),
              const SizedBox(height: 8),
            ],
          )).toList(),
        )),
        Obx(() => controller.selectedGenres.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '已选类型',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.selectedGenres.map((genre) => Chip(
                    label: Text(genre),
                    onDeleted: () => controller.toggleGenre(genre),
                  )).toList(),
                ),
              ],
            )
          : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildGenerationStatus() {
    return GetX<NovelController>(
      builder: (controller) {
        if (!controller.isGenerating.value) {
          return const SizedBox();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生成进度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.generationProgress.value,
                ),
                const SizedBox(height: 8),
                Text(controller.generationStatus.value),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNovelList() {
    return GetX<NovelController>(
      builder: (controller) {
        if (controller.novels.isEmpty) {
          return const Center(
            child: Text('还没有生成任何小说'),
          );
        }
        return ListView.builder(
          itemCount: controller.novels.length,
          itemBuilder: (context, index) {
            final novel = controller.novels[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(novel.title),
                subtitle: Text('${novel.genre} · ${novel.createTime}'),
                trailing: Text('${novel.wordCount}字'),
                onTap: () => Get.to(() => NovelDetailScreen(novel: novel)),
              ),
            );
          },
        );
      },
    );
  }
} 