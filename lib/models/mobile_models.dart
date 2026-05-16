import '../util/plain_text.dart';

/// Acepta int, double o string (evita fallos al decodificar JSON del API).
int? _jsonInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }
  return null;
}

class PendingSummary {
  final int myPendingCount;
  final int myPendingDelayed;
  final int owedPendingCount;
  final int owedPendingDelayed;
  final int pendingTotalCount;
  final int pendingDelayedCount;

  PendingSummary({
    required this.myPendingCount,
    required this.myPendingDelayed,
    required this.owedPendingCount,
    required this.owedPendingDelayed,
    required this.pendingTotalCount,
    required this.pendingDelayedCount,
  });

  factory PendingSummary.fromJson(Map<String, dynamic> json) {
    return PendingSummary(
      myPendingCount: json['my_pending_count'] as int? ?? 0,
      myPendingDelayed: json['my_pending_delayed'] as int? ?? 0,
      owedPendingCount: json['owed_pending_count'] as int? ?? 0,
      owedPendingDelayed: json['owed_pending_delayed'] as int? ?? 0,
      pendingTotalCount: json['pending_total_count'] as int? ?? 0,
      pendingDelayedCount: json['pending_delayed_count'] as int? ?? 0,
    );
  }
}

class OrganizationSummary {
  final int pendingTotalCount;
  final int pendingDelayedCount;

  OrganizationSummary({
    required this.pendingTotalCount,
    required this.pendingDelayedCount,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      pendingTotalCount: json['pending_total_count'] as int? ?? 0,
      pendingDelayedCount: json['pending_delayed_count'] as int? ?? 0,
    );
  }
}

class HallazgosSummary {
  final int pendingCount;
  final int closedCount;

  HallazgosSummary({
    required this.pendingCount,
    required this.closedCount,
  });

  factory HallazgosSummary.fromJson(Map<String, dynamic> json) {
    return HallazgosSummary(
      pendingCount: json['pending_count'] as int? ?? 0,
      closedCount: json['closed_count'] as int? ?? 0,
    );
  }
}

class PendingRow {
  final String category;
  final String title;
  final String responsible;
  final String holderRole;
  final String position;
  final String alertText;
  final bool isDelayed;
  final String editUrl;
  final String? endIso;
  final String? simViewUrl;
  final String? mobileAction;
  final int? mobileObjectId;
  final bool mobileInApp;

  PendingRow({
    required this.category,
    required this.title,
    required this.responsible,
    this.holderRole = '',
    this.position = '',
    required this.alertText,
    required this.isDelayed,
    required this.editUrl,
    this.endIso,
    this.simViewUrl,
    this.mobileAction,
    this.mobileObjectId,
    this.mobileInApp = false,
  });

  factory PendingRow.fromJson(Map<String, dynamic> json) {
    return PendingRow(
      category: plainText(json['category'] as String?),
      title: plainText(json['title'] as String?),
      responsible: plainText(json['responsible'] as String?),
      holderRole: plainText(json['holder_role'] as String?),
      position: plainText(json['position'] as String?),
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
      editUrl: json['edit_url'] as String? ?? '',
      endIso: json['end'] as String?,
      simViewUrl: json['sim_view_url'] as String?,
      mobileAction: json['mobile_action'] as String?,
      mobileObjectId: _jsonInt(json['mobile_object_id']),
      mobileInApp: json['mobile_in_app'] as bool? ?? false,
    );
  }
}

class OwedRow {
  final String kind;
  final String title;
  final String executor;
  final String alertText;
  final bool isDelayed;
  final String editUrl;
  final String? endIso;
  final String? simViewUrl;
  final String? mobileAction;
  final int? mobileObjectId;
  final bool mobileInApp;

  OwedRow({
    required this.kind,
    required this.title,
    required this.executor,
    required this.alertText,
    required this.isDelayed,
    required this.editUrl,
    this.endIso,
    this.simViewUrl,
    this.mobileAction,
    this.mobileObjectId,
    this.mobileInApp = false,
  });

  factory OwedRow.fromJson(Map<String, dynamic> json) {
    return OwedRow(
      kind: plainText(json['kind'] as String?),
      title: plainText(json['title'] as String?),
      executor: plainText(json['executor'] as String?),
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
      editUrl: json['edit_url'] as String? ?? '',
      endIso: json['end'] as String?,
      simViewUrl: json['sim_view_url'] as String?,
      mobileAction: json['mobile_action'] as String?,
      mobileObjectId: _jsonInt(json['mobile_object_id']),
      mobileInApp: json['mobile_in_app'] as bool? ?? false,
    );
  }
}

class NcListItem {
  final int id;
  final String date;
  final String statusLabel;
  final String area;
  final String responsible;
  final String finding;
  final String alertText;
  final bool isDelayed;
  final String openUrl;
  final bool isClosed;

  NcListItem({
    required this.id,
    required this.date,
    required this.statusLabel,
    required this.area,
    required this.responsible,
    required this.finding,
    required this.alertText,
    required this.isDelayed,
    required this.openUrl,
    required this.isClosed,
  });

  factory NcListItem.fromJson(Map<String, dynamic> json) {
    return NcListItem(
      id: json['id'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      statusLabel: plainText(json['status_label'] as String?),
      area: plainText(json['area'] as String?),
      responsible: plainText(json['responsible'] as String?),
      finding: plainText(json['finding'] as String?),
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
      openUrl: json['open_url'] as String? ?? '',
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }
}

class DocumentListItem {
  final int id;
  final String code;
  final String title;
  final String documentType;
  final String publication;
  final String openUrl;

  DocumentListItem({
    required this.id,
    required this.code,
    required this.title,
    required this.documentType,
    required this.publication,
    required this.openUrl,
  });

  factory DocumentListItem.fromJson(Map<String, dynamic> json) {
    return DocumentListItem(
      id: json['id'] as int? ?? 0,
      code: plainText(json['code'] as String?),
      title: plainText(json['title'] as String?),
      documentType: plainText(json['document_type'] as String?),
      publication: json['publication'] as String? ?? '',
      openUrl: json['open_url'] as String? ?? '',
    );
  }
}

class NormativeListItem {
  final int id;
  final String slug;
  final String title;
  final String openUrl;

  NormativeListItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.openUrl,
  });

  factory NormativeListItem.fromJson(Map<String, dynamic> json) {
    return NormativeListItem(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      title: plainText(json['title'] as String?),
      openUrl: json['open_url'] as String? ?? '',
    );
  }
}

class CompanyOption {
  final int id;
  final String name;
  final String logoUrl;

  CompanyOption({
    required this.id,
    required this.name,
    this.logoUrl = '',
  });

  factory CompanyOption.fromJson(Map<String, dynamic> json) {
    return CompanyOption(
      id: json['id'] as int? ?? 0,
      name: plainText(json['name'] as String?),
      logoUrl: json['logo_url'] as String? ?? '',
    );
  }
}

class UserListItem {
  final int id;
  final String name;
  final String email;
  final bool isActive;
  final bool employee;

  UserListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.employee,
  });

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: json['id'] as int? ?? 0,
      name: plainText(json['name'] as String?),
      email: plainText(json['email'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      employee: json['employee'] as bool? ?? true,
    );
  }
}

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String rut;
  final String jobtypeLabel;
  final String observation;
  final bool isActive;
  final bool employee;
  final List<String> positions;
  final int pendingTasks;
  final int skillsCount;
  final int performanceCount;
  final double? performanceAvg;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rut,
    required this.jobtypeLabel,
    required this.observation,
    required this.isActive,
    required this.employee,
    required this.positions,
    required this.pendingTasks,
    required this.skillsCount,
    required this.performanceCount,
    this.performanceAvg,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final positions = (json['positions'] as List<dynamic>? ?? [])
        .map((e) => plainText(e?.toString()))
        .toList();
    return UserProfile(
      id: json['id'] as int? ?? 0,
      name: plainText(json['name'] as String?),
      email: plainText(json['email'] as String?),
      phone: plainText(json['phone'] as String?),
      rut: plainText(json['rut'] as String?),
      jobtypeLabel: plainText(json['jobtype_label'] as String?),
      observation: plainText(json['observation'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      employee: json['employee'] as bool? ?? true,
      positions: positions,
      pendingTasks: summary['pending_tasks'] as int? ?? 0,
      skillsCount: summary['skills_count'] as int? ?? 0,
      performanceCount: summary['performance_count'] as int? ?? 0,
      performanceAvg: (summary['performance_avg'] as num?)?.toDouble(),
    );
  }
}

class UserSkillItem {
  final int id;
  final String skillType;
  final String number;
  final String creation;
  final String deadline;
  final bool effective;
  final String alertText;
  final bool isDelayed;

  UserSkillItem({
    required this.id,
    required this.skillType,
    required this.number,
    required this.creation,
    required this.deadline,
    required this.effective,
    required this.alertText,
    required this.isDelayed,
  });

  factory UserSkillItem.fromJson(Map<String, dynamic> json) {
    return UserSkillItem(
      id: json['id'] as int? ?? 0,
      skillType: plainText(json['skill_type'] as String?),
      number: plainText(json['number'] as String?),
      creation: json['creation'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      effective: json['effective'] as bool? ?? false,
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
    );
  }
}

class UserPerformanceItem {
  final int id;
  final String creation;
  final String start;
  final String end;
  final double? evaluation;
  final String alertText;
  final bool isDelayed;

  UserPerformanceItem({
    required this.id,
    required this.creation,
    required this.start,
    required this.end,
    this.evaluation,
    required this.alertText,
    required this.isDelayed,
  });

  factory UserPerformanceItem.fromJson(Map<String, dynamic> json) {
    return UserPerformanceItem(
      id: json['id'] as int? ?? 0,
      creation: json['creation'] as String? ?? '',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      evaluation: (json['evaluation'] as num?)?.toDouble(),
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
    );
  }
}

class UserTaskItem {
  final int id;
  final String subject;
  final String role;
  final String end;
  final bool isPending;
  final bool? effective;
  final String alertText;
  final bool isDelayed;

  UserTaskItem({
    required this.id,
    required this.subject,
    required this.role,
    required this.end,
    required this.isPending,
    this.effective,
    required this.alertText,
    required this.isDelayed,
  });

  factory UserTaskItem.fromJson(Map<String, dynamic> json) {
    return UserTaskItem(
      id: json['id'] as int? ?? 0,
      subject: plainText(json['subject'] as String?),
      role: plainText(json['role'] as String?),
      end: json['end'] as String? ?? '',
      isPending: json['is_pending'] as bool? ?? true,
      effective: json['effective'] as bool?,
      alertText: plainText(json['alert_text'] as String?),
      isDelayed: json['is_delayed'] as bool? ?? false,
    );
  }
}
