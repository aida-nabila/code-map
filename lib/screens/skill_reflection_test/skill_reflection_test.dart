import 'package:flutter/material.dart';
import '../../models/user_responses.dart';
import '../follow_up_test/follow_up_screen.dart';

class SkillReflectionTest extends StatefulWidget {
  final UserResponses userResponse;

  const SkillReflectionTest({super.key, required this.userResponse});

  @override
  State<SkillReflectionTest> createState() => _SkillReflectionTestState();
}

class _SkillReflectionTestState extends State<SkillReflectionTest> {
  late TextEditingController _controller;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.userResponse.skillReflection);
    _charCount = _controller.text.length;

    _controller.addListener(() {
      setState(() {
        _charCount = _controller.text.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCompletePressed() {
    final text = _controller.text.trim(); // Remove leading/trailing spaces
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Skill reflection cannot be empty."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_charCount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please write at least 500 characters. Current count: $_charCount'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.userResponse.skillReflection = _controller.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowUpScreen(userResponse: widget.userResponse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skill Reflection")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "What IT skills and strengths are you most proud of, and why?",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      "In your own words, describe the skills you are most confident in. Mention any tools, programming languages, or technical concepts you are familiar with. You may also include soft skills, previous projects, or anything you believe showcases your strengths.",
                  hintMaxLines: 10,
                ),
                minLines: 20,
                maxLines: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text('Character count: $_charCount/500',
                textAlign: TextAlign.right),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onCompletePressed,
              child: const Text("Complete"),
            ),
          ],
        ),
      ),
    );
  }
}
