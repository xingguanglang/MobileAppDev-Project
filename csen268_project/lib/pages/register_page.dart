import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_cubit.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<UserCubit, UserState>(
          listener: (context, state) {
            if (state.user != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('register success')),
              );
            } else if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('error: ${state.error}')),
              );
            }
          },
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'username'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();
                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('username or password cannot be empty')),
                      );
                      return;
                    }
                    context.read<UserCubit>().createUser(username, password, AppUser.userTypeNormal);
                  },
                  child: const Text('register'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('back'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
