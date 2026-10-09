import 'package:flutter/material.dart';

/// After sign-out, AuthGate shows the login page by itself; this only clears any pushed screens.
void resetToRoleSelect(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);
void resetToVeryFirstScreen(BuildContext context) => resetToRoleSelect(context);