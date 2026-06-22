import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/widgets/audit_item_title.dart';
import '../core/widgets/audit_verification_status_badge.dart';
import '../core/widgets/mobile_detail/detail_attachments_section.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/audit_verification_service.dart';
import '../services/session_service.dart';
import '../util/file_bytes.dart';
import '../util/session_nav.dart';
import '../util/strip_html.dart';
import 'hallazgos_detail_page.dart';

/// Pantalla de verificación de un punto del plan (equivalente al modal web).
class AuditCheckItemVerifyPage extends StatefulWidget {
  const AuditCheckItemVerifyPage({
    super.key,
    required this.checkItemId,
  });

  final int checkItemId;

  @override
  State<AuditCheckItemVerifyPage> createState() =>
      _AuditCheckItemVerifyPageState();
}

class _PendingUpload {
  _PendingUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
  String description = '';
}

class _AuditCheckItemVerifyPageState extends State<AuditCheckItemVerifyPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _detail;

  late final TextEditingController _evidence;
  late final TextEditingController _ncFinding;
  bool _showNcPanel = false;
  final List<_PendingUpload> _pendingUploads = [];

  Future<AuditVerificationService?> _service() async {
    final headers = await SessionService.authCompanyHeaders();
    if (headers == null) return null;
    final token = headers['Authorization']!.replaceFirst('Bearer ', '');
    final companyId = int.parse(headers['X-Company-ID']!);
    return AuditVerificationService(token: token, companyId: companyId);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await _service();
      if (!mounted) return;
      if (api == null) {
        setState(() {
          _error = 'Seleccione una organización para continuar.';
          _loading = false;
        });
        return;
      }
      final data = await api.fetchDetail(widget.checkItemId);
      if (!mounted) return;
      final line = data['line'] as Map<String, dynamic>?;
      _evidence.text = stripHtml(line?['evidence']?.toString());
      setState(() {
        _detail = data;
        _loading = false;
      });
    } on AuditVerificationException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await navigateToLogin(context);
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _evidence = TextEditingController();
    _ncFinding = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _evidence.dispose();
    _ncFinding.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && !kIsWeb) {
        final p = file.path;
        if (p != null && p.isNotEmpty) {
          bytes = await readLocalFileBytes(p);
        }
      }
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _pendingUploads.add(_PendingUpload(name: file.name, bytes: bytes!));
        });
      }
    }
  }

  Future<void> _submit(int status) async {
    if (_saving) return;
    final ncFinding = _ncFinding.text.trim();
    if (status == 2 && ncFinding.isEmpty) {
      setState(() => _showNcPanel = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describa el hallazgo antes de crear la no conformidad.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = await _service();
      if (!mounted) return;
      if (api == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione una organización para continuar.'),
          ),
        );
        return;
      }
      await api.submit(
        checkItemId: widget.checkItemId,
        status: status,
        evidence: _evidence.text.trim(),
        ncFinding: ncFinding,
        uploads: _pendingUploads
            .map(
              (u) => (
                name: u.name,
                bytes: u.bytes,
                description: u.description,
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuditVerificationException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await navigateToLogin(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación'),
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
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final mayEdit = d['may_edit'] as bool? ?? false;
    final line = d['line'] as Map<String, dynamic>?;
    final attachFiles = line != null
        ? List<Map<String, dynamic>>.from(line['attach_files'] ?? [])
        : <Map<String, dynamic>>[];
    final ncIds = List<int>.from(
      (d['nc_ids'] as List?)?.map((e) => int.parse('$e')) ?? const [],
    );
    final status = int.tryParse('${d['status']}') ?? 0;

    if (!mayEdit) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildAuditItemTopicHeader(context, d),
            const SizedBox(height: 12),
            _resultReadOnly(status, ncIds),
            if (_evidence.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_evidence.text),
            ],
            if (attachFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              DetailAttachmentsSection(files: attachFiles),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildAuditItemTopicHeader(context, d),
          const SizedBox(height: 12),
          TextField(
            controller: _evidence,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Evidencia',
              hintText: 'Describa la evidencia verificada…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (attachFiles.isNotEmpty) ...[
            DetailAttachmentsSection(files: attachFiles),
            const SizedBox(height: 12),
          ],
          if (_pendingUploads.isNotEmpty) ...[
            ..._pendingUploads.map(
              (u) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file, size: 20),
                title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _pendingUploads.remove(u)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('Adjuntar archivos'),
          ),
          if (_showNcPanel) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hallazgo (no conformidad)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ncFinding,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describa el hallazgo…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Al guardar se creará el registro de hallazgo en el módulo NC.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _submit(1),
                  child: _saving && !_showNcPanel
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Conforme'),
                ),
              ),
              const SizedBox(width: 8),
              if (!_showNcPanel)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _showNcPanel = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: const Text('No conforme'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _submit(2),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear hallazgo'),
                  ),
                ),
            ],
          ),
          if (ncIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ncIds
                  .map(
                    (id) => ActionChip(
                      label: Text('Ver hallazgo #$id'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HallazgosDetailPage(ncId: id),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultReadOnly(int status, List<int> ncIds) {
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
}
