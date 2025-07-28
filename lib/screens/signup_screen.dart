import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../providers/auth_provider.dart';
import '../providers/signup_provider.dart';
import '../widgets/password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    final signupProvider = Provider.of<SignupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/signup_bg.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo-or.png', height: 45),
                      const SizedBox(width: 15),
                      const Text(
                        'TO DO',
                        style: TextStyle(
                          color: Color(0xFFEB5E00),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: const TextStyle(
                                    color: Color(0xFFEB5E00),
                                    fontWeight: FontWeight.w900,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: signupProvider.nameController,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFEFF0F6), width: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: signupProvider.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFEFF0F6), width: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: signupProvider.passwordController,
                          hint: 'Password',
                          borderColor: const Color(0xFFEFF0F6),
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: signupProvider.confirmPasswordController,
                          hint: 'Confirm Password',
                          borderColor: const Color(0xFFEFF0F6),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: signupProvider.isLoading
                              ? null
                              : () async {
                            if (signupProvider.passwordController.text !=
                                signupProvider.confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Passwords do not match.")),
                              );
                              return;
                            }
                            signupProvider.toggleLoading();
                            bool success = await authProvider.signupWithEmail(
                              name: signupProvider.nameController.text.trim(),
                              email: signupProvider.emailController.text.trim(),
                              password: signupProvider.passwordController.text.trim(),
                              context: context, // Pass the context here
                            );
                            signupProvider.toggleLoading();
                            if (success) {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFED6E1A), Color(0xFFEB5E00)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: signupProvider.isLoading
                                ? const SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFEFF0F6))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Or'),
                            ),
                            Expanded(child: Divider(color: Color(0xFFEFF0F6))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: Color(0xFFEFF0F6), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/g-logo.png', height: 20),
                              const SizedBox(width: 8),
                              const Text('Continue with Google', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
