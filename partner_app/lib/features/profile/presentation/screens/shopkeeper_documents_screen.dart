import 'package:flutter/material.dart';
import '../controllers/shopkeeper_profile_controller.dart';
import '../../../../core/services/media_document_picker_service.dart';

class ShopkeeperDocumentsScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperDocumentsScreen({super.key, this.controller});

  @override
  State<ShopkeeperDocumentsScreen> createState() => _ShopkeeperDocumentsScreenState();
}

class _ShopkeeperDocumentsScreenState extends State<ShopkeeperDocumentsScreen> {
  late final ShopkeeperProfileController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ShopkeeperProfileController();
      _internalController = true;
      _controller.loadShopkeeperProfile();
    }
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _showDocumentDetailsModal({
    required String title,
    required String docName,
    required String docNumber,
    required String status,
    required bool isOptional,
    bool isUploaded = true,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        docName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(isOptional: isOptional, status: status, isUploaded: isUploaded),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Identifier / Reference',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    docNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verification Authority',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ServiceHub Merchant Compliance & Verification Desk',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleDocumentUpload(title);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Update Document Copy',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDocumentUpload(String title) async {
    if (title == 'Shop Photo') {
      final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
        context,
        title: 'Upload Shop Photo',
        subtitle: 'Take a clear photo of your storefront signboard or premises',
      );
      if (picked != null) {
        _controller.addShopPhoto(picked.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Shop photo uploaded and submitted for verification!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    if (title == 'Owner ID Proof') {
      final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
        context,
        title: 'Upload Owner ID Proof',
        subtitle: 'Upload a clear copy of government issued photo ID (Aadhaar or PAN)',
      );
      if (picked != null && mounted) {
        _showConfirmDocumentDialog(
          title: 'Confirm Owner ID Proof',
          pickedFile: picked,
          firstLabel: 'Aadhaar Number (12 Digits)',
          firstInitialValue: _controller.aadhaarNumber,
          firstHint: 'e.g. 5432 9876 1234',
          secondLabel: 'PAN Card Number (10 Characters)',
          secondInitialValue: _controller.panNumber,
          secondHint: 'e.g. ABCDE1234F',
          onSave: (val1, val2) async {
            await _controller.updateDocument(
              aadhaar: val1,
              pan: val2.toUpperCase(),
              ownerIdPath: picked.path,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Owner ID proof updated and submitted for review!'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }
      return;
    }

    if (title == 'Shop Registration') {
      final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
        context,
        title: 'Upload Shop Registration',
        subtitle: 'Upload your municipality shop certificate or trade license',
      );
      if (picked != null && mounted) {
        _showConfirmDocumentDialog(
          title: 'Confirm Shop Registration',
          pickedFile: picked,
          firstLabel: 'Registration Number',
          firstInitialValue: _controller.shopRegistrationNo,
          firstHint: 'e.g. RJK/SHOP/2026/1587',
          secondLabel: 'Trade License Number (Optional)',
          secondInitialValue: _controller.shopLicenseNumber,
          secondHint: 'e.g. GJ-JAM-SHOP-2026-8921',
          onSave: (val1, val2) async {
            await _controller.updateDocument(
              shopReg: val1,
              shopLic: val2,
              registrationPath: picked.path,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Shop registration certificate submitted!'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }
      return;
    }

    if (title == 'GST Certificate') {
      final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
        context,
        title: 'Upload GST Certificate',
        subtitle: 'Upload your official GST registration certificate',
      );
      if (picked != null && mounted) {
        _showConfirmDocumentDialog(
          title: 'Confirm GST Certificate',
          pickedFile: picked,
          firstLabel: 'GSTIN Number',
          firstInitialValue: _controller.gstNumber,
          firstHint: 'e.g. 24ABCDE1234F1Z5',
          onSave: (val1, _) async {
            await _controller.updateDocument(
              gst: val1.toUpperCase(),
              gstPath: picked.path,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ GST Certificate submitted for verification!'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }
      return;
    }
  }

  void _showConfirmDocumentDialog({
    required String title,
    required PickedMediaFile pickedFile,
    required String firstLabel,
    required String firstInitialValue,
    required String firstHint,
    String? secondLabel,
    String? secondInitialValue,
    String? secondHint,
    required Future<void> Function(String val1, String val2) onSave,
  }) {
    final firstCtrl = TextEditingController(text: firstInitialValue);
    final secondCtrl = TextEditingController(text: secondInitialValue ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    // File Attached Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF16A34A), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedFile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(pickedFile.sizeInBytes / 1024).toStringAsFixed(1)} KB • Image Attached',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      firstLabel,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: firstCtrl,
                      decoration: InputDecoration(
                        hintText: firstHint,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter document identifier';
                        }
                        return null;
                      },
                    ),
                    if (secondLabel != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        secondLabel,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: secondCtrl,
                        decoration: InputDecoration(
                          hintText: secondHint,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);
                                try {
                                  await onSave(firstCtrl.text.trim(), secondCtrl.text.trim());
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } finally {
                                  if (ctx.mounted) setSheetState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Save & Submit Document',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openUploadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Document to Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload original photos or scanned copies for verification',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            _buildUploadOption(
              icon: Icons.storefront_outlined,
              title: 'Shop Photo',
              subtitle: 'Storefront or premises photo',
              onTap: () {
                Navigator.pop(ctx);
                _handleDocumentUpload('Shop Photo');
              },
            ),
            _buildUploadOption(
              icon: Icons.badge_outlined,
              title: 'Owner ID Proof',
              subtitle: 'Aadhaar Card or PAN Card',
              onTap: () {
                Navigator.pop(ctx);
                _handleDocumentUpload('Owner ID Proof');
              },
            ),
            _buildUploadOption(
              icon: Icons.verified_user_outlined,
              title: 'Shop Registration',
              subtitle: 'Trade License or Gumastadhara certificate',
              onTap: () {
                Navigator.pop(ctx);
                _handleDocumentUpload('Shop Registration');
              },
            ),
            _buildUploadOption(
              icon: Icons.receipt_long_outlined,
              title: 'GST Certificate (Optional)',
              subtitle: 'Official GSTIN registration certificate',
              onTap: () {
                Navigator.pop(ctx);
                _handleDocumentUpload('GST Certificate');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0F766E), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required bool isOptional,
    required String status,
    bool isUploaded = true,
  }) {
    if (isOptional && !isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'Optional',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    if (!isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 13),
            const SizedBox(width: 4),
            Text(
              status.isNotEmpty ? status : 'Pending Upload',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 13),
          const SizedBox(width: 4),
          Text(
            status.isNotEmpty ? status : 'Verified ✓',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isOptional,
    required bool isUploaded,
    required String status,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusPill(isOptional: isOptional, status: status, isUploaded: isUploaded),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);
    final hasPhotos = _controller.shopPhotos.isNotEmpty;
    final hasAadhaar = _controller.aadhaarNumber.trim().isNotEmpty;
    final hasPan = _controller.panNumber.trim().isNotEmpty;
    final hasOwnerId = hasAadhaar && hasPan;
    final isPartialOwnerId = hasAadhaar || hasPan;
    final hasRegistration = _controller.shopRegistrationNo.trim().isNotEmpty;
    final hasGst = _controller.gstNumber.trim().isNotEmpty;
    final isAllMandatoryVerified = hasPhotos && hasOwnerId && hasRegistration;

    String ownerIdSubtitle;
    if (hasOwnerId) {
      ownerIdSubtitle = 'Aadhaar: ${_controller.aadhaarNumber} • PAN: ${_controller.panNumber}';
    } else if (hasAadhaar) {
      ownerIdSubtitle = 'Aadhaar: ${_controller.aadhaarNumber} • PAN: Not Uploaded';
    } else if (hasPan) {
      ownerIdSubtitle = 'Aadhaar: Not Uploaded • PAN: ${_controller.panNumber}';
    } else {
      ownerIdSubtitle = 'Government ID proof not uploaded yet';
    }

    final String regSubtitle = hasRegistration
        ? 'Reg: ${_controller.shopRegistrationNo}${_controller.shopLicenseNumber.isNotEmpty ? " • Lic: ${_controller.shopLicenseNumber}" : ""}'
        : 'Trade license or Gumasta certificate not uploaded yet';

    final String gstSubtitle = hasGst
        ? 'GSTIN: ${_controller.gstNumber}'
        : 'Not provided (Optional for small businesses)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button, 'Documents & Verification', subtitle 'Upload and manage your documents'
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents & Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Upload and manage your documents',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Overview Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAllMandatoryVerified
                              ? [const Color(0xFFECFDF5), Colors.white]
                              : [const Color(0xFFFFFBEB), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAllMandatoryVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isAllMandatoryVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isAllMandatoryVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                              color: isAllMandatoryVerified ? emeraldColor : const Color(0xFFD97706),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAllMandatoryVerified ? 'Merchant KYC Verified' : 'Merchant KYC Pending',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isAllMandatoryVerified ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAllMandatoryVerified
                                      ? 'Your store documents meet ServiceHub compliance standards.'
                                      : 'Upload all required documents to complete store verification.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isAllMandatoryVerified ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'REQUIRED DOCUMENTS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Document Card 1: Shop Photo
                    _buildDocCard(
                      title: 'Shop Photo',
                      subtitle: hasPhotos
                          ? '${_controller.shopPhotos.length} Storefront & premises photos verified'
                          : 'Storefront or interior photos not uploaded yet',
                      icon: Icons.store_mall_directory_rounded,
                      iconColor: emeraldColor,
                      isOptional: false,
                      isUploaded: hasPhotos,
                      status: hasPhotos ? 'Verified ✓' : 'Pending Upload',
                      onTap: () {
                        _showDocumentDetailsModal(
                          title: 'Shop Photo',
                          docName: 'Storefront & Premises Imagery',
                          docNumber: hasPhotos ? 'Photos: ${_controller.shopPhotos.length} on record' : 'No photos uploaded',
                          status: hasPhotos ? 'Verified ✓' : 'Pending Upload',
                          isOptional: false,
                          isUploaded: hasPhotos,
                          description: 'Physical store verification photo showing storefront signboard and entrance, verified by local ServiceHub executive.',
                          icon: Icons.store_mall_directory_rounded,
                          color: emeraldColor,
                        );
                      },
                    ),

                    // Document Card 2: Owner ID Proof
                    _buildDocCard(
                      title: 'Owner ID Proof',
                      subtitle: ownerIdSubtitle,
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF2563EB),
                      isOptional: false,
                      isUploaded: hasOwnerId,
                      status: hasOwnerId ? 'Verified ✓' : 'Pending Upload',
                      onTap: () {
                        _showDocumentDetailsModal(
                          title: 'Owner ID Proof',
                          docName: 'Government Issued Identity (Aadhaar & PAN)',
                          docNumber: hasOwnerId
                              ? 'UID: ${_controller.aadhaarNumber}\nPAN: ${_controller.panNumber}'
                              : (isPartialOwnerId
                                  ? '${hasAadhaar ? "UID: ${_controller.aadhaarNumber}\n" : ""}PAN: ${hasPan ? _controller.panNumber : "Pending Upload"}'
                                  : 'Not Uploaded'),
                          status: hasOwnerId ? 'Verified ✓' : 'Pending Upload',
                          isOptional: false,
                          isUploaded: hasOwnerId,
                          description: 'Verified identification of registered merchant ${_controller.ownerName} authenticated via UIDAI and NSDL database.',
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF2563EB),
                        );
                      },
                    ),

                    // Document Card 3: Shop Registration
                    _buildDocCard(
                      title: 'Shop Registration',
                      subtitle: regSubtitle,
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFFD97706),
                      isOptional: false,
                      isUploaded: hasRegistration,
                      status: hasRegistration ? 'Verified ✓' : 'Pending Upload',
                      onTap: () {
                        _showDocumentDetailsModal(
                          title: 'Shop Registration',
                          docName: 'Shop & Establishment Certificate',
                          docNumber: hasRegistration
                              ? 'Reg: ${_controller.shopRegistrationNo}\nLic: ${_controller.shopLicenseNumber.isNotEmpty ? _controller.shopLicenseNumber : "N/A"}'
                              : 'Not Uploaded',
                          status: hasRegistration ? 'Verified ✓' : 'Pending Upload',
                          isOptional: false,
                          isUploaded: hasRegistration,
                          description: 'Official registration certificate issued by municipal corporation for legal trade operations in ${_controller.city}, ${_controller.state}.',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFD97706),
                        );
                      },
                    ),

                    // Document Card 4: GST Certificate
                    _buildDocCard(
                      title: 'GST Certificate',
                      subtitle: gstSubtitle,
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF9333EA),
                      isOptional: true,
                      isUploaded: hasGst,
                      status: hasGst ? 'Verified ✓' : 'Optional',
                      onTap: () {
                        _showDocumentDetailsModal(
                          title: 'GST Certificate',
                          docName: 'Goods and Services Tax Identification',
                          docNumber: hasGst ? _controller.gstNumber : 'None Registered (Exempt)',
                          status: hasGst ? 'Verified ✓' : 'Optional',
                          isOptional: true,
                          isUploaded: hasGst,
                          description: 'GST certificate is optional for merchants with annual turnover under statutory threshold limits. You can upload or update at any time.',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF9333EA),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Security callout: Lock icon: 'All documents are encrypted and secure with us.'
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_rounded, color: Color(0xFF475569), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All documents are encrypted and secure with us.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your identity proofs and business licenses are stored using AES-256 bank-grade encryption and only used for merchant compliance.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
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

            // 'Upload / Update' solid emerald button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => _openUploadSheet(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Upload / Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
