import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping, color: AppColors.secondaryGold, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ServiceHub Delivery Agent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Log in to access your delivery agent portal & earnings dashboard',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Mobile Phone Number',
                hint: 'Enter 10-digit registered number',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Send OTP Authentication',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
