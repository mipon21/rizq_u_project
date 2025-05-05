import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/admin_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsPage extends GetView<AdminController> {
  const ReportsPage({Key? key}) : super(key: key);

  // Override the controller getter to ensure it's properly initialized
  @override
  AdminController get controller {
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController(), permanent: true);
    }
    return Get.find<AdminController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportSection(
              title: 'Generate Reports',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select report type and date range:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Report Type',
                          border: OutlineInputBorder(),
                        ),
                        value: 'subscriptions',
                        items: const [
                          DropdownMenuItem(
                            value: 'subscriptions',
                            child: Text('Subscription Revenue'),
                          ),
                          DropdownMenuItem(
                            value: 'registrations',
                            child: Text('Restaurant Registrations'),
                          ),
                          DropdownMenuItem(
                            value: 'customers',
                            child: Text('Customer Growth'),
                          ),
                          DropdownMenuItem(
                            value: 'scans',
                            child: Text('Scan Activity'),
                          ),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              initialValue: DateFormat('yyyy-MM-dd').format(
                                DateTime.now()
                                    .subtract(const Duration(days: 30)),
                              ),
                              onTap: () {
                                // Show date picker
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              initialValue: DateFormat('yyyy-MM-dd').format(
                                DateTime.now(),
                              ),
                              onTap: () {
                                // Show date picker
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _generateReport('csv'),
                                icon: const Icon(Icons.download),
                                label: const Text('Export CSV'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _generateReport('pdf'),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Export PDF'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildReportSection(
              title: 'Revenue Analytics',
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: _buildRevenueChart(),
              ),
            ),
            const SizedBox(height: 20),
            _buildReportSection(
              title: 'Restaurant Activity',
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: _buildRestaurantActivityChart(),
              ),
            ),
            const SizedBox(height: 20),
            _buildReportSection(
              title: 'Loyalty Program Analytics',
              child: _buildLoyaltyProgramSection(),
            ),
            const SizedBox(height: 20),
            _buildReportSection(
              title: 'Recent Reward Claims',
              child: _buildRecentClaimsTable(),
            ),
            const SizedBox(height: 20),
            _buildReportSection(
              title: 'Recent Activities',
              child: _buildRecentActivitiesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildRevenueChart() {
    // Example data - in a real app, fetch from Firebase
    final List<RevenueData> revenueData = [
      RevenueData('Jan', 780),
      RevenueData('Feb', 1200),
      RevenueData('Mar', 1400),
      RevenueData('Apr', 1100),
      RevenueData('May', 1600),
      RevenueData('Jun', 1800),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<RevenueData, String>>[
        ColumnSeries<RevenueData, String>(
          name: 'Monthly Revenue',
          dataSource: revenueData,
          xValueMapper: (RevenueData data, _) => data.month,
          yValueMapper: (RevenueData data, _) => data.amount,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRestaurantActivityChart() {
    // Example data - in a real app, fetch from Firebase
    final List<ActivityData> scanData = [
      ActivityData('Mon', 90),
      ActivityData('Tue', 120),
      ActivityData('Wed', 150),
      ActivityData('Thu', 110),
      ActivityData('Fri', 220),
      ActivityData('Sat', 280),
      ActivityData('Sun', 160),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ActivityData, String>>[
        SplineSeries<ActivityData, String>(
          name: 'Daily Scans',
          dataSource: scanData,
          xValueMapper: (ActivityData data, _) => data.day,
          yValueMapper: (ActivityData data, _) => data.count,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          color: Colors.green,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildLoyaltyProgramSection() {
    // Fetch loyalty program data when widget is built
    if (!controller.isLoadingLoyaltyData.value &&
        controller.loyaltyPrograms.isEmpty) {
      controller.fetchLoyaltyProgramData();
    }

    return Obx(() {
      if (controller.isLoadingLoyaltyData.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        children: [
          // Loyalty program stats cards
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildStatsCard(
                    title: 'Total Programs',
                    value: '${controller.loyaltyPrograms.length}',
                    icon: Icons.card_giftcard,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    title: 'Total Rewards Claimed',
                    value: '${controller.totalRewardsClaimed}',
                    icon: Icons.redeem,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Top restaurants by rewards claimed
          if (controller.topRestaurantsByRewards.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Restaurants by Rewards Claimed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTopRestaurantsChart(),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRestaurantsChart() {
    final data = controller.topRestaurantsByRewards.entries
        .map((entry) => LoyaltyData(entry.key, entry.value))
        .toList();

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No reward claim data available'),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Rewards Claimed'),
        ),
        series: <CartesianSeries<LoyaltyData, String>>[
          BarSeries<LoyaltyData, String>(
            dataSource: data,
            xValueMapper: (LoyaltyData data, _) => data.restaurant,
            yValueMapper: (LoyaltyData data, _) => data.value,
            name: 'Rewards Claimed',
            color: Colors.purple.shade400,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.inside,
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(enable: true),
      ),
    );
  }

  Widget _buildRecentClaimsTable() {
    return Obx(() {
      if (controller.isLoadingLoyaltyData.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.recentClaims.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text('No recent reward claims'),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Restaurant')),
              DataColumn(label: Text('Customer ID')),
              DataColumn(label: Text('Reward Type')),
              DataColumn(label: Text('Points Used')),
              DataColumn(label: Text('Claim Date')),
            ],
            rows: controller.recentClaims.map((claim) {
              final timestamp = (claim['claimDate'] as Timestamp?)?.toDate();
              final dateFormat = DateFormat('MMM d, yyyy - HH:mm');
              final formattedDate =
                  timestamp != null ? dateFormat.format(timestamp) : 'Unknown';

              return DataRow(
                cells: [
                  DataCell(Text(claim['restaurantName'] ?? 'Unknown')),
                  DataCell(Text(claim['customerId'] ?? 'Unknown')),
                  DataCell(Text(claim['rewardType'] ?? 'Unknown')),
                  DataCell(Text('${claim['pointsUsed'] ?? 0}')),
                  DataCell(Text(formattedDate)),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildRecentActivitiesList() {
    return SizedBox(
      height: 400,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scans')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No recent activities found'));
          }

          return Card(
            child: ListView.separated(
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final restaurantId = data['restaurantId'] ?? '';
                final customerId = data['clientId'] ?? '';
                final timestamp = (data['timestamp'] as Timestamp).toDate();

                return FutureBuilder(
                  future: Future.wait([
                    FirebaseFirestore.instance
                        .collection('restaurants')
                        .doc(restaurantId)
                        .get(),
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(customerId)
                        .get(),
                  ]),
                  builder: (context,
                      AsyncSnapshot<List<DocumentSnapshot>> futureSnapshot) {
                    String restaurantName = 'Unknown Restaurant';
                    String customerName = 'Unknown Customer';

                    if (futureSnapshot.hasData) {
                      final restaurantData = futureSnapshot.data![0].data()
                          as Map<String, dynamic>?;
                      final customerData = futureSnapshot.data![1].data()
                          as Map<String, dynamic>?;

                      restaurantName =
                          restaurantData?['name'] ?? 'Unknown Restaurant';
                      customerName =
                          customerData?['name'] ?? 'Unknown Customer';
                    }

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.qr_code_scanner),
                      ),
                      title: Text('$customerName scanned at $restaurantName'),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy - hh:mm a').format(timestamp),
                      ),
                      trailing: Text(
                        '+${data['pointsAwarded'] ?? 1} points',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _generateReport(String format) {
    // Implementation would create and download the report file
    Get.snackbar(
      'Report Generation',
      'Generating ${format.toUpperCase()} report...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    // In a real app, this would generate the actual report
    Future.delayed(const Duration(seconds: 2), () {
      Get.snackbar(
        'Report Ready',
        'Your ${format.toUpperCase()} report has been generated and downloaded',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }
}

// Models for chart data
class RevenueData {
  final String month;
  final double amount;

  RevenueData(this.month, this.amount);
}

class ActivityData {
  final String day;
  final int count;

  ActivityData(this.day, this.count);
}

class LoyaltyData {
  final String restaurant;
  final int value;

  LoyaltyData(this.restaurant, this.value);
}
