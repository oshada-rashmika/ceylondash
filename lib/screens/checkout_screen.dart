import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final TextEditingController _promoController = TextEditingController();
  static const double _deliveryFee = 250.0;
  final _db = DatabaseService();

  late String _address;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _address = widget.user?.address ?? '';
    _phone = widget.user?.phone ?? '';
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final bucket = cart.shopBuckets[widget.shopId];
        final subtotal = cart.getShopSubtotal(widget.shopId);
        final total = subtotal + _deliveryFee;

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
                    _buildBillSection(subtotal, total),
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

  Widget _buildBillSection(double subtotal, double total) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_rounded,
            label: 'Bill Summary',
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _promoController,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Add promo code',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: Icon(
                  Icons.local_offer_rounded,
                  color: Colors.black26,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x0A000000)),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Subtotal',
            value: 'Rs. ${subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _BillRow(
            label: 'Delivery Fee',
            value: 'Rs. ${_deliveryFee.toStringAsFixed(0)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0x0F000000)),
          ),
          _BillRow(
            label: 'Total',
            value: 'Rs. ${total.toStringAsFixed(0)}',
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
                  'Rs. ${total.toStringAsFixed(0)}',
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
