import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';

import '../models/listing_model.dart';
import '../models/bid_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'invoice_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final String _role = (UserService.currentUser?.role ?? 'farmer').toLowerCase();

  // For Buyer Map
  GoogleMapController? _mapController;
  GeoPoint _buyerCenter = UserService.currentUser?.location ?? const GeoPoint(19.0760, 72.8777); // Default Mumbai
  
  late Stream<List<ListingModel>> _nearbyListingsStream;
  late Stream<List<ListingModel>> _allActiveListingsStream;
  late Stream<List<Map<String, dynamic>>> _myBidsStream;
  late Stream<List<ListingModel>> _myListingsStream;
  
  final PageController _mapPageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _fetchRealLocation();
    
    _nearbyListingsStream = _marketplaceService.getNearbyListings(_buyerCenter, 50.0);
    _allActiveListingsStream = _marketplaceService.getAllActiveListings();
    
    final buyerId = UserService.currentUser?.uid ?? '';
    _myBidsStream = _marketplaceService.getBuyerBidsWithListingInfoStream(buyerId);
    _myListingsStream = _marketplaceService.getFarmerListings(buyerId);
  }

  Future<void> _fetchRealLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _buyerCenter = GeoPoint(pos.latitude, pos.longitude);
        _nearbyListingsStream = _marketplaceService.getNearbyListings(_buyerCenter, 50.0);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    }
  }
  @override
  Widget build(BuildContext context) {
    final buyerId = UserService.currentUser?.uid ?? '';
    final isFarmer = _role == 'farmer';
    
    final tabs = <Tab>[
      const Tab(text: 'Map'),
      const Tab(text: 'All Crops'),
      const Tab(text: 'My Bids'),
    ];
    if (isFarmer) {
      tabs.add(const Tab(text: 'My Listings'));
    }
    
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          toolbarHeight: 0, // Hide the duplicate title, keep only the TabBar
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // TAB 1: MAP VIEW
            StreamBuilder<List<ListingModel>>(
              stream: _nearbyListingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
      
                final listings = snapshot.data ?? [];
                final activeListings = listings.where((l) => l.status == 'active').toList();
      
                Set<Marker> markers = activeListings.asMap().entries.map((entry) {
                  int idx = entry.key;
                  ListingModel l = entry.value;
                  return Marker(
                    markerId: MarkerId(l.id!),
                    position: LatLng(l.location!.latitude, l.location!.longitude),
                    onTap: () {
                      _mapPageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  );
                }).toSet();
      
                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_buyerCenter.latitude, _buyerCenter.longitude),
                        zoom: 10,
                      ),
                      markers: markers,
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    if (activeListings.isNotEmpty)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        height: 140,
                        child: PageView.builder(
                          controller: _mapPageController,
                          itemCount: activeListings.length,
                          onPageChanged: (int index) {
                            final listing = activeListings[index];
                            if (listing.location != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(listing.location!.latitude, listing.location!.longitude),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: _buildMapListingCard(activeListings[index]),
                            );
                          },
                        ),
                      ),
                    if (activeListings.isEmpty)
                      Positioned(
                        top: 24,
                        left: 24,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: const Text(
                            'No active listings found near your location.', 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        )
                      )
                  ],
                );
              },
            ),
            
            // TAB 2: LIST VIEW
            StreamBuilder<List<ListingModel>>(
              stream: _allActiveListingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                }
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                
                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No crops available right now.', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    return _buildListingCard(listings[index]);
                  },
                );
              },
            ),
            
            // TAB 3: MY BIDS
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _myBidsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                }
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('You haven\'t placed any bids yet.', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: () async {
                    setState(() {}); // Rebuild to refetch the Future
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final data = results[index];
                      final bid = data['bid'] as BidModel;
                      final listing = data['listing'] as ListingModel;
                      
                      Color statusColor = Colors.orange;
                      IconData statusIcon = Icons.access_time;
                      if (bid.status == 'accepted') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      } else if (bid.status == 'rejected') {
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(listing.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text('Current Price: ₹${bid.bidAmountPerUnit} / ${listing.unit}', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue[800], fontSize: 16)),
                                    Text('Requested Quantity: ${bid.quantity} ${listing.unit}'),
                                    const SizedBox(height: 4),
                                    Text('Total: ₹${bid.bidAmountPerUnit * bid.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                    if (bid.createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Placed on: ${intl.DateFormat('dd MMM yyyy, hh:mm a').format(bid.createdAt!.toDate())}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (bid.status == 'pending' && bid.latestOfferBy == 'buyer') ...[
                                      const Icon(Icons.access_time, color: Colors.grey, size: 28),
                                      const SizedBox(height: 4),
                                      const Text('WAITING', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ] else if (bid.status == 'pending' && bid.latestOfferBy == 'farmer') ...[
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                      const SizedBox(height: 4),
                                      const Text('ACTION REQUIRED', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ] else ...[
                                      Icon(statusIcon, color: statusColor, size: 28),
                                      const SizedBox(height: 4),
                                      Text(bid.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                                      if (bid.status == 'rejected')
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.only(top: 8),
                                          onPressed: () async {
                                            await _marketplaceService.deleteBid(listing.id!, bid.id!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History deleted')));
                                              setState(() {});
                                            }
                                          },
                                        )
                                    ]
                                  ],
                                ),
                              ),
                              if (bid.status == 'pending' && bid.latestOfferBy == 'farmer')
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  child: Row(
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
                                            await _marketplaceService.declineBid(listing.id!, bid.id!, 'buyer');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Declined')));
                                              setState(() {});
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
                                            _showCounterOfferDialog(context, bid, listing.id!, 'buyer');
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
                                            await _marketplaceService.acceptBid(listing.id!, bid.id!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Accepted!')));
                                              setState(() {}); // refresh FutureBuilder
                                            }
                                          },
                                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Accept', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (bid.status == 'accepted')
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      _showPaymentDialog(context, bid, listing.id!);
                                    },
                                    child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              if (bid.status == 'paid')
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2E7D32),
                                      side: const BorderSide(color: Color(0xFF2E7D32)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(bid: bid, listing: listing)));
                                    },
                                    child: const Text('View Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            // TAB 4: MY LISTINGS (Farmers Only)
            if (isFarmer)
              Stack(
                children: [
                  StreamBuilder<List<ListingModel>>(
                    stream: _myListingsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final listings = snapshot.data ?? [];
                      if (listings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No active listings yet.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to sell your crop.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
            
                      return ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 100),
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          return _buildListingCard(listings[index]);
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton.extended(
                      backgroundColor: const Color(0xFF2E7D32),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen()));
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("New Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section
                Stack(
                  children: [
                    Hero(
                      tag: 'listing_image_${listing.id}',
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: listing.images.isNotEmpty
                            ? listing.images.first.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(listing.images.first.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                                  )
                                : Image.network(
                                    listing.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                                  )
                            : Icon(Icons.eco, size: 80, color: Colors.green[200]),
                      ),
                    ),
                    // Status Badge overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: listing.status == 'active' ? Colors.greenAccent.withOpacity(0.9) : Colors.redAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Text(
                          listing.status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.cropName, 
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                if (listing.location != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(Geolocator.distanceBetween(_buyerCenter.latitude, _buyerCenter.longitude, listing.location!.latitude, listing.location!.longitude) / 1000).toStringAsFixed(1)} km away',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.currency_rupee, size: 20, color: Colors.blue[800]),
                              Text(
                                '${listing.expectedPricePerUnit}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue[800]),
                              ),
                              Text(
                                ' / ${listing.unit}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity Available: ${listing.quantity} ${listing.unit}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          if (listing.createdAt != null)
                            Text(
                              intl.DateFormat('dd MMM yyyy').format(listing.createdAt!.toDate()),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                            ),
                        ],
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

  Widget _buildMapListingCard(ListingModel listing) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
            },
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: double.infinity,
                  child: listing.images.isNotEmpty
                      ? listing.images.first.startsWith('data:image')
                          ? Image.memory(base64Decode(listing.images.first.split(',').last), fit: BoxFit.cover)
                          : Image.network(listing.images.first, fit: BoxFit.cover)
                      : Container(color: Colors.green[100], child: Icon(Icons.eco, color: Colors.green[800], size: 40)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          listing.cropName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${listing.expectedPricePerUnit} / ${listing.unit}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${listing.quantity} ${listing.unit}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(Geolocator.distanceBetween(_buyerCenter.latitude, _buyerCenter.longitude, listing.location!.latitude, listing.location!.longitude) / 1000).toStringAsFixed(1)} km away',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800]),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCounterOfferDialog(BuildContext context, BidModel bid, String listingId, String role) {
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
                  await _marketplaceService.counterBid(listingId, bid.id!, newAmount, role);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counter offer sent!')));
                    setState(() {}); // refresh My Bids FutureBuilder
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

  void _showPaymentDialog(BuildContext context, BidModel bid, String listingId) {
    bool isProcessing = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total Amount: ₹${bid.bidAmountPerUnit * bid.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (isProcessing)
                    const CircularProgressIndicator(color: Color(0xFF2E7D32))
                  else
                    const Text('This is a simulated payment flow.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              actions: [
                if (!isProcessing)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isProcessing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                    onPressed: () async {
                      setState(() => isProcessing = true);
                      await Future.delayed(const Duration(seconds: 2)); // Simulate network request
                      await _marketplaceService.processPayment(listingId, bid.id!);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
                        this.setState(() {}); // refresh My Bids FutureBuilder
                      }
                    },
                    child: const Text('Confirm Payment'),
                  )
              ],
            );
          }
        );
      }
    );
  }
}