import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:intl/intl.dart';
import 'package:rizq/app/ui/pages/restaurant/subscription_page.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/ui/pages/restaurant/dashboard_page.dart';
import 'package:rizq/app/controllers/admin_controller.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  // Calculate optimal Y-axis interval based on max scan count with proper spacing
  double _calculateYInterval(double maxScanCount) {
    if (maxScanCount <= 10) return 2.0;  // Show 0, 2, 4, 6, 8, 10
    if (maxScanCount <= 20) return 5.0;  // Show 0, 5, 10, 15, 20
    if (maxScanCount <= 50) return 10.0; // Show 0, 10, 20, 30, 40, 50
    if (maxScanCount <= 100) return 20.0; // Show 0, 20, 40, 60, 80, 100
    if (maxScanCount <= 200) return 50.0; // Show 0, 50, 100, 150, 200
    if (maxScanCount <= 500) return 100.0; // Show 0, 100, 200, 300, 400, 500
    if (maxScanCount <= 1000) return 200.0; // Show 0, 200, 400, 600, 800, 1000
    return (maxScanCount / 5).ceil().toDouble();
  }



  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RestaurantController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final int scanCount = controller.scanCount;
        final int rewardsGiven = controller.rewardsIssuedCount;
        final List<Map<String, String>> recentScans = controller.recentScans;
        final List<FlSpot> chartData = controller.scanChartData;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Card
              GestureDetector(
                onTap: () {
                  DashboardPage.navigateToTab(3, rewardsSubtabIndex: 1);
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scanCount.toString(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: MColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scans this month',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Chart hint
                        Row(
                                children: [
                                                                     Icon(
                                     Icons.zoom_out_map,
                                     size: 14,
                                     color: Colors.grey[600],
                                   ),
                                  const SizedBox(width: 4),
                                                                     Text(
                                     'Pinch to zoom, drag to scroll',
                                     style: TextStyle(
                                       fontSize: 10,
                                       color: Colors.grey[600],
                                     ),
                                   ),
                                ],
                              ),
                        const SizedBox(height: 8),
                                                SizedBox(
                          height: 180,
                          child: Obx(() {
                            final chartData = controller.scanChartData;
                            if (controller.isLoadingProfile.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (chartData.isEmpty) {
                              return const Center(
                                  child: Text('No scan data for this month'));
                            }
                            final maxScanCount = chartData.map((e) => e.y).fold<double>(
                                    0, (prev, y) => y > prev ? y : prev);
                            // Dynamic Y-axis calculation
                            final maxY = maxScanCount * 1.1; // Add 10% padding at top
                            final yInterval = _calculateYInterval(maxScanCount);
                            final now = DateTime.now();
                            final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                            
                            return InteractiveViewer(
                              constrained: false,
                              minScale: 0.5,
                              maxScale: 4.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              boundaryMargin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                              child: Container(
                                width: daysInMonth * 25.0, // Give more space per day
                                height: maxScanCount > 100 ? 300 : maxScanCount > 50 ? 250 : 180, // Dynamic height based on scan count
                                padding: const EdgeInsets.all(12.0),
                                child: GestureDetector(
                                  onTap: () {
                                    DashboardPage.navigateToTab(3,
                                        rewardsSubtabIndex: 1);
                                  },
                                  child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    drawHorizontalLine: true,
                                    horizontalInterval: yInterval,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.2),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.2),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      axisNameWidget: const Text(
                                        'Scans',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      axisNameSize: 22,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: maxScanCount > 100 ? 60 : 50, // More space for larger numbers
                                        interval: yInterval,
                                        getTitlesWidget: (value, meta) {
                                          if (value % yInterval == 0 && value >= 0 && value <= maxY) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      axisNameWidget: const Text(
                                        'Date',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      axisNameSize: 22,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1, // Show every day
                                        getTitlesWidget: (value, meta) {
                                          final now = DateTime.now();
                                          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                                          
                                          // Show every day but with smaller font for readability
                                          if (value >= 1 && value <= daysInMonth && value % 1 == 0) {
                                            try {
                                              final date = DateTime(now.year, now.month, value.toInt());
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  value.toInt().toString(),
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              return const SizedBox.shrink();
                                            }
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 1,
                                  maxX: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day.toDouble(),
                                  minY: 0,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: chartData,
                                      isCurved: true,
                                      curveSmoothness: 0.3,
                                      color: MColors.primary,
                                      barWidth: 3,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 3,
                                            color: MColors.primary,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: MColors.primary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Rewards Given + Subscription
                  Expanded(
                    child: Column(
                      children: [
                        // Rewards Given Card
                        GestureDetector(
                          onTap: () {
                            // Navigate to rewards tab (index 3), Reward Claims subtab (index 0)
                            DashboardPage.navigateToTab(3, rewardsSubtabIndex: 0);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rewardsGiven.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: MColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Rewards given',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Subscription Card
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const SubscriptionPage());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subscription',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(() {
                                  final profile =
                                      controller.restaurantProfile.value;
                                  if (profile == null) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  // Determine package / plan name
                                  String packageName;
                                  if (profile.subscriptionStatus ==
                                      'free_trial') {
                                    packageName = 'Free Trial';
                                  } else {
                                    // Try to fetch readable name from admin controller
                                    String fallbackName = profile
                                            .subscriptionPlan.capitalizeFirst ??
                                        profile.subscriptionPlan;
                                    try {
                                      final adminController =
                                          Get.find<AdminController>();
                                      final plan = adminController
                                          .subscriptionPlans
                                          .firstWhere((p) =>
                                              p.id == profile.subscriptionPlan);
                                      fallbackName = plan.name;
                                    } catch (_) {
                                      // Keep fallbackName
                                    }
                                    packageName = fallbackName;
                                  }

                                  // Determine end date / remaining days text
                                  String endDateText = '';
                                  if (profile.subscriptionStatus ==
                                      'free_trial') {
                                    endDateText =
                                        '${profile.remainingTrialDays} days remaining';
                                  } else if (profile.subscriptionEnd != null) {
                                    endDateText = 'Ends on '
                                        '${DateFormat('MMM d, yyyy').format(profile.subscriptionEnd!)}';
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: MColors.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          packageName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      if (endDateText.isNotEmpty)
                                        Text(
                                          endDateText,
                                          style: const TextStyle(
                                            color: Color(0xFFB2A4D4),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      const SizedBox(height: 30),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // Recent Scans
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to rewards tab (index 3), Recent Scans subtab (index 1)
                        DashboardPage.navigateToTab(3, rewardsSubtabIndex: 1);
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent scans',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: controller.recentScansStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final scans =
                                    (snapshot.data ?? []).take(3).toList();
                                if (scans.isEmpty) {
                                  return const Text('No recent scans');
                                }
                                return Column(
                                  children: scans.map((scan) {
                                    final name = scan['name'] ?? 'Customer';
                                    final date = scan['date'] != null
                                        ? (scan['date'] is DateTime
                                            ? (scan['date'] as DateTime)
                                            : DateTime.tryParse(
                                                scan['date'].toString()))
                                        : null;
                                    final points = scan['points'] ?? 1;
                                    final formattedDate = date != null
                                        ? DateFormat('MMM dd, hha').format(date)
                                        : '';
                                    return Container(
                                      padding: const EdgeInsets.all(5),
                                      margin: const EdgeInsets.only(bottom: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              Color(0xFF431EB9).withOpacity(0.1),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}
