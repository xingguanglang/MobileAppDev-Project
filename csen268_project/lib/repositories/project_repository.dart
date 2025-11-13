import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final String _userId;
  late final CollectionReference _projectsCollection;

  ProjectRepository({required String userId}) : _userId = userId {
    _projectsCollection =
      FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('projects');
  }

  Future<String> createProjectAutoId(Project project) async {
    final docRef = _projectsCollection.doc();
    await docRef.set(project.toMap());
    return docRef.id;
  }

  Future<List<Project>> getAllProjects() async {
    final querySnapshot = await _projectsCollection.get();
    return querySnapshot.docs
        .map((doc) => Project.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
