import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OutlinePrompt {
  final String name;
  final String description;
  final String template;
  
  OutlinePrompt({
    required this.name,
    required this.description,
    required this.template,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'template': template,
  };

  factory OutlinePrompt.fromJson(Map<String, dynamic> json) => OutlinePrompt(
    name: json['name'],
    description: json['description'],
    template: json['template'],
  );
}

class OutlinePromptController extends GetxController {
  final RxList<OutlinePrompt> prompts = <OutlinePrompt>[].obs;
  final Rx<OutlinePrompt?> selectedPrompt = Rx<OutlinePrompt?>(null);
  late final SharedPreferences _prefs;
  final String _customPromptsKey = 'custom_outline_prompts';
  final String _selectedPromptKey = 'selected_prompt_name';
  
  // 模板变量
  static const Map<String, String> templateVariables = {
    '{title}': '剧名',
    '{genre}': '剧集类型',
    '{theme}': '主题设定',
    '{target_viewers}': '目标观众',
  };

  // 基础模板结构
  String get baseTemplateStructure => '''剧名：{title}
类型：{genre}
主题：{theme}
目标观众：{target_viewers}

要求：
1. 设计一个吸引人的开场
2. 规划8-12集的剧情走向
3. 设计合理的复仇计划
4. 安排扣人心弦的反转
5. 规划正邪对决路线
6. 设计精彩的高潮情节
7. 准备震撼的结局

大纲结构：
1. 第1-3集（起源篇）
   - 人物背景
   - 受害经过
   - 复仇动机
   - 初步计划

2. 第4-8集（复仇篇）
   - 计划实施
   - 反派反击
   - 局势升级
   - 多重反转

3. 第9-12集（终局篇）
   - 真相大白
   - 最终对决
   - 复仇成功
   - 结局反转''';

  // 获取变量说明文本
  String get variableExplanation {
    final buffer = StringBuffer('可用变量说明：\n');
    templateVariables.forEach((key, value) {
      buffer.writeln('$key - $value');
    });
    return buffer.toString();
  }

  // 默认提示词模板
  final List<OutlinePrompt> _defaultPrompts = [
    OutlinePrompt(
      name: '标准短剧大纲',
      description: '适用于悬疑复仇类短剧的标准大纲模板',
      template: '''请根据以下要求制定一个详细的短剧大纲：

剧名：{title}
类型：{genre}
主题：{theme}
目标观众：{target_viewers}

要求：
1. 设计一个吸引人的开场
2. 规划8-12集的剧情走向
3. 设计合理的复仇计划
4. 安排扣人心弦的反转
5. 规划正邪对决路线
6. 设计精彩的高潮情节
7. 准备震撼的结局

大纲结构：
1. 第1-3集（起源篇）
   - 人物背景
   - 受害经过
   - 复仇动机
   - 初步计划

2. 第4-8集（复仇篇）
   - 计划实施
   - 反派反击
   - 局势升级
   - 多重反转

3. 第9-12集（终局篇）
   - 真相大白
   - 最终对决
   - 复仇成功
   - 结局反转''',
    ),
    OutlinePrompt(
      name: '校园复仇大纲',
      description: '适用于校园霸凌复仇类短剧的大纲模板',
      template: '''请根据以下要求制定一个校园复仇短剧的详细大纲：

剧名：{title}
类型：{genre}
主题：{theme}
目标观众：{target_viewers}

要求：
1. 设计一个令人共鸣的校园霸凌背景
2. 规划8-12集的复仇计划
3. 设计多层次的校园权力关系
4. 安排扣人心弦的反转和揭露
5. 规划正邪对决的升级路线
6. 设计震撼人心的高潮情节
7. 准备具有教育意义的结局

大纲结构：
1. 第1-3集（受害篇）
   - 校园生活
   - 霸凌经过
   - 心理创伤
   - 复仇决心

2. 第4-8集（反击篇）
   - 收集证据
   - 舆论反转
   - 局势升级
   - 多重打击

3. 第9-12集（正义篇）
   - 真相曝光
   - 校园整顿
   - 正义实现
   - 成长蜕变''',
    ),
  ];

  Future<void> init() async {
    _prefs = Get.find<SharedPreferences>();
    await _loadPrompts();
    _loadSelectedPrompt();
  }

  void _loadSelectedPrompt() {
    final savedName = _prefs.getString(_selectedPromptKey);
    if (savedName != null) {
      selectedPrompt.value = prompts.firstWhereOrNull((p) => p.name == savedName);
    }
    // 如果没有选中的模板，默认选择第一个
    selectedPrompt.value ??= prompts.firstOrNull;
  }

  Future<void> setSelectedPrompt(String promptName) async {
    final prompt = prompts.firstWhereOrNull((p) => p.name == promptName);
    if (prompt != null) {
      selectedPrompt.value = prompt;
      await _prefs.setString(_selectedPromptKey, promptName);
    }
  }

  // 获取当前选中的提示词模板
  String get currentTemplate {
    return selectedPrompt.value?.template ?? _defaultPrompts[0].template;
  }

  Future<void> _loadPrompts() async {
    try {
      // 清空当前列表
      prompts.clear();
      
      // 首先加载默认模板
      prompts.addAll(_defaultPrompts);
      
      // 然后加载自定义模板
      final customPromptsJson = _prefs.getString(_customPromptsKey);
      if (customPromptsJson != null) {
        final List<dynamic> customPromptsList = jsonDecode(customPromptsJson);
        final List<OutlinePrompt> customPrompts = customPromptsList
            .map((json) => OutlinePrompt.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        prompts.addAll(customPrompts);
      }
      
      print('成功加载 ${prompts.length} 个提示词模板');
    } catch (e) {
      print('加载提示词模板失败: $e');
    }
  }

  Future<void> _saveCustomPrompts() async {
    try {
      final customPrompts = prompts
          .where((prompt) => !_isDefaultPrompt(prompt.name))
          .toList();
      
      final customPromptsJson = jsonEncode(
        customPrompts.map((prompt) => prompt.toJson()).toList(),
      );
      
      await _prefs.setString(_customPromptsKey, customPromptsJson);
      print('成功保存 ${customPrompts.length} 个自定义提示词模板');
    } catch (e) {
      print('保存提示词模板失败: $e');
      rethrow;
    }
  }

  bool _isDefaultPrompt(String promptName) {
    final isDefault = _defaultPrompts.any((prompt) => prompt.name == promptName);
    print('检查是否为默认提示词: $promptName - $isDefault');
    return isDefault;
  }

  bool isDefaultPrompt(String promptName) {
    return _isDefaultPrompt(promptName);
  }

  Future<void> addPrompt(OutlinePrompt prompt) async {
    if (!prompts.any((p) => p.name == prompt.name)) {
      prompts.add(prompt);
      await _saveCustomPrompts();
    }
  }

  Future<void> updatePrompt(int index, OutlinePrompt newPrompt) async {
    try {
      final currentPrompt = prompts[index];
      final isDefault = _isDefaultPrompt(currentPrompt.name);
      print('正在更新提示词：${currentPrompt.name}');
      print('是否为默认提示词：$isDefault');
      
      if (!isDefault) {
        print('开始更新提示词...');
        prompts[index] = newPrompt;
        await _saveCustomPrompts();
        print('提示词更新成功！');
      } else {
        print('无法编辑默认提示词');
        throw Exception('默认提示词模板不可编辑');
      }
    } catch (e) {
      print('更新提示词失败: $e');
      rethrow;
    }
  }

  Future<void> deletePrompt(int index) async {
    if (!_isDefaultPrompt(prompts[index].name)) {
      prompts.removeAt(index);
      await _saveCustomPrompts();
    }
  }
} 