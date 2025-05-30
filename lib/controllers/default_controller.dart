import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';
import 'order_controller.dart';

class DefaultController extends GetxController
    with GetTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  static DefaultController instance = Get.find();
  RxBool isLoading = false.obs;
  RxBool tableLoading = true.obs;
  RxBool uptableLoading = true.obs;

  RxBool cancelIsLoading = false.obs;

  RxInt tabIndex = 0.obs;
  TabController? tabController;
  TabController? dashboardTabController;
  final OrderController bookingController = Get.put(OrderController());
  var activeTables = 0;

  List serviceList = [];
  List courtList = [];

  //var bookingList         = <Booking>[].obs;
  //var filteredBookingList = <Booking>[].obs;

  var upcomingBookingList = <Booking>[].obs;
  var upcomingfilteredBookingList = <Booking>[].obs;

  var sortColumn = 1;
  var sortColumnBooking = 1;
  var isAscending = true;
  var isAscendingBooking = true;

  //var selectedUser = <User>[].obs;
  var selectedBooking = <Booking>[].obs;
  var selectedBookingSlots = <BookingSlot>[].obs;
  var actionBookingSlots = <BookingSlot>[].obs;

  double? bookingPayments = null;
  var bookingPaymentList = <BookingPayments>[].obs;

  final int _itemsPerPage = 13;
  DocumentSnapshot? _lastDocument;

  //upcoming booking slot table
  RxBool upSlotTableLoading = true.obs;
  var upcomingBookingSlotsList = <BookingSlot>[].obs;
  var upcomingFilteredBookingSlotsList = <BookingSlot>[].obs;
  var sortColumnBookingSlot = 1;
  var isAscendingBookingSlot = true;
  //List<BookingSlot> mergedList          = [];
  //var selectedBookingSlots              = <BookingSlot>[].obs;
  double? bookingSlotPayments = null;
  var bookingSlotPaymentList = <BookingSlotPayments>[].obs;
  RxBool cancelSlotIsLoading = false.obs;

  List<BookingSlot> newBookingSlots =
      []; // Populate this list with your user data
  List<BookingSlot> filteredNewBookingSlots = [];
  bool newSortAscending = true;
  int newSortColumnIndex = 1;

  List<BookingSlot> finishedUnpaidBookingSlots = [];
  List<BookingSlot> filteredFinishedUnpaidBookingSlots = [];
  bool fuSortAscending = true;
  int fuSortColumnIndex = 1;

  List<BookingSlot> allBookingSlots = [];
  List<BookingSlot> filteredAllBookingSlots = [];
  bool allSortAscending = true;
  int allSortColumnIndex = 1;

  List<Booking> bookingList = []; // Populate this list with your user data
  List<Booking> filteredBookingList = [];
  bool BookingSortAscending = true;
  int BookingSortColumnIndex = 1;

  RxBool editLoading = false.obs;
  RxBool cancelLoading = false.obs;
  RxBool paymentLoading = false.obs;

  final selectedIds = <String>[].obs;

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void changeTabIndex(int index) {
    tabIndex.value = index;
    print('table index ${tabIndex.value}');
    update();
  }

  final List<String> dateOptions = [
    'Today',
    'Yesterday',
    'Tomorrow',
    'Last 7 Days',
    'Select Date',
  ];
  RxString selectedDateOption = 'Today'.obs;
  DateTime selectedDate = DateTime.now();

  Future<void> selectDate(BuildContext context, String? id) async {
    if (selectedDateOption.value == 'Today') {
      selectedDate = DateTime.now();
    } else if (selectedDateOption.value == 'Yesterday') {
      selectedDate = DateTime.now().subtract(Duration(days: 1));
    } else if (selectedDateOption.value == 'Tomorrow') {
      selectedDate = DateTime.now().add(Duration(days: 1));
    } else if (selectedDateOption.value == 'Last 7 Days') {
      selectedDate = DateTime.now().subtract(Duration(days: 6));
    } else if (selectedDateOption.value == 'Select Date') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (picked != null && picked != selectedDate) {
        isLoading.value = true;
        selectedDate = picked;
        getBookingSlotDetails(
          userId: id,
          bookingId: null,
          subBookingId: null,
          selDate: selectedDate,
        );
        update();
      }
    }
  }

  RxString allselectedDateOption = 'Today'.obs;
  DateTime allselectedDate = DateTime.now();

  Future<void> allselectDate(BuildContext context) async {
    if (allselectedDateOption.value == 'Today') {
      allselectedDate = DateTime.now();
    } else if (allselectedDateOption.value == 'Yesterday') {
      allselectedDate = DateTime.now().subtract(Duration(days: 1));
    } else if (allselectedDateOption.value == 'Tomorrow') {
      allselectedDate = DateTime.now().add(Duration(days: 1));
    } else if (allselectedDateOption.value == 'Last 7 Days') {
      allselectedDate = DateTime.now().subtract(Duration(days: 6));
    } else if (allselectedDateOption.value == 'Select Date') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: allselectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (picked != null && picked != allselectedDate) {
        allselectedDate = picked;
      }
    }
    update();
  }

  // Stream<QuerySnapshot> _allbookingSlotStream(DateTime selectedDate) {
  //   if (allselectedDateOption.value == 'Last 7 Days') {
  //     return FirebaseFirestore.instance
  //         .collection(authController.centerSlug.toString())
  //         .doc('bookingSlots')
  //         .collection('bookingSlot')
  //         .where(
  //           'date',
  //           isGreaterThanOrEqualTo: DateTime(
  //             selectedDate.year,
  //             selectedDate.month,
  //             selectedDate.day,
  //           ),
  //         )
  //         .where(
  //           'date',
  //           isLessThanOrEqualTo: DateTime(
  //             DateTime.now().year,
  //             DateTime.now().month,
  //             DateTime.now().day,
  //           ),
  //         )
  //         .where('status', isEqualTo: 'Booked')
  //         .snapshots();
  //   } else {
  //     return FirebaseFirestore.instance
  //         .collection(authController.centerSlug.toString())
  //         .doc('bookingSlots')
  //         .collection('bookingSlot')
  //         .where(
  //           'date',
  //           isEqualTo: DateTime(
  //             selectedDate.year,
  //             selectedDate.month,
  //             selectedDate.day,
  //           ),
  //         )
  //         .where('status', isEqualTo: 'Booked')
  //         .snapshots();
  //   }
  // }

  // Stream<QuerySnapshot> getBookingSlotStream(DateTime selectedDate) {
  //   return _allbookingSlotStream(selectedDate);
  // }

  @override
  void onInit() {
    fetchServiceList();
    fetchCourtList();
    //getBookingData();
    //getUpcomingBookingData();
    //getUpcomingBookingSlots();
    super.onInit();
    tabController = TabController(length: 4, vsync: this);

    tabController!.addListener(() {
      if (tabController!.indexIsChanging) return;

      switch (tabController!.index) {
        case 0:
          bookingController.fetchBookings('active');
          break;
        case 1:
          bookingController.fetchBookings('upcoming');
          break;
        case 2:
          bookingController.fetchBookings('scheduled');
          break;
        case 3:
          bookingController.fetchBookings('all');
          break;
      }
    });

    bookingController.fetchBookings('active');

    dashboardTabController = TabController(length: 2, vsync: this);
    dashboardTabController!.addListener(() {
      if (dashboardTabController!.indexIsChanging) return;

      switch (dashboardTabController!.index) {
        case 0:
          bookingController.fetchBookings('court view');
          break;
        case 1:
          bookingController.fetchBookings('Dashboard');
          break;
      }
    });
  }

  @override
  void onClose() {
    tabController!.dispose();
    super.onClose();
  }

  void printReceipt() async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final printerIp = '192.168.31.221';
    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res != PosPrintResult.success) {
      showCustomSnackbar(
        'Printer Error',
        'Failed to connect to the printer.',
        Colors.red,
      );
      return;
    }

    final storeName = 'My Store';
    final storeAddress = '123 Main Street, City';
    final storeMobile = 'Phone: 123-456-7890';
    final orderItems = ['1 x Item A    \$10.00', '2 x Item B    \$15.00'];
    final total = 'Total:        \$25.00';

    // Print header with store information
    printer.text(
      '$storeName\n$storeAddress\n$storeMobile\n',
      styles: PosStyles(align: PosAlign.center),
    );

    // Print logo (if available)
    // Replace 'logo.png' with your actual logo file path
    // final ByteData data = await rootBundle.load('assets/logo.png');
    // final Uint8List logoBytes = data.buffer.asUint8List();
    // printer.image(logoBytes);

    // Print order items
    for (var item in orderItems) {
      printer.text(item);
    }

    // Print total
    printer.text(total, styles: PosStyles(align: PosAlign.right));

    printer.cut();
    printer.disconnect();
    printer.drawer();

    showCustomSnackbar(
      'Print Successful',
      'The receipt has been printed successfully.',
      Colors.green,
    );
  }

  void fetchServiceList() async {
    serviceList.clear();
    isLoading.value = true;

    final response = await supabase
        .schema('s22_prod_schema')
        .from('services')
        .select('id, name, icon, display_order')
        .filter('active', 'eq', true)
        .order('display_order', ascending: true);

    if (response.isNotEmpty) {
      final List services = response;
      for (var service in services) {
        serviceList.add({
          'id': service['id'],
          'name': service['name'],
          'icon': service['icon'],
        });
      }
    } else {
      showCustomSnackbar(
        'Error fetching service',
        response.toString(),
        Colors.redAccent,
      );
    }

    isLoading.value = false;
    update();
  }

  // void fetchServiceList() async {
  //   serviceList.clear();
  //   isLoading.value = true;
  //   QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
  //       .collection(authController.centerSlug.toString())
  //       .doc('services')
  //       .collection('service')
  //       .where('active',isEqualTo: 1)
  //       .orderBy('displayOrder',descending: false)
  //       .get();
  //   for(var service in serviceSnapshot.docs) {
  //     serviceList.add({'id':service.id,'name':service['name'],'icon':service['icon']});
  //     print('getting the service length ${serviceList.length}');
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  String getServiceNameById(String serviceId) {
    final service = serviceList.firstWhere(
      (element) => element['id'] == serviceId,
      orElse: () => null,
    );
    if (service != null) {
      return service['name'] as String;
    } else {
      return 'Service Not Found';
    }
  }

  String getServiceIconById(String serviceId) {
    final service = serviceList.firstWhere(
      (element) => element['id'] == serviceId,
      orElse: () => null,
    );
    if (service != null) {
      return '${service['name']}%${service['icon']}';
    } else {
      return 'Service Not Found';
    }
  }

  void fetchCourtList() async {
    courtList.clear();

    final response = await supabase
        .schema('s22_prod_schema')
        .from('courts')
        .select('id, name')
        .eq('status', true);

    if (response.isEmpty) {
      showCustomSnackbar(
        'Error fetching courts',
        response.toString(),
        Colors.redAccent,
      );
    } else {
      final data = response as List;
      for (var court in data) {
        courtList.add({'id': court['id'], 'name': court['name']});
      }
    }

    isLoading.value = false;
    update();
  }

  // void fetchCourtList() async {
  //   courtList.clear();
  //   isLoading.value = true;
  //   QuerySnapshot courtSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('courts')
  //           .collection('court')
  //           .where('status', isEqualTo: true)
  //           .get();
  //   for (var court in courtSnapshot.docs) {
  //     courtList.add({'id': court.id, 'name': court['name']});
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  String getCourtNameById(String courtId) {
    final court = courtList.firstWhere(
      (element) => element['id'] == courtId,
      orElse: () => null,
    );
    if (court != null) {
      return court['name'] as String;
    } else {
      return 'Court Not Found';
    }
  }

  //New code

  //upcoming booking slots
  void getUpcomingBookingSlots() async {
    upcomingBookingSlotsList.clear();
    upSlotTableLoading.value = true;

    QuerySnapshot bookingSlotsSnapshot =
        await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingSlots')
            .collection('bookingSlot')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                DateTime.now().hour,
                DateTime.now().minute,
              ),
            )
            .where('status', isEqualTo: 'Booked')
            .where(
              'startTime',
              isLessThanOrEqualTo: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day + 1,
                DateTime.now().hour,
                DateTime.now().minute,
              ),
            )
            .orderBy('startTime', descending: false)
            .get();

    if (bookingSlotsSnapshot.docs.isNotEmpty) {
      var allSlots = <BookingSlot>[].obs;

      //Store the booking slots in model
      for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
        String serviceId = subDoc['serviceId'];
        String courtId = subDoc['courtId'];

        String serviceName = await getServiceName(serviceId);
        String courtName = await getCourtName(courtId);

        BookingSlot bookingSlot = BookingSlot(
          id: subDoc.id,
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          bookingId: subDoc['bookingId'],
          subBookingId: subDoc['subBookingId'],
          date: subDoc['date'].toDate(),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: subDoc['startTime'].toDate(),
          endTime: subDoc['endTime'].toDate(),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        allSlots.add(bookingSlot);
      }
      List<BookingSlot> mergedList = mergeBookingSlots(allSlots);
      mergedList.sort((a, b) => a.startTime!.compareTo(b.startTime!));
      for (BookingSlot mSlot in mergedList) {
        upcomingBookingSlotsList.add(mSlot);
      }
    }
    upSlotTableLoading.value = false;
    update();
  }

  List<BookingSlot> mergeBookingSlots(List<BookingSlot> cartItemsMrg) {
    if (cartItemsMrg.isEmpty) return [];

    // Sort the cartItemsMrg based on court, date, startTime, and endTime
    cartItemsMrg.sort((a, b) {
      int courtComparison = a.court!.compareTo(b.court!);
      if (courtComparison != 0) {
        return courtComparison;
      }

      int dateComparison = a.date!.compareTo(b.date!);
      if (dateComparison != 0) {
        return dateComparison;
      }

      int startTimeComparison = a.startTime!.compareTo(b.startTime!);
      if (startTimeComparison != 0) {
        return startTimeComparison;
      }

      return a.endTime!.compareTo(b.endTime!);
    });

    List<BookingSlot> mergedSlots = [];
    BookingSlot currentSlot = cartItemsMrg[0];

    for (int i = 1; i < cartItemsMrg.length; i++) {
      BookingSlot nextSlot = cartItemsMrg[i];

      // Check if the next slot can be merged with the current slot
      if (nextSlot.courtId == currentSlot.courtId &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) ==
              Duration(minutes: 0) &&
          nextSlot.serviceId == currentSlot.serviceId &&
          nextSlot.subBookingId == currentSlot.subBookingId &&
          nextSlot.repeatGroupId == currentSlot.repeatGroupId) {
        // Extend the current slot's endTime and add price
        currentSlot.endTime = nextSlot.endTime;
        currentSlot.price = (currentSlot.price ?? 0) + (nextSlot.price ?? 0);
      } else {
        // Cannot merge, add the current slot to the mergedSlots list
        mergedSlots.add(currentSlot);
        currentSlot = nextSlot; // Update the current slot to the next slot
      }
    }

    // Add the last slot to the mergedSlots list
    mergedSlots.add(currentSlot);

    return mergedSlots;
  }

  //search booking slots
  void searchBookingSlots(String query, int index) {
    switch (index) {
      case 0:
        filteredNewBookingSlots =
            newBookingSlots.where((slot) {
              final bookingId = slot.bookingId!.toLowerCase();
              final court = slot.court!.toLowerCase();
              final name = slot.name!.toLowerCase();
              final mobile = slot.mobile!.toLowerCase();
              return bookingId.contains(query.toLowerCase()) ||
                  court.contains(query.toLowerCase()) ||
                  name.contains(query.toLowerCase()) ||
                  mobile.contains(query.toLowerCase());
            }).toList();
        break;

      case 1:
        filteredFinishedUnpaidBookingSlots =
            finishedUnpaidBookingSlots.where((slot) {
              final bookingId = slot.bookingId!.toLowerCase();
              final court = slot.court!.toLowerCase();
              final name = slot.name!.toLowerCase();
              final mobile = slot.mobile!.toLowerCase();
              return bookingId.contains(query.toLowerCase()) ||
                  court.contains(query.toLowerCase()) ||
                  name.contains(query.toLowerCase()) ||
                  mobile.contains(query.toLowerCase());
            }).toList();
        break;

      case 2:
        filteredAllBookingSlots =
            allBookingSlots.where((slot) {
              final bookingId = slot.bookingId!.toLowerCase();
              final court = slot.court!.toLowerCase();
              final name = slot.name!.toLowerCase();
              final mobile = slot.mobile!.toLowerCase();
              return bookingId.contains(query.toLowerCase()) ||
                  court.contains(query.toLowerCase()) ||
                  name.contains(query.toLowerCase()) ||
                  mobile.contains(query.toLowerCase());
            }).toList();
        break;
    }
    update();
  }

  // sort booking slots column
  void onSortBookingSlotColumn1(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      newBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
      filteredNewBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
    } else if (columnIndex == 1) {
      newBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
      filteredNewBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
    } else if (columnIndex == 2) {
      newBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
      filteredNewBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
    } else if (columnIndex == 3) {
      newBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
      filteredNewBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
    } else if (columnIndex == 5) {
      newBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
      filteredNewBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
    }
    newSortColumnIndex = columnIndex;
    newSortAscending = ascending;
    update();
  }

  void onSortBookingSlotColumn2(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      finishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
      filteredFinishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
    } else if (columnIndex == 1) {
      finishedUnpaidBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
      filteredFinishedUnpaidBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
    } else if (columnIndex == 2) {
      finishedUnpaidBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
      filteredFinishedUnpaidBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
    } else if (columnIndex == 3) {
      finishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
      filteredFinishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
    } else if (columnIndex == 5) {
      finishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
      filteredFinishedUnpaidBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
    }
    fuSortColumnIndex = columnIndex;
    fuSortAscending = ascending;
    update();
  }

  void onSortBookingSlotColumn3(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      allBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
      filteredAllBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.bookingId, item2.bookingId),
      );
    } else if (columnIndex == 1) {
      allBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
      filteredAllBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
    } else if (columnIndex == 2) {
      allBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
      filteredAllBookingSlots.sort(
        (item1, item2) => compareString(ascending, item1.court, item2.court),
      );
    } else if (columnIndex == 3) {
      allBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
      filteredAllBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.startTime, item2.startTime),
      );
    } else if (columnIndex == 5) {
      allBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
      filteredAllBookingSlots.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
    }
    allSortColumnIndex = columnIndex;
    allSortAscending = ascending;
    update();
  }

  // get booking slot details
  Future<void> getBookingSlotDetails({
    String? userId,
    String? bookingId,
    String? subBookingId,
    DateTime? selDate,
  }) async {
    //Clear Bookings
    // selectedUser.clear();
    selectedBooking.clear();
    selectedBookingSlots.clear();

    //Retrieve User Data
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('userDetails')
            .collection('user')
            .doc(userId)
            .get();
    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      // selectedUser.add(
      //   User(
      //     id: userId,
      //     email: userData!['email'],
      //     firstName: userData!['firstName'],
      //     lastName: userData!['lastName'],
      //     address: userData!['address'],
      //     mobile: userData!['mobile'],
      //     postcode: userData!['postcode'],
      //     password: userData!['password'],
      //     aboutus: userData!['aboutus'],
      //     dateOfBirth:
      //         userData!['dateOfBirth'] != null
      //             ? (userData!['dateOfBirth'] as Timestamp).toDate()
      //             : null,
      //     city: userData!['city'],
      //     state: userData!['state'],
      //     country: userData!['country'],
      //     imageUrl: userData!['imageUrl'],
      //     userMembershipId: userData!['userMembershipId'],
      //     createdAt: (userData!['createdAt'] as Timestamp).toDate(),
      //     updatedAt: (userData!['updatedAt'] as Timestamp).toDate(),
      //   ),
      // );

      //Retrieve Booking Data
      QuerySnapshot bookingSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookings')
              .collection('booking')
              // .where('userId', isEqualTo: selectedUser[0].id)
              .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        for (var booking in bookingSnapshot.docs) {
          selectedBooking.add(
            Booking(
              booking.id,
              booking['booking_no'],
              booking['customer_id'],
              booking!['name'],
              booking!['mobile'],
              booking!['email'],
              booking!['notes'],
              booking!['subTotal'].toDouble(),
              booking!['discount'].toDouble(),
              booking!['gst'].toDouble(),
              booking!['total'].toDouble(),
              booking!['paymentType'],
              booking!['paymentStatus'],
              booking!['status'],
              [],
              booking!['createdBy'],
              booking!['updatedBy'],
              booking!['createdAt'].toDate(),
              booking!['updatedAt'].toDate(),
            ),
          );
        }
      }

      QuerySnapshot<Map<String, dynamic>> bookingSlotsSnapshot;

      Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookingSlots')
          .collection('bookingSlot')
          .where('userId', isEqualTo: userId.toString())
          .where('status', isEqualTo: 'Booked');

      if (selectedDateOption.value == 'Last 7 Days') {
        bookingSlotsSnapshot =
            await baseQuery
                .where(
                  'date',
                  isGreaterThanOrEqualTo: DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  ),
                )
                .where(
                  'date',
                  isLessThanOrEqualTo: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                )
                .get();
      } else {
        bookingSlotsSnapshot =
            await baseQuery
                .where(
                  'date',
                  isEqualTo: DateTime(
                    selDate!.year,
                    selDate.month,
                    selDate.day,
                  ),
                )
                .get();
      }

      //Booking Slot query
      /*QuerySnapshot bookingSlotsSnapshot = await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookingSlots')
          .collection('bookingSlot')
          .where('userId',isEqualTo: userId.toString())
          //.where('bookingId',isEqualTo: bookingId.toString())
          //.where('subBookingId',isEqualTo: subBookingId.toString())
          .where('date',isEqualTo: DateTime(selDate!.year,selDate.month,selDate.day))
          .where('status',isEqualTo: 'Booked')
          .get();*/

      //Store the booking slot in model
      for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
        String serviceId = subDoc['serviceId'];
        String courtId = subDoc['courtId'];

        String serviceName = await getServiceName(serviceId);
        String courtName = await getCourtName(courtId);

        BookingSlot bookingSlot = BookingSlot(
          id: subDoc.id,
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          bookingId: subDoc['bookingId'],
          subBookingId: subDoc['subBookingId'],
          date: subDoc['date'].toDate(),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: subDoc['startTime'].toDate(),
          endTime: subDoc['endTime'].toDate(),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        selectedBookingSlots.add(bookingSlot);
      }
    }

    isLoading.value = false;
    update();
  }

  //calculate booking slot payments
  Future calculateBookingSlotPayments({
    String? bookingId,
    String? subBookingId,
  }) async {
    try {
      bookingSlotPayments = null;
      bookingSlotPaymentList.clear();
      QuerySnapshot bookingSlotPaymentSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlotPayments')
              .collection('bookingSlotPayment')
              .where('bookingId', isEqualTo: bookingId.toString())
              .where('subBookingId', isEqualTo: subBookingId.toString())
              .get();

      if (bookingSlotPaymentSnapshot.docs.isNotEmpty) {
        for (var payment in bookingSlotPaymentSnapshot.docs) {
          bookingSlotPaymentList.add(
            BookingSlotPayments(
              payment.id,
              payment['bookingPaymentId'],
              payment['bookingId'],
              payment['subBookingId'],
              payment['paymentType'],
              payment['total'].toDouble(),
              payment['paidAmount'].toDouble(),
              payment['balance'].toDouble(),
              payment['status'],
              payment['createdBy'],
              payment['updatedBy'],
              payment['createdAt'].toDate(),
              payment['updatedAt'].toDate(),
            ),
          );
        }

        double paidAmount = 0;
        double balanceAmount = 0;
        bookingSlotPaymentSnapshot.docs.forEach((doc) {
          paidAmount += doc['paidAmount']!;
          balanceAmount +=
              doc['balance']!; // Assuming the field is named 'total'
        });
        bookingSlotPayments = paidAmount - balanceAmount;
      } else {
        bookingSlotPayments = 0;
      }
    } catch (e) {
      print(e.toString());
    }
  }

  //cancel booking slots
  Future<void> cancelBookingSlot(subBookingId) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlots')
              .collection('bookingSlot')
              .where('subBookingId', isEqualTo: subBookingId.toString())
              .where(
                'startTime',
                isGreaterThanOrEqualTo: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  DateTime.now().hour,
                  DateTime.now().minute,
                ),
              )
              .get();

      List<Future<void>> updateFutures = [];
      for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
        updateFutures.add(
          docSnapshot.reference.update({
            'status': 'Cancelled',
            'updatedBy': authController.userId.toString(),
            'updatedAt': DateTime.now(),
          }),
        );
      }

      await Future.wait(updateFutures);
      showCustomSnackbar(
        'Success',
        'Booking Cancelled Successfully',
        Colors.green,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      cancelSlotIsLoading.value = false;
      update();
      Get.offAllNamed('/');
    }
  }

  // get action booking slot details
  Future<void> getActionBookingSlotDetails({List<String>? selectedIds}) async {
    //Clear Bookings
    actionBookingSlots.clear();

    for (var id in selectedIds!) {
      //Booking Slot query
      QuerySnapshot bookingSlotsSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlots')
              .collection('bookingSlot')
              .where('subBookingId', isEqualTo: id.toString())
              .where('status', isEqualTo: 'Booked')
              .get();

      //Store the booking slot in model
      for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
        String serviceId = subDoc['serviceId'];
        String courtId = subDoc['courtId'];

        String serviceName = await getServiceName(serviceId);
        String courtName = await getCourtName(courtId);

        BookingSlot bookingSlot = BookingSlot(
          id: subDoc.id,
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          bookingId: subDoc['bookingId'],
          subBookingId: subDoc['subBookingId'],
          date: subDoc['date'].toDate(),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: subDoc['startTime'].toDate(),
          endTime: subDoc['endTime'].toDate(),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        actionBookingSlots.add(bookingSlot);
      }
    }

    isLoading.value = false;
    update();
  }

  //cancel booking slots
  Future<void> cancelBookingSlots({List<String>? selectedIds}) async {
    try {
      for (var id in selectedIds!) {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: id.toString())
                .get();

        List<Future<void>> updateFutures = [];
        for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
          updateFutures.add(
            docSnapshot.reference.update({
              'status': 'Cancelled',
              'updatedBy': authController.userId.toString(),
              'updatedAt': DateTime.now(),
            }),
          );
        }
        await Future.wait(updateFutures);
      }

      Get.back();
      Get.back();

      //Status alert
      showCustomSnackbar(
        'Success',
        'Booking Cancelled Successfully',
        Colors.green,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      cancelSlotIsLoading.value = false;
      update();
    }
  }

  Future<void> cancelBookingSlotsHold({List<String>? selectedIds}) async {
    try {
      int totalSelectedItems = 0;
      int totalAvailableItems = 0;

      for (var id in selectedIds!) {
        QuerySnapshot querySnapshot1 =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: id.toString())
                .get();
        totalSelectedItems = querySnapshot1.docs.length;

        QuerySnapshot querySnapshot2 =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: id.toString())
                .where('startTime', isGreaterThan: Timestamp.now())
                .get();
        totalAvailableItems = querySnapshot2.docs.length;
      }

      if (totalSelectedItems == totalAvailableItems) {
        print('test');
        for (var id in selectedIds!) {
          QuerySnapshot querySnapshot =
              await FirebaseFirestore.instance
                  .collection(authController.centerSlug.toString())
                  .doc('bookingSlots')
                  .collection('bookingSlot')
                  .where('subBookingId', isEqualTo: id.toString())
                  .where('startTime', isGreaterThan: Timestamp.now())
                  .get();

          List<Future<void>> updateFutures = [];
          for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
            updateFutures.add(
              docSnapshot.reference.update({
                'status': 'Cancelled',
                'updatedBy': authController.userId.toString(),
                'updatedAt': DateTime.now(),
              }),
            );
          }
          await Future.wait(updateFutures);
        }

        //Status alert
        showCustomSnackbar(
          'Success',
          'Booking Cancelled Successfully',
          Colors.green,
        );
        cancelSlotIsLoading.value = false;
        update();
        Get.back();
      } else {
        //Status alert
        showCustomSnackbar(
          'Warning',
          'Some Bookings already Started Unable to Delete that.',
          Colors.orange,
        );
        cancelSlotIsLoading.value = false;
        update();
        Get.back();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  //New code

  //retrive booking
  void getBookingData() async {
    bookingList.clear();
    tableLoading.value = true;

    //Retrieve the booking using unique Booking Ids
    Query query = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookings')
        .collection('booking')
        .orderBy('createdAt', descending: true)
        .limit(_itemsPerPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot bookingSnapshot = await query.get();

    if (bookingSnapshot.docs.isNotEmpty) {
      _lastDocument = bookingSnapshot.docs.last;
      for (var booking in bookingSnapshot.docs) {
        List<BookingSlot> bookingSlots = [];

        //Booking slots query
        QuerySnapshot bookingSlotSnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('bookingId', isEqualTo: booking.id)
                .get();

        //Store the booking slots in model
        for (DocumentSnapshot subDoc in bookingSlotSnapshot.docs) {
          String serviceId = subDoc['serviceId'];
          //String courtId   = subDoc['courtId'];

          String serviceName = await getServiceName(serviceId);
          //String courtName = await getCourtName(courtId);
          String courtName = '';

          BookingSlot bookingSlot = BookingSlot(
            id: subDoc.id,
            userId: subDoc['userId'],
            name: subDoc['name'],
            mobile: subDoc['mobile'],
            date: subDoc['date'].toDate(),
            service: serviceName,
            serviceId: subDoc['serviceId'],
            court: courtName,
            courtId: subDoc['courtId'],
            startTime: subDoc['startTime'].toDate(),
            endTime: subDoc['endTime'].toDate(),
            price: subDoc['price'].toDouble(),
          );
          bookingSlots.add(bookingSlot);
        }
        //Store the Bookings
        bookingList.add(
          Booking(
            booking.id,
            booking['booking_no'],
            booking['customer_id'],
            booking['name'],
            booking['mobile'],
            booking['email'],
            booking['notes'],
            booking['subTotal'].toDouble(),
            booking['discount'].toDouble(),
            booking['gst'].toDouble(),
            booking['total'].toDouble(),
            booking['paymentType'],
            booking['paymentStatus'],
            booking['status'],
            bookingSlots,
            booking['createdBy'],
            booking['updatedBy'],
            booking['createdAt'].toDate(),
            booking['updatedAt'].toDate(),
          ),
        );
      }

      bookingList.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    }
    tableLoading.value = false;
    update();
  }

  void loadMoreBookingData() async {
    //Retrieve the booking using unique Booking Ids
    Query query = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookings')
        .collection('booking')
        .orderBy('createdAt', descending: true)
        .limit(_itemsPerPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot bookingSnapshot = await query.get();

    if (bookingSnapshot.docs.isNotEmpty) {
      _lastDocument = bookingSnapshot.docs.last;
      for (var booking in bookingSnapshot.docs) {
        List<BookingSlot> bookingSlots = [];

        //Booking slots query
        QuerySnapshot bookingSlotSnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('bookingId', isEqualTo: booking.id)
                .get();

        //Store the booking slots in model
        for (DocumentSnapshot subDoc in bookingSlotSnapshot.docs) {
          String serviceId = subDoc['serviceId'];
          //String courtId   = subDoc['courtId'];

          String serviceName = await getServiceName(serviceId);
          //String courtName = await getCourtName(courtId);
          String courtName = '';

          BookingSlot bookingSlot = BookingSlot(
            id: subDoc.id,
            userId: subDoc['userId'],
            name: subDoc['name'],
            mobile: subDoc['mobile'],
            date: subDoc['date'].toDate(),
            service: serviceName,
            serviceId: subDoc['serviceId'],
            court: courtName,
            courtId: subDoc['courtId'],
            startTime: subDoc['startTime'].toDate(),
            endTime: subDoc['endTime'].toDate(),
            price: subDoc['price'].toDouble(),
          );
          bookingSlots.add(bookingSlot);
        }
        //Store the Bookings
        bookingList.add(
          Booking(
            booking.id,
            booking['booking_no'],
            booking['customer_id'],
            booking['name'],
            booking['mobile'],
            booking['email'],
            booking['notes'],
            booking['subTotal'].toDouble(),
            booking['discount'].toDouble(),
            booking['gst'].toDouble(),
            booking['total'].toDouble(),
            booking['paymentType'],
            booking['paymentStatus'],
            booking['status'],
            bookingSlots,
            booking['createdBy'],
            booking['updatedBy'],
            booking['createdAt'].toDate(),
            booking['updatedAt'].toDate(),
          ),
        );
      }

      bookingList.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    }
    update();
  }

  //search booking
  void searchBooking(String query) {
    filteredBookingList =
        bookingList.where((booking) {
          final id = booking.id!.toLowerCase();
          final name = booking.name!.toLowerCase();
          final paymentStatus = booking.paymentStatus!.toLowerCase();
          return id.contains(query.toLowerCase()) ||
              name.contains(query.toLowerCase()) ||
              paymentStatus.contains(query.toLowerCase());
        }).toList();
    update();
  }

  // sort booking column
  void onSortBookingColumn(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      bookingList.sort(
        (item1, item2) => compareString(ascending, item1.id, item2.id),
      );
      filteredBookingList.sort(
        (item1, item2) => compareString(ascending, item1.id, item2.id),
      );
    } else if (columnIndex == 1) {
      bookingList.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
      filteredBookingList.sort(
        (item1, item2) => compareString(ascending, item1.name, item2.name),
      );
    } else if (columnIndex == 2) {
      bookingList.sort(
        (item1, item2) =>
            compareString(ascending, item1.createdAt, item2.createdAt),
      );
      filteredBookingList.sort(
        (item1, item2) =>
            compareString(ascending, item1.createdAt, item2.createdAt),
      );
    } else if (columnIndex == 4) {
      bookingList.sort(
        (item1, item2) => compareString(ascending, item1.status, item2.status),
      );
      filteredBookingList.sort(
        (item1, item2) => compareString(ascending, item1.status, item2.status),
      );
    } else if (columnIndex == 5) {
      bookingList.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
      filteredBookingList.sort(
        (item1, item2) =>
            compareString(ascending, item1.paymentStatus, item2.paymentStatus),
      );
    }
    BookingSortColumnIndex = columnIndex;
    BookingSortAscending = ascending;
    update();
  }

  //retrive upcoming booking
  void getUpcomingBookingData() async {
    upcomingBookingList.clear();
    uptableLoading.value = true;
    Set<String> uniqueBookingIds = {};

    QuerySnapshot bookingSlotsSnapshot =
        await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingSlots')
            .collection('bookingSlot')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                DateTime.now().hour,
                DateTime.now().minute,
              ),
            )
            .get();

    if (bookingSlotsSnapshot.docs.isNotEmpty) {
      //Set<String> uniqueBookingIds = {};
      bookingSlotsSnapshot.docs.forEach((doc) {
        // Get the 'bookingId' field from the document data
        String bookingId = doc['bookingId'];

        // Add the bookingId to the set (Sets automatically handle uniqueness)
        uniqueBookingIds.add(bookingId);
      });
      List<String> distinctBookingIds = uniqueBookingIds.toList();

      //Retrieve the booking using unique Booking Ids
      QuerySnapshot bookingSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookings')
              .collection('booking')
              .where(FieldPath.documentId, whereIn: distinctBookingIds)
              //.orderBy('createdAt',descending: true)
              .get();
      for (var booking in bookingSnapshot.docs) {
        List<BookingSlot> bookingSlots = [];

        //Booking slots query
        QuerySnapshot bookingSlotSnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('bookingId', isEqualTo: booking.id)
                .get();

        //Store the booking slots in model
        for (DocumentSnapshot subDoc in bookingSlotSnapshot.docs) {
          String serviceId = subDoc['serviceId'];
          String courtId = subDoc['courtId'];

          String serviceName = await getServiceName(serviceId);
          //String courtName = await getCourtName(courtId);
          String courtName = '';

          BookingSlot bookingSlot = BookingSlot(
            id: subDoc.id,
            userId: subDoc['userId'],
            name: subDoc['name'],
            mobile: subDoc['mobile'],
            date: subDoc['date'].toDate(),
            service: serviceName,
            serviceId: subDoc['serviceId'],
            court: courtName,
            courtId: subDoc['courtId'],
            startTime: subDoc['startTime'].toDate(),
            endTime: subDoc['endTime'].toDate(),
            price: subDoc['price'].toDouble(),
          );
          bookingSlots.add(bookingSlot);
        }
        //Store the Bookings
        upcomingBookingList.add(
          Booking(
            booking.id,
            booking['booking_no'],
            booking['customer_id'],
            booking['name'],
            booking['mobile'],
            booking['email'],
            booking['notes'],
            booking['subTotal'].toDouble(),
            booking['discount'].toDouble(),
            booking['gst'].toDouble(),
            booking['total'].toDouble(),
            booking['paymentType'],
            booking['paymentStatus'],
            booking['status'],
            bookingSlots,
            booking['createdBy'],
            booking['updatedBy'],
            booking['createdAt'].toDate(),
            booking['updatedAt'].toDate(),
          ),
        );
      }
    }
    upcomingBookingList.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    uptableLoading.value = false;
    update();
  }

  int compareString(bool ascending, var val1, var val2) =>
      ascending
          ? Comparable.compare(val1, val2)
          : Comparable.compare(val2, val1);

  // Function to get service name from local cache or Firestore
  Future<String> getServiceName(String serviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serviceName = prefs.getString('service_$serviceId');
    if (serviceName == null) {
      // Service name not found in cache, fetch it from Firestore
      DocumentSnapshot serviceDoc =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('services')
              .collection('service')
              .doc(serviceId)
              .get();
      serviceName = serviceDoc['name'];
      prefs.setString(
        'service_$serviceId',
        serviceName!,
      ); // Cache the service name
    }
    return serviceName;
  }

  // Function to get court name from local cache or Firestore
  Future<String> getCourtName(String courtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? courtName = prefs.getString('court_$courtId');
    if (courtName == null) {
      // Court name not found in cache, fetch it from Firestore
      DocumentSnapshot courtDoc =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('courts')
              .collection('court')
              .doc(courtId)
              .get();
      courtName = courtDoc['name'];
      prefs.setString('court_$courtId', courtName!); // Cache the court name
    }
    return courtName;
  }

  // Function to get user name from local cache or Firestore
  Future<String> getUserName(String bookingId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('booking_user_$bookingId');
    if (userName == null) {
      DocumentSnapshot bookingDoc =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookings')
              .collection('booking')
              .doc(bookingId)
              .get();
      if (bookingDoc != '') {
        // User name not found in cache, fetch it from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('userDetails')
                .collection('user')
                .doc(bookingDoc['userId'])
                .get();
        userName = userDoc['firstName'].toString();
        prefs.setString(
          'booking_user_$bookingId',
          userName!,
        ); // Cache the service name
      } else {
        userName = '';
      }
    }
    return userName;
  }

  List<BookingSlot> mergeTimeSlots(List<BookingSlot> cartItemsMrg) {
    if (cartItemsMrg.isEmpty) return [];

    // Sort the cartItemsMrg based on court, date, startTime, and endTime
    cartItemsMrg.sort((a, b) {
      int courtComparison = a.court!.compareTo(b.court!);
      if (courtComparison != 0) {
        return courtComparison;
      }

      int dateComparison = a.date!.compareTo(b.date!);
      if (dateComparison != 0) {
        return dateComparison;
      }

      int startTimeComparison = a.startTime!.compareTo(b.startTime!);
      if (startTimeComparison != 0) {
        return startTimeComparison;
      }

      return a.endTime!.compareTo(b.endTime!);
    });

    List<BookingSlot> mergedSlots = [];
    BookingSlot currentSlot = cartItemsMrg[0];

    for (int i = 1; i < cartItemsMrg.length; i++) {
      BookingSlot nextSlot = cartItemsMrg[i];

      // Check if the next slot can be merged with the current slot
      if (nextSlot.court == currentSlot.court &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) ==
              Duration(minutes: 0) &&
          nextSlot.serviceId == currentSlot.serviceId &&
          nextSlot.subBookingId == currentSlot.subBookingId &&
          nextSlot.repeatGroupId == currentSlot.repeatGroupId) {
        // Extend the current slot's endTime and add price
        currentSlot.endTime = nextSlot.endTime;
        currentSlot.price = (currentSlot.price ?? 0) + (nextSlot.price ?? 0);
      } else {
        // Cannot merge, add the current slot to the mergedSlots list
        mergedSlots.add(currentSlot);
        currentSlot = nextSlot; // Update the current slot to the next slot
      }
    }

    // Add the last slot to the mergedSlots list
    mergedSlots.add(currentSlot);

    return mergedSlots;
  }

  Future<void> cancelEntireBooking(bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookings')
          .collection('booking')
          .doc(bookingId)
          .update({
            'status': 'Cancelled',
            'updatedBy': authController.userId.toString(),
            'updatedAt': DateTime.now(),
          });

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlots')
              .collection('bookingSlot')
              .where('bookingId', isEqualTo: bookingId.toString())
              .where(
                'startTime',
                isGreaterThanOrEqualTo: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  DateTime.now().hour,
                  DateTime.now().minute,
                ),
              )
              .get();

      List<Future<void>> updateFutures = [];
      for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
        updateFutures.add(
          docSnapshot.reference.update({
            'status': 'Cancelled',
            'updatedBy': authController.userId.toString(),
            'updatedAt': DateTime.now(),
          }),
        );
      }

      await Future.wait(updateFutures);

      showCustomSnackbar(
        'Success',
        'Booking Cancelled Successfully',
        Colors.green,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      onInit();
      cancelIsLoading.value = false;
      update();
      Get.offAllNamed('/');
    }
  }

  void getBookingDetails(String? id) async {
    //Clear Bookings
    selectedBooking.clear();
    List<BookingSlot> bookingSlots = [];

    //Retrieve Booking Data
    DocumentSnapshot bookingSnapshot =
        await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookings')
            .collection('booking')
            .doc(id)
            .get();

    if (bookingSnapshot.exists) {
      Map<String, dynamic>? booking =
          bookingSnapshot.data() as Map<String, dynamic>?;

      //Booking Slot query
      QuerySnapshot bookingSlotsSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlots')
              .collection('bookingSlot')
              .where('bookingId', isEqualTo: id.toString())
              .get();

      //Store the booking slot in model
      for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
        String serviceId = subDoc['serviceId'];
        String courtId = subDoc['courtId'];

        String serviceName = await getServiceName(serviceId);
        String courtName = await getCourtName(courtId);

        BookingSlot bookingSlot = BookingSlot(
          id: subDoc.id,
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          bookingId: subDoc['bookingId'],
          subBookingId: subDoc['subBookingId'],
          date: subDoc['date'].toDate(),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: subDoc['startTime'].toDate(),
          endTime: subDoc['endTime'].toDate(),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        bookingSlots.add(bookingSlot);
      }

      selectedBooking.add(
        Booking(
          id,
          booking?['booking_no'],
          booking?['customer_id'],
          booking!['name'],
          booking!['mobile'],
          booking!['email'],
          booking!['notes'],
          booking!['subTotal'].toDouble(),
          booking!['discount'].toDouble(),
          booking!['gst'].toDouble(),
          booking!['total'].toDouble(),
          booking!['paymentType'],
          booking!['paymentStatus'],
          booking!['status'],
          bookingSlots,
          booking!['createdBy'],
          booking!['updatedBy'],
          booking!['createdAt'].toDate(),
          booking!['updatedAt'].toDate(),
        ),
      );
    }
    isLoading.value = false;
    update();
  }

  Future calculatePayments({String? bookingId}) async {
    try {
      bookingPayments = null;
      bookingPaymentList.clear();
      QuerySnapshot bookingPaymentSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingPayments')
              .collection('bookingPayment')
              .where('bookingId', isEqualTo: bookingId.toString())
              .get();
      if (bookingPaymentSnapshot.docs.isNotEmpty) {
        for (var payment in bookingPaymentSnapshot.docs) {
          /*bookingPaymentList.add(BookingPayments(
              payment.id,
              payment['bookingId'],
              payment['paymentType'],
              payment['total'].toDouble(),
              payment['paidAmount'].toDouble(),
              payment['balance'].toDouble(),
              payment['status'],
              payment['createdBy'],
              payment['updatedBy'],
              payment['createdAt'].toDate(),
              payment['updatedAt'].toDate()
          ));*/
        }

        double paidAmount = 0;
        double balanceAmount = 0;
        bookingPaymentSnapshot.docs.forEach((doc) {
          paidAmount += doc['paidAmount']!;
          balanceAmount +=
              doc['balance']!; // Assuming the field is named 'total'
        });
        bookingPayments = paidAmount - balanceAmount;
      } else {
        bookingPayments = 0;
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String> getBookingName(String bookingId) async {
    try {
      DocumentSnapshot bookingSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookings')
              .collection('booking')
              .doc(bookingId)
              .get();
      if (bookingSnapshot.exists) {
        return bookingSnapshot.get('name');
      } else {
        return 'Booking not found';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
