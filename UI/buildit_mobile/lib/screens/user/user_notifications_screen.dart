import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/notification_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/notification_model.dart' as notification_model;
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user/user_messages_screen.dart';
import 'package:buildit_mobile/screens/historija_screen.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:intl/intl.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final NotificationProvider _notificationProvider = NotificationProvider();
  List<notification_model.Notification> _allNotifications = [];
  List<notification_model.Notification> _unreadNotifications = [];
  bool _isLoading = true;
  int _currentTab = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (AuthProvider.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      var allResult = await _notificationProvider.get(
        page: 1,
        pageSize: 100,
        filter: {'UserId': AuthProvider.id},
      );

      var unreadResult = await _notificationProvider.get(
        page: 1,
        pageSize: 100,
        filter: {'UserId': AuthProvider.id, 'IsRead': false},
      );

      setState(() {
        _allNotifications = allResult.result;
        _unreadNotifications = unreadResult.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationProvider.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri označavanju kao pročitanu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (var notification in _unreadNotifications) {
        await _notificationProvider.markAsRead(notification.id);
      }
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sve notifikacije označene kao pročitane'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(notification_model.Notification notification) async {
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    if (notification.notificationType == 'Message' && notification.referenceId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserMessagesScreen(otherUserId: null, listingId: null),
        ),
      );
    } else if (notification.notificationType == 'Order' && notification.referenceId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const HistorijaScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          AppLocalizations.of(context).notifications,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                AppLocalizations.of(context).markAllAsRead,
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.lightGray, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          0,
                          '${AppLocalizations.of(context).all} (${_allNotifications.length})',
                          _currentTab == 0,
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          1,
                          '${AppLocalizations.of(context).unread} (${_unreadNotifications.length})',
                          _currentTab == 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: AppColors.primaryOrange,
                    child: _buildNotificationsList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(int index, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryOrange : AppColors.darkGray,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final notificationsToShow = _currentTab == 0 ? _allNotifications : _unreadNotifications;

    if (notificationsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.darkGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _currentTab == 0
                  ? AppLocalizations.of(context).noNotifications
                  : AppLocalizations.of(context).noUnreadNotifications,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificationsToShow.length,
      itemBuilder: (context, index) {
        final notification = notificationsToShow[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(notification_model.Notification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.notificationType) {
      case 'Order':
        icon = Icons.shopping_bag;
        iconColor = Colors.green;
        break;
      case 'Review':
        icon = Icons.star;
        iconColor = AppColors.primaryOrange;
        break;
      case 'Message':
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.darkGray;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.primaryOrange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? AppColors.lightGray : AppColors.primaryOrange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
