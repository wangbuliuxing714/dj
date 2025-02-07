import 'package:get/get.dart';
import 'package:novel_app/services/ai_service.dart';
import 'package:novel_app/prompts/system_prompts.dart';
import 'package:novel_app/prompts/genre_prompts.dart';
import 'package:novel_app/models/novel.dart';
import 'package:novel_app/controllers/api_config_controller.dart';
import 'package:novel_app/services/content_review_service.dart';
import 'package:novel_app/screens/outline_preview_screen.dart';
import 'package:novel_app/services/cache_service.dart';
import 'package:novel_app/controllers/novel_controller.dart';
import 'package:novel_app/controllers/outline_prompt_controller.dart';

class NovelGeneratorService extends GetxService {
  final AIService _aiService;
  final ApiConfigController _apiConfig;
  final CacheService _cacheService;
  final _outlineController = Get.find<OutlinePromptController>();
  final void Function(String)? onProgress;
  final String targetReaders = "青年读者";
  final RxList<String> _generatedParagraphs = <String>[].obs;

  NovelGeneratorService(
    this._aiService, 
    this._apiConfig, 
    this._cacheService,
    {this.onProgress}
  );

  void _updateProgress(String message) {
    onProgress?.call(message);
  }

  // 在生成章节前检查缓存
  Future<String?> _checkCache(String chapterKey) async {
    return _cacheService.getContent(chapterKey);
  }

  // 保存生成的内容到缓存
  Future<void> _cacheContent(String chapterKey, String content) async {
    await _cacheService.cacheContent(chapterKey, content);
  }

  // 检查段落是否重复
  bool _isParagraphDuplicate(String paragraph) {
    return _generatedParagraphs.contains(paragraph);
  }

  // 添加新生成的段落到记录中
  void _addGeneratedParagraph(String paragraph) {
    _generatedParagraphs.add(paragraph);
    // 保持最近1000个段落的记录
    if (_generatedParagraphs.length > 1000) {
      _generatedParagraphs.removeAt(0);
    }
  }

  Future<String> generateOutline({
    required String title,
    required String genre,
    required String theme,
    required String targetReaders,
    required int totalChapters,
    void Function(String)? onProgress,
  }) async {
    try {
      print('开始生成大纲 - 标题: $title, 类型: $genre, 总集数: $totalChapters');
      _updateProgress("正在生成大纲...");
      
      // 每次生成的章节数
      const int batchSize = 20;
      final StringBuffer fullOutline = StringBuffer();
      
      // 分批生成大纲
      for (int start = 1; start <= totalChapters; start += batchSize) {
        final int end = (start + batchSize - 1) > totalChapters ? totalChapters : (start + batchSize - 1);
        print('生成第 $start 至 $end 集的大纲...');
        _updateProgress("正在生成第 $start 至 $end 集的大纲...");
        
        // 获取已生成的大纲内容作为上下文
        String existingOutline = fullOutline.toString();
        print('现有大纲长度: ${existingOutline.length}');
        
        final batchOutline = await _generateOutlineContent(
          title,
          [genre],
          theme,
          totalChapters,
          start,
          end,
          existingOutline,
        );
        
        print('本批次生成的大纲长度: ${batchOutline.length}');
        if (batchOutline.trim().isEmpty) {
          print('警告：本批次生成的大纲为空');
        }
        
        fullOutline.write(batchOutline);
        print('当前完整大纲长度: ${fullOutline.length}');
        
        // 如果不是最后一批，等待一下再继续
        if (end < totalChapters) {
          print('等待2秒后继续生成下一批...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      final completeOutline = fullOutline.toString();
      print('大纲生成完成，总长度: ${completeOutline.length}');
      
      if (completeOutline.trim().isEmpty) {
        print('错误：生成的大纲为空，检查生成过程');
        throw Exception('生成的大纲内容为空，请重试');
      }
      
      // 显示全屏预览对话框
      print('显示大纲预览对话框');
      final confirmedOutline = await Get.to(() => OutlinePreviewScreen(
        outline: completeOutline,
        onOutlineConfirmed: (String modifiedOutline) {
          print('用户确认了修改后的大纲，长度: ${modifiedOutline.length}');
          Get.back(result: modifiedOutline);
        },
      ));
      
      final finalOutline = confirmedOutline ?? completeOutline;
      print('最终大纲长度: ${finalOutline.length}');
      return finalOutline;
    } catch (e, stackTrace) {
      print('大纲生成失败');
      print('错误: $e');
      print('堆栈: $stackTrace');
      _updateProgress("大纲生成失败: $e");
      rethrow;
    }
  }

  Future<String> _generateOutlineContent(
    String title,
    List<String> genres,
    String theme,
    int totalChapters,
    int startChapter,
    int endChapter,
    String existingOutline,
  ) async {
    // 验证类型数量
    if (genres.isEmpty || genres.length > 5) {
      throw Exception('类型数量必须在1-5个之间');
    }

    // 使用选中的提示词模板
    String template = _outlineController.currentTemplate;
    
    // 获取所有选择的类型的提示词和特征
    final genrePrompts = genres.map((g) => GenrePrompts.getPromptByGenre(g)).join('\n\n');
    final genreKeywords = genres.map((g) => GenrePrompts.getKeywordsByGenre(g))
        .expand((i) => i).toSet().toList(); // 使用Set去重
    
    // 合并所有类型的核心要素
    final genreElements = genres.map((g) => GenrePrompts.getElementsByGenre(g))
        .fold<Map<String, List<String>>>({}, (map, elements) {
      elements.forEach((key, value) {
        if (map.containsKey(key)) {
          map[key] = [...map[key]!, ...value].toSet().toList(); // 使用Set去重
        } else {
          map[key] = value;
        }
      });
      return map;
    });

    // 格式化核心要素为文本
    String formatElements(Map<String, List<String>> elements) {
      return elements.entries.map((e) => 
        '${e.key}：${e.value.join("、")}').join('\n');
    }

    // 替换变量
    template = template
      .replaceAll('{title}', title)
      .replaceAll('{genre}', genres.join('+'))
      .replaceAll('{theme}', theme)
      .replaceAll('{target_readers}', targetReaders)
      .replaceAll('{total_chapters}', totalChapters.toString());

    final combinedGenrePrompt = '''
【选定的类型组合】
主类型：${genres[0]}
辅助类型：${genres.length > 1 ? genres.sublist(1).join('、') : '无'}

【各类型特征】
$genrePrompts

【融合后的核心要素】
${formatElements(genreElements)}

【关键词库】
${genreKeywords.join('、')}
''';

    final systemPrompt = '''【核心要求】
你是一位资深的短剧编剧，擅长创作悬疑复仇类短剧。请遵循以下要求：

1. 剧本格式（最高优先级）：
   - 每集2-3个场景
   - 场景格式：序号 地点 时间 内/外景
   - 动作以"△"开头，简短明确
   - 对白格式：角色名（情绪/动作）：对话内容
   - 特殊标记：【闪回】【镜头特写】【字幕】【付费卡点】

2. 剧情设计：
   - 每集必须有悬念和反转
   - 反派台词要强势威胁
   - 正派台词要隐忍有深意
   - 重点使用镜头语言
   - 每集结尾设置付费点

3. 场景要求：
   - 场景之间要有紧密联系
   - 每个场景要有明确冲突
   - 善用特写和慢动作
   - 注重视觉表现力
   - 控制场景节奏感

类型参考：
${combinedGenrePrompt}

用户创作要求：
${theme}

请记住：你不能更改用户指定的任何角色名称和基本设定。''';

    final userPrompt = '''请为这部融合${genres.join('和')}多种类型特点的短剧创作第$startChapter集到第$endChapter集的详细大纲。

【现有内容】
${existingOutline.isEmpty ? '这是第一部分大纲，请从第一集开始创作。' : '已有大纲内容：\n$existingOutline\n请继续创作后续内容。'}

【创作要求】
1. 必须与已有大纲保持连贯性和一致性
2. 每集都要有明确的悬念和反转
3. 注意与前文的呼应和伏笔
4. 为后续剧集预留发展空间
5. 巧妙融合${genres.join('和')}的类型特点
6. 创造独特的混合风格体验

【格式规范】（最高优先级，必须严格遵守）
每集必须包含以下六个部分，并使用指定的标题格式：

第N集：
1. 剧情概要：（简要概述本集主要内容）
2. 场景列表：（2-3个场景，包含地点和时间）
3. 关键对白：（重要人物的关键台词）
4. 重要道具：（本集出现的关键道具）
5. 悬念设计：（本集设置的悬念点）
6. 付费点：（本集的付费点设置）

请注意：
1. 每个部分必须使用以上标准格式的标题
2. 内容要详细具体，不要空泛
3. 每集必须完整包含以上六个部分
4. 严格遵守格式要求，保持一致性

请开始创作第$startChapter集到第$endChapter集的大纲。''';

    final buffer = StringBuffer();
    onProgress?.call('正在生成大纲...');
    
    try {
      print('开始调用AI生成大纲...');
      var hasReceivedContent = false;
      
      await for (final chunk in _aiService.generateTextStream(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 8000,
        temperature: 0.7,
      )) {
        if (chunk.trim().isNotEmpty) {
          hasReceivedContent = true;
          buffer.write(chunk);
          print('收到AI返回内容，当前长度：${buffer.length}');
          onProgress?.call('正在生成大纲...\n\n${buffer.toString()}');
        }
      }
      
      if (!hasReceivedContent) {
        print('错误：AI没有返回任何内容');
        throw Exception('AI生成失败，没有返回内容');
      }
      
      final rawOutline = buffer.toString().trim();
      print('AI生成完成，原始内容长度：${rawOutline.length}');
      
      if (rawOutline.isEmpty) {
        print('错误：AI返回的内容为空');
        throw Exception('AI返回的内容为空，请重试');
      }

      // 解析和格式化大纲
      print('开始格式化大纲...');
      final formattedOutline = _formatOutline(rawOutline, startChapter, endChapter);
      print('大纲格式化完成，长度：${formattedOutline.length}');
      
      if (formattedOutline.trim().isEmpty) {
        print('错误：格式化后的大纲为空');
        // 如果格式化后为空，返回原始内容
        print('返回原始内容');
        return rawOutline;
      }
      
      return formattedOutline;
    } catch (e, stackTrace) {
      print('AI生成过程出错');
      print('错误: $e');
      print('堆栈: $stackTrace');
      rethrow;
    }
  }

  String _formatOutline(String rawOutline, int startChapter, int endChapter) {
    if (rawOutline.trim().isEmpty) {
      print('警告：收到空的大纲内容');
      return '';
    }

    final buffer = StringBuffer();
    
    // 首先尝试按集数分割
    var episodes = rawOutline.split(RegExp(r'第[一二三四五六七八九十\d]+集[：:：]'));
    
    // 如果分割后没有有效内容，尝试其他可能的分隔符
    if (episodes.length <= 1) {
      episodes = rawOutline.split(RegExp(r'第[一二三四五六七八九十\d]+[章集][：:：]'));
    }
    
    print('分割后的片段数量：${episodes.length}');
    
    // 如果仍然无法分割，直接返回原始内容
    if (episodes.length <= 1) {
      print('警告：无法识别集数分隔符，返回原始内容');
      return rawOutline;
    }

    // 从第1个元素开始处理（第0个通常是空的）
    for (int i = 1; i < episodes.length; i++) {
      final episode = episodes[i].trim();
      if (episode.isEmpty) continue;
      
      buffer.writeln('第${startChapter + i - 1}集：');
      buffer.writeln(_formatEpisodeOutline(episode));
      buffer.writeln();
    }
    
    final result = buffer.toString().trim();
    print('格式化后的大纲长度：${result.length}');
    return result;
  }

  String _formatEpisodeOutline(String episodeContent) {
    if (episodeContent.trim().isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    final lines = episodeContent.split('\n');
    
    String currentSection = '';
    bool hasContent = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // 检查是否是段落标记
      if (trimmedLine.contains('剧情概要：') || 
          trimmedLine.contains('情节概要：') ||
          trimmedLine.contains('内容概要：')) {
        currentSection = '剧情概要';
        buffer.writeln('\n剧情概要：');
        hasContent = true;
      } else if (trimmedLine.contains('场景列表：') || 
                 trimmedLine.contains('场景安排：')) {
        currentSection = '场景列表';
        buffer.writeln('\n场景列表：');
        hasContent = true;
      } else if (trimmedLine.contains('关键对白：') || 
                 trimmedLine.contains('重要对白：')) {
        currentSection = '关键对白';
        buffer.writeln('\n关键对白：');
        hasContent = true;
      } else if (trimmedLine.contains('重要道具：') || 
                 trimmedLine.contains('关键道具：')) {
        currentSection = '重要道具';
        buffer.writeln('\n重要道具：');
        hasContent = true;
      } else if (trimmedLine.contains('悬念设计：') || 
                 trimmedLine.contains('悬念安排：')) {
        currentSection = '悬念设计';
        buffer.writeln('\n悬念设计：');
        hasContent = true;
      } else if (trimmedLine.contains('付费点：') || 
                 trimmedLine.contains('付费设计：')) {
        currentSection = '付费点';
        buffer.writeln('\n付费点：');
        hasContent = true;
      } else if (currentSection.isNotEmpty) {
        // 为内容添加缩进
        buffer.writeln('  $trimmedLine');
        hasContent = true;
      } else {
        // 如果没有识别到任何段落标记，直接添加内容
        buffer.writeln(trimmedLine);
        hasContent = true;
      }
    }
    
    if (!hasContent) {
      print('警告：该集内容为空');
      return '  (内容待生成)';
    }
    
    return buffer.toString().trim();
  }

  Future<Chapter> generateChapter({
    required String title,
    required int number,
    required String outline,
    required List<Chapter> previousChapters,
    required int totalChapters,
    required List<String> genres,
    required String theme,
    void Function(String)? onProgress,
  }) async {
    // 验证类型数量
    if (genres.isEmpty || genres.length > 5) {
      throw Exception('类型数量必须在1-5个之间');
    }

    // 生成章节缓存键
    final chapterKey = '${title}_$number';
    
    // 检查缓存
    final cachedContent = await _checkCache(chapterKey);
    if (cachedContent != null) {
      onProgress?.call('从缓存加载第$number章...');
      return Chapter(
        number: number,
        title: title,
        content: cachedContent,
      );
    }

    final context = _buildChapterContext(
      outline: outline,
      previousChapters: previousChapters,
      currentNumber: number,
      totalChapters: totalChapters,
    );

    // 获取成功的写作模式
    final successfulPatterns = _cacheService.getSuccessfulPatterns();
    
    // 根据章节进度动态调整生成参数
    final temperature = _getTemperatureForChapter(number, totalChapters);
    final maxTokens = _getMaxTokensForChapter(number);
    
    // 获取所有选择的类型的提示词和特征
    final genrePrompts = genres.map((g) => GenrePrompts.getPromptByGenre(g)).join('\n\n');
    final genreKeywords = genres.map((g) => GenrePrompts.getKeywordsByGenre(g))
        .expand((i) => i).toSet().toList(); // 使用Set去重
    
    // 合并所有类型的核心要素
    final genreElements = genres.map((g) => GenrePrompts.getElementsByGenre(g))
        .fold<Map<String, List<String>>>({}, (map, elements) {
      elements.forEach((key, value) {
        if (map.containsKey(key)) {
          map[key] = [...map[key]!, ...value].toSet().toList(); // 使用Set去重
        } else {
          map[key] = value;
        }
      });
      return map;
    });

    // 格式化核心要素为文本
    String formatElements(Map<String, List<String>> elements) {
      return elements.entries.map((e) => 
        '${e.key}：${e.value.join("、")}').join('\n');
    }

    final combinedGenrePrompt = '''
【选定的类型组合】
主类型：${genres[0]}
辅助类型：${genres.length > 1 ? genres.sublist(1).join('、') : '无'}

【各类型特征】
$genrePrompts

【融合后的核心要素】
${formatElements(genreElements)}

【关键词库】
${genreKeywords.join('、')}
''';
    
    final systemPrompt = '''【重要提示】
你是一位专业的短剧编剧，现在要创作一部短剧剧本。请遵循以下规范：

1. 格式规范（最高优先级）：
   - 场景格式：序号 地点 时间 内/外景
   - 动作以"△"开头，简短明确
   - 对白格式：角色名（情绪/动作）：对话内容
   - 画外音标注为"VO"
   - 特殊标记：【闪回】【镜头特写】【字幕】【付费卡点】

2. 场景设计：
   - 每个场景要有明确冲突
   - 场景之间要有紧密联系
   - 善用特写和慢动作
   - 注重视觉表现力
   - 控制场景节奏感

3. 对白创作：
   - 反派台词要强势威胁
   - 正派台词要隐忍有深意
   - 对白要简练有力
   - 避免过多废话
   - 突出人物性格特点

4. 视觉表现：
   - 注重镜头语言的运用
   - 善用特写表现细节
   - 通过动作表现情绪
   - 场景描写要有画面感

5. 注意事项：
   - 保持人物性格一致性
   - 注意前后文的连贯性
   - 为后续剧情做铺垫
   - 控制场景切换的节奏
   - 突出戏剧冲突和矛盾

类型参考：
${combinedGenrePrompt}

用户创作要求：
${theme}

请记住：你不能更改用户指定的任何角色名称和基本设定。''';

    final userPrompt = '''请根据以下信息创作第${number}集的内容：

【重要提示】
- 必须严格遵循大纲中关于本集的所有设定
- 必须确保与前文的连贯性和一致性
- 禁止偏离大纲规划的剧情发展方向
- 细节描写需要建立在已有内容基础上

【格式要求】
- 每个场景必须包含：
  * 场景编号（如1.1、1.2）
  * 地点（具体明确）
  * 时间（日/夜）
  * 内/外景标注
  * 出场人物列表

- 动作描写：
  * 以"△"开头
  * 简短明确
  * 富有画面感

- 对白格式：
  * 角色名（情绪/动作）：对话内容
  * 画外音标注为"VO"

- 特殊标记：
  * 【闪回】标注回忆片段
  * 【镜头特写】强调关键细节
  * 【字幕】补充时间或背景信息
  * 【付费卡点】设置在关键剧情处

【上下文信息】
$context

【创作指导】
${_designChapterFocus(number: number, totalChapters: totalChapters, outline: outline)}

特别要求：
1. 本集独特性：
   - 采用${_getChapterStyle(number, totalChapters)}的拍摄风格
   - 重点展现${_getChapterFocus(number, totalChapters)}
   - 通过${_getChapterTechnique(number, totalChapters)}来推进剧情

2. 镜头创新：
   - 采用${_getNarrationStyle(number, totalChapters)}的叙事方式
   - 运用${_getDescriptionStyle(number, totalChapters)}的表现手法
   - 设置${_getPlotDevice(number, totalChapters)}类型的转折

3. 节奏控制：
   - 以${_getChapterRhythm(number, totalChapters)}的节奏展开
   - 在关键处${_getEmotionalStyle(number, totalChapters)}
   - 结尾要${_getEndingStyle(number, totalChapters)}

请确保本集在风格和内容上与其他集有明显区别，给观众带来新鲜的观感体验。''';

    final buffer = StringBuffer();
    onProgress?.call('正在生成第$number章...');
    
    await for (final chunk in _aiService.generateTextStream(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    )) {
      buffer.write(chunk);
      onProgress?.call('正在生成第$number章...\n\n${buffer.toString()}');
    }

    // 检查生成的内容是否有重复
    final paragraphs = buffer.toString().split('\n\n');
    final uniqueParagraphs = <String>[];
    
    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;
      if (!_isParagraphDuplicate(paragraph)) {
        uniqueParagraphs.add(paragraph);
        _addGeneratedParagraph(paragraph);
      }
    }

    final content = uniqueParagraphs.join('\n\n');

    // 添加内容校对步骤
    onProgress?.call('正在校对和润色第$number章...');
    final contentReviewService = Get.find<ContentReviewService>();
    
    final reviewedContent = await contentReviewService.reviewContent(
      content: content,
      style: _determineStyle(number, totalChapters),
      model: AIModel.values.firstWhere(
        (m) => m.toString().split('.').last == _apiConfig.selectedModelId.value,
        orElse: () => AIModel.deepseek,
      ),
    );

    // 缓存成功生成的内容
    await _cacheContent(chapterKey, reviewedContent);

    onProgress?.call('第$number章校对完成');

    return Chapter(
      number: number,
      title: title,
      content: reviewedContent,
    );
  }

  double _getTemperatureForChapter(int number, int totalChapters) {
    final progress = number / totalChapters;
    // 在不同阶段使用不同的温度值，增加内容的多样性
    if (progress < 0.2) return 0.75; // 开始阶段，相对保守
    if (progress < 0.4) return 0.85; // 发展阶段，增加创造性
    if (progress < 0.7) return 0.9;  // 高潮阶段，最大创造性
    return 0.8; // 结尾阶段，适度平衡
  }

  int _getMaxTokensForChapter(int number) {
    // 根据章节重要性动态调整长度，但不超过5000字的token限制
    return 6000; // 约等于5000字
  }

  String _getChapterStyle(int number, int totalChapters) {
    final styles = [
      '写实冷峻',
      '悬疑迷离',
      '快节奏剪辑',
      '慢镜头特写',
      '多机位转场',
      '手持摇晃',
      '固定俯拍',
      '跟拍推进',
      '蒙太奇',
      '平行剪辑'
    ];
    return styles[number % styles.length];
  }

  String _getChapterFocus(int number, int totalChapters) {
    final focuses = [
      '人物表情特写',
      '关键道具细节',
      '环境氛围营造',
      '动作场面设计',
      '对话戏张力',
      '心理状态刻画',
      '群戏调度',
      '空间转换',
      '时间跨度',
      '情绪渲染'
    ];
    return focuses[number % focuses.length];
  }

  String _getChapterTechnique(int number, int totalChapters) {
    final techniques = [
      '倒叙插叙',
      '多线并进',
      '意识流',
      '象征暗示',
      '悬念设置',
      '细节刻画',
      '场景切换',
      '心理描写',
      '对比反衬',
      '首尾呼应'
    ];
    return techniques[number % techniques.length];
  }

  String _getNarrationStyle(int number, int totalChapters) {
    final styles = [
      '全知视角',
      '第一人称',
      '限制视角',
      '多视角交替',
      '客观视角',
      '意识流',
      '书信体',
      '日记体',
      '倒叙',
      '插叙'
    ];
    return styles[number % styles.length];
  }

  String _getDescriptionStyle(int number, int totalChapters) {
    final styles = [
      '白描手法',
      '细节刻画',
      '心理描写',
      '环境烘托',
      '动作描写',
      '对话刻画',
      '象征手法',
      '比喻修辞',
      '夸张手法',
      '衬托对比'
    ];
    return styles[number % styles.length];
  }

  String _getPlotDevice(int number, int totalChapters) {
    final devices = [
      '悬念',
      '伏笔',
      '巧合',
      '误会',
      '反转',
      '暗示',
      '象征',
      '对比',
      '平行',
      '递进'
    ];
    return devices[number % devices.length];
  }

  String _getChapterRhythm(int number, int totalChapters) {
    final rhythms = [
      '舒缓绵长',
      '紧凑快节奏',
      '起伏跌宕',
      '徐徐展开',
      '波澜起伏',
      '节奏明快',
      '张弛有度',
      '缓急结合',
      '循序渐进',
      '高潮迭起'
    ];
    return rhythms[number % rhythms.length];
  }

  String _getEmotionalStyle(int number, int totalChapters) {
    final styles = [
      '情绪爆发',
      '含蓄委婉',
      '峰回路转',
      '悬念迭起',
      '温情脉脉',
      '激烈冲突',
      '平淡中见真情',
      '跌宕起伏',
      '意味深长',
      '震撼人心'
    ];
    return styles[number % styles.length];
  }

  String _getEndingStyle(int number, int totalChapters) {
    final styles = [
      '悬念收尾',
      '意味深长',
      '余音绕梁',
      '峰回路转',
      '留白处理',
      '首尾呼应',
      '点题升华',
      '情感升华',
      '引人深思',
      '伏笔埋藏'
    ];
    return styles[number % styles.length];
  }

  String _determineStyle(int currentChapter, int totalChapters) {
    final progress = currentChapter / totalChapters;
    
    if (progress < 0.3) {
      return '轻松爽快'; // 前期以轻松为主
    } else if (progress < 0.7) {
      return '热血激昂'; // 中期以热血为主
    } else {
      return '高潮迭起'; // 后期以高潮为主
    }
  }

  String _buildChapterContext({
    required String outline,
    required List<Chapter> previousChapters,
    required int currentNumber,
    required int totalChapters,
  }) {
    final buffer = StringBuffer();
    
    // 添加大纲信息
    buffer.writeln('【总体大纲】');
    buffer.writeln(outline);
    buffer.writeln();

    // 添加前文概要
    if (previousChapters.isNotEmpty) {
      buffer.writeln('【前文概要】');
      for (int i = 0; i < previousChapters.length; i++) {
        final chapter = previousChapters[i];
        buffer.writeln('第${chapter.number}章 ${chapter.title}');
        buffer.writeln('概要：${_generateChapterSummary(chapter.content)}');
        buffer.writeln();
      }
    }

    // 添加最近两章的完整内容
    if (previousChapters.isNotEmpty) {
      buffer.writeln('【最近两章详细内容】');
      final recentChapters = previousChapters.length >= 2 
          ? previousChapters.sublist(previousChapters.length - 2)
          : previousChapters;
      
      for (final chapter in recentChapters) {
        buffer.writeln('第${chapter.number}章 ${chapter.title}');
        buffer.writeln(chapter.content);
        buffer.writeln();
      }
    }

    // 添加当前章节定位
    buffer.writeln('【当前章节定位】');
    final progress = currentNumber / totalChapters;
    if (currentNumber == 1) {
      buffer.writeln('开篇章节，需要：');
      buffer.writeln('- 介绍主要人物和背景');
      buffer.writeln('- 设置初始矛盾');
      buffer.writeln('- 埋下后续伏笔');
    } else if (progress < 0.3) {
      buffer.writeln('起始阶段，需要：');
      buffer.writeln('- 展开初期剧情');
      buffer.writeln('- 深化人物塑造');
      buffer.writeln('- 推进主要情节');
    } else if (progress < 0.7) {
      buffer.writeln('发展阶段，需要：');
      buffer.writeln('- 加强矛盾冲突');
      buffer.writeln('- 展示角色成长');
      buffer.writeln('- 推进核心剧情');
    } else if (progress < 0.9) {
      buffer.writeln('高潮阶段，需要：');
      buffer.writeln('- 制造情节高潮');
      buffer.writeln('- 解决主要矛盾');
      buffer.writeln('- 收束重要线索');
    } else {
      buffer.writeln('结局阶段，需要：');
      buffer.writeln('- 完美收官');
      buffer.writeln('- 点题升华');
      buffer.writeln('- 首尾呼应');
    }

    return buffer.toString();
  }

  String _generateChapterSummary(String content) {
    // 简单的摘要生成逻辑，可以根据需要优化
    final sentences = content.split('。');
    if (sentences.length <= 3) return content;
    
    return sentences.take(3).join('。') + '。';
  }

  String _designChapterFocus({
    required int number,
    required int totalChapters,
    required String outline,
  }) {
    final progress = number / totalChapters;
    final buffer = StringBuffer();

    buffer.writeln('本章创作指导：');
    
    // 基础结构指导
    buffer.writeln('【结构创新】');
    if (number == 1) {
      buffer.writeln('- 尝试以非常规视角或时间点切入');
      buffer.writeln('- 通过细节和氛围暗示而不是直接介绍');
      buffer.writeln('- 设置悬念，但不要过于明显');
    } else {
      buffer.writeln('- 避免线性叙事，可以穿插回忆或预示');
      buffer.writeln('- 通过多线并行推进剧情');
      buffer.writeln('- 在关键处设置情节反转或悬念');
    }

    // 场景设计指导
    buffer.writeln('\n【场景设计】');
    buffer.writeln('- 融入独特的环境元素和氛围');
    buffer.writeln('- 通过环境暗示人物心理变化');
    buffer.writeln('- 注重细节描写的新颖性');

    // 人物互动指导
    buffer.writeln('\n【人物刻画】');
    buffer.writeln('- 展现人物的矛盾性和复杂性');
    buffer.writeln('- 通过细微互动体现性格特点');
    buffer.writeln('- 设置内心独白或心理活动');

    // 根据进度添加特殊要求
    buffer.writeln('\n【阶段重点】');
    if (progress < 0.2) {
      buffer.writeln('起始阶段：');
      buffer.writeln('- 设置伏笔但不要太明显');
      buffer.writeln('- 展现人物性格的多面性');
      buffer.writeln('- 通过细节暗示未来发展');
    } else if (progress < 0.4) {
      buffer.writeln('发展初期：');
      buffer.writeln('- 制造情节小高潮');
      buffer.writeln('- 加入意外事件或转折');
      buffer.writeln('- 深化人物关系发展');
    } else if (progress < 0.6) {
      buffer.writeln('中期发展：');
      buffer.writeln('- 展开多线叙事');
      buffer.writeln('- 设置次要矛盾冲突');
      buffer.writeln('- 暗示重要转折点');
    } else if (progress < 0.8) {
      buffer.writeln('高潮铺垫：');
      buffer.writeln('- 多线交织推进');
      buffer.writeln('- 设置关键抉择');
      buffer.writeln('- 情节反转或悬念');
    } else {
      buffer.writeln('结局阶段：');
      buffer.writeln('- 出人意料的结局');
      buffer.writeln('- 首尾呼应但不落俗套');
      buffer.writeln('- 留有想象空间');
    }

    // 写作技巧指导
    buffer.writeln('\n【创新要求】');
    buffer.writeln('1. 叙事视角：');
    buffer.writeln('   - 尝试不同视角切换');
    buffer.writeln('   - 运用时空交错手法');
    buffer.writeln('   - 适当使用意识流');

    buffer.writeln('2. 情节设计：');
    buffer.writeln('   - 避免套路化发展');
    buffer.writeln('   - 设置合理反转');
    buffer.writeln('   - 保持悬念感');

    buffer.writeln('3. 细节描写：');
    buffer.writeln('   - 独特的比喻和修辞');
    buffer.writeln('   - 新颖的场景描绘');
    buffer.writeln('   - 富有特色的对话');

    return buffer.toString();
  }

  String _getChapterSummary(String content) {
    // 取最后三分之一的内容作为上下文
    final lines = content.split('\n');
    final startIndex = (lines.length * 2 / 3).round();
    return lines.sublist(startIndex).join('\n');
  }

  Future<Novel> generateNovel({
    required String title,
    required List<String> genres,
    required String theme,
    required String targetReaders,
    required int totalChapters,
    bool continueGeneration = false,
    void Function(String)? onProgress,
  }) async {
    try {
      // 验证类型数量
      if (genres.isEmpty || genres.length > 5) {
        throw Exception('类型数量必须在1-5个之间');
      }

      String outline;
      List<Chapter> chapters = [];
      String fullContent = '';

      if (continueGeneration) {
        // 从缓存中获取大纲和已生成的章节
        outline = await _checkCache('outline_$title') ?? '';
        if (outline.isEmpty) {
          throw Exception('未找到缓存的大纲，无法继续生成');
        }

        // 获取已缓存的章节
        for (int i = 1; i <= totalChapters; i++) {
          final cachedChapter = await _checkCache('chapter_${title}_$i');
          if (cachedChapter != null) {
            final chapter = Chapter(
              number: i,
              title: '第 $i 章',
              content: cachedChapter,
            );
            chapters.add(chapter);
            fullContent += cachedChapter + '\n\n';
          } else {
            // 从第一个未缓存的章节开始生成
            break;
          }
        }
      } else {
        // 清除之前的缓存
        _cacheService.clearAllCache();
        
        // 生成新大纲
        onProgress?.call('正在生成大纲...');
        outline = await generateOutline(
          title: title,
          genre: genres.join('+'),
          theme: theme,
          targetReaders: targetReaders,
          totalChapters: totalChapters,
          onProgress: onProgress,
        );
        
        // 缓存大纲
        await _cacheService.cacheContent('outline_$title', outline);
      }

      // 继续生成剩余章节
      for (int i = chapters.length + 1; i <= totalChapters; i++) {
        onProgress?.call('正在生成第 $i 章...');
        final chapter = await generateChapter(
          title: '第 $i 章',
          number: i,
          outline: outline,
          previousChapters: chapters,
          totalChapters: totalChapters,
          genres: genres,
          theme: theme,
          onProgress: onProgress,
        );
        
        // 缓存新生成的章节
        await _cacheService.cacheContent('chapter_${title}_$i', chapter.content);
        
        chapters.add(chapter);
        fullContent += chapter.content + '\n\n';

        // 通知章节生成完成
        Get.find<NovelController>().addChapter(chapter);
      }

      return Novel(
        title: title,
        genre: genres.join('+'),
        outline: outline,
        content: fullContent,
        chapters: chapters,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('生成小说失败: $e');
      rethrow;
    }
  }

  Future<String> _generateWithAI(String prompt) async {
    try {
      String response = '';
      await for (final chunk in _aiService.generateTextStream(
        systemPrompt: '''作为一个专业的小说创作助手，请遵循以下创作原则：

1. 故事逻辑：
   - 确保因果关系清晰合理，事件发展有其必然性
   - 人物行为要符合其性格特征和处境
   - 情节转折要有铺垫，避免突兀
   - 矛盾冲突的解决要符合逻辑
   - 故事背景要前后一致，细节要互相呼应

2. 叙事结构：
   - 采用灵活多变的叙事手法，避免单一直线式发展
   - 合理安排伏笔和悬念，让故事更有层次感
   - 注意时间线的合理性，避免前后矛盾
   - 场景转换要流畅自然，不生硬突兀
   - 故事节奏要有张弛，紧凑处突出戏剧性

3. 人物塑造：
   - 赋予角色丰富的心理活动和独特性格
   - 人物成长要符合其经历和环境
   - 人物关系要复杂立体，互动要自然
   - 对话要体现人物性格和身份特点
   - 避免脸谱化和类型化的人物描写

4. 环境描写：
   - 场景描写要与情节和人物情感相呼应
   - 细节要生动传神，突出关键特征
   - 环境氛围要配合故事发展
   - 感官描写要丰富多样
   - 避免无关的环境描写，保持紧凑

5. 语言表达：
   - 用词准确生动，避免重复和陈词滥调
   - 句式灵活多样，富有韵律感
   - 善用修辞手法，但不过分堆砌
   - 对话要自然流畅，符合说话人特点
   - 描写要细腻传神，避免空洞

请基于以上要求，创作出逻辑严密、情节生动、人物丰满的精彩内容。''',
        userPrompt: prompt,
      )) {
        response += chunk;
      }
      return response;
    } catch (e) {
      return '生成失败: $e';
    }
  }
} 