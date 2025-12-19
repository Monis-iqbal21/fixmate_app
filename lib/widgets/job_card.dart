import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;
  const JobCard({super.key, required this.job, required this.onTap});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case "open":
        return AppColors.primary;
      case "in progress":
        return AppColors.warning;
      case "done":
        return AppColors.success;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (job["status"] ?? "").toString();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job["title"] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _statusColor(status).withOpacity(0.25)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _statusColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job["location"] ?? "",
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(
                    "PKR ${(job["budget"] ?? 0)}",
                    style: const TextStyle(color: AppColors.textDark, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job["time"] ?? "",
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
