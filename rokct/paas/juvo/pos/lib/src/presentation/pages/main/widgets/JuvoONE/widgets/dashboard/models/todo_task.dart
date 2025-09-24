// models/todo_task.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TodoTask {
  final String uuid;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? kpiId;
  final String? objectiveId;
  final String? appId;
  final String? roadmapVersion;
  final String? tenderOcid;
  final Map<String, dynamic>? tenderData;
  final List<String>? platforms; // Added platforms field

  TodoTask({
    required this.uuid,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.kpiId,
    this.objectiveId,
    this.appId,
    this.roadmapVersion,
    this.tenderOcid,
    this.tenderData,
    this.platforms,
  });

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    // Handle tenderData parsing
    Map<String, dynamic>? parsedTenderData;
    if (json['tender_data'] != null) {
      if (json['tender_data'] is String) {
        try {
          parsedTenderData = jsonDecode(json['tender_data']);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing tender_data JSON: $e');
          }
          parsedTenderData = null;
        }
      } else if (json['tender_data'] is Map) {
        parsedTenderData = Map<String, dynamic>.from(json['tender_data']);
      }
    }

    // Handle platforms parsing
    List<String>? platforms;
    if (json['platforms'] != null) {
      if (json['platforms'] is String) {
        try {
          platforms = List<String>.from(jsonDecode(json['platforms']));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing platforms JSON: $e');
          }
          platforms = null;
        }
      } else if (json['platforms'] is List) {
        platforms = List<String>.from(json['platforms']);
      }
    }

    return TodoTask(
      uuid: json['uuid'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      assignedTo: json['assigned_to'] != null ? json['assigned_to'].toString() : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      kpiId: json['kpi_id'] != null ? json['kpi_id'].toString() : null,
      objectiveId: json['objective_id'] != null ? json['objective_id'].toString() : null,
      appId: json['app_id'] != null ? json['app_id'].toString() : null,
      roadmapVersion: json['roadmap_version'],
      tenderOcid: json['tender_ocid'],
      tenderData: parsedTenderData,
      platforms: platforms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'kpi_id': kpiId,
      'objective_id': objectiveId,
      'app_id': appId,
      'roadmap_version': roadmapVersion,
      'tender_ocid': tenderOcid,
      'tender_data': tenderData != null ? jsonEncode(tenderData) : null,
      'platforms': platforms != null ? jsonEncode(platforms) : null,
    };
  }

  // Check if the task is a tender task
  bool get isTenderTask => tenderOcid != null && tenderOcid!.isNotEmpty;

  // Check if the task has eSubmission available
  bool get hasESubmission {
    if (!isTenderTask || tenderData == null) return false;
    return tenderData!['hasESubmission'] == true;
  }

  // Get the eSubmission URL if available
  String? get eSubmissionUrl {
    if (!hasESubmission || tenderData == null) return null;
    return tenderData!['eSubmissionUrl'] as String?;
  }

  // Helper method to check if task is for a specific platform
  bool isPlatformTask(String platform) {
    return platforms != null && platforms!.contains(platform);
  }

  // Create a copy with updated fields
  TodoTask copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? assignedTo,
    DateTime? updatedAt,
    List<String>? platforms,
  }) {
    return TodoTask(
      uuid: uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kpiId: kpiId,
      objectiveId: objectiveId,
      appId: appId,
      roadmapVersion: roadmapVersion,
      tenderOcid: tenderOcid,
      tenderData: tenderData,
      platforms: platforms ?? this.platforms,
    );
  }
}
