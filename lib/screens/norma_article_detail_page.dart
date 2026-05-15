import 'package:flutter/material.dart';

import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/session_nav.dart';
import '../widgets/relations_section.dart';
import 'in_app_url_page.dart';

/// Detalle de artículo / cumplimiento (como SIM web).
class NormaArticleDetailPage extends StatefulWidget {
  const NormaArticleDetailPage({
    super.key,
    required this.complyId,
    required this.previewTitle,
  });

  final int complyId;
  final String previewTitle;

  @override
  State<NormaArticleDetailPage> createState() => _NormaArticleDetailPageState();
}

class _NormaArticleDetailPageState extends State<NormaArticleDetailPage> {
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
      final data = await _api.fetchComplyDetail(widget.complyId);
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          plainText(_data?['title']?.toString() ?? widget.previewTitle),
          maxLines: 1,
        ),
        actions: [
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () {
                final url = _data!['edit_url']?.toString() ?? '';
                if (url.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InAppUrlPage(
                      url: url,
                      title: 'Editar cumplimiento',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final requirement = plainText(d['requirement']?.toString());
    final complyText = plainText(d['comply_text']?.toString());
    final status = plainText(d['comply_status_label']?.toString());
    final responsible = plainText(d['responsible']?.toString());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (status.isNotEmpty)
          Chip(
            label: Text(status),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        const SizedBox(height: 8),
        if (requirement.isNotEmpty) ...[
          Text(
            'Requisito',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(requirement),
          const SizedBox(height: 16),
        ],
        if (complyText.isNotEmpty) ...[
          const Divider(),
          Text(
            'Cumplimiento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            complyText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        if (responsible.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Responsable: $responsible',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        RelationsSection(relations: d['relations'] as List<dynamic>? ?? []),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final url = d['edit_url']?.toString() ?? '';
              if (url.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppUrlPage(
                    url: url,
                    title: 'Editar cumplimiento',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
        ),
      ],
    );
  }
}
