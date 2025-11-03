import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/crop.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/crop_data_helper.dart';

class CropCard extends StatelessWidget {
  final FirestoreCrop crop;
  final bool showPlaceOrder;
  final VoidCallback? onTap;

  const CropCard({
    super.key,
    required this.crop,
    this.showPlaceOrder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showCropDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildCropImage(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (crop.isNFT)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.sunYellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'NFT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (crop.isAuction)
                          Consumer<AppState>(
                            builder: (context, appState, child) {
                              final auction = appState.getAuctionByCropId(crop.id);
                              if (auction == null) return const SizedBox.shrink();
                              
                              final timeLeft = auction.endTime.difference(DateTime.now());
                              final isActive = timeLeft.inSeconds > 0;
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.primaryGreen : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.gavel,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      isActive ? 'AUCTION' : 'ENDED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 60,
              padding: const EdgeInsets.all(3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    crop.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 7,
                        color: AppTheme.grey,
                      ),
                      Expanded(
                        child: Text(
                          crop.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey,
                            fontSize: 8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Enhanced pricing display
                  Expanded(child: _buildPricingSection(context)),
                  if (crop.certifications.isNotEmpty)
                    _buildCertificationChips(context)
                  else
                    Text(
                      'Harvested ${_getTimeAgo(crop.harvestDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey,
                        fontSize: 6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropImage() {
    // Since we don't have actual images, we'll create a placeholder with crop-specific colors
    final colors = _getCropColors(crop.name);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCropIcon(crop.name),
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              crop.name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCropColors(String cropName) {
    if (cropName.toLowerCase().contains('wheat')) {
      return [const Color(0xFFD4AF37), const Color(0xFFB8860B)];
    } else if (cropName.toLowerCase().contains('rice')) {
      return [const Color(0xFF8FBC8F), const Color(0xFF556B2F)];
    } else if (cropName.toLowerCase().contains('corn')) {
      return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
    } else if (cropName.toLowerCase().contains('tomato')) {
      return [const Color(0xFFFF6347), const Color(0xFFDC143C)];
    } else {
      return [AppTheme.accentGreen, AppTheme.primaryGreen];
    }
  }

  Widget _buildPricingSection(BuildContext context) {
    if (crop.isAuction) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final auction = appState.getAuctionByCropId(crop.id);
          if (auction == null) {
            return _buildDirectPricing(context);
          }
          
          final bids = appState.getBidsForAuction(auction.id);
          final currentBid = bids.isNotEmpty ? (bids.last['amount'] as num).toDouble() : auction.startingPrice;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      'Current Bid: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: Text(
                      '₹${currentBid.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (bids.isNotEmpty)
                Text(
                  '${bids.length} bid${bids.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (crop.cropType != null && CropDataHelper.getPricingForCropType(crop.cropType!) != null) 
                _buildMarketPricing(context),
            ],
          );
        },
      );
    } else {
      return _buildDirectPricing(context);
    }
  }

  Widget _buildDirectPricing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              flex: 3,
              child: Text(
                '₹${crop.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              flex: 2,
              child: Text(
                '/${crop.quantity}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (crop.cropType != null && CropDataHelper.getPricingForCropType(crop.cropType!) != null) 
          _buildMarketPricing(context),
      ],
    );
  }

  Widget _buildMarketPricing(BuildContext context) {
    final pricing = CropDataHelper.getPricingForCropType(crop.cropType!)!;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'MSP: ₹${pricing.msp?.toStringAsFixed(0) ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Market: ₹${pricing.marketPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: SizedBox(
        height: 16, // Fixed height to prevent overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: crop.certifications.take(2).length,
          itemBuilder: (context, index) {
            final cert = crop.certifications[index];
            return Container(
              margin: const EdgeInsets.only(right: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                CropDataHelper.getCertificationDisplayName(CertificationType.values.firstWhere(
                  (e) => e.name == cert['type'],
                  orElse: () => CertificationType.organic,
                )),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getCropIcon(String cropName) {
    if (cropName.toLowerCase().contains('wheat')) {
      return Icons.grass;
    } else if (cropName.toLowerCase().contains('rice')) {
      return Icons.rice_bowl;
    } else if (cropName.toLowerCase().contains('corn')) {
      return Icons.agriculture;
    } else if (cropName.toLowerCase().contains('tomato')) {
      return Icons.local_florist;
    } else {
      return Icons.eco;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }

  void _showCropDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CropDetailsSheet(
        crop: crop,
        showPlaceOrder: showPlaceOrder,
      ),
    );
  }
}

class _CropDetailsSheet extends StatelessWidget {
  final FirestoreCrop crop;
  final bool showPlaceOrder;

  const _CropDetailsSheet({
    required this.crop,
    this.showPlaceOrder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          crop.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                      ),
                      if (crop.isNFT)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.sunYellow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NFT Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Farmer', crop.farmerName),
                  _buildDetailRow('Location', crop.location),
                  _buildDetailRow('Quantity', crop.quantity),
                  _buildDetailRow('Price', '₹${crop.price.toStringAsFixed(0)}'),
                  _buildDetailRow('Harvest Date', DateFormat('MMM dd, yyyy').format(crop.harvestDate)),
                  if (crop.nftTokenId != null)
                    _buildDetailRow('NFT Token ID', crop.nftTokenId!),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crop.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grey,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (showPlaceOrder)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showOrderDialog(context);
                        },
                        child: const Text('Place Order'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Order'),
        content: Text('Order for ${crop.name} will be placed. This feature will be fully implemented with payment integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}