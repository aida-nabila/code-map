class JobMatch {
  final int userTestId;
  final int jobIndex;
  final double similarityScore;
  final double similarityPercentage;
  final String jobTitle;
  final String jobDescription;

  JobMatch({
    required this.userTestId,
    required this.jobIndex,
    required this.similarityScore,
    required this.similarityPercentage,
    required this.jobTitle,
    required this.jobDescription,
  });

  factory JobMatch.fromJson(Map<String, dynamic> json) => JobMatch(
        userTestId: json["user_test_id"],
        jobIndex: json["job_index"],
        similarityScore: (json["similarity_score"] as num).toDouble(),
        similarityPercentage: (json["similarity_percentage"] as num).toDouble(),
        jobTitle: json["job_title"],
        jobDescription: json["job_description"],
      );
}

class UserProfileMatchResponse {
  final String profileText;
  final List<JobMatch> topMatches;
  final Map<String, dynamic> combinedData;

  UserProfileMatchResponse({
    required this.profileText,
    required this.topMatches,
    required this.combinedData,
  });

  factory UserProfileMatchResponse.fromJson(Map<String, dynamic> json) =>
      UserProfileMatchResponse(
        profileText: json["profile_text"],
        topMatches: (json["top_matches"] as List)
            .map((e) => JobMatch.fromJson(e))
            .toList(),
        combinedData: Map<String, dynamic>.from(json["combined_data"]),
      );
}
