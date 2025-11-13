import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_cubit.dart';
import 'package:go_router/go_router.dart';

class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final username = context.read<UserCubit>().state.user?.username ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          'User Page',
          style: TextStyle(
            fontFamily: 'Spline Sans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 23/18,
            letterSpacing: 0,
            color: Color(0xFF0D1C17),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/avatar.png',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'Spline Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 23/18,
                    letterSpacing: 0,
                    color: Color(0xFF0D1C17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: become a premium user
                },
                icon: Image.asset(
                  'assets/icons/gift.png',
                  width: 24,
                  height: 24,
                ),
                label: const Text(
                  'Become a premium user',
                  style: TextStyle(
                    fontFamily: 'Spline Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 23/18,
                    letterSpacing: 0,
                    color: Color(0xFF0D1C17),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009963)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7FCFA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    fontFamily: 'Spline Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 23/18,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
