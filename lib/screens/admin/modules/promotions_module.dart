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

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Discount %'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final promo = PromotionModel(
                  id: const Uuid().v4(),
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  discountPercentage: double.tryParse(discountCtrl.text) ?? 0.0,
                  type: 'general',
                  isAutoApplied: false,
                );
                context.read<PromotionsBloc>().add(AddPromotion(promo));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Promotions Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<PromotionsBloc, PromotionsState>(
                  builder: (context, state) {
                    if (state is PromotionsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is PromotionsError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is PromotionsLoaded) {
                      if (state.promotions.isEmpty) {
                        return const Center(child: Text('No active promotions'));
                      }
                      return ListView.builder(
                        itemCount: state.promotions.length,
                        itemBuilder: (context, index) {
                          final promo = state.promotions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Text(promo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${promo.description}\nDiscount: ${promo.discountPercentage}%'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  context.read<PromotionsBloc>().add(DeletePromotion(promo.id));
                                },
                              ),
                            ),
                          );
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
}
