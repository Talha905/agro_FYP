import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../models/listing_model.dart';
import '../models/bid_model.dart';
import 'firestore_refs.dart';

class MarketplaceService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String listingId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('listings/$listingId/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> createListing(ListingModel listing, List<File> imageFiles) async {
    final docRef = FirestoreRefs.listings.doc();
    List<String> imageUrls = [];

    for (var file in imageFiles) {
      final url = await uploadListingImage(file, docRef.id);
      imageUrls.add(url);
    }

    final newListing = ListingModel(
      farmerId: listing.farmerId,
      cropId: listing.cropId,
      cropName: listing.cropName,
      quantity: listing.quantity,
      unit: listing.unit,
      expectedPricePerUnit: listing.expectedPricePerUnit,
      images: imageUrls,
      location: listing.location,
      geohash: listing.geohash,
      status: listing.status,
    );

    await docRef.set(newListing.toMap());
  }

  Stream<List<ListingModel>> getFarmerListings(String farmerId) {
    return FirestoreRefs.listings
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<ListingModel>> getNearbyListings(GeoPoint center, double radiusInKm) {
    return GeoCollectionReference(FirestoreRefs.listings)
        .subscribeWithin(
      center: GeoFirePoint(center),
      radiusInKm: radiusInKm,
      field: 'geohash',
      geopointFrom: (data) => (data as Map<String, dynamic>)['location'] as GeoPoint,
    ).map((docs) {
        return docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ListingModel.fromMap(data, doc.id);
        }).toList();
    });
  }

  Future<void> placeBid(String listingId, BidModel bid) async {
    final bidRef = FirestoreRefs.bids(listingId).doc();
    await bidRef.set(bid.toMap());
  }

  Stream<List<BidModel>> getListingBids(String listingId) {
    return FirestoreRefs.bids(listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BidModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> acceptBid(String listingId, String bidId) async {
    WriteBatch batch = FirestoreRefs.firestore.batch();
    
    // Accept the specific bid
    batch.update(FirestoreRefs.bids(listingId).doc(bidId), {'status': 'accepted'});
    
    // Mark listing as sold
    batch.update(FirestoreRefs.listings.doc(listingId), {'status': 'sold'});
    
    // Reject other pending bids (Simplified: just accepting this one is enough, 
    // but in a production app you might iterate over all others and mark rejected)
    
    await batch.commit();
    
    // Optional: add a notification document here to notify the buyer
  }
}
