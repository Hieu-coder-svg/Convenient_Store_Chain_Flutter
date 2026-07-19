import 'package:flutter/foundation.dart';
import '../../product/models/product_model.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  int? _branchId;
  String _paymentMethod = 'Cash';
  int _redeemPoints = 0;

  List<CartItemModel> get items => _items;
  int? get branchId => _branchId;
  String get paymentMethod => _paymentMethod;
  int get redeemPoints => _redeemPoints;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get vatAmount => 0; // Backend handles VAT or calculate if needed
  double get discountFromPoints => _redeemPoints * 100.0;
  double get grandTotal =>
      subtotal - discountFromPoints > 0 ? subtotal - discountFromPoints : 0;

  int get totalItems => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  void setBranchId(int id) {
    _branchId = id;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setRedeemPoints(int points) {
    _redeemPoints = points;
    notifyListeners();
  }

  void addItem(ProductModel product) {
    final index = _items.indexWhere(
      (item) => item.productId == product.productId,
    );
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(
        CartItemModel(
          productId: product.productId,
          productName: product.productName,
          sellingPrice: product.sellingPrice,
          imageUrl: product.imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _redeemPoints = 0;
    _paymentMethod = 'Cash';
    notifyListeners();
  }

  Map<String, dynamic> toCheckoutPayload(int? customerId) {
    return {
      'branchId': _branchId,
      'customerId': customerId,
      'paymentMethod': _paymentMethod,
      'redeemPoints': _redeemPoints,
      'items': _items
          .map(
            (item) => {'productId': item.productId, 'quantity': item.quantity},
          )
          .toList(),
    };
  }
}
