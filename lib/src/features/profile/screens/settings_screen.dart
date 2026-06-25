import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:cookest/src/core/theme/theme_provider.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/profile.dart';
import '../repositories/profile_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _householdController = TextEditingController();
  final _dietaryController = TextEditingController();
  final _allergiesController = TextEditingController();
  bool _saving = false;
  bool _resettingTaste = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _householdController.dispose();
    _dietaryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _hydrateForm(UserProfile profile) {
    if (_hydrated) return;
    _nameController.text = profile.name;
    _householdController.text = profile.householdSize.toString();
    _dietaryController.text = profile.dietaryRestrictions.join(', ');
    _allergiesController.text = profile.allergies.join(', ');
    _hydrated = true;
  }

  List<String> _csvToList(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    final householdSize = int.tryParse(_householdController.text.trim());
    if (householdSize == null || householdSize < 1 || householdSize > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household size must be between 1 and 50.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'name': _nameController.text.trim(),
        'household_size': householdSize,
        'dietary_restrictions': _csvToList(_dietaryController.text),
        'allergies': _csvToList(_allergiesController.text),
      });
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetTaste() async {
    if (_resettingTaste) return;
    setState(() => _resettingTaste = true);
    try {
      await ref.read(profileRepositoryProvider).resetTastePreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taste preferences reset.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset taste preferences: $e')),
      );
    } finally {
      if (mounted) setState(() => _resettingTaste = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: CkAlert(
            variant: CkAlertVariant.error,
            child: Text('Failed to load settings: $e'),
          ),
        ),
        data: (profile) {
          _hydrateForm(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CkCard(
                  padding: CkCardPadding.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CkInput(
                        controller: _nameController,
                        label: 'Name',
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      CkInput(
                        controller: _householdController,
                        label: 'Household size',
                        keyboardType: TextInputType.number,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      CkInput(
                        controller: _dietaryController,
                        label: 'Dietary restrictions',
                        placeholder: 'vegetarian, gluten_free',
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      CkInput(
                        controller: _allergiesController,
                        label: 'Allergies',
                        placeholder: 'nuts, shellfish',
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CkCard(
                  padding: CkCardPadding.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.appHeading,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferred theme mode.',
                        style: TextStyle(color: context.appMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CkButton(
                              variant: themeMode == ThemeMode.light
                                  ? CkButtonVariant.primary
                                  : CkButtonVariant.secondary,
                              size: CkButtonSize.sm,
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.light),
                              child: const Text('Light'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CkButton(
                              variant: themeMode == ThemeMode.dark
                                  ? CkButtonVariant.primary
                                  : CkButtonVariant.secondary,
                              size: CkButtonSize.sm,
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.dark),
                              child: const Text('Dark'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CkButton(
                              variant: themeMode == ThemeMode.system
                                  ? CkButtonVariant.primary
                                  : CkButtonVariant.secondary,
                              size: CkButtonSize.sm,
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.system),
                              child: const Text('System'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CkCard(
                  padding: CkCardPadding.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'AI personalization',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.appHeading,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reset learned taste signals to retrain recommendations from scratch.',
                        style: TextStyle(color: context.appMuted),
                      ),
                      const SizedBox(height: 12),
                      CkButton(
                        variant: CkButtonVariant.secondary,
                        loading: _resettingTaste,
                        onPressed: _resettingTaste ? null : _resetTaste,
                        child: const Text('Reset taste preferences'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CkCard(
                  padding: CkCardPadding.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Onboarding',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.appHeading,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redo onboarding to reconfigure your dietary and cooking preferences.',
                        style: TextStyle(color: context.appMuted),
                      ),
                      const SizedBox(height: 12),
                      CkButton(
                        variant: CkButtonVariant.secondary,
                        onPressed: () => context.push('/onboarding'),
                        child: const Text('Redo onboarding'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CkButton(
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                  child: const Text('Save settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
