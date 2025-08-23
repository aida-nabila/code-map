class FollowUpResponse {
  final int questionId;
  String? selectedOption;
  final int userTestId;

  FollowUpResponse({
    required this.questionId,
    required this.selectedOption,
    required this.userTestId,
  });

  Map<String, dynamic> toJson() {
    return {
      "questionId": questionId,
      "selectedOption": selectedOption,
      "user_test_id": userTestId, // backend expects snake_case
    };
  }
}

class FollowUpResponses {
  final List<FollowUpResponse> responses;

  FollowUpResponses({required this.responses});

  Map<String, dynamic> toJson() {
    return {
      "responses": responses.map((r) => r.toJson()).toList(),
    };
  }
}
