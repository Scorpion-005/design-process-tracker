import 'package:flutter/material.dart';
import '../models/design.dart';
import '../services/database_service.dart';
import '../services/week_utils.dart';
import 'add_design_screen.dart';
import 'design_list_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Design> _designs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await DatabaseService.instance.getAllDesigns();
    setState(() {
      _designs = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayCount = _designs
        .where((d) =>
            d.receivedDate.year == today.year &&
            d.receivedDate.month == today.month &&
            d.receivedDate.day == today.day)
        .length;

    final weekCounts
