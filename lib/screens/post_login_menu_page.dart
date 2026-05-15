import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/sim_theme.dart';
import '../services/pending_audit_plans_service.dart';
import 'dashboard_page.dart';
import 'hallazgos_create_page.dart';
import '../util/session_nav.dart';

/// Tras el login: botones Hallazgos y, si aplica, Auditoría.
class PostLoginMenuPage extends StatefulWidget {
  const PostLoginMenuPage({super.key});

  @override
  State<PostLoginMenuPage> createState() => _PostLoginMenuPageState();
}

class _PostLoginMenuPageState extends State<PostLoginMenuPage> {
  bool _loading = true;

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
      await navigateToLogin(context);
      return;
    }

    var pending = false;
    try {
      pending = await PendingAuditPlansService.userHasPendingPlans(token);
    } catch (_) {
      pending = false;
    }

    if (!mounted) return;

    if (!pending) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HallazgosCreatePage()),
      );
      return;
    }

    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    if (!mounted) return;
    await navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bienvenido. ¿Qué quieres hacer hoy?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ) ??
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 36),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Hallazgos',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SimTheme.accentColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Auditoría',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
