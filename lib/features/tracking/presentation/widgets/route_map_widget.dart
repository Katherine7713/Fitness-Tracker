import 'package:flutter/material.dart' hide Route;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/gps_datasource.dart';
import '../../domain/entities/location_point.dart';

class RouteMapWidget extends StatefulWidget {
  const RouteMapWidget({super.key});

  @override
  State<RouteMapWidget> createState() => RouteMapWidgetState();
}

class RouteMapWidgetState extends State<RouteMapWidget> {
  final GpsDataSource _dataSource = GpsDataSourceImpl();
  final Route _route = Route();

  StreamSubscription<LocationPoint>? _subscription;
  bool _isTracking = false;
  String _statusMessage = 'Presiona Iniciar';

  Route get routeData => _route;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        setState(() => _statusMessage = 'Permisos de ubicación denegados');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa los permisos de ubicación en Ajustes'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final gpsEnabled = await _dataSource.isGpsEnabled();
    if (!gpsEnabled) {
      if (mounted) {
        setState(() => _statusMessage = 'Activa el GPS del dispositivo');
        await Geolocator.openLocationSettings();
      }
      return;
    }

    _subscription = _dataSource.locationStream.listen(
      (point) {
        setState(() {
          _route.addPoint(point);
          _statusMessage = 'Tracking — ${_route.points.length} puntos';
        });
      },
      onError: (error) {
        if (mounted) {
          setState(() => _statusMessage = 'Error GPS: $error');
        }
      },
    );

    setState(() => _isTracking = true);
  }

  void _stopTracking() {
    _subscription?.cancel();
    _route.finish();
    setState(() {
      _isTracking = false;
      _statusMessage = 'Ruta finalizada';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ruta GPS',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                      label: Text(_isTracking ? 'Detener' : 'Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isTracking ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Mapa (Canvas)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: RoutePainter(route: _route),
                size: Size.infinite,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Métricas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(Icons.straighten,
                    '${_route.distanceKm.toStringAsFixed(2)} km', 'Distancia'),
                _buildMetric(
                    Icons.timer, _formatDuration(_route.duration), 'Tiempo'),
                _buildMetric(
                    Icons.speed,
                    '${_route.averageSpeed.toStringAsFixed(1)} km/h',
                    'Velocidad'),
                _buildMetric(
                    Icons.local_fire_department,
                    '${_route.estimatedCalories.toStringAsFixed(0)}',
                    'Calorías'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class RoutePainter extends CustomPainter {
  final Route route;

  RoutePainter({required this.route});

  @override
  void paint(Canvas canvas, Size size) {
    if (route.points.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Sin datos de ruta',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    double minLat = route.points.first.latitude, maxLat = minLat;
    double minLon = route.points.first.longitude, maxLon = minLon;
    for (final p in route.points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    const padding = 20.0;
    final dw = size.width - padding * 2;
    final dh = size.height - padding * 2;

    Offset toPixel(LocationPoint pt) {
      final lr = maxLat - minLat, lr2 = maxLon - minLon;
      final x = lr2 == 0 ? dw / 2 : ((pt.longitude - minLon) / lr2) * dw;
      final y = lr == 0 ? dh / 2 : ((maxLat - pt.latitude) / lr) * dh;
      return Offset(x + padding, y + padding);
    }

    final path = Path()
      ..moveTo(toPixel(route.points.first).dx, toPixel(route.points.first).dy);
    for (var i = 1; i < route.points.length; i++) {
      path.lineTo(toPixel(route.points[i]).dx, toPixel(route.points[i]).dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
        toPixel(route.points.first), 8, Paint()..color = Colors.green);
    canvas.drawCircle(
        toPixel(route.points.last), 8, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.route.points.length != route.points.length;
}
