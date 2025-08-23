import 'package:flutter/material.dart';
import 'education_level_screen.dart';
import '../../models/user_responses.dart';

class EducationalBackgroundTestScreen extends StatelessWidget {
  const EducationalBackgroundTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Educational Background Test',
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
                  // Create a new UserResponses instance
                  UserResponses userResponse =
                      UserResponses(followUpAnswers: {});

                  // Navigate to EducationScreen with the new object
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EducationLevelScreen(userResponse: userResponse),
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
