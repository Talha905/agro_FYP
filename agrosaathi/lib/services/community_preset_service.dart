import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation_model.dart';
import 'location_service.dart';
import 'user_service.dart';

class CommunityPreset {
  final String id;
  final String title;
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
  final bool isSeed;

  CommunityPreset({
    required this.id,
    this.title = 'Standard',
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
    this.isSeed = false,
  });

  int get voteScore => usefulVotes - notUsefulVotes;

  factory CommunityPreset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityPreset(
      id: doc.id,
      title: data['title'] ?? 'Community Favorite',
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
      isSeed: data['isSeed'] == true,
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
    final cleanDistrict = LocationService.extractBroadDistrict(district);
    final distSlug = cleanDistrict.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final binnedSize = binFarmSize(farmSizeAcres);
    return '${distSlug}_${soilType.toLowerCase()}_${season.toLowerCase()}_${waterAvailability.toLowerCase()}_$binnedSize';
  }

  /// Built-in realistic seed presets (3 variants per soil type: Standard, High Yield, Low Input)
  static List<CommunityPreset> getSeedPresets(String soilType, String district) {
    final cleanDist = LocationService.extractBroadDistrict(district);
    final st = soilType.toLowerCase();

    final Map<String, List<Map<String, dynamic>>> seedsConfig = {
      'black': [
        {'title': 'Standard Baseline', 'n': 90.0, 'p': 45.0, 'k': 50.0, 'ph': 7.4, 'water': 'medium', 'season': 'kharif'},
        {'title': 'High-Yield Intensive', 'n': 120.0, 'p': 60.0, 'k': 60.0, 'ph': 7.2, 'water': 'high', 'season': 'kharif'},
        {'title': 'Low-Input / Organic', 'n': 60.0, 'p': 30.0, 'k': 35.0, 'ph': 7.5, 'water': 'low', 'season': 'kharif'},
      ],
      'alluvial': [
        {'title': 'Standard Baseline', 'n': 75.0, 'p': 35.0, 'k': 40.0, 'ph': 6.8, 'water': 'medium', 'season': 'rabi'},
        {'title': 'High-Yield Intensive', 'n': 105.0, 'p': 50.0, 'k': 55.0, 'ph': 6.7, 'water': 'high', 'season': 'rabi'},
        {'title': 'Low-Input / Organic', 'n': 50.0, 'p': 25.0, 'k': 30.0, 'ph': 6.9, 'water': 'low', 'season': 'rabi'},
      ],
      'red': [
        {'title': 'Standard Baseline', 'n': 60.0, 'p': 30.0, 'k': 35.0, 'ph': 5.8, 'water': 'low', 'season': 'kharif'},
        {'title': 'Balanced Nutrient', 'n': 80.0, 'p': 40.0, 'k': 45.0, 'ph': 6.0, 'water': 'medium', 'season': 'kharif'},
        {'title': 'Low-Input / Organic', 'n': 45.0, 'p': 20.0, 'k': 25.0, 'ph': 5.7, 'water': 'low', 'season': 'kharif'},
      ],
      'sandy': [
        {'title': 'Standard Baseline', 'n': 50.0, 'p': 25.0, 'k': 30.0, 'ph': 6.5, 'water': 'low', 'season': 'zaid'},
        {'title': 'Frequent Fertigation', 'n': 75.0, 'p': 35.0, 'k': 40.0, 'ph': 6.4, 'water': 'medium', 'season': 'zaid'},
        {'title': 'Organic Compost', 'n': 40.0, 'p': 20.0, 'k': 25.0, 'ph': 6.6, 'water': 'low', 'season': 'zaid'},
      ],
      'clay': [
        {'title': 'Standard Baseline', 'n': 85.0, 'p': 40.0, 'k': 45.0, 'ph': 7.1, 'water': 'high', 'season': 'kharif'},
        {'title': 'Heavy Feeder Variant', 'n': 110.0, 'p': 55.0, 'k': 55.0, 'ph': 7.0, 'water': 'high', 'season': 'kharif'},
        {'title': 'Low-Input / Organic', 'n': 55.0, 'p': 30.0, 'k': 35.0, 'ph': 7.2, 'water': 'medium', 'season': 'kharif'},
      ],
      'loamy': [
        {'title': 'Standard Baseline', 'n': 70.0, 'p': 35.0, 'k': 40.0, 'ph': 6.6, 'water': 'medium', 'season': 'rabi'},
        {'title': 'Optimal Harvest Boost', 'n': 95.0, 'p': 45.0, 'k': 50.0, 'ph': 6.5, 'water': 'high', 'season': 'rabi'},
        {'title': 'Low-Input / Organic', 'n': 50.0, 'p': 25.0, 'k': 30.0, 'ph': 6.7, 'water': 'medium', 'season': 'rabi'},
      ],
    };

    final variants = seedsConfig[st] ?? seedsConfig['black']!;

    return variants.asMap().entries.map((entry) {
      final idx = entry.key;
      final cfg = entry.value;
      return CommunityPreset(
        id: 'seed_${st}_$idx',
        title: cfg['title'] as String,
        district: cleanDist,
        soilType: st,
        season: cfg['season'] as String,
        waterAvailability: cfg['water'] as String,
        binnedFarmSize: '2.1-5.0',
        farmSizeAcres: 2.0,
        nitrogen: cfg['n'] as double,
        phosphorus: cfg['p'] as double,
        potassium: cfg['k'] as double,
        ph: cfg['ph'] as double,
        usefulVotes: 0,
        notUsefulVotes: 0,
        totalVotes: 0,
        isSeed: true,
      );
    }).toList();
  }

  /// Fetches top 3 presets ranked by score (usefulVotes - notUsefulVotes).
  /// Real community presets rank above seeds.
  /// Unfilled slots up to 3 are filled with typical seed variants for the soil type.
  static Future<List<CommunityPreset>> fetchPresetsForUser({
    required String district,
    required String soilType,
  }) async {
    final cleanDist = LocationService.extractBroadDistrict(district);
    final List<CommunityPreset> communityList = [];

    try {
      final snap = await _db
          .collection('community_crop_presets')
          .where('district', isEqualTo: cleanDist)
          .limit(10)
          .get();

      final fetched = snap.docs.map((d) => CommunityPreset.fromFirestore(d)).toList();
      communityList.addAll(fetched);
    } catch (_) {}

    // Sort community presets by score (usefulVotes - notUsefulVotes), tiebreaker usefulVotes
    communityList.sort((a, b) {
      final scoreCompare = b.voteScore.compareTo(a.voteScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.usefulVotes.compareTo(a.usefulVotes);
    });

    final List<CommunityPreset> result = [];
    result.addAll(communityList.take(3));

    // Fill remaining slots up to 3 using typical seed presets for this soil type
    if (result.length < 3) {
      final seeds = getSeedPresets(soilType, district);
      for (final seed in seeds) {
        if (result.length >= 3) break;
        if (!result.any((r) => r.id == seed.id || (r.nitrogen == seed.nitrogen && r.phosphorus == seed.phosphorus))) {
          result.add(seed);
        }
      }
    }

    return result.take(3).toList();
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
