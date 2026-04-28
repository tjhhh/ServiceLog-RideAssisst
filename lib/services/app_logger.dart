import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  // Singleton instance
  static final AppLogger instance = AppLogger._internal();
  AppLogger._internal();

  // In-memory logs queue
  final Queue<String> _logs = Queue<String>();
  final int _maxLogs = 500; // Limit memory usage
  File? _logFile;
  bool _initialized = false;

  // Initialize file
  Future<void> init() async {
    if (_initialized) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_logs.txt');

      // Load existing logs if needed (optional)
      // For now, we just start fresh or append
      _initialized = true;
      i('AppLogger initialized.');
    } catch (e) {
      debugPrint('Error initializing logger: $e');
    }
  }

  // Info log
  void i(String message) {
    _log('INFO', message);
  }

  // Error log
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(
      'ERROR',
      '$message ${error != null ? '\nError: $error' : ''} ${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}',
    );
  }

  // Warning log
  void w(String message) {
    _log('WARN', message);
  }

  void _log(String level, String message) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final formattedStr = '[$timeStr] [$level] $message';

    // Print to terminal for debug
    debugPrint(formattedStr);

    // Save to memory
    _logs.addLast(formattedStr);
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }

    // Save to file (async, so it doesn't block UI)
    _writeToFile(formattedStr);
  }

  Future<void> _writeToFile(String log) async {
    if (!_initialized || _logFile == null) return;
    try {
      await _logFile!.writeAsString(
        '$log\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  // Get all logs as single string for copying
  String getAllLogs() {
    return _logs.join('\n');
  }

  // Clear logs
  Future<void> clearLogs() async {
    _logs.clear();
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }
}
