import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class LinesPage extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> company;

  const LinesPage({super.key, required this.plan, required this.company});

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  Map<String, dynamic>? planFull;
  List<Map<String, dynamic>> lines = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchPlanFull();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchPlanFull() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final token = await _token();
    if (token == null) return;

    final url =
        '${ApiConfig.baseUrl}/api/v1/plans/${widget.plan['id']}/full/';

    final headers = {
      'Authorization': 'Bearer $token',
      'X-Company-ID': widget.company['id'].toString(),
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        planFull = data;
        lines = List<Map<String, dynamic>>.from(data['lines'] ?? []);
        lines.sort((a, b) {
          final na = '${a['name'] ?? ''}'.toLowerCase();
          final nb = '${b['name'] ?? ''}'.toLowerCase();
          return na.compareTo(nb);
        });
      } else {
        error = 'Error ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error fetching plan: $e';
    }

    setState(() => isLoading = false);
  }

  Future<void> _showLineEditor({Map<String, dynamic>? line}) async {
    final TextEditingController controller =
        TextEditingController(text: line != null ? line['name'] ?? '' : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(line == null ? 'New Line' : 'Edit Line'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter evidence',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Subir / Cámara'),
                onPressed: () async {
                  if (line == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Guarda la línea antes de subir archivos'),
                      ),
                    );
                    return;
                  }
                  await _uploadFiles(line['id']);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('La línea no puede estar vacía')),
                );
                return;
              }

              final token = await _token();
              if (token == null) return;

              final url = line == null
                  ? '${ApiConfig.baseUrl}/api/v1/lines/'
                  : '${ApiConfig.baseUrl}/api/v1/lines/${line['id']}/';

              final body = jsonEncode({
                'plan': int.parse(widget.plan['id'].toString()),
                'name': controller.text,
              });

              final response = await (line == null
                  ? http
                      .post(
                        Uri.parse(url),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                          'X-Company-ID': widget.company['id'].toString(),
                        },
                        body: body,
                      )
                      .timeout(Duration(seconds: ApiConfig.timeoutSeconds))
                  : http
                      .put(
                        Uri.parse(url),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                          'X-Company-ID': widget.company['id'].toString(),
                        },
                        body: body,
                      )
                      .timeout(Duration(seconds: ApiConfig.timeoutSeconds)));


              if (response.statusCode == 200 || response.statusCode == 201) {
                await fetchPlanFull();
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Error saving line: ${response.statusCode}')),
                );
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  Future<void> _uploadFiles(int lineId) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    final token = await _token();
    if (token == null) return;

    for (final file in result.files) {
      if (file.bytes == null) continue;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/v1/lines/upload/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-Company-ID'] = widget.company['id'].toString();
      request.fields['line'] = lineId.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'attach_file',
          file.bytes!,
          filename: file.name,
        ),
      );

      await request.send();
    }

    await fetchPlanFull();
  }

  Widget buildTopics(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        ...items.map((e) => InkWell(
              onTap: () async {
                final urlStr = e['url']?.toString() ?? '';
                if (urlStr.isNotEmpty) {
                  final url = Uri.parse(urlStr);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  e['name'],
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (error.isNotEmpty) {
      return Scaffold(body: Center(child: Text(error)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${planFull?['audited']?['name'] ?? ''} - '
                '${planFull?['position']?['name'] ?? ''} - '
                '${planFull?['location']?['name'] ?? ''}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLineEditor(),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTopics("Customers", planFull?['customers'] ?? []),
            buildTopics("Assets", planFull?['assets'] ?? []),
            buildTopics("Documents", planFull?['documents'] ?? []),
            buildTopics("Kpis", planFull?['kpis'] ?? []),
            buildTopics("Minutes", planFull?['minutes'] ?? []),
            buildTopics("Nc", planFull?['ncs'] ?? []),
            buildTopics("Normativa", planFull?['complys'] ?? []),
            buildTopics("Comités", planFull?['committees'] ?? []),
            buildTopics("Objetivos", planFull?['objectives'] ?? []),
            buildTopics("Oportunidades", planFull?['opportunitys'] ?? []),
            buildTopics("Proyectos", planFull?['projects'] ?? []),
            buildTopics("Cargos", planFull?['positions'] ?? []),
            buildTopics("Procesos", planFull?['processs'] ?? []),
            buildTopics("Repositorios", planFull?['repositorys'] ?? []),
            buildTopics("Riesgos", planFull?['risks'] ?? []),
            buildTopics("Proveedores", planFull?['suppliers'] ?? []),
            buildTopics("Checlist", planFull?['checklists'] ?? []),
            buildTopics("Ítems", planFull?['items'] ?? []),
            buildTopics("Cambios", planFull?['changes'] ?? []),
            buildTopics("Capacitación", planFull?['trainings'] ?? []),
            buildTopics("Revisión Gerencia", planFull?['reviews'] ?? []),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text("Lines",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...lines.map((line) {
              final attachments =
                  List<Map<String, dynamic>>.from(line['attach_files'] ?? []);

              return Card(
                child: ListTile(
                  title: Text(line['name'] ?? 'Line ${line['id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attachments.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.insert_drive_file),
                          onPressed: () async {
                            final fileUrl = attachments.first['attach_file'];
                            if (fileUrl != null) {
                              final uri = Uri.parse(fileUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                        ),
                      const Icon(Icons.edit),
                    ],
                  ),
                  onTap: () => _showLineEditor(line: line),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
