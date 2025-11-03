import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
import '../screens/downloads_screen.dart';

class DownloadService {
  static const String _csrfToken = 'agrichain_download_token_2024';
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB limit
  
  // Allowed file extensions for security
  static const List<String> _allowedExtensions = ['.pdf', '.doc', '.docx', '.txt'];
  
  // Expected file hashes for integrity verification (in production, these would be stored securely)
  static const Map<String, String> _expectedHashes = {
    'AgriChain_Crop_Sale_Agreement.pdf': '', // Would be populated with actual hash
    'AgriChain_Loan_Agreement.pdf': '', // Would be populated with actual hash
  };

  Future<DownloadResult> downloadDocument(
    DocumentInfo document, {
    required Function(double) onProgress,
  }) async {
    try {
      // 1. Validate CSRF token
      if (!_validateCSRFToken()) {
        return DownloadResult(
          success: false,
          errorMessage: 'Security validation failed',
        );
      }

      // 2. Validate file path to prevent directory traversal
      if (!_validateFilePath(document.filePath)) {
        return DownloadResult(
          success: false,
          errorMessage: 'Invalid file path',
        );
      }

      // 3. Check file extension
      if (!_validateFileExtension(document.fileName)) {
        return DownloadResult(
          success: false,
          errorMessage: 'File type not allowed',
        );
      }

      // 4. Check permissions
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        return DownloadResult(
          success: false,
          errorMessage: 'Storage permission denied',
        );
      }

      // 5. Handle different document types
      if (document.id == 'smart_contract') {
        return await _downloadSmartContractDoc(document, onProgress);
      } else {
        return await _downloadPDFFile(document, onProgress);
      }
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download failed: ${e.toString()}',
      );
    }
  }

  bool _validateCSRFToken() {
    // In a real application, this would validate against a server-generated token
    // For this demo, we're using a static token
    return _csrfToken.isNotEmpty;
  }

  bool _validateFilePath(String filePath) {
    if (filePath.isEmpty) return false;
    
    // Prevent directory traversal attacks
    if (filePath.contains('..') || 
        filePath.contains('~') || 
        filePath.startsWith('/etc') ||
        filePath.startsWith('/root') ||
        filePath.contains('\\..\\') ||
        filePath.contains('/../')) {
      return false;
    }

    // Ensure path is within allowed directories
    final allowedPaths = [
      r'c:\geeta uni\geeta hack',
      // Add other allowed paths as needed
    ];

    return allowedPaths.any((allowedPath) => 
        filePath.toLowerCase().startsWith(allowedPath.toLowerCase()));
  }

  bool _validateFileExtension(String fileName) {
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return _allowedExtensions.contains(extension);
  }

  Future<bool> _checkStoragePermission() async {
    if (kIsWeb) {
      // Web doesn't need storage permissions
      return true;
    }

    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }

    // iOS and other platforms
    return true;
  }

  Future<DownloadResult> _downloadPDFFile(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      // Simulate download progress for better UX
      await _simulateDownloadProgress(onProgress);

      // Generate sample PDF content for demo purposes
      final pdfContent = _generateSamplePDFContent(document);
      
      // Get download directory
      final downloadDir = await _getDownloadDirectory();
      final targetFile = File('${downloadDir.path}/${document.fileName}');

      // Write generated content to file
      await targetFile.writeAsBytes(pdfContent);

      // Verify file integrity (simulate hash check)
      final actualHash = _calculateFileHash(pdfContent);
      if (_expectedHashes.containsKey(document.fileName) && _expectedHashes[document.fileName]!.isNotEmpty) {
        if (actualHash != _expectedHashes[document.fileName]) {
          // For demo purposes, we'll allow this to pass
          if (kDebugMode) {
            print('Warning: File integrity check skipped for demo');
          }
        }
      }

      return DownloadResult(
        success: true,
        filePath: targetFile.path,
        fileSize: pdfContent.length,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Download error: ${e.toString()}',
      );
    }
  }

  Uint8List _generateSamplePDFContent(DocumentInfo document) {
    // Generate sample PDF-like content for demo
    final content = '''
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
72 720 Td
(${document.fileName}) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000206 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
299
%%EOF
''';
    return Uint8List.fromList(utf8.encode(content));
  }

  String _calculateFileHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<DownloadResult> _downloadSmartContractDoc(
    DocumentInfo document,
    Function(double) onProgress,
  ) async {
    try {
      // Generate smart contract documentation
      final contractContent = await _generateSmartContractDoc();
      
      // Simulate download progress
      await _simulateDownloadProgress(onProgress);

      // Get download directory
      final downloadDir = await _getDownloadDirectory();
      final targetFile = File('${downloadDir.path}/${document.fileName}');

      // Write content to file
      await targetFile.writeAsString(contractContent);

      final fileSize = await targetFile.length();

      return DownloadResult(
        success: true,
        filePath: targetFile.path,
        fileSize: fileSize,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        errorMessage: 'Smart contract generation failed: ${e.toString()}',
      );
    }
  }

  Future<String> _generateSmartContractDoc() async {
    // Generate a comprehensive smart contract documentation
    return '''
# AgriChain Smart Contract Documentation

## Overview
This document provides comprehensive information about the AgriChain smart contracts deployed on the blockchain network.

## Contract Details

### 1. Crop NFT Contract
- **Address**: 0x1234567890abcdef1234567890abcdef12345678
- **Network**: Ethereum Mainnet
- **Purpose**: Tokenization of crop ownership and authenticity

### 2. Loan Management Contract
- **Address**: 0xabcdef1234567890abcdef1234567890abcdef12
- **Network**: Ethereum Mainnet
- **Purpose**: Decentralized agricultural loan management

### 3. Marketplace Contract
- **Address**: 0x567890abcdef1234567890abcdef1234567890ab
- **Network**: Ethereum Mainnet
- **Purpose**: Peer-to-peer crop trading platform

## Key Features

### Security Measures
- Multi-signature wallet integration
- Time-locked transactions for large amounts
- Automated escrow for buyer protection
- Oracle integration for price feeds

### Transparency
- All transactions recorded on blockchain
- Public audit trail for crop provenance
- Immutable ownership records
- Decentralized governance mechanisms

### Efficiency
- Gas-optimized contract design
- Batch processing capabilities
- Layer 2 scaling solutions
- Cross-chain compatibility

## Usage Guidelines

### For Farmers
1. Register your farm details
2. Mint crop NFTs for your produce
3. List crops on the marketplace
4. Apply for loans using crop collateral

### For Buyers
1. Browse available crops
2. Verify authenticity through NFT
3. Make secure payments through escrow
4. Receive ownership transfer

### For Lenders
1. Review loan applications
2. Assess crop collateral value
3. Fund approved loans
4. Receive automated repayments

## Technical Specifications

### Smart Contract Functions

#### Crop NFT Contract
- `mintCropNFT(cropDetails, metadata)`: Create new crop token
- `transferOwnership(tokenId, newOwner)`: Transfer crop ownership
- `verifyCrop(tokenId)`: Verify crop authenticity
- `getCropHistory(tokenId)`: Get complete crop history

#### Loan Contract
- `applyForLoan(amount, collateral)`: Submit loan application
- `approveLoan(loanId)`: Approve loan application
- `repayLoan(loanId, amount)`: Make loan repayment
- `liquidateCollateral(loanId)`: Liquidate defaulted loan

#### Marketplace Contract
- `listCrop(tokenId, price)`: List crop for sale
- `buyerBid(listingId, bidAmount)`: Place bid on crop
- `acceptBid(listingId, bidId)`: Accept buyer bid
- `completeTransaction(listingId)`: Finalize sale

### Events and Logging
- All contract interactions emit events
- Events include timestamp and transaction hash
- Comprehensive logging for audit purposes
- Real-time notifications for stakeholders

## Security Considerations

### Access Control
- Role-based permissions system
- Multi-signature requirements for admin functions
- Time-delayed execution for critical operations
- Emergency pause functionality

### Data Protection
- Encrypted sensitive information
- Zero-knowledge proofs for privacy
- Selective disclosure mechanisms
- GDPR compliance features

### Economic Security
- Slashing conditions for malicious behavior
- Incentive alignment mechanisms
- Dynamic fee adjustment
- MEV protection strategies

## Integration Guide

### Web3 Integration
```javascript
// Example integration code
const contract = new web3.eth.Contract(ABI, contractAddress);
const result = await contract.methods.mintCropNFT(cropData).send({from: account});
```

### API Endpoints
- REST API for contract interaction
- GraphQL for complex queries
- WebSocket for real-time updates
- SDK for mobile applications

## Governance

### Decentralized Governance
- Token-based voting system
- Proposal submission process
- Execution timelock mechanisms
- Community-driven upgrades

### Upgrade Mechanisms
- Proxy contract pattern
- Gradual migration strategies
- Backward compatibility maintenance
- Community consensus requirements

## Support and Resources

### Documentation
- Complete API reference
- Integration tutorials
- Best practices guide
- Troubleshooting manual

### Community
- Developer Discord channel
- Regular community calls
- Bug bounty program
- Educational workshops

---

**Generated on**: ${DateTime.now().toIso8601String()}
**Version**: 1.0.0
**Network**: Ethereum Mainnet
**Gas Limit**: 8,000,000
**Block Time**: ~15 seconds

For technical support, please contact: support@agrichain.io
For security issues, please contact: security@agrichain.io

© 2024 AgriChain. All rights reserved.
''';
  }

  Future<Directory> _getDownloadDirectory() async {
    if (kIsWeb) {
      // For web, we'll use a temporary directory
      return await getTemporaryDirectory();
    }

    if (Platform.isAndroid) {
      // Try to get external storage directory
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } catch (e) {
        // Fall back to application documents directory
      }
    }

    // Default to application documents directory
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _simulateDownloadProgress(Function(double) onProgress) async {
    // Simulate realistic download progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      onProgress(i / 100.0);
    }
  }

  Future<bool> _verifyFileIntegrity(File file, String fileName) async {
    try {
      final expectedHash = _expectedHashes[fileName];
      if (expectedHash == null || expectedHash.isEmpty) {
        // No hash to verify against, assume valid
        return true;
      }

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualHash = digest.toString();

      return actualHash == expectedHash;
    } catch (e) {
      // If verification fails, assume invalid
      return false;
    }
  }
}

class DownloadResult {
  final bool success;
  final String? errorMessage;
  final String? filePath;
  final int? fileSize;

  DownloadResult({
    required this.success,
    this.errorMessage,
    this.filePath,
    this.fileSize,
  });
}