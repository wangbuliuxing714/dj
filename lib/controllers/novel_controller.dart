import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/novel.dart';
import 'package:novel_app/models/genre_category.dart';
import 'package:novel_app/services/novel_generator_service.dart';
import 'package:novel_app/services/cache_service.dart';
import 'package:novel_app/services/export_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:novel_app/models/character_card.dart';

class NovelController extends GetxController {
  final _novelGenerator = Get.find<NovelGeneratorService>();
  final _cacheService = Get.find<CacheService>();
  final _exportService = ExportService();
  final novels = <Novel>[].obs;
  
  final title = ''.obs;
  final background = ''.obs;
  final otherRequirements = ''.obs;
  final style = '悬疑烧脑'.obs;
  final totalChapters = 12.obs;
  final selectedGenres = <String>[].obs;
  
  // 角色相关
  final Rx<CharacterCard?> selectedMainCharacter = Rx<CharacterCard?>(null);
  final Rx<CharacterCard?> selectedFemaleCharacter = Rx<CharacterCard?>(null);
  final RxList<CharacterCard> selectedSupportingCharacters = <CharacterCard>[].obs;
  final RxList<CharacterCard> selectedVillains = <CharacterCard>[].obs;
  
  final isGenerating = false.obs;
  final generationStatus = ''.obs;
  final generationProgress = 0.0.obs;

  static const _boxName = 'generated_chapters';
  late final Box<dynamic> _box;
  
  final RxList<Chapter> _generatedChapters = <Chapter>[].obs;

  List<Chapter> get generatedChapters => _generatedChapters;

  @override
  void onInit() async {
    super.onInit();
    await _initHive();
    _loadChapters();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  void _loadChapters() {
    final savedChapters = _box.get('chapters');
    if (savedChapters != null) {
      final List<dynamic> chaptersJson = jsonDecode(savedChapters);
      _generatedChapters.value = chaptersJson
          .map((json) => Chapter.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _sortChapters();
    }
  }

  Future<void> _saveChapters() async {
    final chaptersJson = jsonEncode(
      _generatedChapters.map((chapter) => chapter.toJson()).toList(),
    );
    await _box.put('chapters', chaptersJson);
  }

  void updateTitle(String value) => title.value = value;
  void updateBackground(String value) => background.value = value;
  void updateOtherRequirements(String value) => otherRequirements.value = value;
  void updateStyle(String value) => style.value = value;
  void updateTotalChapters(int value) => totalChapters.value = value;

  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else if (selectedGenres.length < 5) {
      selectedGenres.add(genre);
    }
  }

  void clearCache() {
    _cacheService.clearAllCache();
  }

  void setMainCharacter(CharacterCard character) {
    selectedMainCharacter.value = character;
  }

  void setFemaleCharacter(CharacterCard character) {
    selectedFemaleCharacter.value = character;
  }

  void addSupportingCharacter(CharacterCard character) {
    if (!selectedSupportingCharacters.contains(character)) {
      selectedSupportingCharacters.add(character);
    }
  }

  void removeSupportingCharacter(CharacterCard character) {
    selectedSupportingCharacters.remove(character);
  }

  void addVillain(CharacterCard character) {
    if (!selectedVillains.contains(character)) {
      selectedVillains.add(character);
    }
  }

  void removeVillain(CharacterCard character) {
    selectedVillains.remove(character);
  }

  Future<void> generateNovel({bool continueGeneration = false}) async {
    if (title.isEmpty) {
      Get.snackbar('错误', '请输入剧名');
      return;
    }

    if (selectedGenres.isEmpty) {
      Get.snackbar('错误', '请选择至少一个剧集类型');
      return;
    }

    if (selectedMainCharacter.value == null) {
      Get.snackbar('错误', '请选择主角');
      return;
    }

    // 构建完整的创作要求
    final theme = '''【角色设定】
主角设定：${_formatCharacterInfo(selectedMainCharacter.value!)}
女主角设定：${selectedFemaleCharacter.value != null ? _formatCharacterInfo(selectedFemaleCharacter.value!) : '无'}
配角设定：${selectedSupportingCharacters.map((c) => _formatCharacterInfo(c)).join('\n')}
反派设定：${selectedVillains.map((c) => _formatCharacterInfo(c)).join('\n')}
背景设置：${background.value}

【剧情要求】
${otherRequirements.value}

【格式规范】
1. 每集2-3个场景
2. 场景格式：序号 地点 时间 内/外景
3. 动作以"△"开头
4. 对白格式：角色名（情绪/动作）：对话内容
5. 特殊标记：【闪回】【镜头特写】【字幕】【付费卡点】

【核心要求】
1. 每集必须设置悬念和反转
2. 反派台词要强势威胁
3. 正派台词要隐忍有深意
4. 重点使用镜头语言
5. 每集结尾设置付费点''';

    isGenerating.value = true;
    generationProgress.value = 0;

    try {
      final novel = await _novelGenerator.generateNovel(
        title: title.value,
        genres: selectedGenres,
        theme: theme,
        targetReaders: '青年读者',
        totalChapters: totalChapters.value,
        continueGeneration: continueGeneration,
        onProgress: (status) {
          generationStatus.value = status;
          if (status.contains('正在生成大纲')) {
            generationProgress.value = 0.2;
          } else if (status.contains('正在生成第')) {
            final currentChapter = int.tryParse(
                  status.split('第')[1].split('章')[0].trim(),
                ) ??
                0;
            generationProgress.value =
                0.2 + 0.8 * (currentChapter / totalChapters.value);
          }
        },
      );

      novels.insert(0, novel);
      Get.snackbar('成功', '小说生成完成');
    } catch (e) {
      Get.snackbar('错误', '生成失败：$e');
    } finally {
      isGenerating.value = false;
      generationProgress.value = 0;
      generationStatus.value = '';
    }
  }

  void addChapter(Chapter chapter) {
    _generatedChapters.add(chapter);
    _sortChapters();
    _saveChapters();
  }

  void deleteChapter(int chapterNumber) {
    _generatedChapters.removeWhere((chapter) => chapter.number == chapterNumber);
    _saveChapters();
  }

  void clearAllChapters() {
    _generatedChapters.clear();
    _saveChapters();
  }

  void updateChapter(Chapter chapter) {
    final index = _generatedChapters.indexWhere((c) => c.number == chapter.number);
    if (index != -1) {
      _generatedChapters[index] = chapter;
      _saveChapters();
    }
  }

  Chapter? getChapter(int chapterNumber) {
    return _generatedChapters.firstWhereOrNull((chapter) => chapter.number == chapterNumber);
  }

  void _sortChapters() {
    _generatedChapters.sort((a, b) => a.number.compareTo(b.number));
  }

  Future<String> exportChapters() async {
    try {
      if (_generatedChapters.isEmpty) {
        return '没有可导出的章节';
      }

      return await _exportService.exportChapters(
        _generatedChapters,
        'txt',  // 默认使用txt格式
        title: title.value,
      );
    } catch (e) {
      return '导出失败：$e';
    }
  }

  // 在生成新章节时自动添加到存储
  Future<Chapter> generateChapter(int chapterNumber) async {
    try {
      final chapter = await _novelGenerator.generateChapter(
        title: '第 $chapterNumber 章',
        number: chapterNumber,
        outline: novels.first.outline,
        previousChapters: _generatedChapters.toList(),
        totalChapters: totalChapters.value,
        genres: selectedGenres,
        theme: '''主角设定：${_formatCharacterInfo(selectedMainCharacter.value!)}
女主角设定：${selectedFemaleCharacter.value != null ? _formatCharacterInfo(selectedFemaleCharacter.value!) : '无'}
故事背景：${background.value}
其他要求：${otherRequirements.value}''',
        onProgress: (status) {
          generationStatus.value = status;
        },
      );
      
      // 自动添加到存储
      addChapter(chapter);
      
      return chapter;
    } catch (e) {
      print('生成章节失败: $e');
      rethrow;
    }
  }

  // 开始生成
  void startGeneration() {
    if (isGenerating.value) return;
    isGenerating.value = true;
    // 清空已生成的章节
    clearAllChapters();
    generateNovel();
  }

  // 停止生成
  void stopGeneration() {
    isGenerating.value = false;
  }

  String _formatCharacterInfo(CharacterCard character) {
    final info = StringBuffer();
    
    // 基本信息
    info.write('${character.name}');
    if (character.gender != null) info.write('，${character.gender}');
    if (character.age != null) info.write('，${character.age}岁');
    if (character.species != null) info.write('，${character.species}');
    
    // 外貌特征
    final appearance = <String>[];
    if (character.bodyType != null) appearance.add(character.bodyType!);
    if (character.facialFeatures != null) appearance.add(character.facialFeatures!);
    if (character.clothingStyle != null) appearance.add(character.clothingStyle!);
    if (character.accessories != null) appearance.add(character.accessories!);
    if (appearance.isNotEmpty) {
      info.write('\n外貌特征：${appearance.join('；')}');
    }
    
    // 性格特征
    if (character.personality != null) info.write('\n性格：${character.personality}');
    if (character.personalityComplexity != null) info.write('\n性格复杂性：${character.personalityComplexity}');
    if (character.personalityFormation != null) info.write('\n性格形成原因：${character.personalityFormation}');
    
    // 背景故事
    if (character.background != null) info.write('\n背景：${character.background}');
    if (character.lifeExperience != null) info.write('\n重要经历：${character.lifeExperience}');
    if (character.pastEvents != null) info.write('\n关键过往：${character.pastEvents}');
    
    // 目标和动机
    if (character.motivation != null) info.write('\n动机：${character.motivation}');
    if (character.shortTermGoals != null) info.write('\n短期目标：${character.shortTermGoals}');
    if (character.longTermGoals != null) info.write('\n长期目标：${character.longTermGoals}');
    
    // 能力和技能
    final skills = <String>[];
    if (character.specialAbilities != null) skills.add('特殊能力：${character.specialAbilities}');
    if (character.normalSkills != null) skills.add('普通技能：${character.normalSkills}');
    if (skills.isNotEmpty) {
      info.write('\n能力：${skills.join('；')}');
    }
    
    // 人际关系
    final relationships = <String>[];
    if (character.family != null) relationships.add('家人：${character.family}');
    if (character.friends != null) relationships.add('朋友：${character.friends}');
    if (character.enemies != null) relationships.add('敌人：${character.enemies}');
    if (character.lovers != null) relationships.add('情感关系：${character.lovers}');
    if (relationships.isNotEmpty) {
      info.write('\n人际关系：${relationships.join('；')}');
    }
    
    return info.toString();
  }
}