import 'package:flutter/material.dart';
import 'dart:math';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
      ),
      body: const Center(
        child: Text('This is the Jobs page.'),
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  final String driverId, jobId, src, dest;

  const TrackingScreen(this.driverId, this.jobId, this.src, this.dest, {super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  double progress = 0.0; // percentage (0 → 1)

  @override
  void initState() {
    super.initState();
    _simulateGpsUpdates();
  }

  void _simulateGpsUpdates() {
    // In real app, replace with actual GPS listener
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          progress = min(1.0, progress + 0.1);
        });
      }
      return progress < 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Job ${widget.jobId}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Driver: ${widget.driverId}", style: const TextStyle(fontSize: 18)),
            Text("From: ${widget.src}", style: const TextStyle(fontSize: 18)),
            Text("To: ${widget.dest}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            
            LinearProgressIndicator(value: progress, minHeight: 15),
            const SizedBox(height: 10),
            Text("Progress: ${(progress * 100).toStringAsFixed(0)}%"),

            if (progress >= 1.0)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("✅ Reached Destination", style: TextStyle(color: Colors.green, fontSize: 20)),
              )
          ],
        ),
      ),
    );
  }
}