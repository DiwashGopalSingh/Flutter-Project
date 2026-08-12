import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/blood_request_model.dart';
import 'blood_group_badge.dart';

class RequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;
  final VoidCallback? onDonate;
  final bool showActions;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onStatusUpdate,
    this.onDonate,
    this.showActions = false,
  });

  Color get _urgencyColor {
    switch (request.urgency) {
      case 'Emergency': return AppColors.error;
      case 'Urgent': return AppColors.warning;
      default: return AppColors.info;
    }
  }

  Color get _statusColor {
    switch (request.status) {
      case 'Pending': return AppColors.warning;
      case 'Processing': return AppColors.info;
      case 'Fulfilled': return AppColors.success;
      case 'Cancelled': return AppColors.textHint;
      default: return AppColors.textHint;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case 'Pending': return Icons.hourglass_empty_rounded;
      case 'Processing': return Icons.sync_rounded;
      case 'Fulfilled': return Icons.check_circle_rounded;
      case 'Cancelled': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: request.isEmergency
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
            width: request.isEmergency ? 1 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: request.isEmergency
                  ? AppColors.error.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                BloodGroupChip(bloodGroup: request.bloodGroup),
                const SizedBox(width: 8),
                // Urgency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request.isEmergency)
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: _urgencyColor),
                      if (request.isEmergency) const SizedBox(width: 3),
                      Text(
                        request.urgency,
                        style: AppTextStyles.caption.copyWith(
                          color: _urgencyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status
                Row(
                  children: [
                    Icon(_statusIcon, size: 14, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(request.status,
                        style: AppTextStyles.caption.copyWith(color: _statusColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hospital & quantity
            Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.hospitalName,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  request.quantity > 1
                      ? '${request.fulfilledQuantity}/${request.quantity} collected (${request.remainingQuantity} needed)'
                      : '${request.quantity} unit needed',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (request.quantity > 1) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: request.quantity > 0 ? (request.fulfilledQuantity / request.quantity).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ],
            if (request.patientName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Patient: ${request.patientName}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.requestDate),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            if (onDonate != null && request.status != 'Fulfilled' && request.status != 'Cancelled') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDonate,
                  icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                  label: Text(
                    request.remainingQuantity > 1 
                        ? 'Donate 1 Unit (${request.remainingQuantity} needed)' 
                        : 'Donate to Request', 
                    style: AppTextStyles.buttonText.copyWith(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
