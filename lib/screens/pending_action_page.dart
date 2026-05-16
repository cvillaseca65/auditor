import 'package:flutter/material.dart';

import '../core/theme/content_text.dart';
import '../core/widgets/app_premium_card.dart';
import '../core/widgets/mobile_detail/detail_attachments_section.dart';
import '../core/widgets/mobile_detail/detail_date_format.dart';
import '../core/widgets/mobile_detail/detail_fields_compact.dart';
import '../core/widgets/mobile_detail/detail_rational_section.dart';
import '../core/widgets/mobile_detail/detail_map_fields.dart';
import '../core/widgets/mobile_detail/detail_section_card.dart';
import '../core/widgets/mobile_detail/detail_utils.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';
import '../util/open_sim_url.dart';
import '../util/session_nav.dart';

/// Gestión in-app de un ítem de Mis pendientes (lectura, test, tarea, verificación).
/// El bloque `detail` del API resume el mismo contexto que en SIM en task/update_form.html,
/// riesgo/update_form.html, etc., para poder calificar o verificar con criterio.
class PendingActionPage extends StatefulWidget {
  const PendingActionPage({
    super.key,
    required this.actionType,
    required this.objectId,
    required this.subtitle,
    this.fallbackUrl,
    this.simViewUrl,
    this.onPendingRefresh,
  });

  final String actionType;
  final int objectId;
  final String subtitle;
  /// Formulario completo (edit) en SIM, si aplica.
  final String? fallbackUrl;
  /// Vista solo lectura en SIM (p. ej. task/detail) — preferida para enlaces externos.
  final String? simViewUrl;
  /// Tras guardar en BD: recargar listados padre (misma idea que recargar en web).
  final Future<void> Function()? onPendingRefresh;

  @override
  State<PendingActionPage> createState() => _PendingActionPageState();
}

class _PendingActionPageState extends State<PendingActionPage> {
  final _api = MobileApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _payload;

  final _reportController = TextEditingController();
  final _subjectController = TextEditingController();
  final _agreementController = TextEditingController();
  final _observationController = TextEditingController();
  final _costController = TextEditingController();
  final _planController = TextEditingController();
  bool? _effective;
  final Map<int, int?> _testAnswers = {};

  static const _detailOrder = <String>[
    'kind',
    'entity',
    'title',
    'record_id',
    'activity',
    'crime',
    'process_type',
    'subject',
    'task',
    'anchor',
    'number',
    'checklist_title',
    'checklist_id',
    'creator',
    'executor',
    'responsible',
    'participant',
    'area',
    'create',
    'start',
    'end',
    'date',
    'deadline_days',
    'deatline',
    'alert_text',
    'action_kind',
    'probability',
    'residual_probability',
    'imp',
    'imp_res',
    'impact_inherent',
    'impact_residual',
    'budget',
    'cost',
    'mesure',
    'autoridad',
    'authority',
    'purposes',
    'element_in',
    'element_out',
    'ressource',
    'execution',
    'verification',
    'plan',
    'subject_preview',
    'agreement_preview',
    'observation_existing',
    'report_preview',
    'binnacle_recent',
    'observation',
    'legal_residual',
    'reputation_residual',
    'financ_residual',
    'tolerance_ready',
    'tolerance_hint',
    'priority',
  ];

  static const _detailLabels = <String, String>{
    'kind': 'Tipo',
    'entity': 'Registro',
    'view_label': 'Vista',
    'cumplimiento_intro': 'Cumplimiento (resumen)',
    'cumplimiento': 'Cumplimiento',
    'control_taxonomy': 'Clasificación del requisito',
    'requisito': 'Requisito',
    'control': 'Control',
    'purpose': 'Propósito',
    'guide': 'Guía',
    'other': 'Otros',
    'normative': 'Norma',
    'requirement_title': 'Requisito (título)',
    'code_version': 'Código y versión',
    'solicitation_summary': 'Solicitud',
    'time_line_preview': 'Línea de tiempo',
    'document_record': 'Registro (recuperación, retención…)',
    'target_preview': 'Objetivo (proceso)',
    'reach_preview': 'Alcance',
    'resources_preview': 'Recursos (proceso documento)',
    'content_preview': 'Contenido',
    'description_preview': 'Descripción',
    'definition_preview': 'Definiciones',
    'document_type': 'Tipo de documento',
    'participants_preview': 'Participantes',
    'contacts_preview': 'Contactos',
    'contact': 'Contacto',
    'title': 'Título',
    'record_id': 'N.º registro',
    'view': 'Activación',
    'attachments_preview': 'Adjunto(s)',
    'report': 'Reporte',
    'verification': 'Verificación (fecha)',
    'effective': 'Eficaz (actual)',
    'activity': 'Actividad',
    'crime': 'Delito / norma',
    'process_type': 'Tipo de proceso',
    'subject': 'Asunto',
    'task': 'Descripción / alcance',
    'anchor': 'Ubicación / ancla',
    'number': 'Número',
    'checklist_title': 'Gantt',
    'checklist_id': 'Id gantt',
    'creator': 'Creador',
    'executor': 'Ejecutante',
    'responsible': 'Responsable',
    'participant': 'Participantes',
    'area': 'Área',
    'create': 'Creación',
    'start': 'Inicio',
    'end': 'Fin / plazo',
    'date': 'Fecha',
    'deadline_days': 'Plazo',
    'deatline': 'Plazo',
    'alert_text': 'Plazo',
    'action_kind': 'Tipo acción (hallazgo)',
    'probability': 'Probabilidad %',
    'residual_probability': 'Prob. residual %',
    'imp': 'Impacto',
    'imp_res': 'Impacto residual',
    'impact_inherent': 'Impacto inherente',
    'impact_residual': 'Impacto residual',
    'budget': 'Presupuesto',
    'cost': 'Costo',
    'mesure': 'Unidad',
    'autoridad': 'Autoridad',
    'authority': 'Autoridad',
    'purposes': 'Propósito',
    'element_in': 'Entradas',
    'element_out': 'Salidas',
    'ressource': 'Recursos',
    'autority': 'Autoridad',
    'execution': 'Ejecución',
    'plan': 'Plan de acción general',
    'subject_preview': 'Asunto (actual)',
    'agreement_preview': 'Acuerdos (actual)',
    'observation_existing': 'Observación registrada',
    'report_preview': 'Informe / reporte',
    'binnacle_recent': 'Bitácora (últimos registros)',
    'observation': 'Observación',
    'legal_residual': 'Legal residual',
    'reputation_residual': 'Reputación residual',
    'financ_residual': 'Financiero residual',
    'tolerance_ready': 'Tolerancia lista',
    'tolerance_hint': 'Tolerancia',
    'priority': 'Prioridad',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reportController.dispose();
    _subjectController.dispose();
    _agreementController.dispose();
    _observationController.dispose();
    _costController.dispose();
    _planController.dispose();
    super.dispose();
  }

  /// Recarga el formulario desde el servidor. Devuelve false si ya no hay acción in-app.
  Future<bool> _reloadFromServer({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _api.fetchPendingAction(
        widget.actionType,
        widget.objectId,
      );
      if (!mounted) return false;
      setState(() {
        _payload = data;
        _loading = false;
        _error = null;
      });
      _applyPayloadValues(data);
      return true;
    } on MobileApiException catch (e) {
      if (!mounted) return false;
      if (e.statusCode == 401) {
        await navigateToLogin(context);
        return false;
      }
      final viewUrl = widget.simViewUrl?.trim() ?? '';
      if (e.statusCode == 403 && viewUrl.isNotEmpty && showLoading) {
        await openSimUrl(viewUrl);
        if (mounted) Navigator.of(context).pop();
        return false;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      return false;
    }
  }

  Future<void> _load() async {
    await _reloadFromServer(showLoading: true);
  }

  String get _mode => _payload?['mode'] as String? ?? '';

  String get _title =>
      _payload?['title'] as String? ?? widget.subtitle;

  void _applyPayloadValues(Map<String, dynamic> data) {
    final values = data['values'] as Map<String, dynamic>? ?? {};
    if (data['mode'] == 'close_minute') {
      _subjectController.text = values['subject']?.toString() ?? '';
      _agreementController.text = values['agreement']?.toString() ?? '';
      _observationController.text = values['observation']?.toString() ?? '';
    }
    if (data['mode'] == 'verify_risk') {
      _reportController.clear();
      _observationController.text = values['observation']?.toString() ?? '';
      _planController.text = values['plan']?.toString() ?? '';
    }
  }

  static String _humanizeKey(String key) {
    if (key.isEmpty) return key;
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<Map<String, dynamic>> get _testQuestions {
    final test = _payload?['test'] as Map<String, dynamic>?;
    return (test?['questions'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static String _formatDetailValue(
    String key,
    dynamic raw,
    Map<String, dynamic> detail,
  ) {
    if (raw == null) return '';
    if (key == 'ac') {
      final ncId = detail['nc_id'];
      if (ncId == null || ncId == false || ncId == 0) return '';
    }
    if (key == 'action_kind') {
      final label = raw.toString().trim();
      if (label.isEmpty) return '';
      if (label == 'AC') return 'Acción correctiva (AC)';
      if (label == 'AP') return 'Acción inmediata (AP)';
      return label;
    }
    if ((raw is int || raw is num) &&
        (key == 'deatline' || key == 'deadline_days')) {
      return raw.toString();
    }
    if (raw is bool) {
      if (key == 'ac') {
        final ncId = detail['nc_id'];
        if (ncId == null || ncId == false || ncId == 0) return '';
        return raw ? 'Acción correctiva (AC)' : 'Acción inmediata (AP)';
      }
      if (key == 'view') {
        return raw ? 'Activado' : 'Inactivo';
      }
      if (key == 'effective') {
        return raw ? 'Eficaz' : 'Ineficaz';
      }
      return raw ? 'Sí' : 'No';
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return '';
    final formatted = DetailDateFormat.formatField(key, raw);
    if (formatted.isNotEmpty) return formatted;
    return s;
  }

  String _detailLabelFor(String key) {
    if (widget.actionType == 'minute') {
      if (key == 'start') return 'Fecha de inicio';
      if (key == 'end') return 'Término';
    }
    return _detailLabels[key] ?? _humanizeKey(key);
  }

  Widget _buildContextCard(
    Map<String, dynamic> detail, {
    String? fallbackTitle,
  }) {
    final fields = detailMapToFields(
      detail: detail,
      formatValue: (key, value) {
        final text = _formatDetailValue(key, value, detail);
        return text.isEmpty ? null : text;
      },
      labelFor: _detailLabelFor,
      preferredOrder: _detailOrder,
    );

    if (fields.isEmpty) {
      final fb = (fallbackTitle ?? '').trim();
      if (fb.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DetailSectionCard(
          title: 'Datos del registro',
          icon: Icons.article_outlined,
          child: SelectableText(fb, style: ContentText.fieldValue(context)),
        ),
      );
    }

    if (widget.actionType == 'task') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DetailSectionCard(
          title: 'Tarea',
          icon: Icons.assignment_outlined,
          accentColor: Colors.amber.shade800,
          child: DetailRationalSectionLayout(fields: fields),
        ),
      );
    }

    if (widget.actionType == 'minute') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DetailSectionCard(
          title: 'Minuta',
          icon: Icons.event_note_outlined,
          accentColor: Theme.of(context).colorScheme.tertiary,
          child: DetailRationalSectionLayout(fields: fields),
        ),
      );
    }

    final sections = groupDetailFields(fields);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DetailSectionCard(
              title: section.title,
              icon: section.icon,
              child: DetailRationalSectionLayout(fields: section.fields),
            ),
          ),
      ],
    );
  }

  Future<void> _submit(Map<String, dynamic> body) async {
    setState(() => _saving = true);
    try {
      final result = await _api.submitPendingAction(
        widget.actionType,
        widget.objectId,
        body,
      );
      if (!mounted) return;
      if (result['done'] == true) {
        final message = result['message']?.toString() ?? 'Listo';
        await widget.onPendingRefresh?.call();
        if (!mounted) return;
        final stillInApp = await _reloadFromServer(showLoading: false);
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        if (stillInApp) {
          return;
        }
        Navigator.of(context).pop(true);
        return;
      }
      if (result['mode'] == 'test' && result['test'] != null) {
        setState(() {
          _payload = {
            ...?_payload,
            'mode': 'test',
            'test': result['test'],
          };
          _saving = false;
        });
        return;
      }
      setState(() => _saving = false);
      await _load();
    } on MobileApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _markRead() => _submit({'action': 'mark_read'});

  Future<void> _submitTest() async {
    final answers = <String, int>{};
    for (final entry in _testAnswers.entries) {
      if (entry.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Responda todas las preguntas')),
        );
        return;
      }
      answers['${entry.key}'] = entry.value!;
    }
    await _submit({'action': 'submit_test', 'answers': answers});
  }

  Future<void> _submitReport() async {
    final report = _reportController.text.trim();
    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe requerido')),
      );
      return;
    }
    final body = <String, dynamic>{
      'action': 'report',
      'report': report,
    };
    final cost = _costController.text.trim();
    if (cost.isNotEmpty) {
      body['cost'] = cost;
    }
    await _submit(body);
  }

  Future<void> _submitCloseMinute() async {
    final subject = _subjectController.text.trim();
    final agreement = _agreementController.text.trim();
    if (subject.isEmpty || agreement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asunto y acuerdos son obligatorios')),
      );
      return;
    }
    await _submit({
      'action': 'close',
      'subject': subject,
      'agreement': agreement,
      'observation': _observationController.text.trim(),
    });
  }

  Future<void> _submitVerify() async {
    if (_effective == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique si fue eficaz')),
      );
      return;
    }
    await _submit({
      'action': 'verify',
      'effective': _effective,
      if (_reportController.text.trim().isNotEmpty)
        'report': _reportController.text.trim(),
    });
  }

  Future<void> _submitVerifyRisk() async {
    final report = _reportController.text.trim();
    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe de verificación requerido')),
      );
      return;
    }
    await _submit({
      'action': 'verify',
      'report': report,
      'observation': _observationController.text.trim(),
      'plan': _planController.text.trim(),
    });
  }

  Widget _buildMarkRead() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confirme que ha leído el contenido. Si hay test, se mostrará a continuación.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _markRead,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: const SimLoadingIndicator.compact(),
                )
              : const Text('Marcar como leído'),
        ),
      ],
    );
  }

  Widget _buildTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final q in _testQuestions) ...[
          Text(
            q['question'] as String? ?? '',
            style: ContentText.bodyLarge(context)?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...((q['alternatives'] as List<dynamic>? ?? []).map((alt) {
            final m = Map<String, dynamic>.from(alt as Map);
            final id = m['id'] as int;
            final label = m['label'] as String? ?? '';
            final responseId = q['response_id'] as int;
            return RadioListTile<int>(
              title: Text(label),
              value: id,
              groupValue: _testAnswers[responseId],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _testAnswers[responseId] = v),
            );
          })),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: _saving ? null : _submitTest,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: const SimLoadingIndicator.compact(),
                )
              : const Text('Enviar respuestas'),
        ),
      ],
    );
  }

  Widget _buildReport() {
    return DetailSectionCard(
      title: 'Ejecución',
      icon: Icons.playlist_add_check_outlined,
      accentColor: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _reportController,
            decoration: const InputDecoration(
              labelText: 'Informe de ejecución',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _costController,
            decoration: const InputDecoration(
              labelText: 'Costo (opcional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _saving ? null : _submitReport,
            child: const Text('Reportar ejecución'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyRisk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _reportController,
          decoration: const InputDecoration(
            labelText: 'Informe de verificación *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          minLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _planController,
          decoration: const InputDecoration(
            labelText: 'Plan de acción general',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _observationController,
          decoration: const InputDecoration(
            labelText: 'Observación',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _submitVerifyRisk,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: const SimLoadingIndicator.compact(),
                )
              : const Text('Registrar verificación'),
        ),
      ],
    );
  }

  Widget _buildVerify({bool showReport = false}) {
    return DetailSectionCard(
      title: 'Verificación',
      icon: Icons.fact_check_outlined,
      accentColor: Theme.of(context).colorScheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showReport) ...[
            TextField(
              controller: _reportController,
              decoration: const InputDecoration(
                labelText: 'Informe (opcional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            '¿Fue eficaz?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: true, label: Text('Sí')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: _effective == null ? <bool>{} : {_effective!},
            onSelectionChanged: _saving
                ? null
                : (s) =>
                    setState(() => _effective = s.isEmpty ? null : s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _saving ? null : _submitVerify,
            child: const Text('Registrar verificación'),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseMinute() {
    final values = _payload?['values'] as Map<String, dynamic>? ?? {};
    final startRaw = values['start']?.toString() ?? '';
    final endRaw = values['end']?.toString() ?? '';
    final scheme = Theme.of(context).colorScheme;

    return DetailSectionCard(
      title: 'Cerrar minuta',
      icon: Icons.edit_note_outlined,
      accentColor: scheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (startRaw.isNotEmpty && endRaw.isNotEmpty) ...[
            DetailStartEndPeriodRow(
              startRaw: startRaw,
              endRaw: endRaw,
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Asunto *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _agreementController,
            decoration: const InputDecoration(
              labelText: 'Acuerdos *',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            minLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observationController,
            decoration: const InputDecoration(
              labelText: 'Observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _saving ? null : _submitCloseMinute,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: SimLoadingIndicator.compact(),
                  )
                : const Text('Cerrar minuta'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBody() {
    switch (_mode) {
      case 'mark_read':
        return _buildMarkRead();
      case 'test':
        return _buildTest();
      case 'report':
        return _buildReport();
      case 'close_minute':
        return _buildCloseMinute();
      case 'verify':
        final isTask = widget.actionType == 'task';
        return _buildVerify(showReport: !isTask);
      case 'verify_risk':
        return _buildVerifyRisk();
      case 'view':
        return _buildViewOnly();
      default:
        return Center(
          child: Text('Modo no reconocido: $_mode'),
        );
    }
  }

  Widget _buildViewOnly() {
    final msg = _payload?['view_only_message'] as String? ??
        'Pendiente de acción de otra persona. Consulte el detalle arriba '
        'o abra el registro en SIM.';
    final viewUrl = widget.simViewUrl?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    msg,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (viewUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => openSimUrl(viewUrl),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir vista en SIM'),
          ),
        ],
      ],
    );
  }

  List<Widget> _scrollChildren() {
    final detailRaw = _payload?['detail'];
    final list = <Widget>[];
    if (detailRaw is Map) {
      list.add(
        _buildContextCard(
          Map<String, dynamic>.from(detailRaw),
          fallbackTitle: _title,
        ),
      );
    }
    final attachments = DetailUtils.normalizeAttachments(
      _payload?['attachments'] as List<dynamic>?,
    );
    if (attachments.isNotEmpty) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DetailAttachmentsSection(files: attachments),
        ),
      );
    }
    if (_mode == 'verify_risk') {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'El informe de verificación es obligatorio.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    list.add(_buildModeBody());
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasView = widget.simViewUrl != null && widget.simViewUrl!.isNotEmpty;
    final hasEdit = widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_loading ? widget.subtitle : _title, maxLines: 2),
        actions: [
          if (hasView)
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Ver en SIM (vista)',
              onPressed: () => openSimUrl(widget.simViewUrl!),
            ),
          if (hasEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Formulario completo en SIM',
              onPressed: () => openSimUrl(widget.fallbackUrl!),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: SimLoadingIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : AppScreenBackdrop(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _scrollChildren(),
                    ),
                  ),
                ),
    );
  }
}
