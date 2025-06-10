import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      //Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
    );

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('User creation failed!');
       }

      //Create UserModel
      UserModel newUser = UserModel(
        id: firebaseUser.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      //Save user to FireStore
      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set(newUser.toMap());

      //Update UserProvider
      final userProvider = Provider.of<UserProvider>(context,listen: false);
      userProvider.updateUser(newUser);

      //Navigate to HomeScreen
      Navigator.pushReplacementNamed(context,'/home');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration Failed: ${e.toString()}')),
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
                  'Create an Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
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
                    hintText: 'Full Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.black54,
                  validator: (value) => value!.isEmpty ? 'Enter your Name': null,
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 20),
                _isLoading
                  ? const CircularProgressIndicator(color: Colors.black,)
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF305038),
                        padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 10),
                      ),
                      child: const Text('Register', style: TextStyle(fontSize: 18, color: Color(0xFFFFD700),)),
                     ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context,'/login'); // go to login screen
                  },
                  child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF305038),)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
