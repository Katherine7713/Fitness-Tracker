import 'package:flutter/material.dart';
import '../../domain/entities/activity_record.dart';

class ActivityCard extends StatelessWidget {
  final ActivityRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key('activity_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(record.category.icon,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.category.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _formatDate(record.startTime),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Duración
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.formattedDuration,
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Métricas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (record.steps > 0)
                      _Metric(
                          icon: Icons.directions_walk,
                          value: '${record.steps}',
                          label: 'pasos'),
                    if (record.distanceKm > 0)
                      _Metric(
                        icon: Icons.straighten,
                        value: record.distanceKm.toStringAsFixed(2),
                        label: 'km',
                      ),
                    if (record.calories > 0)
                      _Metric(
                        icon: Icons.local_fire_department,
                        value: record.calories.toStringAsFixed(0),
                        label: 'kcal',
                        color: Colors.orange,
                      ),
                    if (record.averageSpeedKmh > 0)
                      _Metric(
                        icon: Icons.speed,
                        value: record.averageSpeedKmh.toStringAsFixed(1),
                        label: 'km/h',
                      ),
                  ],
                ),

                // Notas
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.notes!,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text(
          '¿Eliminar esta sesión de ${record.category.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    if (day == today) return 'Hoy · ${_time(dt)}';
    if (day == today.subtract(const Duration(days: 1)))
      return 'Ayer · ${_time(dt)}';
    return '${dt.day}/${dt.month}/${dt.year} · ${_time(dt)}';
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _Metric(
      {required this.icon,
      required this.value,
      required this.label,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(height: 2),
        Text(value,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}
