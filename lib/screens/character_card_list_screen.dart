import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/character_card.dart';
import 'package:novel_app/controllers/character_card_controller.dart';
import 'package:novel_app/screens/character_card_edit_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class CharacterCardListScreen extends StatelessWidget {
  const CharacterCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CharacterCardController>();
    final selectedCards = <String>[].obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('角色卡片管理'),
        actions: [
          // 导入按钮
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导入角色卡片',
            onPressed: () async {
              try {
                final count = await controller.importCardsFromFile();
                if (count > 0) {
                  Get.snackbar(
                    '导入成功',
                    '成功导入 $count 个角色卡片',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  '导入失败',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
          // 导出按钮
          PopupMenuButton<String>(
            tooltip: '导出角色卡片',
            icon: const Icon(Icons.file_download),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('导出全部角色'),
              ),
              if (selectedCards.isNotEmpty)
                const PopupMenuItem(
                  value: 'selected',
                  child: Text('导出选中角色'),
                ),
            ],
            onSelected: (value) async {
              try {
                String jsonContent;
                if (value == 'all') {
                  jsonContent = await controller.exportAllCards();
                } else {
                  jsonContent = await controller.exportSelectedCards(selectedCards);
                }

                if (kIsWeb) {
                  // Web平台使用下载
                  final blob = html.Blob([jsonContent], 'application/json');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute('download', 'character_cards_${DateTime.now().millisecondsSinceEpoch}.json')
                    ..click();
                  html.Url.revokeObjectUrl(url);
                } else {
                  // 移动平台显示文件路径
                  Get.snackbar(
                    '导出成功',
                    '文件已保存到: $jsonContent',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  '导出失败',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final cards = controller.cards;
        if (cards.isEmpty) {
          return const Center(
            child: Text('还没有创建任何角色卡片'),
          );
        }
        return ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: selectedCards.contains(card.id),
                  onChanged: (checked) {
                    if (checked == true) {
                      selectedCards.add(card.id);
                    } else {
                      selectedCards.remove(card.id);
                    }
                  },
                ),
                title: Text(card.name),
                subtitle: Text(
                  [
                    if (card.gender != null) card.gender,
                    if (card.age != null) '${card.age}岁',
                    if (card.personality != null) card.personality,
                  ].join('，'),
                ),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Get.to(() => CharacterCardEditScreen(cardId: card.id));
                    } else if (value == 'delete') {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('确定要删除角色"${card.name}"吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        controller.deleteCard(card.id);
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CharacterCardEditScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
} 