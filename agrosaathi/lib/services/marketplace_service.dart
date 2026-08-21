import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../models/listing_model.dart';
import '../models/bid_model.dart';
import 'firestore_refs.dart';
import 'notification_service.dart';

class MarketplaceService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  Future<String> uploadListingImage(File imageFile, String listingId) async {
    try {
      // Because Firebase Storage now requires a paid Blaze plan for some new projects,
      // we will bypass Storage entirely and save the image directly in Firestore as a Base64 string!
      
      final bytes = await imageFile.readAsBytes();
      
      // Decode and heavily compress the image so it safely fits within Firestore's 1MB document limit
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception("Failed to decode image");
      
      // Resize to a max width of 600px while maintaining aspect ratio
      final resized = img.copyResize(image, width: 600);
      
      // Compress to 60% quality JPEG
      final compressedBytes = img.encodeJpg(resized, quality: 60);
      
      // Convert to Base64 string
      final base64Str = base64Encode(compressedBytes);
      
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      throw Exception("Failed to process image: $e");
    }
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
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs
            .map((doc) =>
                ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
           list.sort((a, b) => (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
           return list;
        });
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
    }).asBroadcastStream();
  }

  Future<void> placeBid(String listingId, BidModel bid) async {
    final bidRef = FirestoreRefs.bids(listingId).doc();
    await bidRef.set(bid.toMap());

    // Send notification to farmer
    final listingDoc = await FirestoreRefs.listings.doc(listingId).get();
    if (listingDoc.exists) {
      final listing = ListingModel.fromMap(listingDoc.data() as Map<String, dynamic>, listingDoc.id);
      await _notificationService.sendNotification(
        userId: listing.farmerId,
        title: 'New Bid Received!',
        body: 'Someone bid ₹${bid.bidAmountPerUnit} for your ${listing.cropName}.',
        listingId: listingId,
      );
    }
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
    
    final bidDoc = await FirestoreRefs.bids(listingId).doc(bidId).get();
    if (!bidDoc.exists) return;
    final bidData = bidDoc.data() as Map<String, dynamic>;
    final buyerId = bidData['buyerId'];
    
    // Accept the specific bid
    batch.update(FirestoreRefs.bids(listingId).doc(bidId), {'status': 'accepted'});
    
    // Mark listing as sold
    batch.update(FirestoreRefs.listings.doc(listingId), {'status': 'sold'});
    
    // Reject other pending bids
    final otherBidsQuery = await FirestoreRefs.bids(listingId)
        .where('status', isEqualTo: 'pending')
        .get();
        
    for (var doc in otherBidsQuery.docs) {
      if (doc.id != bidId) {
        batch.update(doc.reference, {'status': 'rejected'});
        
        // Notify rejected buyers
        final otherBuyerId = (doc.data() as Map<String, dynamic>)['buyerId'];
        await _notificationService.sendNotification(
          userId: otherBuyerId,
          title: 'Bid Rejected',
          body: 'Your bid was rejected as the listing was sold to someone else.',
          listingId: listingId,
        );
      }
    }
    
    await batch.commit();

    // Notify accepted buyer
    final listingDoc = await FirestoreRefs.listings.doc(listingId).get();
    final listing = ListingModel.fromMap(listingDoc.data() as Map<String, dynamic>, listingDoc.id);
    await _notificationService.sendNotification(
      userId: buyerId,
      title: 'Bid Accepted!',
      body: 'Your bid of ₹${bidData['bidAmountPerUnit']} for ${listing.cropName} was accepted!',
      listingId: listingId,
    );
  }

  Future<void> counterBid(String listingId, String bidId, double newAmount, String counterBy) async {
    final bidRef = FirestoreRefs.bids(listingId).doc(bidId);
    
    await bidRef.update({
      'bidAmountPerUnit': newAmount,
      'latestOfferBy': counterBy,
    });

    final bidDoc = await bidRef.get();
    final bidData = bidDoc.data() as Map<String, dynamic>;
    final buyerId = bidData['buyerId'];

    final listingDoc = await FirestoreRefs.listings.doc(listingId).get();
    final listing = ListingModel.fromMap(listingDoc.data() as Map<String, dynamic>, listingDoc.id);

    final targetUserId = counterBy == 'farmer' ? buyerId : listing.farmerId;
    final counterRole = counterBy == 'farmer' ? 'Farmer' : 'Buyer';

    await _notificationService.sendNotification(
      userId: targetUserId,
      title: 'New Counter Offer',
      body: 'The $counterRole countered with ₹$newAmount for ${listing.cropName}.',
      listingId: listingId,
    );
  }

  Future<void> declineBid(String listingId, String bidId, String declinedByRole) async {
    final bidRef = FirestoreRefs.bids(listingId).doc(bidId);
    await bidRef.update({'status': 'rejected'});

    final bidDoc = await bidRef.get();
    final bidData = bidDoc.data() as Map<String, dynamic>;
    final buyerId = bidData['buyerId'];

    final listingDoc = await FirestoreRefs.listings.doc(listingId).get();
    final listing = ListingModel.fromMap(listingDoc.data() as Map<String, dynamic>, listingDoc.id);

    final targetUserId = declinedByRole == 'farmer' ? buyerId : listing.farmerId;
    final declinerRoleString = declinedByRole == 'farmer' ? 'Farmer' : 'Buyer';

    await _notificationService.sendNotification(
      userId: targetUserId,
      title: 'Offer Declined',
      body: 'The $declinerRoleString has declined the offer for ${listing.cropName}.',
      listingId: listingId,
    );
  }

  Future<void> processPayment(String listingId, String bidId) async {
    final bidRef = FirestoreRefs.bids(listingId).doc(bidId);
    await bidRef.update({'status': 'paid'});

    final bidDoc = await bidRef.get();
    final bidData = bidDoc.data() as Map<String, dynamic>;
    final buyerId = bidData['buyerId'];

    final listingDoc = await FirestoreRefs.listings.doc(listingId).get();
    final listing = ListingModel.fromMap(listingDoc.data() as Map<String, dynamic>, listingDoc.id);

    // Notify farmer about successful payment
    await _notificationService.sendNotification(
      userId: listing.farmerId,
      title: 'Payment Received!',
      body: 'The buyer has successfully paid ₹${bidData['bidAmountPerUnit'] * bidData['quantity']} for ${listing.cropName}.',
      listingId: listingId,
    );
    
    // Notify buyer about invoice
    await _notificationService.sendNotification(
      userId: buyerId,
      title: 'Payment Successful',
      body: 'Your payment for ${listing.cropName} is complete. You can now view the invoice.',
      listingId: listingId,
    );
  }

  Future<void> deleteBid(String listingId, String bidId) async {
    await FirestoreRefs.bids(listingId).doc(bidId).delete();
  }

  Stream<List<ListingModel>> getAllActiveListings() {

    return FirestoreRefs.listings
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
          list.sort((a, b) => (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
          return list;
        });
  }

  Stream<List<Map<String, dynamic>>> getBuyerBidsWithListingInfoStream(String buyerId) {
    return FirestoreRefs.firestore.collectionGroup('bids')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .asyncMap((bidsSnapshot) async {
      List<Map<String, dynamic>> results = [];
      
      for (var bidDoc in bidsSnapshot.docs) {
        final bid = BidModel.fromMap(bidDoc.data(), bidDoc.id);
        
        final listingRef = bidDoc.reference.parent.parent;
        if (listingRef != null) {
          final listingDoc = await listingRef.get();
          if (listingDoc.exists) {
            final listing = ListingModel.fromMap(listingDoc.data()!, listingDoc.id);
            results.add({
              'bid': bid,
              'listing': listing,
            });
          }
        }
      }
      
      results.sort((a, b) {
        final bidA = a['bid'] as BidModel;
        final bidB = b['bid'] as BidModel;
        return (bidB.createdAt ?? Timestamp.now()).compareTo(bidA.createdAt ?? Timestamp.now());
      });
      
      return results;
    });
  }
}
