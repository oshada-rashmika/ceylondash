import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/rider_service.dart';
import '../widgets/top_snackbar.dart';

class RiderQRScannerScreen extends StatefulWidget {
  const RiderQRScannerScreen({super.key});

  @override
  State<RiderQRScannerScreen> createState() => _RiderQRScannerScreenState();
}

class _RiderQRScannerScreenState extends State<RiderQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null) {
        try {
          setState(() => _isProcessing = true);
          final data = jsonDecode(rawValue);
          if (data is Map && data.containsKey('orderId') && data.containsKey('pin')) {
            await RiderService().verifyDelivery(data['orderId'], data['pin'].toString());
            if (mounted) {
              TopSnackbar.show(context, message: 'Delivery verified successfully!', type: SnackbarType.success);
              Navigator.pop(context);
            }
            return;
          }
        } catch (e) {
          if (mounted) {
             TopSnackbar.show(context, message: 'Invalid QR payload format or Verification Failed', type: SnackbarType.error);
          }
        } finally {
          if (mounted) {
            // Keep a brief delay to avoid repeated scanning
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() => _isProcessing = false);
          }
        }
      }
    }
  }

  void _showManualEntryDialog() {
    final orderIdController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Handover Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orderIdController,
                decoration: const InputDecoration(labelText: 'Order ID'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: '4-Digit PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final orderId = orderIdController.text.trim();
                final pin = pinController.text.trim();
                if (orderId.isEmpty || pin.isEmpty) return;

                Navigator.pop(context);
                setState(() => _isProcessing = true);
                try {
                  await RiderService().verifyDelivery(orderId, pin);
                  if (mounted) {
                    TopSnackbar.show(context, message: 'Delivery verified successfully!', type: SnackbarType.success);
                    Navigator.pop(context); // Pop scanner
                  }
                } catch (e) {
                  if (mounted) {
                    TopSnackbar.show(context, message: 'Verification failed: $e', type: SnackbarType.error);
                  }
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Delivery QR'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _showManualEntryDialog,
                icon: const Icon(Icons.pin, size: 24),
                label: const Text('Enter 4-Digit PIN Manually', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
