import 'package:flutter/foundation.dart';

class BasketData extends ChangeNotifier {
  final List<Map<String, dynamic>> _basketItems = [];

  List<Map<String, dynamic>> get basketItems => _basketItems;

void addItem({
  required String mealId,
  required String cookId,
  required String name,
  required String cook,
  required String price,
  required String emoji,
  required bool deliveryAvailable,
  required bool collectionAvailable,
  required int portionsLeft,
  String? imageUrl,
  int quantity = 1,
}) {
  final int existingIndex = _basketItems.indexWhere(
    (item) => item['mealId'] == mealId,
  );

  final double priceValue =
      double.tryParse(
        price.replaceAll('£', '').trim(),
      ) ??
      0;

  if (existingIndex >= 0) {
    final int currentQuantity =
        _basketItems[existingIndex]['quantity']
            as int? ??
        1;

    final int newQuantity =
        currentQuantity + quantity;

    _basketItems[existingIndex]['quantity'] =
        newQuantity > portionsLeft
            ? portionsLeft
            : newQuantity;

    _basketItems[existingIndex]['portionsLeft'] =
        portionsLeft;
  } else {
    final int safeQuantity =
        quantity > portionsLeft
            ? portionsLeft
            : quantity;

    _basketItems.add({
      'mealId': mealId,
      'cookId': cookId,
      'name': name,
      'cook': cook,
      'price': price,
      'priceValue': priceValue,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'quantity': safeQuantity,
      'portionsLeft': portionsLeft,
      'deliveryAvailable': deliveryAvailable,
      'collectionAvailable': collectionAvailable,
    });
  }

  notifyListeners();
}
  void increaseQuantity(String mealName) {
    final int index = _basketItems.indexWhere(
      (item) => item['name'] == mealName,
    );

    if (index == -1) {
      return;
    }

    final int currentQuantity =
        _basketItems[index]['quantity'] as int? ?? 1;

    _basketItems[index]['quantity'] = currentQuantity + 1;

    notifyListeners();
  }

  void decreaseQuantity(String mealName) {
    final int index = _basketItems.indexWhere(
      (item) => item['name'] == mealName,
    );

    if (index == -1) {
      return;
    }

    final int currentQuantity =
        _basketItems[index]['quantity'] as int? ?? 1;

    if (currentQuantity <= 1) {
      _basketItems.removeAt(index);
    } else {
      _basketItems[index]['quantity'] = currentQuantity - 1;
    }

    notifyListeners();
  }

  void removeItem(String mealName) {
    _basketItems.removeWhere(
      (item) => item['name'] == mealName,
    );

    notifyListeners();
  }

  void clearBasket() {
    _basketItems.clear();
    notifyListeners();
  }
}

final BasketData basketData = BasketData();