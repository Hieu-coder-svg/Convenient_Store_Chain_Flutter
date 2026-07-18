import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../providers/product_catalog_provider.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/cloudinary_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final int? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  // Custom unit of measure controllers
  final TextEditingController _unitController = TextEditingController(
    text: 'Cái',
  );
  final TextEditingController _importUnitController = TextEditingController(
    text: 'Cái',
  );
  final TextEditingController _conversionFactorController =
      TextEditingController(text: '1');

  int? _selectedCategoryId;
  int? _selectedSupplierId;
  bool _isActive = true;
  bool _isLoadingSuppliers = false;
  List<Map<String, dynamic>> _suppliers = [];
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();

    // Nếu là chế độ edit, tải dữ liệu sản phẩm lên form
    if (widget.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductData();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _imageUrlController.dispose();
    _unitController.dispose();
    _importUnitController.dispose();
    _conversionFactorController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _isLoadingSuppliers = true);
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.dio.get('/suppliers');
      if (response.data is List) {
        setState(() {
          _suppliers = (response.data as List)
              .map(
                (item) => {
                  'id': item['supplierId'] as int,
                  'name': item['supplierName'] as String,
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Không thể tải nhà cung cấp: $e');
    } finally {
      setState(() => _isLoadingSuppliers = false);
    }
  }

  void _loadProductData() {
    final provider = context.read<ProductCatalogProvider>();
    final product = provider.products.firstWhere(
      (p) => p.productId == widget.productId,
      orElse: () => ProductModel(
        productId: 0,
        productName: '',
        categoryId: 0,
        categoryName: '',
        costPrice: 0,
        sellingPrice: 0,
        isActive: true,
        conversionFactor: 1,
      ),
    );

    if (product.productId != 0) {
      _nameController.text = product.productName;
      _barcodeController.text = product.barcode ?? '';
      _costPriceController.text = product.costPrice.toStringAsFixed(0);
      _sellingPriceController.text = product.sellingPrice.toStringAsFixed(0);
      _imageUrlController.text = product.imageUrl ?? '';
      _unitController.text = product.unit ?? 'Cái';
      _importUnitController.text = product.importUnit ?? 'Cái';
      _conversionFactorController.text = product.conversionFactor.toString();
      setState(() {
        _selectedCategoryId = product.categoryId;
        _selectedSupplierId = product.supplierId;
        _isActive = product.isActive;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imageFile == null) return;

      setState(() => _isUploadingImage = true);

      final String secureUrl = await CloudinaryService.uploadImage(
        imageFile.path,
      );

      setState(() {
        _imageUrlController.text = secureUrl;
        _isUploadingImage = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tải ảnh lên thành công!')));
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImagePickerSourceSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn từ Thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Chụp ảnh từ Máy ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final imageUrl = _imageUrlController.text.trim();
    final unit = _unitController.text.trim();
    final importUnit = _importUnitController.text.trim();
    final conversionFactor =
        int.tryParse(_conversionFactorController.text.trim()) ?? 1;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục.')));
      return;
    }

    if (sellingPrice < costPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giá bán lẻ không được nhỏ hơn giá nhập.'),
        ),
      );
      return;
    }

    if (conversionFactor < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hệ số quy đổi phải lớn hơn hoặc bằng 1.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ProductCatalogProvider>();

    // Tìm tên danh mục từ ID
    final catName = provider.categories
        .firstWhere(
          (c) => c.categoryId == _selectedCategoryId,
          orElse: () => CategoryModel(categoryId: 0, categoryName: ''),
        )
        .categoryName;

    final product = ProductModel(
      productId: widget.productId ?? 0,
      productName: name,
      categoryId: _selectedCategoryId!,
      categoryName: catName,
      supplierId: _selectedSupplierId,
      barcode: barcode.isEmpty ? null : barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      isActive: _isActive,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      unit: unit.isEmpty ? 'Cái' : unit,
      importUnit: importUnit.isEmpty ? 'Cái' : importUnit,
      conversionFactor: conversionFactor,
    );

    bool success;
    if (widget.productId == null) {
      success = await provider.addProduct(product);
    } else {
      success = await provider.editProduct(product);
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productId == null
                ? 'Đã thêm sản phẩm thành công'
                : 'Đã cập nhật sản phẩm thành công',
          ),
        ),
      );
      context.go('/products'); // Quay lại màn hình sản phẩm
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Thao tác thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductCatalogProvider>().categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            context.go('/products');
          },
        ),
        title: Text(
          widget.productId == null ? 'Thêm sản phẩm mới' : 'Chỉnh sửa sản phẩm',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BENTO 1: Image Uploader ---
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_imageUrlController.text.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrlController.text,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: AppColors.error,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageUrlController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _showImagePickerSourceSelection,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 48,
                                    color: AppColors.outline,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Chọn hình ảnh sản phẩm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tải trực tiếp lên Cloudinary (Max 5MB)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_isUploadingImage)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- BENTO 2: Basic Info ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên sản phẩm *',
                              hintText: 'Mì gói Hảo Hảo Tôm chua cay',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tên sản phẩm không được để trống';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Mã vạch / Barcode / SKU',
                              hintText: '8934567890123',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- BENTO 3: Categories & Suppliers ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Danh mục sản phẩm *',
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat.categoryId,
                                child: Text(cat.categoryName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedCategoryId = val);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Vui lòng chọn danh mục';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _isLoadingSuppliers
                              ? const SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  initialValue: _selectedSupplierId,
                                  decoration: const InputDecoration(
                                    labelText: 'Nhà cung cấp',
                                  ),
                                  items: _suppliers.map((sup) {
                                    return DropdownMenuItem<int>(
                                      value: sup['id'] as int,
                                      child: Text(sup['name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedSupplierId = val);
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- BENTO 4: Packaging & Unit of Measure ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quy cách đóng gói & Đơn vị',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Đơn vị bán lẻ *',
                                    hintText: 'Chai, lon, cái...',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Yêu cầu';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _importUnitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Đơn vị nhập sỉ *',
                                    hintText: 'Thùng, két, hộp...',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Yêu cầu';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _conversionFactorController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText:
                                  'Hệ số quy đổi (1 Đơn vị nhập = ? Đơn vị lẻ) *',
                              hintText: '24',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bắt buộc';
                              }
                              final val = int.tryParse(value);
                              if (val == null || val < 1) {
                                return 'Số nguyên >= 1';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Gợi ý: 1 ${_importUnitController.text.trim().isEmpty ? 'đơn vị sỉ' : _importUnitController.text.trim()} nhập kho sẽ được quy đổi thành ${_conversionFactorController.text.trim().isEmpty ? '?' : _conversionFactorController.text.trim()} ${_unitController.text.trim().isEmpty ? 'đơn vị lẻ' : _unitController.text.trim()} khi lưu kho.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- BENTO 5: Pricing & Status ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _costPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Giá nhập (Cost) *',
                                    hintText: 'VND',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Bắt buộc';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Số hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Giá bán (Selling) *',
                                    hintText: 'VND',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Bắt buộc';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Số hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kích hoạt kinh doanh (Active)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _isActive = val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hidden image url controller (keeps string sync)
                    Visibility(
                      visible: false,
                      child: TextFormField(controller: _imageUrlController),
                    ),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveProduct,
                        child: const Text(
                          'Lưu sản phẩm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
