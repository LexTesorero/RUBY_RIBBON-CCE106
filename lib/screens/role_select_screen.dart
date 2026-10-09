import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'customer/customer_shell.dart';
import 'staff/staff_login_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ribbonRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.cake_rounded, color: AppColors.ribbonRed, size: 52),
              ),
              const SizedBox(height: 20),
              Text(
                'Ruby Ribbon\nBakeshop',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, height: 1.15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Freshly baked. Freshly ordered.',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: 'I\'m a Customer',
                subtitle: 'Browse the menu, customize treats, and order online.',
                onTap: () {
                  context.read<AppState>().role = UserRole.customer;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CustomerShell()));
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.badge_rounded,
                title: 'I\'m Bakery Staff',
                subtitle: 'Manage orders, products, payments, and sales.',
                onTap: () {
                  context.read<AppState>().role = UserRole.staff;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StaffLoginScreen()));
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'UI Prototype • Mock Data Only',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: AppColors.ribbonRed, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.chocolateSoft),
            ],
          ),
        ),
      ),
    );
  }
}
