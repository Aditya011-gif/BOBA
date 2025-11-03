import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/firestore_models.dart';

class ContractPdfService {
  static const String _companyName = 'AgriChain Marketplace';
  static const String _companyAddress = 'Blockchain Agriculture Platform\nDecentralized Marketplace';
  static const String _companyEmail = 'contracts@agrichain.com';
  static const String _companyPhone = '+91-XXXX-XXXXXX';

  /// Generate a purchase contract PDF
  static Future<Uint8List> generatePurchaseContract({
    required FirestoreOrder order,
    required FirestoreCrop crop,
    required FirestoreUser buyer,
    required FirestoreUser seller,
    required Map<String, dynamic> contractData,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Load Google Fonts with Unicode support
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(font, boldFont),
            pw.SizedBox(height: 30),

            // Contract Title
            pw.Center(
              child: pw.Text(
                'AGRICULTURAL PURCHASE CONTRACT',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 18,
                  color: PdfColors.green800,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Contract Details
            _buildContractInfo(order, contractData, font, boldFont, timeFormat),
            pw.SizedBox(height: 20),

            // Parties Information
            _buildPartiesInfo(buyer, seller, font, boldFont),
            pw.SizedBox(height: 20),

            // Product Details
            _buildProductDetails(crop, order, font, boldFont, dateFormat),
            pw.SizedBox(height: 20),

            // Financial Details
            _buildFinancialDetails(order, paymentDetails, font, boldFont),
            pw.SizedBox(height: 20),

            // Smart Contract Details
            _buildSmartContractDetails(contractData, font, boldFont),
            pw.SizedBox(height: 20),

            // Terms and Conditions
            _buildTermsAndConditions(contractData, font, boldFont, dateFormat),
            pw.SizedBox(height: 30),

            // Signatures
            _buildSignatureSection(buyer, seller, font, boldFont, timeFormat),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green800, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _companyAddress,
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Email: $_companyEmail',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Phone: $_companyPhone',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildContractInfo(
    FirestoreOrder order,
    Map<String, dynamic> contractData,
    pw.Font font,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONTRACT INFORMATION',
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Contract ID:', order.id, font, boldFont),
                  _buildInfoRow('Order ID:', order.id, font, boldFont),
                  _buildInfoRow('Status:', order.status.name.toUpperCase(), font, boldFont),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Contract Date:', timeFormat.format(order.orderDate), font, boldFont),
                  _buildInfoRow('Blockchain ID:', contractData['contractId'] ?? 'N/A', font, boldFont),
                  _buildInfoRow('Transaction Hash:', _truncateHash(contractData['transactionHash'] ?? 'N/A'), font, boldFont),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPartiesInfo(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BUYER INFORMATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 8),
                _buildInfoRow('Name:', buyer.name, font, boldFont),
                _buildInfoRow('Email:', buyer.email, font, boldFont),
                _buildInfoRow('Phone:', buyer.phone ?? 'N/A', font, boldFont),
                _buildInfoRow('Location:', buyer.location ?? 'N/A', font, boldFont),
                _buildInfoRow('Wallet:', _truncateAddress(buyer.walletAddress ?? 'N/A'), font, boldFont),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SELLER INFORMATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.orange800),
                ),
                pw.SizedBox(height: 8),
                _buildInfoRow('Name:', seller.name, font, boldFont),
                _buildInfoRow('Email:', seller.email, font, boldFont),
                _buildInfoRow('Phone:', seller.phone ?? 'N/A', font, boldFont),
                _buildInfoRow('Location:', seller.location ?? 'N/A', font, boldFont),
                _buildInfoRow('Wallet:', _truncateAddress(seller.walletAddress ?? 'N/A'), font, boldFont),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProductDetails(
    FirestoreCrop crop,
    FirestoreOrder order,
    pw.Font font,
    pw.Font boldFont,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PRODUCT DETAILS',
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Product Name:', crop.name, font, boldFont),
                  _buildInfoRow('Category:', crop.category?.name.toUpperCase() ?? 'N/A', font, boldFont),
                  _buildInfoRow('Quality Grade:', crop.qualityGrade.name.toUpperCase(), font, boldFont),
                  _buildInfoRow('Quantity:', order.quantity, font, boldFont),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Unit Price:', '₹${crop.price.toStringAsFixed(2)}', font, boldFont),
                  _buildInfoRow('Harvest Date:', dateFormat.format(crop.harvestDate), font, boldFont),
                  _buildInfoRow('Location:', crop.location, font, boldFont),
                  _buildInfoRow('NFT Token:', crop.nftTokenId ?? 'N/A', font, boldFont),
                ],
              ),
            ],
          ),
          if (crop.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Certifications:',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              crop.certifications.map((cert) => cert['type'] ?? 'Unknown').join(', '),
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialDetails(
    FirestoreOrder order,
    Map<String, dynamic>? paymentDetails,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FINANCIAL DETAILS',
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.purple800),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}', font, boldFont),
                  _buildInfoRow('Currency:', 'INR', font, boldFont),
                  if (paymentDetails != null) ...[
                    _buildInfoRow('Payment Method:', paymentDetails['payment_method'] ?? 'N/A', font, boldFont),
                    _buildInfoRow('Transaction ID:', paymentDetails['transaction_id'] ?? 'N/A', font, boldFont),
                  ],
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Escrow Status:', 'LOCKED', font, boldFont),
                  _buildInfoRow('Release Condition:', 'On Delivery Confirmation', font, boldFont),
                  if (paymentDetails?['upi_id'] != null)
                    _buildInfoRow('UPI ID:', paymentDetails!['upi_id'], font, boldFont),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSmartContractDetails(
    Map<String, dynamic> contractData,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SMART CONTRACT DETAILS',
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Contract Address:', contractData['contractAddress'] ?? 'N/A', font, boldFont),
          _buildInfoRow('Escrow Address:', contractData['escrowAddress'] ?? 'N/A', font, boldFont),
          _buildInfoRow('Block Number:', contractData['blockNumber']?.toString() ?? 'N/A', font, boldFont),
          _buildInfoRow('Gas Used:', contractData['gasUsed'] ?? 'N/A', font, boldFont),
          pw.SizedBox(height: 8),
          pw.Text(
            'Smart Contract Features:',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Automated escrow with funds locked until delivery\n'
            '• Quality verification and dispute resolution\n'
            '• Automatic NFT ownership transfer on completion\n'
            '• Penalty mechanism for late delivery\n'
            '• Immutable transaction record on blockchain',
            style: pw.TextStyle(font: font, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsAndConditions(
    Map<String, dynamic> contractData,
    pw.Font font,
    pw.Font boldFont,
    DateFormat dateFormat,
  ) {
    final terms = contractData['contractData']?['terms'] as Map<String, dynamic>?;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TERMS AND CONDITIONS',
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.red800),
          ),
          pw.SizedBox(height: 8),
          if (terms != null) ...[
            _buildInfoRow('Delivery Deadline:', 
              terms['deliveryDeadline'] != null 
                ? dateFormat.format(DateTime.parse(terms['deliveryDeadline']))
                : 'N/A', 
              font, boldFont),
            _buildInfoRow('Quality Standards:', terms['qualityStandards'] ?? 'Standard quality', font, boldFont),
            _buildInfoRow('Penalty Rate:', '${((terms['penaltyRate'] ?? 0.0) * 100).toStringAsFixed(1)}% for late delivery', font, boldFont),
            _buildInfoRow('Refund Policy:', terms['refundPolicy'] ?? 'As per platform policy', font, boldFont),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'General Terms:',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. This contract is governed by the smart contract deployed on the blockchain.\n'
            '2. All disputes will be resolved through the platform\'s dispute resolution mechanism.\n'
            '3. The buyer must confirm delivery within 7 days of receiving the goods.\n'
            '4. Quality standards must be met as per the product specifications.\n'
            '5. Late delivery may result in penalties as specified in the contract terms.\n'
            '6. This contract is legally binding and enforceable under applicable laws.',
            style: pw.TextStyle(font: font, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font font,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BUYER SIGNATURE',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              width: 200,
              height: 1,
              color: PdfColors.grey600,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              buyer.name,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.Text(
              'Date: ${timeFormat.format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SELLER SIGNATURE',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              width: 200,
              height: 1,
              color: PdfColors.grey600,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              seller.name,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.Text(
              'Date: ${timeFormat.format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: pw.Text(
          'This contract is digitally generated and cryptographically secured on the blockchain.\n'
          'For verification, use the contract ID and transaction hash provided above.\n'
          'Generated on ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  static String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  static String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  /// Save PDF to device storage and return the file path
  static Future<String> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final contractsDir = Directory('${directory.path}/contracts');
    
    if (!await contractsDir.exists()) {
      await contractsDir.create(recursive: true);
    }
    
    final file = File('${contractsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    
    return file.path;
  }

  /// Share or print the PDF
  static Future<void> shareOrPrintPdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  /// Generate a unique filename for the contract
  static String generateContractFileName(String orderId) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'AgriChain_Contract_${orderId}_$timestamp.pdf';
  }
}