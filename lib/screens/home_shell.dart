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
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Material(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.94),
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  backgroundColor: Colors.transparent,
                ),
                child: NavigationBar(
                  height: 64,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  selectedIndex: _index,
                  onDestinationSelected: (i) {
                    if (i == _index) {
                      _tabNavigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
                    }
                    setState(() => _index = i);
                    if (i == 0) {
                      _homeKey.currentState?.showKpiDashboardOnly();
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Inicio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.report_outlined),
                      selectedIcon: Icon(Icons.report_rounded),
                      label: 'Hallazgos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description_rounded),
                      label: 'Documentos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: 'Norma',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: 'Usuarios',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check_rounded),
                      label: 'Auditoría',
                    ),
                  ],
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
