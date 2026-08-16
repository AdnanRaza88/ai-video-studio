import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';

class ProjectService extends ChangeNotifier {
  final List<Project> _projects = [];
  final _uuid = const Uuid();

  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> loadProjects() async {
    // TODO: load from SQLite
    notifyListeners();
  }

  Future<Project> createProject(String name) async {
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    _projects.insert(0, project);
    // TODO: persist to SQLite + create project directory
    notifyListeners();
    return project;
  }

  Future<void> renameProject(String id, String newName) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _projects[index] = _projects[index].copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    // TODO: delete filesystem assets carefully
    notifyListeners();
  }
}
