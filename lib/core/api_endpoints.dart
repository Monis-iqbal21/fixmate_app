import 'package:fixmate_app/core/api_client.dart';

class ApiEndpoints {
  static const login = "/auth/login.php";
  static const register = "/auth/register.php";
  static const me = "/auth/me.php";
  static const logout = "/auth/logout.php";

  static const jobsList = "/jobs/list.php";
  static const jobsDetail = "/jobs/detail.php";
  static const jobsCreate = "/jobs/create.php";
  static const updateJob = "/jobs/update-job.php";
  static const clientStats = "/jobs/client_stats.php";
  static const workerStats = "/jobs/worker_stats.php";
  static const jobsMediaUpload = "/jobs/media_upload.php";
  static const jobsMediaList = "/jobs/media_list.php";
  static const myJobs = "/jobs/myjob.php";
  static const String completeJob = "/jobs/complete-job.php";
  static const String deleteJob = "/jobs/delete-job.php";
  static const notifications = "/notification/notification.php";
  static const jobsGetBids = "/jobs/get_bids.php";
  static const placeBid = "/jobs/place_bid.php";
  static const updateBid = "/jobs/update_bid.php";
  static const assignWorker = "/jobs/assign_worker.php";
  static const submitReview = "/reviews/submit_review.php";
  static const myCredits = "/worker/my_credits.php";
  static const workerMarkDone = "/jobs/worker_mark_done.php";
  static const clientMarkDone = "/jobs/client_mark_done.php";
  static const reviewsByJob = "/jobs/reviews_by_job.php";
}
