import 'package:flutter/material.dart';

class CommunityProfile {
  const CommunityProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.stableName,
    required this.favoriteBreed,
    required this.followerCount,
    required this.weeklyPosts,
    required this.bio,
    required this.accentValue,
    required this.joinedLabel,
  });

  final String id;
  final String name;
  final String handle;
  final String stableName;
  final String favoriteBreed;
  final int followerCount;
  final int weeklyPosts;
  final String bio;
  final int accentValue;
  final String joinedLabel;

  Color get accent => Color(accentValue);

  String get initials {
    final parts = name.split(' ');
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
  }
}
