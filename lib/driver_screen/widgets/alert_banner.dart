import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;

  const AlertBanner({
    Key? key,
    required this.message,
    required this.type,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case AlertType.info:
        backgroundColor = Colors.blue.shade100;
        icon = Icons.info;
        break;
      case AlertType.warning:
        backgroundColor = Colors.yellow.shade100;
        icon = Icons.warning;
        break;
      case AlertType.error:
        backgroundColor = Colors.red.shade100;
        icon = Icons.error;
        break;
      case AlertType.success:
        backgroundColor = Colors.green.shade100;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: _getColorForType(type)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _getColorForType(type)),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              color: _getColorForType(type),
            ),
        ],
      ),
    );
  }

  Color _getColorForType(AlertType type) {
    switch (type) {
      case AlertType.info:
        return Colors.blue.shade800;
      case AlertType.warning:
        return Colors.yellow.shade800;
      case AlertType.error:
        return Colors.red.shade800;
      case AlertType.success:
        return Colors.green.shade800;
    }
  }
}

enum AlertType { info, warning, error, success }
