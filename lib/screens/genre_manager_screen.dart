import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/genre_category.dart';
import 'package:novel_app/controllers/genre_controller.dart';

class GenreManagerScreen extends StatelessWidget {
  final genreController = Get.find<GenreController>();

  GenreManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('类型管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: Obx(() => ListView.builder(
        itemCount: genreController.categories.length,
        itemBuilder: (context, index) {
          final category = genreController.categories[index];
          return _buildCategoryCard(context, category, index);
        },
      )),
    );
  }

  Widget _buildCategoryCard(BuildContext context, GenreCategory category, int categoryIndex) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text(category.name)),
            if (!genreController.isDefaultCategory(category.name))
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => genreController.deleteCategory(categoryIndex),
              ),
          ],
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category.genres.length,
            itemBuilder: (context, index) {
              final genre = category.genres[index];
              return ListTile(
                title: Text(genre.name),
                subtitle: Text(genre.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditGenreDialog(context, genre, categoryIndex, index),
                    ),
                    if (!genreController.isDefaultGenre(category.name, genre.name))
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => genreController.deleteGenre(categoryIndex, index),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加类型'),
              onPressed: () => _showAddGenreDialog(context, categoryIndex),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新分类'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '分类名称',
            hintText: '请输入分类名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                genreController.addCategory(GenreCategory(
                  name: nameController.text,
                  genres: [],
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddGenreDialog(BuildContext context, int categoryIndex) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final promptController = TextEditingController();
    final keywordsController = TextEditingController();
    final elementsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新类型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '类型名称*',
                  hintText: '请输入类型名称',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '类型描述*',
                  hintText: '请输入类型描述',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: promptController,
                decoration: const InputDecoration(
                  labelText: '提示词*',
                  hintText: '请输入AI生成提示词',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keywordsController,
                decoration: const InputDecoration(
                  labelText: '关键词*',
                  hintText: '例如：复仇, 正义, 救赎, 反转, 真相',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              const Text(
                '关键词用逗号分隔，至少输入3个关键词',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: elementsController,
                decoration: const InputDecoration(
                  labelText: '核心要素*',
                  hintText: '例如：\n人物：主角,配角,反派\n场景：学校,办公室\n情节：复仇,反转',
                  helperText: '每行一个分类，用冒号分隔分类和元素，元素之间用逗号分隔',
                ),
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              const Text(
                '提示：每行输入一个分类，格式为 "分类：元素1,元素2,元素3"',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '* 号为必填项',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 验证所有必填字段
              if (nameController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  promptController.text.isEmpty ||
                  keywordsController.text.isEmpty ||
                  elementsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写所有必填项')),
                );
                return;
              }

              // 解析关键词
              final keywords = keywordsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (keywords.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请至少输入3个关键词')),
                );
                return;
              }

              // 解析核心要素
              final elements = <String, List<String>>{};
              final elementLines = elementsController.text.split('\n');
              for (var line in elementLines) {
                var parts = line.split('：');  // 改用var而不是final
                if (parts.length != 2) {
                  parts = line.split(':'); // 现在可以重新赋值了
                }
                if (parts.length == 2) {
                  final key = parts[0].trim();
                  final values = parts[1]
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (key.isNotEmpty && values.isNotEmpty) {
                    elements[key] = values;
                  }
                }
              }

              if (elements.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请至少输入一组核心要素，格式：分类：元素1,元素2')),
                );
                return;
              }

              // 显示加载指示器
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final success = await genreController.addGenre(
                  categoryIndex,
                  NovelGenre(
                    name: nameController.text,
                    description: descriptionController.text,
                    prompt: promptController.text,
                    keywords: keywords,
                    elements: elements,
                  ),
                );

                // 关闭加载指示器
                Navigator.pop(context);

                if (success) {
                  // 关闭对话框
                  Navigator.pop(context);
                  // 显示成功消息
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加失败，请检查输入是否有效')),
                  );
                }
              } catch (e) {
                // 关闭加载指示器
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('发生错误：$e')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditGenreDialog(BuildContext context, NovelGenre genre, int categoryIndex, int genreIndex) {
    final nameController = TextEditingController(text: genre.name);
    final descriptionController = TextEditingController(text: genre.description);
    final promptController = TextEditingController(text: genre.prompt);
    final keywordsController = TextEditingController(text: genre.keywords.join(', '));
    
    // 将elements转换为字符串格式（每行一个分类）
    final elementsText = genre.elements.entries
        .map((e) => '${e.key}：${e.value.join(',')}')
        .join('\n');  // 使用换行符而不是分号
    final elementsController = TextEditingController(text: elementsText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑类型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '类型名称*',
                  hintText: '请输入类型名称',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '类型描述*',
                  hintText: '请输入类型描述',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: promptController,
                decoration: const InputDecoration(
                  labelText: '提示词*',
                  hintText: '请输入AI生成提示词',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keywordsController,
                decoration: const InputDecoration(
                  labelText: '关键词*',
                  hintText: '例如：复仇, 正义, 救赎, 反转, 真相',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              const Text(
                '关键词用逗号分隔，至少输入3个关键词',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: elementsController,
                decoration: const InputDecoration(
                  labelText: '核心要素*',
                  hintText: '例如：\n人物：主角,配角,反派\n场景：学校,办公室\n情节：复仇,反转',
                  helperText: '每行一个分类，用冒号分隔分类和元素，元素之间用逗号分隔',
                ),
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              const Text(
                '提示：每行输入一个分类，格式为 "分类：元素1,元素2,元素3"',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '* 号为必填项',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 验证所有必填字段
              if (nameController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  promptController.text.isEmpty ||
                  keywordsController.text.isEmpty ||
                  elementsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写所有必填项')),
                );
                return;
              }

              // 解析关键词
              final keywords = keywordsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (keywords.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请至少输入3个关键词')),
                );
                return;
              }

              // 解析核心要素
              final elements = <String, List<String>>{};
              final elementLines = elementsController.text.split('\n');
              for (var line in elementLines) {
                var parts = line.split('：');  // 改用var而不是final
                if (parts.length != 2) {
                  parts = line.split(':'); // 现在可以重新赋值了
                }
                if (parts.length == 2) {
                  final key = parts[0].trim();
                  final values = parts[1]
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (key.isNotEmpty && values.isNotEmpty) {
                    elements[key] = values;
                  }
                }
              }

              if (elements.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请至少输入一组核心要素，格式：分类：元素1,元素2')),
                );
                return;
              }

              // 显示加载指示器
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final success = await genreController.updateGenre(
                  categoryIndex,
                  genreIndex,
                  NovelGenre(
                    name: nameController.text,
                    description: descriptionController.text,
                    prompt: promptController.text,
                    keywords: keywords,
                    elements: elements,
                  ),
                );

                // 关闭加载指示器
                Navigator.pop(context);

                if (success) {
                  // 关闭对话框
                  Navigator.pop(context);
                  // 显示成功消息
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('保存成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // 显示失败消息，但不关闭对话框
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('保存失败，请检查输入是否有效，并确保类型名称不重复'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                // 关闭加载指示器
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('发生错误：$e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
} 