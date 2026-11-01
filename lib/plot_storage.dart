import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class PlotStorage {
  static const String _key = 'area_calculator_saved_plots';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> save(Map<String, dynamic> record) async {
    final records = await getAll();

    final index = records.indexWhere(
      (e) => e['id'] == record['id'],
    );

    if (index >= 0) {
      records[index] = record;
    } else {
      records.insert(0, record);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records));
  }

  static Future<void> delete(String id) async {
    final records = await getAll();
    records.removeWhere((e) => e['id'] == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records));
  }

  static Future<void> backup() async {
    final records = await getAll();

    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'app': 'Area Calculator',
        'version': 1,
        'backupDate': DateTime.now().toIso8601String(),
        'plots': records,
      }),
    );

    await FilePicker.platform.saveFile(
      dialogTitle: 'Save Area Calculator Backup',
      fileName: 'Area_Calculator_Backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  static Future<void> restore({bool merge = true}) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Area Calculator Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;

    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      throw Exception('Backup file could not be read.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    final imported = (decoded['plots'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final prefs = await SharedPreferences.getInstance();

    if (!merge) {
      await prefs.setString(_key, jsonEncode(imported));
      return;
    }

    final existing = await getAll();

    for (final item in imported) {
      final index = existing.indexWhere(
        (e) => e['id'] == item['id'],
      );

      if (index >= 0) {
        existing[index] = item;
      } else {
        existing.add(item);
      }
    }

    await prefs.setString(_key, jsonEncode(existing));
  }
}
