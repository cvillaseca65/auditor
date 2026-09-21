import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../audit_verification_service.dart';
import '../session_service.dart';
import 'audit_offline_store.dart';

/// Descarga de planes para campo y vaciado de la cola offline.
class AuditSyncService {
  AuditSyncService._();
  static final AuditSyncService instance = AuditSyncService._();

  final _store = AuditOfflineStore.instance;
  bool _flushing = false;

  Future<bool> isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return true;
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Descarga el plan completo y el detalle de cada ítem de verificación.
  Future<Map<String, dynamic>> downloadPlanForOffline({
    required int planId,
    required Future<Map<String, dynamic>> Function() fetchPlanFull,
    required Future<Map<String, dynamic>> Function(int checkItemId)
        fetchCheckItemDetail,
  }) async {
    final companyId = await SessionService.getCompanyId();
    if (companyId == null) {
      throw StateError('Sin empresa activa');
    }
    final planFull = await fetchPlanFull();
    final details = <String, Map<String, dynamic>>{};
    final ids = <int>{};
    void collect(List? list) {
      if (list == null) return;
      for (final item in list) {
        if (item is! Map) continue;
        final id = int.tryParse('${item['id']}');
        if (id != null) ids.add(id);
      }
    }

    collect(planFull['check_items'] as List?);
    final grouped = planFull['check_items_grouped'] as List?;
    if (grouped != null) {
      for (final g in grouped) {
        if (g is Map) collect(g['items'] as List?);
      }
    }

    for (final id in ids) {
      try {
        details['$id'] = await fetchCheckItemDetail(id);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('offline prefetch check-item $id failed: $e');
        }
      }
    }

    await _store.savePlanFull(
      companyId: companyId,
      planId: planId,
      planFull: planFull,
      checkItemDetails: details,
    );
    return planFull;
  }

  Future<int> flushOutbox() async {
    if (_flushing) return 0;
    if (!await isOnline()) return 0;
    _flushing = true;
    var synced = 0;
    try {
      final rows = await _store.loadOutbox();
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        if (row['type'] != 'check_item_verify') continue;
        final id = '${row['id']}';
        try {
          await _flushCheckItemVerify(row);
          await _store.removeOutbox(id);
          synced++;
        } catch (e) {
          await _store.bumpOutboxAttempt(id, '$e');
          if (kDebugMode) {
            debugPrint('outbox flush failed $id: $e');
          }
        }
      }
    } finally {
      _flushing = false;
    }
    return synced;
  }

  Future<void> _flushCheckItemVerify(Map<String, dynamic> row) async {
    final headers = await SessionService.authCompanyHeaders();
    if (headers == null) {
      throw StateError('Sesión no disponible');
    }
    final token = headers['Authorization']!.replaceFirst('Bearer ', '');
    final companyId = int.parse(headers['X-Company-ID']!);
    final api = AuditVerificationService(token: token, companyId: companyId);

    final uploads = <({String name, Uint8List bytes, String description})>[];
    final meta = row['uploads'];
    if (meta is List) {
      for (final u in meta) {
        if (u is! Map) continue;
        final fileName = '${u['file'] ?? ''}';
        final bytes = await _store.readUploadBytes(fileName);
        if (bytes == null || bytes.isEmpty) continue;
        uploads.add((
          name: '${u['name'] ?? fileName}',
          bytes: bytes,
          description: '${u['description'] ?? ''}',
        ));
      }
    }

    await api.submit(
      checkItemId: int.parse('${row['check_item_id']}'),
      status: int.parse('${row['status']}'),
      evidence: '${row['evidence'] ?? ''}',
      ncFinding: '${row['nc_finding'] ?? ''}',
      uploads: uploads,
    );
  }
}
