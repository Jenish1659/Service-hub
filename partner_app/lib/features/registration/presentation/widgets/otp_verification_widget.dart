import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/otp_service.dart';

class OtpVerificationWidget extends StatefulWidget {
  final String mobileNumber;
  final ValueChanged<bool> onVerificationChanged;

  const OtpVerificationWidget({
    super.key,
    required this.mobileNumber,
    required this.onVerificationChanged,
  });

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  final OtpService _otpService = OtpService();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _timerSeconds = 56;
  Timer? _timer;
  bool _isVerified = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendOtpAndStartTimer();
  }

  void _sendOtpAndStartTimer() {
    _startTimer();
    _otpService.sendOtp(widget.mobileNumber);
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 56;
      _errorMessage = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(int index, String val) {
    if (val.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    _checkAndVerify();
  }

  void _checkAndVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });

      final res = await _otpService.verifyOtpDetailed(widget.mobileNumber, code);
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isVerified = res.success;
          if (!res.success) {
            _errorMessage = res.message;
          }
        });
        widget.onVerificationChanged(_isVerified);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.shopkeeperGreenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.shopkeeperGreenBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.shopkeeperGreenPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mobile Number Verified Successfully',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.shopkeeperGreenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+91 ${widget.mobileNumber} is verified for registration',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Security Shield Vector Icon Box (Matching Image)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.providerBluePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.mark_email_read, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify your contact number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter the 6-digit code sent to +91 ${widget.mobileNumber.length >= 10 ? widget.mobileNumber.replaceRange(2, 7, 'XXXXX') : widget.mobileNumber}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6 Digit OTP Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                height: 46,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.providerBluePrimary, width: 2),
                    ),
                  ),
                  onChanged: (val) => _onDigitEntered(index, val),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          if (_isVerifying)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.providerBluePrimary)),
                  SizedBox(width: 8),
                  Text('Verifying OTP...', style: TextStyle(fontSize: 11, color: AppColors.providerBluePrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),

          // Resend OTP & Countdown Timer Row (Matching Reference Image)
          Row(
            children: [
              const Text(
                "Didn't receive OTP? ",
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              GestureDetector(
                onTap: _timerSeconds == 0 ? _sendOtpAndStartTimer : null,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _timerSeconds == 0 ? AppColors.providerBluePrimary : Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '00:${_timerSeconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.providerBluePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
