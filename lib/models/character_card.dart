import 'dart:convert';

class CharacterCard {
  final String id; // 唯一标识
  final String name; // 角色名称
  String? gender; // 性别
  int? age; // 年龄
  String? species; // 种族/物种
  
  // 外貌特征
  String? bodyType; // 体型
  String? facialFeatures; // 面部特征
  String? clothingStyle; // 服装风格
  String? accessories; // 标志性配饰
  
  // 性格特征
  String? personality; // 主要性格倾向
  String? personalityComplexity; // 性格的复杂性
  String? personalityFormation; // 性格形成原因
  
  // 背景故事
  String? background; // 出生和成长环境
  String? lifeExperience; // 重要的人生经历
  String? pastEvents; // 与主要情节相关的过去事件
  
  // 目标和动机
  String? shortTermGoals; // 短期目标
  String? longTermGoals; // 长期目标
  String? motivation; // 动机
  
  // 能力和技能
  String? specialAbilities; // 特殊能力
  String? normalSkills; // 普通技能
  
  // 人际关系
  String? family; // 家人
  String? friends; // 朋友
  String? enemies; // 敌人
  String? lovers; // 恋人/情人
  
  DateTime createdAt; // 创建时间
  DateTime updatedAt; // 更新时间

  CharacterCard({
    required this.id,
    required this.name,
    this.gender,
    this.age,
    this.species,
    this.bodyType,
    this.facialFeatures,
    this.clothingStyle,
    this.accessories,
    this.personality,
    this.personalityComplexity,
    this.personalityFormation,
    this.background,
    this.lifeExperience,
    this.pastEvents,
    this.shortTermGoals,
    this.longTermGoals,
    this.motivation,
    this.specialAbilities,
    this.normalSkills,
    this.family,
    this.friends,
    this.enemies,
    this.lovers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // 从JSON创建实例
  factory CharacterCard.fromJson(Map<String, dynamic> json) => CharacterCard(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    age: json['age'],
    species: json['species'],
    bodyType: json['bodyType'],
    facialFeatures: json['facialFeatures'],
    clothingStyle: json['clothingStyle'],
    accessories: json['accessories'],
    personality: json['personality'],
    personalityComplexity: json['personalityComplexity'],
    personalityFormation: json['personalityFormation'],
    background: json['background'],
    lifeExperience: json['lifeExperience'],
    pastEvents: json['pastEvents'],
    shortTermGoals: json['shortTermGoals'],
    longTermGoals: json['longTermGoals'],
    motivation: json['motivation'],
    specialAbilities: json['specialAbilities'],
    normalSkills: json['normalSkills'],
    family: json['family'],
    friends: json['friends'],
    enemies: json['enemies'],
    lovers: json['lovers'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  // 转换为JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'age': age,
    'species': species,
    'bodyType': bodyType,
    'facialFeatures': facialFeatures,
    'clothingStyle': clothingStyle,
    'accessories': accessories,
    'personality': personality,
    'personalityComplexity': personalityComplexity,
    'personalityFormation': personalityFormation,
    'background': background,
    'lifeExperience': lifeExperience,
    'pastEvents': pastEvents,
    'shortTermGoals': shortTermGoals,
    'longTermGoals': longTermGoals,
    'motivation': motivation,
    'specialAbilities': specialAbilities,
    'normalSkills': normalSkills,
    'family': family,
    'friends': friends,
    'enemies': enemies,
    'lovers': lovers,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // 创建副本并更新
  CharacterCard copyWith({
    String? name,
    String? gender,
    int? age,
    String? species,
    String? bodyType,
    String? facialFeatures,
    String? clothingStyle,
    String? accessories,
    String? personality,
    String? personalityComplexity,
    String? personalityFormation,
    String? background,
    String? lifeExperience,
    String? pastEvents,
    String? shortTermGoals,
    String? longTermGoals,
    String? motivation,
    String? specialAbilities,
    String? normalSkills,
    String? family,
    String? friends,
    String? enemies,
    String? lovers,
  }) {
    return CharacterCard(
      id: this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      species: species ?? this.species,
      bodyType: bodyType ?? this.bodyType,
      facialFeatures: facialFeatures ?? this.facialFeatures,
      clothingStyle: clothingStyle ?? this.clothingStyle,
      accessories: accessories ?? this.accessories,
      personality: personality ?? this.personality,
      personalityComplexity: personalityComplexity ?? this.personalityComplexity,
      personalityFormation: personalityFormation ?? this.personalityFormation,
      background: background ?? this.background,
      lifeExperience: lifeExperience ?? this.lifeExperience,
      pastEvents: pastEvents ?? this.pastEvents,
      shortTermGoals: shortTermGoals ?? this.shortTermGoals,
      longTermGoals: longTermGoals ?? this.longTermGoals,
      motivation: motivation ?? this.motivation,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      normalSkills: normalSkills ?? this.normalSkills,
      family: family ?? this.family,
      friends: friends ?? this.friends,
      enemies: enemies ?? this.enemies,
      lovers: lovers ?? this.lovers,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 