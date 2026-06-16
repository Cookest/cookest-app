import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config.dart';
import '../features/recipes/screens/food_recipe_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/recipes/screens/recipes_screen.dart';
import '../features/meal_plan/screens/meal_plan_screen.dart';
import '../features/pantry/screens/inventory_screen.dart';
import '../features/shopping_list/screens/shopping_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/subscription/screens/paywall_screen.dart';
import '../features/recipes/screens/recipe_detail_screen.dart';
import '../features/recipes/screens/create_recipe_screen.dart';
import '../features/pantry/screens/grocery_scan_screen.dart';
import '../features/pantry/screens/barcode_scan_screen.dart';
import '../features/meal_plan/screens/recipe_discover_screen.dart';
import '../features/stores/screens/stores_map_screen.dart';
import '../features/stores/screens/store_detail_screen.dart';
import '../features/nutrition/screens/what_to_buy_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provider that configures and exposes the app's [GoRouter].
///
/// Auth guard redirect logic:
/// - Unauthenticated users on a protected route → `/login`.
/// - Authenticated users on `/login` or `/register` → `/`.
/// - `/splash` bypasses all guards.
/// - Demo mode (`AppConfig.isDemoMode`) disables all guards for screenshot capture.
///
/// The router refreshes automatically whenever [authProvider] emits a new state.
final routerProvider = Provider<GoRouter>((ref) {
  final isDemoMode = AppConfig.isDemoMode;
  final router = GoRouter(
    initialLocation: isDemoMode ? '/' : '/splash',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/splash';

      // Demo mode for screenshot capture — skip all auth guards
      if (AppConfig.isDemoMode) return null;

      if (isSplash) return null;
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/recipes/create',
        builder: (context, state) => const CreateRecipeScreen(),
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (context, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/browse/recipes/:id',
        builder: (context, state) => FoodRecipeDetailScreen(
          recipeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/grocery-scan',
        builder: (context, state) => const GroceryScanScreen(),
      ),
      GoRoute(
        path: '/barcode-scan',
        builder: (context, state) => const BarcodeScanScreen(),
      ),
      GoRoute(
        path: '/what-to-buy',
        builder: (context, state) => const WhatToBuyScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const RecipeDiscoverScreen(),
      ),
      GoRoute(
        path: '/stores/:id',
        builder: (context, state) =>
            StoreDetailScreen(storeId: state.pathParameters['id']!),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/meals',
            builder: (context, state) => const MealPlanScreen(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (context, state) => const RecipesScreen(),
          ),
          GoRoute(
            path: '/pantry',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/groceries',
            builder: (context, state) => const ShoppingListScreen(),
          ),
          GoRoute(
            path: '/stores',
            builder: (context, state) => const StoresMapScreen(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (previous, next) => router.refresh());
  return router;
});

class _AppShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _AppShell({required this.location, required this.child});

  static const _tabs = [
    (icon: LucideIcons.home, label: 'Home', path: '/'),
    (icon: LucideIcons.calendarDays, label: 'Meals', path: '/meals'),
    (icon: LucideIcons.bookOpen, label: 'Recipes', path: '/recipes'),
    (icon: LucideIcons.package, label: 'Pantry', path: '/pantry'),
    (icon: LucideIcons.shoppingCart, label: 'Groceries', path: '/groceries'),
    (icon: LucideIcons.mapPin, label: 'Stores', path: '/stores'),
  ];

  int get _currentIndex {
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].path == '/') {
        if (location == '/') return i;
      } else if (location.startsWith(_tabs[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? CookestTokens.colorSurfaceDark
        : CookestTokens.colorSurfaceLight;
    final borderColor = isDark
        ? CookestTokens.colorBorderDark
        : CookestTokens.colorBorderLight;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final isActive = _currentIndex == i;
                final tab = _tabs[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => GoRouter.of(context).go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Icon(
                            tab.icon,
                            key: ValueKey(isActive),
                            size: 22,
                            color: isActive
                                ? CookestTokens.colorPrimaryDEFAULT
                                : (isDark
                                      ? CookestTokens.colorMutedDark
                                      : CookestTokens.colorMutedLight),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isActive
                                ? CookestTokens.colorPrimaryDEFAULT
                                : (isDark
                                      ? CookestTokens.colorMutedDark
                                      : CookestTokens.colorMutedLight),
                          ),
                          child: Text(tab.label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
