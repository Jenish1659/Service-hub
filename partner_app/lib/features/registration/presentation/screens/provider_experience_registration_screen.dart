import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';
import '../../../../core/storage/local_registration_cache.dart';

class ProviderExperienceRegistrationScreen extends StatefulWidget {
  final String categoryId;

  const ProviderExperienceRegistrationScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<ProviderExperienceRegistrationScreen> createState() =>
      _ProviderExperienceRegistrationScreenState();
}

class _ProviderExperienceRegistrationScreenState
    extends State<ProviderExperienceRegistrationScreen> {
  // Section 1: Years of Experience (Unselected by default)
  String? _selectedExperience;

  // Section 2: Languages (Unchecked by default)
  final Set<String> _selectedLanguages = {};

  // Section 3: Available Days (Unchecked by default)
  final Set<String> _selectedDays = {};

  // Section 4: Working Hours (Unselected by default, options starting with 00:00 / 12:00 AM)
  String? _startTime;
  String? _endTime;

  // Section 5: Emergency Service
  String _emergencyService = 'No';
  String? _emergencyStartTime;
  String? _emergencyEndTime;

  // Section 6: Category Specific Details (All unselected by default)
  // AC
  final Set<String> _acTypes = {};
  String? _acOwnTools;

  // Cooking
  String? _cookingLocation;
  String? _cookingCapacity;

  // Car Service
  final Set<String> _carServiceTypes = {};
  final Set<String> _vehicleTypes = {};

  // Care Taker
  String? _careAvailability;
  String? _carePreference;

  // Plumber
  String? _plumberCategory;
  String? _plumberEmergency;

  // Laundry
  String? _laundryPickupMode;
  String? _laundryCapacity;

  // Section 7: About Yourself (Empty text - provider enters themselves)
  final TextEditingController _aboutController = TextEditingController();

  // Section 8: Profile Headline (Empty text - provider enters themselves)
  final TextEditingController _headlineController = TextEditingController();

  // Validation State
  bool _hasSubmitted = false;

  final List<String> _experienceOptions = [
    'Fresher',
    'Less than 1 Year',
    '1 – 3 Years',
    '3 – 5 Years',
    '5 – 10 Years',
    '10+ Years',
  ];

  final List<String> _languageOptions = ['English', 'Gujarati', 'Hindi'];

  final List<String> _daysList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Timings list starting with 00:00 AM / 12:00 AM
  final List<String> _timeOptions = [
    '12:00 AM (00:00)', '01:00 AM (01:00)', '02:00 AM (02:00)', '03:00 AM (03:00)',
    '04:00 AM (04:00)', '05:00 AM (05:00)', '06:00 AM (06:00)', '07:00 AM (07:00)',
    '08:00 AM (08:00)', '09:00 AM (09:00)', '10:00 AM (10:00)', '11:00 AM (11:00)',
    '12:00 PM (12:00)', '01:00 PM (13:00)', '02:00 PM (14:00)', '03:00 PM (15:00)',
    '04:00 PM (16:00)', '05:00 PM (17:00)', '06:00 PM (18:00)', '07:00 PM (19:00)',
    '08:00 PM (20:00)', '09:00 PM (21:00)', '10:00 PM (22:00)', '11:00 PM (23:00)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    _selectedExperience ??= '3 – 5 Years';
    _selectedLanguages.addAll(['English', 'Gujarati', 'Hindi']);
    _selectedDays.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
    _startTime ??= '09:00 AM (09:00)';
    _endTime ??= '07:00 PM (19:00)';
    _acTypes.addAll(['Split AC', 'Window AC', 'Inverter AC']);
    _acOwnTools ??= 'Yes';
    if (_aboutController.text.trim().isEmpty) {
      _aboutController.text = 'Experienced HVAC air conditioning specialist providing residential and commercial cooling repair and preventative maintenance for over 4 years.';
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  String _getCategoryTitle() {
    switch (widget.categoryId) {
      case 'cooking':
        return 'Cooking Provider';
      case 'car_service':
        return 'Car Service Provider';
      case 'care_taker':
        return 'Care Taker Provider';
      case 'plumber':
        return 'Plumber Provider';
      case 'laundry':
        return 'Laundry Provider';
      case 'ac_service':
      default:
        return 'AC Service Provider';
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.categoryId) {
      case 'cooking':
        return Icons.soup_kitchen_rounded;
      case 'car_service':
        return Icons.directions_car_rounded;
      case 'care_taker':
        return Icons.volunteer_activism_rounded;
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'ac_service':
      default:
        return Icons.ac_unit_rounded;
    }
  }

  Future<void> _handleContinue() async {
    setState(() {
      _hasSubmitted = true;
    });

    // Validations
    if (_selectedExperience == null) {
      _showToast('Please select your Years of Experience.');
      return;
    }
    if (_selectedLanguages.isEmpty) {
      _showToast('Please select at least one Language you speak.');
      return;
    }
    if (_selectedDays.isEmpty) {
      _showToast('Please select at least one Available Day.');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showToast('Please select your Working Start and End Hours.');
      return;
    }
    if (_emergencyService == 'Yes' && (_emergencyStartTime == null || _emergencyEndTime == null)) {
      _showToast('Please select Emergency Service Start and End Time.');
      return;
    }

    // Category Specific Validation
    if (!_validateCategorySpecificFields()) {
      return;
    }

    // About Yourself compulsory min 50 characters
    if (_aboutController.text.trim().length < 50) {
      _showToast('About Yourself field is compulsory (minimum 50 characters required).');
      return;
    }

    final draft = await LocalRegistrationCache.getDraft() ?? {};
    draft['experience_years'] = _selectedExperience;
    draft['languages'] = _selectedLanguages.toList();
    draft['languages_str'] = _selectedLanguages.join(', ');
    draft['available_days'] = _selectedDays.toList();
    draft['available_days_str'] = _selectedDays.join(', ');
    draft['working_hours'] = '$_startTime - $_endTime';
    draft['start_time'] = _startTime;
    draft['end_time'] = _endTime;
    draft['emergency_service'] = _emergencyService;
    draft['about'] = _aboutController.text.trim();
    draft['about_yourself'] = _aboutController.text.trim();
    draft['headline'] = _headlineController.text.trim();
    if (_acTypes.isNotEmpty) draft['ac_types'] = _acTypes.toList();
    if (_acOwnTools != null) draft['ac_own_tools'] = _acOwnTools;
    await LocalRegistrationCache.saveDraft(draft);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Professional Experience Saved Successfully! Moving to Identity Verification...'),
        backgroundColor: AppColors.shopkeeperGreenPrimary,
        duration: Duration(seconds: 1),
      ),
    );

    context.push('/register/verify-identity');
  }

  bool _validateCategorySpecificFields() {
    switch (widget.categoryId) {
      case 'cooking':
        if (_cookingLocation == null) {
          _showToast('Please select where you provide cooking services.');
          return false;
        }
        if (_cookingCapacity == null) {
          _showToast('Please select maximum people you can cook for.');
          return false;
        }
        break;
      case 'car_service':
        if (_carServiceTypes.isEmpty) {
          _showToast('Please select at least one Car Service Type.');
          return false;
        }
        if (_vehicleTypes.isEmpty) {
          _showToast('Please select Vehicle Types you work on.');
          return false;
        }
        break;
      case 'care_taker':
        if (_careAvailability == null) {
          _showToast('Please select your Care Taker Availability shift.');
          return false;
        }
        if (_carePreference == null) {
          _showToast('Please select your Care Preference.');
          return false;
        }
        break;
      case 'plumber':
        if (_plumberCategory == null) {
          _showToast('Please select your Plumbing Service Category.');
          return false;
        }
        if (_plumberEmergency == null) {
          _showToast('Please select if you can handle emergency plumbing calls.');
          return false;
        }
        break;
      case 'laundry':
        if (_laundryPickupMode == null) {
          _showToast('Please select Laundry Pickup & Delivery Mode.');
          return false;
        }
        if (_laundryCapacity == null) {
          _showToast('Please select your Daily Laundry Capacity.');
          return false;
        }
        break;
      case 'ac_service':
      default:
        if (_acTypes.isEmpty) {
          _showToast('Please select which types of ACs you work on.');
          return false;
        }
        if (_acOwnTools == null) {
          _showToast('Please specify if you have your own professional tools.');
          return false;
        }
        break;
    }
    return true;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3B82F6);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
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
        title: const ShLogoWidget(size: 32, showSubtitle: true),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header with Category Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tell us about your\nprofessional experience',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Help customers understand your skills and availability.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category Badge Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getCategoryIcon(), color: primaryBlue, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getCategoryTitle(),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 1 & Section 2 Row Layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 500;
                            return Flex(
                              direction: isMobile ? Axis.vertical : Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section 1: Years of Experience
                                Expanded(
                                  flex: isMobile ? 0 : 3,
                                  child: _buildCardSection(
                                    icon: Icons.workspace_premium_outlined,
                                    title: '1. Years of Experience',
                                    isRequired: true,
                                    hasError: _hasSubmitted && _selectedExperience == null,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 10,
                                      children: _experienceOptions.map((exp) {
                                        final isSelected = _selectedExperience == exp;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedExperience = exp;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected ? primaryBlue : borderColor,
                                                width: isSelected ? 1.8 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  exp,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? primaryBlue
                                                        : const Color(0xFF334155),
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.radio_button_checked_rounded,
                                                    color: primaryBlue,
                                                    size: 14,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                if (!isMobile) const SizedBox(width: 14),
                                if (isMobile) const SizedBox(height: 14),

                                // Section 2: Languages You Speak
                                Expanded(
                                  flex: isMobile ? 0 : 2,
                                  child: _buildCardSection(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    title: '2. Languages You Speak',
                                    isRequired: true,
                                    hasError: _hasSubmitted && _selectedLanguages.isEmpty,
                                    child: Column(
                                      children: _languageOptions.map((lang) {
                                        final isChecked = _selectedLanguages.contains(lang);
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isChecked) {
                                                _selectedLanguages.remove(lang);
                                              } else {
                                                _selectedLanguages.add(lang);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: isChecked ? primaryBlue : Colors.white,
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(
                                                      color: isChecked ? primaryBlue : const Color(0xFFCBD5E1),
                                                    ),
                                                  ),
                                                  child: isChecked
                                                      ? const Icon(Icons.check_rounded,
                                                          color: Colors.white, size: 14)
                                                      : null,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  lang,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isChecked
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Section 3: Available Days
                        _buildCardSection(
                          icon: Icons.calendar_today_outlined,
                          title: '3. Available Days',
                          isRequired: true,
                          hasError: _hasSubmitted && _selectedDays.isEmpty,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _daysList.map((day) {
                                final isSelected = _selectedDays.contains(day);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedDays.remove(day);
                                        } else {
                                          _selectedDays.add(day);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryBlue : borderColor,
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: isSelected ? primaryBlue : Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isSelected ? primaryBlue : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded,
                                                    color: Colors.white, size: 13)
                                                : null,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            day,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isSelected ? primaryBlue : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 4 & 5: Working Hours & Emergency Service
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 550;
                            return Flex(
                              direction: isMobile ? Axis.vertical : Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section 4: Working Hours
                                Expanded(
                                  flex: isMobile ? 0 : 1,
                                  child: _buildCardSection(
                                    icon: Icons.access_time_rounded,
                                    title: '4. Working Hours',
                                    isRequired: true,
                                    hasError: _hasSubmitted && (_startTime == null || _endTime == null),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Time',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                        const SizedBox(height: 6),
                                        _buildTimeDropdown(_startTime, 'Select Start Time', (val) {
                                          if (val != null) setState(() => _startTime = val);
                                        }),
                                        const SizedBox(height: 12),
                                        const Text('End Time',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                        const SizedBox(height: 6),
                                        _buildTimeDropdown(_endTime, 'Select End Time', (val) {
                                          if (val != null) setState(() => _endTime = val);
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isMobile) const SizedBox(width: 14),
                                if (isMobile) const SizedBox(height: 14),

                                // Section 5: Emergency Service
                                Expanded(
                                  flex: isMobile ? 0 : 1,
                                  child: _buildCardSection(
                                    icon: Icons.notifications_active_outlined,
                                    title: '5. Emergency Service',
                                    isRequired: true,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: ['Yes', 'No'].map((opt) {
                                            final isSel = _emergencyService == opt;
                                            return Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: InkWell(
                                                  onTap: () => setState(() => _emergencyService = opt),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isSel ? primaryBlue : borderColor,
                                                        width: isSel ? 1.8 : 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          isSel
                                                              ? Icons.radio_button_checked_rounded
                                                              : Icons.radio_button_unchecked_rounded,
                                                          color: isSel ? primaryBlue : const Color(0xFF94A3B8),
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          opt,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                                            color: isSel ? primaryBlue : const Color(0xFF334155),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),

                                        if (_emergencyService == 'Yes') ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Emergency Service Available Between',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryBlue,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('Start Time',
                                                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                          const SizedBox(height: 4),
                                                          _buildTimeDropdown(_emergencyStartTime, 'Start Time', (val) {
                                                            if (val != null) setState(() => _emergencyStartTime = val);
                                                          }, isSmall: true),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('End Time',
                                                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                          const SizedBox(height: 4),
                                                          _buildTimeDropdown(_emergencyEndTime, 'End Time', (val) {
                                                            if (val != null) setState(() => _emergencyEndTime = val);
                                                          }, isSmall: true),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Section 6: Category Specific Details (DIFFERENT PER PROVIDER!)
                        _buildCategorySpecificSection(),
                        const SizedBox(height: 14),

                        // Section 7: About Yourself (Empty - Compulsory & Min 50 Chars)
                        _buildCardSection(
                          icon: Icons.person_outline_rounded,
                          title: '7. About Yourself',
                          isRequired: true,
                          hasError: _hasSubmitted && _aboutController.text.trim().length < 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: _hasSubmitted && _aboutController.text.trim().length < 50
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _hasSubmitted && _aboutController.text.trim().length < 50
                                        ? const Color(0xFFEF4444)
                                        : borderColor,
                                    width: _hasSubmitted && _aboutController.text.trim().length < 50 ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Semantics(
                                  label: 'About yourself',
                                  textField: true,
                                  child: TextField(
                                    controller: _aboutController,
                                    maxLines: 4,
                                    maxLength: 300,
                                    onChanged: (val) => setState(() {}),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.all(14),
                                      border: InputBorder.none,
                                      hintText: 'Tell customers about your skills, background and service quality (minimum 50 characters required)...',
                                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _aboutController.text.trim().length < 50
                                        ? '* Min 50 characters required (${50 - _aboutController.text.trim().length} needed)'
                                        : '✓ Min 50 characters satisfied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _aboutController.text.trim().length < 50
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                  Text(
                                    '${_aboutController.text.length} / 300 characters',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 8: Profile Headline (Empty - Optional)
                        _buildCardSection(
                          icon: Icons.local_offer_outlined,
                          title: '8. Profile Headline (Optional)',
                          isRequired: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                child: TextField(
                                  controller: _headlineController,
                                  maxLength: 50,
                                  onChanged: (val) => setState(() {}),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: InputBorder.none,
                                    hintText: 'e.g. Expert Technician / Professional Specialist',
                                    hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_headlineController.text.length} / 50',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
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

            // Bottom Navigation Sticky Button
            Container(
              padding: const EdgeInsets.all(16),
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
                    constraints: const BoxConstraints(maxWidth: 620),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _handleContinue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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

  // Card Wrapper Widget
  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required bool isRequired,
    bool hasError = false,
    required Widget child,
  }) {
    const primaryBlue = Color(0xFF3B82F6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: hasError ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: hasError ? const Color(0xFFEF4444) : primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                    ),
                    children: [
                      if (isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444)),
                        ),
                    ],
                  ),
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

  // Time Selector Dropdown starting with 00:00 / 12:00 AM
  Widget _buildTimeDropdown(String? value, String hintText, ValueChanged<String?> onChanged, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hintText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF64748B),
            size: isSmall ? 18 : 22,
          ),
          style: TextStyle(
            fontSize: isSmall ? 11.5 : 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          onChanged: onChanged,
          items: _timeOptions.map((t) {
            return DropdownMenuItem<String>(
              value: t,
              child: Row(
                children: [
                  Icon(Icons.access_time, size: isSmall ? 13 : 14, color: const Color(0xFF94A3B8)),
                  SizedBox(width: isSmall ? 4 : 6),
                  Expanded(
                    child: Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 11.5 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Section 6 Widget - Category Specific Customization
  Widget _buildCategorySpecificSection() {
    switch (widget.categoryId) {
      case 'cooking':
        return _buildCookingSection();
      case 'car_service':
        return _buildCarServiceSection();
      case 'care_taker':
        return _buildCareTakerSection();
      case 'plumber':
        return _buildPlumberSection();
      case 'laundry':
        return _buildLaundrySection();
      case 'ac_service':
      default:
        return _buildAcServiceSection();
    }
  }

  // 1. AC Service Details
  Widget _buildAcServiceSection() {
    return _buildCardSection(
      icon: Icons.build_outlined,
      title: '6. Service Specific Details (AC Service)',
      isRequired: true,
      hasError: _hasSubmitted && (_acTypes.isEmpty || _acOwnTools == null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Which type of ACs do you work on? *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                ...['Residential', 'Commercial', 'Industrial'].map((type) {
                  final isChecked = _acTypes.contains(type);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _acTypes.remove(type);
                        } else {
                          _acTypes.add(type);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(type, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Do you have your own professional tools? *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: ['Yes', 'No'].map((opt) {
                    final isSel = _acOwnTools == opt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _acOwnTools = opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Center(
                              child: Text(opt,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569))),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Cooking Service Details
  Widget _buildCookingSection() {
    return _buildCardSection(
      icon: Icons.soup_kitchen_outlined,
      title: '6. Service Specific Details (Cooking Service)',
      isRequired: true,
      hasError: _hasSubmitted && (_cookingLocation == null || _cookingCapacity == null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Where do you provide cooking services? *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    ...["Customer's Home", 'My Kitchen', 'Both'].map((loc) {
                      final isSel = _cookingLocation == loc;
                      return InkWell(
                        onTap: () => setState(() => _cookingLocation = loc),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(loc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Maximum people you can cook for *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['1 – 5 People', '6 – 15 People', '16 – 30 People', '30+ People'].map((cap) {
                        final isSel = _cookingCapacity == cap;
                        return InkWell(
                          onTap: () => setState(() => _cookingCapacity = cap),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              cap,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Car Service Details
  Widget _buildCarServiceSection() {
    return _buildCardSection(
      icon: Icons.directions_car_outlined,
      title: '6. Service Specific Details (Car Service)',
      isRequired: true,
      hasError: _hasSubmitted && (_carServiceTypes.isEmpty || _vehicleTypes.isEmpty),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Type *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    ...['Doorstep Service', 'Workshop Service', 'Both (Doorstep + Workshop)'].map((type) {
                      final isChecked = _carServiceTypes.contains(type);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _carServiceTypes.remove(type);
                            } else {
                              _carServiceTypes.add(type);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(type, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vehicle Types You Work On *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Hatchback', 'Sedan', 'SUV', 'Luxury', 'Commercial'].map((v) {
                        final isChecked = _vehicleTypes.contains(v);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _vehicleTypes.remove(v);
                              } else {
                                _vehicleTypes.add(v);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              v,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Care Taker Service Details
  Widget _buildCareTakerSection() {
    return _buildCardSection(
      icon: Icons.volunteer_activism_outlined,
      title: '6. Service Specific Details (Care Taker)',
      isRequired: true,
      hasError: _hasSubmitted && (_careAvailability == null || _carePreference == null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Availability *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Day Shift', 'Night Shift', '24 Hours'].map((av) {
                        final isSel = _careAvailability == av;
                        return InkWell(
                          onTap: () => setState(() => _careAvailability = av),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              av,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Care Preference *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Male', 'Female', 'Both'].map((pref) {
                        final isSel = _carePreference == pref;
                        return InkWell(
                          onTap: () => setState(() => _carePreference = pref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              pref,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Plumber Service Details
  Widget _buildPlumberSection() {
    return _buildCardSection(
      icon: Icons.plumbing_outlined,
      title: '6. Service Specific Details (Plumber)',
      isRequired: true,
      hasError: _hasSubmitted && (_plumberCategory == null || _plumberEmergency == null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Category *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                ...['Residential', 'Commercial', 'Industrial'].map((cat) {
                  final isSel = _plumberCategory == cat;
                  return InkWell(
                    onTap: () => setState(() => _plumberCategory = cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(cat, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Can you handle emergency plumbing calls? *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: ['Yes', 'No'].map((opt) {
                    final isSel = _plumberEmergency == opt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _plumberEmergency = opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                            ),
                            child: Center(
                              child: Text(opt,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569))),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Laundry Service Details (Custom self-designed as requested)
  Widget _buildLaundrySection() {
    return _buildCardSection(
      icon: Icons.local_laundry_service_outlined,
      title: '6. Service Specific Details (Laundry Service)',
      isRequired: true,
      hasError: _hasSubmitted && (_laundryPickupMode == null || _laundryCapacity == null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Location & Pickup Mode *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                ...['Doorstep Pickup & Drop', 'In-Store Drop Off', 'Both'].map((mode) {
                  final isSel = _laundryPickupMode == mode;
                  return InkWell(
                    onTap: () => setState(() => _laundryPickupMode = mode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(mode, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Capacity (KG / Items) *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['10 – 25 KG', '25 – 50 KG', '50 – 100 KG', '100+ KG'].map((cap) {
                    final isSel = _laundryCapacity == cap;
                    return InkWell(
                      onTap: () => setState(() => _laundryCapacity = cap),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          cap,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
