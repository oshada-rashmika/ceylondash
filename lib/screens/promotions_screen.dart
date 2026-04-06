import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/promotion_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class PromotionsScreen extends StatefulWidget {
  final UserModel user;

  const PromotionsScreen({super.key, required this.user});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<PromotionModel> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final uid = widget.user.uid;
      final address = widget.user.address ?? '';

      final results = await Future.wait([
        _db.getUserOrderCount(uid),
        _db.getSeasonalPromotions(address),
      ]);

      final orderCount = results[0] as int;
      final seasonalPromos = results[1] as List<PromotionModel>;

      final allPromos = <PromotionModel>[];

      if (orderCount >= 100) {
        allPromos.add(
          PromotionModel(
            id: 'loyalty_platinum',
            title: 'Platinum Rider',
            description: 'Thank you for your incredible loyalty!',
            discountPercentage: 50.0,
            type: 'loyalty',
            isAutoApplied: true,
          ),
        );
      } else if (orderCount >= 20) {
        allPromos.add(
          PromotionModel(
            id: 'loyalty_gold',
            title: 'Gold Rider',
            description: 'You\'re one of our best customers.',
            discountPercentage: 25.0,
            type: 'loyalty',
            isAutoApplied: true,
          ),
        );
      } else if (orderCount >= 2) {
        allPromos.add(
          PromotionModel(
            id: 'loyalty_silver',
            title: 'Silver Rider',
            description: 'A little something to say thanks for riding with us.',
            discountPercentage: 10.0,
            type: 'loyalty',
            isAutoApplied: true,
          ),
        );
      }

      allPromos.addAll(seasonalPromos);

      if (mounted) {
        setState(() {
          _promotions = allPromos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading promotions: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Promotions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _promotions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promo = _promotions[index];
                final isClaimed =
                    widget.user.usedPromotions?.contains(promo.id) ?? false;
                return _PromotionCard(promotion: promo, isClaimed: isClaimed);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.ticket,
              size: 80,
              color: Colors.black.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 24),
            Text(
              'No active promotions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.8),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep ordering to unlock exclusive rewards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final bool isClaimed;

  const _PromotionCard({required this.promotion, required this.isClaimed});

  @override
  Widget build(BuildContext context) {
    final isLoyalty = promotion.type == 'loyalty';
    final badgeText = isLoyalty ? 'Loyalty Reward' : 'Seasonal Offer';
    final badgeColor = isLoyalty
        ? Colors.purple.shade50
        : Colors.orange.shade50;
    final badgeTextColor = isLoyalty
        ? Colors.purple.shade700
        : Colors.orange.shade700;

    return Opacity(
      opacity: isClaimed ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${promotion.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: isClaimed
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                promotion.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                promotion.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              if (promotion.isAutoApplied && !isClaimed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Auto-applied at checkout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
              if (isClaimed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'You have already claimed it',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
