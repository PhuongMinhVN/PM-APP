import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../models/profile.dart';
import 'checkout_page.dart';
import 'add_product_page.dart';  
import 'product_detail_page.dart'; // Import detail page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  // Migrated to Provider
  // final List<Product> _cart = [];
  bool _isLoading = true;
  Profile? _profile;
  
  late TabController _tabController;
  final List<String> _categories = [
    'Tất cả',
    'Camera IP Pro',
    'Camera IP Home',
    'Smarthome',
    'Thiết bị mạng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchProfile();
    _fetchProducts();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _filterProducts();
  }

  void _filterProducts() {
    final selectedCategory = _categories[_tabController.index];
    setState(() {
      if (selectedCategory == 'Tất cả') {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((p) => p.category == selectedCategory).toList();
      }
    });
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        setState(() {
          _profile = Profile.fromJson(data);
        });
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _products = (data as List).map((e) => Product.fromJson(e)).toList();
        _filteredProducts = List.from(_products);
        _isLoading = false;
      });
      _filterProducts(); // Ensure filter applies if initial load happens
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  void _addToCart(Product product) {
    if (_profile?.isSales != true && _profile?.isAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không có quyền bán hàng')));
      return;
    }
    context.read<CartProvider>().addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${product.name} vào giỏ'), duration: const Duration(seconds: 1)),
    );
  }

  // Navigate to Detail Page
  Future<void> _openProductDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          onAddToCart: (cartProduct) => _addToCart(cartProduct), 
        ),
      ),
    );

    if (result == true) {
      _fetchProducts();
    }
  }

  void _goToCheckout() async {
    // Navigate to checkout. 
    // If it returns, it might mean success (handled inside Checkout to redirect) OR cancel.
    // Actually, CheckoutPage now pushes OrderSuccessPage.
    // But when OrderSuccessPage pops, it returns true if "Go Home" is clicked.
    // Wait, CheckoutPage uses pushReplacement. So duplicate logic isn't ideal.
    
    // Revised logic:
    // CheckoutPage -> Pushes Replacement OrderSuccessPage.
    // OrderSuccessPage -> Pops with 'true'.
    // That pop will go back to HomePage? No, CheckoutPage replaced itself.
    // So HomePage stays in stack. OrderSuccessPage is on top.
    // When OrderSuccessPage pops, it returns to HomePage.
    // So we just need to await the navigation result from the initial push.
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutPage(cart: context.read<CartProvider>().cart)),
    );
    
    // If we come back and it was successful (true), clear cart.
    if (result == true) {
      if (mounted) context.read<CartProvider>().clearCart();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa Hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
          labelColor: const Color(0xFF03DAC6), // Teal
          unselectedLabelColor: Colors.white54, // Readable on dark
          indicatorColor: const Color(0xFF03DAC6),
        ),
        actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/warranty');
              }, 
              icon: const Icon(Icons.search),
              tooltip: 'Tra cứu bảo hành',
            ),
            if (_profile?.isAdmin == true)
            IconButton(
              onPressed: () async {
                 await Navigator.pushNamed(context, '/add_product');
                 _fetchProducts();
              },
              icon: const Icon(Icons.add),
              tooltip: 'Thêm sản phẩm',
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: context.watch<CartProvider>().cart.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _goToCheckout,
        label: Text('Giỏ hàng (${context.watch<CartProvider>().cart.length})'),
        icon: const Icon(Icons.shopping_cart_checkout),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? const Center(child: Text('Chưa có sản phẩm trong danh mục này.'))
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return Card(
                      // Card picks up cardColor from Theme (0xFF1E1E1E)
                      clipBehavior: Clip.antiAlias,
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _openProductDetail(product),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50)),
                                    )
                                  : Container(
                                      color: Colors.grey.shade800, // Darker placeholder
                                      child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white, // Ensure white text
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Gap(4),
                                  Text(
                                    _formatCurrency(product.price),
                                    style: const TextStyle(
                                      color: Color(0xFFCF6679), // Muted red for Dark Mode (Material Design recommendation)
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (product.category != null)
                                    Text(
                                      product.category!,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF03DAC6)), // Teal
                                    ),
                                  const Gap(2),
                                  Text(
                                    'BH: ${product.warrantyPeriodMonths} tháng',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }



  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_profile?.fullName ?? 'Người dùng'),
            accountEmail: Text((_profile?.role ?? '...').toUpperCase()),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade800,
                backgroundImage: _profile?.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                child: _profile?.avatarUrl == null
                  ? Text(
                      (_profile?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24.0),
                    )
                  : null,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Hồ Sơ Cá Nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang Chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Tra Cứu Bảo Hành'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/warranty');
            },
          ),
          if (_profile?.isAdmin == true)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Quản Lý Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),
          if (_profile?.isAdmin == true)
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Thống Kê Doanh Số'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sales_stats');
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Liên Hệ / Giới Thiệu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contact');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng Xuất'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
