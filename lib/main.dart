import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:novel_app/controllers/api_config_controller.dart';
import 'package:novel_app/controllers/novel_controller.dart';
import 'package:novel_app/controllers/character_card_controller.dart';
import 'package:novel_app/screens/home/home_screen.dart';
import 'package:novel_app/screens/storage/storage_screen.dart';
import 'package:novel_app/screens/chapter_detail/chapter_detail_screen.dart';
import 'package:novel_app/screens/chapter_edit/chapter_edit_screen.dart';
import 'package:novel_app/screens/draft/draft_screen.dart';
import 'package:novel_app/services/ai_service.dart';
import 'package:novel_app/services/novel_generator_service.dart';
import 'package:novel_app/models/prompt_template.dart';
import 'package:novel_app/services/content_review_service.dart';
import 'package:novel_app/services/announcement_service.dart';
import 'package:novel_app/screens/announcement_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novel_app/services/cache_service.dart';
import 'package:novel_app/models/novel.dart';
import 'package:novel_app/controllers/theme_controller.dart';
import 'package:novel_app/controllers/draft_controller.dart';
import 'package:novel_app/services/license_service.dart';
import 'package:novel_app/screens/license_screen.dart';
import 'package:novel_app/controllers/genre_controller.dart';
import 'package:novel_app/screens/genre_manager_screen.dart';
import 'package:novel_app/controllers/style_controller.dart';
import 'package:novel_app/controllers/outline_prompt_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await Hive.initFlutter();

  // 初始化SharedPreferences（确保最先初始化）
  final prefs = await SharedPreferences.getInstance();
  Get.put(prefs);
  
  // 初始化主题控制器
  Get.put(ThemeController());
  
  // 初始化基础服务
  final apiConfig = Get.put(ApiConfigController());
  final aiService = Get.put(AIService(apiConfig));
  final cacheService = Get.put(CacheService(prefs));

  // 运行应用
  runApp(const MyApp());

  // 延迟初始化其他服务
  Future.delayed(const Duration(milliseconds: 100), () async {
    // 初始化其他控制器和服务
    final outlinePromptController = OutlinePromptController();
    await outlinePromptController.init();
    Get.put(outlinePromptController);
    
    Get.put(CharacterCardController());
    Get.put(NovelGeneratorService(aiService, apiConfig, cacheService));
    Get.put(ContentReviewService(aiService, apiConfig, cacheService));
    Get.put(NovelController());
    Get.put(DraftController());
    Get.put(GenreController());
    Get.put(StyleController());
    
    // 初始化公告服务
    final announcementService = Get.put(AnnouncementService());
    await announcementService.init();
    
    // 检查公告
    if (announcementService.announcement.value != null) {
      Get.dialog(
        AnnouncementScreen(announcement: announcementService.announcement.value!),
        barrierDismissible: false,
      );
    }

    // Web平台特定初始化
    if (kIsWeb) {
      final licenseService = LicenseService();
      await licenseService.init();
      Get.put(licenseService);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '岱宗文脉',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 100),
      initialBinding: BindingsBuilder(() {
        Get.put(ThemeController());
        Get.put(NovelController());
      }),
      routingCallback: (routing) {
        if (routing?.current == '/') {
          Get.toNamed('/storage', preventDuplicates: false);
          Get.back();
        }
      },
      home: kIsWeb  // 只在Web平台检查许可证
          ? Obx(() {
              final licenseService = Get.find<LicenseService>();
              return licenseService.isLicensed.value
                  ? const HomeScreen()  // 已激活许可证，显示主页
                  : LicenseScreen();    // 未激活许可证，显示激活页面
            })
          : const HomeScreen(),  // 非Web平台直接显示主页
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/storage', page: () => StorageScreen()),
        GetPage(name: '/chapter_detail', page: () => ChapterDetailScreen()),
        GetPage(name: '/chapter_edit', page: () => ChapterEditScreen()),
        GetPage(name: '/draft', page: () => DraftScreen()),
      ],
    );
  }
}