import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config.dart';

class PollOption {
  final int id;
  final String label;
  final String? imageUrl;
  final int? recipeId;
  final int votes;

  PollOption({
    required this.id,
    required this.label,
    this.imageUrl,
    this.recipeId,
    required this.votes,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] as int? ?? 0,
        label: json['label']?.toString() ?? '',
        imageUrl: json['image_url']?.toString(),
        recipeId: json['recipe_id'] as int?,
        votes: json['votes'] as int? ?? 0,
      );
}

class MealPoll {
  final String id;
  final String token;
  final String title;
  final String status;
  final List<PollOption> options;
  final int totalVotes;

  MealPoll({
    required this.id,
    required this.token,
    required this.title,
    required this.status,
    required this.options,
    required this.totalVotes,
  });

  factory MealPoll.fromJson(Map<String, dynamic> json) => MealPoll(
        id: json['id']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        options: (json['options'] as List? ?? [])
            .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        totalVotes: json['total_votes'] as int? ?? 0,
      );

  /// Public link people without the app can open to vote.
  String get shareUrl => '${AppConfig.publicWebUrl}/vote/$token';
}

class MealPollRepository {
  final Dio _dio;
  MealPollRepository(this._dio);

  /// Create a poll from candidate dishes. Each option: {recipe_id?, label, image_url?}.
  Future<MealPoll> create({
    required String title,
    int? slotId,
    required List<Map<String, dynamic>> options,
  }) async {
    final response = await _dio.post('/api/my-polls', data: {
      'title': title,
      if (slotId != null) 'slot_id': slotId,
      'options': options,
    });
    return MealPoll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MealPoll> get(String token) async {
    final response = await _dio.get('/api/polls/$token');
    return MealPoll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MealPoll> vote(String token, int optionId,
      {required String voterKey, String? voterName}) async {
    final response = await _dio.post('/api/polls/$token/vote', data: {
      'option_id': optionId,
      'voter_key': voterKey,
      if (voterName != null) 'voter_name': voterName,
    });
    return MealPoll.fromJson(response.data as Map<String, dynamic>);
  }
}

final mealPollRepositoryProvider = Provider<MealPollRepository>((ref) {
  return MealPollRepository(ref.watch(dioProvider));
});
