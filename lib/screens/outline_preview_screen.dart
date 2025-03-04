import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutlinePreviewScreen extends StatefulWidget {
  final String outline;
  final Function(String) onOutlineConfirmed;
  final Stream<String>? generationStream;

  const OutlinePreviewScreen({
    Key? key,
    required this.outline,
    required this.onOutlineConfirmed,
    this.generationStream,
  }) : super(key: key);

  @override
  State<OutlinePreviewScreen> createState() => _OutlinePreviewScreenState();
}

class _OutlinePreviewScreenState extends State<OutlinePreviewScreen> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isGenerating = false;
  String _generatingContent = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.outline);
    _listenToGenerationStream();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _listenToGenerationStream() {
    if (widget.generationStream != null) {
      setState(() {
        _isGenerating = true;
        _generatingContent = '';
      });
      
      // 使用缓冲区减少状态更新频率，特别是在Web平台上
      String buffer = '';
      bool updateScheduled = false;
      bool hasContent = false;
      
      widget.generationStream!.listen(
        (content) {
          // 更新缓冲区
          buffer = content;
          hasContent = true;
          
          // 如果没有计划更新，则安排一个
          if (!updateScheduled) {
            updateScheduled = true;
            
            // 使用microtask确保更新优先级
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _generatingContent = buffer;
                  _controller.text = buffer;
                });
              }
              updateScheduled = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isGenerating = false;
              if (hasContent) {
                // 确保最终内容已更新
                _generatingContent = buffer;
                _controller.text = buffer;
              } else {
                // 如果没有收到任何内容，显示错误信息
                Get.snackbar('提示', '未收到生成内容');
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isGenerating = false);
            Get.snackbar('错误', '生成过程出现错误: $error');
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGenerating ? '正在生成大纲...' : '大纲预览'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                // 保存修改
                widget.onOutlineConfirmed(_controller.text);
                setState(() => _isEditing = false);
              } else {
                // 进入编辑模式
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isGenerating) ...[              
              LinearProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '正在生成大纲，请稍候...',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
            ],
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      enabled: !_isGenerating,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '在此编辑大纲内容...',
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _isGenerating ? _generatingContent : _controller.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    child: const Text('修改大纲'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onOutlineConfirmed(_controller.text);
                      Get.back();
                    },
                    child: const Text('确认并继续'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}