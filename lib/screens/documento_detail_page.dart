import 'package:flutter/material.dart';

import '../core/widgets/mobile_detail/detail_utils.dart';
import '../core/widgets/mobile_detail/mobile_entity_detail_body.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/session_nav.dart';

class DocumentoDetailPage extends StatefulWidget {
  final int documentId;

  const DocumentoDetailPage({super.key, required this.documentId});

  @override
  State<DocumentoDetailPage> createState() => _DocumentoDetailPageState();
}

class _DocumentoDetailPageState extends State<DocumentoDetailPage> {
  final _api = MobileApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.fetchDocumentDetail(widget.documentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el documento. Compruebe la conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documento')),
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
    final d = _data!;
    final code = plainText(d['code']?.toString());
    final title = plainText(d['title']?.toString());
    final docType = plainText(d['document_type']?.toString());

    return MobileEntityDetailBody(
      title: [code, title].where((s) => s.isNotEmpty).join(' · '),
      subtitle: docType.isNotEmpty ? docType : null,
      fields: DetailUtils.normalizeFields(d['fields'] as List<dynamic>?),
      attachments: DetailUtils.normalizeAttachments(d['files'] as List<dynamic>?),
      relations: d['relations'] as List<dynamic>? ?? [],
      simOpenUrl: d['open_url']?.toString(),
      openSimLabel: 'Abrir documento en SIM',
    );
  }
}
