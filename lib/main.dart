import 'dart:io';

import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const JarvisApp());
}

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

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final TextEditingController controller = TextEditingController();
  final Battery battery = Battery();

  String result = "";

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // ================= PERMISSIONS =================

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  // ================= MAIN =================

  Future<void> runJarvis(String cmd) async {
    cmd = cmd.trim().toLowerCase();

    String response = "";

    // Battery
    if (cmd.contains("battery")) {
      int level = await battery.batteryLevel;
      response = "Battery $level%";
    }

    // Vibrate
    else if (cmd.contains("vibrate")) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 800);
        response = "Vibrating";
      }
    }

    // Flash ON
    else if (cmd.contains("flash on")) {
      await TorchLight.enableTorch();
      response = "Flash ON";
    }

    // Flash OFF
    else if (cmd.contains("flash off")) {
      await TorchLight.disableTorch();
      response = "Flash OFF";
    }

    // Image
    else if (cmd.startsWith("open image")) {
      String key = cmd.replaceFirst("open image", "").trim();
      response = await openImage(key);
    }

    // Video
    else if (cmd.startsWith("open video")) {
      String key = cmd.replaceFirst("open video", "").trim();
      response = await openVideo(key);
    }

    else {
      response = "Command not recognized";
    }

    await saveLog(cmd, response);

    setState(() {
      result = response;
    });
  }

  // ================= IMAGE =================

  Future<String> openImage(String key) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      return "Storage permission not granted";
    }

    final dir = Directory("/storage/emulated/0");

    await for (var file in dir.list(recursive: true)) {
      if (file is File) {
        final name = file.path.toLowerCase();

        if (name.contains(key.toLowerCase()) &&
            (name.endsWith(".jpg") ||
                name.endsWith(".png") ||
                name.endsWith(".jpeg"))) {

          await OpenFilex.open(file.path);

          return "Image opened";
        }
      }
    }

    return "Image not found";
  }

  // ================= VIDEO =================

  Future<String> openVideo(String key) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      return "Storage permission not granted";
    }

    final dir = Directory("/storage/emulated/0");

    await for (var file in dir.list(recursive: true)) {
      if (file is File) {
        final name = file.path.toLowerCase();

        if (name.contains(key.toLowerCase()) &&
            (name.endsWith(".mp4") ||
                name.endsWith(".mkv") ||
                name.endsWith(".avi") ||
                name.endsWith(".mov"))) {

          await OpenFilex.open(file.path);

          return "Video opened";
        }
      }
    }

    return "Video not found";
  }

  // ================= LOG =================

  Future<void> saveLog(String cmd, String res) async {
    final dir = await getExternalStorageDirectory();

    final file = File("${dir!.path}/jarvis.txt");

    await file.writeAsString(
      "$cmd => $res\n",
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

            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),

              decoration: const InputDecoration(
                hintText: "Enter command",
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  runJarvis(controller.text);
                },

                child: const Text("RUN"),
              ),
            ),

            const SizedBox(height: 20),

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
