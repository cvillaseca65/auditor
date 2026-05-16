import 'package:flutter/material.dart';

import '../core/motion/app_page_transitions.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../core/widgets/ui/app_visual_kit.dart';

import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import 'documento_detail_page.dart';
import '../util/session_nav.dart';

class DocumentosPage extends StatefulWidget {
  const DocumentosPage({super.key});

  @override
  State<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  final _api = MobileApiService();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<DocumentListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.fetchDocuments(
        query: _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Código, título o tipo…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: SimLoadingIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _items.isEmpty
                      ? const Center(child: Text('Sin documentos'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final sub = item.publication.isNotEmpty
                                  ? '${item.documentType}\n${item.publication}'
                                  : item.documentType;
                              return AppEntityListTile(
                                title: '${item.code} ${item.title}',
                                subtitle: sub,
                                leadingIcon: Icons.description_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    AppPageTransitions.elegant(
                                      DocumentoDetailPage(documentId: item.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
