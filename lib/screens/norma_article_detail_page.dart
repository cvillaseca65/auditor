import 'package:flutter/material.dart';

import '../core/widgets/mobile_detail/norma_article_detail_body.dart';
import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';
import '../util/plain_text.dart';
import '../util/session_nav.dart';

/// Detalle de artículo / cumplimiento (como `requirement_detail.html` en SIM).
class NormaArticleDetailPage extends StatefulWidget {
  const NormaArticleDetailPage({
    super.key,
    required this.complyId,
    required this.previewTitle,
  });

  final int complyId;
  final String previewTitle;

  @override
  State<NormaArticleDetailPage> createState() => _NormaArticleDetailPageState();
}

class _NormaArticleDetailPageState extends State<NormaArticleDetailPage> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchComplyDetail(widget.complyId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = plainText(
      _data?['title']?.toString() ?? widget.previewTitle,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1),
      ),
      body: _loading
          ? const Center(child: SimLoadingIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return NormaArticleDetailBody(data: _data!);
  }
}
