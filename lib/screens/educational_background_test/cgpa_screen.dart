import 'package:flutter/material.dart';
import '../../models/user_responses.dart';
import 'major_screen.dart';

class CgpaScreen extends StatefulWidget {
  final UserResponses userResponse;

  const CgpaScreen({super.key, required this.userResponse});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  final TextEditingController cgpaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Current CGPA")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "What is your current CGPA?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: cgpaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "What is your current CGPA?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (cgpaController.text.isNotEmpty) {
                  widget.userResponse.cgpa = cgpaController.text;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MajorScreen(userResponse: widget.userResponse),
                    ),
                  );
                }
              },
              child: const Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
