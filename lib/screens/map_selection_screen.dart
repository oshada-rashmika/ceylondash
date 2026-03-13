import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../widgets/top_snackbar.dart';

class MapSelectionResult {
  final String address;
  final double latitude;
  final double longitude;

  const MapSelectionResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  final MapController _mapController = MapController();

  LatLng _center = _defaultCenter;
  bool _isDragging = false;
  bool _isLoading = false;
  bool _isResolvingPreview = false;
  String _selectedAddress = 'Move the map to choose your location';
  bool _hasResolvedAddress = false;

  @override
  void initState() {
    super.initState();
    _resolvePreviewAddress();
  }

  Future<void> _resolvePreviewAddress() async {
    if (_isResolvingPreview || _isLoading) return;

    setState(() {
      _isResolvingPreview = true;
    });

    try {
      final address = await _reverseGeocode(_center);
      if (!mounted) return;
      setState(() {
        _selectedAddress = address;
        _hasResolvedAddress = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress =
            'Unable to load address for this point. You can still try again.';
        _hasResolvedAddress = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingPreview = false;
        });
      }
    }
  }

  Future<String> _reverseGeocode(LatLng point) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=${point.latitude}'
      '&lon=${point.longitude}'
      '&zoom=18'
      '&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: const {
        'User-Agent': 'CeylonDash/1.0 (teamxceylon@gmail.com)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Reverse geocoding failed');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final displayName = (data['display_name'] as String?)?.trim();

    if (displayName == null || displayName.isEmpty) {
      throw Exception('No address found');
    }

    return displayName;
  }

  Future<void> _confirmLocation() async {
    if (_isLoading) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final address = await _reverseGeocode(_center);

      if (!mounted) return;

      Navigator.pop(
        context,
        MapSelectionResult(
          address: address,
          latitude: _center.latitude,
          longitude: _center.longitude,
        ),
      );
    } catch (_) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Could not resolve address. Please try again.',
          type: SnackbarType.error,
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

  void _goToDefaultLocation() {
    HapticFeedback.selectionClick();
    _mapController.move(_defaultCenter, 16);
    setState(() {
      _center = _defaultCenter;
      _selectedAddress = 'Finding address...';
      _hasResolvedAddress = false;
    });
    _resolvePreviewAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Pin Location',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged: (position, hasGesture) {
                final currentCenter = position.center;

                _center = currentCenter;

                if (hasGesture) {
                  setState(() {
                    _selectedAddress = 'Finding address...';
                    _hasResolvedAddress = false;
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() {
                    _isDragging = true;
                  });
                } else if (event is MapEventMoveEnd) {
                  setState(() {
                    _isDragging = false;
                  });
                  _resolvePreviewAddress();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.example.ceylondash',
              ),
            ],
          ),
          Center(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  0,
                  _isDragging ? -15 : 0,
                  0,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 54,
                  color: Colors.cyan,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                elevation: 6,
                shadowColor: Colors.black12,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _goToDefaultLocation,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black38,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.place_rounded,
                            color: Colors.cyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_center.latitude.toStringAsFixed(6)}, '
                      '${_center.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isResolvingPreview)
                            ? null
                            : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _hasResolvedAddress
                                    ? 'Confirm Address'
                                    : 'Resolve Address First',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
