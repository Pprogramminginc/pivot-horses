import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/inbox_item.dart';

class InboxRepository {
  const InboxRepository();

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSupabaseAvailable => _supabaseClient != null;

  Future<List<InboxItem>> loadInboxItems({required String ownerId}) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return const <InboxItem>[];
    }

    final response = await supabase
        .from('inbox_items')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      response,
    ).map(InboxItem.fromJson).toList();
  }

  Future<void> markRead({
    required String ownerId,
    required String itemId,
    required DateTime readAt,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    await supabase
        .from('inbox_items')
        .update({'read_at': readAt.toUtc().toIso8601String()})
        .eq('owner_id', ownerId)
        .eq('id', itemId);
  }

  Future<void> markAllRead({
    required String ownerId,
    required InboxItemKind kind,
    required DateTime readAt,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    await supabase
        .from('inbox_items')
        .update({'read_at': readAt.toUtc().toIso8601String()})
        .eq('owner_id', ownerId)
        .eq('kind', kind.storageValue)
        .filter('read_at', 'is', null);
  }
}
