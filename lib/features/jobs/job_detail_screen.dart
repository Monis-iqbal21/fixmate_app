import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_colors.dart';
import '../../core/api_config.dart';
import '../../core/storage.dart';
import 'jobs_api.dart';
import 'job_create_screen.dart';
import 'job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = true;

  Map<String, dynamic>? _job;
  List<Map<String, dynamic>> _media = [];
  List<Map<String, dynamic>> _bids = [];

  Map<String, dynamic>? _myBid;
  int _workerCredits = 0;

  // NOTE: your detail.php screenshot returns ONLY { job: {...} }
  // so these will be null unless your API also returns them.
  Map<String, dynamic>? _clientReview;
  Map<String, dynamic>? _workerReview;

  String _userRole = "client";
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ----------------------------
  // DATA LOADING + SORTING
  // ----------------------------
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final role = await AppStorage.getRole();
      final uid = await AppStorage.getUserId();

      final jobData = await JobsApi.detail(widget.jobId);
      final mediaData = await JobsApi.mediaList(widget.jobId);
      final allBids = await JobsApi.getBids(widget.jobId);

      // ✅ reviews only from reviewsByJob endpoint
      Map<String, dynamic> reviewsPayload = {};
      try {
        reviewsPayload = await JobsApi.reviewsByJob(widget.jobId);
      } catch (e) {
        debugPrint("reviewsByJob failed: $e");
        reviewsPayload = {};
      }

      // Sort bids latest first
      allBids.sort((a, b) {
        final da = DateTime.tryParse((a['created_at'] ?? '').toString());
        final db = DateTime.tryParse((b['created_at'] ?? '').toString());
        if (da != null && db != null) return db.compareTo(da);

        final ia = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
        final ib = int.tryParse((b['id'] ?? '0').toString()) ?? 0;
        return ib.compareTo(ia);
      });

      int credits = 0;
      Map<String, dynamic>? myBidData;

      if (role == 'worker') {
        final index = allBids.indexWhere(
          (b) => b['worker_id'].toString() == uid.toString(),
        );
        if (index != -1) {
          myBidData = allBids.removeAt(index);
          allBids.insert(0, myBidData);
        }

        try {
          credits = await JobsApi.myCredits();
        } catch (_) {
          credits = 0;
        }
      }

      final cReview = reviewsPayload['client_review'];
      final wReview = reviewsPayload['worker_review'];

      if (!mounted) return;
      setState(() {
        _userRole = role ?? "client";
        _currentUserId = uid ?? 0;

        _job = jobData;

        _media = (mediaData is List)
            ? mediaData.map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];

        _bids = allBids;
        _myBid = myBidData;

        _clientReview = (cReview is Map)
            ? Map<String, dynamic>.from(cReview)
            : null;
        _workerReview = (wReview is Map)
            ? Map<String, dynamic>.from(wReview)
            : null;

        _workerCredits = credits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading job details: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ----------------------------
  // LOGIC HELPERS
  // ----------------------------
  bool get _isClient => _userRole == 'client';
  bool get _isWorker => _userRole == 'worker';

  bool get _hasHiredWorker =>
      (_job?['hired_worker_id'] != null &&
      _job?['hired_worker_id'].toString() != '0');

  bool get _workerConfirmed => (_job?['worker_marked_done']?.toString() == '1');
  bool get _clientConfirmed => (_job?['client_marked_done']?.toString() == '1');

  bool get _isJobCompleted =>
      (_job?['worker_marked_done']?.toString() == '1') &&
      (_job?['client_marked_done']?.toString() == '1');

  bool get _canClientReview =>
      _isClient && _isJobCompleted && _hasHiredWorker && _clientReview == null;

  bool get _canWorkerReview =>
      _isAssignedToMe && _isJobCompleted && _workerReview == null;

  bool get _isJobDeleted => (_job?['status'] ?? '').toString() == 'deleted';

  bool get _isAssignedToMe =>
      _isWorker &&
      (_job?['hired_worker_id']?.toString() == _currentUserId.toString());

  bool get _isAssignable {
    if (!_isClient) return false;
    if (_hasHiredWorker) return false;
    final s = (_job?['status'] ?? '').toString();
    return ![
      'completed',
      'completion_pending',
      'cancelled',
      'deleted',
      'expired',
    ].contains(s);
  }

  bool get _canBid =>
      _isWorker &&
      !_hasHiredWorker &&
      !_isJobCompleted &&
      ((_job?['status'] ?? '').toString() == 'open' ||
          (_job?['status'] ?? '').toString() == 'live');

  bool get _canMarkDone =>
      _isAssignedToMe &&
      !_workerConfirmed &&
      !_isJobCompleted &&
      !['cancelled', 'deleted'].contains((_job?['status'] ?? '').toString());

  bool get _canReviewClient =>
      _isAssignedToMe && _isJobCompleted && _workerReview == null;

  bool get _canReviewWorker =>
      _isClient && _isJobCompleted && _clientReview == null;

  String get _clientName => (_job?['client_name'] ?? 'Client').toString();
  String get _workerName => (_job?['hired_worker_name'] ?? 'Worker').toString();

  // ----------------------------
  // MEDIA HELPERS
  // ----------------------------
  String _absUrl(String filePath) {
    final host = ApiConfig.host.trim().replaceAll(RegExp(r'\/+$'), '');
    final p = filePath.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return "$host$p";
    return "$host/$p";
  }

  List<Map<String, dynamic>> get _imageVideoMedia => _media.where((m) {
    final t = (m['media_type'] ?? '').toString().toLowerCase();
    return t == 'image' || t == 'video';
  }).toList();

  List<Map<String, dynamic>> get _audioMedia => _media
      .where((m) => (m['media_type'] ?? '').toString().toLowerCase() == 'audio')
      .toList();

  // ----------------------------
  // ACTIONS
  // ----------------------------
  Future<void> _submitNewBid(
    double amount,
    int credits,
    String time,
    bool materials,
    String msg,
  ) async {
    if (_workerCredits < credits) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Insufficient credits.")));
      return;
    }

    final success = await JobsApi.placeBid(
      widget.jobId,
      amount,
      msg,
      credits,
      time,
      materials,
    );

    if (success) {
      if (mounted) Navigator.pop(context);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proposal submitted successfully.")),
      );
    }
  }

  Future<void> _updateMyBid({
    required double newAmount,
    required String newTime,
    required bool newMaterials,
    required String newMsg,
  }) async {
    if (_myBid == null) return;

    final changes = <String, dynamic>{};

    final oldAmount = (_myBid!['bid_amount'] ?? '').toString();
    if (oldAmount != newAmount.toString()) changes['bid_amount'] = newAmount;

    final oldMsg = (_myBid!['message'] ?? _myBid!['proposal_text'] ?? '')
        .toString();
    if (oldMsg != newMsg.trim()) changes['message'] = newMsg.trim();

    final oldTime = (_myBid!['time_estimate'] ?? '').toString();
    if (oldTime != newTime.trim()) changes['time_estimate'] = newTime.trim();

    final oldMat = (_myBid!['include_materials'].toString() == '1');
    if (oldMat != newMaterials)
      changes['include_materials'] = newMaterials ? 1 : 0;

    if (changes.isEmpty) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No changes to update.")));
      return;
    }

    final bidId = int.tryParse(_myBid!['id'].toString()) ?? 0;
    if (bidId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid bid id.")));
      return;
    }

    final success = await JobsApi.updateBid(bidId, changes);

    if (success) {
      if (mounted) Navigator.pop(context);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proposal updated successfully.")),
      );
    }
  }

  Future<void> _markWorkerDone() async {
    final success = await JobsApi.workerMarkDone(widget.jobId);
    if (success) _loadData();
  }

  Future<void> _assignWorker(int bidId, String workerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Assignment"),
        content: Text("Assign job to $workerName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Assign"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await JobsApi.assignWorker(widget.jobId, bidId);
      if (success) _loadData();
    }
  }

  Future<void> _markCompleted() async {
    final success = await JobsApi.markComplete(widget.jobId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Job marked completed!")));
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to confirm job completion.")),
      );
    }
  }

  void _showReviewModal() {
    final clientName = (_job?['client_name'] ?? _job?['client'] ?? 'Client')
        .toString();
    final workerName =
        (_job?['hired_worker_name'] ?? _job?['worker_name'] ?? 'Worker')
            .toString();

    // who am I reviewing?
    final revieweeName = _isWorker ? clientName : workerName;
    final roleLabel = _isWorker ? "Worker" : "Client";

    showDialog(
      context: context,
      builder: (_) => _ReviewDialog(
        jobId: widget.jobId,
        onSubmit: _loadData,
        reviewerRoleLabel: roleLabel,
        revieweeName: revieweeName,
      ),
    );
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat feature coming soon...")),
    );
  }

  void _openGallery(int initialIndex) {
    final items = _imageVideoMedia;
    if (items.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _MediaGalleryDialog(
        items: items,
        initialIndex: initialIndex,
        absUrl: _absUrl,
      ),
    );
  }

  // ✅ Bid Dialog (New / Edit)
  void _showBidDialog({bool isEdit = false}) {
    final amountCtrl = TextEditingController(
      text: (isEdit && _myBid != null) ? _myBid!['bid_amount'].toString() : '',
    );
    final msgCtrl = TextEditingController(
      text: (isEdit && _myBid != null)
          ? (_myBid!['message'] ?? _myBid!['proposal_text'] ?? '')
          : '',
    );
    final timeCtrl = TextEditingController(
      text: (isEdit && _myBid != null) ? (_myBid!['time_estimate'] ?? '') : '',
    );

    bool includeMaterials = (isEdit && _myBid != null)
        ? (_myBid!['include_materials'].toString() == '1')
        : false;

    final int requiredCredits =
        int.tryParse(_job?['credits_required'].toString() ?? '1') ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? "Edit your proposal" : "Submit a proposal",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Available credits: $_workerCredits",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label("Your bid amount (PKR) *"),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco("3000"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label("Credits *"),
                          const SizedBox(height: 6),
                          TextField(
                            enabled: false,
                            controller: TextEditingController(
                              text: requiredCredits.toString(),
                            ),
                            decoration: _inputDeco("1"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label("Estimated time"),
                const SizedBox(height: 6),
                TextField(
                  controller: timeCtrl,
                  decoration: _inputDeco("e.g. 2 days"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: includeMaterials,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) =>
                            setDialogState(() => includeMaterials = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Price includes materials",
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label("Message to client *"),
                const SizedBox(height: 6),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: _inputDeco("Explain your experience..."),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;

                      if (amount <= 0 || msgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter amount + message."),
                          ),
                        );
                        return;
                      }

                      if (!isEdit || _myBid == null) {
                        await _submitNewBid(
                          amount,
                          requiredCredits,
                          timeCtrl.text,
                          includeMaterials,
                          msgCtrl.text,
                        );
                      } else {
                        await _updateMyBid(
                          newAmount: amount,
                          newTime: timeCtrl.text,
                          newMaterials: includeMaterials,
                          newMsg: msgCtrl.text,
                        );
                      }
                    },
                    icon: Icon(
                      isEdit ? Icons.save : Icons.send_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      isEdit ? "Update proposal" : "Submit proposal",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF564BF0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Client Edit Job Post
  Future<void> _editJobPost() async {
    if (_job == null) return;
    final jobModel = JobModel.fromJson(_job!);
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobCreateScreen(jobToEdit: jobModel)),
    );
    if (res == true) _loadData();
  }

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        text: text.replaceAll('*', ''),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: [
          if (text.contains('*'))
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF564BF0)),
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle() {
    String status = (_job?['status'] ?? 'open').toString();
    final deadlineStr = _job?['deadline'];

    if (deadlineStr != null && status == 'open') {
      final deadline = DateTime.tryParse(deadlineStr.toString());
      if (deadline != null && DateTime.now().isAfter(deadline))
        status = 'expired';
    }

    if (_workerConfirmed && _clientConfirmed) {
      return {
        'text': 'Completed',
        'bg': Colors.indigo.shade50,
        'color': Colors.indigo,
      };
    }
    if (_workerConfirmed && !_clientConfirmed) {
      return {
        'text': 'Waiting for client confirmation',
        'bg': Colors.amber.shade50,
        'color': Colors.amber.shade800,
      };
    }
    if (_clientConfirmed && !_workerConfirmed) {
      return {
        'text': 'Client confirmed • waiting for you',
        'bg': Colors.indigo.shade50,
        'color': Colors.indigo.shade800,
      };
    }
    if (_isAssignedToMe &&
        !['completed', 'cancelled', 'deleted'].contains(status)) {
      return {
        'text': 'Assigned to you',
        'bg': Colors.blue.shade50,
        'color': Colors.blue.shade800,
      };
    }
    if (_hasHiredWorker && !_isAssignedToMe) {
      return {
        'text': 'Assigned to another worker',
        'bg': Colors.grey.shade200,
        'color': Colors.grey.shade600,
      };
    }

    switch (status) {
      case 'cancelled':
        return {
          'text': 'Cancelled',
          'bg': Colors.grey.shade200,
          'color': Colors.grey.shade700,
        };
      case 'deleted':
        return {
          'text': 'Deleted',
          'bg': Colors.grey.shade300,
          'color': Colors.grey.shade800,
        };
      case 'expired':
        return {
          'text': 'Expired',
          'bg': Colors.red.shade50,
          'color': Colors.red.shade700,
        };
      default:
        return {
          'text': 'Live',
          'bg': Colors.green.shade50,
          'color': Colors.green.shade700,
        };
    }
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_job == null) {
      return const Scaffold(body: Center(child: Text("Job not found")));
    }

    final statusStyle = _getStatusStyle();

    DateTime? created;
    final createdStr = (_job!['created_at'] ?? '').toString();
    if (createdStr.isNotEmpty) created = DateTime.tryParse(createdStr);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Job Details"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Header ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_job!['title'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Badge(
                              text: statusStyle['text'],
                              color: statusStyle['color'],
                              bg: statusStyle['bg'],
                            ),
                            if (_isWorker)
                              _Badge(
                                text: "Balance: $_workerCredits",
                                color: Colors.grey.shade700,
                                bg: Colors.grey.shade100,
                                icon: Icons.account_balance_wallet,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Posted by: $_clientName",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. Worker action bar ---
              if (_isWorker) ...[
                if (_canBid)
                  if (_myBid == null)
                    _ActionButton(
                      label: "Bid on this Job",
                      icon: Icons.handshake,
                      color: Colors.indigo,
                      onTap: () => _showBidDialog(isEdit: false),
                    )
                  else
                    _ActionButton(
                      label: "Edit Proposal",
                      icon: Icons.edit,
                      color: Colors.indigo,
                      onTap: () => _showBidDialog(isEdit: true),
                    ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text("Message Client"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_canMarkDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ActionButton(
                      label: "Mark Job as Done",
                      icon: Icons.check_circle,
                      color: Colors.teal,
                      onTap: _markWorkerDone,
                    ),
                  ),
                if (_canWorkerReview)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ActionButton(
                      label: "Review Client",
                      icon: Icons.star,
                      color: Colors.green,
                      onTap: _showReviewModal,
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // --- 3. Main Info ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconText(Icons.person, _clientName, isBold: true),
                    if (_job!['location'] != null)
                      _iconText(
                        Icons.location_on,
                        (_job!['location']).toString(),
                      ),
                    if (_job!['category'] != null)
                      _iconText(Icons.category, (_job!['category']).toString()),
                    if (created != null)
                      _iconText(
                        Icons.calendar_today,
                        "Posted: ${DateFormat('MMM dd, yyyy').format(created)}",
                      ),
                    const Divider(height: 24),
                    const Text(
                      "Job Description:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (_job!['description'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // --- 4. Attachments (Images/Videos gallery) ---
              if (_imageVideoMedia.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Attachments",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageVideoMedia.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final m = _imageVideoMedia[index];
                      final type = (m['media_type'] ?? '')
                          .toString()
                          .toLowerCase();
                      final url = _absUrl((m['file_path'] ?? '').toString());

                      return InkWell(
                        onTap: () => _openGallery(index),
                        child: Container(
                          width: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            color: Colors.grey.shade50,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (type == 'image')
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  )
                                else
                                  Container(
                                    color: Colors.black12,
                                    child: const Center(
                                      child: Icon(Icons.videocam, size: 34),
                                    ),
                                  ),
                                if (type == 'video')
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // --- 4b. Voice notes (audio) ---
              if (_audioMedia.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  "Voice notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._audioMedia.map((m) {
                  final url = _absUrl((m['file_path'] ?? '').toString());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VoiceNoteTile(url: url),
                  );
                }),
              ],

              // --- 5. Job Overview ---
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Job Overview",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _statRow(
                      "Assigned to",
                      _hasHiredWorker ? _workerName : "Not assigned yet",
                    ),
                    _statRow(
                      "Budget",
                      "Rs ${_job!['price']}",
                      valueColor: Colors.green,
                    ),
                    _statRow("Credits per bid", "${_job!['credits_required']}"),
                    _statRow(
                      "Has media",
                      (_job!['has_media'].toString() == '1') ? "Yes" : "No",
                    ),
                    if (_isClient &&
                        !_hasHiredWorker &&
                        !_isJobCompleted &&
                        !_isJobDeleted) ...[
                      const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _editJobPost,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Edit Job Post"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // --- 6. Client completion/review actions ---
              if (_isClient && !_isJobDeleted) ...[
                const SizedBox(height: 20),
                if (_hasHiredWorker && !_isJobCompleted) ...[
                  if (_workerConfirmed)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Worker marked this job as done. Confirm?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _markCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text(
                        "Confirm Job Completed",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if (_isJobCompleted && _hasHiredWorker) ...[
                  if (_canClientReview)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showReviewModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                        child: const Text(
                          "Leave a Review",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        "You have already submitted your review.",
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],

              // --- 7. Bids list ---
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Proposals / Bids",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "${_bids.length} bid(s)",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_bids.isEmpty)
                const Text("No bids yet.", style: TextStyle(color: Colors.grey))
              else
                ..._bids.map((bid) => _buildBidCard(bid)).toList(),

              // --- 8. Reviews section (AT END, only when completed) ---
              if (_isJobCompleted) ...[
                const SizedBox(height: 24),
                const Text(
                  "Reviews",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

                // Client review card OR pending
                if (_clientReview != null)
                  _buildReviewCard(
                    "$_clientName's Review",
                    _clientReview,
                    isSent: true,
                  )
                else
                  _pendingReviewTile("Review pending of $_clientName"),

                const SizedBox(height: 10),

                // Worker review card OR pending
                if (_workerReview != null)
                  _buildReviewCard(
                    "$_workerName's Review",
                    _workerReview,
                    isSent: false,
                  )
                else
                  _pendingReviewTile("Review pending of $_workerName"),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // WIDGETS
  // ----------------------------
  Widget _Badge({
    required String text,
    required Color color,
    required Color bg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isBold ? Colors.black : Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingReviewTile(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String title,
    Map<String, dynamic>? review, {
    required bool isSent,
  }) {
    final statusColor = review != null ? Colors.green : Colors.amber;
    final statusText = review != null ? "Submitted" : "Pending";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSent ? Colors.grey.shade50 : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (review != null) ...[
            const SizedBox(height: 6),
            Text(
              "Rating: ${review['rating']}/5",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if ((review['comment'] ?? '').toString().trim().isNotEmpty)
              Text(
                review['comment'].toString(),
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            if (review['created_at'] != null)
              Text(
                DateFormat(
                  'MMM dd, yyyy',
                ).format(DateTime.parse(review['created_at'].toString())),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBidCard(Map<String, dynamic> bid) {
    final isSelected = bid['status'].toString() == '1';
    final isRejected = bid['status'].toString() == '2';
    final isMyBid =
        _isWorker && bid['worker_id'].toString() == _currentUserId.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyBid ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? Colors.green.withOpacity(0.5)
              : (isMyBid
                    ? Colors.indigo.withOpacity(0.3)
                    : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    (bid['worker_name'] ?? 'Worker').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isMyBid)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "YOU",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (isSelected)
                const Chip(
                  label: Text(
                    "Selected",
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                  backgroundColor: Color(0xFFE8F5E9),
                  padding: EdgeInsets.all(0),
                  labelPadding: EdgeInsets.symmetric(horizontal: 8),
                )
              else if (isRejected)
                const Chip(
                  label: Text(
                    "Not Selected",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  backgroundColor: Color(0xFFF5F5F5),
                  padding: EdgeInsets.all(0),
                  labelPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (bid['message'] != null || bid['proposal_text'] != null)
            Text(
              (bid['message'] ?? bid['proposal_text']).toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rs ${bid['bid_amount']}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isAssignable && !isSelected && !isRejected && _isClient)
                ElevatedButton(
                  onPressed: () => _assignWorker(
                    int.parse(bid['id'].toString()),
                    (bid['worker_name'] ?? 'Worker').toString(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Assign",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------
// FULLSCREEN GALLERY (IMAGE/VIDEO SWIPE)
// ----------------------------
class _MediaGalleryDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;
  final String Function(String) absUrl;

  const _MediaGalleryDialog({
    required this.items,
    required this.initialIndex,
    required this.absUrl,
  });

  @override
  State<_MediaGalleryDialog> createState() => _MediaGalleryDialogState();
}

class _MediaGalleryDialogState extends State<_MediaGalleryDialog> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (context, i) {
              final m = widget.items[i];
              final type = (m['media_type'] ?? '').toString().toLowerCase();
              final url = widget.absUrl((m['file_path'] ?? '').toString());

              if (type == 'video') return _VideoViewer(url: url);

              return Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final String url;
  const _VideoViewer({required this.url});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _vc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vc!.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _vc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPlaying = _vc!.value.isPlaying;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _vc!.value.aspectRatio,
            child: VideoPlayer(_vc!),
          ),
        ),
        Positioned(
          bottom: 18,
          left: 16,
          right: 16,
          child: VideoProgressIndicator(_vc!, allowScrubbing: true),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isPlaying) {
                _vc!.pause();
              } else {
                _vc!.play();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------
// VOICE NOTE TILE (progress + play/pause + reset on finish)
// ----------------------------
class VoiceNoteTile extends StatefulWidget {
  final String url;
  const VoiceNoteTile({super.key, required this.url});

  @override
  State<VoiceNoteTile> createState() => _VoiceNoteTileState();
}

class _VoiceNoteTileState extends State<VoiceNoteTile> {
  late final AudioPlayer _player;

  Duration _duration = Duration.zero;
  Duration _pos = Duration.zero;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool _loading = true;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);

      _duration = _player.duration ?? Duration.zero;

      _durSub = _player.durationStream.listen((d) {
        if (!mounted) return;
        setState(() => _duration = d ?? Duration.zero);
      });

      _posSub = _player.positionStream.listen((d) {
        if (!mounted) return;
        setState(() => _pos = d);
      });

      _stateSub = _player.playerStateStream.listen((s) async {
        if (!mounted) return;

        final completed = s.processingState == ProcessingState.completed;
        final playing = s.playing;

        if (completed) {
          await _player.seek(Duration.zero);
          await _player.pause();
          if (!mounted) return;
          setState(() {
            _playing = false;
            _pos = Duration.zero;
          });
          return;
        }

        setState(() => _playing = playing);
      });

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Voice note load error: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return "${two(m)}:${two(s)}";
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds;
    final posMs = _pos.inMilliseconds.clamp(0, maxMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _loading
                ? null
                : () async {
                    if (_playing) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                  },
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _loading
                    ? Icons.hourglass_empty
                    : (_playing ? Icons.pause : Icons.play_arrow),
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.orange,
                    thumbColor: Colors.orange,
                    overlayColor: Colors.orange.withOpacity(0.15),
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                  child: Slider(
                    value: posMs.toDouble(),
                    min: 0,
                    max: maxMs.toDouble(),
                    onChanged: _loading
                        ? null
                        : (v) =>
                              _player.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_pos),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      _fmt(_duration),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------
// REVIEW DIALOG (with confirmation: non-editable)
// ----------------------------
class _ReviewDialog extends StatefulWidget {
  final int jobId;
  final VoidCallback onSubmit;
  final String reviewerRoleLabel; // "Client" or "Worker"
  final String revieweeName; // who you are reviewing (name)

  const _ReviewDialog({
    required this.jobId,
    required this.onSubmit,
    required this.reviewerRoleLabel,
    required this.revieweeName,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;

    final text = _comment.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please write a comment.")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Review"),
        content: const Text(
          "Once submitted, this review cannot be edited. Do you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    final ok = await JobsApi.submitReview(widget.jobId, _rating, text);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context); // ✅ close dialog
      widget.onSubmit(); // ✅ refresh job detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Review submitted for ${widget.revieweeName}.")),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit review. Try again.")),
      );
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Leave a Review (${widget.reviewerRoleLabel})"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Reviewing: ${widget.revieweeName}",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          TextField(
            controller: _comment,
            enabled: !_submitting,
            decoration: const InputDecoration(
              hintText: "Share your experience...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : _submit, // ✅ disabled while submitting
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
}
