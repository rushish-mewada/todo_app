import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;

  void toggleLoading() {
    isLoading = !isLoading;
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  Future<void> loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe = prefs.getBool('rememberMe') ?? false;
    if (rememberMe) {
      emailController.text = prefs.getString('rememberedEmail') ?? '';
    }
    notifyListeners();
  }

  Future<void> saveEmailIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('rememberedEmail', emailController.text);
      await prefs.setBool('rememberMe', true);
      await prefs.setInt('rememberTimestamp', DateTime.now().millisecondsSinceEpoch);
    } else {
      await prefs.remove('rememberedEmail');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> clearIfExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('rememberTimestamp');
    if (ts != null) {
      final storedTime = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(storedTime).inDays > 30) {
        await prefs.remove('rememberedEmail');
        await prefs.remove('rememberMe');
        await prefs.remove('rememberTimestamp');
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
