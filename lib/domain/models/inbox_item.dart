enum InboxItemKind {
  message,
  notification;

  String get storageValue => switch (this) {
    InboxItemKind.message => 'message',
    InboxItemKind.notification => 'notification',
  };

  static InboxItemKind fromStorageValue(String? value) {
    return switch (value) {
      'notification' || 'alert' => InboxItemKind.notification,
      _ => InboxItemKind.message,
    };
  }
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.readAt,
    this.actionLabel,
    this.actionPayload = const <String, dynamic>{},
  });

  final String id;
  final String ownerId;
  final InboxItemKind kind;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionLabel;
  final Map<String, dynamic> actionPayload;

  bool get isUnread => readAt == null;

  InboxItem copyWith({DateTime? readAt}) {
    return InboxItem(
      id: id,
      ownerId: ownerId,
      kind: kind,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      actionLabel: actionLabel,
      actionPayload: actionPayload,
    );
  }

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final actionPayload = json['action_payload'];
    return InboxItem(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      kind: InboxItemKind.fromStorageValue(json['kind'] as String?),
      title: json['title'] as String? ?? 'Inbox update',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      actionLabel: json['action_label'] as String?,
      actionPayload: actionPayload is Map<String, dynamic>
          ? actionPayload
          : const <String, dynamic>{},
    );
  }
}
