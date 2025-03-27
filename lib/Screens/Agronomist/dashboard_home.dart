import 'package:flutter/material.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔔 Quick Stats
          const Text(
            "Quick Insights",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInsightCard(
                title: "Crop Health",
                value: "Good",
                icon: Icons.eco,
                color: Colors.green.shade200,
              ),
              _buildInsightCard(
                title: "Weather",
                value: "Sunny 28°C",
                icon: Icons.wb_sunny,
                color: Colors.orange.shade200,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 📋 Pending Tasks
          const Text(
            "Pending Tasks",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTaskTile(
              "Inspect Field #12", "Due Today", Icons.assignment_late),
          _buildTaskTile("Soil Test Analysis", "Due Tomorrow", Icons.science),
          _buildTaskTile("Meet Farmer Rakesh", "Scheduled", Icons.person),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(String task, String dueDate, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(task),
        subtitle: Text(dueDate),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to task details
        },
      ),
    );
  }
}
