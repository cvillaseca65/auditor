import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../core/widgets/sim_loading_indicator.dart';
import 'package:flutter/services.dart';

import '../services/mobile_api_service.dart';
import '../services/nc_hallazgos_service.dart';
import '../services/session_service.dart';

/// Formulario in-app para la etapa actual del workflow NC.
class HallazgosWorkflowSection extends StatefulWidget {
  const HallazgosWorkflowSection({
    super.key,
    required this.ncId,
    required this.workflow,
    required this.onUpdated,
  });

  final int ncId;
  final Map<String, dynamic> workflow;
  final VoidCallback onUpdated;

  @override
  State<HallazgosWorkflowSection> createState() =>
      _HallazgosWorkflowSectionState();
}

class _HallazgosWorkflowSectionState extends State<HallazgosWorkflowSection> {
  final _api = MobileApiService();
  bool _saving = false;

  int? _typeId;
  int? _areaId;
  int? _locationId;
  IdTitle? _analyst;
  int? _causeTypeId;
  final _causeController = TextEditingController();
  final _commentController = TextEditingController();
  final _rejectObservationController = TextEditingController();
  bool? _effective;

  @override
  void initState() {
    super.initState();
    _readValues();
  }

  @override
  void didUpdateWidget(HallazgosWorkflowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workflow != widget.workflow) {
      _readValues();
    }
  }

  void _readValues() {
    final v = widget.workflow['values'] as Map<String, dynamic>? ?? {};
    _typeId = _readInt(v['type_id']);
    _areaId = _readInt(v['area_id']);
    _locationId = _readInt(v['location_id']);
    _causeTypeId = _readInt(v['cause_type_id']);
    _causeController.text = v['cause']?.toString() ?? '';
    _commentController.text = v['comment']?.toString() ?? '';
    _rejectObservationController.text = v['observation']?.toString() ?? '';
    _effective = v['effective'] as bool?;
    final causeUserId = _readInt(v['cause_user_id']);
    if (causeUserId != null) {
      _analyst = IdTitle(id: causeUserId, title: 'Usuario #$causeUserId');
    }
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  @override
  void dispose() {
    _causeController.dispose();
    _commentController.dispose();
    _rejectObservationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _options =>
      widget.workflow['options'] as Map<String, dynamic>? ?? {};

  List<Map<String, dynamic>> _choices(String key) {
    final raw = (_options[key] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final m in raw) {
      final id = m['id'];
      if (id is int) continue;
      if (id is num) {
        m['id'] = id.toInt();
      } else if (id != null) {
        m['id'] = int.tryParse(id.toString());
      }
    }
    return raw;
  }

  Future<void> _submit(Map<String, dynamic> body) async {
    setState(() => _saving = true);
    try {
      await _api.submitNcWorkflow(widget.ncId, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
      widget.onUpdated();
    } on MobileApiException catch (e) {
      if (!mounted) return;
      await _showErrorWithCopy(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showErrorWithCopy(BuildContext scaffoldContext, String message) async {
    await showDialog<void>(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No se pudo guardar'),
        content: SingleChildScrollView(
          child: SelectableText(
            message.isEmpty ? 'Error desconocido' : message,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<int?> onChanged,
  }) {
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: 'Sin opciones disponibles',
        ),
        child: const SizedBox.shrink(),
      );
    }
    final initial = items.any((e) => e['id'] == value) ? value : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$initial-${items.length}'),
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .where((e) => e['id'] != null && e['id'] is int)
          .map(
            (e) => DropdownMenuItem<int>(
              value: e['id'] as int,
              child: Text(e['title']?.toString() ?? ''),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _effectiveSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Fue eficaz?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: true, label: Text('Sí')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: _effective == null ? <bool>{} : {_effective!},
          onSelectionChanged: (s) =>
              setState(() => _effective = s.isEmpty ? null : s.first),
        ),
      ],
    );
  }

  Widget _buildCrea() {
    final types = _choices('types');
    final areas = _choices('areas');
    final locations = _choices('locations');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          label: 'Tipo de hallazgo *',
          value: _typeId,
          items: types,
          onChanged: (v) => setState(() => _typeId = v),
        ),
        const SizedBox(height: 12),
        if (areas.isNotEmpty)
          _dropdown(
            label: 'Área',
            value: _areaId,
            items: areas,
            onChanged: (v) => setState(() => _areaId = v),
          ),
        if (areas.isNotEmpty) const SizedBox(height: 12),
        if (locations.isNotEmpty)
          _dropdown(
            label: 'Localidad',
            value: _locationId,
            items: locations,
            onChanged: (v) => setState(() => _locationId = v),
          ),
        if (locations.isNotEmpty) const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () => _submit({
                      'action': 'authorize',
                      'type_id': _typeId,
                      if (_areaId != null) 'area_id': _areaId,
                      'location_id': _locationId,
                    }),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: const SimLoadingIndicator.compact(),
                  )
                : const Text('Autorizar'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rejectObservationController,
          decoration: const InputDecoration(
            labelText: 'Motivo de rechazo',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _saving
                ? null
                : () => _submit({
                      'action': 'reject',
                      'observation': _rejectObservationController.text.trim(),
                    }),
            child: const Text('Rechazar'),
          ),
        ),
      ],
    );
  }

  Widget _buildAsigna() {
    final showEffective = _options['show_effective'] as bool? ?? false;
    final hasAp = _options['has_ap_tasks'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownSearch<IdTitle>(
          selectedItem: _analyst,
          itemAsString: (u) => u.title,
          compareFn: (a, b) => a.id == b.id,
          items: (filter, _) async {
            final token = await SessionService.getToken();
            final companyId = await SessionService.getCompanyId();
            if (token == null || companyId == null) return [];
            final r = await NcHallazgosService.searchCompanyUsers(
              token: token,
              companyId: companyId,
              query: filter,
            );
            return r.items;
          },
          onChanged: (v) => setState(() => _analyst = v),
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            disableFilter: true,
            searchDelay: Duration(milliseconds: 400),
          ),
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: 'Analista de causa',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving || _analyst == null
                ? null
                : () => _submit({
                      'action': 'assign_analyst',
                      'cause_user_id': _analyst!.id,
                    }),
            child: const Text('Asignar analista'),
          ),
        ),
        if (showEffective && hasAp) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Cierre SNC (sin analista, con AP)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _effectiveSwitch(),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: _saving || _effective == null
                  ? null
                  : () => _submit({
                        'action': 'close_snc',
                        'effective': _effective,
                      }),
              child: const Text('Cerrar como SNC'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalisa() {
    final causeTypes = _choices('cause_types');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (causeTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No hay tipos de causa configurados para esta empresa. '
              'Configure "Tipos de causa" en SIM o contacte al administrador.',
              style: TextStyle(color: Colors.orange),
            ),
          )
        else
          _dropdown(
            label: 'Tipo de causa *',
            value: _causeTypeId,
            items: causeTypes,
            onChanged: (v) => setState(() => _causeTypeId = v),
          ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96, maxHeight: 280),
          child: TextField(
            controller: _causeController,
            decoration: const InputDecoration(
              labelText: 'Causa raíz *',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            minLines: null,
            maxLines: null,
            expands: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () => _submit({
                      'action': 'submit_analysis',
                      'cause_type_id': _causeTypeId,
                      'cause': _causeController.text.trim(),
                    }),
            child: const Text('Enviar análisis'),
          ),
        ),
      ],
    );
  }

  Widget _buildAprueba() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () => _submit({'action': 'approve_analysis'}),
            child: const Text('Aprobar análisis'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Comentario (si rechaza)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _saving
                ? null
                : () => _submit({
                      'action': 'reject_analysis',
                      'comment': _commentController.text.trim(),
                    }),
            child: const Text('Rechazar análisis'),
          ),
        ),
      ],
    );
  }

  Widget _buildClose() {
    final actions = (widget.workflow['actions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (!actions.contains('close')) {
      // Misma regla que NcCloseUpdateView (nc_show_effective_allowed) y
      // nc_close_form.html: todas las tareas con verificación, o ninguna tarea.
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Para cerrar la NC, todas las acciones inmediatas y correctivas '
              'asociadas al hallazgo deben estar verificadas.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete o verifique en SIM web las tareas pendientes; cuando no '
              'quede ninguna sin verificar, podrá indicar la eficacia y cerrar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _effectiveSwitch(),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _saving || _effective == null
                ? null
                : () => _submit({
                      'action': 'close',
                      'effective': _effective,
                    }),
            child: const Text('Cerrar hallazgo (AC)'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.workflow['stage']?.toString();
    final stageLabel = widget.workflow['stage_label']?.toString() ?? '';

    Widget form;
    switch (stage) {
      case 'crea':
        form = _buildCrea();
        break;
      case 'asigna':
        form = _buildAsigna();
        break;
      case 'analisa':
        form = _buildAnalisa();
        break;
      case 'aprueba_analisis':
        form = _buildAprueba();
        break;
      case 'close':
        form = _buildClose();
        break;
      default:
        form = const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stageLabel.isNotEmpty ? stageLabel : 'Su gestión',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.workflow['status_label']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            form,
          ],
        ),
      ),
    );
  }
}
