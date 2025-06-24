import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  int totalListings = 0;
  int totalUsers = 0;
  Map<String, int> categoryCounts = {};
  Map<String, int> statusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final listingsSnapshot = await FirebaseFirestore.instance.collection('listings').get();
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    // Reset counters
    Map<String, int> tempCat = {};
    Map<String, int> tempStatus = {};

    for (var doc in listingsSnapshot.docs) {
      final data = doc.data();
      final cat = data['category'] ?? 'Unknown';
      final status = data['status'] ?? 'Unspecified';

      tempCat[cat] = (tempCat[cat] ?? 0) + 1;
      tempStatus[status] = (tempStatus[status] ?? 0) + 1;
    }

    setState(() {
      totalListings = listingsSnapshot.size;
      totalUsers = usersSnapshot.size;
      categoryCounts = tempCat;
      statusCounts = tempStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Admin Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("🏠 Listings", totalListings),
              _buildStatCard("👥 Users", totalUsers),
            ],
          ),
          const SizedBox(height: 30),
          const Text("📦 Listings by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(height: 250, child: _buildBarChart()),
          const SizedBox(height: 30),
          const Text("📈 Listings by Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(height: 250, child: _buildPieChart()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count) {
    return Card(
      elevation: 4,
      child: Container(
        width: 140,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (categoryCounts.isEmpty) {
      return const Center(child: Text("No category data"));
    }

    final categories = categoryCounts.keys.toList();
    final values = categoryCounts.values.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                return index >= 0 && index < categories.length
                    ? Text(categories[index], style: const TextStyle(fontSize: 10))
                    : const Text('');
              },
              reservedSize: 36,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(categories.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: values[i].toDouble(), width: 20, color: Colors.indigo),
          ]);
        }),
      ),
    );
  }

  Widget _buildPieChart() {
    if (statusCounts.isEmpty) {
      return const Center(child: Text("No status data"));
    }

    final sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        title: "${entry.key} (${entry.value})",
        value: entry.value.toDouble(),
        radius: 60,
      );
    }).toList();

    return PieChart(PieChartData(sections: sections));
  }
}
