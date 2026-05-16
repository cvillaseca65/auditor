import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../core/motion/app_motion_kit.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/app_premium_card.dart';
import '../core/widgets/login_hero_visuals.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';
import '../services/session_service.dart';
import 'app_info_page.dart';
import 'company_picker_page.dart';
import 'contact_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String _error = '';
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/token/'),
            headers: {
              ...ApiConfig.defaultHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'username': _usernameController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SessionService.setToken(data['access'] as String);
        await MobileApiService().syncWelcomeFirstNameFromServer(
          fallbackUsername: _usernameController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanyPickerPage()),
        );
      } else {
        setState(() {
          _error = 'Usuario o contraseña incorrectos';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar con SIM. Verifique su red.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final maxW = wide ? 1120.0 : double.infinity;

            if (wide) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW, maxHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 12,
                          child: LoginHeroBackdrop(
                            cornerRadius: AppRadii.xl + 6,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          flex: 11,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _loginStackedBody(
                                context,
                                showFeatureIntro: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final heroHeight = (constraints.maxHeight * 0.32).clamp(220.0, 300.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: heroHeight,
                    width: double.infinity,
                    child: LoginHeroBackdrop(
                      compact: true,
                      cornerRadius: AppRadii.xl + 4,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _loginStackedBody(
                            context,
                            showFeatureIntro: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _loginStackedBody(
    BuildContext context, {
    required bool showFeatureIntro,
  }) {
    return Column(
      children: [
        _buildLoginCard(context),
        if (showFeatureIntro) ...[
          const SizedBox(height: 20),
          _buildFeatureShowcase(),
        ],
        const SizedBox(height: 18),
        _buildActionButtons(context),
        const SizedBox(height: 14),
        Text(
          '© SIM Four · Gestión integrada',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
              ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppPremiumCard(
      borderRadius: BorderRadius.circular(AppRadii.xl + 2),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Credenciales de simfour.com',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese su usuario'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              onFieldSubmitted: (_) => _login(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingrese su contraseña' : null,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _error,
                style: TextStyle(
                  color: scheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SimLoadingIndicator.compact()
                    : const Text('Entrar'),
              ),
            ),
          ],
        ),
      ),
    ).appHeroIn(delay: const Duration(milliseconds: 220));
  }

  Widget _buildFeatureShowcase() {
    final scheme = Theme.of(context).colorScheme;
    const features = [
      _FeatureChip(
        Icons.report_rounded,
        'Hallazgos',
        Color(0xFFEF5350),
      ),
      _FeatureChip(
        Icons.description_rounded,
        'Documentos',
        Color(0xFF66BB6A),
      ),
      _FeatureChip(
        Icons.menu_book_rounded,
        'Norma',
        Color(0xFFFFB74D),
      ),
      _FeatureChip(
        Icons.fact_check_rounded,
        'Auditoría',
        Color(0xFF26C6DA),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm - 2,
                vertical: AppSpacing.sm - 4,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: AppShadows.card(context, opacity: 0.85),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(features[i].icon, size: 16, color: features[i].color),
                  const SizedBox(width: 4),
                  Text(
                    features[i].label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline, width: 1.25),
                backgroundColor: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              icon: const Icon(Icons.support_agent, size: 22),
              label: const Text(
                'Contacto',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm - 2),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppInfoPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline, width: 1.25),
                backgroundColor: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              icon: const Icon(Icons.info_outline, size: 22),
              label: const Text(
                'Información',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip {
  const _FeatureChip(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}
