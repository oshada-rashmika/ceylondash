import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaBubble extends StatelessWidget {
  final String messageType;
  final String? mediaUrl;
  final String? text;
  final bool isIncoming;

  const MediaBubble({
    super.key,
    required this.messageType,
    this.mediaUrl,
    this.text,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    if (messageType == 'image' && mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          mediaUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 200, height: 200, 
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
        ),
      );
    } 
    
    if (messageType == 'document' && mediaUrl != null) {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.parse(mediaUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text ?? 'Document', 
                  style: TextStyle(
                    color: isIncoming ? Colors.black87 : Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (messageType == 'location' && text != null) {
      final parts = text!.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          final center = LatLng(lat, lng);
          return SizedBox(
            width: 200,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return const SizedBox.shrink();
  }
}
