/// Clasificación de campos según `detail.html` de SIM (col-sm-12 vs columnas cortas).
abstract final class DetailFieldLayout {
  /// Por encima de este umbral → bloque ancho completo (TextField / col-sm-12).
  static const int fullWidthMinChars = 72;

  /// Etiquetas cortas: tabla superior (pares en 2 columnas).
  static const metaLabels = {
    'Código',
    'Versión',
    'Tipo',
    'Título',
    'Área',
    'Crea',
    'Solicitud',
    'Edición',
    'Eliminación',
    'Vista',
    'Estado',
    'Publicación',
    'Versión anterior',
    'Fecha',
    'Cierre',
    'Origen',
    'Grado',
    'Localidad',
    'Detector',
    'Responsable',
    'Índice',
    'Tipo acción',
    'N.º registro',
    'Gantt',
    'Id gantt',
    'Número',
    'Plazo',
    'Probabilidad %',
    'Prob. residual %',
    'Impacto',
    'Impacto residual',
    'Impacto inherente',
    'Presupuesto',
    'Costo',
    'Unidad',
    'Autoridad',
    'Activación',
    'Registro',
    'Código y versión',
    'Tipo de documento',
    'Contacto',
    'Eficaz (actual)',
    'Verificación (fecha)',
    'Autoriza',
    'Privado',
    'Público',
    'Creación',
    'Inicio',
    'Término',
    'Ejecución',
    'Fin / plazo',
    'Fecha de inicio',
    'Ejecutante',
    'Creador',
    'Prioridad',
    'Tipo de proceso',
    'Norma',
    'Control',
    'Clasificación del requisito',
    'Tolerancia lista',
    'Cumplimiento (resumen)',
    'Legal residual',
    'Reputación residual',
    'Financiero residual',
    'Tolerancia',
  };

  /// Textos largos: siempre ancho completo en móvil.
  static const proseLabels = {
    'Descripción',
    'Definiciones',
    'Contenido',
    'Objetivo',
    'Alcance',
    'Recursos',
    'Observación',
    'Hallazgo',
    'Retención',
    'Recuperación',
    'Almacenaje',
    'Disposición',
    'Protección',
    'Causa',
    'Asunto',
    'Descripción / alcance',
    'Plan de acción general',
    'Informe / reporte',
    'Bitácora (últimos registros)',
    'Observación registrada',
    'Acuerdos (actual)',
    'Asunto (actual)',
    'Requisito',
    'Cumplimiento',
    'Guía',
    'Otros',
    'Propósito',
    'Entradas',
    'Salidas',
    'Línea de tiempo',
    'Registro (recuperación, retención…)',
    'Ubicación / ancla',
    'Actividad',
    'Delito / norma',
    'Requisito (título)',
    'Adjunto(s)',
    'Reporte',
    'Informe de ejecución',
    'Informe de verificación *',
    'Motivo de rechazo',
    'Comentario (si rechaza)',
    'Causa raíz *',
    'Acuerdos *',
    'Descripción del documento',
    'Objetivo (proceso)',
    'Recursos (proceso documento)',
    'Participantes',
    'Contactos',
  };

  /// Claves API = texto largo (equivalente a TextField en SIM).
  static const fullWidthKeys = {
    'finding',
    'hallazgo',
    'subject',
    'task',
    'report',
    'report_preview',
    'observation',
    'observation_existing',
    'binnacle_recent',
    'plan',
    'agreement_preview',
    'subject_preview',
    'content_preview',
    'description_preview',
    'definition_preview',
    'cumplimiento',
    'cumplimiento_intro',
    'requisito',
    'guide',
    'other',
    'time_line_preview',
    'target_preview',
    'reach_preview',
    'resources_preview',
    'participants_preview',
    'contacts_preview',
    'element_in',
    'element_out',
    'ressource',
    'purposes',
    'description',
    'definition',
    'content',
    'target',
    'reach',
    'resources',
    'retention',
    'recuperation',
    'storage',
    'disposal',
    'protection',
    'cause',
    'attachments_preview',
    'document_record',
    'solicitation_summary',
    'activity',
    'crime',
    'anchor',
    'process_type',
    'requirement_title',
    'normative',
    'control_taxonomy',
    'control',
    'view_label',
    'tolerance_hint',
    'title',
    'participant',
    'contact',
    'mesure',
  };

  /// Fechas, números y metadatos cortos → rejilla 2 columnas.
  static const compactGridKeys = {
    'kind',
    'entity',
    'record_id',
    'number',
    'checklist_id',
    'checklist_title',
    'create',
    'start',
    'end',
    'date',
    'execution',
    'verification',
    'deadline_days',
    'deatline',
    'ac',
    'view',
    'effective',
    'probability',
    'residual_probability',
    'imp',
    'imp_res',
    'impact_inherent',
    'impact_residual',
    'budget',
    'cost',
    'priority',
    'area',
    'autoridad',
    'authority',
    'autority',
    'purpose',
    'tolerance_ready',
    'legal_residual',
    'reputation_residual',
    'financ_residual',
    'document_type',
    'code_version',
  };

  static bool isPersonDateField(Map<String, dynamic> field) {
    if (field['layout'] == 'person_date') return true;
    final key = field['key'] as String? ?? '';
    return key.startsWith('doc_');
  }

  static bool isFullWidthField(Map<String, dynamic> field) {
    if (isPersonDateField(field)) return false;
    if (field['layout'] == 'full_width') return true;

    final key = field['key'] as String?;
    if (key != null && fullWidthKeys.contains(key)) return true;
    if (key != null && compactGridKeys.contains(key)) return false;

    final label = (field['label'] as String? ?? '').trim();
    if (proseLabels.contains(label)) return true;
    if (_labelLooksLikeLongText(label)) return true;

    final value = (field['value'] as String? ?? '').trim();
    if (value.contains('\n')) return true;
    if (value.length > fullWidthMinChars) return true;

    return false;
  }

  static bool _labelLooksLikeLongText(String label) {
    final l = label.toLowerCase();
    const hints = [
      'descrip',
      'informe',
      'reporte',
      'observ',
      'hallazgo',
      'acuerdo',
      'asunto',
      'contenido',
      'definicion',
      'objetivo',
      'alcance',
      'recurso',
      'bitácora',
      'bitacora',
      'plan',
      'causa',
      'requisito',
      'cumplimiento',
      'guía',
      'guia',
      'adjunto',
      'motivo',
      'comentario',
      'evidencia',
    ];
    for (final h in hints) {
      if (l.contains(h)) return true;
    }
    return false;
  }

  static bool isCompactGridField(Map<String, dynamic> field) {
    if (isPersonDateField(field)) return true;
    if (isFullWidthField(field)) return false;

    final key = field['key'] as String?;
    if (key != null && compactGridKeys.contains(key)) return true;
    if (key == 'creator' || key == 'executor' || key == 'editor') return true;
    if (key == 'responsible') return true;

    final label = (field['label'] as String? ?? '').trim();
    if (metaLabels.contains(label)) {
      final value = (field['value'] as String? ?? '').trim();
      return value.length <= fullWidthMinChars;
    }

    final value = (field['value'] as String? ?? '').trim();
    return value.length <= 48 && !value.contains('\n');
  }

  static bool isProseField(Map<String, dynamic> field) =>
      isFullWidthField(field);

  static bool isMetaField(Map<String, dynamic> field) {
    if (isPersonDateField(field)) return false;
    if (isFullWidthField(field)) return false;
    if (isCompactGridField(field)) return false;

    final label = (field['label'] as String? ?? '').trim();
    if (metaLabels.contains(label)) return true;
    if (label.startsWith('Publicador') || label.startsWith('Publicación ')) {
      return true;
    }
    final value = (field['value'] as String? ?? '').trim();
    return value.length <= fullWidthMinChars;
  }

  static DetailFieldSplit split(List<Map<String, dynamic>> fields) {
    final meta = <Map<String, dynamic>>[];
    final prose = <Map<String, dynamic>>[];
    final compact = <Map<String, dynamic>>[];

    for (final f in fields) {
      if (isPersonDateField(f)) continue;
      if (isFullWidthField(f)) {
        prose.add(f);
      } else if (isMetaField(f)) {
        meta.add(f);
      } else if (isCompactGridField(f)) {
        compact.add(f);
      } else {
        prose.add(f);
      }
    }
    return DetailFieldSplit(meta: meta, prose: prose, compact: compact);
  }
}

class DetailFieldSplit {
  const DetailFieldSplit({
    required this.meta,
    required this.prose,
    required this.compact,
  });

  final List<Map<String, dynamic>> meta;
  final List<Map<String, dynamic>> prose;
  final List<Map<String, dynamic>> compact;

  bool get isEmpty => meta.isEmpty && prose.isEmpty && compact.isEmpty;
}
