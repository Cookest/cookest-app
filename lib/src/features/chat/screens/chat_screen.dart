import 'dart:math' as math;

import 'package:cookest/src/features/meal_plan/repositories/meal_plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';

import '../repositories/chat_repository.dart';
import '../models/chat_message.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

ChatMessage _welcomeMessage() => ChatMessage(
      text:
          "Hi! I'm Cookest AI 👋\n\nI know your pantry, your meal plan, and your dietary preferences. Ask me anything — or tap a suggestion below to get started.",
      isUser: false,
      timestamp: DateTime.now(),
    );

final chatMessagesProvider = StateProvider<List<ChatMessage>>(
  (ref) => [_welcomeMessage()],
);

final chatSessionIdProvider = StateProvider<int?>((ref) => null);

// ── Capabilities data ─────────────────────────────────────────────────────────

final _capabilities = [
  (
    icon: LucideIcons.search,
    title: 'Find recipes',
    desc: 'By cuisine, ingredient, time, or dietary need',
  ),
  (
    icon: LucideIcons.calendarDays,
    title: 'Manage meal plan',
    desc: 'View, change, or clear your weekly meals',
  ),
  (
    icon: LucideIcons.checkCircle,
    title: 'Mark meals done',
    desc: 'Log what you\'ve cooked today',
  ),
  (
    icon: LucideIcons.shoppingBag,
    title: 'Pantry management',
    desc: 'Check inventory, add or remove items',
  ),
  (
    icon: LucideIcons.alertTriangle,
    title: 'Expiry alerts',
    desc: 'See what\'s about to go off in your fridge',
  ),
  (
    icon: LucideIcons.bookOpen,
    title: 'Recipe details',
    desc: 'Ingredients, steps, and full nutrition info',
  ),
  (
    icon: LucideIcons.chefHat,
    title: 'Cooking guidance',
    desc: 'Step-by-step help while you cook',
  ),
];

// ── Suggestion chips ──────────────────────────────────────────────────────────

final _suggestions = [
  (icon: LucideIcons.utensils, label: 'What can I cook today?'),
  (icon: LucideIcons.calendarDays, label: 'Show my meal plan'),
  (icon: LucideIcons.chefHat, label: 'Change dinner to Italian'),
  (icon: LucideIcons.clock, label: "What's expiring soon?"),
  (icon: LucideIcons.shoppingBag, label: "What's in my pantry?"),
  (icon: LucideIcons.helpCircle, label: "What can you do?"),
];

// ── Tool label mapping ─────────────────────────────────────────────────────────

String _toolLabel(String toolName) {
  switch (toolName) {
    case 'clear_meal_plan':
      return '🗑️ Cleared meal plan';
    case 'search_recipes':
      return '🔍 Searched recipes';
    case 'get_meal_plan':
      return '📅 Checked meal plan';
    case 'update_meal_plan_slot':
      return '✏️ Updated meal plan';
    case 'mark_meal_completed':
      return '✅ Marked meal done';
    case 'get_pantry':
      return '🥫 Checked pantry';
    case 'add_to_pantry':
      return '➕ Added to pantry';
    case 'remove_from_pantry':
      return '🗑️ Removed from pantry';
    case 'get_recipe_details':
      return '📖 Got recipe details';
    default:
      return '🔧 $toolName';
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage([String? prefill]) async {
    final text = (prefill ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    final sessionId = ref.read(chatSessionIdProvider);

    ref.read(chatMessagesProvider.notifier).update(
          (msgs) => [
            ...msgs,
            ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
          ],
        );

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final response = await ref
          .read(chatRepositoryProvider)
          .sendMessage(text, sessionId: sessionId);

      ref.read(chatSessionIdProvider.notifier).state = response.sessionId;

      ref.read(chatMessagesProvider.notifier).update(
            (msgs) => [
              ...msgs,
              ChatMessage(
                text: response.reply,
                isUser: false,
                timestamp: DateTime.now(),
                actionsPerformed: response.actionsTaken,
              ),
            ],
          );

      if (response.actionsTaken.any((t) =>
          t == 'update_meal_plan_slot' ||
          t == 'mark_meal_completed' ||
          t == 'clear_meal_plan')) {
        ref.invalidate(currentMealPlanProvider);
      }
    } catch (e) {
      if (e.toString().contains('Pro')) {
        if (mounted) context.push('/paywall');
      } else {
        ref.read(chatMessagesProvider.notifier).update(
              (msgs) => [
                ...msgs,
                ChatMessage(
                  text: e.toString(),
                  isUser: false,
                  timestamp: DateTime.now(),
                  isError: true,
                ),
              ],
            );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _clearConversation() {
    ref.read(chatMessagesProvider.notifier).state = [_welcomeMessage()];
    ref.read(chatSessionIdProvider.notifier).state = null;
  }

  void _showCapabilities() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CapabilitiesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final showSuggestions = messages.length == 1 && !_isLoading;

    return Scaffold(
      backgroundColor: context.appBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cookest AI',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
            ),
            Text(
              'Your personal cooking assistant',
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, size: 20),
            tooltip: 'What can I do?',
            onPressed: _showCapabilities,
          ),
          if (messages.length > 1)
            IconButton(
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              tooltip: 'Clear conversation',
              onPressed: _clearConversation,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: messages.length +
                  (_isLoading ? 1 : 0) +
                  (showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (showSuggestions && index == 1) {
                  return _SuggestionChips(onSelected: _sendMessage);
                }

                final msgIndex = showSuggestions ? index - 1 : index;

                if (_isLoading && msgIndex == messages.length) {
                  return _TypingIndicator(controller: _typingController);
                }

                if (msgIndex < 0 || msgIndex >= messages.length) {
                  return const SizedBox.shrink();
                }

                final message = messages[msgIndex];
                return message.isUser
                    ? _UserBubble(message: message)
                    : _AiBubble(message: message);
              },
            ),
          ),
          _InputBar(
            controller: _messageController,
            isLoading: _isLoading,
            onSend: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}

// ── Capabilities bottom sheet ─────────────────────────────────────────────────

class _CapabilitiesSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What Cookest AI can do',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Just ask in plain English — no commands needed.',
            style: TextStyle(fontSize: 13, color: context.appMuted),
          ),
          const SizedBox(height: 20),
          ..._capabilities.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CookestTokens.colorPrimaryDEFAULT
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      c.icon,
                      size: 18,
                      color: CookestTokens.colorPrimaryDEFAULT,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.appHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message widgets ───────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CookestTokens.colorPrimaryDEFAULT,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: SelectableText(
          message.text,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CkCard(
              variant: CkCardVariant.standard,
              padding: CkCardPadding.sm,
              child: _RichText(
                text: message.text,
                isError: message.isError,
              ),
            ),
            if (message.actionsPerformed.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: message.actionsPerformed
                    .map((t) => _ActionChip(label: _toolLabel(t)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  const _RichText({required this.text, this.isError = false});
  final String text;
  final bool isError;

  List<InlineSpan> _parseInline(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(
            TextSpan(text: line.substring(last, match.start), style: base));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = isError
        ? const Color(0xFFD32F2F)
        : DefaultTextStyle.of(context).style.color;
    final base = TextStyle(fontSize: 14, height: 1.5, color: baseColor);

    final lines = text.split('\n');
    return SelectableText.rich(
      TextSpan(
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (lines[i].startsWith('- ') || lines[i].startsWith('• '))
              TextSpan(
                children: [
                  const TextSpan(text: '• '),
                  ..._parseInline(
                    lines[i].replaceFirst(RegExp(r'^[-•]\s'), ''),
                    base,
                  ),
                ],
              )
            else
              TextSpan(children: _parseInline(lines[i], base)),
            if (i < lines.length - 1) const TextSpan(text: '\n'),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 56),
        child: CkCard(
          variant: CkCardVariant.standard,
          padding: CkCardPadding.sm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: controller,
                  builder: (_, a) {
                    final offset = math.sin(
                      (controller.value * 2 * math.pi) - (i * math.pi / 3),
                    );
                    return Container(
                      margin: EdgeInsets.only(
                        right: i < 2 ? 4 : 0,
                        bottom: ((offset + 1) * 4).clamp(0, 8),
                      ),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CookestTokens.colorPrimaryDEFAULT
                            .withValues(alpha: 0.5 + offset * 0.5),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
              const SizedBox(width: 8),
              Text(
                'Thinking…',
                style: TextStyle(fontSize: 12, color: context.appMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Suggestion chips ──────────────────────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.onSelected});
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return CkButton(
            variant: CkButtonVariant.secondary,
            size: CkButtonSize.sm,
            onPressed: () => onSelected(s.label),
            iconLeft: Icon(s.icon,
                size: 14, color: CookestTokens.colorPrimaryDEFAULT),
            child: Text(s.label),
          );
        }).toList(),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        12, 8, 12, MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CkInput(
              controller: controller,
              placeholder: 'Ask Cookest AI…',
              fullWidth: true,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CkSpinner(size: CkSpinnerSize.sm),
                )
              : CkButton(
                  variant: CkButtonVariant.ghost,
                  size: CkButtonSize.sm,
                  iconLeft: const Icon(LucideIcons.send, size: 16),
                  onPressed: onSend,
                  child: const SizedBox.shrink(),
                ),
        ],
      ),
    );
  }
}
