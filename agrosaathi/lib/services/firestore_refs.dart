import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRefs {

  static final firestore =
      FirebaseFirestore.instance;

  static CollectionReference users =
      firestore.collection('users');

  static CollectionReference cropCatalog =
      firestore.collection('cropCatalog');

  static CollectionReference recommendations =
      firestore.collection('recommendations');

  static CollectionReference diseaseDetections =
      firestore.collection('diseaseDetections');

  static CollectionReference growthPlans =
      firestore.collection('growthPlans');

  static CollectionReference listings =
      firestore.collection('listings');

  static Query bidsGroup =
      firestore.collectionGroup('bids');

  static CollectionReference bids(String listingId) =>
      listings.doc(listingId).collection('bids');
}