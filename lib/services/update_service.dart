import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks GitHub Releases for a newer build of the app and, if found,
/// shows a dialog letting the user download + install the new APK.
///
/// IMPORTANT: replace [githubOwner] and [githubRepo] below with your
/// actual GitHub username and repo name.
class UpdateService {
  static const String githubOwner = 'Scorpion-005';
  static const String githubRepo = 'design-process-tracker';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final url = Uri.parse(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
      );
      final response = await http
          .get(url, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return; // no releases yet, or network issue

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?) ?? '';
      final latestBuild = int.tryParse(tagName.replaceAll(RegExp(r'[^0-9]'), ''));
      if (latestBuild == null || latestBuild <= currentBuild) return;

      final assets = (data['assets'] as List?) ?? [];
      String? apkUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null) return;

      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('New update available'),
          content: const Text(
            'A newer version of Design Tracker is ready. Update now to get the latest changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final uri = Uri.parse(apkUrl!);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Silently ignore Ã¢â‚¬â€ never block app startup because of update-check failures.
    }
  }
}
