import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/product.dart';

class BillGenerator {
  /// Compiles a professional styled PDF payment receipt containing the official store logo,
  /// transaction timestamps, user details, and itemized LKR totals.
  static Future<File> generateReceipt({
    required String orderId,
    required String paymentId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String address,
    required String city,
    required List<CartItem> items,
    required double subtotal,
    required double deliveryCharge,
    required double total,
  }) async {
    final pdf = pw.Document();

    // 1. Load the store logo from app assets
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      print("Warning: Failed to load assets/images/logo.png for PDF: $e");
    }

    // 2. Format current date & time (DD/MM/YYYY HH:MM)
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // 3. Define styling palette
    final primaryColor = PdfColor.fromHex('#1A2F5A'); // Dark Navy
    final successColor = PdfColor.fromHex('#2E7D32'); // Green for PAID status

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── BRAND HEADER ──────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 65,
                      height: 65,
                      child: pw.Image(logoImage),
                    )
                  else
                    pw.Text(
                      "FASHION STORE",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Payment Receipt",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("Date: $formattedDate", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1.5, color: primaryColor),
              pw.SizedBox(height: 15),

              // ─── TRANSACTION DETAILS ─────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("CUSTOMER DETAILS", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerEmail, style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(customerPhone, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ORDER INFORMATION", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text("Order ID: $orderId", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Payment ID: $paymentId", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Payment Method: PayHere", style: const pw.TextStyle(fontSize: 9)),
                      pw.Row(
                        children: [
                          pw.Text("Status: ", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(
                            "PAID",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text("DELIVERY ADDRESS:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.SizedBox(height: 2),
              pw.Text("$address, $city", style: const pw.TextStyle(fontSize: 10)),

              pw.SizedBox(height: 25),

              // ─── ITEMIZED PRODUCTS TABLE ─────────────────────────────────
              pw.Text("ITEMIZED PRODUCTS", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 1.0, color: PdfColors.grey400),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),   // Product Name
                  1: pw.FlexColumnWidth(1),   // Quantity
                  2: pw.FlexColumnWidth(2),   // Unit Price
                  3: pw.FlexColumnWidth(2),   // Subtotal
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryColor),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Product Description", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Qty", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Unit Price", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Subtotal", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // Table Rows
                  ...items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            "${item.product.name} (${item.selectedSize} / ${item.selectedColor})",
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("LKR ${item.product.price.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("LKR ${item.totalPrice.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // ─── BILL SUMMARY ───────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Thank you for shopping with Fashion Store!",
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: successColor),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 9.5)),
                            pw.Text("LKR ${subtotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9.5)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Delivery Charge:", style: const pw.TextStyle(fontSize: 9.5)),
                            pw.Text("LKR ${deliveryCharge.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9.5)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Grand Total:",
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                            pw.Text(
                              "LKR ${total.toStringAsFixed(2)}",
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ─── FOOTER SECTION ──────────────────────────────────────────
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  "Fashion Store | 2026 | fashionstore.lk",
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF file in app documents directory
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/Receipt_$orderId.pdf");
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}
