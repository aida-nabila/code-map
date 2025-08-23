import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/follow_up_responses.dart';
import '../models/user_profile_match.dart';
import '../models/user_responses.dart';

class ApiService {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? "http://localhost:8000";

  // Submit the initial test and return the generated userTestId
  static Future<int> submitTest(UserResponses responses) async {
    final url = Uri.parse("$baseUrl/submit-test");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(responses.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print("Submit Success: $decoded");
      return decoded['id'];
    } else {
      throw Exception("Submit Error: ${response.statusCode} ${response.body}");
    }
  }

  static Future<List<Map<String, dynamic>>> generateQuestions({
    required String skillReflection,
    required int userTestId,
  }) async {
    final url = Uri.parse("$baseUrl/generate-questions");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_test_id": userTestId}),
    );

    print("Raw questions response body: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded.containsKey('questions')) {
        final rawQuestions = decoded['questions'];
        if (rawQuestions is List) {
          return rawQuestions
              .where((q) => q != null && q is Map)
              .map((q) => Map<String, dynamic>.from(q))
              .map((q) {
            if (q['options'] == null ||
                (q['options'] is List && q['options'].isEmpty)) {
              q['options'] = ["Option A", "Option B", "Option C", "Option D"];
            }
            return q;
          }).toList();
        }
      }

      if (decoded.containsKey('error')) throw Exception(decoded['error']);
      throw Exception("Unexpected response format");
    } else {
      throw Exception("Error generating questions: ${response.body}");
    }
  }

  // Send follow-up answers to backend
  static Future<void> submitFollowUpResponses({
    required FollowUpResponses responses,
  }) async {
    final url = Uri.parse("$baseUrl/submit-follow-up");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(responses.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print("Follow-up Submit Success: $decoded");
    } else {
      throw Exception(
          "Follow-up Submit Error: ${response.statusCode} ${response.body}");
    }
  }

  // Get user profile + job match
  static Future<UserProfileMatchResponse?> getUserProfileMatch({
    required int userTestId,
    String? skillReflection,
  }) async {
    final url = Uri.parse("$baseUrl/user-profile-match");

    final body = {
      "user_test_id": userTestId,
      if (skillReflection != null) "skillReflection": skillReflection,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserProfileMatchResponse.fromJson(decoded);
    } else {
      print("Error ${response.statusCode}: ${response.body}");
      return null;
    }
  }
}
