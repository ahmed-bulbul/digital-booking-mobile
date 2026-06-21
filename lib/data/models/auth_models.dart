class AuthResponse {
  final String token;
  final int userId;
  final dynamic role;

  AuthResponse({required this.token, required this.userId, required this.role});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        userId: json['userId'] as int,
        role: json['role'],
      );
}

class CurrentUser {
  final int id;
  final String name;
  final String email;
  final String? phone;

  CurrentUser({required this.id, required this.name, required this.email, this.phone});

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
      );
}

class RouteOption {
  final int routeId;
  final String sourceName;
  final String destinationName;

  RouteOption({
    required this.routeId,
    required this.sourceName,
    required this.destinationName,
  });

  // Backend RouteLookupResponse returns: { id, sourceName, destinationName }
  factory RouteOption.fromJson(Map<String, dynamic> json) => RouteOption(
        routeId: (json['id'] ?? json['routeId']) as int,
        sourceName: json['sourceName'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
      );

  String get label => '$sourceName → $destinationName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RouteOption && routeId == other.routeId;

  @override
  int get hashCode => routeId.hashCode;
}
