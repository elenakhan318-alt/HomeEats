import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import '../../theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _forestGreen = Color(0xFF3F5133);
  static const Color _terracotta = Color(0xFFD56F32);
  static const Color _warmCream = Color(0xFFFAF6EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                      child: Image.asset(
  'assets/images/homeeats_logo.png',
  height: 230,
  fit: BoxFit.contain,
),
                      ),

                      const SizedBox(height: 28),
const Text(
  'Homemade food you can trust.',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: AppColors.secondary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
),

const SizedBox(height: 12),

const Padding(
  padding: EdgeInsets.symmetric(horizontal: 18),
  child: Text(
    'Freshly prepared by verified local cooks and delivered with care.',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      height: 1.5,
    ),
  ),
),
                      const Spacer(),

                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _terracotta,
                            foregroundColor:
                                Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create an account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _forestGreen,
                            side: const BorderSide(
                              color: _forestGreen,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}