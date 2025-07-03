// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/customer_controller.dart';
import '../../../routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/utils/app_events.dart';
import 'package:rizq/app/ui/pages/customer/qr_code_page.dart';
import 'package:rizq/app/ui/pages/customer/customer_profile_page.dart';
import 'package:rizq/app/ui/pages/customer/home_tab.dart';
import 'package:rizq/app/ui/pages/customer/rewards_tab.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rizq/app/utils/constants/support_constants.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> with RouteAware {
  final CustomerController controller = Get.find<CustomerController>();
  final AuthController authController = Get.find<AuthController>();
  final RouteObserver<PageRoute> routeObserver =
      Get.find<RouteObserver<PageRoute>>();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data when the page is created
    _refreshData();

    // Check if we have navigation arguments upon initial creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args is Map && args.containsKey('navigateTo')) {
        final tabIndex = args['navigateTo'] as int;
        if (tabIndex >= 0 && tabIndex < 4) {
          _changeTab(tabIndex);
        }
      }

      // Check if there's already a tab navigation request
      // This handles the case where the event was fired before this page loaded
      if (AppEvents.navigateToTab.value >= 0 &&
          AppEvents.navigateToTab.value < 4) {
        if (kDebugMode) {
          print(
              "DEBUG: Found existing tab navigation request: ${AppEvents.navigateToTab.value}");
        }
        _changeTab(AppEvents.navigateToTab.value);
        AppEvents.navigateToTab.value = -1;
      }

      // Set up a permanent worker to listen for tab navigation events
      // This ensures the listener persists as long as the app is running
      _setupTabNavigationListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this page
    _refreshData();

    // Check for navigation result
    final result = Get.arguments;
    if (result != null && result is Map && result.containsKey('navigateTo')) {
      final tabIndex = result['navigateTo'] as int;
      if (tabIndex >= 0 && tabIndex < 4) {
        _changeTab(tabIndex);
      }
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Refresh data method
  void _refreshData() {
    controller.fetchAllRestaurantPrograms();
    // Also fetch history data for the rewards tab
    controller.fetchClaimHistory();
    controller.fetchScanHistory();
  }

  // Method to change tab
  void _changeTab(int index) {
    if (kDebugMode) {
      print(
          "DEBUG: _changeTab called with index $index (current: $_currentIndex)");
    }

    // Refresh data when switching tabs to ensure fresh content
    if (_currentIndex != index) {
      _refreshTabSpecificData(index);
    }

    setState(() {
      _currentIndex = index;
    });
    if (kDebugMode) {
      print("DEBUG: Tab changed to $_currentIndex");
    }
  }

  // Refresh data specific to the selected tab
  void _refreshTabSpecificData(int tabIndex) {
    switch (tabIndex) {
      case 0: // Home tab
        controller.fetchAllRestaurantPrograms();
        break;
      case 2: // Rewards tab
        controller.refreshClaimHistory();
        break;
      default:
        break;
    }
  }

  // Method to get the tab at the current index
  Widget _getPage() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          controller: controller,
          refreshData: _refreshData,
          showClaimConfirmation: _showClaimConfirmation,
        );
      case 1:
        return const QrCodePage();
      case 2:
        return RewardsTab(controller: controller);
      case 3:
        return const CustomerProfilePage();
      default:
        return HomeTab(
          controller: controller,
          refreshData: _refreshData,
          showClaimConfirmation: _showClaimConfirmation,
        );
    }
  }

  // Get app bar title based on selected tab
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'Mon QR Code';
      case 2:
        return 'Your Rewards';
      case 3:
        return 'Mon Profil';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: _currentIndex == 3
            ? Image.asset('assets/icons/general-u.png', height: 70)
            : Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        // Add Help menu only for the profile tab (index 3)
        actions: _currentIndex == 3
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'contact_us') {
                        _showContactUsOptions();
                      } else if (value == 'delete_account') {
                        _showDeleteAccountConfirmation();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'contact_us',
                        child: Row(
                          children: [
                            Icon(Icons.headset_mic_sharp,
                          color: MColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Contact Us'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete_account',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Account',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      children: [
                        Icon(Icons.help,
                            color: Theme.of(context).primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Help',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    tooltip: 'Help',
                  ),
                ),
              ]
            : null,
      ),
      body: _getPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR Code',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Récompenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: _changeTab,
      ),
    );
  }

  // Show confirmation dialog before claiming a reward
  void _showClaimConfirmation(dynamic program) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Claim ${program.rewardType}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to claim this reward at ${program.restaurantName}?',
              ),
              const SizedBox(height: 12),
              const Text(
                'Your points will be reset after claiming.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.claimReward(program);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  // Set up a permanent worker to listen for tab navigation events
  void _setupTabNavigationListener() {
    ever(AppEvents.navigateToTab, (int tabIndex) {
      if (kDebugMode) {
        print("DEBUG: Tab navigation event received: $tabIndex");
      }

      if (tabIndex >= 0 && tabIndex < 4) {
        _changeTab(tabIndex);
        // Reset the value to prevent repeated navigations
        AppEvents.navigateToTab.value = -1;
      }
    });
  }

  // Show help options dialog
  void _showContactUsOptions() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Contact Us',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  Icons.card_giftcard,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Question about loyalty program'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLoyaltyProgramsQuestion();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.app_settings_alt,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Question about Rizq application'),
                onTap: () {
                  Navigator.of(context).pop();

                  // Get the profile data for customer information
                  final profile =
                      Get.find<CustomerController>().customerProfile.value;
                  final userId = Get.find<AuthController>().currentUserUid;

                  // Create a formatted message with footer containing customer information
                  String messageWithFooter = '' +
                      '\n\n---------------------------' +
                      '\nSent from Rizq App' +
                      '\nCustomer Information:' +
                      '\nName: ${profile?.name ?? "N/A"}' +
                      '\nEmail: ${profile?.email ?? "N/A"}' +
                      '\nUser ID: $userId';

                  // Launch email with complete information
                  _launchEmailWithBody(
                      email: SupportConstants.supportEmail,
                      subject: 'Question about Rizq Application',
                      body: messageWithFooter);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to encode query parameters
  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Show loyalty programs question dialog
  void _showLoyaltyProgramsQuestion() async {
    CustomerController customerController = Get.find<CustomerController>();

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      // Get the user's active loyalty programs
      if (customerController.loyaltyCards.isEmpty) {
        await customerController.fetchLoyaltyData();
      }
    } finally {
      // Always close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }

    if (customerController.loyaltyCards.isEmpty) {
      Get.snackbar(
        'No Loyalty Programs',
        'You don\'t have any active loyalty programs',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Loyalty Program',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customerController.loyaltyCards.length,
              itemBuilder: (context, index) {
                final program = customerController.loyaltyCards[index];
                return ListTile(
                  leading: program.logoUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(program.logoUrl),
                        )
                      : CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Text(
                            program.restaurantName[0],
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  title: Text(program.restaurantName),
                  subtitle: Text(
                      '${program.points}/${program.pointsRequired} points'),
                  onTap: () async {
                    Navigator.of(context).pop();

                    // Get the profile data for customer information
                    final profile = customerController.customerProfile.value;
                    final userId = Get.find<AuthController>().currentUserUid;

                    // Create a formatted message with footer containing customer information
                    String messageWithFooter = '' +
                        '\n\n---------------------------' +
                        '\nSent from Rizq App' +
                        '\nCustomer Information:' +
                        '\nName: ${profile?.name ?? "N/A"}' +
                        '\nEmail: ${profile?.email ?? "N/A"}' +
                        '\nUser ID: $userId';

                    // Get restaurant email
                    String restaurantEmail =
                        await _getRestaurantEmail(program.restaurantId);

                    // Launch email with complete information
                    _launchEmailWithBody(
                        email: restaurantEmail,
                        subject:
                            'Question about loyalty program at ${program.restaurantName}',
                        body: messageWithFooter);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Separate method to fetch restaurant email and show contact form
  Future<void> _fetchRestaurantEmailAndShowContactForm(dynamic program) async {
    BuildContext? currentContext = Get.context;
    if (currentContext == null) return;

    if (kDebugMode) {
      print(
          'Starting email fetch for restaurant: ${program.restaurantName}, ID: ${program.restaurantId}');
    }

    // Show loading indicator without using context
    final loadingDialogCompleter = Completer();
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fetching contact information...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    ).then((_) => loadingDialogCompleter.complete());

    String restaurantName = program.restaurantName;
    String programDetails =
        '${program.points}/${program.pointsRequired} points - ${program.rewardType}';

    // Initialize with the restaurateur's email
    String contactEmail = await _getRestaurantEmail(program.restaurantId);

    // Always close loading dialog
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // Add a small delay to ensure dialog is fully closed before opening the next one
    await Future.delayed(const Duration(milliseconds: 300));

    // Show the contact form with the restaurant's email (or default if failed)
    if (kDebugMode) {
      print('Showing contact form with email: $contactEmail');
    }

    _showContactForm(
      restaurantEmail: contactEmail,
      restaurantName: restaurantName,
      programDetails: programDetails,
    );
  }

  // Helper method to get restaurant email from multiple sources
  Future<String> _getRestaurantEmail(String restaurantId) async {
    // Default fallback email
            String contactEmail = SupportConstants.supportEmail;

    try {
      // First try to get from restaurants collection
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (restaurantDoc.exists) {
        Map<String, dynamic>? data =
            restaurantDoc.data() as Map<String, dynamic>?;

        if (kDebugMode) {
          print('Restaurant document exists: ${data.toString()}');
        }

        // Check for email in restaurant document (may not exist depending on data model)
        if (data != null &&
            data.containsKey('email') &&
            data['email'] != null &&
            data['email'].toString().isNotEmpty) {
          contactEmail = data['email'];
          if (kDebugMode) {
            print('Found email in restaurant document: $contactEmail');
          }
          return contactEmail;
        }

        // If not found in restaurant document, try to get from users collection
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(restaurantId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic>? userData =
                userDoc.data() as Map<String, dynamic>?;

            if (kDebugMode) {
              print('User document exists: ${userData.toString()}');
            }

            if (userData != null &&
                userData.containsKey('email') &&
                userData['email'] != null &&
                userData['email'].toString().isNotEmpty) {
              contactEmail = userData['email'];
              if (kDebugMode) {
                print('Found email in user document: $contactEmail');
              }
              return contactEmail;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching user document: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('Restaurant document does not exist');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant email: $e');
      }

      // Show error if in debug mode only
      Get.snackbar(
        'Contact Information',
        'Could not retrieve restaurant email. Using default support email.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }

    return contactEmail;
  }

  // Show Rizq application question dialog
  void _showRizqAppQuestion() {
    // We'll use the improved contact form for the Rizq application questions as well
    _showContactForm(
                        restaurantEmail: SupportConstants.supportEmail,
      restaurantName: 'Rizq Support Team',
      programDetails: 'Question about Rizq Application',
    );
  }

  // Final confirmation for account deletion
  void _confirmDeleteAccount() {
    AuthController authController = Get.find<AuthController>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
            'This action is permanent and cannot be undone. All your data will be deleted. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Execute account deletion
              authController.deleteAccount();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Show account deletion confirmation dialog
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
            child: const Text('Yes, I want to delete my account'),
          ),
        ],
      ),
    );
  }

  // Show contact form dialog
  void _showContactForm({
    required String restaurantEmail,
    required String restaurantName,
    required String programDetails,
  }) {
    // Create controllers for input fields
    final TextEditingController subjectController = TextEditingController(
        text:
            'Question about loyalty program at $restaurantName: $programDetails');
    final TextEditingController messageController = TextEditingController();

    // Get customer information
    CustomerController customerController = Get.find<CustomerController>();
    AuthController authController = Get.find<AuthController>();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Contact $restaurantName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email info with nice styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email,
                          color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          restaurantEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            color: Theme.of(context).primaryColor),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: restaurantEmail));
                          Get.snackbar(
                            'Copied',
                            'Email address copied to clipboard',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Subject field
                Text(
                  'Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'Enter subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue or question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your contact information will be automatically included in the email.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Get the profile data for customer information
                final profile = customerController.customerProfile.value;
                final userId = authController.currentUserUid;

                // Create a formatted message with footer containing customer information
                String messageWithFooter = messageController.text +
                    '\n\n---------------------------' +
                    '\nSent from Rizq App' +
                    '\nCustomer Information:' +
                    '\nName: ${profile?.name ?? "N/A"}' +
                    '\nEmail: ${profile?.email ?? "N/A"}' +
                    '\nUser ID: $userId';

                // Launch email with complete information
                _launchEmailWithBody(
                    email: restaurantEmail,
                    subject: subjectController.text,
                    body: messageWithFooter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ),
    );
  }

  // Show fallback dialog when email client can't be launched (with body)
  void _showEmailFallbackDialogWithBody(
      String email, String subject, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Client Not Available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not launch email app automatically. Please copy the information below and send an email manually:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildCopyableField('Email', email),
              const SizedBox(height: 8),
              _buildCopyableField('Subject', subject),
              const SizedBox(height: 8),
              _buildCopyableField('Message', body, maxLines: 5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(
                  text: 'To: $email\nSubject: $subject\n\n$body'));
              Get.snackbar(
                'Copied',
                'All email details copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Copy All'),
          ),
        ],
      ),
    );
  }

  // Build a copyable text field with a copy button
  Widget _buildCopyableField(String label, String content, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    content,
                    maxLines: maxLines,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Get.snackbar(
                    'Copied',
                    'Text copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to launch email with body
  Future<void> _launchEmailWithBody(
      {required String email,
      required String subject,
      required String body}) async {
    final controller = Get.find<CustomerController>();
    final profile = controller.customerProfile.value;
    final userEmail = profile?.email ?? '';
    final uid = Get.find<AuthController>().currentUserUid;

    // Use body as is, without adding footer
    final completeBody = body;

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': completeBody,
      }),
    );

    try {
      // Try to launch with explicit app selection
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );

      if (launched) {
        return; // Successfully launched
      } else {
        // Fallback: Show a dialog with the email information that can be copied
        _showEmailFallbackDialogWithBody(email, subject, completeBody);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching email client: $e');
      }
      // Show error and manual email instructions
      _showEmailFallbackDialogWithBody(email, subject, completeBody);
    }
  }
}
