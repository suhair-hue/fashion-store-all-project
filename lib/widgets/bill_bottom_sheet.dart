import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';

class BillBottomSheet extends StatefulWidget {
  final String pdfPath;
  final String orderId;

  const BillBottomSheet({
    super.key,
    required this.pdfPath,
    required this.orderId,
  });

  @override
  State<BillBottomSheet> createState() => _BillBottomSheetState();
}

class _BillBottomSheetState extends State<BillBottomSheet> {
  bool _isDownloading = false;

  /// Handles transferring the cached PDF receipt from internal app directories
  /// directly into the device's public Downloads folder.
  Future<void> _downloadPDF() async {
    setState(() => _isDownloading = true);

    try {
      // 1. Request storage permissions for Android compatibility
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Fallback check: try requesting manageExternalStorage or check if SDK >= 30
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted && !status.isGranted) {
            _showSnackBar("Storage permission is required to save the PDF.", Colors.redAccent);
            setState(() => _isDownloading = false);
            return;
          }
        }
      }

      // 2. Resolve standard Android Downloads path
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final String newPath = "${downloadDir.path}/Receipt_${widget.orderId}.pdf";
      final sourceFile = File(widget.pdfPath);

      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        _showSnackBar("Receipt saved to Downloads folder!", Colors.green);
      } else {
        _showSnackBar("Source receipt file not found.", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Failed to download PDF: $e", Colors.redAccent);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  /// Triggers standard system share sheets to transfer PDF via WhatsApp/Gmail
  Future<void> _sharePDF() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.pdfPath)],
          text: "Here is your Fashion Store purchase receipt (#${widget.orderId})!",
        );
      } else {
        _showSnackBar("Receipt file does not exist.", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Failed to share PDF: $e", Colors.redAccent);
    }
  }

  /// Launches the native OS print spooler interface
  Future<void> _printPDF() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        final pdfBytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (_) => pdfBytes,
          name: "Receipt_${widget.orderId}",
        );
      } else {
        _showSnackBar("Receipt file does not exist.", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Failed to print PDF: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── BOTTOM SHEET DRAGGABLE HANDLE ───────────────────────
          Center(
            child: Container(
              width: 45,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── TITLE ────────────────────────────────────────────────
          const Text(
            "Invoice & Receipt Options",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Choose how you want to manage your payment receipt",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ─── OPTION 1: DOWNLOAD ──────────────────────────────────
          _buildOptionCard(
            title: "Download Receipt",
            subtitle: "Save copy to your phone's Downloads folder",
            icon: Icons.file_download_outlined,
            iconColor: Colors.blue,
            isLoading: _isDownloading,
            onTap: _downloadPDF,
          ),
          const SizedBox(height: 12),

          // ─── OPTION 2: SHARE ──────────────────────────────────────
          _buildOptionCard(
            title: "Share Receipt",
            subtitle: "Send receipt via WhatsApp, Gmail, or Messages",
            icon: Icons.share_outlined,
            iconColor: Colors.purple,
            onTap: _sharePDF,
          ),
          const SizedBox(height: 12),

          // ─── OPTION 3: PRINT ──────────────────────────────────────
          _buildOptionCard(
            title: "Print Receipt",
            subtitle: "Print or export receipt as standard A4 document",
            icon: Icons.print_outlined,
            iconColor: Colors.green,
            onTap: _printPDF,
          ),
          const SizedBox(height: 24),

          // ─── CLOSE BUTTON ─────────────────────────────────────────
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
            ),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent)),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
