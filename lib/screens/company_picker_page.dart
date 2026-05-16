import 'package:flutter/material.dart';

import '../core/widgets/sim_loading_indicator.dart';

import '../core/theme/sim_theme.dart';
import '../core/widgets/sim_branded_app_bar.dart';
import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import '../services/session_service.dart';
import 'home_shell.dart';
import '../util/session_nav.dart';

class CompanyPickerPage extends StatefulWidget {
  const CompanyPickerPage({super.key});

  @override
  State<CompanyPickerPage> createState() => _CompanyPickerPageState();
}

class _CompanyPickerPageState extends State<CompanyPickerPage> {
  final _api = MobileApiService();
  bool _loading = true;
  String? _error;
  List<CompanyOption> _companies = [];

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
      final companies = await _api.fetchCompanies();
      if (!mounted) return;
      if (companies.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No tienes acceso a ninguna organización.';
        });
        return;
      }
      if (companies.length == 1) {
        await _select(companies.first);
        return;
      }
      setState(() {
        _companies = companies;
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

  Future<void> _select(CompanyOption company) async {
    await SessionService.setCompany(
      company.id,
      company.name,
      logoUrl: company.logoUrl,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _logout() async {
    if (!mounted) return;
    await navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimBrandedAppBar(
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      color: SimTheme.primaryColor.withValues(alpha: 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccione empresa',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SimTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Trabajará con los datos de la organización elegida.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _companies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final c = _companies[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    SimTheme.accentColor.withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.business,
                                  color: SimTheme.accentColor,
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _select(c),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
