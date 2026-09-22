import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_permissions_service.dart';

/// Result container for picked images and documents
class PickedMediaFile {
  final String path;
  final String name;
  final Uint8List? bytes;
  final int sizeInBytes;
  final bool isFromCamera;

  const PickedMediaFile({
    required this.path,
    required this.name,
    this.bytes,
    required this.sizeInBytes,
    required this.isFromCamera,
  });

  File get file => File(path);
}

/// Robust Media & Document Selection Service with real Camera/Gallery interaction
class MediaDocumentPickerService {
  static final MediaDocumentPickerService instance = MediaDocumentPickerService._internal();
  MediaDocumentPickerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Prompts user with Camera vs Gallery selection sheet, handles permissions, and captures real media
  Future<PickedMediaFile?> pickImageWithSourceChoice(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool preferCamera = false,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 32),
                            SizedBox(height: 8),
                            Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                            SizedBox(height: 2),
                            Text('Use Camera', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_rounded, color: Color(0xFF0F172A), size: 32),
                            SizedBox(height: 8),
                            Text('Choose Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text('Upload from Photos', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    if (!context.mounted) return null;

    // 1. Enforce App Permissions Check
    if (source == ImageSource.camera) {
      final hasPermission = await AppPermissionsService.instance.requestCameraPermission(
        context,
        title: 'Camera Access for $title',
        rationale: 'ServiceHub requires camera access to capture a live, authentic photo for $title.',
      );
      if (!hasPermission) return null;
    } else {
      final hasPermission = await AppPermissionsService.instance.requestMediaPermission(
        context,
        title: 'Photos Access for $title',
        rationale: 'ServiceHub requires photo storage access to upload your $title document.',
      );
      if (!hasPermission) return null;
    }

    // 2. Open Real Image Picker
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        return PickedMediaFile(
          path: picked.path,
          name: picked.name,
          bytes: bytes,
          sizeInBytes: bytes.length,
          isFromCamera: source == ImageSource.camera,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? "camera" : "gallery"}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }

    return null;
  }

  /// Uploads image or document file to Supabase Storage bucket using binary bytes.
  /// Falls back safely to storing local file path if offline or bucket is not accessible.
  Future<String> uploadImageToSupabase({
    required File file,
    required String bucket,
    required String path,
    String? contentType,
  }) async {
    try {
      if (!kIsWeb && await file.exists()) {
        final client = Supabase.instance.client;
        final bytes = await file.readAsBytes();
        await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? _inferContentType(path),
            upsert: true,
          ),
        );
        return client.storage.from(bucket).getPublicUrl(path);
      }
      return file.path;
    } catch (e) {
      debugPrint('[MediaDocumentPickerService] Supabase upload failed, fallback to local path: $e');
      return file.path;
    }
  }

  /// Uploads picked media container to Supabase Storage bucket using binary bytes.
  /// Falls back safely to storing local file path if offline or bucket is not accessible.
  Future<String> uploadPickedMediaToSupabase({
    required PickedMediaFile media,
    required String bucket,
    required String path,
    String? contentType,
  }) async {
    try {
      final client = Supabase.instance.client;
      final Uint8List uploadBytes = media.bytes ?? (await File(media.path).readAsBytes());
      await client.storage.from(bucket).uploadBinary(
        path,
        uploadBytes,
        fileOptions: FileOptions(
          contentType: contentType ?? _inferContentType(path),
          upsert: true,
        ),
      );
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('[MediaDocumentPickerService] Supabase upload failed, fallback to local path: $e');
      return media.path;
    }
  }

  String _inferContentType(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
