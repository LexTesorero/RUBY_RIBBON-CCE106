import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: context.read<AppState>().currentCustomer?.name ?? '');
  late final _contactController = TextEditingController(text: context.read<AppState>().currentCustomer?.contact ?? '');
  late final _addressController = TextEditingController(text: context.read<AppState>().currentCustomer?.address ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Saved Delivery Address', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<AppState>().updateProfile(
                      name: _nameController.text.trim(),
                      contact: _contactController.text.trim(),
                      address: _addressController.text.trim(),
                    );
                showSuccessSnack(context, 'Profile updated.');
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
