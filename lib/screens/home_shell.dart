import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/widgets/app_premium_card.dart';
import '../core/widgets/sim_branded_app_bar.dart';
import '../core/widgets/tab_root_navigator.dart';
import '../util/session_nav.dart';
import 'dashboard_page.dart';
import 'documentos_page.dart';
import 'hallazgos_list_page.dart';
import 'home_pending_page.dart';
import 'norma_page.dart';
import 'usuarios_list_page.dart';

/// Shell principal: fondo tipo app dashboard + barra inferior flotante.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _tabCount = 6;

  int _index = 0;
  final _hallazgosKey = GlobalKey<HallazgosListPageState>();
  final _homeKey = GlobalKey<HomePendingPageState>();
  late final List<GlobalKey<NavigatorState>> _tabNavigatorKeys =
      List.generate(_tabCount, (_) => GlobalKey<NavigatorState>());

  Future<void> _logout() async {
    if (!mounted) return;
    await navigateToLogin(context);
  }

  bool _activeTabCanPop() {
    return _tabNavigatorKeys[_index].currentState?.canPop() ?? false;
  }

  void _popActiveTab() {
    _tabNavigatorKeys[_index].currentState?.pop();
  }

  void _goHallazgosTab() {
    setState(() => _index = 1);
  }

  Widget _floatingNavBar() {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.navFloat(context),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.55),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(_index),
                tween: Tween(begin: 0.96, end: 1),
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
                child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.97),
                      Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow
                          .withValues(alpha: 0.98),
                    ],
                  ),
                ),
                child: _ShellBottomNav(
                  index: _index,
                  onSelected: (i) {
                    if (i == _index) {
                      _tabNavigatorKeys[i]
                          .currentState
                          ?.popUntil((r) => r.isFirst);
                    }
                    setState(() => _index = i);
                    if (i == 0) {
                      _homeKey.currentState?.showKpiDashboardOnly();
                    }
                  },
                ),
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_activeTabCanPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeTabCanPop()) _popActiveTab();
      },
      child: Scaffold(
        appBar: SimBrandedAppBar(
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout,
            ),
          ],
        ),
        body: AppScreenBackdrop(
          child: IndexedStack(
            index: _index,
            children: [
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[0],
                  child: HomePendingPage(
                    key: _homeKey,
                    onOpenHallazgos: _goHallazgosTab,
                  ),
                ),
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[1],
                  child: HallazgosListPage(key: _hallazgosKey),
                ),
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[2],
                  child: const DocumentosPage(),
                ),
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[3],
                  child: const NormaPage(),
                ),
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[4],
                  child: const UsuariosListPage(),
                ),
                TabRootNavigator(
                  navigatorKey: _tabNavigatorKeys[5],
                  child: const DashboardPage(showMenuBack: false),
                ),
            ],
          ),
        ),
        floatingActionButton: _index == 1
            ? Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FloatingActionButton.extended(
                  onPressed: () => _hallazgosKey.currentState?.createHallazgo(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo'),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _floatingNavBar(),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barra inferior compacta: 6 pestañas sin solapar etiquetas.
class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    _ShellNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _ShellNavItem(
      icon: Icons.report_outlined,
      selectedIcon: Icons.report_rounded,
      label: 'Hallazgo',
    ),
    _ShellNavItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      label: 'Documento',
    ),
    _ShellNavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Norma',
    ),
    _ShellNavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people_rounded,
      label: 'Usuario',
    ),
    _ShellNavItem(
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
      label: 'Auditar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 72,
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = index == i;
          final color =
              selected ? scheme.primary : scheme.onSurfaceVariant;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTypography.navBarLabel,
                          fontWeight: FontWeight.w400,
                          height: 1.1,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
