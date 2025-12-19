class JobModel {
  final int id;
  final String title;
  final String description;
  final String status; // open/assigned/done etc
  final String budget;
  final String city;
  final String area;
  final String createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.budget,
    required this.city,
    required this.area,
    required this.createdAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) => int.tryParse(v?.toString() ?? "") ?? 0;

    return JobModel(
      id: toInt(j["id"]),
      title: (j["title"] ?? j["job_title"] ?? "").toString(),
      description: (j["description"] ?? j["details"] ?? "").toString(),
      status: (j["status"] ?? "open").toString(),
      budget: (j["budget"] ?? j["price"] ?? j["amount"] ?? "").toString(),
      city: (j["city"] ?? "").toString(),
      area: (j["area_name"] ?? j["area"] ?? "").toString(),
      createdAt: (j["created_at"] ?? j["createdAt"] ?? "").toString(),
    );
  }
}
