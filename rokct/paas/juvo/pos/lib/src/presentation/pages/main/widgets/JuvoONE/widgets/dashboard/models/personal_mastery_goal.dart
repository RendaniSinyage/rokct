// lib/models/personal_mastery_goal.dart
class PersonalMasteryGoal {
  final String id;
  final String uuid;
  final String userId;
  final String area;
  final String title;
  final String? description;
  final String? relatedObjectiveId;
  final DateTime? targetDate;
  final String status;

  PersonalMasteryGoal({
    required this.id,
    required this.uuid,
    required this.userId,
    required this.area,
    required this.title,
    this.description,
    this.relatedObjectiveId,
    this.targetDate,
    required this.status,
  });

  factory PersonalMasteryGoal.fromJson(Map<String, dynamic> json) {
    return PersonalMasteryGoal(
      id: json['id'].toString(),
      uuid: json['uuid'],
      userId: json['user_id'].toString(),
      area: json['area'],
      title: json['title'],
      description: json['description'],
      relatedObjectiveId: json['related_objective_id']?.toString(),
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'user_id': userId,
      'area': area,
      'title': title,
      'description': description,
      'related_objective_id': relatedObjectiveId,
      'target_date': targetDate?.toIso8601String(),
      'status': status,
    };
  }
}
