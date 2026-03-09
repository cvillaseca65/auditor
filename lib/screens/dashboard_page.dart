import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'login_page.dart';
import 'lines_page.dart';

enum ViewLevel { companies, audits, plans }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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

  @override
  void initState() {
    super.initState();
    fetchData();
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

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

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
            break;
          case ViewLevel.audits:
            audits =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            break;
          case ViewLevel.plans:
            plans =
                data.map((e) => Map<String, dynamic>.from(e)).toList();
            break;
        }
      } else if (response.statusCode == 401) {
        _logout();
        return;
      } else {
        error = 'Error ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error fetching data: $e';
    }

    setState(() => isLoading = false);
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

  Widget buildList() {
    List<Map<String, dynamic>> data = [];
    String emptyMessage = '';

    switch (currentLevel) {
      case ViewLevel.companies:
        data = companies;
        emptyMessage = 'No companies';
        break;
      case ViewLevel.audits:
        data = audits;
        emptyMessage = 'No audits';
        break;
      case ViewLevel.plans:
        data = plans;
        emptyMessage = 'No plans';
        break;
    }

    if (isLoading) return const Center(child: CircularProgressIndicator());
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
                  : item['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: currentLevel == ViewLevel.audits &&
                    item['start'] != null
                ? Text(
                    formatDate(item['start']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                : currentLevel == ViewLevel.plans &&
                        item['moment'] != null
                    ? Text(
                        formatDate(item['moment']),
                        style: const TextStyle(
                          fontSize: 12,
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
                  break;
              }
              fetchData();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLevel == ViewLevel.companies
              ? 'Compañías'
              : currentLevel == ViewLevel.audits
                  ? 'Auditorías - ${selectedCompany?['name'] ?? ''}'
                  : 'Planes - ${selectedAudit?['title'] ?? ''}',
        ),
        leading: currentLevel != ViewLevel.companies
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    switch (currentLevel) {
                      case ViewLevel.audits:
                        currentLevel = ViewLevel.companies;
                        break;
                      case ViewLevel.plans:
                        currentLevel = ViewLevel.audits;
                        break;
                      default:
                        break;
                    }
                    fetchData();
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: buildList(),
    );
  }
}
