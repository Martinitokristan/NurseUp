import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../usage/presentation/providers/usage_provider.dart';
import '../providers/file_manager_provider.dart';

class FileUploadPage extends ConsumerStatefulWidget {
  const FileUploadPage({super.key});

  @override
  ConsumerState<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends ConsumerState<FileUploadPage> with WidgetsBindingObserver {
  static const int _maxFileBytes = 25 * 1024 * 1024;

  final _imagePicker = ImagePicker();
  final List<_SelectedUploadFile> _files = [];
  _UploadSource? _pendingPermissionRetry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retryPendingPickerAfterSettings();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(fileUploadControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload File')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              onTap: uploadState.isUploading ? null : _showUploadSourceSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: Column(
                  children: [
                    uploadState.isUploading ? const CircularProgressIndicator(color: AppColors.primary) : const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 64),
                    const SizedBox(height: 16),
                    Text(uploadState.message ?? 'Tap to upload files', style: AppTextStyles.h3, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      uploadState.errorMessage ?? 'Choose Files, Photos, or Camera.\nFiles opens the full Android picker for WPS Office, Google Drive, AI Gallery, and other apps.',
                      style: TextStyle(color: uploadState.errorMessage == null ? AppColors.textSecondary : AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _files.isEmpty
                  ? const Center(child: Text('No files selected yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)))
                  : ListView.separated(
                      itemCount: _files.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _SelectedFileTile(
                        file: _files[index],
                        onRemove: uploadState.isUploading ? null : () => setState(() => _files.removeAt(index)),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: uploadState.isUploading ? 'Submitting...' : 'Submit for Review',
              icon: Icons.auto_awesome_rounded,
              onPressed: uploadState.isUploading || _files.isEmpty ? null : _submitForReview,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUploadSourceSheet() async {
    final source = await showModalBottomSheet<_UploadSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose Upload Source', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _UploadSourceTile(
              icon: Icons.folder_open_rounded,
              color: Colors.blue,
              title: 'Files',
              subtitle: 'Open Android picker: WPS Office, Google Drive, AI Gallery, and all installed apps',
              onTap: () => Navigator.pop(ctx, _UploadSource.files),
            ),
            const SizedBox(height: 12),
            _UploadSourceTile(
              icon: Icons.photo_library_rounded,
              color: Colors.green,
              title: 'Photos',
              subtitle: 'Choose an image from your gallery',
              onTap: () => Navigator.pop(ctx, _UploadSource.photos),
            ),
            const SizedBox(height: 12),
            _UploadSourceTile(
              icon: Icons.camera_alt_rounded,
              color: Colors.deepOrange,
              title: 'Camera',
              subtitle: 'Take a new photo',
              onTap: () => Navigator.pop(ctx, _UploadSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    switch (source) {
      case _UploadSource.files:
        await _pickFiles();
      case _UploadSource.photos:
        await _pickPhoto();
      case _UploadSource.camera:
        await _capturePhoto();
    }
  }

  Future<FilePickerResult?> _pickStudyFilesFromProviders() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) return result;
    return FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await _pickStudyFilesFromProviders();
      if (result == null || result.files.isEmpty) {
        _showSnackBar('No file selected. Tap the menu icon to choose Downloads, Drive, WPS Office, or another app.');
        return;
      }
      final selected = <_SelectedUploadFile>[];
      for (final file in result.files) {
        final bytes = await _readPlatformFileBytes(file);
        if (bytes == null) {
          _showSnackBar('Unable to read ${file.name}. Please try a different file.');
          continue;
        }
        final item = _SelectedUploadFile.fromBytes(name: file.name, bytes: bytes, path: file.path);
        if (_validateFile(item)) selected.add(item);
      }
      if (selected.isNotEmpty) setState(() => _files.addAll(selected));
    } catch (error) {
      _showSnackBar('Unable to open file picker. Please try Downloads, Drive, WPS Office, or another file app.');
    }
  }

  Future<void> _pickPhoto() async {
    if (!await _ensureMediaPermission(_UploadSource.photos)) return;
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      await _addXFile(image);
    } catch (error) {
      _showSnackBar('Unable to open gallery: $error');
    }
  }

  Future<void> _capturePhoto() async {
    if (!await _ensureCameraPermission()) return;
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      await _addXFile(image);
    } catch (error) {
      _showSnackBar('Unable to open camera: $error');
    }
  }

  Future<void> _addXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final item = _SelectedUploadFile.fromBytes(name: p.basename(file.path), bytes: bytes, path: file.path, mimeType: file.mimeType);
    if (_validateFile(item)) setState(() => _files.add(item));
  }

  Future<Uint8List?> _readPlatformFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    final path = file.path;
    if (path == null) return null;
    return XFile(path).readAsBytes();
  }

  Future<bool> _ensureCameraPermission() async {
    final proceed = await _showPermissionRationale(
      title: 'Allow camera access?',
      message: 'Use your camera to take a photo of your notes and turn it into a reviewer.',
    );
    if (!proceed) return false;

    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted || cameraStatus.isLimited) return true;

    _pendingPermissionRetry = _UploadSource.camera;
    _showSnackBar('Camera permission denied. Enable it in app settings to continue.');
    await openAppSettings();
    return false;
  }

  Future<bool> _ensureMediaPermission(_UploadSource retrySource) async {
    final proceed = await _showPermissionRationale(
      title: 'Allow gallery access?',
      message: 'Choose a photo of your notes from your gallery and turn it into a reviewer.',
    );
    if (!proceed) return false;

    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted || storageStatus.isLimited) return true;

    _pendingPermissionRetry = retrySource;
    _showSnackBar('Gallery permission denied. Enable it in app settings to continue.');
    await openAppSettings();
    return false;
  }

  Future<bool> _showPermissionRationale({required String title, required String message}) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(112, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _retryPendingPickerAfterSettings() async {
    final retrySource = _pendingPermissionRetry;
    if (retrySource == null) return;

    switch (retrySource) {
      case _UploadSource.camera:
        final status = await Permission.camera.status;
        if (!status.isGranted && !status.isLimited) return;
        _pendingPermissionRetry = null;
        await _capturePhoto();
      case _UploadSource.photos:
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        if (!photosStatus.isGranted && !photosStatus.isLimited && !storageStatus.isGranted && !storageStatus.isLimited) return;
        _pendingPermissionRetry = null;
        await _pickPhoto();
      case _UploadSource.files:
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted && !storageStatus.isLimited) return;
        _pendingPermissionRetry = null;
        await _pickFiles();
    }
  }

  bool _validateFile(_SelectedUploadFile file) {
    if (file.sizeBytes > _maxFileBytes) {
      _showSnackBar('${file.name} is over 25MB. Please choose a smaller file.');
      return false;
    }
    return true;
  }

  Future<void> _submitForReview() async {
    final router = GoRouter.of(context);
    final usageController = ref.read(usageControllerProvider.notifier);
    final uploadController = ref.read(fileUploadControllerProvider.notifier);
    final plan = ref.read(activePlanProvider);

    final pickList = _files
        .map((f) => PickedUploadFile(name: f.name, bytes: f.bytes, extension: f.extension, mimeType: f.mimeType, path: f.path))
        .toList();

    final prepared = await uploadController.prepareSelectedFiles(pickList);
    if (!mounted) return;
    if (prepared.isEmpty) {
      _showSnackBar(ref.read(fileUploadControllerProvider).errorMessage ?? 'Could not read the selected file(s).');
      return;
    }

    final totalWords = prepared.fold<int>(0, (sum, item) => sum + item.wordCount);
    final usage = ref.read(usageProvider).valueOrNull;
    if (usage == null) {
      _showSnackBar('Usage status is loading. Please try again.');
      return;
    }

    final limit = usageController.checkUploadLimit(
      usage: usage,
      newWords: totalWords,
      weeklyWordLimit: plan.isPro ? plan.weeklyWordLimit : 1000,
      dailyWordLimit: plan.isPro ? 10000 : 500,
      dailyFileLimit: plan.isPro ? 999999 : 3,
      newFiles: prepared.length,
    );

    if (!limit.allowed) {
      uploadController.setError(limit.reason ?? 'Usage limit reached.');
      _showSnackBar(limit.reason ?? 'Usage limit reached.');
      return;
    }

    final uploaded = await uploadController.uploadPreparedFiles(prepared);
    if (!mounted) return;
    if (uploaded.isEmpty) {
      _showSnackBar(ref.read(fileUploadControllerProvider).errorMessage ?? 'Upload failed. Please try again.');
      return;
    }

    await usageController.recordUsage(totalWords);
    if (mounted) router.push('${AppRoutes.reviewerGenerating}?fileId=${uploaded.first.fileId}');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({required this.file, required this.onRemove});

  final _SelectedUploadFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _FilePreview(file: file),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${file.typeLabel} · ${file.sizeLabel}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded), tooltip: 'Remove'),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file});

  final _SelectedUploadFile file;

  @override
  Widget build(BuildContext context) {
    if (file.isImage) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(file.bytes, width: 56, height: 56, fit: BoxFit.cover));
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
      child: Icon(_iconFor(file.extension), color: AppColors.primary),
    );
  }

  IconData _iconFor(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _UploadSourceTile extends StatelessWidget {
  const _UploadSourceTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withAlpha(50))),
    );
  }
}

class _SelectedUploadFile {
  const _SelectedUploadFile({required this.name, required this.bytes, required this.extension, required this.mimeType, this.path});

  factory _SelectedUploadFile.fromBytes({required String name, required Uint8List bytes, String? path, String? mimeType}) {
    final resolvedMimeType = mimeType ?? lookupMimeType(path ?? name, headerBytes: bytes);
    final extension = p.extension(name).replaceFirst('.', '').toLowerCase();
    return _SelectedUploadFile(name: name, bytes: bytes, extension: extension.isEmpty ? 'file' : extension, mimeType: resolvedMimeType, path: path);
  }

  final String name;
  final Uint8List bytes;
  final String extension;
  final String? mimeType;
  final String? path;

  int get sizeBytes => bytes.length;
  bool get isImage => mimeType?.startsWith('image/') == true;
  String get typeLabel => isImage ? 'Image' : extension.toUpperCase();
  String get sizeLabel => sizeBytes >= 1024 * 1024 ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
}

enum _UploadSource { files, photos, camera }
