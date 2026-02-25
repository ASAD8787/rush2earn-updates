import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class PedometerService {
  Stream<StepCount> get stepCountStream => Pedometer.stepCountStream;
  Stream<PedestrianStatus> get pedestrianStatusStream =>
      Pedometer.pedestrianStatusStream;

  Future<bool> requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }
}
