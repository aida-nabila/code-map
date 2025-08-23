class UserResponses {
  String educationLevel;
  String cgpa;
  String major;
  List<String> programmingLanguages;
  String courseworkExperience;
  String skillReflection;

  UserResponses({
    this.educationLevel = '',
    this.cgpa = '',
    this.major = '',
    List<String>? programmingLanguages,
    this.courseworkExperience = '',
    this.skillReflection = '',
    required Map<String, String> followUpAnswers,
  }) : programmingLanguages = programmingLanguages ?? [];

  Map<String, dynamic> toJson() => {
        "educationLevel": educationLevel,
        "cgpa": double.tryParse(cgpa),
        "major": major,
        "programmingLanguages": programmingLanguages,
        "courseworkExperience": courseworkExperience,
        "skillReflection": skillReflection,
      };
}

// Global shared object
UserResponses globalUserResponses = UserResponses(followUpAnswers: {});
