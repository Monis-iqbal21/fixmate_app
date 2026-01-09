import 'package:flutter/material.dart';

class JobModel {
  final int id;
  final int clientId;

  final String title;
  final String description;

  /// raw status from DB like: open/live/completed/deleted/cancelled
  final String status;

  final String budget;
  final String city;
  final String area;
  final String createdAt;

  final String? category;
  final int bidCount;

  final int? hiredWorkerId; // null if not assigned
  final bool workerMarkedDone;
  final bool clientMarkedDone;
  final DateTime? deadline;

  /// Worker-side: my bid id if I already bid on this job
  final int? myBidId;

  /// review flags (returned by list.php / myjob.php)
  final int? clientReviewId;
  final int? workerReviewId;

  String get location => area;
  bool get hasMyBid => (myBidId ?? 0) > 0;

  /// Job completed only when BOTH confirmed
  bool get isCompleted => workerMarkedDone && clientMarkedDone;

  bool get isAssigned => (hiredWorkerId ?? 0) > 0;

  JobModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.status,
    required this.budget,
    required this.city,
    required this.area,
    required this.createdAt,
    this.category,
    required this.bidCount,
    this.hiredWorkerId,
    required this.workerMarkedDone,
    required this.clientMarkedDone,
    this.deadline,
    this.myBidId,
    this.clientReviewId,
    this.workerReviewId,
  });

  factory JobModel.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) => int.tryParse(v?.toString() ?? "") ?? 0;

    final hiredId = (j["hired_worker_id"] ?? j["hiredWorkerId"]);
    final workerDone = (j["worker_marked_done"] ?? j["workerMarkedDone"] ?? 0);
    final clientDone = (j["client_marked_done"] ?? j["clientMarkedDone"] ?? 0);

    return JobModel(
      id: toInt(j["id"]),
      clientId: toInt(j["client_id"]),

      title: (j["title"] ?? j["job_title"] ?? "").toString(),
      description: (j["description"] ?? j["details"] ?? "").toString(),
      status: (j["status"] ?? "open").toString(),

      budget: (j["budget"] ?? j["price"] ?? j["amount"] ?? "").toString(),
      city: (j["city"] ?? "").toString(),
      area: (j["area_name"] ?? j["area"] ?? j["location"] ?? "").toString(),
      createdAt: (j["created_at"] ?? j["createdAt"] ?? "").toString(),

      category: j["category"]?.toString(),
      bidCount: toInt(j["bid_count"]),
      hiredWorkerId: hiredId == null ? null : toInt(hiredId),

      workerMarkedDone: workerDone.toString() == "1",
      clientMarkedDone: clientDone.toString() == "1",

      deadline: j["deadline"] != null
          ? DateTime.tryParse(j["deadline"].toString())
          : null,

      myBidId: j["my_bid_id"] == null ? null : toInt(j["my_bid_id"]),

      clientReviewId: j["client_review_id"] == null
          ? null
          : toInt(j["client_review_id"]),
      workerReviewId: j["worker_review_id"] == null
          ? null
          : toInt(j["worker_review_id"]),
    );
  }

  /// ✅ who is allowed to review this job?
  bool canReview({
    required String viewerRole, // 'client' or 'worker'
    required int viewerUserId,
  }) {
    if (!isCompleted) return false; // reviews only after completed

    if (viewerRole == 'client') {
      return viewerUserId == clientId;
    }

    // worker must be the HIRED worker
    return (hiredWorkerId ?? 0) == viewerUserId;
  }

  bool hasReviewed({required String viewerRole, required int viewerUserId}) {
    if (!canReview(viewerRole: viewerRole, viewerUserId: viewerUserId)) {
      return false;
    }
    if (viewerRole == 'client') return (clientReviewId ?? 0) > 0;
    return (workerReviewId ?? 0) > 0;
  }

  bool reviewPending({required String viewerRole, required int viewerUserId}) {
    if (!canReview(viewerRole: viewerRole, viewerUserId: viewerUserId)) {
      return false;
    }
    return !hasReviewed(viewerRole: viewerRole, viewerUserId: viewerUserId);
  }

  /// ✅ Status used in LIST screen
  Map<String, dynamic> getStatusDisplay({
    required String viewerRole, // 'client' or 'worker'
    required int viewerUserId,
  }) {
    if (isCompleted) {
      return {'text': 'Completed', 'color': Colors.indigo};
    }

    final hired = (hiredWorkerId ?? 0) > 0;

    if (hired) {
      if (workerMarkedDone && !clientMarkedDone) {
        return {
          'text': viewerRole == 'client'
              ? 'Your confirmation pending'
              : 'Waiting for client confirmation',
          'color': Colors.orange,
        };
      }

      if (!workerMarkedDone && clientMarkedDone) {
        return {
          'text': viewerRole == 'worker'
              ? 'Your confirmation pending'
              : 'Waiting for vendor confirmation',
          'color': Colors.orange,
        };
      }

      return {'text': 'Assigned', 'color': Colors.blue};
    }

    return {'text': 'Live', 'color': Colors.green};
  }

  /// ✅ Extra badges:
  /// Worker: Bid Sent, Hired you
  /// Both: Review Pending/Reviewed (ONLY if viewer is eligible)
  List<Map<String, dynamic>> extraBadges({
    required String viewerRole,
    required int viewerUserId,
  }) {
    final badges = <Map<String, dynamic>>[];

    if (viewerRole == 'worker' && myBidId != null) {
      badges.add({'text': 'Bid sent', 'color': Colors.deepPurple});
    }

    if (viewerRole == 'worker' &&
        (hiredWorkerId ?? 0) == viewerUserId &&
        (hiredWorkerId ?? 0) > 0) {
      badges.add({'text': 'Hired you', 'color': Colors.teal});
    }

    // ✅ Review badges only for the client owner OR hired worker
    if (reviewPending(viewerRole: viewerRole, viewerUserId: viewerUserId)) {
      badges.add({'text': 'Review pending', 'color': Colors.redAccent});
    } else if (hasReviewed(
      viewerRole: viewerRole,
      viewerUserId: viewerUserId,
    )) {
      badges.add({'text': 'Reviewed', 'color': Colors.green});
    }

    return badges;
  }
}
