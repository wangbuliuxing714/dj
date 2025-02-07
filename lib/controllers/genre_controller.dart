import 'dart:convert';
import 'package:get/get.dart';
import 'package:novel_app/models/genre_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenreController extends GetxController {
  final RxList<GenreCategory> categories = <GenreCategory>[].obs;
  final _prefs = Get.find<SharedPreferences>();
  final String _customGenresKey = 'custom_genres';
  
  // 默认类型列表
  final List<GenreCategory> _defaultCategories = GenreCategories.categories;

  @override
  void onInit() {
    super.onInit();
    _loadGenres();
  }

  // 加载类型数据
  void _loadGenres() {
    try {
      // 清空当前列表
      categories.clear();
      print('开始加载类型数据');
      
      // 首先加载默认类型
      print('加载默认类型...');
      categories.addAll(_defaultCategories);
      print('已加载 ${_defaultCategories.length} 个默认分类');
      
      // 然后加载自定义类型
      final customGenresJson = _prefs.getString(_customGenresKey);
      if (customGenresJson != null) {
        print('发现自定义类型数据，开始加载...');
        final List<dynamic> customGenresList = jsonDecode(customGenresJson);
        final List<GenreCategory> customCategories = customGenresList
            .map((json) => GenreCategory(
                  name: json['name'],
                  genres: (json['genres'] as List)
                      .map((g) => NovelGenre.fromJson(g))
                      .toList(),
                ))
            .toList();
        
        // 验证自定义类型的有效性
        for (var category in customCategories) {
          print('验证自定义分类：${category.name}');
          if (_validateCategory(category)) {
            if (!_isDefaultCategory(category.name)) {
              categories.add(category);
              print('成功添加自定义分类：${category.name}');
            } else {
              print('跳过默认分类：${category.name}');
            }
          } else {
            print('警告：类型 ${category.name} 验证失败，已跳过');
          }
        }
        print('自定义类型加载完成');
      } else {
        print('未发现自定义类型数据');
      }
      
      print('类型数据加载完成，共 ${categories.length} 个分类');
    } catch (e, stackTrace) {
      print('加载类型数据失败: $e');
      print('错误堆栈: $stackTrace');
      // 确保至少加载默认类型
      if (categories.isEmpty) {
        print('加载失败，重新加载默认类型');
        categories.addAll(_defaultCategories);
      }
    }
  }

  // 保存自定义类型
  Future<void> _saveCustomGenres() async {
    try {
      final customCategories = categories
          .where((category) => !_isDefaultCategory(category.name))
          .toList();
      
      final customGenresJson = jsonEncode(customCategories
          .map((category) => {
                'name': category.name,
                'genres': category.genres
                    .map((genre) => genre.toJson())
                    .toList(),
              })
          .toList());
      
      await _prefs.setString(_customGenresKey, customGenresJson);
    } catch (e, stackTrace) {
      print('保存自定义类型失败: $e');
      print('错误堆栈: $stackTrace');
      rethrow;
    }
  }

  // 验证类型数据的有效性
  bool _validateCategory(GenreCategory category) {
    if (category.name.isEmpty) return false;
    if (category.genres.isEmpty) return false;
    
    return category.genres.every((genre) => 
      genre.name.isNotEmpty &&
      genre.description.isNotEmpty &&
      genre.prompt.isNotEmpty &&
      genre.elements.isNotEmpty &&
      genre.keywords.isNotEmpty
    );
  }

  // 检查类型名称是否已存在（跨分类检查）
  bool _isGenreNameExists(String genreName, {int? excludeCategoryIndex}) {
    for (var i = 0; i < categories.length; i++) {
      if (excludeCategoryIndex != null && i == excludeCategoryIndex) continue;
      if (categories[i].genres.any((g) => g.name == genreName)) {
        return true;
      }
    }
    return false;
  }

  bool _isDefaultCategory(String categoryName) {
    return _defaultCategories.any((category) => category.name == categoryName);
  }

  bool isDefaultCategory(String categoryName) {
    return _isDefaultCategory(categoryName);
  }

  bool isDefaultGenre(String categoryName, String genreName) {
    print('检查是否为默认类型 - 分类：$categoryName，类型：$genreName');
    // 在默认类型列表中查找对应的分类
    final defaultCategory = _defaultCategories
        .firstWhereOrNull((category) => category.name == categoryName);
    
    if (defaultCategory == null) {
      print('未找到对应的默认分类');
      return false;
    }
    
    // 在该分类下查找对应的类型
    final isDefault = defaultCategory.genres
        .any((genre) => genre.name == genreName);
    
    print('是否为默认类型：$isDefault');
    return isDefault;
  }

  // 添加新分类
  Future<bool> addCategory(GenreCategory category) async {
    try {
      if (!_validateCategory(category)) {
        print('类型数据验证失败');
        return false;
      }
      
      if (categories.any((c) => c.name == category.name)) {
        print('分类名称已存在');
        return false;
      }
      
      // 检查分类下的所有类型名称是否有重复
      for (var genre in category.genres) {
        if (_isGenreNameExists(genre.name)) {
          print('类型名称 ${genre.name} 已存在于其他分类中');
          return false;
        }
      }
      
      categories.add(category);
      await _saveCustomGenres();
      return true;
    } catch (e) {
      print('添加分类失败: $e');
      return false;
    }
  }

  // 删除分类
  Future<bool> deleteCategory(int index) async {
    try {
      final category = categories[index];
      if (!_isDefaultCategory(category.name)) {
        categories.removeAt(index);
        await _saveCustomGenres();
        return true;
      }
      return false;
    } catch (e) {
      print('删除分类失败: $e');
      return false;
    }
  }

  // 添加类型
  Future<bool> addGenre(int categoryIndex, NovelGenre genre) async {
    try {
      // 验证数据
      if (genre.name.isEmpty || 
          genre.description.isEmpty || 
          genre.prompt.isEmpty ||
          genre.elements.isEmpty ||
          genre.keywords.isEmpty) {
        print('类型数据不完整');
        return false;
      }
      
      // 检查名称是否重复
      if (_isGenreNameExists(genre.name)) {
        print('类型名称已存在');
        return false;
      }
      
      final category = categories[categoryIndex];
      final updatedGenres = List<NovelGenre>.from(category.genres)..add(genre);
      categories[categoryIndex] = GenreCategory(
        name: category.name,
        genres: updatedGenres,
      );
      await _saveCustomGenres();
      return true;
    } catch (e) {
      print('添加类型失败: $e');
      return false;
    }
  }

  // 更新类型
  Future<bool> updateGenre(int categoryIndex, int genreIndex, NovelGenre newGenre) async {
    try {
      final category = categories[categoryIndex];
      final oldGenre = category.genres[genreIndex];
      
      print('开始更新类型：${oldGenre.name} -> ${newGenre.name}');
      
      // 验证数据
      if (newGenre.name.isEmpty) {
        print('类型名称不能为空');
        return false;
      }
      if (newGenre.description.isEmpty) {
        print('类型描述不能为空');
        return false;
      }
      if (newGenre.prompt.isEmpty) {
        print('提示词不能为空');
        return false;
      }
      if (newGenre.elements.isEmpty) {
        print('核心要素不能为空');
        return false;
      }
      if (newGenre.keywords.isEmpty) {
        print('关键词不能为空');
        return false;
      }
      
      // 如果是默认类型，不允许修改
      final isDefault = isDefaultGenre(category.name, oldGenre.name);
      print('检查是否为默认类型：$isDefault');
      if (isDefault) {
        print('默认类型不可修改：${oldGenre.name}');
        return false;
      }
      
      // 如果修改了名称，检查新名称是否重复
      if (oldGenre.name != newGenre.name) {
        print('检查新名称是否重复：${newGenre.name}');
        // 检查同一分类中是否有重复
        final hasDuplicateInSameCategory = category.genres
            .where((g) => g != oldGenre)
            .any((g) => g.name == newGenre.name);
        if (hasDuplicateInSameCategory) {
          print('同一分类中已存在相同名称的类型');
          return false;
        }
        
        // 检查其他分类中是否有重复
        if (_isGenreNameExists(newGenre.name, excludeCategoryIndex: categoryIndex)) {
          print('其他分类中已存在相同名称的类型');
          return false;
        }
      }
      
      print('验证通过，开始更新类型数据');
      final updatedGenres = List<NovelGenre>.from(category.genres);
      updatedGenres[genreIndex] = newGenre;
      categories[categoryIndex] = GenreCategory(
        name: category.name,
        genres: updatedGenres,
      );
      
      print('保存更新后的数据');
      await _saveCustomGenres();
      print('类型更新成功');
      return true;
    } catch (e, stackTrace) {
      print('更新类型失败: $e');
      print('错误堆栈: $stackTrace');
      return false;
    }
  }

  // 删除类型
  Future<bool> deleteGenre(int categoryIndex, int genreIndex) async {
    try {
      final category = categories[categoryIndex];
      final genre = category.genres[genreIndex];
      
      if (isDefaultGenre(category.name, genre.name)) {
        print('默认类型不可删除');
        return false;
      }
      
      final updatedGenres = List<NovelGenre>.from(category.genres)
        ..removeAt(genreIndex);
      categories[categoryIndex] = GenreCategory(
        name: category.name,
        genres: updatedGenres,
      );
      await _saveCustomGenres();
      return true;
    } catch (e) {
      print('删除类型失败: $e');
      return false;
    }
  }

  // 获取指定类型的模板
  String? getTemplateByGenre(String genreName) {
    try {
      for (var category in categories) {
        final genre = category.genres.firstWhereOrNull((g) => g.name == genreName);
        if (genre != null) {
          return genre.template;
        }
      }
      return null;
    } catch (e) {
      print('获取类型模板失败: $e');
      return null;
    }
  }

  // 获取指定类型的关键词
  List<String>? getKeywordsByGenre(String genreName) {
    try {
      for (var category in categories) {
        final genre = category.genres.firstWhereOrNull((g) => g.name == genreName);
        if (genre != null) {
          return genre.keywords;
        }
      }
      return null;
    } catch (e) {
      print('获取类型关键词失败: $e');
      return null;
    }
  }

  // 获取指定类型的核心要素
  Map<String, List<String>>? getElementsByGenre(String genreName) {
    try {
      for (var category in categories) {
        final genre = category.genres.firstWhereOrNull((g) => g.name == genreName);
        if (genre != null) {
          return genre.elements;
        }
      }
      return null;
    } catch (e) {
      print('获取类型核心要素失败: $e');
      return null;
    }
  }
} 