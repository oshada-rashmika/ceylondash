import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/promotions_bloc.dart';
import '../../../../models/promotion_model.dart';
import 'package:uuid/uuid.dart';

class PromotionsModule extends StatelessWidget {
  const PromotionsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PromotionsBloc()..add(LoadPromotions()),
      child: const PromotionsView(),
    );
  }
}

class PromotionsView extends StatelessWidget {
  const PromotionsView({super.key});

  Future<void> _showPromoDialog(BuildContext context, {PromotionModel? existingPromo}) async {
    final titleCtrl = TextEditingController(text: existingPromo?.title);
    final descCtrl = TextEditingController(text: existingPromo?.description);
    final discountCtrl = TextEditingController(text: existingPromo?.discountPercentage.toString());
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existingPromo == null ? 'Launch New Offer' : 'Edit Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(
                  controller: discountCtrl, 
                  decoration: const InputDecoration(labelText: 'Discount %'), 
                  keyboardType: TextInputType.number
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final promo = PromotionModel(
                  id: existingPromo?.id ?? const Uuid().v4(),
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  discountPercentage: double.tryParse(discountCtrl.text) ?? 0.0,
                  type: 'general',
                  isAutoApplied: false,
                );
                
                final bloc = context.read<PromotionsBloc>();
                if (existingPromo == null) {
                  bloc.add(AddPromotion(promo));
                } else {
                  bloc.add(UpdatePromotion(promo)); 
                }
                Navigator.pop(ctx);
              },
              child: Text(existingPromo == null ? 'Launch' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoDialog(context),
        label: const Text('New Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<PromotionsBloc, PromotionsState>(
                  builder: (context, state) {
                    if (state is PromotionsLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    } else if (state is PromotionsError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is PromotionsLoaded) {
                      if (state.promotions.isEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.builder(
                        itemCount: state.promotions.length,
                        itemBuilder: (context, index) {
                          return _buildPromoCard(context, state.promotions[index]);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marketing Suite',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black.withAlpha(220),
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage active campaigns and flash sales',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, PromotionModel promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6dd5ed), Color(0xFF2193b0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${promo.discountPercentage}% OFF Active',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.flash_on_rounded, color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.description,
                  style: TextStyle(
                    color: Colors.black.withAlpha(150),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showPromoDialog(context, existingPromo: promo),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Refine'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        context.read<PromotionsBloc>().add(DeletePromotion(promo.id));
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Deactivate'),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.withAlpha(80)),
          const SizedBox(height: 24),
          const Text(
            'No Active Campaigns',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Boost orders by launching a new flash sale.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
