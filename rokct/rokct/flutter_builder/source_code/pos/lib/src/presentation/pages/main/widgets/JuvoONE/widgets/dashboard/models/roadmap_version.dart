class RoadmapVersion {
  final String id;
  final String uuid;
  final String appId;
  final String versionNumber;
  final String status;
  final String? description;
  final List<String> features;
  final DateTime? releaseDate;

  RoadmapVersion({
    required this.id,
    required this.uuid,
    required this.appId,
    required this.versionNumber,
    required this.status,
    this.description,
    required this.features,
    this.releaseDate,
  });

  factory RoadmapVersion.fromJson(Map<String, dynamic> json) {
    List<String> featuresList = [];
    if (json['features'] != null) {
      featuresList = List<String>.from(json['features']);
    }

    return RoadmapVersion(
      id: json['id'].toString(),
      uuid: json['uuid'],
      appId: json['app_id'].toString(),
      versionNumber: json['version_number'],
      status: json['status'],
      description: json['description'],
      features: featuresList,
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'app_id': appId,
      'version_number': versionNumber,
      'status': status,
      'description': description,
      'features': features,
      'release_date': releaseDate?.toIso8601String(),
    };
  }
}
