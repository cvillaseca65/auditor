import 'package:flutter/material.dart';

import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/open_sim_url.dart';
import '../util/session_nav.dart';
import '../widgets/hallazgos_workflow_section.dart';
import '../widgets/relations_section.dart';

class HallazgosDetailPage extends StatefulWidget {
  final int ncId;

  const HallazgosDetailPage({super.key, required this.ncId});

  @override
  State<HallazgosDetailPage> createState() => _HallazgosDetailPageState();
}

class _HallazgosDetailPageState extends State<HallazgosDetailPage> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchNcDetail(widget.ncId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
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
        _error = 'No se pudo cargar el hallazgo. Compruebe la conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallazgo #${widget.ncId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
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
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final workflow = d['workflow'] as Map<String, dynamic>? ?? {};
    final canAct = workflow['can_act'] as bool? ?? false;
    final isClosed = d['is_closed'] as bool? ?? false;

    // Contexto del hallazgo primero (como nc_close_form.html): siempre visible
    // antes de las acciones de workflow, en cualquier etapa.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._buildReadOnlyContent(d, isClosed),
        if (canAct && !isClosed) ...[
          const SizedBox(height: 8),
          HallazgosWorkflowSection(
            key: ValueKey(
              '${workflow['stage']}-${workflow['status']}-${d['id']}',
            ),
            ncId: widget.ncId,
            workflow: workflow,
            onUpdated: _load,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildReadOnlyContent(Map<String, dynamic> d, bool isClosed) {
    final attachments = d['attachments'] as List<dynamic>? ?? [];
    final openUrl = d['open_url']?.toString() ?? '';

    return [
      Text(
        plainText(d['status_label']?.toString()),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      _row('Fecha', d['date']?.toString() ?? '-'),
      _row('Cierre', d['close']?.toString() ?? '-'),
      _row('Origen', d['origin']?.toString() ?? '-'),
      _row('Área', d['area']?.toString() ?? '-'),
      const SizedBox(height: 12),
      Text(
        'Hallazgo',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 4),
      Text(plainText(d['finding']?.toString())),
      if (attachments.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Adjuntos', style: Theme.of(context).textTheme.labelLarge),
        ...attachments.map((a) {
          final map = a as Map<String, dynamic>;
          final url = map['url']?.toString() ?? '';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(map['description']?.toString() ?? 'Adjunto'),
            trailing: const Icon(Icons.open_in_new),
            onTap: url.isNotEmpty ? () => openSimUrl(url) : null,
          );
        }),
      ],
      RelationsSection(relations: d['relations'] as List<dynamic>? ?? []),
      if (openUrl.isNotEmpty) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => openSimUrl(openUrl),
          icon: const Icon(Icons.open_in_browser),
          label: Text(isClosed ? 'Ver en SIM (web)' : 'Abrir en SIM (web)'),
        ),
      ],
    ];
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
