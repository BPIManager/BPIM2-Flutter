import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../widgets/disclaimer_dialog.dart';
import 'eagate_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? _bpiController;
  bool _importing = false;
  String? _pendingCsv;

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
    userAgent:
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
  );

  Future<void> _onFabPressed() async {
    if (_importing) return;

    final accepted = await isDisclaimerAccepted();
    if (!accepted && mounted) {
      final ok = await showDisclaimerDialog(context);
      if (!ok) return;
    }

    if (!mounted) return;
    final csv = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const EagateImportScreen()),
    );
    if (csv == null || !mounted) return;
    await _importCsv(csv);
  }

  Future<void> _importCsv(String csv) async {
    if (_bpiController == null) return;
    setState(() {
      _importing = true;
      _pendingCsv = csv;
    });
    await _bpiController!.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://bpi2.poyashi.me/import')),
    );
  }

  Future<void> _onPageLoaded(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    final csv = _pendingCsv;
    if (csv == null) return;
    if (url?.toString().contains('/import') != true) return;

    _pendingCsv = null;
    final csvJson = jsonEncode(csv);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await controller.evaluateJavascript(
      source:
          '''
      (function() {
        const ta = document.querySelector('textarea#csv-data');
        if (!ta) return 'ERROR: textarea#csv-data not found';
        const setter = Object.getOwnPropertyDescriptor(
          window.HTMLTextAreaElement.prototype, 'value'
        )?.set;
        if (setter) {
          setter.call(ta, $csvJson);
        } else {
          ta.value = $csvJson;
        }
        ta.dispatchEvent(new Event('input', { bubbles: true }));
        ta.dispatchEvent(new Event('change', { bubbles: true }));
        const btn = Array.from(document.querySelectorAll('button')).find(
          b => b.textContent.trim().includes('インポートを開始')
        );
        if (!btn) return 'ERROR: button not found';
        btn.click();
        return 'OK';
      })();
    ''',
    );

    if (mounted) setState(() => _importing = false);
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction action,
  ) async {
    if (!mounted) return false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AuthPopup(windowId: action.windowId),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://bpi2.poyashi.me/'),
              ),
              initialSettings: _settings,
              onWebViewCreated: (c) => _bpiController = c,
              onLoadStop: _onPageLoaded,
              onCreateWindow: _onCreateWindow,
            ),
            if (_importing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importing ? null : _onFabPressed,
        backgroundColor: const Color(0xFF260606),
        foregroundColor: Colors.white,
        child: _importing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.sync),
      ),
    );
  }
}

class _AuthPopup extends StatelessWidget {
  const _AuthPopup({required this.windowId});

  final int windowId;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: InAppWebView(
        windowId: windowId,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        ),
        onCloseWindow: (_) => Navigator.of(context).pop(),
      ),
    );
  }
}
