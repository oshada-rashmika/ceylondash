import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/promotion_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/top_snackbar.dart';
import 'payment_method_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String shopId;
  final UserModel? user;

  const CheckoutScreen({super.key, required this.shopId, this.user});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery';
  static const double _deliveryFee = 250.0;
  final _db = DatabaseService();

  late String _address;
  late String _phone;

  List<PromotionModel> _availablePromos = [];
  PromotionModel? _selectedPromo;
  bool _isLoadingPromos = true;

  @override
  void initState() {
    super.initState();
    _address = widget.user?.address ?? '';
    _phone = widget.user?.phone ?? '';
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final uid = widget.user?.uid;
      final address = widget.user?.address ?? '';

      if (uid == null) {
        if (mounted) {
          setState(() {
            _isLoadingPromos = false;
          });
        }
        return;
      }

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
            isAutoApplied: false,
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
            isAutoApplied: false,
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
            isAutoApplied: false,
          ),
        );
      }

      allPromos.addAll(seasonalPromos);

      if (mounted) {
        setState(() {
          _availablePromos = allPromos;
          _isLoadingPromos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPromos = false;
        });
      }
    }
  }

  Future<void> _showEditBottomSheet({
    required String title,
    required String currentValue,
    required TextInputType keyboardType,
    required String firestoreField,
    required void Function(String) onSaved,
  }) async {
    final ctrl = TextEditingController(text: currentValue);
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 14),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: PremiumTextField(
                          controller: ctrl,
                          label: title,
                          keyboardType: keyboardType,
                          textCapitalization:
                              keyboardType == TextInputType.phone
                                  ? TextCapitalization.none
                                  : TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final newVal = ctrl.text.trim();
                                    if (newVal.isEmpty) return;
                                    setSheetState(() => saving = true);
                                    try {
                                      final uid = widget.user?.uid;
                                      if (uid != null) {
                                        await _db.updateUserField(uid, {
                                          firestoreField: newVal,
                                        });
                                      }
                                      if (mounted) {
                                        onSaved(newVal);
                                        Navigator.pop(sheetCtx);
                                        TopSnackbar.show(
                                          context,
                                          message:
                                              '$title updated successfully',
                                          type: SnackbarType.success,
                                        );
                                      }
                                    } catch (_) {
                                      setSheetState(() => saving = false);
                                      if (mounted) {
                                        TopSnackbar.show(
                                          context,
                                          message:
                                              'Failed to update. Try again.',
                                          type: SnackbarType.error,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    ctrl.dispose();
  }

  void _showPromoSelectorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Promotions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingPromos
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.cyan),
                            )
                          : _availablePromos.isEmpty
                              ? _buildEmptyPromosState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _availablePromos.length,
                                  itemBuilder: (context, index) {
                                    final promo = _availablePromos[index];
                                    return _buildPromoOptionCard(promo);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyPromosState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.ticket, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          const Text(
            'Keep ordering to unlock\nexclusive rewards.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoOptionCard(PromotionModel promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedPromo = promo);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${promo.discountPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyan,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final bucket = cart.shopBuckets[widget.shopId];
        final subtotal = cart.getShopSubtotal(widget.shopId);
        
        final discountAmount = _selectedPromo != null
            ? (subtotal * (_selectedPromo!.discountPercentage / 100))
            : 0.0;
        final total = subtotal + _deliveryFee - discountAmount;

        if (bucket == null || bucket.items.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            appBar: _buildAppBar(context, 'Checkout'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: _buildAppBar(context, 'Checkout - ${bucket.shopName}'),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDeliverySection(),
                    const SizedBox(height: 16),
                    _buildPromoSelector(),
                    const SizedBox(height: 16),
                    _buildBillSection(subtotal, total, discountAmount),
                    const SizedBox(height: 16),
                    _buildPaymentSection(context),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              _buildCheckoutButton(context, cart, total),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildDeliverySection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.local_shipping_rounded,
            label: 'Delivery Details',
          ),
          const SizedBox(height: 12),
          _DeliveryTile(
            icon: Icons.location_on_rounded,
            iconColor: Colors.cyan,
            label: 'Delivery Address',
            value: _address.isNotEmpty ? _address : 'Add a delivery address',
            valueColor: _address.isNotEmpty ? Colors.black87 : Colors.black38,
            onTap: () {
              HapticFeedback.selectionClick();
              _showEditBottomSheet(
                title: 'Edit Address',
                currentValue: _address,
                keyboardType: TextInputType.streetAddress,
                firestoreField: 'address',
                onSaved: (v) => setState(() => _address = v),
              );
            },
          ),
          const Divider(height: 1, color: Color(0x0A000000)),
          _DeliveryTile(
            icon: Icons.phone_rounded,
            iconColor: Colors.cyan,
            label: 'Phone Number',
            value: _phone.isNotEmpty ? _phone : 'Add a phone number',
            valueColor: _phone.isNotEmpty ? Colors.black87 : Colors.black38,
            onTap: () {
              HapticFeedback.selectionClick();
              _showEditBottomSheet(
                title: 'Edit Phone Number',
                currentValue: _phone,
                keyboardType: TextInputType.phone,
                firestoreField: 'phone',
                onSaved: (v) => setState(() => _phone = v),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSelector() {
    return _SectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(CupertinoIcons.ticket, color: Colors.cyan, size: 22),
        ),
        title: Text(
          _selectedPromo == null ? 'Apply Promotion' : _selectedPromo!.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: _selectedPromo == null ? FontWeight.w600 : FontWeight.bold,
            color: _selectedPromo == null ? Colors.black87 : Colors.cyan,
          ),
        ),
        trailing: _selectedPromo == null
            ? const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 22)
            : IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPromo = null);
                },
                icon: const Icon(Icons.close_rounded, color: Colors.black38, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
        onTap: _selectedPromo == null
            ? () {
                HapticFeedback.selectionClick();
                _showPromoSelectorBottomSheet();
              }
            : null,
      ),
    );
  }

  Widget _buildBillSection(double subtotal, double total, double discountAmount) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_rounded,
            label: 'Bill Summary',
          ),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Subtotal',
            value: 'Rs. ${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _BillRow(
            label: 'Delivery Fee',
            value: 'Rs. ${_deliveryFee.toStringAsFixed(2)}',
          ),
          if (_selectedPromo != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${_selectedPromo!.discountPercentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
                Text(
                  '- Rs. ${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0x0F000000)),
          ),
          _BillRow(
            label: 'Total',
            value: 'Rs. ${total.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.payment_rounded, label: 'Payment'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              HapticFeedback.selectionClick();
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentMethodScreen(currentMethod: _selectedPayment),
                ),
              );
              if (result != null && mounted) {
                setState(() => _selectedPayment = result);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _selectedPayment,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(
    BuildContext context,
    CartProvider cart,
    double total,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              cart.clearShop(widget.shopId);
              Navigator.popUntil(context, (route) => route.isFirst);
              TopSnackbar.show(
                context,
                message: 'Order Placed Successfully!',
                type: SnackbarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('·', style: TextStyle(color: Colors.white54)),
                const SizedBox(width: 8),
                Text(
                  'Rs. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black38),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black38,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;
  const _DeliveryTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _BillRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.3,
          )
        : const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
