import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../controllers/admin_controller.dart';
import '../../../utils/constants/colors.dart';

class ReportsPage extends GetView<AdminController> {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available, but don't create it during build
    if (!Get.isRegistered<AdminController>()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          backgroundColor: MColors.primary,
        ),
        body: const Center(
          child: Text('Controller not initialized. Please return to dashboard.'),
        ),
      );
    }

    // Fetch loyalty program data and revenue data after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoadingLoyaltyData.value &&
          controller.loyaltyPrograms.isEmpty) {
        controller.fetchLoyaltyProgramData();
      }
      if (!controller.isLoadingRevenueData.value) {
        controller.fetchRevenueData();
      }
      if (!controller.isLoadingActivityData.value) {
        controller.fetchRestaurantActivityData();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: MColors.primary,
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
                      Obx(() => DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Report Type',
                              border: OutlineInputBorder(),
                            ),
                            value: controller.selectedReportType.value,
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
                              DropdownMenuItem(
                                value: 'reward_claims',
                                child: Text('Reward Claims'),
                              ),
                              DropdownMenuItem(
                                value: 'recent_activities',
                                child: Text('Recent Activities'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedReportType.value = value;
                              }
                            },
                          )),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: DateFormat('yyyy-MM-dd').format(
                                  controller.reportStartDate.value,
                                ),
                              ),
                              onTap: () => _selectStartDate(),
                            )),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(() => TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: DateFormat('yyyy-MM-dd').format(
                                  controller.reportEndDate.value,
                                ),
                              ),
                              onTap: () => _selectEndDate(),
                            )),
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
                                icon: Icon(Icons.download),
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
                child: Column(
                  children: [
                    // Header with refresh button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subscription Revenue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Obx(() => IconButton(
                            onPressed: controller.isLoadingRevenueData.value
                                ? null
                                : () => controller.fetchRevenueData(),
                            icon: controller.isLoadingRevenueData.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            tooltip: 'Refresh Revenue Data',
                          )),
                        ],
                      ),
                    ),
                    // Chart
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: _buildRevenueChart(),
                      ),
                    ),
                  ],
                ),
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
                child: Column(
                  children: [
                    // Header with refresh button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'QR Code Scans',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Obx(() => IconButton(
                            onPressed: controller.isLoadingActivityData.value
                                ? null
                                : () => controller.fetchRestaurantActivityData(),
                            icon: controller.isLoadingActivityData.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            tooltip: 'Refresh Activity Data',
                          )),
                        ],
                      ),
                    ),
                    // Chart
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: _buildRestaurantActivityChart(),
                      ),
                    ),
                  ],
                ),
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
    return Obx(() {
      if (controller.isLoadingRevenueData.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.monthlyRevenueData.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No revenue data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting the date range',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      // Convert real data to chart format
      final List<RevenueData> revenueData = controller.monthlyRevenueData
          .map((data) => RevenueData(
                data['month'] as String,
                data['amount'] as double,
              ))
          .toList();

      return SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x : \$point.y',
        ),
        series: <CartesianSeries<RevenueData, String>>[
          ColumnSeries<RevenueData, String>(
            name: 'Monthly Revenue',
            dataSource: revenueData,
            xValueMapper: (RevenueData data, _) => data.month,
            yValueMapper: (RevenueData data, _) => data.amount,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.outer,
              textStyle: TextStyle(fontSize: 10),
            ),
            color: Colors.blue,
          ),
        ],
      );
    });
  }

  Widget _buildRestaurantActivityChart() {
    return Obx(() {
      if (controller.isLoadingActivityData.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.dailyScanData.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No scan activity data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting the date range',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      // Convert real data to chart format
      final List<ActivityData> scanData = controller.dailyScanData
          .map((data) => ActivityData(
                data['day'] as String,
                data['count'] as int,
              ))
          .toList();

      return SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x : point.y scans',
        ),
        series: <CartesianSeries<ActivityData, String>>[
          SplineSeries<ActivityData, String>(
            name: 'Daily Scans',
            dataSource: scanData,
            xValueMapper: (ActivityData data, _) => data.day,
            yValueMapper: (ActivityData data, _) => data.count,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.outer,
              textStyle: TextStyle(fontSize: 10),
            ),
            color: Colors.green,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLoyaltyProgramSection() {
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
              Icon(icon, color: color, size: (24).isFinite && 24 > 0 ? 24 : 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: controller.reportStartDate.value,
      firstDate: DateTime(2020),
      lastDate: controller.reportEndDate.value,
    );
    if (picked != null && picked != controller.reportStartDate.value) {
      controller.reportStartDate.value = picked;
      // Re-fetch data with new date range
      controller.fetchRevenueData();
      controller.fetchRestaurantActivityData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: controller.reportEndDate.value,
      firstDate: controller.reportStartDate.value,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != controller.reportEndDate.value) {
      controller.reportEndDate.value = picked;
      // Re-fetch data with new date range
      controller.fetchRevenueData();
      controller.fetchRestaurantActivityData();
    }
  }

  void _generateReport(String format) async {
    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      if (format == 'csv') {
        switch (controller.selectedReportType.value) {
          case 'subscriptions':
            await controller.exportSubscriptionsToCSV();
            break;
          case 'registrations':
            await controller.exportRestaurantsToCSV();
            break;
          case 'customers':
            await controller.exportCustomersToCSV();
            break;
          case 'scans':
          case 'recent_activities':
            await controller.exportScansToCSV();
            break;
          case 'reward_claims':
            await controller.exportRewardClaimsToCSV();
            break;
          default:
            Get.snackbar('Error', 'Unknown report type selected');
        }
      } else {
        switch (controller.selectedReportType.value) {
          case 'subscriptions':
            await controller.exportSubscriptionsToPDF();
            break;
          case 'registrations':
            await controller.exportRestaurantsToPDF();
            break;
          case 'customers':
            await controller.exportCustomersToPDF();
            break;
          case 'scans':
          case 'recent_activities':
            await controller.exportScansToPDF();
            break;
          case 'reward_claims':
            await controller.exportRewardClaimsToPDF();
            break;
          default:
            Get.snackbar('Error', 'Unknown report type selected');
        }
      }
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
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
