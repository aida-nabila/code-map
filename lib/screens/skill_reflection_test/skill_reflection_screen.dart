import 'package:code_map/screens/skill_reflection_test/skill_reflection_test.dart';
import 'package:flutter/material.dart';
import '../../models/user_responses.dart';

class SkillReflectionScreen extends StatelessWidget {
  final UserResponses userResponse;

  const SkillReflectionScreen({super.key, required this.userResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Skill Reflection Test',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SkillReflectionTest(userResponse: userResponse),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
