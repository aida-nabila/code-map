import 'package:flutter/material.dart';
import '../../../../models/user_responses.dart';
import '../../../../services/api_service.dart';
import 'follow_up_test.dart';

class FollowUpScreen extends StatelessWidget {
  final UserResponses userResponse;

  const FollowUpScreen({super.key, required this.userResponse});

  Future<void> _startFollowUp(BuildContext context) async {
    final skillReflection = userResponse.skillReflection;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Hang tight!\nWe’re generating your questions…",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Submit test -> backend creates userTestId (id in UserTest)
      final userTestId = await ApiService.submitTest(userResponse);

      // Generate follow-up questions
      final questions = await ApiService.generateQuestions(
        skillReflection: skillReflection,
        userTestId: userTestId,
      );

      print("Questions received: $questions");

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (questions.isNotEmpty) {
        // Navigate to FollowUpTest screen, pass userTestId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FollowUpTest(
              userTestId: userTestId,
              userResponse: userResponse,
              questions: questions,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No questions were generated.")),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Follow-up Test: Validate Your Skills',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startFollowUp(context),
                child: const Text('Start'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
