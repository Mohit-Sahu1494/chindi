import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_version_model.dart';
import '../../features/auth/auth_provider.dart';
import '../widgets/update_dialog.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppUpdateService(apiClient);
});

final appVersionCheckProvider = FutureProvider.autoDispose<AppVersionModel?>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return await service.checkForUpdate();
});

class AppUpdateService {
  final ApiClient _apiClient;
  static bool _dialogShowing = false;

  AppUpdateService(this._apiClient);

  Future<AppVersionModel?> checkForUpdate() async {
    try {
      final res = await _apiClient.get('/version');
      if (res is Map<String, dynamic>) {
        final versionInfo = AppVersionModel.fromJson(res);
        return versionInfo;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking app version: $e');
    }
    return null;
  }

  /// Automatically displays the update popup if an update is available
  Future<void> checkAndShowUpdatePopup(BuildContext context) async {
    if (_dialogShowing) return;

    final versionInfo = await checkForUpdate();
    if (versionInfo != null && versionInfo.isUpdateAvailable && context.mounted) {
      _dialogShowing = true;
      try {
        await showDialog(
          context: context,
          barrierDismissible: !versionInfo.isMandatory,
          builder: (ctx) => UpdateDialog(
            versionInfo: versionInfo,
            onUpdate: () => openUpdateUrl(versionInfo.updateUrl),
          ),
        );
      } finally {
        _dialogShowing = false;
      }
    }
  }

  static Future<bool> openUpdateUrl(String url) async {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error opening update URL: $e');
    }
    return false;
  }
}
