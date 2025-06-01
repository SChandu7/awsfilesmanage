import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // Add this import
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
          Uri.parse(
              'https://8671a5f8-6323-4a16-9356-a2dd53e7078c-00-2m041txxfet0b.pike.replit.dev/uploadfiletos3/'), // Your Django endpoint
        );
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));
        var response = await request.send();

        setState(() {
          status = response.statusCode == 200
              ? 'Uploaded successfully!'
              : 'Upload failed!';
        });
      }
    } else {
      // Mobile/Desktop
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://8671a5f8-6323-4a16-9356-a2dd53e7078c-00-2m041txxfet0b.pike.replit.dev/uploadfiletos3/'), // Android emulator? use 10.0.2.2
      );
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));

      var response = await request.send();

      setState(() {
        status = response.statusCode == 200
            ? 'Uploaded successfully!'
            : 'Upload failed!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload File to S3")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => S3ImagesScreen()),
                  );
                },
                child: const Text("Select & Upload File"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => S3PdfScreen()),
                  );
                },
                child: const Text("Pdf Files from S3"),
              ),
            ],
          ),
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
    final response = await http.get(Uri.parse(
        'https://8671a5f8-6323-4a16-9356-a2dd53e7078c-00-2m041txxfet0b.pike.replit.dev/receivefilesfroms3/'));

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

class S3PdfScreen extends StatefulWidget {
  @override
  _S3PdfScreenState createState() => _S3PdfScreenState();
}

class _S3PdfScreenState extends State<S3PdfScreen> {
  List<String> pdfUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPdfUrls();
  }

  Future<void> fetchPdfUrls() async {
    final response = await http.get(Uri.parse(
        'https://8671a5f8-6323-4a16-9356-a2dd53e7078c-00-2m041txxfet0b.pike.replit.dev/receivefilesfroms3/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> allFiles = List<String>.from(data['files']);
      List<String> onlyPdfs =
          allFiles.where((url) => url.toLowerCase().endsWith('.java')).toList();

      setState(() {
        pdfUrls = onlyPdfs;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to fetch files");
    }
  }

  Future<void> _viewPdfInApp(String url) async {
    final filename = url.split('/').last;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$filename';
    final file = File(filePath);

    // Download if not already present
    if (!await file.exists()) {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download PDF")),
        );
        return;
      }
    }

    // Open with external PDF viewer app
    final result = await OpenFilex.open(file.path);

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open PDF with external app")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Files from S3')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: pdfUrls.length,
              itemBuilder: (context, index) {
                final url = pdfUrls[index];
                final fileName = url.split('/').last;

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(fileName),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () => _viewPdfInApp(url),
                  ),
                );
              },
            ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String path;

  const PdfViewerScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View PDF')),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          print('PDF error: $error');
        },
        onRender: (_pages) {
          print('PDF rendered with $_pages pages');
        },
        onPageError: (page, error) {
          print('Error on page $page: $error');
        },
      ),
    );
  }
}
