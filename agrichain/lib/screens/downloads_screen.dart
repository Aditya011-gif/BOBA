import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_app_bar.dart';
import '../services/download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with TickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Download status tracking
  final Map<String, DownloadStatus> _downloadStatuses = {};
  final Map<String, double> _downloadProgress = {};

  // Document information
  final List<DocumentInfo> _documents = [
    DocumentInfo(
      id: 'crop_sale_agreement',
      title: 'Crop Sale Agreement',
      description: 'Legal contract template for crop sales',
      fileName: 'AgriChain_Crop_Sale_Agreement.pdf',
      filePath: r'c:\geeta uni\geeta hack\AgriChain_Crop_Sale_Agreement.pdf',
      icon: Icons.agriculture,
      color: AppTheme.primaryGreen,
      estimatedSize: '2.3 MB',
    ),
    DocumentInfo(
      id: 'loan_agreement',
      title: 'Loan Agreement',
      description: 'Legal contract template for agricultural loans',
      fileName: 'AgriChain_Loan_Agreement.pdf',
      filePath: r'c:\geeta uni\geeta hack\AgriChain_Loan_Agreement.pdf',
      icon: Icons.account_balance,
      color: AppTheme.secondaryColor,
      estimatedSize: '1.8 MB',
    ),
    DocumentInfo(
      id: 'smart_contract',
      title: 'Smart Contract',
      description: 'Blockchain smart contract documentation',
      fileName: 'AgriChain_Smart_Contract.pdf',
      filePath: '', // Placeholder - will be generated
      icon: Icons.code,
      color: Colors.purple,
      estimatedSize: '0.5 MB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDownloadStatuses();
    _checkFileAvailability();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  void _initializeDownloadStatuses() {
    for (final doc in _documents) {
      _downloadStatuses[doc.id] = DownloadStatus.ready;
      _downloadProgress[doc.id] = 0.0;
    }
  }

  Future<void> _checkFileAvailability() async {
    // Skip file availability checks on web platform to avoid namespace errors
    if (kIsWeb) {
      return;
    }
    
    for (final doc in _documents) {
      if (doc.filePath.isNotEmpty) {
        try {
          final file = File(doc.filePath);
          if (await file.exists()) {
            final size = await file.length();
            setState(() {
              doc.actualSize = _formatFileSize(size);
            });
          }
        } catch (e) {
          // Silently handle file system errors
          if (kDebugMode) {
            print('File availability check failed for ${doc.fileName}: $e');
          }
        }
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: const EnhancedAppBar(
        title: 'Downloads',
        subtitle: 'Legal documents and contracts',
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildDocumentsSection(),
                const SizedBox(height: 24),
                _buildSecurityInfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.download,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Downloads',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access legal contracts and smart contract documentation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGreen,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _documents.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDocumentCard(_documents[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(DocumentInfo doc, int index) {
    final status = _downloadStatuses[doc.id] ?? DownloadStatus.ready;
    final progress = _downloadProgress[doc.id] ?? 0.0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 100,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: doc.color.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Document icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: doc.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        doc.icon,
                        color: doc.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Document details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${doc.fileName} • ${doc.actualSize ?? doc.estimatedSize}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Download button
                    Flexible(
                      flex: 1,
                      child: _buildDownloadButton(doc, status, progress),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadButton(DocumentInfo doc, DownloadStatus status, double progress) {
    switch (status) {
      case DownloadStatus.ready:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadDocument(doc),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: doc.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
        );
      case DownloadStatus.downloading:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Downloading...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case DownloadStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Downloaded',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case DownloadStatus.error:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadDocument(doc),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
        );
    }
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Download failed. Please check your connection and try again.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Security Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSecurityItem('All downloads are verified for integrity'),
          _buildSecurityItem('Files are scanned for security threats'),
          _buildSecurityItem('CSRF protection enabled for all requests'),
          _buildSecurityItem('Path validation prevents unauthorized access'),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocument(DocumentInfo doc) async {
    try {
      setState(() {
        _downloadStatuses[doc.id] = DownloadStatus.downloading;
        _downloadProgress[doc.id] = 0.0;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      final result = await _downloadService.downloadDocument(
        doc,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[doc.id] = progress;
          });
        },
      );

      if (result.success) {
        setState(() {
          _downloadStatuses[doc.id] = DownloadStatus.completed;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${doc.title} downloaded successfully'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }

        // Reset status after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _downloadStatuses[doc.id] = DownloadStatus.ready;
            });
          }
        });
      } else {
        setState(() {
          _downloadStatuses[doc.id] = DownloadStatus.error;
        });

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result.errorMessage ?? 'Download failed'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _downloadStatuses[doc.id] = DownloadStatus.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Enums and Data Classes
enum DownloadStatus { ready, downloading, completed, error }

class DocumentInfo {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final IconData icon;
  final Color color;
  final String estimatedSize;
  String? actualSize;

  DocumentInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.icon,
    required this.color,
    required this.estimatedSize,
    this.actualSize,
  });
}