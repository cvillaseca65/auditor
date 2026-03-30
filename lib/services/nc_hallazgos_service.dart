import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class IdTitle {
  const IdTitle({required this.id, required this.title});

  final int id;
  final String title;

  static IdTitle fromJson(Map<String, dynamic> j) {
    return IdTitle(
      id: j['id'] as int,
      title: '${j['title'] ?? j['name'] ?? ''}',
    );
  }

  static int compareAlphabetic(IdTitle a, IdTitle b) {
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}

class NcFormOptions {
  const NcFormOptions({
    required this.origins,
    required this.areas,
    required this.locations,
    required this.involvedUsers,
  });

  final List<IdTitle> origins;
  final List<IdTitle> areas;
  final List<IdTitle> locations;
  final List<IdTitle> involvedUsers;

  static NcFormOptions fromJson(Map<String, dynamic> m) {
    List<IdTitle> list(String key) {
      final raw = m[key];
      if (raw is! List) return [];
      final items = raw
          .map((e) => IdTitle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      items.sort(IdTitle.compareAlphabetic);
      return items;
    }

    return NcFormOptions(
      origins: list('origins'),
      areas: list('areas'),
      locations: list('locations'),
      involvedUsers: list('involved_users'),
    );
  }
}

/// Adjunto enviado junto al crear la NC (mismo POST multipart).
class NcAttachmentPart {
  const NcAttachmentPart({
    required this.fileName,
    required this.bytes,
    this.documentDescription = '',
  });

  final String fileName;
  final Uint8List bytes;
  final String documentDescription;
}

class NcHallazgosService {
  NcHallazgosService._();

  static Map<String, String> _jsonHeaders(String token) => {
        ...ApiConfig.defaultHeaders(token: token),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Future<List<IdTitle>> fetchNcCompanies(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ncCompaniesPath}');
    final res = await http
        .get(uri, headers: _jsonHeaders(token))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (res.statusCode != 200) {
      throw Exception('Empresas NC: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map ? (decoded['results'] as List? ?? []) : []);
    final out = list
        .map((e) => IdTitle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    out.sort(IdTitle.compareAlphabetic);
    return out;
  }

  static Future<NcFormOptions> fetchFormOptions({
    required String token,
    required int companyId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ncFormOptionsPath}');
    final res = await http
        .get(
          uri,
          headers: {
            ...ApiConfig.defaultHeaders(token: token),
            'Accept': 'application/json',
            'X-Company-ID': '$companyId',
          },
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (res.statusCode != 200) {
      throw Exception('Opciones NC: ${res.statusCode} ${res.body}');
    }
    return NcFormOptions.fromJson(
      Map<String, dynamic>.from(jsonDecode(res.body) as Map),
    );
  }

  /// Crea la NC y adjuntos en **un solo** POST multipart (transaccional en servidor).
  static Future<int> createNc({
    required String token,
    required int companyId,
    required String dateIso,
    required int originId,
    required int areaId,
    int? locationId,
    required String finding,
    List<int> userIds = const [],
    List<NcAttachmentPart> attachments = const [],
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ncCreatePath}');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(ApiConfig.defaultHeaders(token: token))
      ..headers['X-Company-ID'] = '$companyId'
      ..fields['date'] = dateIso
      ..fields['origin_id'] = '$originId'
      ..fields['area_id'] = '$areaId'
      ..fields['finding'] = finding
      ..fields['user_ids'] = jsonEncode(userIds)
      ..fields['document_descriptions'] = jsonEncode(
        attachments.map((a) => a.documentDescription).toList(),
      );
    if (locationId != null) {
      request.fields['location_id'] = '$locationId';
    }
    for (final a in attachments) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attach_file',
          a.bytes,
          filename: a.fileName,
        ),
      );
    }

    final streamed = await request.send().timeout(
          Duration(seconds: ApiConfig.timeoutSeconds),
        );
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) {
      throw Exception('Crear NC: ${res.statusCode} ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return map['id'] as int;
  }

  static Future<void> uploadAttachment({
    required String token,
    required int companyId,
    required int ncId,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    String documentDescription = '',
  }) async {
    final hasBytes = fileBytes != null && fileBytes.isNotEmpty;
    final hasPath =
        filePath != null && filePath.isNotEmpty && !kIsWeb;

    if (!hasBytes && !hasPath) {
      if (kIsWeb) {
        throw UnsupportedError(
          'En el navegador el archivo debe cargarse en memoria (bytes). '
          'Vuelve a elegir el archivo o prueba con uno más pequeño.',
        );
      }
      throw ArgumentError('filePath o fileBytes es requerido para el adjunto.');
    }

    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ncAttachmentPath(ncId)}');
    final http.MultipartFile filePart;
    if (hasBytes) {
      filePart = http.MultipartFile.fromBytes(
        'attach_file',
        fileBytes,
        filename: fileName,
      );
    } else {
      filePart = await http.MultipartFile.fromPath(
        'attach_file',
        filePath!,
        filename: fileName,
      );
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(ApiConfig.defaultHeaders(token: token))
      ..headers['X-Company-ID'] = '$companyId'
      ..fields['document_description'] = documentDescription
      ..files.add(filePart);

    final streamed = await request.send().timeout(
          Duration(seconds: ApiConfig.timeoutSeconds),
        );
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) {
      throw Exception('Adjunto NC: ${res.statusCode} ${res.body}');
    }
  }

  /// Búsqueda paginada de usuarios de la compañía (involucrados).
  static Future<({List<IdTitle> items, int totalCount})> searchCompanyUsers({
    required String token,
    required int companyId,
    String query = '',
    int page = 1,
    int perPage = 25,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.ncCompanyUsersSearchPath}',
    ).replace(
      queryParameters: {
        'q': query,
        'page': '$page',
        'per_page': '$perPage',
      },
    );
    final res = await http
        .get(
          uri,
          headers: {
            ...ApiConfig.defaultHeaders(token: token),
            'Accept': 'application/json',
            'X-Company-ID': '$companyId',
          },
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (res.statusCode != 200) {
      throw Exception('Buscar usuarios: ${res.statusCode} ${res.body}');
    }
    final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    final raw = map['items'];
    final list = raw is List ? raw : <dynamic>[];
    final items = list
        .map((e) => IdTitle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final total = map['total_count'];
    final totalCount = total is int ? total : int.tryParse('$total') ?? items.length;
    return (items: items, totalCount: totalCount);
  }
}
