import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'Model/notifcation_prayer.dart';
import 'screens/HomeView.dart';
import 'screens/homePage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  schedulePrayerNotifications();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeNotifications();
  runApp(ChangeNotifierProvider<AppState>(
      create: (_) => AppState(), child: MyApp()));
}

Future<void> initializeNotifications() async {
  // Request permission for notifications
  await requestNotificationPermission();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  // Initialize Flutter Local Notifications Plugin
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Schedule prayer notifications
  schedulePrayerNotifications();
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class AppState with ChangeNotifier {
  int pageOfSaved = 0;
  int actualPage = 0;
  bool first = false;

  int qareaa = 1;
  late int prayer;

  void setPageOfSaved(int val) {
    pageOfSaved = val;
    notifyListeners();
  }

  void setActualPage(int val) {
    actualPage = val;
    notifyListeners();
  }

  void setQareaa(int qar) {
    qareaa = qar;
    notifyListeners();
  }

  void setPrayer(int pr) {
    prayer = pr;
    notifyListeners();
  }

  get getPageOfSaved => pageOfSaved;
  get getActualPage => actualPage;
  get getQareaa => qareaa;
  get getPrayer => prayer;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int page;

  @override
  void initState() {
    super.initState();
    initializeAppState();
  }

  Future<void> initializeAppState() async {
    await _determinePosition();
    Wakelock.enable();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      theme: ThemeData(primaryColor: Colors.black, hintColor: Colors.black),
      home: FutureBuilder<bool>(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data == true) {
            return LifeCycleManager(child: MyHomePage(initialPage: page));
          }

          return LifeCycleManager(child: MyHomePage(initialPage: page + 1));
        },
      ),
    );
  }

  Future<bool> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    AppState appState = Provider.of<AppState>(context, listen: false);

    int savedPage = prefs.getInt('savedPage') ?? 0;
    int lastPage = prefs.getInt('lastPage') ?? 0;
    int qareaa = prefs.getInt("Qareaa") ?? 1;
    int prayer = prefs.getInt("prayer") ?? 0;

    page = lastPage;
    appState.setQareaa(qareaa);
    appState.setPrayer(prayer);
    appState.setActualPage(lastPage);
    appState.setPageOfSaved(savedPage);

    return page != 0;
  }
}
