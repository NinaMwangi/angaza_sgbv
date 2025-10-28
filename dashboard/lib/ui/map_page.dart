import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:latlong2/latlong.dart';
import '../services/incidents_service.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angaza — Incidents Map')),
      body: StreamBuilder<List<Incident>>(
        stream: IncidentsService.streamIncidents(), // Live Firestore stream
        builder: (context, snap) {
          final incidents = snap.data ?? [];

          // Convert each incident to a map marker
          final markers = incidents
              .where((e) => e.lat != null && e.lng != null)
              .map((e) => Marker(
                    point: LatLng(e.lat!, e.lng!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showIncidentSheet(context, e),
                      child: const Icon(Icons.location_on,
                          size: 26, color: Colors.redAccent),
                    ),
                  ))
              .toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-1.95, 30.06), // Kigali
              initialZoom: 11,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'angaza.dashboard',
              ),
              SuperclusterLayer.immutable(
                initialMarkers: markers,
                indexBuilder: IndexBuilders.rootIsolate, // ✅ REQUIRED argument

                // Cluster bubble UI
                builder: (context, position, count, extra) => Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Optional fine-tuning
                minimumClusterSize: 2,
                maxClusterRadius: 80,
                clusterWidgetSize: const Size(36, 36),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIncidentSheet(BuildContext context, Incident e) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Incident', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('ID: ${e.id}'),
              Text('Time: ${e.ts.toLocal()}'),
              if (e.lat != null && e.lng != null)
                Text('Location: ${e.lat!.toStringAsFixed(5)}, ${e.lng!.toStringAsFixed(5)}'),
              if (e.transcript != null) ...[
                const SizedBox(height: 12),
                const Text('Transcript (snippet):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  e.transcript!.length > 240 ? '${e.transcript!.substring(0, 240)}…' : e.transcript!,
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
