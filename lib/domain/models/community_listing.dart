import 'horse.dart';

class CommunityListing {
  const CommunityListing({
    required this.id,
    required this.sellerProfileId,
    required this.sellerName,
    required this.sellerHandle,
    required this.sellerStableName,
    required this.horse,
    required this.sellerPayout,
  });

  final String id;
  final String sellerProfileId;
  final String sellerName;
  final String sellerHandle;
  final String sellerStableName;
  final Horse horse;
  final int sellerPayout;

  CommunityListing copyWith({
    String? id,
    String? sellerProfileId,
    String? sellerName,
    String? sellerHandle,
    String? sellerStableName,
    Horse? horse,
    int? sellerPayout,
  }) {
    return CommunityListing(
      id: id ?? this.id,
      sellerProfileId: sellerProfileId ?? this.sellerProfileId,
      sellerName: sellerName ?? this.sellerName,
      sellerHandle: sellerHandle ?? this.sellerHandle,
      sellerStableName: sellerStableName ?? this.sellerStableName,
      horse: horse ?? this.horse,
      sellerPayout: sellerPayout ?? this.sellerPayout,
    );
  }
}
