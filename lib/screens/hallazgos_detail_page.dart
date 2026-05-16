import 'package:flutter/material.dart';

import '../core/widgets/mobile_detail/nc_detail_body.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';
import '../util/session_nav.dart';
import '../widgets/hallazgos_workflow_section.dart';

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
    final workflow = d['workflow'] as Map<String, dynamic>? ?? {};
    final canAct = workflow['can_act'] as bool? ?? false;
    final isClosed = d['is_closed'] as bool? ?? false;

    return NcDetailBody(
      ncId: widget.ncId,
      data: d,
      simOpenUrl: d['open_url']?.toString(),
      openSimLabel: isClosed ? 'Ver en SIM (web)' : 'Abrir en SIM (web)',
      extraSections: [
        if (canAct && !isClosed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HallazgosWorkflowSection(
              key: ValueKey(
                '${workflow['stage']}-${workflow['status']}-${d['id']}',
              ),
              ncId: widget.ncId,
              workflow: workflow,
              onUpdated: _load,
            ),
          ),
      ],
    );
  }
}
