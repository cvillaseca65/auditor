import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/nc_hallazgos_service.dart';
import '../util/file_bytes.dart';
import 'login_page.dart';

class _PendingAttachment {
  _PendingAttachment({
    required this.name,
    this.path,
    this.bytes,
  }) : assert(
          (path != null && path.isNotEmpty) ||
              (bytes != null && bytes.isNotEmpty),
        );

  final String name;
  final String? path;
  final Uint8List? bytes;
  String description = '';
}

/// Formulario alineado con Django `NcCreateForm` / `NcCreateView` (nc/create/).
class HallazgosCreatePage extends StatefulWidget {
  const HallazgosCreatePage({super.key});

  @override
  State<HallazgosCreatePage> createState() => _HallazgosCreatePageState();
}

class _HallazgosCreatePageState extends State<HallazgosCreatePage> {
  final _findingController = TextEditingController();

  String? _token;
  List<IdTitle> _companies = [];
  int? _companyId;
  NcFormOptions? _options;
  bool _loadingCompanies = true;
  bool _loadingOptions = false;
  bool _submitting = false;
  String? _pageError;

  DateTime _date = DateTime.now();
  int? _originId;
  int? _areaId;
  int? _locationId;
  final Set<int> _involvedUserIds = {};
  final Map<int, String> _involvedTitles = {};
  final List<_PendingAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    _token = token;
    try {
      final companies = await NcHallazgosService.fetchNcCompanies(token);
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _companyId = companies.isEmpty ? null : companies.first.id;
        _loadingCompanies = false;
      });
      if (_companyId != null) {
        await _loadOptions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCompanies = false;
        _pageError = '$e';
      });
    }
  }

  Future<void> _loadOptions() async {
    final token = _token;
    final cid = _companyId;
    if (token == null || cid == null) return;

    setState(() {
      _loadingOptions = true;
      _pageError = null;
      _options = null;
      _originId = null;
      _areaId = null;
      _locationId = null;
      _involvedUserIds.clear();
      _involvedTitles.clear();
    });

    try {
      final opt = await NcHallazgosService.fetchFormOptions(
        token: token,
        companyId: cid,
      );
      if (!mounted) return;
      setState(() {
        _options = opt;
        _loadingOptions = false;
        if (opt.origins.length == 1) _originId = opt.origins.first.id;
        if (opt.areas.length == 1) _areaId = opt.areas.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOptions = false;
        _pageError = '$e';
      });
    }
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (r == null || !mounted) return;
    var skippedWebWithoutBytes = false;
    setState(() {
      for (final f in r.files) {
        final bytes = f.bytes;
        final path = f.path;
        if (bytes != null && bytes.isNotEmpty) {
          _attachments.add(
            _PendingAttachment(name: f.name, bytes: bytes, path: path),
          );
        } else if (!kIsWeb && path != null && path.isNotEmpty) {
          _attachments.add(_PendingAttachment(name: f.name, path: path));
        } else if (kIsWeb) {
          skippedWebWithoutBytes = true;
        }
      }
    });
    if (skippedWebWithoutBytes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo leer el archivo en el navegador. '
            'Prueba con otro archivo o uno más pequeño.',
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final token = _token;
    final cid = _companyId;
    if (token == null || cid == null) return;

    final finding = _findingController.text.trim();
    if (_originId == null || _areaId == null || finding.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origen, área y hallazgo son obligatorios.'),
        ),
      );
      return;
    }

    final dateIso =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    final parts = <NcAttachmentPart>[];
    for (final a in _attachments) {
      var bytes = a.bytes;
      if (bytes == null || bytes.isEmpty) {
        final p = a.path;
        if (p != null && p.isNotEmpty) {
          bytes = await readLocalFileBytes(p);
          if (!mounted) return;
        }
      }
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo leer un archivo adjunto. Vuelve a seleccionarlo.',
            ),
          ),
        );
        return;
      }
      parts.add(
        NcAttachmentPart(
          fileName: a.name,
          bytes: bytes,
          documentDescription: a.description,
        ),
      );
    }

    setState(() => _submitting = true);

    try {
      await NcHallazgosService.createNc(
        token: token,
        companyId: cid,
        dateIso: dateIso,
        originId: _originId!,
        areaId: _areaId!,
        locationId: _locationId,
        finding: finding,
        userIds: _involvedUserIds.toList(),
        attachments: parts,
      );

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hallazgo creado exitosamente'),
          ),
        );
        _resetAfterSuccessfulCreate();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<IdTitle> _involvedSelectedItems() {
    final list = _involvedUserIds
        .map((id) => IdTitle(id: id, title: _involvedTitles[id] ?? '#$id'))
        .toList();
    list.sort(IdTitle.compareAlphabetic);
    return list;
  }

  Future<void> _logoutToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _resetAfterSuccessfulCreate() {
    setState(() {
      _findingController.clear();
      _attachments.clear();
      _date = DateTime.now();
      _locationId = null;
      _involvedUserIds.clear();
      _involvedTitles.clear();
      _originId = null;
      _areaId = null;
    });
    final cid = _companyId;
    final token = _token;
    if (token != null && cid != null) {
      _loadOptions();
    }
  }

  PreferredSizeWidget _hallazgosAppBar() {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      title: const Text('Hallazgos'),
      automaticallyImplyLeading: canPop,
      actions: [
        if (!canPop)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logoutToLogin,
          ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  void dispose() {
    _findingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCompanies) {
      return Scaffold(
        appBar: _hallazgosAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_companies.isEmpty) {
      return Scaffold(
        appBar: _hallazgosAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _pageError ??
                  'No tienes empresas asignadas para crear hallazgos.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _hallazgosAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_pageError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _pageError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Compañía',
                border: OutlineInputBorder(),
              ),
              value: _companyId,
              items: _companies
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.title)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _companyId = v);
                _loadOptions();
              },
            ),
            const SizedBox(height: 16),
            if (_loadingOptions)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_options != null) ...[
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                  '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  border: OutlineInputBorder(),
                ),
                value: _originId,
                items: _options!.origins
                    .map(
                      (o) =>
                          DropdownMenuItem(value: o.id, child: Text(o.title)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _originId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Área del hallazgo',
                  border: OutlineInputBorder(),
                ),
                value: _areaId,
                items: _options!.areas
                    .map(
                      (o) =>
                          DropdownMenuItem(value: o.id, child: Text(o.title)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _areaId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Localidad (opcional)',
                  border: OutlineInputBorder(),
                ),
                value: _locationId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('—'),
                  ),
                  ..._options!.locations.map(
                    (o) => DropdownMenuItem<int?>(
                      value: o.id,
                      child: Text(o.title),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _locationId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _findingController,
                decoration: const InputDecoration(
                  labelText: 'Hallazgo',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownSearch<IdTitle>.multiSelection(
                key: ValueKey<int?>(_companyId),
                enabled: _token != null && _companyId != null,
                selectedItems: _involvedSelectedItems(),
                itemAsString: (u) => u.title,
                compareFn: (a, b) => a.id == b.id,
                items: (filter, loadProps) async {
                  final t = _token!;
                  final c = _companyId!;
                  final r = await NcHallazgosService.searchCompanyUsers(
                    token: t,
                    companyId: c,
                    query: filter,
                    page: 1,
                    perPage: 40,
                  );
                  return r.items;
                },
                onChanged: (List<IdTitle> selected) {
                  setState(() {
                    _involvedUserIds.clear();
                    _involvedTitles.clear();
                    for (final u in selected) {
                      _involvedUserIds.add(u.id);
                      _involvedTitles[u.id] = u.title;
                    }
                  });
                },
                popupProps: PopupPropsMultiSelection.menu(
                  showSearchBox: true,
                  disableFilter: true,
                  searchDelay: const Duration(milliseconds: 400),
                  constraints: const BoxConstraints(maxHeight: 360),
                  showSelectedItems: true,
                ),
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: 'Involucrados',
                    border: OutlineInputBorder(),
                    hintText: 'Desplegar, buscar y marcar varios',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Adjuntar archivos'),
              ),
              ..._attachments.asMap().entries.map((e) {
                final i = e.key;
                final a = e.value;
                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _attachments.removeAt(i)),
                            ),
                          ],
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Descripción del documento',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (t) => a.description = t,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar hallazgo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
