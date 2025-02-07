import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/character_card.dart';
import 'package:novel_app/controllers/character_card_controller.dart';
import 'package:novel_app/screens/character_card_edit_screen.dart';

class CharacterCardListScreen extends StatelessWidget {
  final _controller = Get.find<CharacterCardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('角色卡片'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Get.to(() => CharacterCardEditScreen()),
          ),
        ],
      ),
      body: Obx(
        () => _controller.cards.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '还没有角色卡片',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('创建角色卡片'),
                      onPressed: () => Get.to(() => CharacterCardEditScreen()),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _controller.cards.length,
                itemBuilder: (context, index) {
                  final card = _controller.cards[index];
                  return _buildCharacterCard(card);
                },
              ),
      ),
    );
  }

  Widget _buildCharacterCard(CharacterCard card) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.to(() => CharacterCardEditScreen(cardId: card.id)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Get.to(() => CharacterCardEditScreen(cardId: card.id)),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(card),
                  ),
                ],
              ),
              if (card.gender != null || card.age != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    [
                      if (card.gender != null) card.gender,
                      if (card.age != null) '${card.age}岁',
                    ].join(' · '),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              if (card.species != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    card.species!,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              if (card.personality != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '性格: ${card.personality}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              if (card.shortTermGoals != null || card.longTermGoals != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '目标: ${card.shortTermGoals ?? card.longTermGoals}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(CharacterCard card) {
    Get.dialog(
      AlertDialog(
        title: Text('删除角色卡片'),
        content: Text('确定要删除角色"${card.name}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              _controller.deleteCard(card.id);
              Get.back();
            },
          ),
        ],
      ),
    );
  }
} 