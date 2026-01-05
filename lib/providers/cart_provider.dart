import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<Product> _cart = [];
  Map<String, int> _defaultPoints = {};

  List<Product> get cart => _cart;

  CartProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      final data = response as List<dynamic>;
      for (var item in data) {
        final key = item['key'] as String; // e.g., 'points_Camera IP Pro'
        final value = int.tryParse(item['value'] as String) ?? 0;
        final category = key.replaceFirst('points_', '');
        _defaultPoints[category] = value;
      }
    } catch (e) {
      debugPrint('CartProvider: Error loading settings: $e');
    }
  }

  void addToCart(Product product) {
    // Apply points logic: Product Specific > Category Default
    if (product.cartRewardPoints == null || product.cartRewardPoints == 0) {
        int points = 0;
        
        // Check Product Specific first
        if (product.rewardPoints > 0) {
          points = product.rewardPoints;
        } 
        // Fallback to Category Default
        else if (product.category != null && _defaultPoints.containsKey(product.category)) {
            points = _defaultPoints[product.category!]!;
        }
        product.cartRewardPoints = points;
    }
    _cart.add(product);
    notifyListeners();
  }
  
  void removeFromCart(Product product) {
    _cart.remove(product);
    notifyListeners();
  }

  int calculatePoints(Product product) {
    if (product.rewardPoints > 0) {
      return product.rewardPoints;
    } 
    if (product.category != null && _defaultPoints.containsKey(product.category)) {
      return _defaultPoints[product.category!]!;
    }
    return 0;
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
