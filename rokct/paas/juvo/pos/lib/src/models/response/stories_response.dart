import '../models.dart';

class StoriesResponse {
  List<StoriesData>? data;
  Meta? meta;

  StoriesResponse({
    this.data,
    this.meta,
  });

  StoriesResponse copyWith({
    List<StoriesData>? data,
    Meta? meta,
  }) =>
      StoriesResponse(
        data: data ?? this.data,
        meta: meta ?? this.meta,
      );

  factory StoriesResponse.fromJson(Map<String, dynamic> json) => StoriesResponse(
    data: json["data"] == null ? [] : List<StoriesData>.from(json["data"]!.map((x) => StoriesData.fromJson(x))),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}




