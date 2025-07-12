import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [_buildSliverAppBar(), _buildNotificationsList()],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        StreamBuilder<int>(
          stream: _notificationService.getUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount == 0) return const SizedBox.shrink();

            return TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final notification = notifications[index];
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      ((index * 0.1) + 0.2).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index * 0.1).clamp(0.0, 1.0),
                            ((index * 0.1) + 0.2).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onDismiss: () => _deleteNotification(notification.id),
                    ),
                  ),
                ),
              );
            }, childCount: notifications.length),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they\'ll appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.read) {
      _notificationService.markAsRead(notification.id);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(notification: notification),
      ),
    );
  }

  void _markAllAsRead() {
    _notificationService.markAllAsRead();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    _notificationService.deleteNotification(notificationId);
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notification.read
              ? null
              : Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.read
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.read)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case 'alert':
        return Colors.red;
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'alert':
        return Icons.warning_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'warning':
        return Icons.error_outline_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
