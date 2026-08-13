import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/notification_model.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../services/firestore_refs.dart';
import '../widgets/app_card.dart';

/// Real-time Alerts and Notifications Screen.
/// Owned by Person A. Multi-language and responsive.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String selectedFilter = 'all';

  final List<NotificationItem> _defaultDemoNotifications = [
    NotificationItem(
      id: 'demo_1',
      type: 'pestReminder',
      title: 'Pest Watch: Stem Borer Alert',
      message: 'Warm and humid conditions detected. Inspect paddy crops for early signs of yellow stem borer larvae.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: 'demo_2',
      type: 'weatherAlert',
      title: 'Rain Anticipated Tomorrow',
      message: 'Scattered showers expected in Nashik district. Postpone foliar insecticide spraying.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    NotificationItem(
      id: 'demo_3',
      type: 'bidReceived',
      title: 'New Bid on Soybean Listing',
      message: 'Buyer Agro Traders placed a bid of ₹4,850/quintal for your 25 quintal soybean harvest.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: 'demo_4',
      type: 'cropAdvisory',
      title: 'Optimal Sowing Window: Wheat',
      message: 'Temperatures are dropping below 22°C. Excellent timing for early Rabi wheat sowing.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'pestReminder':
        return Icons.bug_report_outlined;
      case 'weatherAlert':
        return Icons.water_drop_outlined;
      case 'bidReceived':
      case 'bidAccepted':
        return Icons.gavel_outlined;
      case 'cropAdvisory':
      default:
        return Icons.eco_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'pestReminder':
        return AppColors.warning;
      case 'weatherAlert':
        return AppColors.accent;
      case 'bidReceived':
      case 'bidAccepted':
        return AppColors.secondary;
      case 'cropAdvisory':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = UserService.currentUser?.uid;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, langCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LocalizationService.tr('notifications_title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all, size: 20),
                tooltip: LocalizationService.tr('mark_all_read'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All alerts marked as read')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Alerts'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pestReminder', 'Pests & Diseases'),
                    const SizedBox(width: 8),
                    _buildFilterChip('weatherAlert', 'Weather'),
                    const SizedBox(width: 8),
                    _buildFilterChip('bidReceived', 'Market Bids'),
                  ],
                ),
              ),

              // List
              Expanded(
                child: uid == null
                    ? _buildList(_defaultDemoNotifications)
                    : StreamBuilder<List<NotificationItem>>(
                        stream: FirestoreRefs.users
                            .doc(uid)
                            .collection('notifications')
                            .orderBy('createdAt', descending: true)
                            .snapshots()
                            .map((snap) => snap.docs
                                .map((d) => NotificationItem.fromMap(d.id, d.data()))
                                .toList()),
                        builder: (context, snapshot) {
                          final items = snapshot.data != null && snapshot.data!.isNotEmpty
                              ? snapshot.data!
                              : _defaultDemoNotifications;

                          final filtered = selectedFilter == 'all'
                              ? items
                              : items.where((i) => i.type == selectedFilter).toList();

                          return _buildList(filtered);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => selectedFilter = filterKey);
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
    );
  }

  Widget _buildList(List<NotificationItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              LocalizationService.tr('no_notifications'),
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final typeColor = _getTypeColor(item.type);

        return AppCard(
          backgroundColor: item.isRead ? AppColors.surface : const Color(0xFFF9FBE7),
          borderColor: item.isRead ? AppColors.cardBorder : AppColors.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getTypeIcon(item.type), size: 22, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
