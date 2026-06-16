import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Immutable snapshot of the current authentication state.
///
/// Three logical states:
/// - **Loading** — `isLoading == true`; an auth operation is in flight.
/// - **Authenticated** — `accessToken != null && !isLoading`.
/// - **Unauthenticated** — `accessToken == null && !isLoading`.
///
/// The [tier] getter decodes the JWT claim to expose the user's subscription tier.
class AuthState {
  final String? accessToken;
  final bool isLoading;
  final String? error;

  /// Local override set the moment onboarding is completed, before a fresh
  /// access token (with `onboarding_completed: true`) is issued on next refresh.
  /// Prevents the router from bouncing the user back to `/onboarding`.
  final bool onboardingDone;

  AuthState({
    this.accessToken,
    this.isLoading = false,
    this.error,
    this.onboardingDone = false,
  });

  bool get isAuthenticated => accessToken != null;

  String? get tier {
    if (accessToken == null) return null;
    try {
      final payload = JwtDecoder.decode(accessToken!);
      return payload['tier'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Whether the user has finished onboarding. True if either the session-local
  /// override is set or the access token carries `onboarding_completed: true`.
  bool get onboardingCompleted {
    if (onboardingDone) return true;
    if (accessToken == null) return false;
    try {
      final payload = JwtDecoder.decode(accessToken!);
      return payload['onboarding_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  AuthState copyWith({
    String? accessToken,
    bool? isLoading,
    String? error,
    bool? onboardingDone,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

/// Manages [AuthState] transitions: token injection after login, clearing
/// state on logout, and surfacing loading / error flags to the UI.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  /// Stores [token] in state and clears the loading flag.
  /// Called by [AuthRepository] after login/register and by [dioProvider]
  /// after a silent token refresh.
  void setToken(String token) {
    state = state.copyWith(accessToken: token, isLoading: false);
  }

  /// Resets state to the initial unauthenticated snapshot.
  /// Does **not** call the API logout endpoint — that is handled by
  /// [AuthRepository.logout].
  void logout() {
    state = AuthState();
  }

  /// Marks onboarding as completed for the current session. Called right after
  /// the onboarding flow is submitted so the router stops gating on it before
  /// the next token refresh picks up the updated `onboarding_completed` claim.
  void markOnboardingCompleted() {
    state = state.copyWith(onboardingDone: true);
  }

  /// Sets the loading flag. Used by auth screens to show a spinner
  /// while an async operation is in progress.
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Stores an error message and clears the loading flag.
  /// Pass `null` to dismiss a previous error.
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }
}

/// Provider that exposes [AuthNotifier] / [AuthState].
///
/// Alive for the lifetime of the app. [dioProvider] reads this provider
/// on every request to inject the current access token as a `Bearer` header.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
