import 'package:flutter/material.dart';

import '../core/widgets/sim_loading_indicator.dart';

import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/open_sim_url.dart';
import '../util/session_nav.dart';
import '../core/widgets/mobile_detail/detail_prose_block.dart';
import '../core/widgets/mobile_detail/detail_section_card.dart';
import '../core/theme/app_tokens.dart';
import '../widgets/relations_section.dart';

class NormaDetailPage extends StatefulWidget {
  final String slug;
  final String title;

  const NormaDetailPage({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<NormaDetailPage> createState() => _NormaDetailPageState();
}

class _NormaDetailPageState extends State<NormaDetailPage> {
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
      final data = await _api.fetchNormativeDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on MobileApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        if (!mounted) return;
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
      appBar: AppBar(title: Text(widget.title, maxLines: 1)),
      body: _loading
          ? const Center(child: SimLoadingIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final requirements = d['requirements'] as List<dynamic>? ?? [];
    final observation = plainText(d['observation']?.toString());

    return Column(
      children: [
        if (observation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: DetailSectionCard(
              title: 'Observación',
              icon: Icons.notes_outlined,
              child: DetailProseBlock(text: observation),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: requirements.length,
            itemBuilder: (context, index) {
              final req = requirements[index] as Map<String, dynamic>;
              final status = req['comply_status_label']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ExpansionTile(
                  title: Text(
                    plainText(req['title']?.toString()),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: status.isNotEmpty ? Text(plainText(status)) : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plainText(req['requirement']?.toString()).isNotEmpty) ...[
                            Text(
                              'Requisito',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            DetailProseBlock(
                              text: plainText(req['requirement']?.toString()),
                            ),
                          ],
                          if (plainText(req['comply_text']?.toString()).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Cumplimiento',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            DetailProseBlock(
                              text: plainText(req['comply_text']?.toString()),
                            ),
                          ],
                          if (plainText(req['responsible']?.toString()).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Responsable: ${plainText(req['responsible']?.toString())}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: RelationsSection(
            relations: d['relations'] as List<dynamic>? ?? [],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final url = d['open_url']?.toString() ?? '';
                if (url.isNotEmpty) openSimUrl(url);
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Ver en SIM'),
            ),
          ),
        ),
      ],
    );
  }
}
