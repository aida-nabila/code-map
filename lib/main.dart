import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/educational_background_test/educational_background_screen.dart';

Future<void> main() async {
  // Load environment variables before the app starts
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CodeMap: Navigate Your IT Future',
      home: EducationalBackgroundTestScreen(),
    );
  }
}
