import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../theme/app_theme_mode.dart';
import '../theme/sim_theme.dart';

/// Barra superior con degradado SIM, logo y organización activa.
class SimBrandedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;

  const SimBrandedAppBar({super.key, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SimBrandedAppBar> createState() => _SimBrandedAppBarState();
}

class _SimBrandedAppBarState extends State<SimBrandedAppBar> {
  String _companyName = '';
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await SessionService.getCompanyName();
    final logo = await SessionService.getCompanyLogoUrl();
    if (!mounted) return;
    setState(() {
      _companyName = name ?? '';
      _logoUrl = logo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: widget.leading,
      titleSpacing: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: SimTheme.headerGradient),
      ),
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(child: _companyCenter()),
          ),
          SizedBox(
            width: 48 +
                ((AppThemeMode.maybeOf(context) != null ? 1 : 0) +
                    (widget.actions?.length ?? 0)) *
                    48,
          ),
        ],
      ),
      actions: [
        if (AppThemeMode.maybeOf(context) != null)
          ListenableBuilder(
            listenable: AppThemeMode.of(context),
            builder: (context, _) {
              final mode = AppThemeMode.of(context).value;
              late final IconData icon;
              late final String tip;
              switch (mode) {
                case ThemeMode.system:
                  icon = Icons.brightness_auto_rounded;
                  tip = 'Tema: sistema (tocar para claro)';
                  break;
                case ThemeMode.light:
                  icon = Icons.dark_mode_rounded;
                  tip = 'Tema: claro (tocar para oscuro)';
                  break;
                case ThemeMode.dark:
                  icon = Icons.light_mode_rounded;
                  tip = 'Tema: oscuro (tocar para sistema)';
                  break;
              }
              return IconButton(
                tooltip: tip,
                icon: Icon(icon),
                onPressed: () {
                  final n = AppThemeMode.of(context);
                  n.value = switch (n.value) {
                    ThemeMode.system => ThemeMode.light,
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.system,
                  };
                },
              );
            },
          ),
        ...?widget.actions,
      ],
    );
  }

  Widget _companyCenter() {
    if (_logoUrl != null && _logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _logoUrl!,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _companyNameText(),
        ),
      );
    }
    return _companyNameText();
  }

  Widget _companyNameText() {
    if (_companyName.isEmpty) return const SizedBox.shrink();
    return Text(
      _companyName,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
