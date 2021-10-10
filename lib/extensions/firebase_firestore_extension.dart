import 'package:cloud_firestore/cloud_firestore.dart';

// ユーザIDを引数にして、CollectionReferenceを返却
extension FirebaseFirestoreX on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> userListRef(String userId) =>
      collection('lists').doc(userId).collection('userList');
}