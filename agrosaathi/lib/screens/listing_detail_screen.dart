import 'package:flutter/material.dart';

import '../models/listing_model.dart';
import '../models/bid_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';
import 'place_bid_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final String _role = UserService.currentUser?.role ?? 'farmer';
  final String _uid = UserService.currentUser?.uid ?? '';

  bool get _isOwner => _role == 'farmer' && widget.listing.farmerId == _uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        title: Text(widget.listing.cropName),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.listing.images.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(widget.listing.images.first, fit: BoxFit.cover),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.grass, size: 80, color: Color(0xFF6B6B6B)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.listing.cropName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.listing.status == 'active' ? const Color(0xFF43A047).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Text(
                          widget.listing.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: widget.listing.status == 'active' ? const Color(0xFF43A047) : Colors.red
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quantity: ${widget.listing.quantity} ${widget.listing.unit}',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF6B6B6B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expected Price: ₹${widget.listing.expectedPricePerUnit} / ${widget.listing.unit}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
                  ),
                  
                  const SizedBox(height: 32),
                  if (_isOwner) ...[
                    const Text('Incoming Bids', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildBidsList(),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: _role == 'buyer' && widget.listing.status == 'active'
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => PlaceBidScreen(listing: widget.listing),
                );
              },
              child: const Text('Place Bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        : null,
    );
  }

  Widget _buildBidsList() {
    return StreamBuilder<List<BidModel>>(
      stream: _marketplaceService.getListingBids(widget.listing.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final bids = snapshot.data ?? [];
        if (bids.isEmpty) {
          return const Text('No bids yet.', style: TextStyle(color: Color(0xFF6B6B6B)));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length,
          itemBuilder: (context, index) {
            final bid = bids[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bid: ₹${bid.bidAmountPerUnit} / ${widget.listing.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Quantity: ${bid.quantity} ${widget.listing.unit}', style: const TextStyle(color: Color(0xFF6B6B6B))),
                          if (bid.message != null && bid.message!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('"${bid.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ]
                        ],
                      ),
                    ),
                    if (widget.listing.status == 'active' && bid.status == 'pending')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8860B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await _marketplaceService.acceptBid(widget.listing.id!, bid.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bid Accepted!')),
                            );
                            Navigator.pop(context); // Go back after accepting
                          }
                        },
                        child: const Text('Accept'),
                      )
                    else 
                      Text(
                        bid.status.toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: bid.status == 'accepted' ? const Color(0xFF43A047) : Colors.grey
                        )
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
