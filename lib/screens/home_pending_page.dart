import 'dart:async';

import 'package:flutter/material.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/app_premium_card.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import '../services/session_service.dart';
import '../util/open_sim_url.dart';
import '../util/plazo_sort.dart';
import '../core/motion/app_page_transitions.dart';
import '../core/widgets/ui/app_visual_kit.dart';
import '../widgets/kpi_summary_card.dart';
import '../util/session_nav.dart';
import 'hallazgos_detail_page.dart';
import 'pending_action_page.dart';

Future<void> _openPendingItem(
  BuildContext context, {
  required bool mobileInApp,
  required String? mobileAction,
  required int? mobileObjectId,
  required String subtitle,
  required String editUrl,
  String? simViewUrl,
  Future<void> Function()? onPendingRefresh,
}) async {
  // Hallazgo (NC): workflow propio; no usar PendingActionView.
  if (mobileInApp &&
      mobileAction == 'nc' &&
      mobileObjectId != null) {
    await Navigator.of(context).push<void>(
      AppPageTransitions.elegant(
        HallazgosDetailPage(ncId: mobileObjectId),
      ),
    );
    await onPendingRefresh?.call();
    return;
  }

  if (mobileInApp &&
      mobileAction != null &&
      mobileObjectId != null &&
      mobileAction.isNotEmpty) {
    await Navigator.of(context).push<bool>(
      AppPageTransitions.elegant(
        PendingActionPage(
          actionType: mobileAction,
          objectId: mobileObjectId,
          subtitle: subtitle,
          fallbackUrl: editUrl,
          simViewUrl: simViewUrl,
          onPendingRefresh: onPendingRefresh,
        ),
      ),
    );
    return;
  }

  final url = (simViewUrl != null && simViewUrl.trim().isNotEmpty)
      ? simViewUrl.trim()
      : editUrl.trim();
  if (url.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay enlace disponible para abrir este ítem.'),
        ),
      );
    }
    return;
  }
  final opened = await openSimUrl(url);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el enlace. Compruebe la conexión.'),
      ),
    );
  }
}

class HomePendingPage extends StatefulWidget {
  final VoidCallback? onOpenHallazgos;

  const HomePendingPage({super.key, this.onOpenHallazgos});

  @override
  HomePendingPageState createState() => HomePendingPageState();
}

enum _HomePendingListMode { dashboard, personal, organization }

class HomePendingPageState extends State<HomePendingPage> {
  final _api = MobileApiService();
  bool _loading = true;
  String? _error;
  PendingSummary? _summary;
  OrganizationSummary? _orgSummary;
  HallazgosSummary? _hallazgosSummary;
  List<PendingRow> _myItems = [];
  List<OwedRow> _owedItems = [];
  List<PendingRow> _orgItems = [];
  _HomePendingListMode _listMode = _HomePendingListMode.dashboard;
  String? _welcomeName;

  Timer? _welcomeClockTimer;

  Future<void> reload() => _load();

  Future<void> _openOrganizationPending() async {
    final needsReload =
        _orgItems.isEmpty && (_orgSummary?.pendingTotalCount ?? 0) > 0;
    if (needsReload) {
      await _load();
      if (!mounted) return;
    }
    setState(() => _listMode = _HomePendingListMode.organization);
  }

  /// Vuelve a la home solo con tarjetas KPI (quita listas). Útil con [IndexedStack]
  /// al cambiar de tab: si no se llama, el modo lista queda activo.
  void showKpiDashboardOnly() {
    if (!mounted) return;
    if (_listMode != _HomePendingListMode.dashboard) {
      setState(() => _listMode = _HomePendingListMode.dashboard);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final welcome = await SessionService.getUserDisplayName();
      if (welcome == null || welcome.isEmpty) {
        await MobileApiService().syncWelcomeFirstNameFromServer();
      }
      final resolvedWelcome = await SessionService.getUserDisplayName();
      if (!mounted) return;
      setState(() => _welcomeName = resolvedWelcome);
      final data = await _api.fetchHomePending();
      if (!mounted) return;
      setState(() {
        _summary = data.summary;
        _orgSummary = data.organizationSummary;
        _hallazgosSummary = data.hallazgosSummary;
        _myItems = data.myItems;
        _owedItems = data.owedItems;
        _orgItems = data.organizationItems;
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

  String _delayedFooter(int total, int delayed) {
    if (delayed > 0) {
      return 'Gestionar urgente: $delayed atrasadas';
    }
    return total > 0 ? 'Al día con los plazos' : 'Sin pendientes';
  }

  @override
  void initState() {
    super.initState();
    _welcomeClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    reload();
  }

  @override
  void dispose() {
    _welcomeClockTimer?.cancel();
    super.dispose();
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    int count, {
    double top = 20,
    IconData icon = Icons.inbox_rounded,
    Color? accentColor,
  }) {
    return AppSectionHeader(
      title: title,
      count: count,
      icon: icon,
      topPadding: top,
      accentColor: accentColor,
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final name = _welcomeName;
    final line = name != null && name.isNotEmpty
        ? 'Bienvenido, $name'
        : 'Bienvenido';
    return AppWelcomeBanner(
      greeting: line,
      subtitle: DateUtilsApp.formatNowLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SimLoadingIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final summary = _summary!;
    final org = _orgSummary!;
    final nc = _hallazgosSummary!;

    if (_listMode == _HomePendingListMode.dashboard) {
      return AppScreenBackdrop(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
            _buildWelcomeHeader(context),
            KpiSummaryCard(
              title: 'Mis pendientes',
              labelLeft: 'Mis pendientes',
              countLeft: summary.myPendingCount,
              delayedLeft: summary.myPendingDelayed,
              labelRight: 'Me deben',
              countRight: summary.owedPendingCount,
              delayedRight: summary.owedPendingDelayed,
              footer: _delayedFooter(
                summary.pendingTotalCount,
                summary.pendingDelayedCount,
              ),
              icon: Icons.assignment_outlined,
              accentColor: Colors.amber.shade800,
              onTap: () => setState(() => _listMode = _HomePendingListMode.personal),
            ),
            KpiSummaryCard(
              title: 'Pendientes Generales',
              labelLeft: 'Total en colas',
              countLeft: org.pendingTotalCount,
              delayedLeft: org.pendingDelayedCount,
              footer: _delayedFooter(
                org.pendingTotalCount,
                org.pendingDelayedCount,
              ),
              icon: Icons.corporate_fare_outlined,
              accentColor: Theme.of(context).colorScheme.primary,
              onTap: () => _openOrganizationPending(),
            ),
            KpiSummaryCard(
              title: 'Hallazgos (NC)',
              labelLeft: 'Pendientes',
              countLeft: nc.pendingCount,
              labelRight: 'Cerrados',
              countRight: nc.closedCount,
              footer: nc.pendingCount > 0
                  ? '${nc.pendingCount} hallazgos en gestión'
                  : 'Sin hallazgos pendientes en la empresa',
              icon: Icons.report_problem_outlined,
              accentColor: const Color(0xFF16A34A),
              onTap: widget.onOpenHallazgos,
            ),
          ],
          ),
        ),
      );
    }

    if (_listMode == _HomePendingListMode.organization) {
      return AppScreenBackdrop(
        child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                title: 'Pendientes Generales',
                subtitle: '${_orgSummary?.pendingTotalCount ?? 0} en colas de la empresa',
                onBack: () => setState(
                  () => _listMode = _HomePendingListMode.dashboard,
                ),
                accentColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            SliverToBoxAdapter(
            child: _buildSectionTitle(
              context,
              'Pendientes Generales',
              _orgItems.length,
              top: 12,
              icon: Icons.corporate_fare_rounded,
              accentColor: Theme.of(context).colorScheme.primary,
            ),
            ),
            if (_orgItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    (_orgSummary?.pendingTotalCount ?? 0) > 0
                        ? 'El resumen indica ${_orgSummary!.pendingTotalCount} pendientes, '
                            'pero no se recibió el detalle. Deslice hacia abajo para '
                            'recargar y compruebe que el servidor SIM esté actualizado.'
                        : 'No hay ítems en las colas de la empresa activa.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PendingTile(
                    row: _orgItems[index],
                    onPendingRefresh: _load,
                  ),
                  childCount: _orgItems.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
        ),
      );
    }

    return AppScreenBackdrop(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Mis pendientes',
              subtitle: '${_summary?.myPendingCount ?? 0} personales · ${_owedItems.length} me deben',
              onBack: () => setState(
                () => _listMode = _HomePendingListMode.dashboard,
              ),
              accentColor: Colors.amber.shade800,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              context,
              'Mis Pendientes',
              _myItems.length,
              top: 12,
              icon: Icons.assignment_rounded,
              accentColor: Colors.amber.shade800,
            ),
          ),
          if (_myItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No hay ítems en su lista personal.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PendingTile(
                  row: _myItems[index],
                  onPendingRefresh: _load,
                ),
                childCount: _myItems.length,
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              context,
              'Pendientes que me deben',
              _owedItems.length,
              icon: Icons.people_outline_rounded,
              accentColor: const Color(0xFF0D9488),
            ),
          ),
          if (_owedItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No hay tareas ni Gantts pendientes de ejecución a su favor.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _OwedTile(
                  row: _owedItems[index],
                  onPendingRefresh: _load,
                ),
                childCount: _owedItems.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        ),
      ),
    );
  }
}

String _misPendientesPlazoCol1(PendingRow row, int? plazoDays) {
  if (plazoDays != null) {
    if (plazoDays == 0) return 'Hoy';
    return '$plazoDays';
  }
  final a = row.alertText.trim();
  if (a.isEmpty) return '—';
  final words = a.split(RegExp(r'\s+')).take(4).join(' ');
  if (words.length <= 16) return words;
  return '${words.substring(0, 14)}…';
}

bool _isPlaceholderPerson(String value) {
  final v = value.trim();
  return v.isEmpty || v == '-';
}

String _pendingHolderLabel(PendingRow row) {
  final name = row.responsible.trim();
  final role = row.holderRole.trim();
  if (_isPlaceholderPerson(name)) {
    final r = role.isNotEmpty ? role : 'Responsable';
    return '$r: Sin asignar';
  }
  if (role.isEmpty) return name;
  return '$role: $name';
}

String? _misPendientesRow2Meta(PendingRow row, int? plazoDays) {
  final alert = row.alertText.trim();

  final headParts = <String>[_pendingHolderLabel(row)];
  final pos = row.position.trim();
  if (pos.isNotEmpty && pos != '-') {
    headParts.add(pos);
  }
  final head = headParts.join(' · ');

  var showAlert = alert.isNotEmpty;
  if (showAlert && plazoDays != null) {
    final fromAlert = plazoDaysFromAlertText(alert);
    final compact = alert.replaceAll(RegExp(r'\s'), '');
    if (fromAlert == plazoDays && compact.length <= 16) {
      showAlert = false;
    }
  }

  if (!showAlert) {
    return head.isEmpty ? null : head;
  }
  if (head.isEmpty) return alert;
  return '$head · $alert';
}

String? _owedRow2Meta(OwedRow row, int? plazoDays) {
  final kind = row.kind.trim();
  final exe = row.executor.trim();
  final alert = row.alertText.trim();

  final headParts = <String>[];
  if (kind.isNotEmpty) headParts.add(kind);
  if (exe.isNotEmpty) headParts.add(exe);
  final head = headParts.join(' · ');

  var showAlert = alert.isNotEmpty;
  if (showAlert && plazoDays != null) {
    final fromAlert = plazoDaysFromAlertText(alert);
    final compact = alert.replaceAll(RegExp(r'\s'), '');
    if (fromAlert == plazoDays && compact.length <= 16) {
      showAlert = false;
    }
  }

  if (!showAlert) {
    return head.isEmpty ? null : head;
  }
  if (head.isEmpty) return alert;
  return '$head · $alert';
}

String _owedPlazoCol1(OwedRow row, int? plazoDays) {
  if (plazoDays != null) {
    if (plazoDays == 0) return 'Hoy';
    return '$plazoDays';
  }
  final a = row.alertText.trim();
  if (a.isEmpty) return '—';
  final words = a.split(RegExp(r'\s+')).take(4).join(' ');
  if (words.length <= 16) return words;
  return '${words.substring(0, 14)}…';
}

class _PendingTile extends StatelessWidget {
  final PendingRow row;
  final Future<void> Function()? onPendingRefresh;

  const _PendingTile({
    required this.row,
    this.onPendingRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final plazoDays = pendingPlazoDays(endIso: row.endIso, alertText: row.alertText);
    final plazoLabel = _misPendientesPlazoCol1(row, plazoDays);
    final metaLine = _misPendientesRow2Meta(row, plazoDays);

    return AppActionListTile(
      title: row.title,
      category: row.category,
      leadingLabel: plazoLabel,
      subtitle: metaLine,
      isDelayed: row.isDelayed,
      inApp: row.mobileInApp,
      onTap: () => _openPendingItem(
        context,
        mobileInApp: row.mobileInApp,
        mobileAction: row.mobileAction,
        mobileObjectId: row.mobileObjectId,
        subtitle: row.title,
        editUrl: row.editUrl,
        simViewUrl: row.simViewUrl,
        onPendingRefresh: onPendingRefresh,
      ),
    );
  }
}

class _OwedTile extends StatelessWidget {
  final OwedRow row;
  final Future<void> Function()? onPendingRefresh;

  const _OwedTile({
    required this.row,
    this.onPendingRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final plazoDays = pendingPlazoDays(endIso: row.endIso, alertText: row.alertText);
    final plazoLabel = _owedPlazoCol1(row, plazoDays);
    final metaLine = _owedRow2Meta(row, plazoDays);

    return AppActionListTile(
      title: row.title,
      category: row.kind,
      leadingLabel: plazoLabel,
      subtitle: metaLine,
      isDelayed: row.isDelayed,
      inApp: row.mobileInApp,
      accentColor: const Color(0xFF0D9488),
      onTap: () => _openPendingItem(
        context,
        mobileInApp: row.mobileInApp,
        mobileAction: row.mobileAction,
        mobileObjectId: row.mobileObjectId,
        subtitle: row.title,
        editUrl: row.editUrl,
        simViewUrl: row.simViewUrl,
        onPendingRefresh: onPendingRefresh,
      ),
    );
  }
}
