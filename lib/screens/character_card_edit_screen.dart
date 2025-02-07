import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel_app/models/character_card.dart';
import 'package:novel_app/controllers/character_card_controller.dart';

class CharacterCardEditScreen extends StatefulWidget {
  final String? cardId;

  const CharacterCardEditScreen({Key? key, this.cardId}) : super(key: key);

  @override
  _CharacterCardEditScreenState createState() => _CharacterCardEditScreenState();
}

class _CharacterCardEditScreenState extends State<CharacterCardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<CharacterCardController>();
  late CharacterCard _card;
  
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _speciesController = TextEditingController();
  final _bodyTypeController = TextEditingController();
  final _facialFeaturesController = TextEditingController();
  final _clothingStyleController = TextEditingController();
  final _accessoriesController = TextEditingController();
  final _personalityController = TextEditingController();
  final _personalityComplexityController = TextEditingController();
  final _personalityFormationController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _lifeExperienceController = TextEditingController();
  final _pastEventsController = TextEditingController();
  final _shortTermGoalsController = TextEditingController();
  final _longTermGoalsController = TextEditingController();
  final _motivationController = TextEditingController();
  final _specialAbilitiesController = TextEditingController();
  final _normalSkillsController = TextEditingController();
  final _familyController = TextEditingController();
  final _friendsController = TextEditingController();
  final _enemiesController = TextEditingController();
  final _loversController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null) {
      _card = _controller.getCard(widget.cardId!)!;
      _initializeControllers();
    } else {
      _card = _controller.createNewCard('');
    }
  }

  void _initializeControllers() {
    _nameController.text = _card.name;
    _genderController.text = _card.gender ?? '';
    _ageController.text = _card.age?.toString() ?? '';
    _speciesController.text = _card.species ?? '';
    _bodyTypeController.text = _card.bodyType ?? '';
    _facialFeaturesController.text = _card.facialFeatures ?? '';
    _clothingStyleController.text = _card.clothingStyle ?? '';
    _accessoriesController.text = _card.accessories ?? '';
    _personalityController.text = _card.personality ?? '';
    _personalityComplexityController.text = _card.personalityComplexity ?? '';
    _personalityFormationController.text = _card.personalityFormation ?? '';
    _backgroundController.text = _card.background ?? '';
    _lifeExperienceController.text = _card.lifeExperience ?? '';
    _pastEventsController.text = _card.pastEvents ?? '';
    _shortTermGoalsController.text = _card.shortTermGoals ?? '';
    _longTermGoalsController.text = _card.longTermGoals ?? '';
    _motivationController.text = _card.motivation ?? '';
    _specialAbilitiesController.text = _card.specialAbilities ?? '';
    _normalSkillsController.text = _card.normalSkills ?? '';
    _familyController.text = _card.family ?? '';
    _friendsController.text = _card.friends ?? '';
    _enemiesController.text = _card.enemies ?? '';
    _loversController.text = _card.lovers ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _speciesController.dispose();
    _bodyTypeController.dispose();
    _facialFeaturesController.dispose();
    _clothingStyleController.dispose();
    _accessoriesController.dispose();
    _personalityController.dispose();
    _personalityComplexityController.dispose();
    _personalityFormationController.dispose();
    _backgroundController.dispose();
    _lifeExperienceController.dispose();
    _pastEventsController.dispose();
    _shortTermGoalsController.dispose();
    _longTermGoalsController.dispose();
    _motivationController.dispose();
    _specialAbilitiesController.dispose();
    _normalSkillsController.dispose();
    _familyController.dispose();
    _friendsController.dispose();
    _enemiesController.dispose();
    _loversController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedCard = CharacterCard(
      id: _card.id,
      name: _nameController.text,
      gender: _genderController.text.isEmpty ? null : _genderController.text,
      age: int.tryParse(_ageController.text),
      species: _speciesController.text.isEmpty ? null : _speciesController.text,
      bodyType: _bodyTypeController.text.isEmpty ? null : _bodyTypeController.text,
      facialFeatures: _facialFeaturesController.text.isEmpty ? null : _facialFeaturesController.text,
      clothingStyle: _clothingStyleController.text.isEmpty ? null : _clothingStyleController.text,
      accessories: _accessoriesController.text.isEmpty ? null : _accessoriesController.text,
      personality: _personalityController.text.isEmpty ? null : _personalityController.text,
      personalityComplexity: _personalityComplexityController.text.isEmpty ? null : _personalityComplexityController.text,
      personalityFormation: _personalityFormationController.text.isEmpty ? null : _personalityFormationController.text,
      background: _backgroundController.text.isEmpty ? null : _backgroundController.text,
      lifeExperience: _lifeExperienceController.text.isEmpty ? null : _lifeExperienceController.text,
      pastEvents: _pastEventsController.text.isEmpty ? null : _pastEventsController.text,
      shortTermGoals: _shortTermGoalsController.text.isEmpty ? null : _shortTermGoalsController.text,
      longTermGoals: _longTermGoalsController.text.isEmpty ? null : _longTermGoalsController.text,
      motivation: _motivationController.text.isEmpty ? null : _motivationController.text,
      specialAbilities: _specialAbilitiesController.text.isEmpty ? null : _specialAbilitiesController.text,
      normalSkills: _normalSkillsController.text.isEmpty ? null : _normalSkillsController.text,
      family: _familyController.text.isEmpty ? null : _familyController.text,
      friends: _friendsController.text.isEmpty ? null : _friendsController.text,
      enemies: _enemiesController.text.isEmpty ? null : _enemiesController.text,
      lovers: _loversController.text.isEmpty ? null : _loversController.text,
    );

    if (widget.cardId != null) {
      await _controller.updateCard(updatedCard);
    } else {
      await _controller.addCard(updatedCard);
    }

    Get.back();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '请输入$label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardId != null ? '编辑角色卡片' : '新建角色卡片'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  '基本信息',
                  [
                    _buildTextField('角色名称', _nameController, isRequired: true),
                    _buildTextField('性别', _genderController),
                    _buildTextField('年龄', _ageController),
                    _buildTextField('种族/物种', _speciesController),
                  ],
                ),
                _buildSection(
                  '外貌特征',
                  [
                    _buildTextField('体型', _bodyTypeController),
                    _buildTextField('面部特征', _facialFeaturesController, maxLines: 3),
                    _buildTextField('服装风格', _clothingStyleController, maxLines: 3),
                    _buildTextField('标志性配饰', _accessoriesController),
                  ],
                ),
                _buildSection(
                  '性格特征',
                  [
                    _buildTextField('主要性格倾向', _personalityController),
                    _buildTextField('性格的复杂性', _personalityComplexityController, maxLines: 3),
                    _buildTextField('性格形成原因', _personalityFormationController, maxLines: 3),
                  ],
                ),
                _buildSection(
                  '背景故事',
                  [
                    _buildTextField('出生和成长环境', _backgroundController, maxLines: 3),
                    _buildTextField('重要的人生经历', _lifeExperienceController, maxLines: 3),
                    _buildTextField('与主要情节相关的过去事件', _pastEventsController, maxLines: 3),
                  ],
                ),
                _buildSection(
                  '目标和动机',
                  [
                    _buildTextField('短期目标', _shortTermGoalsController),
                    _buildTextField('长期目标', _longTermGoalsController),
                    _buildTextField('动机', _motivationController, maxLines: 3),
                  ],
                ),
                _buildSection(
                  '能力和技能',
                  [
                    _buildTextField('特殊能力', _specialAbilitiesController, maxLines: 3),
                    _buildTextField('普通技能', _normalSkillsController, maxLines: 3),
                  ],
                ),
                _buildSection(
                  '人际关系',
                  [
                    _buildTextField('家人', _familyController, maxLines: 3),
                    _buildTextField('朋友', _friendsController, maxLines: 3),
                    _buildTextField('敌人', _enemiesController, maxLines: 3),
                    _buildTextField('恋人/情人', _loversController, maxLines: 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 