import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/widgets/audit_item_title.dart';
import '../core/widgets/audit_verification_status_badge.dart';
import '../core/widgets/sim_loading_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/session_service.dart';
import '../util/file_bytes.dart';
import 'audit_check_item_verify_page.dart';
import 'hallazgos_detail_page.dart';

class LinesPage extends StatefulWidget {
  final Map<String, dynamic> plan;

  const LinesPage({super.key, required this.plan});

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  Map<String, dynamic>? planFull;
  List<Map<String, dynamic>> lines = [];
  bool isLoading = true;
  String error = '';

  bool get _hasChecklist {
    final grouped = planFull?['check_items_grouped'] as List?;
    if (grouped != null && grouped.isNotEmpty) return true;
    final flat = planFull?['check_items'] as List?;
    return flat != null && flat.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    fetchPlanFull();
  }

  Future<String?> _token() => SessionService.getToken();

  Future<void> fetchPlanFull() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final headers = await SessionService.authCompanyHeaders();
    if (headers == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = 'Seleccione una organización para continuar.';
        });
      }
      return;
    }

    final url =
        '${ApiConfig.baseUrl}/api/v1/plans/${widget.plan['id']}/full/';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        planFull = data;
        lines = List<Map<String, dynamic>>.from(data['lines'] ?? []);
        lines.sort((a, b) {
          final na = '${a['name'] ?? ''}'.toLowerCase();
          final nb = '${b['name'] ?? ''}'.toLowerCase();
          return na.compareTo(nb);
        });
      } else {
        error = 'Error ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error fetching plan: $e';
    }

    setState(() => isLoading = false);
  }

  Future<void> _openCheckItem(Map<String, dynamic> item) async {
    final token = await _token();
    if (token == null || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuditCheckItemVerifyPage(
          checkItemId: int.parse('${item['id']}'),
        ),
      ),
    );
    if (saved == true) {
      await fetchPlanFull();
    }
  }

  Widget _statusBadge(Map<String, dynamic> item) {
    final status = int.tryParse('${item['status']}') ?? 0;
    final ncIds = List<int>.from(
      (item['nc_ids'] as List?)?.map((e) => int.parse('$e')) ?? const [],
    );
    return AuditVerificationStatusBadge(
      status: status,
      ncIds: ncIds,
      onNcTap: status == 2 && ncIds.isNotEmpty
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HallazgosDetailPage(ncId: ncIds.first),
                ),
              );
            }
          : null,
    );
  }

  Widget _buildChecklistRow(
    Map<String, dynamic> item, {
    String? topic,
  }) {
    final titleWidget = buildAuditItemTitle(context, item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCheckItem(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (topic != null)
                SizedBox(
                  width: 88,
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              Expanded(child: titleWidget),
              const SizedBox(width: 8),
              _statusBadge(item),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItems() {
    final grouped =
        List<Map<String, dynamic>>.from(planFull?['check_items_grouped'] ?? []);
    final flat =
        List<Map<String, dynamic>>.from(planFull?['check_items'] ?? []);

    if (grouped.isEmpty && flat.isEmpty) {
      return const SizedBox.shrink();
    }

    final progress = planFull?['check_progress'] as Map<String, dynamic>?;
    final done = progress?['done'] ?? 0;
    final total = progress?['total'] ?? flat.length;

    final rows = <Widget>[];

    if (grouped.isNotEmpty) {
      for (final group in grouped) {
        final topic = group['scope_kind_label']?.toString() ?? '';
        final items =
            List<Map<String, dynamic>>.from(group['items'] ?? []);
        for (var i = 0; i < items.length; i++) {
          rows.add(
            _buildChecklistRow(
              items[i],
              topic: i == 0 ? topic : null,
            ),
          );
          if (i < items.length - 1) {
            rows.add(const Divider(height: 1));
          }
        }
        rows.add(const Divider(height: 16));
      }
    } else {
      for (var i = 0; i < flat.length; i++) {
        rows.add(_buildChecklistRow(flat[i]));
        if (i < flat.length - 1) {
          rows.add(const Divider(height: 1));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verificación ($done/$total)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Toque cada punto para registrar evidencia y resultado.',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showLineEditor({Map<String, dynamic>? line}) async {
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => LineEvidenceEditorDialog(
        planId: int.parse(widget.plan['id'].toString()),
        existingLine: line,
        fetchPlanFull: fetchPlanFull,
        onParentSnack: (message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      ),
    );
  }

  Widget buildTopics(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...items.map((e) => InkWell(
              onTap: () async {
                final urlStr = e['url']?.toString() ?? '';
                if (urlStr.isNotEmpty) {
                  final url = Uri.parse(urlStr);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  e['name'],
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: SimLoadingIndicator()));
    }

    if (error.isNotEmpty) {
      return Scaffold(body: Center(child: Text(error)));
    }

    final auditedName = planFull?['audited']?['name']?.toString() ?? '';
    final positionName = planFull?['position']?['name']?.toString() ?? '';
    final locationName = planFull?['location']?['name']?.toString() ?? '';
    final titleParts = [auditedName, positionName, locationName]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleParts.isNotEmpty ? titleParts : 'Líneas de auditoría',
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
      floatingActionButton: _hasChecklist
          ? null
          : FloatingActionButton(
              onPressed: () => _showLineEditor(),
              child: const Icon(Icons.add),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckItems(),
            if (!_hasChecklist) ...[
              buildTopics("Customers", planFull?['customers'] ?? []),
              buildTopics("Assets", planFull?['assets'] ?? []),
              buildTopics("Documents", planFull?['documents'] ?? []),
              buildTopics("Kpis", planFull?['kpis'] ?? []),
              buildTopics("Minutes", planFull?['minutes'] ?? []),
              buildTopics("Nc", planFull?['ncs'] ?? []),
              buildTopics("Normativa", planFull?['complys'] ?? []),
              buildTopics("Comités", planFull?['committees'] ?? []),
              buildTopics("Objetivos", planFull?['objectives'] ?? []),
              buildTopics("Oportunidades", planFull?['opportunitys'] ?? []),
              buildTopics("Proyectos", planFull?['projects'] ?? []),
              buildTopics("Cargos", planFull?['positions'] ?? []),
              buildTopics("Procesos", planFull?['processs'] ?? []),
              buildTopics("Repositorios", planFull?['repositorys'] ?? []),
              buildTopics("Riesgos", planFull?['risks'] ?? []),
              buildTopics("Proveedores", planFull?['suppliers'] ?? []),
              buildTopics("Checlist", planFull?['checklists'] ?? []),
              buildTopics("Ítems", planFull?['items'] ?? []),
              buildTopics("Cambios", planFull?['changes'] ?? []),
              buildTopics("Capacitación", planFull?['trainings'] ?? []),
              buildTopics("Revisión Gerencia", planFull?['reviews'] ?? []),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text("Lines",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...lines.map((line) {
                final attachments =
                    List<Map<String, dynamic>>.from(line['attach_files'] ?? []);

                return Card(
                  child: ListTile(
                    title: Text(line['name'] ?? 'Line ${line['id']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (attachments.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.insert_drive_file),
                            onPressed: () async {
                              final fileUrl = attachments.first['attach_file'];
                              if (fileUrl != null) {
                                final uri = Uri.parse(fileUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                          ),
                        const Icon(Icons.edit),
                      ],
                    ),
                    onTap: () => _showLineEditor(line: line),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Evidencia libre (planes sin checklist de verificación).
class LineEvidenceEditorDialog extends StatefulWidget {
  const LineEvidenceEditorDialog({
    super.key,
    required this.planId,
    required this.fetchPlanFull,
    required this.onParentSnack,
    this.existingLine,
  });

  final int planId;
  final Map<String, dynamic>? existingLine;
  final Future<void> Function() fetchPlanFull;
  final void Function(String message) onParentSnack;

  @override
  State<LineEvidenceEditorDialog> createState() =>
      _LineEvidenceEditorDialogState();
}

class _LineEvidenceEditorDialogState extends State<LineEvidenceEditorDialog> {
  late final TextEditingController _evidence;
  late final bool _openedAsNewLine;
  int? _serverLineId;

  @override
  void initState() {
    super.initState();
    _openedAsNewLine = widget.existingLine == null;
    _evidence = TextEditingController(
      text: widget.existingLine != null
          ? '${widget.existingLine!['name'] ?? ''}'
          : '',
    );
    if (widget.existingLine != null) {
      _serverLineId = int.tryParse('${widget.existingLine!['id']}');
    }
  }

  @override
  void dispose() {
    _evidence.dispose();
    super.dispose();
  }

  String _defaultEvidenceLabelFromFileName(String fileName) {
    final t = fileName.trim();
    if (t.isEmpty) return 'Evidencia (archivo)';
    return t;
  }

  Future<({int? id, String? errorHint})> _createLineApi(
    Map<String, String> headers,
    String evidence,
  ) async {
    final url = '${ApiConfig.baseUrl}/api/v1/lines/';
    final bodyMap = <String, dynamic>{
      'plan': widget.planId,
      'name': evidence,
    };
    final body = jsonEncode(bodyMap);
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      if (response.statusCode != 200 && response.statusCode != 201) {
        return (
          id: null,
          errorHint: _shortServerErrorMessage(response.body),
        );
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final rawId = map['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      if (id == null) {
        return (id: null, errorHint: 'El servidor no devolvió el id de la línea.');
      }
      return (id: id, errorHint: null);
    } catch (e) {
      return (id: null, errorHint: '$e');
    }
  }

  static String? _shortServerErrorMessage(String body) {
    final t = body.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      if (decoded is Map) {
        final d = decoded['detail'];
        if (d != null) return '$d';
        final name = decoded['name'];
        if (name is List && name.isNotEmpty) return '${name.first}';
        if (name != null) return '$name';
        final plan = decoded['plan'];
        if (plan is List && plan.isNotEmpty) return '${plan.first}';
        if (plan != null) return '$plan';
      }
    } catch (_) {
      /* cuerpo no JSON */
    }
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }

  Future<bool> _uploadSingleFile({
    required Map<String, String> headers,
    required int lineId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/lines/upload/'),
    );
    request.headers.addAll(headers);
    request.fields['line'] = lineId.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'attach_file',
        bytes,
        filename: fileName,
      ),
    );
    try {
      final streamed = await request.send().timeout(
            Duration(seconds: ApiConfig.timeoutSeconds),
          );
      final res = await http.Response.fromStream(streamed);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickAndUploadAttachments() async {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final headers = await SessionService.authCompanyHeaders();
    if (!mounted) return;
    if (headers == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una organización para continuar.')),
      );
      return;
    }

    final resolved = <({String name, Uint8List bytes})>[];
    var skippedWeb = false;
    for (final file in result.files) {
      Uint8List? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        final p = file.path;
        if (!kIsWeb && p != null && p.isNotEmpty) {
          bytes = await readLocalFileBytes(p);
        }
      }
      if (bytes != null && bytes.isNotEmpty) {
        resolved.add((name: file.name, bytes: bytes));
      } else if (kIsWeb) {
        skippedWeb = true;
      }
    }

    if (!mounted) return;

    if (skippedWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo leer un archivo en el navegador. '
            'Prueba otro archivo o uno más pequeño.',
          ),
        ),
      );
    }

    if (resolved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron leer los archivos. '
            'Vuelve a elegirlos o revisa permisos.',
          ),
        ),
      );
      return;
    }

    late final int lineIdToUse;
    if (_serverLineId != null) {
      lineIdToUse = _serverLineId!;
    } else {
      final trimmed = _evidence.text.trim();
      final evidenceLabel = trimmed.isNotEmpty
          ? trimmed
          : _defaultEvidenceLabelFromFileName(resolved.first.name);

      final created = await _createLineApi(headers, evidenceLabel);
      if (!mounted) return;
      final createdId = created.id;
      if (createdId == null) {
        final hint = created.errorHint;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              hint != null && hint.isNotEmpty
                  ? 'No se pudo crear la evidencia: $hint'
                  : 'No se pudo crear la evidencia en el servidor. '
                      'Revisa la conexión o escribe un texto y pulsa Guardar.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _serverLineId = createdId;
        if (trimmed.isEmpty) {
          _evidence.text = evidenceLabel;
        }
      });
      lineIdToUse = createdId;
    }

    var anyFailed = false;
    for (final f in resolved) {
      final ok = await _uploadSingleFile(
        headers: headers,
        lineId: lineIdToUse,
        fileName: f.name,
        bytes: f.bytes,
      );
      if (!ok) anyFailed = true;
      if (!mounted) return;
    }

    await widget.fetchPlanFull();

    if (!mounted) return;

    if (_openedAsNewLine) {
      Navigator.of(context).pop();
      widget.onParentSnack(
        anyFailed
            ? 'Evidencia creada; algunos archivos no se subieron'
            : 'Evidencia creada y archivos subidos',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            anyFailed
                ? 'Algunos archivos no se pudieron subir'
                : 'Archivos subidos',
          ),
        ),
      );
    }
  }

  Future<void> _saveEvidenceTextOnly() async {
    if (_evidence.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escribe la evidencia o usa «Subir / Cámara» para adjuntar un archivo sin texto.',
          ),
        ),
      );
      return;
    }

    final headers = await SessionService.authCompanyHeaders();
    if (!mounted) return;
    if (headers == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una organización para continuar.')),
      );
      return;
    }

    final url = _serverLineId != null
        ? '${ApiConfig.baseUrl}/api/v1/lines/$_serverLineId/'
        : '${ApiConfig.baseUrl}/api/v1/lines/';
    final body = jsonEncode({
      'plan': widget.planId,
      'name': _evidence.text,
    });

    final response = await (_serverLineId != null
            ? http.put(
                Uri.parse(url),
                headers: {
                  ...headers,
                  'Content-Type': 'application/json',
                },
                body: body,
              )
            : http.post(
                Uri.parse(url),
                headers: {
                  ...headers,
                  'Content-Type': 'application/json',
                },
                body: body,
              ))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      await widget.fetchPlanFull();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingLine == null;
    return AlertDialog(
      title: Text(isNew ? 'Nueva evidencia' : 'Editar evidencia'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _evidence,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Texto de la evidencia (opcional si adjuntas archivos)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Subir / Cámara'),
              onPressed: _pickAndUploadAttachments,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveEvidenceTextOnly,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
