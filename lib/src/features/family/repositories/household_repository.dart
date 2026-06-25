import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// A member of a household.
class HouseholdMember {
  final String userId;
  final String? name;
  final String role;

  HouseholdMember({required this.userId, this.name, required this.role});

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      HouseholdMember(
        userId: json['user_id']?.toString() ?? '',
        name: json['name']?.toString(),
        role: json['role']?.toString() ?? 'member',
      );
}

/// A family group that shares meal planning.
class Household {
  final String id;
  final String name;
  final String ownerId;
  final List<HouseholdMember> members;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
  });

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        ownerId: json['owner_id']?.toString() ?? '',
        members: (json['members'] as List? ?? [])
            .map((m) => HouseholdMember.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class HouseholdRepository {
  final Dio _dio;
  HouseholdRepository(this._dio);

  Future<Household?> getMyHousehold() async {
    final response = await _dio.get('/api/households/me');
    if (response.data == null) return null;
    return Household.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Household> create(String name) async {
    final response = await _dio.post('/api/households', data: {'name': name});
    return Household.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Household> join(String token) async {
    final response =
        await _dio.post('/api/households/join', data: {'token': token});
    return Household.fromJson(response.data as Map<String, dynamic>);
  }

  /// Returns the raw invite token for the household.
  Future<String> createInvite(String householdId) async {
    final response = await _dio.post('/api/households/$householdId/invites');
    return response.data['token'] as String;
  }

  /// Removes a member from the household, or leaves the household.
  Future<Household?> removeMember(String memberId) async {
    final response = await _dio.delete('/api/households/members/$memberId');
    if (response.data == null) return null;
    return Household.fromJson(response.data as Map<String, dynamic>);
  }

  /// Transfers ownership of the household to another member.
  Future<Household> transferOwnership(String newOwnerId) async {
    final response = await _dio.post('/api/households/transfer-ownership', data: {
      'new_owner_id': newOwnerId,
    });
    return Household.fromJson(response.data as Map<String, dynamic>);
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(dioProvider));
});

final myHouseholdProvider = FutureProvider<Household?>((ref) async {
  return ref.watch(householdRepositoryProvider).getMyHousehold();
});
