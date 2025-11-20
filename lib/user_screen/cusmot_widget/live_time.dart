import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';


class LiveDateTime extends StatefulWidget {
  const LiveDateTime({super.key});

  @override
  LiveDateTimeState createState() => LiveDateTimeState();
}

class LiveDateTimeState extends State<LiveDateTime> {
  late String _time;
  late String _date;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _time = DateFormat('hh:mm a').format(now); // 12:54 PM
      _date = DateFormat('dd MMM yyyy').format(now); // 27 Sep 2025
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _time,
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 6, 23, 38),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _date,
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 6, 23, 38),
          ),
        ),
      ],
    );
  }
}
