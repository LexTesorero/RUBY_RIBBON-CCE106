import 'package:cce106project/models/order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'order_tracking_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyState(
          icon: Icons.person_outline_rounded,
          title: 'You\'re browsing as a guest',
          subtitle: 'Log in or create an account to view your profile and order history.',
          action: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Log In / Register'),
          ),
        ),
      );
    }

    final customer = appState.currentCustomer!;
    final orders = appState.ordersForCurrentCustomer();
    final recentOrders = orders.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.ribbonRed,
                    child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                  Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(customer.email, style: Theme.of(context).textTheme.bodyMedium),
                  const Divider(height: 28),
                  _infoRow(context, Icons.phone_outlined, customer.contact.isEmpty ? 'No contact number set' : customer.contact),
                  const SizedBox(height: 8),
                  _infoRow(context, Icons.location_on_outlined, customer.address.isEmpty ? 'No saved address' : customer.address),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                          onPressed: () async {
                            final confirmed = await showLogoutDialog(context);
                            if (confirmed) {
                              // AuthGate reacts to the sign-out and shows the login screen.
                              appState.logout();
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SectionHeader(title: 'Order History'),
          if (recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders yet', subtitle: 'Your placed orders will show up here.'),
            )
          else
            for (final order in recentOrders)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(order.id),
                  subtitle: Text('${DateFormat('MMM d, y').format(order.createdAt)} • ${peso(order.total)}'),
                  trailing: StatusBadge(label: order.orderStatus.label, color: orderStatusColor(order.orderStatus)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id))),
                ),
              ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.chocolateSoft),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}