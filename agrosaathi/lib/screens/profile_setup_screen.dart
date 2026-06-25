import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';

import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  String selectedRole = 'Farmer';

  String selectedLanguage = 'English';

  bool isLoading = false;

  Future<void> saveProfile() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception("User not logged in");
      }

      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: nameController.text.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        role: selectedRole,
        preferredLanguage:
            selectedLanguage,
      );

      await FirestoreService()
          .createUser(user);

      UserService.currentUser = user;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Profile',
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Full Name',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter your name';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButtonFormField<String>(
                value: selectedRole,

                decoration:
                    const InputDecoration(
                  labelText: 'Role',
                  border:
                      OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: 'Farmer',
                    child:
                        Text('Farmer'),
                  ),

                  DropdownMenuItem(
                    value: 'Buyer',
                    child:
                        Text('Buyer'),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    selectedRole =
                        value!;
                  });
                },
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButtonFormField<String>(
                value:
                    selectedLanguage,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Language',
                  border:
                      OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: 'English',
                    child:
                        Text('English'),
                  ),

                  DropdownMenuItem(
                    value: 'Hindi',
                    child:
                        Text('Hindi'),
                  ),

                  DropdownMenuItem(
                    value: 'Marathi',
                    child:
                        Text('Marathi'),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    selectedLanguage =
                        value!;
                  });
                },
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width: double.infinity,

                height: 55,

                child: ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : saveProfile,

                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Continue',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}