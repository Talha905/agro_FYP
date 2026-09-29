import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation_model.dart';
import 'user_service.dart';

class CommunityPreset {
  final String id;
  final String district;
  final String soilType;
  final String season;
  final String waterAvailability;
  final String binnedFarmSize;
  final double farmSizeAcres;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? ph;
  final int usefulVotes;
  final int notUsefulVotes;
  final int totalVotes;

  CommunityPreset({
    required this.id,
    required this.district,
    required this.soilType,
    required this.season,
    required this.waterAvailability,
    required this.binnedFarmSize,
    required this.farmSizeAcres,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.ph,
    required this.usefulVotes,
    required this.notUsefulVotes,
    required this.totalVotes,
  });

  factory CommunityPreset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityPreset(
      id: doc.id,
      district: data['district'] ?? '',
      soilType: data['soilType'] ?? 'black',
      season: data['season'] ?? 'kharif',
      waterAvailability: data['waterAvailability'] ?? 'medium',
      binnedFarmSize: data['binnedFarmSize'] ?? '2.1-5.0',
      farmSizeAcres: (data['farmSizeAcres'] as num?)?.toDouble() ?? 2.0,
      nitrogen: (data['nitrogen'] as num?)?.toDouble(),
      phosphorus: (data['phosphorus'] as num?)?.toDouble(),
      potassium: (data['potassium'] as num?)?.toDouble(),
      ph: (data['ph'] as num?)?.toDouble(),
      usefulVotes: (data['usefulVotes'] as num?)?.toInt() ?? 0,
      notUsefulVotes: (data['notUsefulVotes'] as num?)?.toInt() ?? 0,
      totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityPresetService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String binFarmSize(double acres) {
    if (acres <= 2.0) return '0.5-2.0';
    if (acres <= 5.0) return '2.1-5.0';
    if (acres <= 10.0) return '5.1-10.0';
    return '10.0+';
  }

  static String generatePresetKey({
    required String district,
    required String soilType,
    required String season,
    required String waterAvailability,
    required double farmSizeAcres,
  }) {
    final distSlug = district.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final binnedSize = binFarmSize(farmSizeAcres);
    return '${distSlug}_${soilType.toLowerCase()}_${season.toLowerCase()}_${waterAvailability.toLowerCase()}_$binnedSize';
  }

  /// Fetches top community presets for a district requiring minimum 3 useful votes
  static Future<List<CommunityPreset>> fetchTopCommunityPresets(String district) async {
    try {
      final snap = await _db
          .collection('community_crop_presets')
          .where('district', isEqualTo: district)
          .where('usefulVotes', isGreaterThanOrEqualTo: 3)
          .orderBy('usefulVotes', descending: true)
          .limit(3)
          .get();

      return snap.docs.map((d) => CommunityPreset.fromFirestore(d)).toList();
    } catch (_) {}
    return [];
  }

  /// Records a user vote ("useful" or "not_useful") transactionally.
  /// Enforces one vote document per user per recommendation setup.
  static Future<bool> recordRecommendationVote({
    required RecommendationInput input,
    required bool isUseful,
  }) async {
    final userId = UserService.currentUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final presetKey = generatePresetKey(
      district: input.district,
      soilType: input.soilType,
      season: input.season,
      waterAvailability: input.waterAvailability,
      farmSizeAcres: input.farmSizeAcres,
    );

    final voteDocRef = _db.collection('recommendation_votes').doc('${userId}_$presetKey');
    final presetDocRef = _db.collection('community_crop_presets').doc(presetKey);

    try {
      return await _db.runTransaction<bool>((transaction) async {
        final voteSnap = await transaction.get(voteDocRef);
        final bool alreadyVoted = voteSnap.exists;
        final String? previousVote = alreadyVoted ? (voteSnap.data()?['vote'] as String?) : null;

        final newVoteStr = isUseful ? 'useful' : 'not_useful';

        if (alreadyVoted && previousVote == newVoteStr) {
          // Same vote already cast; no-op
          return true;
        }

        // 1. Record / update vote doc
        transaction.set(voteDocRef, {
          'userId': userId,
          'presetKey': presetKey,
          'district': input.district,
          'vote': newVoteStr,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Transactionally update preset counts
        final presetSnap = await transaction.get(presetDocRef);
        if (!presetSnap.exists) {
          transaction.set(presetDocRef, {
            'district': input.district,
            'soilType': input.soilType,
            'season': input.season,
            'waterAvailability': input.waterAvailability,
            'binnedFarmSize': binFarmSize(input.farmSizeAcres),
            'farmSizeAcres': input.farmSizeAcres,
            'nitrogen': input.nitrogen,
            'phosphorus': input.phosphorus,
            'potassium': input.potassium,
            'ph': input.ph,
            'usefulVotes': isUseful ? 1 : 0,
            'notUsefulVotes': isUseful ? 0 : 1,
            'totalVotes': 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          int usefulInc = 0;
          int notUsefulInc = 0;

          if (isUseful) {
            usefulInc = 1;
            if (previousVote == 'not_useful') notUsefulInc = -1;
          } else {
            notUsefulInc = 1;
            if (previousVote == 'useful') usefulInc = -1;
          }

          transaction.update(presetDocRef, {
            'usefulVotes': FieldValue.increment(usefulInc),
            'notUsefulVotes': FieldValue.increment(notUsefulInc),
            'totalVotes': FieldValue.increment(alreadyVoted ? 0 : 1),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        return true;
      });
    } catch (_) {
      return false;
    }
  }
}
