import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/atmospheric_background.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isLoading = false;

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500)); // Simulate API call
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _showSuccessModal();
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF008939), // tertiary-container from HTML
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Yêu cầu đã gửi',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chúng tôi đã gửi hướng dẫn khôi phục mật khẩu vào thông tin bạn cung cấp. Vui lòng kiểm tra hộp thư.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  context.pop(); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Quay lại Đăng nhập', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: AtmosphericBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 32),
                      ),
                      Text(
                        'Quên mật khẩu',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập email hoặc số điện thoại đã đăng ký để khôi phục mật khẩu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Form Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const CustomTextField(
                        labelText: 'Email hoặc Số điện thoại',
                        hintText: 'name@store.com hoặc 09x...',
                        prefixIcon: Icons.alternate_email,
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Gửi yêu cầu khôi phục', style: TextStyle(color: Colors.white, fontSize: 16)),
                                    SizedBox(width: 8),
                                    Icon(Icons.send, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Visual Support & Links
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 128,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD85qlaMM53v0G2Qf79VK8mxXCUgm06EjMH_yiXTtnedDjMWULZTXYf-1NflmhTS_nplgDvk65SB6AKfaK9GDBEXYEIlzUfv4GuMHJhR5aUg0Y7ycJCThDSnkoILW8SVTS3NAHtxQAtiBiCcJjQAag36R544MOt9YDB-UL_1lUz__jr2NHMmdqEeezuuiz6y_sjCVS750Qc0ExuxwExl2QvruWZjjF98sWCXRdmhYa8MEFoRCpRKULgnhi6Th310EldVco2XFvaitE'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 128,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined, color: AppColors.onSecondaryFixed, size: 32),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Bảo mật đa lớp cho Store Manager',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSecondaryFixed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Bạn cần hỗ trợ thêm? Liên hệ quản trị viên',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
