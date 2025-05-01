import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/customer_controller.dart'; // Adjust import

class ScanHistoryPage extends GetView<CustomerController> {
  const ScanHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: Obx(() {
        if (controller.isLoadingHistory.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.scanHistory.isEmpty) {
          return const Center(child: Text('No scans recorded yet.'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchScanHistory(),
          child: ListView.builder(
            itemCount: controller.scanHistory.length,
            itemBuilder: (context, index) {
              final historyItem = controller.scanHistory[index];
              return ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined),
                title: Text(historyItem.restaurantName),
                subtitle: Text(
                  historyItem.formattedTimestamp,
                ), // Use formatted date
                trailing: Text(
                  '+${historyItem.pointsAwarded} pt${historyItem.pointsAwarded > 1 ? 's' : ''}',
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
