import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';
import '../models/listing_model.dart';
import '../models/bid_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';
import 'invoice_screen.dart';
import 'place_bid_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final String _uid = UserService.currentUser?.uid ?? '';

  bool get _isOwner => widget.listing.farmerId == _uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.listing.cropName, 
                style: const TextStyle(fontWeight: FontWeight.w900, textBaseline: TextBaseline.alphabetic, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])
              ),
              background: Hero(
                tag: 'listing_image_${widget.listing.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.listing.images.isNotEmpty
                      ? widget.listing.images.first.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(widget.listing.images.first.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.green[100],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 60, color: Colors.green[800]),
                                      const SizedBox(height: 8),
                                      Text('Image failed to load', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              widget.listing.images.first, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.green[100],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 60, color: Colors.green[800]),
                                      const SizedBox(height: 8),
                                      Text('Image failed to load', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            )
                      : Container(
                          color: Colors.green[100],
                          child: Icon(Icons.grass, size: 100, color: Colors.green[800]),
                        ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.listing.status == 'active' ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.listing.status == 'active' ? Colors.green[200]! : Colors.red[200]!)
                        ),
                        child: Text(
                          widget.listing.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 0.5,
                            color: widget.listing.status == 'active' ? Colors.green[700] : Colors.red[700]
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Detail Cards
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.scale, 'Quantity', '${widget.listing.quantity} ${widget.listing.unit}')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoCard(Icons.currency_rupee, 'Expected Price', '₹${widget.listing.expectedPricePerUnit}')),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  if (_isOwner) ...[
                    Text('Incoming Bids', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    _buildBidsList(),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: !_isOwner && widget.listing.status == 'active'
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shadowColor: const Color(0xFF2E7D32).withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 64),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PlaceBidScreen(listing: widget.listing),
                  );
                },
                child: const Text('Place a Bid', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
          )
        : null,
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
        ],
      ),
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
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No bids received yet.', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length,
          itemBuilder: (context, index) {
            final bid = bids[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${bid.bidAmountPerUnit} / ${widget.listing.unit}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.blue[800])),
                            if (bid.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                intl.DateFormat('dd MMM yyyy, hh:mm a').format(bid.createdAt!.toDate()),
                                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                            ]
                          ],
                        ),
                        if (widget.listing.status == 'active' && bid.status == 'pending' && bid.latestOfferBy == 'farmer')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                            child: Text('WAITING FOR BUYER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange[800])),
                          )
                        else if (bid.status != 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bid.status == 'accepted' ? Colors.green[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Row(
                              children: [
                                Text(
                                  bid.status.toUpperCase(), 
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900, 
                                    color: bid.status == 'accepted' ? Colors.green[700] : Colors.grey[600]
                                  )
                                ),
                                if (bid.status == 'rejected') ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      await _marketplaceService.deleteBid(widget.listing.id!, bid.id!);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History deleted')));
                                      }
                                    },
                                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  ),
                                ]
                              ],
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Requested Quantity: ${bid.quantity} ${widget.listing.unit}', style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Total: ₹${bid.bidAmountPerUnit * bid.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    if (bid.message != null && bid.message!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                        child: Text('"${bid.message}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800])),
                      )
                    ],
                    if (widget.listing.status == 'active' && bid.status == 'pending' && bid.latestOfferBy == 'buyer') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                foregroundColor: Colors.red[800],
                                side: BorderSide(color: Colors.red[800]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await _marketplaceService.declineBid(widget.listing.id!, bid.id!, 'farmer');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Declined')));
                                }
                              },
                              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Decline', style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                foregroundColor: Colors.blue[800],
                                side: BorderSide(color: Colors.blue[800]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                _showCounterOfferDialog(context, bid, 'farmer');
                              },
                              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Counter', style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                backgroundColor: const Color(0xFFB8860B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await _marketplaceService.acceptBid(widget.listing.id!, bid.id!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid Accepted!')));
                                }
                              },
                              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Accept', style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ],
                      )
                    ],
                    if (bid.status == 'paid')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(bid: bid, listing: widget.listing)));
                          },
                          child: const Center(child: Text('View Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
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

  void _showCounterOfferDialog(BuildContext context, BidModel bid, String role) {
    final TextEditingController counterController = TextEditingController(text: bid.bidAmountPerUnit.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Counter Offer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: counterController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New Amount (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              onPressed: () async {
                final newAmount = double.tryParse(counterController.text);
                if (newAmount != null && newAmount > 0) {
                  Navigator.pop(context);
                  await _marketplaceService.counterBid(widget.listing.id!, bid.id!, newAmount, role);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counter offer sent!')));
                  }
                }
              },
              child: const Text('Send Counter'),
            )
          ],
        );
      }
    );
  }
}
