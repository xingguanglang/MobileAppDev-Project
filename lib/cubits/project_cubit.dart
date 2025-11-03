import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectCubit extends Cubit<List<String>> {
  ProjectCubit() : super([]);

  void loadProjects() {
    final mockProjects = ['Project A', 'Project B', 'Project C'];
    emit(mockProjects);
  }
}
