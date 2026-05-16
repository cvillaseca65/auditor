import 'package:flutter/material.dart';

import '../../../screens/media_viewer_page.dart';
import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../authenticated_network_image.dart';
import 'detail_section_card.dart';
import 'detail_utils.dart';

/// Adjuntos: descripción (si existe) + enlace abrir/descargar (sin nombre de archivo en storage).
class DetailAttachmentsSection extends StatelessWidget {
  const DetailAttachmentsSection({
    super.key,
    required this.files,
    this.title = 'Archivos adjuntos',
  });

  final List<Map<String, dynamic>> files;
  final String title;

  void _open(BuildContext context, Map<String, dynamic> file) {
    final url = file['url']?.toString() ?? '';
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerPage(
          url: url,
          title: DetailUtils.attachmentDisplayTitle(file),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final linkStyle = ContentText.bodyMedium(context)?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary.withValues(alpha: 0.5),
        );

    final images = files
        .where(
          (f) => DetailUtils.isImageUrl(f['url']?.toString() ?? ''),
        )
        .toList();
    final others = files.where((f) => !images.contains(f)).toList();

    return DetailSectionCard(
      title: title,
      icon: Icons.attach_file,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (images.isNotEmpty) ...[
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final file = images[index];
                  final url = file['url']!.toString();
                  final desc = DetailUtils.attachmentDescription(file);
                  return Material(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _open(context, file),
                      child: SizedBox(
                        width: 112,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AuthenticatedNetworkImage(
                              url: url,
                              fit: BoxFit.cover,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                            ),
                            if (desc.isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  color: Colors.black54,
                                  child: Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            const Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (others.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ],
          for (final file in others) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => _open(context, file),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        DetailUtils.isPdfUrl(file['url']?.toString() ?? '')
                            ? Icons.picture_as_pdf_outlined
                            : Icons.insert_drive_file_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (DetailUtils.attachmentDescription(file)
                                .isNotEmpty)
                              Text(
                                DetailUtils.attachmentDescription(file),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: ContentText.bodyMedium(context)
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: DetailUtils.attachmentDescription(file)
                                        .isNotEmpty
                                    ? 6
                                    : 0,
                              ),
                              child: Text(
                                'Abrir / descargar',
                                style: linkStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.download_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
