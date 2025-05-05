import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this to pubspec.yaml if not present
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/controllers/program_controller.dart';
import 'package:rizq/app/ui/pages/restaurant/rewards_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RestaurantController controller = Get.find<RestaurantController>();
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;

  Widget _buildDashboardTab() {
    return Obx(() {
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
            Card(
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
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B217B),
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
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B217B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Starter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Free Trial',
                              style: TextStyle(
                                color: Color(0xFFB2A4D4),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        final maxY = chartData.map((e) => e.y).fold<double>(
                                0, (prev, y) => y > prev ? y : prev) +
                            5;
                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 100,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 100 == 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.left,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: chartData.first.x,
                            maxX: chartData.last.x,
                            minY: 0,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartData,
                                isCurved: true,
                                color: const Color(0xFF3B217B),
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      const Color(0xFF3B217B).withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rewards Given
                Expanded(
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
                        Text(
                          rewardsGiven.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B217B),
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
                SizedBox(width: 10),
                // Recent Scans
                Expanded(
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
                                      color: Color(0xFF431EB9).withOpacity(0.1),
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
                                        // Text(
                                        //   '+$points',
                                        //   style: const TextStyle(
                                        //     color: Colors.green,
                                        //     fontWeight: FontWeight.bold,
                                        //     fontSize: 14,
                                        //   ),
                                        // ),
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
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  // Restore Program Settings Tab
  Widget _buildProgramSettingsTab() {
    final ProgramController programController = Get.find<ProgramController>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final List<String> rewardOptions = [
      "Free Coffee",
      "Free Meal",
      "10% Discount",
      "Free Appetizer",
    ];
    final TextEditingController rewardTypeController = TextEditingController(
      text: programController.currentRewardType,
    );
    final RxString selectedRewardType = programController.currentRewardType.obs;

    ever(programController.loyaltyProgram, (_) {
      if (programController.loyaltyProgram.value != null) {
        rewardTypeController.text = programController.currentRewardType;
        selectedRewardType.value = programController.currentRewardType;
      }
    });

    return Obx(() {
      if (programController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure Your Reward',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 30),
              const Text(
                'Select Reward Type:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Obx(() => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: rewardOptions.map((rewardType) {
                      final isSelected = selectedRewardType.value == rewardType;
                      return GestureDetector(
                        onTap: () {
                          selectedRewardType.value = rewardType;
                          rewardTypeController.text = rewardType;
                        },
                        child: Card(
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                rewardType,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 15),
              const Text(
                'Or enter a custom reward type below:',
                style: TextStyle(color: Colors.grey),
              ),
              TextFormField(
                controller: rewardTypeController,
                decoration: const InputDecoration(
                  labelText: 'Reward Description (e.g., Free Coffee)',
                  hintText: 'Enter custom reward...',
                ),
                onChanged: (value) => selectedRewardType.value = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reward description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Points Required for Reward',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '10',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'points',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Points required is fixed at 10',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      programController.updateLoyaltyProgram(
                        rewardTypeController.text.trim(),
                        10, // Fixed at 10 points
                      );
                      Get.snackbar('Success', 'Program settings updated!');
                    }
                  },
                  child: const Text('Save Program Settings'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Restore Rewards Tab
  Widget _buildRewardsTab() {
    return const RewardsTab();
  }

  // Restore Profile Tab
  Widget _buildProfileTab() {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final profile = controller.restaurantProfile.value;
      if (profile == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please complete your profile setup'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                child: const Text('Setup Profile'),
              ),
            ],
          ),
        );
      }

      // This is the actual profile content
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: profile.logoUrl.isNotEmpty
                  ? NetworkImage(profile.logoUrl)
                  : null,
              child: profile.logoUrl.isEmpty
                  ? const Icon(Icons.restaurant, size: 50)
                  : null,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Name', profile.name),
                    _buildInfoRow('Address', profile.address),
                    _buildInfoRow('User ID', profile.uid),
                    _buildInfoRow(
                      'Member Since',
                      profile.createdAt.toString(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subscription Plan Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Plan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Current Plan',
                      'Free Trial',
                    ),
                    _buildInfoRow(
                      'Status',
                      'active',
                      valueColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Scans Used',
                      '0 scans',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_SUBSCRIPTION),
                        child: const Text('Manage Subscription'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildDashboardTab(),
      _buildProgramSettingsTab(),
      const SizedBox(), // Placeholder for FAB
      _buildRewardsTab(),
      _buildProfileTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: _pages[_currentIndex == 2 ? 0 : _currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.RESTAURANT_QR_SCANNER),
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan Customer QR',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Home',
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: _currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Program Settings',
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.card_giftcard_outlined,
                  color: _currentIndex == 3
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Rewards History',
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                  controller.fetchClaimedRewards();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 4
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Edit Profile',
                onPressed: () {
                  setState(() {
                    _currentIndex = 4;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
