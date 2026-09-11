import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';
import '../../../../core/storage/local_registration_cache.dart';

class OptionItem {
  final String letter;
  final String title;
  final String? subtitle;
  final bool isRequired;
  final String? requiredNote;

  const OptionItem({
    required this.letter,
    required this.title,
    this.subtitle,
    this.isRequired = false,
    this.requiredNote,
  });
}

class ServiceCategoryDetailConfig {
  final String id;
  final String headerTitle;
  final String headerSubtitle;
  final String boxTitle;
  final String boxSubtitle;
  final List<OptionItem> options;
  final Color primaryColor;
  final Color lightBgColor;

  const ServiceCategoryDetailConfig({
    required this.id,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.boxTitle,
    required this.boxSubtitle,
    required this.options,
    this.primaryColor = AppColors.providerBluePrimary,
    this.lightBgColor = AppColors.providerBlueLight,
  });
}

class ProviderServiceOptionsSelectionScreen extends StatefulWidget {
  final String categoryId;

  const ProviderServiceOptionsSelectionScreen({
    super.key,
    required this.categoryId,
  });

  static const Map<String, ServiceCategoryDetailConfig> categoryConfigs = {
    'ac_service': ServiceCategoryDetailConfig(
      id: 'ac_service',
      headerTitle: 'AC Service Provider',
      headerSubtitle: 'Tell us which AC services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your AC Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF2563EB),
      lightBgColor: Color(0xFFEFF6FF),
      options: [
        OptionItem(letter: 'A.', title: 'AC Deep Cleaning'),
        OptionItem(letter: 'B.', title: 'AC Gas Refilling'),
        OptionItem(letter: 'C.', title: 'AC Installation'),
        OptionItem(letter: 'D.', title: 'AC Maintenance'),
        OptionItem(letter: 'E.', title: 'AC Repair'),
        OptionItem(letter: 'F.', title: 'AC Uninstallation'),
        OptionItem(letter: 'G.', title: 'Cassette AC Service'),
        OptionItem(letter: 'H.', title: 'Split AC Service'),
        OptionItem(letter: 'I.', title: 'Window AC Service'),
      ],
    ),
    'laundry': ServiceCategoryDetailConfig(
      id: 'laundry',
      headerTitle: 'Laundry Service Provider',
      headerSubtitle: 'Tell us which laundry services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your Laundry Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF4F46E5),
      lightBgColor: Color(0xFFEEF2FF),
      options: [
        OptionItem(letter: 'A.', title: 'Washing'),
        OptionItem(letter: 'B.', title: 'Dry Cleaning'),
        OptionItem(letter: 'C.', title: 'Ironing'),
        OptionItem(letter: 'D.', title: 'Steam Press'),
        OptionItem(letter: 'E.', title: 'Shoe Cleaning'),
        OptionItem(letter: 'F.', title: 'Carpet Cleaning'),
        OptionItem(letter: 'G.', title: 'Blanket Cleaning'),
        OptionItem(letter: 'H.', title: 'Curtain Cleaning'),
        OptionItem(
          letter: 'I.',
          title: 'Pickup & Delivery',
          isRequired: true,
          requiredNote: 'This service is mandatory and cannot be unselected.',
        ),
      ],
    ),
    'cooking': ServiceCategoryDetailConfig(
      id: 'cooking',
      headerTitle: 'Cooking Service Provider',
      headerSubtitle: 'Tell us which cooking services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your Cooking Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF4338CA),
      lightBgColor: Color(0xFFEEF2FF),
      options: [
        OptionItem(letter: 'A.', title: 'Home Cook'),
        OptionItem(letter: 'B.', title: 'Personal Chef'),
        OptionItem(
          letter: 'C.',
          title: 'Tiffin Service (Per Head)',
          subtitle: 'Tiffin size is the same for all.',
        ),
        OptionItem(letter: 'D.', title: 'North Indian'),
        OptionItem(letter: 'E.', title: 'South Indian'),
        OptionItem(letter: 'F.', title: 'Chinese'),
        OptionItem(letter: 'G.', title: 'Continental'),
        OptionItem(letter: 'H.', title: 'Fast Food'),
        OptionItem(letter: 'I.', title: 'Jain Food'),
        OptionItem(letter: 'J.', title: 'Vegan'),
        OptionItem(letter: 'K.', title: 'Bakery'),
      ],
    ),
    'car_service': ServiceCategoryDetailConfig(
      id: 'car_service',
      headerTitle: 'Car Service Provider',
      headerSubtitle: 'Tell us which car services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your Car Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF2563EB),
      lightBgColor: Color(0xFFEFF6FF),
      options: [
        OptionItem(
          letter: 'A.',
          title: 'General Car Service',
          subtitle: '(Full Inspection & Checkup)',
        ),
        OptionItem(
          letter: 'B.',
          title: 'Engine Repair',
          subtitle: '(Engine Diagnostic & Repair)',
        ),
        OptionItem(
          letter: 'C.',
          title: 'AC Service & Repair',
          subtitle: '(AC Gas Filling, Cooling Check)',
        ),
        OptionItem(
          letter: 'D.',
          title: 'Car Washing & Detailing',
          subtitle: '(Interior & Exterior Cleaning)',
        ),
        OptionItem(
          letter: 'E.',
          title: 'Denting & Painting',
          subtitle: '(Body Repair & Painting)',
        ),
        OptionItem(
          letter: 'F.',
          title: 'Brake Service',
          subtitle: '(Brake Check & Replacement)',
        ),
        OptionItem(
          letter: 'G.',
          title: 'Tyre Service',
          subtitle: '(Tyre Change, Rotation & Balancing)',
        ),
        OptionItem(
          letter: 'H.',
          title: 'Battery Service',
          subtitle: '(Battery Check & Replacement)',
        ),
        OptionItem(
          letter: 'I.',
          title: 'Car Electrical Repair',
          subtitle: '(Wiring, Lights, Sensors, etc.)',
        ),
        OptionItem(
          letter: 'J.',
          title: 'Roadside Assistance',
          subtitle: '(Breakdown Support & Towing)',
        ),
      ],
    ),
    'care_taker': ServiceCategoryDetailConfig(
      id: 'care_taker',
      headerTitle: 'Care Taker Service Provider',
      headerSubtitle: 'Tell us which care taker services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your Care Taker Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF3B82F6),
      lightBgColor: Color(0xFFEFF6FF),
      options: [
        OptionItem(
          letter: 'A.',
          title: 'Elderly Care',
          subtitle: 'Taking care of senior citizens.',
        ),
        OptionItem(
          letter: 'B.',
          title: 'Patient Care',
          subtitle: 'Taking care of sick or bedridden patients.',
        ),
        OptionItem(
          letter: 'C.',
          title: 'Child Care / Baby Sitting',
          subtitle: 'Taking care of children and babies.',
        ),
        OptionItem(
          letter: 'D.',
          title: 'Post Surgery Care',
          subtitle: 'Assistance and care after surgery.',
        ),
        OptionItem(
          letter: 'E.',
          title: 'Companion Care',
          subtitle: 'Providing companionship and support.',
        ),
        OptionItem(
          letter: 'F.',
          title: 'Home Assistance',
          subtitle: 'Help with daily activities at home.',
        ),
        // Note: Night Care removed as requested by user
      ],
    ),
    'plumber': ServiceCategoryDetailConfig(
      id: 'plumber',
      headerTitle: 'Plumbing Service Provider',
      headerSubtitle: 'Tell us which plumbing services you provide.\nYou can select multiple options.',
      boxTitle: 'Select Your Plumbing Services',
      boxSubtitle: 'Choose all the services you can provide to customers.',
      primaryColor: Color(0xFF0284C7),
      lightBgColor: Color(0xFFF0F9FF),
      options: [
        OptionItem(
          letter: 'A.',
          title: 'Water Pipe Repair & Fitting',
          subtitle: 'Tap, Pipe & Pipeline Repair',
        ),
        OptionItem(
          letter: 'B.',
          title: 'Drainage & Blockage Clearing',
          subtitle: 'Sink, Drain & Toilet Unblocking',
        ),
        OptionItem(
          letter: 'C.',
          title: 'Bathroom & Sanitary Fitting',
          subtitle: 'Commode, Shower & Basin Installation',
        ),
        OptionItem(
          letter: 'D.',
          title: 'Water Tank Cleaning & Repair',
          subtitle: 'Overhead & Underground Tank Services',
        ),
        OptionItem(
          letter: 'E.',
          title: 'Motor & Pump Installation',
          subtitle: 'Water Pump Fitting & Repair',
        ),
        OptionItem(
          letter: 'F.',
          title: 'Leakage Detection & Sealing',
          subtitle: 'Wall & Ceiling Leakage Repair',
        ),
        OptionItem(
          letter: 'G.',
          title: 'Geyser Installation & Repair',
          subtitle: 'Gas & Electric Water Heater Fitting',
        ),
      ],
    ),
  };

  @override
  State<ProviderServiceOptionsSelectionScreen> createState() =>
      _ProviderServiceOptionsSelectionScreenState();
}

class _ProviderServiceOptionsSelectionScreenState
    extends State<ProviderServiceOptionsSelectionScreen> {
  final Set<String> _selectedOptions = {};
  final TextEditingController _otherDetailsController = TextEditingController();
  bool _hasSubmitted = false;
  bool _isTouched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    final config = ProviderServiceOptionsSelectionScreen.categoryConfigs[widget.categoryId] ??
        ProviderServiceOptionsSelectionScreen.categoryConfigs['ac_service']!;
    
    // Pre-select required options (e.g., Pickup & Delivery in Laundry)
    for (final opt in config.options) {
      if (opt.isRequired) {
        _selectedOptions.add(opt.title);
      }
    }
    if (_selectedOptions.isEmpty && config.options.isNotEmpty) {
      _selectedOptions.add(config.options.first.title);
      if (config.options.length > 1) {
        _selectedOptions.add(config.options[1].title);
      }
    }
    if (_otherDetailsController.text.trim().isEmpty) {
      _otherDetailsController.text = 'Professional AC installation, deep cleaning jet wash service, compressor troubleshooting, and gas charging with guaranteed performance.';
    }
  }

  @override
  void dispose() {
    _otherDetailsController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() {
      _hasSubmitted = true;
    });

    final text = _otherDetailsController.text.trim();
    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Service details are compulsory! Please write at least 50 characters.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final draft = await LocalRegistrationCache.getDraft() ?? {};
    draft['service_options'] = _selectedOptions.toList();
    draft['specialization'] = _selectedOptions.isNotEmpty ? _selectedOptions.join(', ') : 'AC Jet Cleaning & Gas Refill';
    draft['service_details'] = text;
    await LocalRegistrationCache.saveDraft(draft);

    if (mounted) {
      context.push('/register/experience/${widget.categoryId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ProviderServiceOptionsSelectionScreen.categoryConfigs[widget.categoryId] ??
        ProviderServiceOptionsSelectionScreen.categoryConfigs['ac_service']!;

    final currentLength = _otherDetailsController.text.trim().length;
    final isInvalid = (_hasSubmitted || _isTouched) && currentLength < 50;

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
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Title Header
                        Text(
                          config.headerTitle,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          config.headerSubtitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section Banner Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: config.lightBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: config.primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: config.primaryColor.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: config.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.boxTitle,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: config.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      config.boxSubtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options Checkbox List
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: config.options.length,
                            separatorBuilder: (ctx, idx) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final option = config.options[index];
                              final isSelected = _selectedOptions.contains(option.title);

                              return InkWell(
                                onTap: option.isRequired
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedOptions.remove(option.title);
                                          } else {
                                            _selectedOptions.add(option.title);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.vertical(
                                  top: index == 0 ? const Radius.circular(18) : Radius.zero,
                                  bottom: index == config.options.length - 1
                                      ? const Radius.circular(18)
                                      : Radius.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Animated Custom Checkbox
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? config.primaryColor
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected
                                                ? config.primaryColor
                                                : const Color(0xFFCBD5E1),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      // Letter Prefix Code
                                      Text(
                                        option.letter,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: config.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Option Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    option.title,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                if (option.isRequired) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEEF2FF),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                          color: const Color(0xFFC7D2FE)),
                                                    ),
                                                    child: const Text(
                                                      'Required',
                                                      style: TextStyle(
                                                        color: Color(0xFF4F46E5),
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (option.subtitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                option.subtitle!,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                            if (option.requiredNote != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                option.requiredNote!,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Other Services TextField Box (Mandatory & Min 50 Chars Rule)
                        RichText(
                          text: const TextSpan(
                            text: 'Please Describe Your Other Service(s) ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(
                                text: '* (Compulsory - Min 50 characters)',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Write the services you provide which are not listed above.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Input Box Container with Red Border on Validation Failure
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isInvalid ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isInvalid
                                  ? const Color(0xFFEF4444)
                                  : (currentLength >= 50
                                      ? config.primaryColor
                                      : const Color(0xFFCBD5E1)),
                              width: isInvalid ? 2.0 : 1.5,
                            ),
                            boxShadow: isInvalid
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Semantics(
                                label: 'Enter your service details',
                                textField: true,
                                child: TextField(
                                  controller: _otherDetailsController,
                                  maxLines: 4,
                                  maxLength: 300,
                                  onChanged: (val) {
                                    setState(() {
                                      _isTouched = true;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your service details (minimum 50 characters required)...',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    contentPadding: EdgeInsets.all(14),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(
                                        currentLength < 50
                                            ? 'Min 50 chars required (${50 - currentLength} more needed)'
                                            : '✓ Minimum length satisfied',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: currentLength < 50
                                              ? (isInvalid
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF64748B))
                                              : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$currentLength / 300 characters',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isInvalid
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Error Banner Below Text Field
                        if (isInvalid) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'This field is compulsory! Please enter at least 50 characters (currently $currentLength/50).',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

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
                    constraints: const BoxConstraints(maxWidth: 580),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.primaryColor,
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
}
