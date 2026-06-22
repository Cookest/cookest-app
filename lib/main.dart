import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'src/core/config.dart';
import 'src/core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(
    const ProviderScope(
      child: CookestApp(),
    ),
  );
}

/// Root widget of the Cookest application.
///
/// Wraps [MaterialApp.router] with design-system themes from [CookestTheme]
/// and delegates routing to [routerProvider]. Always rendered inside a
/// [ProviderScope] so that all Riverpod providers are accessible.
class CookestApp extends ConsumerWidget {
  const CookestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cookest',
      debugShowCheckedModeBanner: false,
      theme: CookestTheme.light,
      darkTheme: CookestTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
