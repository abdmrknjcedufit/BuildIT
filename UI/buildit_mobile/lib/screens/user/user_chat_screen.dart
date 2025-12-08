import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/message_provider.dart';
import 'package:buildit_mobile/providers/conversation_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/models/message_model.dart';
import 'package:buildit_mobile/models/conversation_model.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';

class UserChatScreen extends StatefulWidget {
  final int conversationId;
  final int? otherUserId;
  final User? otherUser;

  const UserChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.otherUser,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final MessageProvider _messageProvider = MessageProvider();
  final ConversationProvider _conversationProvider = ConversationProvider();
  final UserProvider _userProvider = UserProvider();
  final TextEditingController _messageController = TextEditingController();
  
  Conversation? _conversation;
  User? _otherUser;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isLoadingMessages = false;
  Timer? _refreshTimer;
  int? _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Ako je korisnik već proslijeđen, koristi ga odmah
    if (widget.otherUser != null) {
      _otherUser = widget.otherUser;
    }
    _loadConversation();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _refreshMessages();
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadConversation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _conversationProvider.get(
        filter: {'id': widget.conversationId},
        page: 1,
        pageSize: 1,
      );

      if (result.result.isNotEmpty) {
        final conversation = result.result.first;
        setState(() {
          _conversation = conversation;
        });

        // Load other user only if not already provided
        if (_otherUser == null && AuthProvider.id != null) {
          final otherUserId = conversation.user1Id == AuthProvider.id
              ? conversation.user2Id
              : conversation.user1Id;
          
          try {
            final userResult = await _userProvider.get(
              filter: {'id': otherUserId},
              page: 1,
              pageSize: 1,
            );
            if (userResult.result.isNotEmpty) {
              setState(() {
                _otherUser = userResult.result.first;
              });
            }
          } catch (e) {
            // Ignore user loading errors
          }
        }

        await _loadMessages();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingConversation}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_conversation == null) return;

    try {
      setState(() {
        _isLoadingMessages = true;
      });

      final result = await _messageProvider.get(
        filter: {'conversationId': _conversation!.id},
        page: 1,
        pageSize: 1000,
      );

      setState(() {
        _messages = result.result;
        _lastMessageCount = result.result.length;
        _isLoadingMessages = false;
      });

      if (AuthProvider.id != null) {
        await _messageProvider.markConversationAsRead(
          _conversation!.id,
          AuthProvider.id!,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    if (_conversation == null || _isLoadingMessages) return;

    try {
      final result = await _messageProvider.get(
        filter: {'conversationId': _conversation!.id},
        page: 1,
        pageSize: 1000,
      );

      if (result.result.length != _lastMessageCount) {
        setState(() {
          _messages = result.result;
          _lastMessageCount = result.result.length;
        });

        if (AuthProvider.id != null) {
          await _messageProvider.markConversationAsRead(
            _conversation!.id,
            AuthProvider.id!,
          );
        }
      }
    } catch (e) {
      // Ignore refresh errors
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversation == null) {
      return;
    }

    try {
      setState(() {
        _isSendingMessage = true;
      });

      final messageRequest = {
        'conversationId': _conversation!.id,
        'senderId': AuthProvider.id,
        'content': _messageController.text.trim(),
      };

      await _messageProvider.insert(messageRequest);

      _messageController.clear();
      await _loadMessages();

      setState(() {
        _isSendingMessage = false;
      });
    } catch (e) {
      setState(() {
        _isSendingMessage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorSendingMessage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context).yesterday;
    } else if (difference.inDays < 7) {
      final days = [
        AppLocalizations.of(context).monday,
        AppLocalizations.of(context).tuesday,
        AppLocalizations.of(context).wednesday,
        AppLocalizations.of(context).thursday,
        AppLocalizations.of(context).friday,
        AppLocalizations.of(context).saturday,
        AppLocalizations.of(context).sunday,
      ];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _otherUser != null
        ? '${_otherUser!.firstName} ${_otherUser!.lastName}'
        : widget.otherUser != null
            ? '${widget.otherUser!.firstName} ${widget.otherUser!.lastName}'
            : AppLocalizations.of(context).loading;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryOrange,
                child: Text(
                  displayName.isNotEmpty && displayName != AppLocalizations.of(context).loading
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.otherUser != null || _otherUser != null)
                      Text(
                        AppLocalizations.of(context).activeStatus,
                        style: TextStyle(
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryOrange,
                child: Text(
                  displayName.isNotEmpty && displayName != AppLocalizations.of(context).loading
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body:           Center(
          child: Text(AppLocalizations.of(context).conversationNotFound),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryOrange,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Aktivan',
                    style: TextStyle(
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
      body: Column(
        children: [
          Expanded(
            child: _buildMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return           Center(
            child: Text(
          AppLocalizations.of(context).sendFirstMessage,
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMe = message.senderId == AuthProvider.id;

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryRed : AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? AppColors.white : AppColors.primaryBlack,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe
                          ? AppColors.white.withOpacity(0.7)
                          : AppColors.darkGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).enterMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSendingMessage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: AppColors.primaryRed),
            onPressed: _isSendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

