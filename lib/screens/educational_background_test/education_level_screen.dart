import 'package:flutter/material.dart';
import '../../models/user_responses.dart';
import 'cgpa_screen.dart';

class EducationLevelScreen extends StatefulWidget {
  final UserResponses userResponse;

  const EducationLevelScreen({super.key, required this.userResponse});

  @override
  State<EducationLevelScreen> createState() => _EducationLevelScreenState();
}

class _EducationLevelScreenState extends State<EducationLevelScreen> {
  String? selectedLevel;

  final List<String> levels = [
    "SPM (Sijil Pelajaran Malaysia)",
    "STPM (Sijil Tinggi Persekolahan Malaysia)",
    "Diploma",
    "Undergraduate (Bachelor's Degree)",
    "Postgraduate (Master's Degree)"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Highest Education")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "What was your highest level of education?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                return ListTile(
                  title: Text(level),
                  tileColor:
                      selectedLevel == level ? Colors.lightGreenAccent : null,
                  onTap: () {
                    setState(() {
                      selectedLevel = level;
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedLevel != null) {
                widget.userResponse.educationLevel = selectedLevel!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CgpaScreen(userResponse: widget.userResponse),
                  ),
                );
              }
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
