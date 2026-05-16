import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/widgets/sim_loading_indicator.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../core/widgets/sim_branded_app_bar.dart';
import '../services/session_service.dart';
import 'lines_page.dart';
import '../util/session_nav.dart';

enum ViewLevel { companies, audits, plans }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.showMenuBack = false});

  final bool showMenuBack;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  ViewLevel currentLevel = ViewLevel.companies;

  Map<String, dynamic>? selectedCompany;
  Map<String, dynamic>? selectedAudit;
  Map<String, dynamic>? selectedPlan;

  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> audits = [];
  List<Map<String, dynamic>> plans = [];

  bool isLoading = true;
  String error = '';
  bool _sessionCompanyApplied = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final companyId = await SessionService.getCompanyId();
    final companyName = await SessionService.getCompanyName();
    if (companyId != null) {
      selectedCompany = {
        'id': companyId,
        'name': companyName ?? 'Organización',
      };
      currentLevel = ViewLevel.audits;
      _sessionCompanyApplied = true;
    }
    await fetchData();
  }

  static int _compareMapsByName(Map<String, dynamic> a, Map<String, dynamic> b) {
    final na = '${a['name'] ?? ''}'.toLowerCase();
    final nb = '${b['name'] ?? ''}'.toLowerCase();
    return na.compareTo(nb);
  }

  String formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().substring(2);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return dateString;
    }
  }

  Future<String?> _token() => SessionService.getToken();

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final token = await _token();
    if (token == null) {
      _logout();
      return;
    }

    String url = '';
    Map<String, String> headers = ApiConfig.defaultHeaders(token: token);

    try {
      switch (currentLevel) {
        case ViewLevel.companies:
          url = '${ApiConfig.baseUrl}/api/v1/companies/';
          break;
        case ViewLevel.audits:
          if (selectedCompany == null) return;
          url = '${ApiConfig.baseUrl}/api/v1/audits/';
          headers['X-Company-ID'] = selectedCompany!['id'].toString();
          break;
        case ViewLevel.plans:
          if (selectedAudit == null || selectedCompany == null) return;
          url =
              '${ApiConfig.baseUrl}/api/v1/plans/?audit=${selectedAudit!['id']}';
          headers['X-Company-ID'] = selectedCompany!['id'].toString();
          break;
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('results')) {
          data = decoded['results'];
        }

        switch (currentLevel) {
          case ViewLevel.companies:
            companies =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            companies.sort(_compareMapsByName);
            break;
          case ViewLevel.audits:
            audits =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            audits.sort(_compareMapsByName);
            break;
          case ViewLevel.plans:
            plans =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            plans.sort(_compareMapsByName);
            break;
        }
      } else if (response.statusCode == 401) {
        _logout();
        return;
      } else {
        error = 'Error ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error al cargar: $e';
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _logout() async {
    if (!mounted) return;
    await navigateToLogin(context);
  }

  void _onBack() {
    if (currentLevel == ViewLevel.plans) {
      setState(() => currentLevel = ViewLevel.audits);
      fetchData();
      return;
    }
    if (currentLevel == ViewLevel.audits) {
      if (_sessionCompanyApplied || widget.showMenuBack) {
        Navigator.of(context).pop();
      } else {
        setState(() => currentLevel = ViewLevel.companies);
        fetchData();
      }
      return;
    }
    if (widget.showMenuBack) {
      Navigator.of(context).pop();
    }
  }

  String _appBarTitle() {
    switch (currentLevel) {
      case ViewLevel.companies:
        return 'Auditorías';
      case ViewLevel.audits:
        return 'Auditorías en curso';
      case ViewLevel.plans:
        return selectedAudit?['title']?.toString() ??
            selectedAudit?['name']?.toString() ??
            'Planes';
    }
  }

  Widget buildList() {
    List<Map<String, dynamic>> data = [];
    String emptyMessage = '';

    switch (currentLevel) {
      case ViewLevel.companies:
        data = companies;
        emptyMessage = 'No hay auditorías asignadas';
        break;
      case ViewLevel.audits:
        data = audits;
        emptyMessage = 'No hay auditorías en curso';
        break;
      case ViewLevel.plans:
        data = plans;
        emptyMessage = 'No hay planes en esta auditoría';
        break;
    }

    if (isLoading) return const Center(child: SimLoadingIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));
    if (data.isEmpty) return Center(child: Text(emptyMessage));

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Text(
              currentLevel == ViewLevel.companies
                  ? item['name'] ?? 'Company ${item['id']}'
                  : item['name'] ?? item['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: currentLevel == ViewLevel.audits && item['start'] != null
                ? Text(
                    formatDate(item['start']),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  )
                : currentLevel == ViewLevel.plans && item['moment'] != null
                    ? Text(
                        formatDate(item['moment']),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      )
                    : null,
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              switch (currentLevel) {
                case ViewLevel.companies:
                  selectedCompany = item;
                  currentLevel = ViewLevel.audits;
                  break;
                case ViewLevel.audits:
                  selectedAudit = item;
                  currentLevel = ViewLevel.plans;
                  break;
                case ViewLevel.plans:
                  selectedPlan = item;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LinesPage(
                        plan: selectedPlan!,
                        company: selectedCompany!,
                      ),
                    ),
                  );
                  return;
              }
              fetchData();
            },
          ),
        );
      },
    );
  }

  Widget _auditBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _appBarTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: fetchData,
              ),
            ],
          ),
        ),
        Expanded(child: buildList()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showMenuBack) {
      return _auditBody();
    }

    final showBack = currentLevel != ViewLevel.companies ||
        widget.showMenuBack ||
        _sessionCompanyApplied;

    return Scaffold(
      appBar: SimBrandedAppBar(
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: _auditBody(),
    );
  }
}
