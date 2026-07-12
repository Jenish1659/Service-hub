import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    // Auto-refresh order status every 3 seconds for simulated real-time tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchOrderDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrderDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _orderData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'Placed':
        return 0;
      case 'Packing':
        return 1;
      case 'Ready for Pickup':
        return 2;
      case 'Out for Delivery':
        return 3;
      case 'Delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _orderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchOrderDetails(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _orderData!;
    final status = order['status'] ?? 'Placed';
    final currentStep = _getStatusStep(status);
    final deliveryPin = order['delivery_pin'] ?? '2842';
    final hasAgent = order['agent_id'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order: #${widget.orderId.substring(0, 8).toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchOrderDetails(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. SECURE DELIVERY PIN BANNER
              if (status != 'Delivered')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xffeff6ff),
                  child: Column(
                    children: [
                      const Text(
                        'Secure Delivery Verification PIN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share this PIN code with the delivery agent to complete verification:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          deliveryPin,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. MAP VIEWPORT
              Container(
                height: 200,
                color: const Color(0xffe2e8f0),
                child: const Center(
                  child: Icon(Icons.map, size: 60, color: AppTheme.textSecondaryColor),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. DELIVERY AGENT INFO
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xffeff6ff),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.directions_bike, color: AppTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasAgent ? 'Ravi Kumar' : 'Assigning Delivery Partner...',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasAgent ? 'Delivery Partner · Honda Activa' : 'Hyperlocal partner dispatch',
                                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (hasAgent)
                              IconButton(
                                icon: const Icon(Icons.call, color: AppTheme.successColor),
                                onPressed: () {},
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. STEP TIMELINE
                    const Text(
                      'Order Timeline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 16),
                    _buildStep('Order Placed', 'Payment processed successfully', currentStep >= 0),
                    _buildStep('Accepted & Packing', 'Seller preparing items', currentStep >= 1),
                    _buildStep('Ready for Pickup', 'Waiting for Delivery Agent', currentStep >= 2),
                    _buildStep('Out for Delivery', 'Agent is carrying your order', currentStep >= 3),
                    _buildStep('Delivered', 'Completed with PIN verification', currentStep >= 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String subtitle, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.primaryColor : AppTheme.borderCol,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 35,
              color: isCompleted ? AppTheme.primaryColor : AppTheme.borderCol,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
