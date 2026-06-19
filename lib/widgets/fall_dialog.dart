import 'dart:async';
import 'package:flutter/material.dart';

class FallDialog {
  static void show({
    required BuildContext context,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FallDialogContent(onConfirm: onConfirm),
    );
  }
}

class _FallDialogContent extends StatefulWidget {
  final VoidCallback? onConfirm;
  const _FallDialogContent({this.onConfirm});

  @override
  State<_FallDialogContent> createState() => _FallDialogContentState();
}

class _FallDialogContentState extends State<_FallDialogContent> {
  int _secondsRemaining = 15;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expired = _secondsRemaining <= 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
          const SizedBox(width: 8),
          const Text('Alerta de Caída'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            expired
              ? '¡Por favor, responde! Hemos detectado una caída y necesitamos confirmar que estás bien.'
              : 'Hemos detectado una posible caída. ¿Te encuentras bien?',
            style: TextStyle(
              fontSize: 16,
              color: expired ? Colors.red[700] : null,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: expired ? Colors.red[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: expired ? Colors.red[700] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  expired ? 'TIEMPO AGOTADO' : '$_secondsRemaining s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: expired ? Colors.red[700] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onConfirm?.call();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Sí, estoy bien'),
        ),
      ],
    );
  }
}
