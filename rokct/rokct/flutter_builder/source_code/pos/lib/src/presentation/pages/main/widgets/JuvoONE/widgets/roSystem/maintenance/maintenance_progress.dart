
class MaintenanceProgress {
  final String vesselId;
  final String currentStage;
  final DateTime stageStartTime;

  MaintenanceProgress({
    required this.vesselId,
    required this.currentStage,
    required this.stageStartTime,
  });

  Map<String, dynamic> toJson() => {
    'vesselId': vesselId,
    'currentStage': currentStage,
    'stageStartTime': stageStartTime.toIso8601String(),
  };

  factory MaintenanceProgress.fromJson(Map<String, dynamic> json) {
    return MaintenanceProgress(
      vesselId: json['vesselId'],
      currentStage: json['currentStage'],
      stageStartTime: DateTime.parse(json['stageStartTime']),
    );
  }
}
