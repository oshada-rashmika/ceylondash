import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  final bool isActive;

  const ChatListScreen({super.key, required this.isActive});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService();

  UserModel? _user;
  Stream<List<OrderModel>>? _ordersStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      _user = await _dbService.getUser(uid);
      if (_user != null) {
        final isRider = _user!.role == 'rider';
        _ordersStream = isRider
            ? _dbService.getMyActiveRouteStream(uid)
            : _dbService.streamCustomerOrders(uid);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login to see chats.")));
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null || _ordersStream == null) {
      return const Scaffold(body: Center(child: Text("User not found.")));
    }

    final isRider = _user!.role == 'rider';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad + 24)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Active chats linked to your orders.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              StreamBuilder<List<OrderModel>>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Error loading orders: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final allOrders = snapshot.data ?? [];
                  final displayOrders = allOrders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();

                  if (displayOrders.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "No active orders found.",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: displayOrders.length,
                      itemBuilder: (context, index) {
                        final order = displayOrders[index];
                        return _ChatTile(
                          order: order,
                          currentUser: _user!,
                          isRider: isRider,
                        );
                      },
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final OrderModel order;
  final UserModel currentUser;
  final bool isRider;

  const _ChatTile({
    required this.order,
    required this.currentUser,
    required this.isRider,
  });

  @override
  Widget build(BuildContext context) {
    final chatName = isRider ? 'Customer (${order.orderName})' : 'Delivery Rider (${order.orderName})';
    final initial = chatName.characters.first.toUpperCase();
    
    // Format timestamp
    String timeStr = '';
    final updatedAt = order.timestamps['updatedAt'];
    if (updatedAt != null) {
      final dt = (updatedAt is Timestamp) ? updatedAt.toDate() : DateTime.now();
      timeStr = DateFormat('hh:mm a').format(dt);
    } else {
      timeStr = 'Just now';
    }

    final messagePreview = 'Chat regarding order ${order.id.substring(0, 5)}...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  trackingId: order.id,
                  currentUserId: currentUser.uid,
                  currentUserName: currentUser.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.cyan.withAlpha(28),
          highlightColor: Colors.cyan.withAlpha(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF5FEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isRider ? Colors.deepPurple : Colors.black,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chatName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            messagePreview,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

