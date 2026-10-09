import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/people.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dialogs.dart';
import 'staff_dashboard_screen.dart';
import 'order_management_screen.dart';
import 'product_management_screen.dart';
import 'analytics_screen.dart';

class StaffShell extends StatefulWidget {
  final int initialIndex;
  const StaffShell({super.key, this.initialIndex = 0});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late int _index = widget.initialIndex;

  static const _titles = ['Dashboard', 'Order Management', 'Product Management', 'Sales & Analytics'];

  /// From the drawer: switch tab and close the drawer.
  void goTo(int i) {
    setState(() => _index = i);
    Navigator.of(context).pop();
  }

  /// From dashboard cards: switch tab only.
  void goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AppState>().currentStaff;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppColors.ribbonRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.badge_rounded, color: AppColors.ribbonRed)),
                    const SizedBox(height: 10),
                    Text(staff?.name ?? 'Staff', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text('Staff', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              _drawerTile(Icons.dashboard_rounded, 'Dashboard', 0),
              _drawerTile(Icons.receipt_long_rounded, 'Order Management', 1),
              _drawerTile(Icons.bakery_dining_rounded, 'Product Management', 2),
              _drawerTile(Icons.bar_chart_rounded, 'Sales & Analytics', 3),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  final confirmed = await showLogoutDialog(context);
                  if (confirmed && context.mounted) {
                    context.read<AppState>().staffLogout();
                    // Close the drawer; AuthGate swaps to the login screen on sign-out.
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          StaffDashboardScreen(onNavigate: goToTab),
          const OrderManagementScreen(),
          const ProductManagementScreen(),
          const AnalyticsScreen(),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String label, int i) {
    final selected = _index == i;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.ribbonRed : AppColors.chocolateSoft),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.ribbonRed : AppColors.chocolate,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.creamDark,
      onTap: () => goTo(i),
    );
  }
}