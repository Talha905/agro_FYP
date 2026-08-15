import 'package:flutter/material.dart';

import '../models/listing_model.dart';
import '../models/bid_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';

class PlaceBidScreen extends StatefulWidget {
  final ListingModel listing;
  
  const PlaceBidScreen({super.key, required this.listing});

  @override
  State<PlaceBidScreen> createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.listing.quantity.toString();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bid = BidModel(
        buyerId: UserService.currentUser!.uid,
        bidAmountPerUnit: double.parse(_amountController.text.trim()),
        quantity: double.parse(_quantityController.text.trim()),
        status: 'pending',
        message: _messageController.text.trim(),
      );

      await _marketplaceService.placeBid(widget.listing.id!, bid);

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid placed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the bottom padding based on keyboard visibility
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 24.0,
        bottom: bottomInset + 24.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Place a Bid', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Asking price: ₹${widget.listing.expectedPricePerUnit} / ${widget.listing.unit}', style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Your Bid (per ${widget.listing.unit})',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: widget.listing.unit,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0 || val > widget.listing.quantity) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message to Farmer (Optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: _submitBid,
                    child: const Text('Submit Bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
