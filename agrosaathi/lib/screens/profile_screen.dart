import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';

class ProfileScreen
    extends StatelessWidget {

  const ProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final user =
        UserService.currentUser;

    return Padding(
      padding:
          const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const CircleAvatar(
            radius: 40,
            child:
                Icon(Icons.person),
          ),

          const SizedBox(
            height: 20,
          ),

          Text(
            user?.name ??
                "Unknown User",
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            user?.phone ??
                "No Phone",
            style:
                const TextStyle(
              fontSize: 18,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            "Role: ${user?.role ?? ''}",
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            "Language: ${user?.preferredLanguage ?? ''}",
          ),

          const SizedBox(
            height: 30,
          ),

          ElevatedButton(
            onPressed: () async {

              await FirebaseAuth
                  .instance
                  .signOut();

            },

            child:
                const Text(
              "Logout",
            ),
          ),
        ],
      ),
    );
  }
}