import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import 'hallazgos_create_page.dart';
import 'hallazgos_detail_page.dart';
import '../util/session_nav.dart';

class HallazgosListPage extends StatefulWidget {
  const HallazgosListPage({super.key});

  @override
  HallazgosListPageState createState() => HallazgosListPageState();
}

class HallazgosListPageState extends State<HallazgosListPage>
    with SingleTickerProviderStateMixin {
  final _api = MobileApiService();
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<NcListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  void reload() => _load();

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _tab => _tabController.index == 0 ? 'pending' : 'closed';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.fetchNcList(
        tab: _tab,
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

  void _onItemTap(NcListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HallazgosDetailPage(ncId: item.id),
      ),
    );
  }

  Future<void> createHallazgo() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HallazgosCreatePage()),
    );
    if (!mounted) return;
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hallazgo creado exitosamente')),
      );
      _load();
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
                    hintText: 'Buscar hallazgo…',
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
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Cerrados'),
          ],
        ),
        Expanded(
          child: _loading
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
                  : _items.isEmpty
                      ? const Center(child: Text('Sin hallazgos'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                title: Text(
                                  '#${item.id} · ${item.finding}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${item.statusLabel} · ${item.area}\n'
                                  '${item.responsible}',
                                ),
                                isThreeLine: true,
                                leading: item.isDelayed
                                    ? const Icon(
                                        Icons.warning_amber,
                                        color: Colors.red,
                                      )
                                    : Icon(
                                        item.isClosed
                                            ? Icons.check_circle_outline
                                            : Icons.pending_actions,
                                      ),
                                trailing: Icon(
                                  item.isClosed
                                      ? Icons.chevron_right
                                      : Icons.open_in_new,
                                  size: 20,
                                ),
                                onTap: () => _onItemTap(item),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

}
