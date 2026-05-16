import 'package:flutter/material.dart';

import '../core/widgets/sim_loading_indicator.dart';

import '../core/theme/sim_theme.dart';
import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import '../util/session_nav.dart';
import 'usuario_detail_page.dart';

class UsuariosListPage extends StatefulWidget {
  const UsuariosListPage({super.key});

  @override
  State<UsuariosListPage> createState() => _UsuariosListPageState();
}

class _UsuariosListPageState extends State<UsuariosListPage> {
  final _api = MobileApiService();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<UserListItem> _items = [];

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
      final items = await _api.fetchUsers(
        query: _searchController.text.trim(),
        active: '1',
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
                    hintText: 'Nombre, email, RUT…',
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
                      ? const Center(child: Text('Sin personas'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final u = _items[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: SimTheme.accentColor
                                      .withValues(alpha: 0.15),
                                  child: Icon(
                                    u.employee
                                        ? Icons.person
                                        : Icons.person_outline,
                                    color: SimTheme.accentColor,
                                  ),
                                ),
                                title: Text(
                                  u.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    decoration: u.isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Text(u.email),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UsuarioDetailPage(userId: u.id),
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
