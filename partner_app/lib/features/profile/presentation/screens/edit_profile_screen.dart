import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileController controller;

  const EditProfileScreen({
    super.key,
    required this.controller,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _bizNameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late String _selectedExperience;

  bool _isSaving = false;

  final List<String> _experienceOptions = [
    '0 Years',
    '1+ Years',
    '2+ Years',
    '3+ Years',
    '5+ Years',
    '10+ Years',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _nameController = TextEditingController(text: c.partnerName);
    _phoneController = TextEditingController(text: c.phoneNumber);
    _emailController = TextEditingController(text: c.emailAddress);
    _dobController = TextEditingController(text: c.dateOfBirth);
    _bizNameController = TextEditingController(text: c.businessName);
    _bioController = TextEditingController(text: c.shortBio);
    _cityController = TextEditingController(text: c.serviceCity);

    _selectedExperience = _experienceOptions.contains(c.experienceYears)
        ? c.experienceYears
        : '3+ Years';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _bizNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.controller.pickPhoto(ImageSource.camera).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.controller.pickPhoto(ImageSource.gallery).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      TopToast.show(context, 'Full Name is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final success = await widget.controller.saveProfileDetails(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      dob: _dobController.text,
      bizName: _bizNameController.text,
      exp: _selectedExperience,
      bio: _bioController.text,
      city: _cityController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      TopToast.show(context, '? Profile updated successfully!', isError: false);
      Navigator.pop(context);
    } else {
      TopToast.show(context, 'Failed to save updates', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Keep your information up to date',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content with Zero-Overflow Guarantee
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header Preview
                    Center(
                      child: Column(
                        children: [
                          ProfileAvatarWidget(
                            photoPath: c.profilePhotoPath,
                            name: c.partnerName,
                            size: 80,
                            onTap: _showImageSourcePicker,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : c.partnerName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            c.categoryTitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Personal Information
                    _buildSectionContainer(
                      title: 'Personal Information',
                      subtitle: 'Update your personal details',
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            label: 'Email Address',
                            controller: _emailController,
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            label: 'Date of Birth',
                            controller: _dobController,
                            icon: Icons.cake_outlined,
                            suffixIcon: Icons.calendar_today_rounded,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1995, 3, 12),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                setState(() {
                                  _dobController.text = '${picked.day.toString().padLeft(2, '0')} ${months[picked.month - 1]} ${picked.year}';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Business Information
                    _buildSectionContainer(
                      title: 'Business Information',
                      subtitle: 'Update your business details',
                      icon: Icons.storefront_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Business Name',
                            controller: _bizNameController,
                            icon: Icons.business_center_outlined,
                          ),
                          const SizedBox(height: 14),

                          // Years of Experience Dropdown
                          const Text(
                            'Years of Experience',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedExperience,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                items: _experienceOptions.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.work_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        Text(opt, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedExperience = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Short Bio
                          const Text(
                            'Short Bio',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.description_outlined, size: 18, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _bioController,
                                        maxLines: 3,
                                        maxLength: 150,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          counterText: '',
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    '${_bioController.text.length}/150',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Profile Picture
                    _buildSectionContainer(
                      title: 'Profile Picture',
                      subtitle: 'Update your profile photo',
                      icon: Icons.camera_alt_rounded,
                      iconBg: const Color(0xFFFDF4FF),
                      iconColor: const Color(0xFFC026D3),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ProfileAvatarWidget(
                                photoPath: c.profilePhotoPath,
                                name: c.partnerName,
                                size: 60,
                                showCameraBadge: false,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, btnConstraints) {
                                    final changeBtn = OutlinedButton.icon(
                                      onPressed: _showImageSourcePicker,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                        side: const BorderSide(color: Color(0xFF93C5FD)),
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Change Photo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      ),
                                    );

                                    final removeBtn = OutlinedButton.icon(
                                      onPressed: () {
                                        widget.controller.removePhoto().then((_) {
                                          if (mounted) setState(() {});
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('Remove Photo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      ),
                                    );

                                    if (btnConstraints.maxWidth < 240) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          changeBtn,
                                          const SizedBox(height: 6),
                                          removeBtn,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: changeBtn),
                                        const SizedBox(width: 8),
                                        Expanded(child: removeBtn),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Recommended: Square image, at least 500x500 px',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Service Area (Optional)
                    _buildSectionContainer(
                      title: 'Service Area (Optional)',
                      subtitle: 'Set or update your working area',
                      icon: Icons.location_on_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      child: _buildTextField(
                        label: 'Service City / Region',
                        controller: _cityController,
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: keyboardType == TextInputType.phone ? 10 : null,
                  buildCounter: keyboardType == TextInputType.phone
                      ? (context, {required currentLength, required isFocused, maxLength}) => null
                      : null,
                  inputFormatters: keyboardType == TextInputType.phone
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  readOnly: onTap != null,
                  onTap: onTap,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (suffixIcon != null)
                IconButton(
                  icon: Icon(suffixIcon, size: 18, color: const Color(0xFF64748B)),
                  onPressed: onTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
