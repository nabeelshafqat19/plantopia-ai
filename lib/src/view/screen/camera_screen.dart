import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _caption;
  bool _isLoading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Register the iframe view with improved configuration
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'flask-html',
        (int viewId) => html.IFrameElement()
          ..src = 'https://32a8-74-235-137-163.ngrok-free.app'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100vh'
          ..style.margin = '0'
          ..style.padding = '0'
          ..style.position = 'fixed'
          ..style.top = '0'
          ..style.left = '0'
          ..style.right = '0'
          ..style.bottom = '0',
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _caption = null;
      });

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final blob = html.Blob([bytes]);
        _imageUrl = html.Url.createObjectUrlFromBlob(blob);
      }
    }
  }

  Future<void> _getCaption() async {
    if (_selectedImage == null) {
      Get.snackbar('Error', 'Please select an image first',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://32a8-74-235-137-163.ngrok-free.app'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _caption = result['captionResult']?['text'] ?? 'No caption found';
        });
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get caption: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (_imageUrl != null) {
      html.Url.revokeObjectUrl(_imageUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF184A2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed('/home'),
        ),
        title: const Text(
          'Image Caption AI',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: kIsWeb
          ? const HtmlElementView(viewType: 'flask-html')
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF184A2C),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Pick Image', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedImage != null) ...[
                        const Text('Image Preview', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        kIsWeb
                            ? Image.network(
                                _imageUrl!,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _getCaption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF184A2C),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                            : const Text('Get Caption', style: TextStyle(color: Colors.white)),
                      ),
                      if (_caption != null) ...[
                        const SizedBox(height: 20),
                        Text(_caption!, style: const TextStyle(color: Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
