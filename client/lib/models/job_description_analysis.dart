class JobDescriptionAnalysis {
  final List<String> requiredSkills;
  final List<String> desiredSkills;
  final String experienceLevel;
  final List<String> domainKnowledge;
  final List<String> softSkills;
  final List<String> technologies;
  
  JobDescriptionAnalysis({
    required this.requiredSkills,
    required this.desiredSkills,
    required this.experienceLevel,
    required this.domainKnowledge,
    required this.softSkills,
    required this.technologies,
  });
  
  factory JobDescriptionAnalysis.fromJson(Map<String, dynamic> json) {
    return JobDescriptionAnalysis(
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      desiredSkills: List<String>.from(json['desired_skills'] ?? []),
      experienceLevel: json['experience_level'] ?? 'mid',
      domainKnowledge: List<String>.from(json['domain_knowledge'] ?? []),
      softSkills: List<String>.from(json['soft_skills'] ?? []),
      technologies: List<String>.from(json['technologies'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'required_skills': requiredSkills,
      'desired_skills': desiredSkills,
      'experience_level': experienceLevel,
      'domain_knowledge': domainKnowledge,
      'soft_skills': softSkills,
      'technologies': technologies,
    };
  }
}