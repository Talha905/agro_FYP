import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/listing_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final String _role = UserService.currentUser?.role ?? 'farmer';

  // For Buyer Map
  GoogleMapController? _mapController;
  final GeoPoint _buyerCenter = UserService.currentUser?.location ?? const GeoPoint(19.0760, 72.8777); // Default Mumbai
  
  @override
  Widget build(BuildContext context) {
    if (_role == 'farmer') {
      return _buildFarmerView();
    } else {
      return _buildBuyerView();
    }
  }

  Widget _buildFarmerView() {
    final farmerId = UserService.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ListingModel>>(
        stream: _marketplaceService.getFarmerListings(farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const Center(
              child: Text(
                'No active listings. Tap + to create one.',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return _buildListingCard(listing);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBuyerView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        title: const Text('Nearby Crops', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ListingModel>>(
        // Hardcoded 50km radius for now
        stream: _marketplaceService.getNearbyListings(_buyerCenter, 50.0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final listings = snapshot.data ?? [];
          final activeListings = listings.where((l) => l.status == 'active').toList();

          Set<Marker> markers = activeListings.map((l) {
            return Marker(
              markerId: MarkerId(l.id!),
              position: LatLng(l.location!.latitude, l.location!.longitude),
              infoWindow: InfoWindow(
                title: '${l.cropName} (${l.quantity} ${l.unit})',
                snippet: '₹${l.expectedPricePerUnit}/${l.unit}',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: l)));
                }
              ),
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
              ),
              if (activeListings.isEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text('No active listings found nearby.', textAlign: TextAlign.center),
                    ),
                  )
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: listing.images.isNotEmpty 
                    ? DecorationImage(image: NetworkImage(listing.images.first), fit: BoxFit.cover)
                    : null
                ),
                child: listing.images.isEmpty ? const Icon(Icons.grass, color: Color(0xFF6B6B6B)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.cropName, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF212121))
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.quantity} ${listing.unit}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${listing.expectedPricePerUnit} / ${listing.unit}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: listing.status == 'active' ? const Color(0xFF43A047).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                  listing.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: listing.status == 'active' ? const Color(0xFF43A047) : Colors.red
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}