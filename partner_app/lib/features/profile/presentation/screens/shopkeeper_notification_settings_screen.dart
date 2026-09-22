import 'package:flutter/material.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperNotificationSettingsScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperNotificationSettingsScreen({super.key, this.controller});

  @override
  State<ShopkeeperNotificationSettingsScreen> createState() =>
      _ShopkeeperNotificationSettingsScreenState();
}

class _ShopkeeperNotificationSettingsScreenState
    extends State<ShopkeeperNotificationSettingsScreen> {
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

  void _updateSettings({
    bool? orders,
    bool? payments,
    bool? inventory,
    bool? promo,
    bool? system,
  }) {
    _controller.updateNotificationSettings(
      orders: orders ?? _controller.orderNotifications,
      payments: payments ?? _controller.paymentNotifications,
      inventory: inventory ?? _controller.inventoryAlerts,
      promo: promo ?? _controller.promotionalUpdates,
      system: system ?? _controller.systemNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Configure store alerts and customer notifications',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFFEA580C),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Real-Time Store Alerts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9A3412),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Never miss incoming technician orders and critical payment settlements.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFC2410C),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Store Operations
                    _buildSectionHeader('TRANSACTIONAL & STORE ALERTS'),
                    _buildCard([
                      // Order Notifications
                      _buildSwitchTile(
                        icon: Icons.shopping_bag_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Order Notifications',
                        subtitle: 'Incoming part orders, cancellations, returns & pickups',
                        value: _controller.orderNotifications,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) => _updateSettings(orders: v),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // Payment Notifications
                      _buildSwitchTile(
                        icon: Icons.currency_rupee_rounded,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Payment Notifications',
                        subtitle: 'Daily bank transfers, settlement receipts & dues',
                        value: _controller.paymentNotifications,
                        activeColor: const Color(0xFF16A34A),
                        onChanged: (v) => _updateSettings(payments: v),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // Inventory Alerts
                      _buildSwitchTile(
                        icon: Icons.inventory_2_outlined,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Inventory Alerts',
                        subtitle: 'Low stock warnings, out-of-stock and reorder tips',
                        value: _controller.inventoryAlerts,
                        activeColor: const Color(0xFFD97706),
                        onChanged: (v) => _updateSettings(inventory: v),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section: Marketing & Platform
                    _buildSectionHeader('PLATFORM UPDATES & CAMPAIGNS'),
                    _buildCard([
                      // Promotional Updates
                      _buildSwitchTile(
                        icon: Icons.campaign_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Promotional Updates',
                        subtitle: 'Merchant bonus campaigns, seasonal sales & tips',
                        value: _controller.promotionalUpdates,
                        activeColor: const Color(0xFF9333EA),
                        onChanged: (v) => _updateSettings(promo: v),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // System Notifications
                      _buildSwitchTile(
                        icon: Icons.build_circle_outlined,
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF475569),
                        title: 'System Notifications',
                        subtitle: 'Scheduled maintenance, app upgrades & terms changes',
                        value: _controller.systemNotifications,
                        activeColor: const Color(0xFF475569),
                        onChanged: (v) => _updateSettings(system: v),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _updateSettings(
                                orders: true,
                                payments: true,
                                inventory: true,
                                promo: true,
                                system: true,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All notifications enabled'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Enable All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _updateSettings(
                                orders: true,
                                payments: true,
                                inventory: true,
                                promo: false,
                                system: true,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Promotional alerts muted'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Essential Only',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
