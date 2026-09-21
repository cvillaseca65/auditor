import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audit_offline_io.dart';

/// Persistencia local para planes de auditoría y cola de sync (outbox).
class AuditOfflineStore {
  AuditOfflineStore._();
  static final AuditOfflineStore instance = AuditOfflineStore._();

  static const _outboxPrefsKey = 'audit_outbox_v1';
  static const _plansIndexKey = 'audit_plans_index_v1';

  String _planKey(int companyId, int planId) => 'c${companyId}_p$planId';

  Future<String?> _planFilePath(int companyId, int planId) async {
    final root = await offlineDocumentsRoot();
    if (root == null) return null;
    await offlineEnsureDir(root);
    return '$root/plan_${_planKey(companyId, planId)}.json';
  }

  Future<void> savePlanFull({
    required int companyId,
    required int planId,
    required Map<String, dynamic> planFull,
    Map<String, Map<String, dynamic>>? checkItemDetails,
  }) async {
    final payload = <String, dynamic>{
      'company_id': companyId,
      'plan_id': planId,
      'saved_at': DateTime.now().toIso8601String(),
      'plan_full': planFull,
      'check_items': checkItemDetails ?? {},
    };
    final raw = jsonEncode(payload);
    final path = await _planFilePath(companyId, planId);
    if (path != null && !kIsWeb) {
      await offlineWriteString(path, raw);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'audit_plan_${_planKey(companyId, planId)}',
        raw,
      );
    }
    await _indexAdd(companyId, planId, planFull);
  }

  Future<Map<String, dynamic>?> getPlanBundle(
    int companyId,
    int planId,
  ) async {
    String? raw;
    final path = await _planFilePath(companyId, planId);
    if (path != null && !kIsWeb) {
      raw = await offlineReadString(path);
    }
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString('audit_plan_${_planKey(companyId, planId)}');
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPlanFull(int companyId, int planId) async {
    final bundle = await getPlanBundle(companyId, planId);
    final full = bundle?['plan_full'];
    if (full is Map<String, dynamic>) return full;
    if (full is Map) return Map<String, dynamic>.from(full);
    return null;
  }

  Future<Map<String, dynamic>?> getCheckItemDetail(
    int companyId,
    int planId,
    int checkItemId,
  ) async {
    final bundle = await getPlanBundle(companyId, planId);
    final items = bundle?['check_items'];
    if (items is! Map) return null;
    final raw = items['$checkItemId'] ?? items[checkItemId];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> patchCheckItemInPlan({
    required int companyId,
    required int planId,
    required int checkItemId,
    required int status,
    required String evidence,
  }) async {
    final bundle = await getPlanBundle(companyId, planId);
    if (bundle == null) return;
    final planFull = Map<String, dynamic>.from(
      (bundle['plan_full'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (planFull.isEmpty) return;

    void patchList(List list) {
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is! Map) continue;
        if ('${item['id']}' != '$checkItemId') continue;
        final copy = Map<String, dynamic>.from(item);
        copy['status'] = status;
        list[i] = copy;
      }
    }

    final flat = planFull['check_items'];
    if (flat is List) patchList(flat);
    final grouped = planFull['check_items_grouped'];
    if (grouped is List) {
      for (final g in grouped) {
        if (g is! Map) continue;
        final items = g['items'];
        if (items is List) patchList(items);
      }
    }

    final progress = Map<String, dynamic>.from(
      (planFull['check_progress'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final total = int.tryParse('${progress['total'] ?? 0}') ?? 0;
    var done = 0;
    final checkItems = planFull['check_items'];
    if (checkItems is List) {
      for (final item in checkItems) {
        if (item is Map && (int.tryParse('${item['status']}') ?? 0) > 0) {
          done++;
        }
      }
    }
    progress['done'] = done;
    progress['total'] =
        total > 0 ? total : (checkItems is List ? checkItems.length : 0);
    planFull['check_progress'] = progress;

    final details = <String, Map<String, dynamic>>{};
    final existing = bundle['check_items'];
    if (existing is Map) {
      existing.forEach((k, v) {
        if (v is Map) {
          details['$k'] = Map<String, dynamic>.from(v);
        }
      });
    }
    final detail = details['$checkItemId'];
    if (detail != null) {
      detail['status'] = status;
      final line = Map<String, dynamic>.from(
        (detail['line'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      line['evidence'] = evidence;
      detail['line'] = line;
      details['$checkItemId'] = detail;
    }

    await savePlanFull(
      companyId: companyId,
      planId: planId,
      planFull: planFull,
      checkItemDetails: details,
    );
  }

  Future<List<Map<String, dynamic>>> listDownloadedPlans(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansIndexKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['company_id'] == companyId)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _indexAdd(
    int companyId,
    int planId,
    Map<String, dynamic> planFull,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await listDownloadedPlans(companyId);
    final others = existing.where((e) => e['plan_id'] != planId).toList();
    others.add({
      'company_id': companyId,
      'plan_id': planId,
      'name': planFull['name']?.toString() ?? 'Plan $planId',
      'saved_at': DateTime.now().toIso8601String(),
    });
    final rawAll = prefs.getString(_plansIndexKey);
    final all = <Map<String, dynamic>>[];
    if (rawAll != null && rawAll.isNotEmpty) {
      try {
        for (final e in jsonDecode(rawAll) as List) {
          if (e is Map && e['company_id'] != companyId) {
            all.add(Map<String, dynamic>.from(e));
          }
        }
      } catch (_) {}
    }
    all.addAll(others);
    await prefs.setString(_plansIndexKey, jsonEncode(all));
  }

  Future<List<Map<String, dynamic>>> loadOutbox() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_outboxPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOutbox(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outboxPrefsKey, jsonEncode(rows));
  }

  Future<String> enqueueCheckItemVerify({
    required int companyId,
    required int planId,
    required int checkItemId,
    required int status,
    required String evidence,
    String ncFinding = '',
    List<({String name, Uint8List bytes, String description})> uploads =
        const [],
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final uploadMeta = <Map<String, dynamic>>[];
    for (var i = 0; i < uploads.length; i++) {
      final u = uploads[i];
      final fileName = '${id}_${i}_${u.name}';
      await _writeUploadBytes(fileName, u.bytes);
      uploadMeta.add({
        'name': u.name,
        'description': u.description,
        'file': fileName,
      });
    }

    final rows = await loadOutbox();
    rows.add({
      'id': id,
      'type': 'check_item_verify',
      'company_id': companyId,
      'plan_id': planId,
      'check_item_id': checkItemId,
      'status': status,
      'evidence': evidence,
      'nc_finding': ncFinding,
      'uploads': uploadMeta,
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
    await _saveOutbox(rows);
    await patchCheckItemInPlan(
      companyId: companyId,
      planId: planId,
      checkItemId: checkItemId,
      status: status,
      evidence: evidence,
    );
    return id;
  }

  Future<void> removeOutbox(String id) async {
    final rows = await loadOutbox();
    final kept = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row['id'] == id) {
        final uploads = row['uploads'];
        if (uploads is List) {
          for (final u in uploads) {
            if (u is Map && u['file'] != null) {
              await _deleteUploadFile('${u['file']}');
            }
          }
        }
      } else {
        kept.add(row);
      }
    }
    await _saveOutbox(kept);
  }

  Future<void> bumpOutboxAttempt(String id, String error) async {
    final rows = await loadOutbox();
    for (final row in rows) {
      if (row['id'] == id) {
        row['attempts'] = (int.tryParse('${row['attempts']}') ?? 0) + 1;
        row['last_error'] = error;
      }
    }
    await _saveOutbox(rows);
  }

  Future<int> pendingCount() async => (await loadOutbox()).length;

  Future<void> _writeUploadBytes(String fileName, Uint8List bytes) async {
    final root = await offlineDocumentsRoot();
    if (root != null && !kIsWeb) {
      await offlineEnsureDir('$root/uploads');
      await offlineWriteBytes('$root/uploads/$fileName', bytes);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audit_upload_$fileName', base64Encode(bytes));
  }

  Future<Uint8List?> readUploadBytes(String fileName) async {
    final root = await offlineDocumentsRoot();
    if (root != null && !kIsWeb) {
      return offlineReadBytes('$root/uploads/$fileName');
    }
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString('audit_upload_$fileName');
    if (b64 == null || b64.isEmpty) return null;
    return base64Decode(b64);
  }

  Future<void> _deleteUploadFile(String fileName) async {
    final root = await offlineDocumentsRoot();
    if (root != null && !kIsWeb) {
      await offlineDeleteFile('$root/uploads/$fileName');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('audit_upload_$fileName');
  }
}
