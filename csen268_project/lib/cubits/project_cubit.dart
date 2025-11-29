import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/repositories/project_repository.dart';
import 'package:csen268_project/models/project_model.dart';

class ProjectCubit extends Cubit<List<Project>> {
  final ProjectRepository _repository;
  ProjectCubit(this._repository) : super([]);

  Future<void> loadProjects() async {
    try {
      final projects = await _repository.getAllProjects();
      emit(projects);
    } catch (e) {
      emit([]);
    }
  }

  Future<void> addProject(String name, String? imageUrl) async {
    try {
      final id = await _repository.createProjectAutoId(Project(id: '', name: name, imageUrl: imageUrl));
      final newProject = Project(id: id, name: name, imageUrl: imageUrl);
      emit([...state, newProject]);
    } catch (e) {
      // handle error
    }
  }

  // add a method to delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _repository.deleteProject(projectId);
      emit(state.where((p) => p.id != projectId).toList());
    } catch (e) {
      // handle error
    }
  }
}
