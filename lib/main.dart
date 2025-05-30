import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Upload to S3',
      home: FileUploader(),
    );
  }
}

class FileUploader extends StatefulWidget {
  @override
  _FileUploaderState createState() => _FileUploaderState();
}

class _FileUploaderState extends State<FileUploader> {
  String status = '';

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      setState(() {
        status = 'No file selected.';
      });
      return;
    }

    if (kIsWeb) {
      // Web
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;

      if (fileBytes != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/uploadfiletos3/'), // Your Django endpoint
        );
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));
        var response = await request.send();

        setState(() {
          status = response.statusCode == 200 ? 'Uploaded successfully!' : 'Upload failed!';
            
        });

      }
    } else {
      // Mobile/Desktop
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/uploadfiletos3/'), // Android emulator? use 10.0.2.2
      );
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));

      var response = await request.send();

      setState(() {
        status = response.statusCode == 200 ? 'Uploaded successfully!' : 'Upload failed!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload File to S3")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickAndUploadFile,
              child: const Text("S3 Images"),
            ),
            const SizedBox(height: 20),
           
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Text(
    status,
    textAlign: TextAlign.center,
    softWrap: true,
    style: TextStyle(fontSize: 16),
  ),
),

ElevatedButton(
              onPressed: (){
Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  S3ImagesScreen()),
                                        );},
              child: const Text("Select & Upload File"),
            ),

          ],
        ),
      ),
    );
  }
}


class S3ImagesScreen extends StatefulWidget {
  @override
  _S3ImagesScreenState createState() => _S3ImagesScreenState();
}

class _S3ImagesScreenState extends State<S3ImagesScreen> {
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
  }

  Future<void> fetchImageUrls() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/receivefilesfroms3/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        imageUrls = List<String>.from(data['files']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to fetch images");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('S3 Bucket Images')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: Icon(Icons.broken_image)),
                );
              },
            ),
    );
  }
}

