import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/activity_record.dart';
import '../bloc/history_bloc.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_form.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _showStats = true;

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(HistoryLoadRequested());
  }


  void _openForm({ActivityRecord? record}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    record == null ? 'Nueva actividad' : 'Editar actividad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ActivityForm(
                record: record,
                onSave: (saved) {
                  Navigator.pop(ctx);
                  if (record == null) {
                    context.read<HistoryBloc>().add(HistoryCreateRequested(saved));
                  } else {
                    context.read<HistoryBloc>().add(HistoryUpdateRequested(saved));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(int id) {
    context.read<HistoryBloc>().add(HistoryDeleteRequested(id));
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todo el historial'),
        content: const Text(
          'Esta acción eliminará permanentemente todas tus actividades registradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HistoryBloc>().add(HistoryDeleteAllRequested());
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.bar_chart : Icons.bar_chart_outlined),
            tooltip: 'Estadísticas',
            onPressed: () => setState(() => _showStats = !_showStats),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Borrar todo',
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is HistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = switch (state) {
            HistoryLoaded()           => state.records,
            HistoryOperationSuccess() => state.records,
            _                         => <ActivityRecord>[],
          };

          final stats = state is HistoryLoaded ? state.stats : null;

          return Column(
            children: [
              if (_showStats && stats != null) _StatsBanner(stats: stats),

              Expanded(
                child: records.isEmpty
                    ? _EmptyState(onAdd: () => _openForm())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => ActivityCard(
                          record: records[i],
                          onEdit: () => _openForm(record: records[i]),
                          onDelete: () => _deleteRecord(records[i].id!),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva actividad'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6366F1),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.fitness_center,
                value: '${stats['totalSessions']}',
                label: 'sesiones',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.directions_walk,
                value: _fmt(stats['totalSteps']),
                label: 'pasos',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.straighten,
                value: '${(stats['totalDistanceKm'] as double).toStringAsFixed(1)} km',
                label: 'distancia',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                value: '${(stats['totalCalories'] as double).toStringAsFixed(0)}',
                label: 'kcal',
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    final n = value as int;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin actividades registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para añadir tu primera sesión',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Añadir actividad'),
          ),
        ],
      ),
    );
  }
}