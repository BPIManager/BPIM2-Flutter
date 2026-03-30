import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EagateImportScreen extends StatefulWidget {
  const EagateImportScreen({super.key});

  @override
  State<EagateImportScreen> createState() => _EagateImportScreenState();
}

class _EagateImportScreenState extends State<EagateImportScreen> {
  bool _loginRequired = false;
  bool _processing = false;
  String _statusText = '';

  final _scoreUrl = WebUri(
    'https://p.eagate.573.jp/game/2dx/33/djdata/score_download.html?style=SP',
  );

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
  );

  Future<void> _onPageLoaded(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    if (_processing) return;

    final bodyText =
        await controller.evaluateJavascript(
              source: 'document.body?.innerText ?? ""',
            )
            as String?;

    final loginRequired =
        bodyText?.contains('ご利用にはe-amusementへのログインが必要です。') == true;

    if (loginRequired) {
      if (mounted) {
        setState(() {
          _loginRequired = true;
          _processing = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loginRequired = false);

    if (url?.toString().contains('score_download') != true) return;

    if (mounted) {
      setState(() {
        _processing = true;
        _statusText = 'スコアデータを確認中...';
      });
    }
    await _tryExtractCsv(controller);
  }

  void _previewCsv(String csv, {required String source}) {
    final lines = csv.split('\n');
    debugPrint('=== CSV取得完了 (source: $source) ===');
    debugPrint('総行数: ${lines.length}行');
    final preview = lines.take(5).join('\n');
    debugPrint('--- 先頭5行 ---\n$preview');
    debugPrint('===============');
  }

  Future<void> _tryExtractCsv(InAppWebViewController controller) async {
    final csvValue =
        await controller.evaluateJavascript(
              source: '''
      (function() {
        const ta = document.querySelector('textarea#score_data');
        return ta && ta.value ? ta.value : null;
      })();
    ''',
            )
            as String?;

    if (csvValue != null && csvValue.isNotEmpty) {
      _previewCsv(csvValue, source: 'textarea#score_data');
      if (mounted) Navigator.pop(context, csvValue);
      return;
    }

    // Fallback: scraper.js
    if (mounted) setState(() => _statusText = 'スクレイパーを実行中...');
    final js = await rootBundle.loadString('assets/scraper.js');
    final script = js.replaceFirst('"__MODE__"', '"all"');
    await controller.evaluateJavascript(source: script);
  }

  void _onScraperMessage(String raw) {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'progress':
        if (mounted) {
          setState(() {
            _statusText =
                '${msg['level']} (${msg['page']}ページ目) ${msg['songs']}曲';
          });
        }
      case 'done':
        final csv = msg['csv'] as String;
        _previewCsv(csv, source: 'scraper.js');
        if (mounted) Navigator.pop(context, csv);
      case 'error':
        if (mounted) {
          setState(() => _processing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: ${msg['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア取得'),
        backgroundColor: const Color(0xFF5B21B6),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: _scoreUrl),
            initialSettings: _settings,
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'ScraperChannel',
                callback: (args) {
                  if (args.isNotEmpty) _onScraperMessage(args[0] as String);
                },
              );
            },
            onLoadStop: (controller, url) => _onPageLoaded(controller, url),
          ),
          if (_loginRequired)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.orange.shade700,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ログインが必要です。ログイン後、自動的にスコアを取得します。',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_processing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Color(0xEB5B21B6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
