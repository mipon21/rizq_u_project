import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/admin_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardPage extends GetView<AdminController> {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is registered with GetX
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController());
    }

    // Fetch dashboard metrics when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDashboardMetrics();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _buildDashboardContent(context),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: MColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Get.back(); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Restaurants'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_RESTAURANTS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Customers'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_CUSTOMERS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Subscriptions'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_SUBSCRIPTIONS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_REPORTS);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => controller.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchDashboardMetrics(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            const Text(
              'Registration Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
              child: _buildRegistrationChart(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Revenue by Subscription Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
              child: _buildRevenuePieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final layout = _getCardLayout(Get.width);
    return Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: layout['count'],
          childAspectRatio: layout['ratio'],
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatCard(
              title: 'Total Restaurants',
              value: controller.totalRestaurants.value.toString(),
              icon: Icons.restaurant,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Total Customers',
              value: controller.totalCustomers.value.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Revenue',
              value: '\$${controller.totalRevenue.value.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.amber,
            ),
            _buildStatCard(
              title: 'New Restaurants (Month)',
              value: controller.newRestaurantsThisMonth.value.toString(),
              icon: Icons.trending_up,
              color: Colors.purple,
            ),
          ],
        ));
  }

  Map<String, dynamic> _getCardLayout(double width) {
    if (width > 1200) return {'count': 4, 'ratio': 1.5};
    if (width > 800) return {'count': 2, 'ratio': 1.3};
    if (width > 600) return {'count': 2, 'ratio': 1.2};
    return {'count': 2, 'ratio': 1.0}; // More height for small screens
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationChart() {
    // Example data - in a real app, fetch from Firebase
    final List<ChartData> chartData = [
      ChartData('Jan', 5, 12),
      ChartData('Feb', 7, 15),
      ChartData('Mar', 9, 20),
      ChartData('Apr', 11, 18),
      ChartData('May', 13, 25),
      ChartData('Jun', 12, 22),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ChartData, String>>[
        ColumnSeries<ChartData, String>(
          name: 'Restaurants',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.month,
          yValueMapper: (ChartData data, _) => data.restaurants,
          color: Colors.blue,
        ),
        ColumnSeries<ChartData, String>(
          name: 'Customers',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.month,
          yValueMapper: (ChartData data, _) => data.customers,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildRevenuePieChart() {
    // Example data - in a real app, fetch from Firebase
    final List<PieChartData> pieData = [
      PieChartData('Free Trial', 30, Colors.grey),
      PieChartData('Basic Plan', 45, Colors.blue),
      PieChartData('Premium', 25, Colors.green),
    ];

    return SfCircularChart(
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        PieSeries<PieChartData, String>(
          dataSource: pieData,
          xValueMapper: (PieChartData data, _) => data.plan,
          yValueMapper: (PieChartData data, _) => data.percentage,
          pointColorMapper: (PieChartData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
        ),
      ],
    );
  }
}

// Models for chart data
class ChartData {
  final String month;
  final int restaurants;
  final int customers;

  ChartData(this.month, this.restaurants, this.customers);
}

class PieChartData {
  final String plan;
  final double percentage;
  final Color color;

  PieChartData(this.plan, this.percentage, this.color);
}
