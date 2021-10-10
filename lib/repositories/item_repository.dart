import 'package:campe_firebase/extensions/firebase_firestore_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'custom_exception.dart';
import '../general_providers.dart';
import '../models/item_model.dart';

abstract class BaseItemRepository {
  // アイテムのリストを返す
  Future<List<Item>> retrieveItems({required String userId});
  // アイテムを保存して、作成されたアイテムIDを返す
  Future<String> createItem({required String userId, required Item item});
  // アイテムを更新する
  Future<void> updateItem({required String userId, required Item item});
  // アイテムを削除する
  Future<void> deleteItem({required String userId, required String itemId});
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) => ItemRepository(ref.read));

class ItemRepository implements BaseItemRepository {
  final Reader _read;

  const ItemRepository(this._read);

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      // UserIdに紐づく、アイテムを取得
      final snap = await _read(firebaseFirestoreProvider)
          .userListRef(userId)
          .get();
      return snap.docs.map((doc) => Item.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<String> createItem({required String userId, required Item item}) async {
    try {
      // UserIdに紐付けてアイテムを登録
      final docRef = await _read(firebaseFirestoreProvider)
          .userListRef(userId)
          .add(item.toDocument());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
  @override
  Future<void> updateItem({required String userId, required Item item}) async {
    try {
      // UserId＞ItemIdに紐づくアイテムを更新
      await _read(firebaseFirestoreProvider)
          .userListRef(userId)
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> deleteItem({required String userId, required String itemId}) async {
    try {
      // UserId>ItemIdに紐づくアイテムを削除
      await _read(firebaseFirestoreProvider)
          .userListRef(userId)
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
}