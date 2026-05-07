class LocalAccount {
  const LocalAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.createdAt,
    required this.lastSignedInAt,
    this.handle,
    this.stableName,
    this.favoriteBreed,
    this.accentValue,
  });

  final String id;
  final String email;
  final String displayName;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime lastSignedInAt;
  final String? handle;
  final String? stableName;
  final String? favoriteBreed;
  final int? accentValue;

  LocalAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastSignedInAt,
    String? handle,
    String? stableName,
    String? favoriteBreed,
    int? accentValue,
  }) {
    return LocalAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastSignedInAt: lastSignedInAt ?? this.lastSignedInAt,
      handle: handle ?? this.handle,
      stableName: stableName ?? this.stableName,
      favoriteBreed: favoriteBreed ?? this.favoriteBreed,
      accentValue: accentValue ?? this.accentValue,
    );
  }
}
