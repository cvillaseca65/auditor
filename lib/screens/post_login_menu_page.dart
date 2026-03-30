import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pending_audit_plans_service.dart';
import 'dashboard_page.dart';
import 'hallazgos_create_page.dart';
import 'login_page.dart';

/// Tras el login: botones Hallazgos y, si aplica, Auditoría.
class PostLoginMenuPage extends StatefulWidget {
  const PostLoginMenuPage({super.key});

  @override
  State<PostLoginMenuPage> createState() => _PostLoginMenuPageState();
}

class _PostLoginMenuPageState extends State<PostLoginMenuPage> {
  bool _loading = true;
  bool _hasPendingAuditPlans = false;

  @override
  void initState() {
    super.initState();
    _loadMenuFlags();
  }

  Future<void> _loadMenuFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    bool pending = false;
    try {
      pending = await PendingAuditPlansService.userHasPendingPlans(token);
    } catch (_) {
      pending = false;
    }

    if (!mounted) return;
    setState(() {
      _hasPendingAuditPlans = pending;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HallazgosCreatePage(),
                            ),
                          );
                          if (!context.mounted) return;
                          if (created == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Hallazgo creado exitosamente',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Hallazgos'),
                      ),
                    ),
                    if (_hasPendingAuditPlans) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DashboardPage(
                                  showMenuBack: true,
                                ),
                              ),
                            );
                          },
                          child: const Text('Auditoría'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
