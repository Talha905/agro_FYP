import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../models/listing_model.dart';
import '../services/marketplace_service.dart';
import '../services/user_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedUnit = 'kg';
  List<File> _images = [];
  bool _isLoading = false;
  GeoPoint? _currentLocation;
  String? _geohash;

  final MarketplaceService _marketplaceService = MarketplaceService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    } 

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = GeoPoint(position.latitude, position.longitude);
      _geohash = GeoFirePoint(_currentLocation!).geohash;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location acquired successfully!')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    if (_currentLocation == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your current location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final listing = ListingModel(
        farmerId: UserService.currentUser!.uid,
        cropId: 'temp_id', // Would normally come from cropCatalog selection
        cropName: _cropNameController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        expectedPricePerUnit: double.parse(_priceController.text.trim()),
        location: _currentLocation,
        geohash: _geohash,
        status: 'active',
      );

      await _marketplaceService.createListing(listing, _images);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFAF9F4),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Crop Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cropNameController,
                    decoration: InputDecoration(
                      labelText: 'Crop Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          items: ['kg', 'quintal'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => _selectedUnit = val!),
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Expected Price per $_selectedUnit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Images', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._images.map((img) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0, top: 0,
                            child: InkWell(
                              onTap: () => setState(() => _images.remove(img)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                              ),
                            ),
                          )
                        ],
                      )),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF6B6B6B)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_a_photo, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
                    label: Text(_currentLocation == null ? 'Get Current Location' : 'Location Acquired', style: const TextStyle(color: Color(0xFF1976D2))),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Publish Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
