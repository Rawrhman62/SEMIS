import 'dart:convert';

/// Model representing the authenticated user in SEMIS.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;
  final DateTime loggedInAt;
  final bool isOffline;
  final bool hasDriveScope;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    required this.loggedInAt,
    this.isOffline = false,
    this.hasDriveScope = false,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? accessToken,
    String? idToken,
    DateTime? loggedInAt,
    bool? isOffline,
    bool? hasDriveScope,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      loggedInAt: loggedInAt ?? this.loggedInAt,
      isOffline: isOffline ?? this.isOffline,
      hasDriveScope: hasDriveScope ?? this.hasDriveScope,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'idToken': idToken,
      'loggedInAt': loggedInAt.toIso8601String(),
      'isOffline': isOffline,
      'hasDriveScope': hasDriveScope,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Peternak',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      accessToken: map['accessToken'] as String?,
      idToken: map['idToken'] as String?,
      loggedInAt: map['loggedInAt'] != null
          ? DateTime.tryParse(map['loggedInAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isOffline: map['isOffline'] as bool? ?? false,
      hasDriveScope: map['hasDriveScope'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

enum AuthStatus {
  success,
  offlineSuccess,
  permissionDenied,
  offlineNoSession,
  cancelled,
  error,
}

class AuthResult {
  final AuthStatus status;
  final String message;
  final AuthUser? user;

  const AuthResult({
    required this.status,
    required this.message,
    this.user,
  });

  bool get isSuccess =>
      status == AuthStatus.success || status == AuthStatus.offlineSuccess;
}

