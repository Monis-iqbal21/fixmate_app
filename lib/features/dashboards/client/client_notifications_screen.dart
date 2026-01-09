import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ Correct Imports
import '../../../core/api_config.dart'; 
import '../../../core/app_colors.dart';
import '../../../core/api_client.dart';
import '../../jobs/job_detail_screen.dart'; 

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() => _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  
  // Filters
  String _selectedType = 'all'; 
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(
        "/notification/notification.php?type=$_selectedType&filter=$_selectedStatus"
      );
      
      if (res.data['status'] == 'ok') {
        if (mounted) {
          setState(() {
            _notifications = res.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.post("/notification/notification.php", data: {"action": "mark_all_read"});
      _loadNotifications(); 
    } catch (e) {
      debugPrint("Error marking all read: $e");
    }
  }

  Future<void> _handleTap(Map<String, dynamic> notif) async {
    if (notif['is_read'].toString() == "0") {
      setState(() {
        notif['is_read'] = 1;
      });
      ApiClient.post("/notification/notification.php", data: {
        "action": "mark_one_read", 
        "id": notif['id']
      });
    }

    final type = notif['type'].toString();
    final jobId = int.tryParse(notif['job_id'].toString());

    if (jobId != null && (type.contains('bid') || type.contains('job') || type.contains('review'))) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)),
      );
    } else if (type == 'message') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Open Chat Screen")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (_notifications.any((n) => n['is_read'].toString() == "0"))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
              label: const Text("Mark all read", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip("All", 'all'),
                  const SizedBox(width: 8),
                  _filterChip("Unread", 'unread', isStatus: true),
                  const SizedBox(width: 8),
                  _filterChip("Bids", 'bid'),
                  const SizedBox(width: 8),
                  _filterChip("Jobs", 'job'),
                  const SizedBox(width: 8),
                  _filterChip("Messages", 'message'),
                ],
              ),
            ),
          ),
          
          // Notification List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty 
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, {bool isStatus = false}) {
    final isSelected = isStatus ? _selectedStatus == value : _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (isStatus) {
            _selectedStatus = selected ? value : 'all';
          } else {
            _selectedType = selected ? value : 'all';
          }
        });
        _loadNotifications();
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final isRead = notif['is_read'].toString() == '1';
    final type = notif['type'] ?? 'system';
    final avatarUrl = notif['avatar_url']; 

    IconData icon = Icons.notifications;
    Color iconColor = Colors.grey;
    Color iconBg = Colors.grey.shade100;
    
    if (type.contains('bid')) { 
      icon = Icons.local_offer; 
      iconColor = Colors.blue.shade700; 
      iconBg = Colors.blue.shade50;
    } else if (type.contains('job_completed') || type.contains('job_marked_done')) { 
      icon = Icons.check_circle; 
      iconColor = Colors.green.shade700; 
      iconBg = Colors.green.shade50;
    } else if (type.contains('review')) { 
      icon = Icons.star; 
      iconColor = Colors.amber.shade700; 
      iconBg = Colors.amber.shade50;
    } else if (type == 'message') { 
      icon = Icons.message; 
      iconColor = Colors.purple.shade700; 
      iconBg = Colors.purple.shade50;
    }

    return Material(
      color: isRead ? Colors.white : Colors.blue.withOpacity(0.02),
      elevation: 0, 
      // ✅ FIXED: Removed 'borderRadius' here to fix assertion error.
      // The shape handles the radius.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(notif),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (avatarUrl != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 22,
                  onBackgroundImageError: (_, __) {},
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              
              const SizedBox(width: 14),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8, 
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary, 
                              shape: BoxShape.circle
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['message'] ?? '',
                      style: TextStyle(
                        fontSize: 13, 
                        color: isRead ? Colors.grey[600] : Colors.black87,
                        height: 1.4
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notif['created_at']),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                        if (notif['job_title'] != null) ...[
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100, 
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300)
                              ),
                              child: Text(
                                "Job: ${notif['job_title']}", 
                                style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No notifications", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}