import 'package:permission_handler/permission_handler.dart';import 'dart:io';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jarvis AI',
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
@override
void initState() {
  super.initState();
  requestPermissions();
}
  final TextEditingController controller = TextEditingController();
  final Battery battery = Battery();
  String result = "";


Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.camera,
    Permission.location,
  ].request();
}
  // ================= MAIN JARVIS ==================
  Future<void> runJarvis(String cmd) async {
    cmd = cmd.trim().toLowerCase();
    String response = "";

    // WiFi
    if (cmd.contains("wifi")) {
      response = "Android मध्ये WiFi control परवानगी नाही";
    }
    // Battery
    else if (cmd.contains("battery") || cmd.contains("बॅटरी")) {
      int level = await battery.batteryLevel;
      response = "बॅटरी $level टक्के आहे";
    }
    // Vibrate
    else if (cmd.contains("vibrate") || cmd.contains("वायब्रेट")) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 1000);
        response = "फोन वायब्रेट झाला";
      } else {
        response = "Vibrator नाही";
      }
    }
    // Flash ON
    else if (cmd.contains("flash on") || cmd.contains("लाईट लावा")) {
      try {
        await TorchLight.enableTorch();
        response = "फ्लॅश सुरू आहे";
      } catch (e) {
        response = "Flash Error";
      }
    }
    // Flash OFF
    else if (cmd.contains("flash off") || cmd.contains("लाईट बंद")) {
      try {
        await TorchLight.disableTorch();
        response = "फ्लॅश बंद आहे";
      } catch (e) {
        response = "Flash Error";
      }
    }
    // Image Search
    else if (cmd.startsWith("open image")) {
      String key = cmd.replaceFirst("open image", "").trim();
      response = await searchImage(key);
    }
    // Video Search
    else if (cmd.startsWith("open video")) {
      String key = cmd.replaceFirst("open video", "").trim();
      response = await searchVideo(key);
    }
    // Unknown
    else {
      response = "माफ करा, मी हा आदेश समजू शकत नाही";
    }

    await saveLog(cmd, response);
    setState(() {
      result = response;
    });
  }

  // ================= IMAGE SEARCH ==================
  Future<String> searchImage(String key) async {
    await Permission.storage.request();
    Directory dir = Directory("/storage/emulated/0");
    List<FileSystemEntity> files =
        dir.listSync(recursive: true, followLinks: false);
    for (var f in files) {
      if (f is File) {
        String name = f.path.toLowerCase();
        if (name.contains(key.toLowerCase()) &&
            (name.endsWith(".jpg") ||
                name.endsWith(".jpeg") ||
                name.endsWith(".png"))) {
          return f.path;
        }
      }
    }
    return "NOT_FOUND";
  }

  // ================= VIDEO SEARCH ==================
  Future<String> searchVideo(String key) async {
    await Permission.storage.request();
    Directory dir = Directory("/storage/emulated/0");
    List<FileSystemEntity> files =
        dir.listSync(recursive: true, followLinks: false);
    String k = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (var f in files) {
      if (f is File) {
        String name = f.path.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (name.contains(k) &&
            (f.path.endsWith(".mp4") ||
                f.path.endsWith(".mkv") ||
                f.path.endsWith(".avi") ||
                f.path.endsWith(".mov") ||
                f.path.endsWith(".3gp") ||
                f.path.endsWith(".webm"))) {
          return f.path;
        }
      }
    }
    return "NOT_FOUND";
  }

  // ================= SAVE LOG ==================
  Future<void> saveLog(String cmd, String res) async {
    Directory dir = await getExternalStorageDirectory() ??
        Directory("/storage/emulated/0");
    File file = File("${dir.path}/jarvis.txt");
    await file.writeAsString(
      "कमांड: $cmd\nउत्तर: $res\n\n",
      mode: FileMode.append,
    );
  }

  // ================= UI ==================
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
                hintText: "कमांड लिहा...",
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
