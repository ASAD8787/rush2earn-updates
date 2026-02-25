import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/web3_config.dart';

class AppUpdateService {
  Future<String?> checkAndMaybeUpdate({required bool userInitiated}) async {
    try {
      final currentVersion = Web3Config.currentAppVersion.trim();
      final manifestUri = Uri.parse(Web3Config.appUpdateManifestUrl);
      final response = await http.get(manifestUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return userInitiated ? 'Could not check updates right now.' : null;
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return userInitiated ? 'Invalid update manifest format.' : null;
      }

      final latestVersion = (payload['version'] ?? '').toString().trim();
      final apkUrl = (payload['apkUrl'] ?? '').toString().trim();
      final notes = (payload['notes'] ?? '').toString().trim();
      if (latestVersion.isEmpty || apkUrl.isEmpty) {
        return userInitiated
            ? 'Update manifest is missing version or apkUrl.'
            : null;
      }

      if (!_isVersionNewer(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
      )) {
        return userInitiated
            ? 'You are already on the latest version ($currentVersion).'
            : null;
      }

      if (!userInitiated) {
        return 'Update available: v$latestVersion. Open "Check For Updates" to install.';
      }

      final url = Uri.parse(apkUrl);
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return 'Update found (v$latestVersion) but could not open download link.';
      }

      if (notes.isNotEmpty) {
        return 'Downloading update v$latestVersion. $notes';
      }
      return 'Downloading update v$latestVersion.';
    } catch (_) {
      return userInitiated
          ? 'Update check failed. Verify manifest URL and internet access.'
          : null;
    }
  }

  bool _isVersionNewer({
    required String currentVersion,
    required String latestVersion,
  }) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);
    final maxLen = current.length > latest.length
        ? current.length
        : latest.length;
    for (var i = 0; i < maxLen; i++) {
      final a = i < current.length ? current[i] : 0;
      final b = i < latest.length ? latest[i] : 0;
      if (b > a) {
        return true;
      }
      if (b < a) {
        return false;
      }
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }
}
