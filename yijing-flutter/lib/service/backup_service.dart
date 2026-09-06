/// 数据备份文件通道 (iter41)
/// 抽象 FilePorter 便于单测; 真机实现 = path_provider + dart:io + file_picker + share_plus
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 备份文件读写/分享端口 (测试用 Fake 替换)
abstract class FilePorter {
  /// 写入备份文件, 返回绝对路径
  Future<String> writeBackup(String json, {required String fileName});

  /// 调用系统分享面板分享文件
  Future<void> shareFile(String path, {String? subject, String? text});

  /// 选取一个备份文件并返回其内容 (用户取消 → null)
  Future<String?> pickBackupText();
}

/// 真机实现
class DeviceFilePorter implements FilePorter {
  @override
  Future<String> writeBackup(String json, {required String fileName}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, flush: true);
    return file.path;
  }

  @override
  Future<void> shareFile(String path, {String? subject, String? text}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path)],
      subject: subject,
      text: text,
    ));
  }

  @override
  Future<String?> pickBackupText() async {
    final result = await FilePicker.pickFiles( // file_picker 11: 静态 API (无 .platform)
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
      withData: true, // 优先走 bytes (iOS/Android 沙箱无直读权限时更稳)
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes != null) {
      return String.fromCharCodes(bytes);
    }
    final path = f.path;
    if (path == null) return null;
    return File(path).readAsString();
  }
}

/// 备份服务 — 文件名生成 + 端口编排 (VM 只依赖本类)
class BackupService {
  BackupService({FilePorter? porter}) : _porter = porter ?? DeviceFilePorter();

  final FilePorter _porter;

  static const String prefix = 'yijing-backup';

  /// yijing-backup-20260906-2048.json
  String fileNameFor(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '$prefix-${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}.json';
  }

  /// 导出为本地文件, 返回路径
  Future<String> exportToFile(String json, {DateTime? now}) =>
      _porter.writeBackup(json, fileName: fileNameFor(now ?? DateTime.now()));

  /// 导出并调起系统分享 (可存入 Files/网盘/微信等)
  Future<String> shareBackup(String json, {DateTime? now}) async {
    final path = await exportToFile(json, now: now);
    await _porter.shareFile(path,
        subject: '易道 · 卦象数据备份', text: '易道备份文件 (含起卦记录与收藏)');
    return path;
  }

  /// 选取备份文件并返回文本 (取消 → null)
  Future<String?> pickBackupText() => _porter.pickBackupText();
}
