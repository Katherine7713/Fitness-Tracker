import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/activity_record.dart';

class ActivityForm extends StatefulWidget {
  final ActivityRecord? record;
  final void Function(ActivityRecord record) onSave;

  const ActivityForm({super.key, this.record, required this.onSave});

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();

  late ActivityCategory _category;
  late DateTime _startTime;
  late DateTime _endTime;
  late TextEditingController _stepsCtrl;
  late TextEditingController _distanceCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _category = r?.category ?? ActivityCategory.walking;
    _startTime =
        r?.startTime ?? DateTime.now().subtract(const Duration(minutes: 30));
    _endTime = r?.endTime ?? DateTime.now();
    _stepsCtrl = TextEditingController(text: r != null ? '${r.steps}' : '');
    _distanceCtrl = TextEditingController(
        text: r != null ? r.distanceKm.toStringAsFixed(2) : '');
    _caloriesCtrl = TextEditingController(
        text: r != null ? r.calories.toStringAsFixed(1) : '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
  }

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _distanceCtrl.dispose();
    _caloriesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = picked;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(minutes: 30));
        }
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final record = ActivityRecord(
      id: widget.record?.id,
      category: _category,
      startTime: _startTime,
      endTime: _endTime,
      steps: int.tryParse(_stepsCtrl.text) ?? 0,
      distanceKm: double.tryParse(_distanceCtrl.text) ?? 0,
      calories: double.tryParse(_caloriesCtrl.text) ?? 0,
      averageSpeedKmh: _calcAverageSpeed(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    widget.onSave(record);
  }

  double _calcAverageSpeed() {
    final distKm = double.tryParse(_distanceCtrl.text) ?? 0;
    final hours = _endTime.difference(_startTime).inSeconds / 3600;
    if (hours <= 0 || distKm <= 0) return 0;
    return distKm / hours;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Categoría
          Text('Tipo de actividad', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ActivityCategory.values.map((cat) {
              final selected = _category == cat;
              return ChoiceChip(
                label: Text('${cat.icon} ${cat.label}'),
                selected: selected,
                selectedColor: colorScheme.primaryContainer,
                onSelected: (_) => setState(() => _category = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Fechas
          Text('Horario', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _DateTimeButton(
                label: 'Inicio',
                dateTime: _startTime,
                onTap: () => _pickDateTime(isStart: true),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _DateTimeButton(
                label: 'Fin',
                dateTime: _endTime,
                onTap: () => _pickDateTime(isStart: false),
              )),
            ],
          ),
          const SizedBox(height: 20),

          // Métricas
          Text('Métricas', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _NumberField(
                controller: _stepsCtrl,
                label: 'Pasos',
                icon: Icons.directions_walk,
                isInteger: true,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _NumberField(
                controller: _distanceCtrl,
                label: 'Distancia (km)',
                icon: Icons.straighten,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _NumberField(
            controller: _caloriesCtrl,
            label: 'Calorías (kcal)',
            icon: Icons.local_fire_department,
          ),
          const SizedBox(height: 20),

          // Notas
          Text('Notas (opcional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Cómo te sentiste, ruta, clima...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const SizedBox(height: 28),

          // Botón guardar
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save),
            label: Text(widget.record == null
                ? 'Guardar actividad'
                : 'Actualizar actividad'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  const _DateTimeButton(
      {required this.label, required this.dateTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}\n'
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.schedule, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(formatted,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isInteger;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
