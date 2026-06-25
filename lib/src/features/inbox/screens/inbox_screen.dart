import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookest_ui/cookest_ui.dart';
import '../repositories/notification_repository.dart';
import '../repositories/suggestion_repository.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotificationsList(),
          _SuggestionsList(),
        ],
      ),
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  const _NotificationsList();

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await ref.read(notificationRepositoryProvider).getNotifications();
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      _loadNotifications();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text('No notifications.'));
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final isRead = notif['read_at'] != null;

        return ListTile(
          title: Text(notif['title'] ?? 'Notification'),
          subtitle: Text(notif['body'] ?? ''),
          trailing: isRead ? null : const Icon(Icons.circle, color: CookestColors.primary, size: 12),
          onTap: () {
            if (!isRead) {
              _markAsRead(notif['id']);
            }
          },
        );
      },
    );
  }
}

class _SuggestionsList extends ConsumerStatefulWidget {
  const _SuggestionsList();

  @override
  ConsumerState<_SuggestionsList> createState() => _SuggestionsListState();
}

class _SuggestionsListState extends ConsumerState<_SuggestionsList> {
  // Real implementation would pass a planId, but for now we just show a placeholder
  // since suggestions are usually tied to a specific meal plan.
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Suggestions appear on the meal plan screen.'),
    );
  }
}
