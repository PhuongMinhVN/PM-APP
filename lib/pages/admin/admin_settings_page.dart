import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import '../../models/product.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cấu Hình Điểm Thưởng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Theo Danh Mục'),
              Tab(text: 'Theo Sản Phẩm'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryConfigTab(),
            _ProductConfigTab(),
          ],
        ),
      ),
    );
  }
}

// ================== CATEGORY CONFIG TAB ==================
class _CategoryConfigTab extends StatefulWidget {
  const _CategoryConfigTab();

  @override
  State<_CategoryConfigTab> createState() => _CategoryConfigTabState();
}

class _CategoryConfigTabState extends State<_CategoryConfigTab> {
  final Map<String, TextEditingController> _controllers = {
    'points_Camera IP Pro': TextEditingController(),
    'points_Camera IP Home': TextEditingController(),
    'points_Smarthome': TextEditingController(),
    'points_Thiết bị mạng': TextEditingController(),
    'points_Dịch vụ': TextEditingController(),
    'points_Khác': TextEditingController(),
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      
      final data = response as List<dynamic>;
      for (var item in data) {
        final key = item['key'] as String;
        final value = item['value'] as String;
        if (_controllers.containsKey(key)) {
          _controllers[key]!.text = value;
        }
      }
      
      // Set defaults if empty
      _controllers.forEach((key, controller) {
        if (controller.text.isEmpty) controller.text = '0';
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải cài đặt: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      for (var entry in _controllers.entries) {
        await Supabase.instance.client
            .from('app_settings')
            .upsert({'key': entry.key, 'value': entry.value.text.trim()});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình danh mục.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            const Card(
              color: Color(0xFFE0F2F1),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Cài đặt điểm mặc định chung cho từng loại sản phẩm. Nếu một sản phẩm KHÔNG có cấu hình riêng, hệ thống sẽ dùng điểm ở đây.',
                  style: TextStyle(color: Color(0xFF00695C), fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const Gap(24),
            ..._controllers.entries.map((entry) {
              final categoryName = entry.key.replaceAll('points_', '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Điểm cho $categoryName',
                    suffixText: 'điểm',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Lưu Thay Đổi (Danh Mục)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ================== PRODUCT CONFIG TAB ==================
class _ProductConfigTab extends StatefulWidget {
  const _ProductConfigTab();

  @override
  State<_ProductConfigTab> createState() => _ProductConfigTabState();
}

class _ProductConfigTabState extends State<_ProductConfigTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = false;
  Timer? _debounce;

  // Track edits
  final Map<String, int> _unsavedChanges = {};

  @override
  void initState() {
    super.initState();
    _searchProducts(); // Load initial products
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      var dbQuery = Supabase.instance.client
          .from('products')
          .select();

      if (query.isNotEmpty) {
        dbQuery = dbQuery.ilike('name', '%$query%');
      }

      final data = await dbQuery
          .order('name', ascending: true)
          .limit(20);
      setState(() {
        _products = (data as List).map((e) => Product.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error searching products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProductPoints(Product product, int newPoints) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'reward_points': newPoints})
          .eq('id', product.id);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật điểm cho "${product.name}"')));
      
      // Update local list to reflect saved state
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
         // Create a temporary clone with updated points just for display consistency 
         //(Actual reload would need another fetch but this is faster for UX)
        // Note: Product is immutable, but we can't easily replace it in list without refetching or creating a new object
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Tìm kiếm sản phẩm...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (_isLoading)
          const LinearProgressIndicator(),
        
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final product = _products[index];
              return _ProductPointEditor(product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _ProductPointEditor extends StatefulWidget {
  final Product product;
  const _ProductPointEditor({required this.product});

  @override
  State<_ProductPointEditor> createState() => _ProductPointEditorState();
}

class _ProductPointEditorState extends State<_ProductPointEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.product.rewardPoints.toString());
  }

  @override
  void didUpdateWidget(covariant _ProductPointEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
        _ctrl.text = widget.product.rewardPoints.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          image: widget.product.imageUrl != null 
              ? DecorationImage(image: NetworkImage(widget.product.imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: widget.product.imageUrl == null ? const Icon(Icons.image, size: 30, color: Colors.grey) : null,
      ),
      title: Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${widget.product.category ?? "---"}'),
      trailing: SizedBox(
        width: 140,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                   suffixText: 'điểm',
                   isDense: true,
                   contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                   border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                 final val = int.tryParse(_ctrl.text.trim()) ?? 0;
                 if (val < 0) return;
                 
                 try {
                    await Supabase.instance.client
                        .from('products')
                        .update({'reward_points': val})
                        .eq('id', widget.product.id);
                        
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu!')));
                 } catch (e) {
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                 }
              },
              icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            )
          ],
        ),
      ),
    );
  }
}
