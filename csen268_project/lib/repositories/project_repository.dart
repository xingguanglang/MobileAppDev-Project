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

  /// create project and save the unique id field in the data
  Future<String> createProjectAutoId(Project project) async {
    // first generate a document reference to get the unique ID
    final docRef = _projectsCollection.doc();
    final projectWithId = Project(
      id: docRef.id,
      name: project.name,
      imageUrl: project.imageUrl,
    );
    // save the project data with the id field to Firestore
    await docRef.set(projectWithId.toMap());
    return docRef.id;
  }

  Future<List<Project>> getAllProjects() async {
    final querySnapshot = await _projectsCollection.get();
    return querySnapshot.docs
        .map((doc) => Project.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// delete the specified project
  Future<void> deleteProject(String projectId) async {
    await _projectsCollection.doc(projectId).delete();
  }
}
