import 'package:flutter/material.dart';



import '../services/mobile_api_service.dart';

import '../util/plain_text.dart';

import '../util/open_sim_url.dart';

import '../util/session_nav.dart';

import '../widgets/detail_fields_list.dart';

import '../widgets/relations_section.dart';

import 'in_app_url_page.dart';



class DocumentoDetailPage extends StatefulWidget {

  final int documentId;



  const DocumentoDetailPage({super.key, required this.documentId});



  @override

  State<DocumentoDetailPage> createState() => _DocumentoDetailPageState();

}



class _DocumentoDetailPageState extends State<DocumentoDetailPage> {

  final _api = MobileApiService();

  bool _loading = true;

  String? _error;

  Map<String, dynamic>? _data;



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    try {

      final data = await _api.fetchDocumentDetail(widget.documentId);

      if (!mounted) return;

      setState(() {

        _data = data;

        _loading = false;

        _error = null;

      });

    } on MobileApiException catch (e) {

      if (!mounted) return;

      if (e.statusCode == 401) {

        await navigateToLogin(context);

        return;

      }

      setState(() {

        _loading = false;

        _error = e.message;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() {

        _loading = false;

        _error = 'No se pudo cargar el documento. Compruebe la conexión.';

      });

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Documento')),

      body: _loading

          ? const Center(child: CircularProgressIndicator())

          : _error != null

              ? Center(

                  child: Padding(

                    padding: const EdgeInsets.all(24),

                    child: Column(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(_error!, textAlign: TextAlign.center),

                        const SizedBox(height: 16),

                        ElevatedButton(

                          onPressed: _load,

                          child: const Text('Reintentar'),

                        ),

                      ],

                    ),

                  ),

                )

              : _buildBody(),

    );

  }



  Widget _buildBody() {

    final d = _data!;

    final fields = d['fields'] as List<dynamic>? ?? [];

    final files = d['files'] as List<dynamic>? ?? [];



    return ListView(

      padding: const EdgeInsets.all(16),

      children: [

        Text(

          '${plainText(d['code']?.toString())} ${plainText(d['title']?.toString())}'

              .trim(),

          style: Theme.of(context).textTheme.titleLarge,

        ),

        if (plainText(d['document_type']?.toString()).isNotEmpty) ...[

          const SizedBox(height: 4),

          Text(

            plainText(d['document_type']?.toString()),

            style: Theme.of(context).textTheme.titleSmall?.copyWith(

                  color: Theme.of(context).colorScheme.primary,

                ),

          ),

        ],

        const SizedBox(height: 16),

        DetailFieldsList(fields: fields),

        const SizedBox(height: 8),

        Text(

          'Archivos',

          style: Theme.of(context).textTheme.titleSmall?.copyWith(

                fontWeight: FontWeight.w600,

              ),

        ),

        const SizedBox(height: 8),

        if (files.isEmpty)

          const Text('Sin archivos adjuntos')

        else

          ...files.map((f) {

            final map = f as Map<String, dynamic>;

            final url = map['url']?.toString() ?? '';

            return Card(

              child: ListTile(

                title: Text(() {

                  final label = plainText(

                    map['description']?.toString() ?? map['name']?.toString(),

                  );

                  return label.isNotEmpty ? label : 'Archivo';

                }()),

                trailing: const Icon(Icons.download),

                onTap: url.isNotEmpty

                    ? () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) => InAppUrlPage(

                              url: url,

                              title: plainText(

                                map['description']?.toString() ??

                                    map['name']?.toString(),

                              ),

                            ),

                          ),

                        );

                      }

                    : null,

              ),

            );

          }),

        const SizedBox(height: 16),

        RelationsSection(relations: d['relations'] as List<dynamic>? ?? []),

        const SizedBox(height: 8),

        ElevatedButton.icon(

          onPressed: () {

            final url = d['open_url']?.toString() ?? '';

            if (url.isNotEmpty) openSimUrl(url);

          },

          icon: const Icon(Icons.open_in_browser),

          label: const Text('Abrir en SIM'),

        ),

      ],

    );

  }

}

