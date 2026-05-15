import 'package:flutter/material.dart';

import '../core/theme/sim_theme.dart';
import '../models/mobile_models.dart';
import '../services/mobile_api_service.dart';
import '../util/session_nav.dart';

class UsuarioDetailPage extends StatefulWidget {
  final int userId;

  const UsuarioDetailPage({super.key, required this.userId});

  @override
  State<UsuarioDetailPage> createState() => _UsuarioDetailPageState();
}

class _UsuarioDetailPageState extends State<UsuarioDetailPage>
    with SingleTickerProviderStateMixin {
  final _api = MobileApiService();
  late TabController _tabController;
  bool _loadingProfile = true;
  String? _error;
  UserProfile? _profile;

  List<UserSkillItem> _skills = [];
  List<UserPerformanceItem> _performance = [];
  List<UserTaskItem> _tasks = [];
  bool _loadingTab = false;
  String _taskTab = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadTab(_tabController.index);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _error = null;
    });
    try {
      final profile = await _api.fetchUserProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
      _loadTab(_tabController.index);
    } on MobileApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        if (!mounted) return;
        await navigateToLogin(context);
        return;
      }
      setState(() {
        _loadingProfile = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadTab(int index) async {
    if (_profile == null) return;
    setState(() => _loadingTab = true);
    try {
      switch (index) {
        case 1:
          _skills = await _api.fetchUserSkills(widget.userId);
          break;
        case 2:
          _performance = await _api.fetchUserPerformance(widget.userId);
          break;
        case 3:
          _tasks = await _api.fetchUserTasks(widget.userId, tab: _taskTab);
          break;
        default:
          break;
      }
      if (!mounted) return;
      setState(() => _loadingTab = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTab = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  _profile?.name ?? 'Persona',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: SimTheme.primaryColor,
            indicatorColor: SimTheme.accentColor,
            tabs: const [
              Tab(text: 'Ficha'),
              Tab(text: 'Competencias'),
              Tab(text: 'Desempeño'),
              Tab(text: 'Tareas'),
            ],
          ),
        ),
        Expanded(
          child: _loadingProfile
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(),
                        _buildListTab(_skills.map(_skillTile).toList()),
                        _buildListTab(_performance.map(_perfTile).toList()),
                        _buildTasksTab(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final p = _profile!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: SimTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: SimTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (!p.isActive)
                    const Text(
                      'Inactivo',
                      style: TextStyle(color: Colors.red),
                    ),
                  if (p.jobtypeLabel.isNotEmpty)
                    Text(p.jobtypeLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _infoRow('Email', p.email),
        if (p.phone.isNotEmpty) _infoRow('Teléfono', p.phone),
        if (p.rut.isNotEmpty) _infoRow('RUT', p.rut),
        if (p.positions.isNotEmpty)
          _infoRow('Cargos', p.positions.join(', ')),
        if (p.observation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Observación', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(p.observation),
        ],
        const SizedBox(height: 20),
        Text(
          'Resumen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Pendientes', '${p.pendingTasks}'),
            _chip('Competencias', '${p.skillsCount}'),
            _chip('Desempeños', '${p.performanceCount}'),
            if (p.performanceAvg != null)
              _chip('Prom. eval.', p.performanceAvg!.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Solo consulta. Para editar, use SIM en el navegador.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: SimTheme.accentColor.withValues(alpha: 0.1),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(List<Widget> tiles) {
    if (_loadingTab && _tabController.index != 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tiles.isEmpty) {
      return const Center(child: Text('Sin registros'));
    }
    return ListView(padding: const EdgeInsets.all(8), children: tiles);
  }

  Widget _skillTile(UserSkillItem s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(s.skillType, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          [
            if (s.number.isNotEmpty) 'Nº ${s.number}',
            if (s.creation.isNotEmpty) 'Emisión: ${s.creation}',
            if (s.alertText.isNotEmpty) s.alertText,
          ].join('\n'),
        ),
        isThreeLine: true,
        leading: s.effective
            ? const Icon(Icons.thumb_up, color: SimTheme.accentColor)
            : s.isDelayed
                ? const Icon(Icons.warning_amber, color: Colors.red)
                : const Icon(Icons.school_outlined),
      ),
    );
  }

  Widget _perfTile(UserPerformanceItem p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          p.evaluation != null
              ? 'Evaluación: ${p.evaluation!.toStringAsFixed(2)}'
              : 'Desempeño #${p.id}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          [
            if (p.creation.isNotEmpty) 'Creación: ${p.creation}',
            if (p.start.isNotEmpty && p.end.isNotEmpty)
              'Periodo: ${p.start} – ${p.end}',
            if (p.alertText.isNotEmpty) p.alertText,
          ].join('\n'),
        ),
        isThreeLine: true,
        leading: p.isDelayed
            ? const Icon(Icons.warning_amber, color: Colors.red)
            : const Icon(Icons.trending_up, color: SimTheme.accentColor),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _taskFilterChip('pending', 'Pendientes'),
              _taskFilterChip('execution', 'Por ejecutar'),
              _taskFilterChip('verification', 'Por verificar'),
              _taskFilterChip('closed', 'Cerradas'),
            ],
          ),
        ),
        Expanded(
          child: _loadingTab
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                  ? const Center(child: Text('Sin tareas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final t = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              t.subject,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${t.role == "executor" ? "Ejecutor" : "Creador"}'
                              '${t.end.isNotEmpty ? " · $t.end" : ""}'
                              '${t.alertText.isNotEmpty ? "\n${t.alertText}" : ""}',
                            ),
                            isThreeLine: t.alertText.isNotEmpty,
                            leading: t.isDelayed
                                ? const Icon(
                                    Icons.warning_amber,
                                    color: Colors.red,
                                  )
                                : Icon(
                                    t.isPending
                                        ? Icons.pending_actions
                                        : Icons.check_circle_outline,
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _taskFilterChip(String tab, String label) {
    final selected = _taskTab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _taskTab = tab);
          _loadTab(3);
        },
      ),
    );
  }
}
