import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/customer/payment_success_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HomeEatsApp());
}

class HomeEatsApp extends StatelessWidget {
  const HomeEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeEats',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        final Uri uri = Uri.parse(
          settings.name ?? '/',
        );

        if (uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first ==
                'payment-success') {
          final String? orderId =
              uri.pathSegments.length > 1
                  ? uri.pathSegments[1]
                  : null;

          return MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              orderId: orderId,
            ),
          );
        }

        return null;
      },
    );
  }
}