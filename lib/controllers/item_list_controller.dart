import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_controller.dart';
import '../repositories/custom_exception.dart';
import '../repositories/item_repository.dart';
import '../models/item_model.dart';


// チェックがついているものだけ絞り込む
enum ItemListFilter {
  all,
  obtained
}

final itemListFilterProvider = StateProvider<ItemListFilter>((_) => ItemListFilter.all);

final filteredItemListProvider = Provider<List<Item>>((ref) {
  final itemListFilterState = ref.watch(itemListFilterProvider).state;
  final itemListState = ref.watch(itemListControllerProvider);
  return itemListState.maybeWhen(
      data: (items) {
        switch (itemListFilterState) {
          case ItemListFilter.obtained: return items.where((item) => item.obtained).toList();
          default: return items;
        }
      },
    orElse: () => [],
  );
});


final itemListExceptionProvider = StateProvider<CustomException?>((_) => null);

final itemListControllerProvider = StateNotifierProvider<ItemListController, AsyncValue<List<Item>>>(
    (ref) {
      final user = ref.watch(authControllerProvider);
      return ItemListController(ref.read, user?.uid);
    }
);

// 非同期でラップ
class ItemListController extends StateNotifier<AsyncValue<List<Item>>> {
  final Reader _read;
  final String? _userId;

  // Readerとnull許可ユーザIDを受け取る
  ItemListController(this._read, this._userId) : super(const AsyncValue.loading()) {
    // ユーザIDがNULLでない場合、アイテムの取得をする
    if (_userId != null) {
      retrieveItems();
    }
  }

  // アイテムの取得
  Future<void> retrieveItems({bool isRefreshing = false}) async {
    if (isRefreshing) state = const AsyncValue.loading();
    try {
      final items = await _read(itemRepositoryProvider).retrieveItems(userId: _userId!);
      if (mounted) {
        state = AsyncValue.data(items);
      }
    } on CustomException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // アイテムの追加
  Future<void> addItem({required String name, bool obtained = false}) async {
    try {
      final item = Item(name: name, obtained: obtained);
      final itemId = await _read(itemRepositoryProvider).createItem(
          userId: _userId!,
          item: item,
      );
      state.whenData((items) => state = AsyncValue.data(items..add(item.copyWith(id: itemId))));
    } on CustomException catch (e) {
      _read(itemListExceptionProvider).state = e;
    }
  }
  
  // アイテムの更新
  Future<void> updateItem({required Item updatedItem}) async {
    try {
      await _read(itemRepositoryProvider).updateItem(userId: _userId!, item: updatedItem);
      state.whenData((items) {
        state = AsyncValue.data([
          for (final item in items)
            if (item.id == updatedItem.id) updatedItem else item
        ]);
      });
    } on CustomException catch (e) {
      _read(itemListExceptionProvider).state = e;
    }
  }
  
  // アイテムの削除
  Future<void> deleteItem({required String itemId}) async {
    try {
      await _read(itemRepositoryProvider).deleteItem(
          userId: _userId!,
          itemId: itemId,
      );
      state.whenData((items) => state = AsyncValue.data(items..removeWhere((item) => item.id == itemId)));
    } on CustomException catch (e) {
      _read(itemListExceptionProvider).state = e;
    }
  }
}