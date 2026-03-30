import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _prefKey = 'eamu_import_disclaimer_accepted';
const _githubUrl = 'https://github.com/BPIManager/IIDX-Scraping-Bookmarklet';

/// Returns true if the disclaimer has already been accepted.
Future<bool> isDisclaimerAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefKey) ?? false;
}

/// Marks the disclaimer as accepted.
Future<void> _acceptDisclaimer() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey, true);
}

/// Shows the first-use disclaimer dialog.
/// Returns true if the user accepted, false if they cancelled.
Future<bool> showDisclaimerDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _DisclaimerDialog(),
  );
  return result ?? false;
}

class _DisclaimerDialog extends StatelessWidget {
  const _DisclaimerDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自動インポート機能について'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'この機能はeAMUSEMENT GATEからスコアデータを取得します。\n\n'
              '・セキュリティ上のリスクを伴います。必ずBPIManager/BPIM2-Flutterでソースコードを確認してご利用ください\n'
              '・問題が発生した場合はGitHubにてご報告ください',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(_githubUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                _githubUrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () async {
            await _acceptDisclaimer();
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('同意して使用する'),
        ),
      ],
    );
  }
}
