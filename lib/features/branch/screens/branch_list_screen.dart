import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/branch_provider.dart';
import '../models/branch_model.dart';
import '../widgets/add_edit_branch_dialog.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _filterActive; // null = Tất cả, true = Hoạt động, false = Tạm đóng

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<BranchProvider>().fetchBranches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditBranchDialog({BranchModel? branch}) {
    showDialog(
      context: context,
      builder: (context) => AddEditBranchDialog(branch: branch),
    );
  }

  void _confirmDeleteBranch(BranchModel branch) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa chi nhánh "${branch.branchName}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final provider = context.read<BranchProvider>();
                final success = await provider.removeBranch(branch.branchId);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa chi nhánh thành công'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Thao tác thất bại'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BranchProvider>();

    // Lọc chi nhánh theo tìm kiếm và bộ lọc trạng thái hoạt động
    final filteredBranches = provider.branches.where((br) {
      final matchesSearch =
          br.branchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          br.formattedCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (br.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesFilter =
          _filterActive == null || br.isActive == _filterActive;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chi nhánh cửa hàng',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: provider.isLoading && provider.branches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchBranches(),
              child: Column(
                children: [
                  // Sticky Search Bar Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    color: AppColors.background,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm chi nhánh...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.outline,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hoạt động', true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Tạm ngưng', false),
                      ],
                    ),
                  ),

                  // Branch List Area
                  Expanded(
                    child: filteredBranches.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    size: 64,
                                    color: AppColors.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không tìm thấy chi nhánh nào',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Thử lại với từ khóa khác hoặc thêm mới chi nhánh.'
                                        : 'Chưa có chi nhánh nào hoạt động trong hệ thống.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredBranches.length,
                            itemBuilder: (context, index) {
                              final branch = filteredBranches[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.storefront,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  branch.branchName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                if (branch.phone != null &&
                                                    branch
                                                        .phone!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.call,
                                                        size: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        branch.phone!,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (branch.address != null &&
                                                    branch
                                                        .address!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          branch.address!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _showAddEditBranchDialog(
                                                      branch: branch,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: AppColors.error,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _confirmDeleteBranch(
                                                      branch,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(
                                        height: 1,
                                        color: Colors.grey,
                                        thickness: 0.1,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: branch.isActive
                                                  ? Colors.green.shade50
                                                  : AppColors.error.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              branch.isActive
                                                  ? 'Đang hoạt động'
                                                  : 'Tạm ngưng',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: branch.isActive
                                                    ? Colors.green.shade800
                                                    : AppColors.error,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Mã: ${branch.formattedCode}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.outline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditBranchDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

    );
  }

  Widget _buildFilterChip(String label, bool? value) {
    final isSelected = _filterActive == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
      ),
      onSelected: (selected) {
        setState(() {
          _filterActive = value;
        });
      },
    );
  }


}
