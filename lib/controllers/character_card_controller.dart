import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:novel_app/models/character_card.dart';

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
} 