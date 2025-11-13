import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  Future<String> createUserAutoId(AppUser user) async {
    final docRef = _usersCollection.doc();
    await docRef.set(user.toMap());
    return docRef.id;
  }

  Future<AppUser?> getUser(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } else {
      return null;
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    final querySnapshot = await _usersCollection.get();
    return querySnapshot.docs
        .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<AppUser?> signIn(String username, String password) async {
    final querySnapshot = await _usersCollection
      .where('username', isEqualTo: username)
      .where('password', isEqualTo: password)
      .limit(1)
      .get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
