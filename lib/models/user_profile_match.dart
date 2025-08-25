class JobMatch {
  final int userTestId;
  final int jobIndex;
  final double similarityScore;
  final double similarityPercentage;
  final String jobTitle;
  final String jobDescription;
  final List<String> requiredSkills;
  final List<String> requiredKnowledge;

  JobMatch(
      {required this.userTestId,
      required this.jobIndex,
      required this.similarityScore,
      required this.similarityPercentage,
      required this.jobTitle,
      required this.jobDescription,
      required this.requiredSkills,
      required this.requiredKnowledge});

  factory JobMatch.fromJson(Map<String, dynamic> json) => JobMatch(
        userTestId: json["user_test_id"] as int? ?? 0,
        jobIndex: json["job_index"] as int? ?? 0,
        similarityScore: (json["similarity_score"] as num?)?.toDouble() ?? 0.0,
        similarityPercentage:
            (json["similarity_percentage"] as num?)?.toDouble() ?? 0.0,
        jobTitle: json["job_title"] as String? ?? 'N/A',
        jobDescription: json["job_description"] as String? ?? 'N/A',
        requiredSkills: (json["required_skills"] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        requiredKnowledge: (json["required_knowledge"] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class UserProfileMatchResponse {
  final String profileText;
  final List<JobMatch> topMatches;

  UserProfileMatchResponse({
    required this.profileText,
    required this.topMatches,
  });

  factory UserProfileMatchResponse.fromJson(Map<String, dynamic> json) =>
      UserProfileMatchResponse(
        profileText:
            json["profile_text"] as String? ?? "Career profile analysis",
        topMatches: (json["top_matches"] as List<dynamic>)
            .map((e) => JobMatch.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
