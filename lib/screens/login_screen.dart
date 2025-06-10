import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // for validation
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try{
      //Authenticate user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      //Fetch user details from FireStore using providers
      final userProvider = Provider.of<UserProvider>(context,listen: false);
      await userProvider.fetchUser(userCredential.user!.uid);

      //Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    }

    setState(() {
      _isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Login to DimeFlow",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.black54,
                  validator: (value) => value!.isEmpty ? 'Enter an email': null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.black54,
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters': null,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final emailController = TextEditingController();
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text("Reset Password"),
                          content: TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blueGrey,
                                  )
                              ),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blueGrey,
                                  )
                              ),
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            cursorColor: Colors.black54,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey),),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await FirebaseAuth.instance.sendPasswordResetEmail(
                                    email: emailController.text.trim(),
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Password reset email sent!")),
                                  );
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: ${e.toString()}")),
                                  );
                                }
                              },
                              child: const Text("Send", style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF305038),),
                  ),
                ),
                const SizedBox(height: 10),
                _isLoading
                  ? const CircularProgressIndicator(color: Colors.black,)
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF305038),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      ),
                      child: const Text('Login', style: TextStyle(fontSize: 18, color: Color(0xFFFFD700),)),
                    ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register'); //navigate to register page
                  },
                  child: const Text("Don't have an account yet? Sign up now", style: TextStyle(color: Color(0xFF305038),)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
