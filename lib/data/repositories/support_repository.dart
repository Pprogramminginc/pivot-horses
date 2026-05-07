import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class CoinPurchaseVerificationResult {
  const CoinPurchaseVerificationResult({
    required this.coinAmount,
    required this.coinBalance,
    required this.alreadyProcessed,
  });

  final int coinAmount;
  final int coinBalance;
  final bool alreadyProcessed;
}

class SupportRepository {
  const SupportRepository();

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSupabaseAvailable => _supabaseClient != null;

  Future<void> logClientEvent({
    required String ownerId,
    required String eventType,
    String status = 'info',
    String? message,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    await supabase.from('client_event_log').insert({
      'owner_id': ownerId,
      'event_type': eventType,
      'status': status,
      'message': message ?? eventType,
      'context': _sanitize(context),
    });
  }

  Future<void> logErrorEvent({
    required String ownerId,
    required String source,
    required String message,
    String? stackTrace,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    await supabase.from('error_events').insert({
      'owner_id': ownerId,
      'source': source,
      'message': message,
      'stack_trace': stackTrace,
      'context': _sanitize(context),
    });
  }

  Future<void> createSupportSnapshot({
    required String ownerId,
    required String supportCode,
    required String snapshotSummary,
    required Map<String, dynamic> snapshotPayload,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    await supabase.from('support_snapshots').insert({
      'owner_id': ownerId,
      'support_code': supportCode,
      'snapshot_summary': snapshotSummary,
      'snapshot_payload': _sanitize(snapshotPayload),
    });
  }

  Future<bool> createFeedbackSubmission({
    required String ownerId,
    required String email,
    required String displayName,
    required String category,
    required String message,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return false;
    }

    final payload = {
      'owner_id': ownerId,
      'email': email,
      'display_name': displayName,
      'category': category,
      'message': message,
      'context': _sanitize(context),
    };

    try {
      await supabase.from('feedback_submissions').insert(payload);
    } catch (error) {
      await supabase.from('client_event_log').insert({
        'owner_id': ownerId,
        'event_type': 'feedback_submission',
        'status': 'info',
        'message': message,
        'context': _sanitize({
          ...context,
          'email': email,
          'display_name': displayName,
          'category': category,
          'fallback_reason': error.toString(),
          'storage_target': 'client_event_log',
        }),
      });
    }
    return true;
  }

  Future<bool> logPurchaseReceipt({
    required String ownerId,
    required String productId,
    required String transactionId,
    required int purchasedAmount,
    required int priceCents,
    String platform = 'ios',
    String currency = 'USD',
    String? rawReceiptHash,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return false;
    }

    try {
      await supabase.from('purchase_receipts').insert({
        'owner_id': ownerId,
        'platform': platform,
        'product_id': productId,
        'transaction_id': transactionId,
        'purchased_amount': purchasedAmount,
        'price_cents': priceCents,
        'currency': currency,
        'raw_receipt_hash': rawReceiptHash,
        'context': _sanitize(context),
      });
      return true;
    } catch (error) {
      await supabase.from('client_event_log').insert({
        'owner_id': ownerId,
        'event_type': 'purchase_receipt_log_failed',
        'status': 'warning',
        'message': 'Purchase receipt could not be logged.',
        'context': _sanitize({
          ...context,
          'product_id': productId,
          'transaction_id': transactionId,
          'purchased_amount': purchasedAmount,
          'price_cents': priceCents,
          'error': error.toString(),
        }),
      });
      return false;
    }
  }

  Future<CoinPurchaseVerificationResult?> verifyCoinPurchase({
    required String productId,
    required String transactionId,
    required String source,
    required String serverVerificationData,
    required String localVerificationData,
    String platform = 'ios',
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }

    final response = await supabase.functions.invoke(
      'verify-coin-purchase',
      body: {
        'productId': productId,
        'transactionId': transactionId,
        'platform': platform,
        'source': source,
        'serverVerificationData': serverVerificationData,
        'localVerificationData': localVerificationData,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return null;
    }

    return CoinPurchaseVerificationResult(
      coinAmount: (data['coin_amount'] as num?)?.toInt() ?? 0,
      coinBalance: (data['coin_balance'] as num?)?.toInt() ?? 0,
      alreadyProcessed: data['already_processed'] == true,
    );
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> value) {
    final encoded = jsonEncode(value);
    return jsonDecode(encoded) as Map<String, dynamic>;
  }
}
