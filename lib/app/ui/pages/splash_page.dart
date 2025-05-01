import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AuthController is initialized globally via InitialBinding
    // It will automatically navigate away from splash once auth state is determined
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading Rizq...'),
          ],
        ),
      ),
    );
  }
}
