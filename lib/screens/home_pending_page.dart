import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import '../services/session_service.dart';
import '../util/open_sim_url.dart';
import '../util/plazo_sort.dart';
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
  VoidCallback? onCompleted,
}) async {
  // Hallazgo (NC): workflow propio; no usar PendingActionView.
  if (mobileInApp &&
      mobileAction == 'nc' &&
      mobileObjectId != null) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HallazgosDetailPage(ncId: mobileObjectId),
      ),
    );
    onCompleted?.call();
    return;
  }

  if (mobileInApp &&
      mobileAction != null &&
      mobileObjectId != null &&
      mobileAction.isNotEmpty) {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PendingActionPage(
          actionType: mobileAction,
          objectId: mobileObjectId,
          subtitle: subtitle,
          fallbackUrl: editUrl,
          simViewUrl: simViewUrl,
          onCompleted: onCompleted,
        ),
      ),
    );
    if (done == true && onCompleted != null) {
      onCompleted();
    }
    return;
  }
  await openSimUrl(simViewUrl ?? editUrl);
}

class HomePendingPage extends StatefulWidget {
  final VoidCallback? onOpenHallazgos;

  const HomePendingPage({super.key, this.onOpenHallazgos});

  @override
  HomePendingPageState createState() => HomePendingPageState();
}

class HomePendingPageState extends State<HomePendingPage> {
  final _api = MobileApiService();
  bool _loading = true;
  String? _error;
  PendingSummary? _summary;
  OrganizationSummary? _orgSummary;
  HallazgosSummary? _hallazgosSummary;
  List<PendingRow> _myItems = [];
  List<OwedRow> _owedItems = [];
  bool _showDetail = false;
  String? _welcomeName;

  Timer? _welcomeClockTimer;

  Future<void> reload() => _load();

  /// Vuelve a la home solo con tarjetas KPI (quita listas). Útil con [IndexedStack]
  /// al cambiar de tab: si no se llama, `_showDetail` queda en true y se ven listas.
  void showKpiDashboardOnly() {
    if (!mounted) return;
    if (_showDetail) setState(() => _showDetail = false);
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
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'ítem' : 'ítems'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final name = _welcomeName;
    final line = name != null && name.isNotEmpty
        ? 'Bienvenido, $name'
        : 'Bienvenido';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            DateUtilsApp.formatNowLocal(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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

    if (!_showDetail) {
      return RefreshIndicator(
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
              onTap: () => setState(() => _showDetail = true),
            ),
            KpiSummaryCard(
              title: 'Pendientes de la empresa activa',
              labelLeft: 'Total en colas',
              countLeft: org.pendingTotalCount,
              delayedLeft: org.pendingDelayedCount,
              footer: _delayedFooter(
                org.pendingTotalCount,
                org.pendingDelayedCount,
              ),
              icon: Icons.corporate_fare_outlined,
              accentColor: Theme.of(context).colorScheme.primary,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showDetail = false),
                  ),
                  Text(
                    'Mis pendientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              context,
              'Mis Pendientes',
              _myItems.length,
              top: 12,
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
                  onCompleted: _load,
                ),
                childCount: _myItems.length,
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              context,
              'Pendientes que me deben',
              _owedItems.length,
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
                  onCompleted: _load,
                ),
                childCount: _owedItems.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
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

String? _misPendientesRow2Meta(PendingRow row, int? plazoDays) {
  final cat = row.category.trim();
  final alert = row.alertText.trim();

  final headParts = <String>[];
  if (cat.isNotEmpty) headParts.add(cat);
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
  final VoidCallback? onCompleted;

  const _PendingTile({required this.row, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = theme.colorScheme.onSurfaceVariant;
    final plazoDays = pendingPlazoDays(endIso: row.endIso, alertText: row.alertText);
    final plazoLabel = _misPendientesPlazoCol1(row, plazoDays);
    final metaLine = _misPendientesRow2Meta(row, plazoDays);
    final plazoStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: row.isDelayed ? theme.colorScheme.error : theme.colorScheme.primary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final openIcon = Icon(
      row.mobileInApp ? Icons.touch_app : Icons.open_in_new,
      color: row.isDelayed ? Colors.red : variant,
      size: row.isDelayed ? 20 : 18,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _openPendingItem(
          context,
          mobileInApp: row.mobileInApp,
          mobileAction: row.mobileAction,
          mobileObjectId: row.mobileObjectId,
          subtitle: row.title,
          editUrl: row.editUrl,
          simViewUrl: row.simViewUrl,
          onCompleted: onCompleted,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(94),
                  1: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 2),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            plazoLabel,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: plazoStyle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.85),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    row.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, left: 6),
                                  child: openIcon,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (metaLine != null && metaLine.isNotEmpty)
                    TableRow(
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (row.isDelayed)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  metaLine,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
                                    color:
                                        row.isDelayed && plazoDays == null
                                            ? Colors.red
                                            : variant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      );
  }
}

class _OwedTile extends StatelessWidget {
  final OwedRow row;
  final VoidCallback? onCompleted;

  const _OwedTile({required this.row, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = theme.colorScheme.onSurfaceVariant;
    final plazoDays = pendingPlazoDays(endIso: row.endIso, alertText: row.alertText);
    final plazoLabel = _owedPlazoCol1(row, plazoDays);
    final metaLine = _owedRow2Meta(row, plazoDays);
    final plazoStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: row.isDelayed ? theme.colorScheme.error : theme.colorScheme.primary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final openIcon = Icon(
      row.mobileInApp ? Icons.touch_app : Icons.open_in_new,
      color: row.isDelayed ? Colors.red : variant,
      size: row.isDelayed ? 20 : 18,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _openPendingItem(
          context,
          mobileInApp: row.mobileInApp,
          mobileAction: row.mobileAction,
          mobileObjectId: row.mobileObjectId,
          subtitle: row.title,
          editUrl: row.editUrl,
          simViewUrl: row.simViewUrl,
          onCompleted: onCompleted,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(94),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        plazoLabel,
                        textAlign: TextAlign.right,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: plazoStyle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.85),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                row.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2, left: 6),
                              child: openIcon,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (metaLine != null && metaLine.isNotEmpty)
                TableRow(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (row.isDelayed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              metaLine,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: row.isDelayed && plazoDays == null
                                    ? Colors.red
                                    : variant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
