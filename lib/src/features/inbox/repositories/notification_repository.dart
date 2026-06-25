import 'package:cookest_app/src/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final notifs = await repo.getNotifications();
  return notifs.where((n) => n['read_at'] == null).length;
});

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _apiClient.get('/api/users/me/notifications');
    final List<dynamic> data = response.data;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.put('/api/users/me/notifications/$id/read');
  }
}
