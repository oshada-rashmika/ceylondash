import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LeaderboardDashboardScreen extends StatefulWidget {
  const LeaderboardDashboardScreen({super.key});

  @override
  State<LeaderboardDashboardScreen> createState() =>
      _LeaderboardDashboardScreenState();
}

class _LeaderboardDashboardScreenState extends State<LeaderboardDashboardScreen> {
  // Demo data for the entire leaderboard
  final List<Map<String, dynamic>> _sellers = [
    {'name': 'DailyMart LK', 'deliveries': 342, 'onTime': 98.5, 'rank': 1},
    {'name': 'Island Threads', 'deliveries': 298, 'onTime': 97.2, 'rank': 2},
    {'name': 'SpicePack Co.', 'deliveries': 261, 'onTime': 95.8, 'rank': 3},
    {'name': 'Ceylon Tech', 'deliveries': 245, 'onTime': 96.0, 'rank': 4},
    {'name': 'Lanka Fashion', 'deliveries': 230, 'onTime': 94.5, 'rank': 5},
    {'name': 'Kandy Spices', 'deliveries': 210, 'onTime': 93.2, 'rank': 6},
    {'name': 'Colombo Express', 'deliveries': 195, 'onTime': 92.1, 'rank': 7},
    {'name': 'Galle Traders', 'deliveries': 190, 'onTime': 91.5, 'rank': 8},
    {'name': 'Negombo Seafoods', 'deliveries': 188, 'onTime': 90.8, 'rank': 9},
    {'name': 'Jaffna Sweets', 'deliveries': 185, 'onTime': 96.0, 'rank': 10},
    {'name': 'Matara Crafts', 'deliveries': 180, 'onTime': 89.5, 'rank': 11},
    {'name': 'Your Business', 'deliveries': 187, 'onTime': 96.5, 'rank': 12, 'isSelf': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213E), // Dark theme matching the overview card
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Seller Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMyRankBanner(),
                  const SizedBox(height: 32),
                  const Text(
                    'TOP SELLERS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final seller = _sellers[index];
                  return _buildLeaderboardTile(seller);
                },
                childCount: _sellers.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 48), // Padding at the bottom
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '#12',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Top 5% of Sellers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> seller) {
    final rank = seller['rank'] as int;
    final isSelf = seller['isSelf'] ?? false;
    
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFFFD700); // Gold
    else if (rank == 2) medalColor = const Color(0xFFC0C0C0); // Silver
    else if (rank == 3) medalColor = const Color(0xFFCD7F32); // Bronze

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isSelf 
          ? Colors.amber.withValues(alpha: 0.1) 
          : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf 
            ? Colors.amber.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Rank Indicator
          SizedBox(
            width: 40,
            child: medalColor != null
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: medalColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: medalColor,
                        size: 20,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelf ? Colors.amber : Colors.white60,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Seller Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelf ? FontWeight.w800 : FontWeight.w700,
                    color: isSelf ? Colors.amber : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(CupertinoIcons.cube_box_fill, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      '${seller['deliveries']} deliveries',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(CupertinoIcons.timer, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      '${seller['onTime']}% on-time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
