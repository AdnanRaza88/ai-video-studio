import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/character.dart';

/// Stores user character reference images locally.
/// These images are attached to every scene generation request.
class CharacterService extends ChangeNotifier {
  final List<Character> characters = <Character>[];
  final Set<String> selectedIds = <String>{};
  String? error;

  List<Character> get selected =>
      characters.where((c) => selectedIds.contains(c.id)).toList();

  Future<void> load() async {
    error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('characters_v1');
      characters.clear();
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          characters.add(Character.fromJson(e as Map<String, dynamic>));
        }
      }
      final sel = prefs.getStringList('selected_characters_v1') ?? <String>[];
      selectedIds
        ..clear()
        ..addAll(sel.where((id) => characters.any((c) => c.id == id)));
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'characters_v1',
      jsonEncode(characters.map((c) => c.toJson()).toList()),
    );
    await prefs.setStringList('selected_characters_v1', selectedIds.toList());
  }

  Future<Character?> addFromFile({
    required String sourcePath,
    required String name,
    String description = '',
  }) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final charDir = Directory(p.join(dir.path, 'characters'));
      await charDir.create(recursive: true);

      final id = const Uuid().v4();
      final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final dest = File(p.join(charDir.path, '$id$ext'));
      await File(sourcePath).copy(dest.path);

      final c = Character(
        id: id,
        name: name.trim().isEmpty ? 'Character' : name.trim(),
        imagePath: dest.path,
        description: description,
      );
      characters.add(c);
      selectedIds.add(id);
      await _persist();
      notifyListeners();
      return c;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> remove(String id) async {
    characters.removeWhere((c) => c.id == id);
    selectedIds.remove(id);
    try {
      // best-effort delete file
      final match = characters.where((c) => c.id == id);
      // already removed from list; skip file if gone
    } catch (_) {}
    await _persist();
    notifyListeners();
  }

  void toggleSelected(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    _persist();
    notifyListeners();
  }

  /// Payload for the agent: every selected character image goes to the model each scene.
  List<Map<String, String>> selectedPayload() {
    return selected
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'image_path': c.imagePath,
            'description': c.description,
          },
        )
        .toList();
  }
}
