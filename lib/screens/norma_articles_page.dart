import 'package:flutter/material.dart';

import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/session_nav.dart';
import 'norma_article_detail_page.dart';

/// Listado de artículos (requisitos) de una norma.
class NormaArticlesPage extends StatefulWidget {
  const NormaArticlesPage({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  State<NormaArticlesPage> createState() => _NormaArticlesPageState();
}

class _NormaArticlesPageState extends State<NormaArticlesPage> {
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
      final data = await _api.fetchNormativeDetail(widget.slug);
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
        title: Text(widget.title, maxLines: 1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildList(),
    );
  }

  Widget _buildList() {
    final d = _data!;
    final observation = plainText(d['observation']?.toString());
    final requirements = d['requirements'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (observation.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(observation),
              ),
            ),
          Text(
            'Artículos (${requirements.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((raw) {
            final req = raw as Map<String, dynamic>;
            final index = req['index']?.toString() ?? '';
            final title = plainText(req['title']?.toString());
            final status = plainText(req['comply_status_label']?.toString());
            final complyId = req['comply_id'] as int?;

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    index.isNotEmpty ? index : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: status.isNotEmpty ? Text(status) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (complyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sin registro de cumplimiento para esta organización',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NormaArticleDetailPage(
                        complyId: complyId,
                        previewTitle: title,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
