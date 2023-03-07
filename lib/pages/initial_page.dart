import 'package:admin/pages/sign_in.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService().checkUserState(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('error'),
          );
        } else if (snapshot.hasData) {
          if (snapshot.data != null && snapshot.data == true) {
            return const HomePage();
          } else {
            return const SignInPage();
          }
        } else {
          return const SignInPage();
        }
      },
    );
  }
}