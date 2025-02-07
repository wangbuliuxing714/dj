class NovelGenre {
  final String name;
  final String description;
  final String prompt;
  final Map<String, List<String>> elements;  // 核心要素，每个要素包含多个具体项
  final List<String> keywords;  // 关键词列表

  const NovelGenre({
    required this.name,
    required this.description,
    required this.prompt,
    required this.elements,
    required this.keywords,
  });

  // 生成模板文本
  String get template => '''类型：$name
常见题材：${prompt.split('：')[1].trim()}
核心要素：
${_generateElementsText()}
关键词：${keywords.join('、')}''';

  // 生成核心要素文本
  String _generateElementsText() {
    final buffer = StringBuffer();
    var index = 1;
    elements.forEach((key, values) {
      buffer.writeln('$index. $key：${values.join('、')}');
      index++;
    });
    return buffer.toString().trim();
  }

  // 从JSON创建实例
  factory NovelGenre.fromJson(Map<String, dynamic> json) => NovelGenre(
    name: json['name'],
    description: json['description'],
    prompt: json['prompt'],
    elements: Map<String, List<String>>.from(
      json['elements']?.map((key, value) => MapEntry(
        key,
        (value as List).map((e) => e.toString()).toList(),
      )) ?? {},
    ),
    keywords: List<String>.from(json['keywords'] ?? []),
  );

  // 转换为JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'prompt': prompt,
    'elements': elements,
    'keywords': keywords,
  };

  // 创建副本并更新
  NovelGenre copyWith({
    String? name,
    String? description,
    String? prompt,
    Map<String, List<String>>? elements,
    List<String>? keywords,
  }) {
    return NovelGenre(
      name: name ?? this.name,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      elements: elements ?? Map.from(this.elements),
      keywords: keywords ?? List.from(this.keywords),
    );
  }
}

class GenreCategory {
  final String name;
  final List<NovelGenre> genres;

  const GenreCategory({
    required this.name,
    required this.genres,
  });
}

class GenreCategories {
  static const List<GenreCategory> categories = [
    GenreCategory(
      name: '悬疑复仇',
      genres: [
        NovelGenre(
          name: '校园复仇',
          description: '校园霸凌与复仇的故事',
          prompt: '校园复仇：校园霸凌、权力压制、心理创伤等元素',
          elements: {
            '校园背景': ['高中/大学校园', '社团活动', '校园生活'],
            '霸凌形式': ['暴力', '孤立', '网暴', '权力欺压'],
            '复仇动机': ['创伤经历', '家人伤害', '友情背叛'],
            '复仇手段': ['心理战', '证据收集', '舆论反转'],
            '人物关系': ['受害者', '霸凌者', '旁观者', '帮凶']
          },
          keywords: ['复仇', '正义', '救赎', '反转', '真相'],
        ),
        NovelGenre(
          name: '职场复仇',
          description: '职场陷害与复仇的故事',
          prompt: '职场复仇：职场陷害、商业阴谋、权力斗争等元素',
          elements: {
            '职场环境': ['公司', '办公室', '会议室', '商业场所'],
            '陷害手段': ['栽赃陷害', '商业诈骗', '职位剥夺'],
            '复仇计划': ['商业布局', '证据收集', '身份隐藏'],
            '权力斗争': ['股权争夺', '职位竞争', '商业战争'],
            '人物关系': ['受害者', '加害者', '盟友', '对手']
          },
          keywords: ['阴谋', '权力', '反击', '胜利', '真相'],
        ),
      ],
    ),
    GenreCategory(
      name: '都市现代',
      genres: [
        NovelGenre(
          name: '都市异能',
          description: '都市背景下的超能力故事',
          prompt: '都市异能：重生、系统流、赘婿、神豪等元素',
          elements: {
            '都市背景': ['都市', '超能力', '重生', '系统流', '赘婿', '神豪'],
            '超能力类型': ['异能', '系统', '赘婿', '神豪'],
            '故事类型': ['都市', '现代', '超能力'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['都市', '现代', '未来']
          },
          keywords: ['都市', '现代', '超能力', '重生', '系统流', '赘婿', '神豪'],
        ),
        NovelGenre(
          name: '娱乐圈',
          description: '演艺圈发展故事',
          prompt: '娱乐圈：星探、试镜、爆红、黑料等元素',
          elements: {
            '娱乐圈': ['星探', '试镜', '爆红', '黑料'],
            '故事类型': ['娱乐圈', '演艺圈'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['娱乐圈', '演艺圈', '星探', '试镜', '爆红', '黑料'],
        ),
        NovelGenre(
          name: '职场商战',
          description: '职场或商业竞争故事',
          prompt: '职场商战：升职加薪、商业谈判、公司运营等元素',
          elements: {
            '职场环境': ['职场', '公司', '办公室', '会议室', '商业场所'],
            '竞争类型': ['职场', '商业'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['职场', '商业', '升职加薪', '商业谈判', '公司运营'],
        ),
        NovelGenre(
          name: '亿万富翁',
          description: '富豪人生故事',
          prompt: '亿万富翁：财富积累、商业帝国、豪门生活等元素',
          elements: {
            '富豪': ['亿万富翁', '财富积累', '商业帝国', '豪门生活'],
            '故事类型': ['富豪', '人生'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['亿万富翁', '财富积累', '商业帝国', '豪门生活'],
        ),
      ],
    ),
    GenreCategory(
      name: '玄幻修仙',
      genres: [
        NovelGenre(
          name: '玄幻修仙',
          description: '修真问道的故事',
          prompt: '玄幻修仙：修炼体系、宗门势力、天材地宝等元素',
          elements: {
            '修炼体系': ['玄幻', '修仙', '修炼', '体系', '宗门势力', '天材地宝'],
            '故事类型': ['玄幻', '修仙'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['玄幻', '修仙', '修炼', '体系', '宗门势力', '天材地宝'],
        ),
        NovelGenre(
          name: '重生',
          description: '重获新生的故事',
          prompt: '重生：前世记忆、改变命运、复仇崛起等元素',
          elements: {
            '重生': ['重生', '前世记忆', '改变命运', '复仇崛起'],
            '故事类型': ['重生'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['重生', '前世记忆', '改变命运', '复仇崛起'],
        ),
        NovelGenre(
          name: '系统流',
          description: '获得系统的故事',
          prompt: '系统流：金手指、任务奖励、属性面板等元素',
          elements: {
            '系统流': ['系统', '金手指', '任务奖励', '属性面板'],
            '故事类型': ['系统', '流'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['系统', '金手指', '任务奖励', '属性面板'],
        ),
      ],
    ),
    GenreCategory(
      name: '游戏竞技',
      genres: [
        NovelGenre(
          name: '电竞',
          description: '电子竞技故事',
          prompt: '电竞：职业选手、战队训练、比赛竞技等元素',
          elements: {
            '电竞': ['电竞', '职业选手', '战队训练', '比赛竞技'],
            '故事类型': ['电竞'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['电竞', '职业选手', '战队训练', '比赛竞技'],
        ),
        NovelGenre(
          name: '游戏',
          description: '游戏世界的故事',
          prompt: '游戏：虚拟世界、副本攻略、公会组织等元素',
          elements: {
            '游戏': ['游戏', '虚拟世界', '副本攻略', '公会组织'],
            '故事类型': ['游戏'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['游戏', '虚拟世界', '副本攻略', '公会组织'],
        ),
        NovelGenre(
          name: '无限流',
          description: '轮回闯关的故事',
          prompt: '无限流：任务世界、轮回闯关、积分兑换等元素',
          elements: {
            '无限流': ['无限', '任务世界', '轮回闯关', '积分兑换'],
            '故事类型': ['无限', '流'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['无限', '任务世界', '轮回闯关', '积分兑换'],
        ),
      ],
    ),
    GenreCategory(
      name: '科幻未来',
      genres: [
        NovelGenre(
          name: '末世',
          description: '末日求生的故事',
          prompt: '末世：病毒爆发、丧尸横行、废土重建等元素',
          elements: {
            '末世': ['末世', '病毒爆发', '丧尸横行', '废土重建'],
            '故事类型': ['末世'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['未来', '科幻']
          },
          keywords: ['末世', '病毒爆发', '丧尸横行', '废土重建'],
        ),
        NovelGenre(
          name: '赛博朋克',
          description: '高科技低生活的故事',
          prompt: '赛博朋克：机械改造、黑客技术、巨型企业等元素',
          elements: {
            '赛博朋克': ['赛博朋克', '机械改造', '黑客技术', '巨型企业'],
            '故事类型': ['赛博朋克'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['未来', '科幻']
          },
          keywords: ['赛博朋克', '机械改造', '黑客技术', '巨型企业'],
        ),
        NovelGenre(
          name: '机器人觉醒',
          description: 'AI觉醒的故事',
          prompt: '机器人觉醒：人工智能、机械文明、人机共存等元素',
          elements: {
            '机器人觉醒': ['机器人', '觉醒', '人工智能', '机械文明', '人机共存'],
            '故事类型': ['机器人', '觉醒'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['未来', '科幻']
          },
          keywords: ['机器人', '觉醒', '人工智能', '机械文明', '人机共存'],
        ),
      ],
    ),
    GenreCategory(
      name: '古代历史',
      genres: [
        NovelGenre(
          name: '宫斗',
          description: '后宫争斗的故事',
          prompt: '宫斗：后宫争宠、权谋算计、皇权斗争等元素',
          elements: {
            '宫斗': ['宫斗', '后宫争宠', '权谋算计', '皇权斗争'],
            '故事类型': ['宫斗'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['宫斗', '后宫争宠', '权谋算计', '皇权斗争'],
        ),
        NovelGenre(
          name: '穿越',
          description: '穿越时空的故事',
          prompt: '穿越：时空穿梭、历史改变、文化冲突等元素',
          elements: {
            '穿越': ['穿越', '时空穿梭', '历史改变', '文化冲突'],
            '故事类型': ['穿越'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['穿越', '时空穿梭', '历史改变', '文化冲突'],
        ),
        NovelGenre(
          name: '种田',
          description: '农家生活的故事',
          prompt: '种田：农家生活、乡村发展、生活技能等元素',
          elements: {
            '种田': ['种田', '农家生活', '乡村发展', '生活技能'],
            '故事类型': ['种田'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['种田', '农家生活', '乡村发展', '生活技能'],
        ),
        NovelGenre(
          name: '民国',
          description: '民国时期的故事',
          prompt: '民国：乱世生存、谍战情报、革命斗争等元素',
          elements: {
            '民国': ['民国', '乱世生存', '谍战情报', '革命斗争'],
            '故事类型': ['民国'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['民国', '乱世生存', '谍战情报', '革命斗争'],
        ),
      ],
    ),
    GenreCategory(
      name: '情感',
      genres: [
        NovelGenre(
          name: '言情',
          description: '纯爱故事',
          prompt: '言情：甜宠恋爱、情感纠葛、浪漫邂逅等元素',
          elements: {
            '言情': ['言情', '甜宠恋爱', '情感纠葛', '浪漫邂逅'],
            '故事类型': ['言情'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['言情', '甜宠恋爱', '情感纠葛', '浪漫邂逅'],
        ),
        NovelGenre(
          name: '虐文',
          description: '虐心故事',
          prompt: '虐文：情感折磨、误会纠葛、痛苦救赎等元素',
          elements: {
            '虐文': ['虐文', '情感折磨', '误会纠葛', '痛苦救赎'],
            '故事类型': ['虐文'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['虐文', '情感折磨', '误会纠葛', '痛苦救赎'],
        ),
        NovelGenre(
          name: '禁忌之恋',
          description: '禁忌感情故事',
          prompt: '禁忌之恋：身份差距、伦理冲突、命运阻隔等元素',
          elements: {
            '禁忌之恋': ['禁忌之恋', '身份差距', '伦理冲突', '命运阻隔'],
            '故事类型': ['禁忌之恋'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['禁忌之恋', '身份差距', '伦理冲突', '命运阻隔'],
        ),
        NovelGenre(
          name: '耽美',
          description: '男男感情故事',
          prompt: '耽美：男男情感、相知相守、甜虐交织等元素',
          elements: {
            '耽美': ['耽美', '男男情感', '相知相守', '甜虐交织'],
            '故事类型': ['耽美'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['耽美', '男男情感', '相知相守', '甜虐交织'],
        ),
      ],
    ),
    GenreCategory(
      name: '其他题材',
      genres: [
        NovelGenre(
          name: '灵异',
          description: '灵异故事',
          prompt: '灵异：鬼怪神秘、通灵驱邪、阴阳交界等元素',
          elements: {
            '灵异': ['灵异', '鬼怪神秘', '通灵驱邪', '阴阳交界'],
            '故事类型': ['灵异'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['灵异', '鬼怪神秘', '通灵驱邪', '阴阳交界'],
        ),
        NovelGenre(
          name: '悬疑',
          description: '悬疑推理故事',
          prompt: '悬疑：案件侦破、推理解谜、心理较量等元素',
          elements: {
            '悬疑': ['悬疑', '案件侦破', '推理解谜', '心理较量'],
            '故事类型': ['悬疑'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['悬疑', '案件侦破', '推理解谜', '心理较量'],
        ),
        NovelGenre(
          name: '沙雕',
          description: '搞笑欢乐故事',
          prompt: '沙雕：欢乐搞笑、日常吐槽、轻松愉快等元素',
          elements: {
            '沙雕': ['沙雕', '欢乐搞笑', '日常吐槽', '轻松愉快'],
            '故事类型': ['沙雕'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['古代', '历史']
          },
          keywords: ['沙雕', '欢乐搞笑', '日常吐槽', '轻松愉快'],
        ),
        NovelGenre(
          name: '直播',
          description: '直播生活故事',
          prompt: '直播：网络主播、粉丝互动、直播生态等元素',
          elements: {
            '直播': ['直播', '网络主播', '粉丝互动', '直播生态'],
            '故事类型': ['直播'],
            '主要角色': ['主角', '配角', '反派'],
            '故事背景': ['现代', '都市']
          },
          keywords: ['直播', '网络主播', '粉丝互动', '直播生态'],
        ),
      ],
    ),
  ];

  static List<String> get availableGenres {
    final List<String> genres = [];
    for (var category in categories) {
      for (var genre in category.genres) {
        genres.add(genre.name);
      }
    }
    return genres;
  }

  static NovelGenre? getGenreByName(String name) {
    for (var category in categories) {
      for (var genre in category.genres) {
        if (genre.name == name) {
          return genre;
        }
      }
    }
    return null;
  }

  static String? getTemplateByGenre(String genre) {
    return getGenreByName(genre)?.template;
  }

  static List<String>? getKeywordsByGenre(String genre) {
    return getGenreByName(genre)?.keywords;
  }

  static List<String>? getCoreElementsByGenre(String genre) {
    return getGenreByName(genre)?.elements.values.expand((e) => e).toList();
  }
} 