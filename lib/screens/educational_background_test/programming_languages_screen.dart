import 'package:flutter/material.dart';
import '../../models/user_responses.dart';
import 'coursework_screen.dart';

class ProgrammingLanguagesScreen extends StatefulWidget {
  final UserResponses userResponse; // <-- changed

  const ProgrammingLanguagesScreen({super.key, required this.userResponse});

  @override
  State<ProgrammingLanguagesScreen> createState() =>
      _ProgrammingLanguagesScreenState();
}

class _ProgrammingLanguagesScreenState
    extends State<ProgrammingLanguagesScreen> {
  final List<String> languages = [
    "Python",
    "Java",
    "JavaScript",
    "C",
    "C++",
    "C#",
    "PHP",
    "Ruby",
    "SQL",
    "Swift",
    "Kotlin",
    "Go (Golang)",
    "TypeScript",
    "R",
    "Dart",
    "MATLAB",
    "Rust",
    "Scala",
    "Perl",
    "Lua",
    "Julia",
    "F#",
    "Erlang",
    "Assembly",
    "SAS",
    "None"
  ];

  final List<String> selectedLanguages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Programming Languages")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "What programming languages have you learned?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguages.contains(lang);
                return ListTile(
                  title: Text(lang),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      isSelected
                          ? selectedLanguages.remove(lang)
                          : selectedLanguages.add(lang);
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.userResponse.programmingLanguages =
                  List.from(selectedLanguages);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseworkExperienceScreen(
                      userResponse: widget.userResponse),
                ),
              );
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
