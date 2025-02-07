import 'package:novel_app/models/genre_category.dart';

class GenrePrompts {
  // 获取指定类型的模板
  static String getPromptByGenre(String genre) {
    return GenreCategories.getGenreByName(genre)?.template ?? '';
  }
  
  // 获取指定类型的关键词
  static List<String> getKeywordsByGenre(String genre) {
    return GenreCategories.getGenreByName(genre)?.keywords ?? [];
  }
  
  // 获取指定类型的核心要素
  static Map<String, List<String>> getElementsByGenre(String genre) {
    return GenreCategories.getGenreByName(genre)?.elements ?? {};
  }
  
  // 获取所有可用的类型
  static List<String> get availableGenres {
    return GenreCategories.availableGenres;
  }
} 