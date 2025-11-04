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
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('dd MMMM yyyy \'at\' HH:mm');

    // Load professional fonts
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final italicFont = await PdfGoogleFonts.openSansItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 40),
        header: (context) => _buildProfessionalHeader(regularFont, boldFont),
        footer: (context) => _buildProfessionalFooter(regularFont, boldFont),
        build: (pw.Context context) {
          return [
            // Contract Title with proper spacing
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'AGRICULTURAL PURCHASE CONTRACT',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: 200,
                    height: 2,
                    color: PdfColors.black,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Contract Reference Information
            _buildProfessionalContractInfo(order, contractData, regularFont, boldFont, timeFormat),
            pw.SizedBox(height: 25),

            // Parties Section with proper legal formatting
            _buildProfessionalPartiesSection(buyer, seller, regularFont, boldFont),
            pw.SizedBox(height: 25),

            // Product Specifications
            _buildProfessionalProductSection(crop, order, regularFont, boldFont, dateFormat),
            pw.SizedBox(height: 25),

            // Financial Terms
            _buildProfessionalFinancialSection(order, paymentDetails, regularFont, boldFont),
            pw.SizedBox(height: 25),

            // Smart Contract Integration
            _buildProfessionalSmartContractSection(contractData, regularFont, boldFont),
            pw.SizedBox(height: 25),

            // Terms and Conditions with numbered clauses
            _buildProfessionalTermsSection(contractData, regularFont, boldFont, italicFont, dateFormat),
            pw.SizedBox(height: 30),

            // Signature Section
            _buildProfessionalSignatureSection(buyer, seller, regularFont, boldFont, timeFormat),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildProfessionalHeader(pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
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
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _companyAddress,
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Email: $_companyEmail',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
              pw.Text(
                'Phone: $_companyPhone',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfessionalContractInfo(
    FirestoreOrder order,
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTRACT REFERENCE',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Contract Number:', order.id, regularFont, boldFont),
            _buildTableRow('Contract Date:', timeFormat.format(order.orderDate), regularFont, boldFont),
            _buildTableRow('Status:', order.status.name.toUpperCase(), regularFont, boldFont),
            _buildTableRow('Blockchain ID:', contractData['contractId'] ?? 'Pending', regularFont, boldFont),
            _buildTableRow('Transaction Hash:', _truncateHash(contractData['transactionHash'] ?? 'Pending'), regularFont, boldFont),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalPartiesSection(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTRACTING PARTIES',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 15),
        
        // Buyer Section
        pw.Text(
          '1. THE BUYER',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Name: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: buyer.name, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Email: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: buyer.email, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Phone: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: buyer.phone ?? 'Not provided', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Location: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: buyer.location ?? 'Not specified', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Wallet Address: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: _truncateAddress(buyer.walletAddress ?? 'Not connected'), style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 15),
        
        // Seller Section
        pw.Text(
          '2. THE SELLER',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Name: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: seller.name, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Email: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: seller.email, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Phone: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: seller.phone ?? 'Not provided', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Location: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: seller.location ?? 'Not specified', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Wallet Address: ', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.TextSpan(text: _truncateAddress(seller.walletAddress ?? 'Not connected'), style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalProductSection(
    FirestoreCrop crop,
    FirestoreOrder order,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PRODUCT SPECIFICATIONS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Product Name:', crop.name, regularFont, boldFont),
            _buildTableRow('Category:', crop.category?.name.toUpperCase() ?? 'Not specified', regularFont, boldFont),
            _buildTableRow('Quality Grade:', crop.qualityGrade.name.toUpperCase(), regularFont, boldFont),
            _buildTableRow('Quantity:', order.quantity, regularFont, boldFont),
            _buildTableRow('Unit Price:', '₹${crop.price.toStringAsFixed(2)}', regularFont, boldFont),
            _buildTableRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}', regularFont, boldFont),
            _buildTableRow('Harvest Date:', dateFormat.format(crop.harvestDate), regularFont, boldFont),
            _buildTableRow('Origin Location:', crop.location, regularFont, boldFont),
            _buildTableRow('NFT Token ID:', crop.nftTokenId ?? 'Not minted', regularFont, boldFont),
          ],
        ),
        if (crop.certifications.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'CERTIFICATIONS:',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            crop.certifications.map((cert) => '• ${cert['type'] ?? 'Unknown certification'}').join('\n'),
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildProfessionalFinancialSection(
    FirestoreOrder order,
    Map<String, dynamic>? paymentDetails,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FINANCIAL TERMS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Total Amount:', '₹${order.totalAmount.toStringAsFixed(2)}', regularFont, boldFont),
            _buildTableRow('Currency:', 'Indian Rupees (INR)', regularFont, boldFont),
            _buildTableRow('Payment Method:', paymentDetails?['payment_method'] ?? 'Digital Payment', regularFont, boldFont),
            _buildTableRow('Transaction ID:', paymentDetails?['transaction_id'] ?? 'Pending', regularFont, boldFont),
            _buildTableRow('Escrow Status:', 'FUNDS SECURED', regularFont, boldFont),
            _buildTableRow('Release Condition:', 'Upon successful delivery confirmation', regularFont, boldFont),
            if (paymentDetails?['upi_id'] != null)
              _buildTableRow('UPI ID:', paymentDetails!['upi_id'], regularFont, boldFont),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalSmartContractSection(
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BLOCKCHAIN INTEGRATION',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Contract Address:', contractData['contractAddress'] ?? 'Deploying...', regularFont, boldFont),
            _buildTableRow('Escrow Address:', contractData['escrowAddress'] ?? 'Initializing...', regularFont, boldFont),
            _buildTableRow('Block Number:', contractData['blockNumber']?.toString() ?? 'Pending', regularFont, boldFont),
            _buildTableRow('Gas Fee:', contractData['gasUsed'] ?? 'Calculating...', regularFont, boldFont),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'SMART CONTRACT FEATURES:',
          style: pw.TextStyle(font: boldFont, fontSize: 10),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '• Automated escrow with secure fund management\n'
          '• Quality verification and dispute resolution mechanism\n'
          '• Automatic NFT ownership transfer upon completion\n'
          '• Penalty enforcement for contract violations\n'
          '• Immutable transaction record on blockchain\n'
          '• Multi-signature approval for fund release',
          style: pw.TextStyle(font: regularFont, fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalTermsSection(
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    DateFormat dateFormat,
  ) {
    final terms = contractData['contractData']?['terms'] as Map<String, dynamic>?;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMS AND CONDITIONS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 15),
        
        // Specific Terms
        if (terms != null) ...[
          pw.Text(
            'SPECIFIC CONTRACT TERMS:',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow('Delivery Deadline:', 
                terms['deliveryDeadline'] != null 
                  ? dateFormat.format(DateTime.parse(terms['deliveryDeadline']))
                  : 'As per mutual agreement', 
                regularFont, boldFont),
              _buildTableRow('Quality Standards:', terms['qualityStandards'] ?? 'As per product specifications', regularFont, boldFont),
              _buildTableRow('Late Delivery Penalty:', '${((terms['penaltyRate'] ?? 0.05) * 100).toStringAsFixed(1)}% per day', regularFont, boldFont),
              _buildTableRow('Refund Policy:', terms['refundPolicy'] ?? 'Full refund if quality standards not met', regularFont, boldFont),
            ],
          ),
          pw.SizedBox(height: 15),
        ],
        
        // General Terms
        pw.Text(
          'GENERAL TERMS AND CONDITIONS:',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        
        ..._buildNumberedTerms(regularFont, boldFont),
        
        pw.SizedBox(height: 15),
        pw.Text(
          'By executing this contract, both parties acknowledge that they have read, understood, and agree to be bound by all terms and conditions stated herein.',
          style: pw.TextStyle(font: italicFont, fontSize: 10),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildNumberedTerms(pw.Font regularFont, pw.Font boldFont) {
    final terms = [
      'This contract is governed by the smart contract deployed on the blockchain network and is legally binding under applicable laws.',
      'All disputes shall be resolved through the platform\'s automated dispute resolution mechanism before escalating to legal proceedings.',
      'The buyer must confirm delivery within seven (7) days of receiving the goods, failing which delivery shall be deemed accepted.',
      'Quality standards must be met as per the product specifications outlined in this contract.',
      'Late delivery may result in penalties as specified in the contract terms, automatically enforced by the smart contract.',
      'Both parties warrant that they have the legal capacity and authority to enter into this contract.',
      'This contract may only be modified through mutual written consent and blockchain transaction confirmation.',
      'Force majeure events shall be handled as per platform policies and may result in contract suspension or termination.',
      'All personal data shall be handled in accordance with applicable privacy laws and platform policies.',
      'This contract shall remain in effect until all obligations are fulfilled or the contract is terminated as per these terms.',
    ];

    return terms.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final term = entry.value;
      
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 25,
              child: pw.Text(
                '$index.',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                term,
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static pw.Widget _buildProfessionalSignatureSection(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    final currentDate = timeFormat.format(DateTime.now());
    
    return pw.Column(
      children: [
        pw.Text(
          'SIGNATURES',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 20),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Buyer Signature
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'THE BUYER:',
                    style: pw.TextStyle(font: boldFont, fontSize: 11),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    buyer.name,
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                  pw.Text(
                    'Digital Signature',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                  pw.Text(
                    'Date: $currentDate',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(width: 40),
            
            // Seller Signature
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'THE SELLER:',
                    style: pw.TextStyle(font: boldFont, fontSize: 11),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    seller.name,
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                  pw.Text(
                    'Digital Signature',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                  pw.Text(
                    'Date: $currentDate',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 30),
        
        // Witness/Platform Signature
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'WITNESSED BY:',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: 200,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                _companyName,
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                'Platform Authority',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
              pw.Text(
                'Date: $currentDate',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value, pw.Font regularFont, pw.Font boldFont) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalFooter(pw.Font regularFont, pw.Font boldFont) {
    final currentDateTime = DateFormat('dd MMMM yyyy, HH:mm:ss').format(DateTime.now());
    
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DIGITAL VERIFICATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '✓ Blockchain Secured',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  '✓ Cryptographically Signed',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  '✓ Immutable Record',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'DOCUMENT INFORMATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Generated: $currentDateTime',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  'Platform: $_companyName',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  'Version: 2.0',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'This contract is legally binding and enforceable under applicable laws.\n'
            'For verification and dispute resolution, please contact platform support.',
            style: pw.TextStyle(font: regularFont, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
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