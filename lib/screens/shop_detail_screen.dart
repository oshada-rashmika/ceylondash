import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop_model.dart';

class ShopDetailScreen extends StatelessWidget {
  final ShopModel shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(context),
          _buildMenuSliverList(),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        title: Text(
          shop.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: _HeaderBackground(imageUrl: shop.headerImage),
      ),
    );
  }

  SliverList _buildMenuSliverList() {
    final tiles = <Widget>[];

    for (final category in shop.categories) {
      tiles.add(_CategoryHeader(category: category));
      final categoryItems =
          shop.items.where((item) => item.category == category).toList();

      if (categoryItems.isEmpty) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'No items in this category.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.3),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      } else {
        for (final item in categoryItems) {
          tiles.add(_ShopItemTile(item: item));
        }
      }

      tiles.add(const SizedBox(height: 24));
    }

    return SliverList(
      delegate: SliverChildListDelegate(tiles),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  final String imageUrl;
  const _HeaderBackground({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF1A1A1A),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.cyan,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white30,
                size: 60,
              ),
            ),
          )
        else
          Container(
            color: const Color(0xFF1A1A1A),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white30,
              size: 60,
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.4, 1.0],
              colors: [Colors.transparent, Color(0xCC000000)],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  String _formatCategory(String raw) {
    return raw
        .split(RegExp(r'[\s_]+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Text(
        _formatCategory(category),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  final ShopItemModel item;
  const _ShopItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.black.withOpacity(0.04),
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black.withOpacity(0.04),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: Colors.black26,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black.withOpacity(0.04),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Colors.black26,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.4),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => HapticFeedback.lightImpact(),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.cyan.shade600,
              size: 28,
            ),
            splashRadius: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
