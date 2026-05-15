import 'package:flutter/material.dart';

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
    this.onCompleted,
  });

  final String actionType;
  final int objectId;
  final String subtitle;
  /// Formulario completo (edit) en SIM, si aplica.
  final String? fallbackUrl;
  /// Vista solo lectura en SIM (p. ej. task/detail) — preferida para enlaces externos.
  final String? simViewUrl;
  final VoidCallback? onCompleted;

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
    'ac',
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
    'ac': 'Tipo acción',
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchPendingAction(
        widget.actionType,
        widget.objectId,
      );
      if (!mounted) return;
      setState(() {
        _payload = data;
        _loading = false;
      });
      _applyPayloadValues(data);
    } on MobileApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await navigateToLogin(context);
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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

  static String _formatDetailValue(String key, dynamic raw) {
    if (raw == null) return '';
    if ((raw is int || raw is num) &&
        (key == 'deatline' || key == 'deadline_days')) {
      return raw.toString();
    }
    if (raw is bool) {
      if (key == 'ac') {
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
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return '${iso.day.toString().padLeft(2, '0')}/'
          '${iso.month.toString().padLeft(2, '0')}/${iso.year}';
    }
    return s;
  }

  Widget _buildContextCard(
    Map<String, dynamic> detail, {
    String? fallbackTitle,
  }) {
    final theme = Theme.of(context);
    final seen = <String>{};
    final rows = <Widget>[];

    void addRow(String key, dynamic value) {
      if (key == 'display_key_order') return;
      final text = _formatDetailValue(key, value);
      if (text.isEmpty) return;
      final label = _detailLabels[key] ?? _humanizeKey(key);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final explicitOrder = detail['display_key_order'];
    if (explicitOrder is List<dynamic>) {
      for (final rawKey in explicitOrder) {
        if (rawKey is! String) continue;
        if (!detail.containsKey(rawKey)) continue;
        seen.add(rawKey);
        addRow(rawKey, detail[rawKey]);
      }
    } else {
      for (final key in _detailOrder) {
        if (!detail.containsKey(key)) continue;
        seen.add(key);
        addRow(key, detail[key]);
      }
    }
    for (final e in detail.entries) {
      if (e.key == 'display_key_order') continue;
      if (seen.contains(e.key)) continue;
      addRow(e.key, e.value);
    }

    if (rows.isEmpty) {
      final fb = (fallbackTitle ?? '').trim();
      if (fb.isNotEmpty) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos del registro',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(fb, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos del registro',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
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
        widget.onCompleted?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Listo',
            ),
          ),
        );
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
                  child: CircularProgressIndicator(strokeWidth: 2),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar respuestas'),
        ),
      ],
    );
  }

  Widget _buildReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _reportController,
          decoration: const InputDecoration(
            labelText: 'Informe de ejecución',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _costController,
          decoration: const InputDecoration(
            labelText: 'Costo (opcional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _submitReport,
          child: const Text('Reportar ejecución'),
        ),
      ],
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar verificación'),
        ),
      ],
    );
  }

  Widget _buildVerify({bool showReport = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showReport) ...[
          TextField(
            controller: _reportController,
            decoration: const InputDecoration(
              labelText: 'Informe (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Eficaz',
          style: Theme.of(context).textTheme.titleSmall,
        ),
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
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _submitVerify,
          child: const Text('Registrar verificación'),
        ),
      ],
    );
  }

  Widget _buildCloseMinute() {
    final values = _payload?['values'] as Map<String, dynamic>? ?? {};
    final start = values['start']?.toString();
    final end = values['end']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (start != null && start.isNotEmpty)
          Text('Inicio: $start', style: Theme.of(context).textTheme.bodySmall),
        if (end != null && end.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Fin: $end', style: Theme.of(context).textTheme.bodySmall),
          ),
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
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _submitCloseMinute,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cerrar minuta'),
        ),
      ],
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
      default:
        return Center(
          child: Text('Modo no reconocido: $_mode'),
        );
    }
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
    if (_mode == 'verify' || _mode == 'verify_risk') {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _mode == 'verify_risk'
                ? 'Verificación de riesgo: el bloque superior resume el registro como en SIM. El informe de verificación es obligatorio.'
                : 'Verifique la eficacia en relación con el contexto mostrado arriba (mismo criterio que en SIM).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          ? const Center(child: CircularProgressIndicator())
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _scrollChildren(),
                  ),
                ),
    );
  }
}
