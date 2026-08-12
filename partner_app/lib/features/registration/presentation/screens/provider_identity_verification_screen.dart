import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';

class ProviderIdentityVerificationScreen extends StatefulWidget {
  const ProviderIdentityVerificationScreen({super.key});

  @override
  State<ProviderIdentityVerificationScreen> createState() =>
      _ProviderIdentityVerificationScreenState();
}

class _ProviderIdentityVerificationScreenState
    extends State<ProviderIdentityVerificationScreen> {
  // Section 1: Profile Photo
  bool _profilePhotoUploaded = false;

  // Section 2: Aadhaar Card
  bool _aadhaarFrontUploaded = false;
  bool _aadhaarBackUploaded = false;
  String? _extractedAadhaarNumber;

  // Section 3: Aadhaar Face Verification
  bool _isFaceRDInstalled = true;
  bool _isFaceVerified = false;

  // Section 4: Driving License & Vehicle Docs
  bool _dlFrontUploaded = false;
  bool _dlBackUploaded = false;
  bool _numberPlateUploaded = false;
  bool _rcBookUploaded = false;

  // Section 5: Experience Certificate
  bool _experienceCertUploaded = false;
  bool _experienceCertSkipped = false;

  // Section 6: Shop License
  bool _shopLicenseUploaded = false;
  bool _shopLicenseSkipped = false;

  // Section 7: Declaration
  bool _declarationGenuine = false;
  bool _declarationTerms = false;

  void _simulateDocumentAudit({
    required String docTitle,
    required VoidCallback onSuccess,
    String? extractedData,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Security Verification',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyzing $docTitle for authenticity...',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFF2563EB), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Checking Real vs AI-Generated / Tampered Document...',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  LinearProgressIndicator(color: Color(0xFF2563EB), backgroundColor: Color(0xFFDBEAFE)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          onSuccess();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    extractedData != null
                        ? '$docTitle Verified! Extracted ID: $extractedData'
                        : '$docTitle Verified! Document is Authentic & Original.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _startFaceRDVerification() {
    if (!_isFaceRDInstalled) {
      _showFaceRDMissingDialog();
      return;
    }

    if (!_aadhaarFrontUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Aadhaar Card Front Side first before face verification.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Aadhaar FaceRD Live Scan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Position your face inside the circle frame.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFF2563EB), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.face_rounded, size: 90, color: Color(0xFF2563EB)),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Aadhaar FaceRD Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showFaceMismatchPopup();
                        },
                        child: const Text('Simulate Mismatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isFaceVerified = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Aadhaar Face Verification Successful (99.2% Match Score)!'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Verify Face Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFaceMismatchPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text('Face Match Failed!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your live selfie does NOT match the photo on your uploaded Aadhaar card.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              '• Ensure your face is clearly visible with good lighting.\n'
              '• Remove glasses, masks, or caps.\n'
              '• Make sure you uploaded your own valid Aadhaar card.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  void _showFaceRDMissingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 8),
            Expanded(child: Text('Aadhaar FaceRD Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: const Text(
          'Aadhaar FaceRD Service App is mandatory on your device for UIDAI face authentication. Please install it from Google Play Store or App Store.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isFaceRDInstalled = true;
              });
            },
            child: const Text('Simulate App Installed', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (!_profilePhotoUploaded) {
      _showErrorSnackBar('Please upload your Profile Photo.');
      return;
    }
    if (!_aadhaarFrontUploaded || !_aadhaarBackUploaded) {
      _showErrorSnackBar('Please upload both Front and Back sides of your Aadhaar Card.');
      return;
    }
    if (!_isFaceVerified) {
      _showErrorSnackBar('Aadhaar Face Verification is mandatory. Please complete face scanning.');
      return;
    }
    if (!_dlFrontUploaded || !_dlBackUploaded) {
      _showErrorSnackBar('Please upload your Driving License details.');
      return;
    }
    if (!_declarationGenuine || !_declarationTerms) {
      _showErrorSnackBar('Please check both declaration boxes to confirm document authenticity.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Identity & Documents Successfully Verified! Application Submitted.'),
        backgroundColor: AppColors.shopkeeperGreenPrimary,
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryNavy, size: 14),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/register/service-category');
            }
          },
        ),
        title: const ShLogoWidget(size: 26, showSubtitle: false),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Need Help?',
            icon: const Icon(Icons.help_outline_rounded, size: 20, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support line: support@servicehub.com'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Banner
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verify Your Identity',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.shield_outlined, color: primaryColor, size: 14),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Your information is safe and secure with us.',
                                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Why Verification Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, color: primaryColor, size: 16),
                                  SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Why Verification?', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryColor)),
                                      Text('Build customer trust', style: TextStyle(fontSize: 9.5, color: Color(0xFF475569))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Profile Photo
                        _buildSectionContainer(
                          stepNum: '1',
                          title: 'Profile Photo',
                          isMandatory: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Clear photo, no sunglasses.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              const Text('JPG / PNG – Max 5 MB', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 10),
                              _buildUploadDropzone(
                                isUploaded: _profilePhotoUploaded,
                                title: _profilePhotoUploaded ? 'Photo Uploaded' : 'Upload Profile Photo',
                                subtitle: 'Tap to upload picture',
                                icon: Icons.camera_alt_outlined,
                                onTap: () {
                                  _simulateDocumentAudit(
                                    docTitle: 'Profile Photo',
                                    onSuccess: () => setState(() => _profilePhotoUploaded = true),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 2: Aadhaar Card
                        _buildSectionContainer(
                          stepNum: '2',
                          title: 'Aadhaar Card',
                          isMandatory: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Front Side', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                        const SizedBox(height: 6),
                                        _buildUploadDropzone(
                                          isUploaded: _aadhaarFrontUploaded,
                                          title: 'Upload Front',
                                          subtitle: 'JPG / PNG (5 MB)',
                                          icon: Icons.cloud_upload_outlined,
                                          onTap: () {
                                            _simulateDocumentAudit(
                                              docTitle: 'Aadhaar Card Front',
                                              extractedData: '9876-5432-1098',
                                              onSuccess: () {
                                                setState(() {
                                                  _aadhaarFrontUploaded = true;
                                                  _extractedAadhaarNumber = '9876-5432-1098';
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Back Side', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                        const SizedBox(height: 6),
                                        _buildUploadDropzone(
                                          isUploaded: _aadhaarBackUploaded,
                                          title: 'Upload Back',
                                          subtitle: 'JPG / PNG (5 MB)',
                                          icon: Icons.cloud_upload_outlined,
                                          onTap: () {
                                            _simulateDocumentAudit(
                                              docTitle: 'Aadhaar Card Back',
                                              onSuccess: () {
                                                setState(() {
                                                  _aadhaarBackUploaded = true;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_aadhaarFrontUploaded || _aadhaarBackUploaded) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _extractedAadhaarNumber != null
                                              ? 'Aadhaar Verified (ID: $_extractedAadhaarNumber - Authentic)'
                                              : 'Aadhaar Uploaded Successfully',
                                          style: const TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 3: Aadhaar Face Verification (Adaptive Layout)
                        _buildSectionContainer(
                          stepNum: '3',
                          title: 'Aadhaar Face Verification',
                          isMandatory: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Face Icon Graphic
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.face_retouching_natural_rounded, size: 38, color: primaryColor),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isFaceVerified ? '✓ Verified' : 'FaceRD',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: _isFaceVerified ? const Color(0xFF10B981) : primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Guidelines
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Verify your face using Aadhaar',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text('Well-lit environment', style: TextStyle(fontSize: 11, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text('Remove glasses/cap', style: TextStyle(fontSize: 11, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text('Look into camera', style: TextStyle(fontSize: 11, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Start Scan Full Width Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFaceVerified ? const Color(0xFF10B981) : primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _startFaceRDVerification,
                                  icon: Icon(_isFaceVerified ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                                  label: Text(
                                    _isFaceVerified ? 'Aadhaar Face Verified' : 'Start Face Verification',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 4: Driving License (All Providers)
                        _buildSectionContainer(
                          stepNum: '4',
                          title: 'Driving License (All Providers)',
                          isMandatory: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Car Service Providers: Car Driving License\nOther Services: Regular Driving License',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                              ),
                              const SizedBox(height: 12),

                              // Mini Upload Boxes
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildMiniUploadBox(
                                    title: 'DL Front Side',
                                    isUploaded: _dlFrontUploaded,
                                    onTap: () {
                                      _simulateDocumentAudit(
                                        docTitle: 'Driving License Front',
                                        onSuccess: () => setState(() => _dlFrontUploaded = true),
                                      );
                                    },
                                  ),
                                  _buildMiniUploadBox(
                                    title: 'DL Back Side',
                                    isUploaded: _dlBackUploaded,
                                    onTap: () {
                                      _simulateDocumentAudit(
                                        docTitle: 'Driving License Back',
                                        onSuccess: () => setState(() => _dlBackUploaded = true),
                                      );
                                    },
                                  ),
                                  _buildMiniUploadBox(
                                    title: 'Number Plate',
                                    isUploaded: _numberPlateUploaded,
                                    onTap: () {
                                      _simulateDocumentAudit(
                                        docTitle: 'Vehicle Number Plate',
                                        onSuccess: () => setState(() => _numberPlateUploaded = true),
                                      );
                                    },
                                  ),
                                  _buildMiniUploadBox(
                                    title: 'RC Book Document',
                                    isUploaded: _rcBookUploaded,
                                    onTap: () {
                                      _simulateDocumentAudit(
                                        docTitle: 'RC Book Document',
                                        onSuccess: () => setState(() => _rcBookUploaded = true),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: primaryColor, size: 14),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text('Mandatory for all service providers.', style: TextStyle(color: primaryColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 5: Experience Certificate (Optional)
                        _buildSectionContainer(
                          stepNum: '5',
                          title: 'Experience Certificate (Optional)',
                          isMandatory: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Upload your experience certificate to build more customer trust.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildUploadDropzone(
                                      isUploaded: _experienceCertUploaded,
                                      title: _experienceCertUploaded ? 'Uploaded' : 'Upload Cert',
                                      subtitle: 'PDF / JPG (10 MB)',
                                      icon: Icons.workspace_premium_outlined,
                                      onTap: () {
                                        _simulateDocumentAudit(
                                          docTitle: 'Experience Certificate',
                                          onSuccess: () => setState(() {
                                            _experienceCertUploaded = true;
                                            _experienceCertSkipped = false;
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _experienceCertSkipped = !_experienceCertSkipped;
                                      });
                                    },
                                    child: Text(_experienceCertSkipped ? 'Skipped' : 'Skip', style: TextStyle(color: _experienceCertSkipped ? const Color(0xFF64748B) : primaryColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 6: Shop License (If Applicable)
                        _buildSectionContainer(
                          stepNum: '6',
                          title: 'Shop License (If Applicable)',
                          isMandatory: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Required for shops & commercial establishments.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildUploadDropzone(
                                      isUploaded: _shopLicenseUploaded,
                                      title: _shopLicenseUploaded ? 'Uploaded' : 'Upload License',
                                      subtitle: 'PDF / JPG (10 MB)',
                                      icon: Icons.storefront_outlined,
                                      onTap: () {
                                        _simulateDocumentAudit(
                                          docTitle: 'Shop License',
                                          onSuccess: () => setState(() {
                                            _shopLicenseUploaded = true;
                                            _shopLicenseSkipped = false;
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _shopLicenseSkipped = !_shopLicenseSkipped;
                                      });
                                    },
                                    child: Text(_shopLicenseSkipped ? 'Skipped' : 'Skip', style: TextStyle(color: _shopLicenseSkipped ? const Color(0xFF64748B) : primaryColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 7: Declaration
                        _buildSectionContainer(
                          stepNum: '7',
                          title: 'Declaration',
                          isMandatory: true,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _declarationGenuine = !_declarationGenuine),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _declarationGenuine,
                                      activeColor: primaryColor,
                                      onChanged: (val) => setState(() => _declarationGenuine = val ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I confirm all uploaded documents are genuine and belong to me.',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _declarationTerms = !_declarationTerms),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _declarationTerms,
                                      activeColor: primaryColor,
                                      onChanged: (val) => setState(() => _declarationTerms = val ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I agree to ServiceHub\'s Terms & Conditions and Privacy Policy.',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sticky Bottom Continue Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _handleContinue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String stepNum,
    required String title,
    required bool isMandatory,
    required Widget child,
  }) {
    const primaryColor = Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(stepNum, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMandatory) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Mandatory', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadDropzone({
    required bool isUploaded,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF2563EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            width: isUploaded ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? const Color(0xFF10B981) : primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isUploaded ? const Color(0xFF065F46) : primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isUploaded ? const Color(0xFF047857) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniUploadBox({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF2563EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Icon(isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined, size: 18, color: isUploaded ? const Color(0xFF10B981) : primaryColor),
            const SizedBox(height: 2),
            Text(
              isUploaded ? 'Uploaded' : 'Upload',
              style: TextStyle(fontSize: 9.5, color: isUploaded ? const Color(0xFF065F46) : primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
