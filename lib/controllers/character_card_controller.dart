import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:novel_app/models/character_card.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CharacterCardController extends GetxController {
  final _prefs = Get.find<SharedPreferences>();
  final String _cardsKey = 'character_cards';
  final RxList<CharacterCard> cards = <CharacterCard>[].obs;
  final Rx<CharacterCard?> selectedCard = Rx<CharacterCard?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadCards();
  }

  void _loadCards() {
    try {
      final cardsJson = _prefs.getString(_cardsKey);
      if (cardsJson != null) {
        final List<dynamic> cardsList = jsonDecode(cardsJson);
        cards.value = cardsList
            .map((json) => CharacterCard.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (e) {
      print('加载角色卡片失败: $e');
    }
  }

  Future<void> _saveCards() async {
    try {
      final cardsJson = jsonEncode(
        cards.map((card) => card.toJson()).toList(),
      );
      await _prefs.setString(_cardsKey, cardsJson);
    } catch (e) {
      print('保存角色卡片失败: $e');
      rethrow;
    }
  }

  Future<void> addCard(CharacterCard card) async {
    try {
      cards.add(card);
      await _saveCards();
    } catch (e) {
      print('添加角色卡片失败: $e');
      rethrow;
    }
  }

  Future<void> updateCard(CharacterCard card) async {
    try {
      final index = cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        cards[index] = card;
        await _saveCards();
      }
    } catch (e) {
      print('更新角色卡片失败: $e');
      rethrow;
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      cards.removeWhere((card) => card.id == id);
      await _saveCards();
    } catch (e) {
      print('删除角色卡片失败: $e');
      rethrow;
    }
  }

  CharacterCard? getCard(String id) {
    return cards.firstWhereOrNull((card) => card.id == id);
  }

  void setSelectedCard(String? id) {
    if (id == null) {
      selectedCard.value = null;
    } else {
      selectedCard.value = getCard(id);
    }
  }

  CharacterCard createNewCard(String name) {
    return CharacterCard(
      id: const Uuid().v4(),
      name: name,
    );
  }

  // 导出所有角色卡片
  Future<String> exportAllCards() async {
    try {
      final cardsJson = jsonEncode(
        cards.map((card) => card.toJson()).toList(),
      );

      if (kIsWeb) {
        // Web平台直接返回JSON字符串
        return cardsJson;
      } else {
        // 移动平台保存到文件
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/character_cards_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(cardsJson);
        return file.path;
      }
    } catch (e) {
      print('导出角色卡片失败: $e');
      rethrow;
    }
  }

  // 导出选中的角色卡片
  Future<String> exportSelectedCards(List<String> cardIds) async {
    try {
      final selectedCards = cards.where((card) => cardIds.contains(card.id)).toList();
      final cardsJson = jsonEncode(
        selectedCards.map((card) => card.toJson()).toList(),
      );

      if (kIsWeb) {
        return cardsJson;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/character_cards_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(cardsJson);
        return file.path;
      }
    } catch (e) {
      print('导出选中角色卡片失败: $e');
      rethrow;
    }
  }

  // 导入角色卡片
  Future<int> importCards(String jsonContent) async {
    try {
      final List<dynamic> cardsList = jsonDecode(jsonContent);
      final List<CharacterCard> newCards = cardsList
          .map((json) => CharacterCard.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      // 为导入的卡片生成新的ID，避免冲突
      for (var card in newCards) {
        final existingCard = cards.firstWhereOrNull((c) => c.name == card.name);
        if (existingCard == null) {
          final newCard = CharacterCard(
            id: const Uuid().v4(),
            name: card.name,
            gender: card.gender,
            age: card.age,
            species: card.species,
            bodyType: card.bodyType,
            facialFeatures: card.facialFeatures,
            clothingStyle: card.clothingStyle,
            accessories: card.accessories,
            personality: card.personality,
            personalityComplexity: card.personalityComplexity,
            personalityFormation: card.personalityFormation,
            background: card.background,
            lifeExperience: card.lifeExperience,
            pastEvents: card.pastEvents,
            shortTermGoals: card.shortTermGoals,
            longTermGoals: card.longTermGoals,
            motivation: card.motivation,
            specialAbilities: card.specialAbilities,
            normalSkills: card.normalSkills,
            family: card.family,
            friends: card.friends,
            enemies: card.enemies,
            lovers: card.lovers,
          );
          cards.add(newCard);
        }
      }
      
      await _saveCards();
      return newCards.length;
    } catch (e) {
      print('导入角色卡片失败: $e');
      rethrow;
    }
  }

  // 从文件导入角色卡片
  Future<int> importCardsFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String jsonContent;
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          if (bytes == null) throw Exception('无法读取文件内容');
          jsonContent = utf8.decode(bytes);
        } else {
          final file = File(result.files.first.path!);
          jsonContent = await file.readAsString();
        }
        
        return await importCards(jsonContent);
      }
      return 0;
    } catch (e) {
      print('从文件导入角色卡片失败: $e');
      rethrow;
    }
  }
} 