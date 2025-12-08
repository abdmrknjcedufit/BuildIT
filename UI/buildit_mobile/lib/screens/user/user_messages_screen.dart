import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/conversation_provider.dart';
import 'package:buildit_mobile/models/conversation_model.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/screens/user/user_chat_screen.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';

class UserMessagesScreen extends StatefulWidget {
  final int? otherUserId;
  final int? listingId;

  const UserMessagesScreen({super.key, this.otherUserId, this.listingId});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> with WidgetsBindingObserver {
  final ConversationProvider _conversationProvider = ConversationProvider();
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
    _startRefreshTimer();
    if (widget.otherUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startConversationWithUser(widget.otherUserId!);
      });
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading) {
        _refreshConversations();
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refreshConversations() async {
    if (_isLoading) return;
    
    try {
      final result = await _conversationProvider.get(
        filter: {'userId': AuthProvider.id},
        page: 1,
        pageSize: 100,
      );

      // Sortiraj konverzacije po najnovijoj poruci
      final sortedConversations = List<Conversation>.from(result.result);
      sortedConversations.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.updatedAt ?? a.createdAt;
        final bTime = b.lastMessage?.createdAt ?? b.updatedAt ?? b.createdAt;
        return bTime.compareTo(aTime); // Najnovije prvo
      });

      if (mounted) {
        setState(() {
          _conversations = sortedConversations;
        });
      }
    } catch (e) {
      // Ignore refresh errors silently
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _conversationProvider.get(
        filter: {'userId': AuthProvider.id},
        page: 1,
        pageSize: 100,
      );

      // Sortiraj konverzacije po najnovijoj poruci
      final sortedConversations = List<Conversation>.from(result.result);
      sortedConversations.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.updatedAt ?? a.createdAt;
        final bTime = b.lastMessage?.createdAt ?? b.updatedAt ?? b.createdAt;
        return bTime.compareTo(aTime); // Najnovije prvo
      });

      setState(() {
        _conversations = sortedConversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingConversations}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startConversationWithUser(int otherUserId, {User? otherUser}) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final conversation = await _conversationProvider.getOrCreate(
        user1Id: AuthProvider.id!,
        user2Id: otherUserId,
        listingId: widget.listingId,
      );

      setState(() {
        _isLoading = false;
      });

      await _loadConversations();
      
      // Navigate to chat screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserChatScreen(
              conversationId: conversation.id,
              otherUserId: otherUserId,
              otherUser: otherUser,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorCreatingConversation}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  User? _getOtherUser(Conversation conversation) {
    if (AuthProvider.id == null) return null;
    if (conversation.user1Id == AuthProvider.id) {
      return conversation.user2;
    } else {
      return conversation.user1;
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
  Widget build(BuildContext context) {
    // Prikaži listu korisnika
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
          AppLocalizations.of(context).messagesTitle,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryBlack),
            onPressed: () => _showNewConversationDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchMessages,
                  prefixIcon: const Icon(Icons.search, color: AppColors.darkGray),
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ?                             Center(
                            child: Text(
                            AppLocalizations.of(context).noConversations,
                            style: TextStyle(color: AppColors.darkGray),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final otherUser = _getOtherUser(conversation);
                            final displayName = otherUser != null
                                ? '${otherUser.firstName} ${otherUser.lastName}'
                                : AppLocalizations.of(context).unknownUser;

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserChatScreen(
                                      conversationId: conversation.id,
                                      otherUserId: otherUser?.id,
                                      otherUser: otherUser,
                                    ),
                                  ),
                                );
                                // Osveži listu konverzacija nakon povratka sa chat screen-a
                                if (mounted) {
                                  _loadConversations();
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: conversation.unreadCount > 0
                                      ? AppColors.primaryRed.withOpacity(0.05)
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: conversation.unreadCount > 0
                                        ? AppColors.primaryRed.withOpacity(0.3)
                                        : AppColors.lightGray,
                                    width: conversation.unreadCount > 0 ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primaryOrange,
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(color: AppColors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: conversation.unreadCount > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: conversation.unreadCount > 0
                                                        ? AppColors.primaryBlack
                                                        : AppColors.darkGray,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (conversation.unreadCount > 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryRed,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${conversation.unreadCount}',
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            conversation.lastMessage?.content ?? AppLocalizations.of(context).noMessages,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: conversation.unreadCount > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: conversation.unreadCount > 0
                                                  ? AppColors.primaryBlack
                                                  : AppColors.darkGray,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      conversation.lastMessage != null
                                          ? _formatTime(conversation.lastMessage!.createdAt)
                                          : _formatTime(conversation.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog() {
    final searchController = TextEditingController();
    final userProvider = UserProvider();
    List<User> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> searchUsers(String query) async {
            if (query.trim().isEmpty) {
              setDialogState(() {
                searchResults = [];
                isSearching = false;
              });
              return;
            }

            setDialogState(() {
              isSearching = true;
            });

            try {
              final result = await userProvider.get(
                filter: {'fts': query.trim(), 'isActive': true},
                page: 1,
                pageSize: 20,
              );

              setDialogState(() {
                searchResults = result.result
                    .where((user) => user.id != AuthProvider.id)
                    .toList();
                isSearching = false;
              });
            } catch (e) {
              setDialogState(() {
                isSearching = false;
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context).errorSearchingUsers}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return Dialog(
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).newConversation,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).searchUsers,
                        hintText: AppLocalizations.of(context).enterUsernameNameOrEmail,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {
                                    searchResults = [];
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                        if (value.trim().length >= 1) {
                          searchUsers(value);
                        } else {
                          setDialogState(() {
                            searchResults = [];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: searchController.text.trim().isEmpty
                          ?                                   Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Text(
                                  AppLocalizations.of(context).startTypingToFindUsers,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : searchResults.isEmpty
                                  ?                                           Padding(
                                            padding: EdgeInsets.all(20.0),
                                            child: Center(
                                              child: Text(
                                          AppLocalizations.of(context).noResults,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: searchResults.length,
                                      itemBuilder: (context, index) {
                                        final user = searchResults[index];
                                        return InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            _startConversationWithUser(user.id, otherUser: user);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.withOpacity(0.2),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: AppColors.primaryOrange,
                                                  child: Text(
                                                    user.firstName.isNotEmpty
                                                        ? user.firstName[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '${user.firstName} ${user.lastName}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '@${user.username}',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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

}
