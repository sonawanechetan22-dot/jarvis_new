import 'dart:io';

import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const JarvisApp());
}

// ================= APP =================

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JarvisHome(),
    );
  }
}

// ================= HOME =================

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final TextEditingController controller = TextEditingController();
  final Battery battery = Battery();

  String result = "";

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // ================= PERMISSIONS =================

  Future<void> requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.camera,
      Permission.location,
      Permission.photos,
      Permission.videos,
    ].request();
  }

  // ================= MAIN LOGIC =================

  Future<void> runJarvis(String cmd) async {
    cmd = cmd.trim().toLowerCase();

    String response = "";

    // WIFI (Android Restricted)
    if (cmd.contains("wifi")) {
      response = "WiFi control Android मध्ये परवानगी नाही";
    }

    // BATTERY
    else if (cmd.contains("battery") || cmd.contains("बॅटरी")) {
      int level = await battery.batteryLevel;
      response = "Battery $level% आहे";
    }

    // VIBRATE
    else if (cmd.contains("vibrate") || cmd.contains("वायब्रेट")) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 1000);
        response = "Phone vibrate झाला";
      } else {
        response = "Vibrator नाही";
      }
    }

    // FLASH ON
    else if (cmd.contains("flash on")) {
      try {
        await TorchLight.enableTorch();
        response = "Flash ON";
      } catch (e) {
        response = "Flash error";
      }
    }

    // FLASH OFF
    else if (cmd.contains("flash off")) {
      try {
        await TorchLight.disableTorch();
        response = "Flash OFF";
      } catch (e) {
        response = "Flash error";
      }
    }

    // IMAGE
    else if (cmd.contains("open image")) {
      String key = cmd.split("open image").last.trim();
      response = await searchImage(key);
    }

    // VIDEO
    else if (cmd.contains("open video")) {
      String key = cmd.split("open video").last.trim();
      response = await searchVideo(key);
    }

    // UNKNOWN
    else {
      response = "Command समजला नाही";
    }

    await saveLog(cmd, response);

    setState(() {
      result = response;
    });
  }

  // ================= IMAGE SEARCH =================

  Future<String> searchImage(String key) async {
    Directory dir = Directory("/storage/emulated/0");

    await for (var f in dir.list(recursive: true)) {
      if (f is File) {
        String name = f.path.toLowerCase();

        if (name.contains(key.toLowerCase()) &&
            (name.endsWith(".jpg") ||
                name.endsWith(".jpeg") ||
                name.endsWith(".png"))) {

          await OpenFilex.open(f.path);

          return "Image opened";
        }
      }
    }

    return "Image not found";
  }

  // ================= VIDEO SEARCH =================

  Future<String> searchVideo(String key) async {
    Directory dir = Directory("/storage/emulated/0");

    await for (var f in dir.list(recursive: true)) {
      if (f is File) {
        String name = f.path.toLowerCase();

        if (name.contains(key.toLowerCase()) &&
            (name.endsWith(".mp4") ||
                name.endsWith(".mkv") ||
                name.endsWith(".avi") ||
                name.endsWith(".mov") ||
                name.endsWith(".3gp") ||
                name.endsWith(".webm"))) {

          await OpenFilex.open(f.path);

          return "Video opened";
        }
      }
    }

    return "Video not found";
  }

  // ================= SAVE LOG =================

  Future<void> saveLog(String cmd, String res) async {
    Directory dir = await getExternalStorageDirectory() ??
        Directory("/storage/emulated/0");

    File file = File("${dir.path}/jarvis.txt");

    await file.writeAsString(
      "Command: $cmd\nResponse: $res\n\n",
      mode: FileMode.append,
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Jarvis AI"),
        backgroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // INPUT
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),

              decoration: const InputDecoration(
                hintText: "Type command...",
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  runJarvis(controller.text);
                },

                child: const Text("RUN"),
              ),
            ),

            const SizedBox(height: 25),

            // RESULT
            Text(
              result,

              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
