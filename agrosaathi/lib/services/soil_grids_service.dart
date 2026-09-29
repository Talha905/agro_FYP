import 'dart:convert';
import 'package:http/http.dart' as http;

class SoilPropertyData {
  final String soilType; // black/clay, sandy, loamy/alluvial, red
  final double sandPercent;
  final double clayPercent;
  final double siltPercent;
  final double ph;

  SoilPropertyData({
    required this.soilType,
    required this.sandPercent,
    required this.clayPercent,
    required this.siltPercent,
    required this.ph,
  });
}

class SoilGridsService {
  /// Queries ISRIC SoilGrids 2.0 API for soil properties (sand, clay, silt, pH) by (lat, lon)
  /// and maps them to standard agricultural soil types.
  static Future<SoilPropertyData?> fetchSoilProperties(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://rest.isric.org/soilgrids/v2.0/properties/query?'
        'lon=$lon&lat=$lat&property=clay&property=sand&property=silt&property=phh2o&depth=0-5cm&value=mean',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final layers = data['properties']?['layers'] as List?;
        if (layers != null) {
          double sand = 33.0;
          double clay = 33.0;
          double silt = 33.0;
          double ph = 6.8;

          for (var layer in layers) {
            final name = layer['name'];
            final depths = layer['depths'] as List?;
            if (depths != null && depths.isNotEmpty) {
              final val = depths[0]['values']?['mean'];
              if (val != null) {
                final dVal = (val as num).toDouble();
                if (name == 'sand') sand = dVal / 10.0;
                if (name == 'clay') clay = dVal / 10.0;
                if (name == 'silt') silt = dVal / 10.0;
                if (name == 'phh2o') ph = dVal / 10.0;
              }
            }
          }

          String soilType = 'loamy';
          if (clay > 40) {
            soilType = 'black';
          } else if (sand > 50) {
            soilType = 'sandy';
          } else if (silt > 40) {
            soilType = 'alluvial';
          } else if (ph < 5.8) {
            soilType = 'red';
          }

          return SoilPropertyData(
            soilType: soilType,
            sandPercent: sand,
            clayPercent: clay,
            siltPercent: silt,
            ph: ph,
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
