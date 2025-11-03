import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/firestore_models.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/crop_card.dart';
import '../widgets/payment_method_selector.dart';
import '../services/smart_contract_service.dart';
import '../services/firebase_service.dart';
import '../services/contract_pdf_service.dart';
import '../screens/rating_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Recent';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFarmer = appState.currentUser?.userType == UserType.farmer;
        
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CustomAppBar(
                  title: 'Marketplace',
                  actions: [
                    if (!isFarmer) ...[
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFilterSheet(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () => _showCart(context),
                      ),
                    ],
                  ],
                ),
              ];
            },
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      if (!isFarmer) _buildSearchBar(),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryGreen,
                        unselectedLabelColor: AppTheme.grey,
                        indicatorColor: AppTheme.primaryGreen,
                        tabs: isFarmer ? const [
                          Tab(text: 'Price Comparison'),
                          Tab(text: 'My Orders'),
                        ] : const [
                          Tab(text: 'Browse Crops'),
                          Tab(text: 'My Orders'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: isFarmer ? [
                      const _PriceComparisonTab(),
                      const _MyOrdersTab(),
                    ] : [
                      _BrowseCropsTab(
                        searchQuery: _searchQuery,
                        selectedCategory: _selectedCategory,
                        sortBy: _sortBy,
                      ),
                      const _MyOrdersTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search crops, farmers, locations...',
          prefixIcon: Icon(Icons.search, color: AppTheme.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.lightGrey,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        onApply: (category, sort) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sort;
          });
        },
      ),
    );
  }

  void _showCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Shopping Cart'),
          ],
        ),
        content: const Text('Cart functionality will be implemented with order management.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BrowseCropsTab extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final String sortBy;

  const _BrowseCropsTab({
    required this.searchQuery,
    required this.selectedCategory,
    required this.sortBy,
  });

  @override
  State<_BrowseCropsTab> createState() => _BrowseCropsTabState();
}

class _BrowseCropsTabState extends State<_BrowseCropsTab> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _firebaseCrops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCropsFromFirebase();
  }

  Future<void> _loadCropsFromFirebase() async {
    try {
      final crops = await _firebaseService.getAllCrops();
      if (mounted) {
        setState(() {
          _firebaseCrops = crops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading crops from Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use crops from AppState (which are already FirestoreCrop objects)
        var allCrops = <FirestoreCrop>[];
        
        // Add local crops
        allCrops.addAll(appState.crops);

        var filteredCrops = allCrops.where((crop) {
          // Search filter
          if (widget.searchQuery.isNotEmpty) {
            final query = widget.searchQuery.toLowerCase();
            if (!crop.name.toLowerCase().contains(query) &&
                !crop.farmerName.toLowerCase().contains(query) &&
                !crop.location.toLowerCase().contains(query)) {
              return false;
            }
          }

          // Category filter
          if (widget.selectedCategory != 'All') {
            if (widget.selectedCategory == 'NFT' && !crop.isNFT) return false;
            if (widget.selectedCategory == 'Regular' && crop.isNFT) return false;
            if (widget.selectedCategory != 'NFT' && 
                widget.selectedCategory != 'Regular' && 
                !crop.name.toLowerCase().contains(widget.selectedCategory.toLowerCase())) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort crops
        switch (widget.sortBy) {
          case 'Price Low to High':
            filteredCrops.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Price High to Low':
            filteredCrops.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'Recent':
            filteredCrops.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
            break;
          case 'Alphabetical':
            filteredCrops.sort((a, b) => a.name.compareTo(b.name));
            break;
        }

        return Column(
          children: [
            _buildCategoryChips(),
            Expanded(
              child: filteredCrops.isEmpty
                  ? _buildEmptyState(context)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filteredCrops.length,
                        itemBuilder: (context, index) {
                          return CropCard(
                            crop: filteredCrops[index],
                            onTap: () => _showCropDetails(context, filteredCrops[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'NFT', 'Regular', 'Wheat', 'Rice', 'Corn', 'Vegetables'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                // This would trigger a rebuild in the parent widget
              },
              selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No crops found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCropDetails(BuildContext context, FirestoreCrop crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CropDetailsSheet(crop: crop),
    );
  }
}

class _CropDetailsSheet extends StatefulWidget {
  final FirestoreCrop crop;

  const _CropDetailsSheet({required this.crop});

  @override
  State<_CropDetailsSheet> createState() => _CropDetailsSheetState();
}

class _CropDetailsSheetState extends State<_CropDetailsSheet> {
  int _quantity = 1;
  bool _isOrdering = false;
  final TextEditingController _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.crop.price * _quantity;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCropHeader(),
                  const SizedBox(height: 20),
                  _buildCropImage(),
                  const SizedBox(height: 20),
                  if (widget.crop.isAuction) ...[
                    _buildAuctionInfo(),
                    const SizedBox(height: 20),
                  ],
                  _buildCropDetails(),
                  const SizedBox(height: 20),
                  _buildFarmerInfo(),
                  const SizedBox(height: 20),
                  if (!widget.crop.isAuction) ...[
                    _buildQuantitySelector(),
                    const SizedBox(height: 20),
                    _buildPriceBreakdown(totalPrice),
                  ] else ...[
                    _buildBiddingSection(),
                  ],
                ],
              ),
            ),
          ),
          _buildOrderButton(totalPrice),
        ],
      ),
    );
  }

  Widget _buildAuctionInfo() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final auction = appState.getAuctionByCropId(widget.crop.id);
        if (auction == null) return const SizedBox.shrink();

        final timeLeft = auction.endTime.difference(DateTime.now());
        final isActive = timeLeft.inSeconds > 0;
        final bids = appState.getBidsForAuction(auction.id);
        final currentBid = bids.isNotEmpty ? (bids.last['amount'] as num).toDouble() : auction.startingPrice;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen.withOpacity(0.1), AppTheme.accentGreen.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Live Auction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'ENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Bid',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${currentBid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Left',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          isActive ? _formatTimeLeft(timeLeft) : 'Ended',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppTheme.primaryGreen : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (bids.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${bids.length} bid${bids.length > 1 ? 's' : ''} placed',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiddingSection() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final auction = appState.getAuctionByCropId(widget.crop.id);
        if (auction == null) return const SizedBox.shrink();

        final bids = appState.getBidsForAuction(auction.id);
        final currentBid = bids.isNotEmpty ? (bids.last['amount'] as num).toDouble() : auction.startingPrice;
        final minBidAmount = currentBid + 100; // Minimum bid increment

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Place Your Bid',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bidController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Bid Amount (₹)',
                            hintText: 'Min: ₹${minBidAmount.toStringAsFixed(0)}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _placeBid(appState, auction.id, minBidAmount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Bid'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reserve Price: ₹${auction.reservePrice?.toStringAsFixed(0) ?? 'Not set'}',
                    style: TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (bids.isNotEmpty) ...[
              Text(
                'Bid History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[bids.length - 1 - index]; // Show latest first
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppTheme.primaryGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bid['bidderName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '₹${(bid['amount'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatTimeLeft(Duration timeLeft) {
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays}d ${timeLeft.inHours % 24}h';
    } else if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
    } else {
      return '${timeLeft.inMinutes}m ${timeLeft.inSeconds % 60}s';
    }
  }

  void _placeBid(AppState appState, String auctionId, double minBidAmount) {
    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount < minBidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum bid amount is ₹${minBidAmount.toStringAsFixed(0)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = appState.currentUser;
    if (user == null) return;

    if (user.walletBalance < bidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      appState.placeBid(
        auctionId: auctionId,
        bidAmount: bidAmount,
      );
      _bidController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bid placed successfully for ₹${bidAmount.toStringAsFixed(0)}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCropHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.crop.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 4),
                  Text(
                    widget.crop.location,
                    style: TextStyle(color: AppTheme.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.crop.isNFT)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.sunYellow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.white),
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
    );
  }

  Widget _buildCropImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 60,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              widget.crop.name,
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.crop.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Harvest Date',
                DateFormat('MMM dd, yyyy').format(widget.crop.harvestDate),
                Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                'Available',
                widget.crop.quantity,
                Icons.inventory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.crop.farmerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                Text(
                  'Verified Farmer',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _contactFarmer(),
            icon: Icon(
              Icons.message,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: Icon(Icons.remove),
                    color: AppTheme.primaryGreen,
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: Icon(Icons.add),
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'units',
              style: TextStyle(color: AppTheme.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(double totalPrice) {
    final deliveryFee = 50.0;
    final platformFee = totalPrice * 0.02; // 2% platform fee
    final finalTotal = totalPrice + deliveryFee + platformFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow('Crop Price', '₹${widget.crop.price.toStringAsFixed(0)} × $_quantity', '₹${totalPrice.toStringAsFixed(0)}'),
          _buildPriceRow('Delivery Fee', '', '₹${deliveryFee.toStringAsFixed(0)}'),
          _buildPriceRow('Platform Fee', '2%', '₹${platformFee.toStringAsFixed(0)}'),
          const Divider(),
          _buildPriceRow('Total', '', '₹${finalTotal.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String subtitle, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    color: isTotal ? AppTheme.darkGrey : AppTheme.grey,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryGreen : AppTheme.darkGrey,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton(double totalPrice) {
    final deliveryFee = 50.0;
    final platformFee = totalPrice * 0.02;
    final finalTotal = totalPrice + deliveryFee + platformFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isOrdering ? null : () => _showPaymentDialog(finalTotal),
          child: _isOrdering
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Processing...'),
                  ],
                )
              : Text('Place Order - ₹${finalTotal.toStringAsFixed(0)}'),
        ),
      ),
    );
  }

  void _contactFarmer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${widget.crop.farmerName}'),
        content: const Text('Messaging functionality will be implemented with real-time chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(double totalAmount) async {
    setState(() {
      _isOrdering = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final expectedDelivery = DateTime.now().add(const Duration(days: 3));
      
      // Step 1: Create smart contract for the purchase
      final contractResult = await SmartContractService.createPurchaseContract(
        buyerAddress: appState.currentUser?.walletAddress ?? '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
        sellerAddress: '0x${widget.crop.farmerName.hashCode.toRadixString(16)}',
        cropId: widget.crop.id,
        nftTokenId: widget.crop.nftTokenId ?? 'NFT${DateTime.now().millisecondsSinceEpoch}',
        amount: totalAmount,
        quantity: '$_quantity kg',
        expectedDelivery: expectedDelivery,
      );

      if (!contractResult['success']) {
        throw Exception('Failed to create smart contract');
      }

      // Step 2: Lock funds in escrow
      final escrowResult = await SmartContractService.lockEscrow(
        contractId: contractResult['contractId'],
        buyerAddress: appState.currentUser?.walletAddress ?? '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
        amount: totalAmount,
      );

      if (!escrowResult['success']) {
        throw Exception('Failed to lock funds in escrow');
      }

      // Step 3: Create order with smart contract details
        final newOrder = FirestoreOrder(
        id: contractResult['contractId'],
        cropId: widget.crop.id,
        buyerId: appState.currentUser?.id ?? '',
        buyerName: appState.currentUser?.name ?? '',
        sellerId: 'farmer_${widget.crop.farmerName.hashCode}',
        sellerName: widget.crop.farmerName,
        quantity: '$_quantity kg',
        totalAmount: totalAmount,
        status: OrderStatus.confirmed,
        orderDate: DateTime.now(),
        expectedDelivery: expectedDelivery,
        createdAt: DateTime.now(),
      );

      appState.addOrder(newOrder);

      Navigator.pop(context);
      
      // Show success dialog with contract details
      _showContractSuccessDialog(
        contractResult['contractId'],
        contractResult['transactionHash'],
        escrowResult['transactionHash'],
        totalAmount,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isOrdering = false;
      });
    }
  }

  void _showPaymentDialog(double totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'Payment for ${widget.crop.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            // Payment method selector
            Expanded(
              child: PaymentMethodSelector(
                amount: totalAmount,
                description: 'Purchase of ${widget.crop.name} (${_quantity} kg)',
                metadata: {
                  'crop_id': widget.crop.id,
                  'crop_name': widget.crop.name,
                  'farmer_name': widget.crop.farmerName,
                  'quantity': '$_quantity kg',
                },
                onPaymentSuccess: (paymentResponse) {
                  Navigator.pop(context); // Close payment dialog
                  _placeOrderWithPayment(totalAmount, paymentResponse);
                },
                onPaymentFailure: (error) {
                  Navigator.pop(context); // Close payment dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrderWithPayment(double totalAmount, Map<String, dynamic> paymentResponse) async {
    setState(() {
      _isOrdering = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final expectedDelivery = DateTime.now().add(const Duration(days: 3));
      
      // Step 1: Create smart contract for the purchase
      final contractResult = await SmartContractService.createPurchaseContract(
        buyerAddress: appState.currentUser?.walletAddress ?? '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
        sellerAddress: '0x${widget.crop.farmerName.hashCode.toRadixString(16)}',
        cropId: widget.crop.id,
        nftTokenId: widget.crop.nftTokenId ?? 'NFT${DateTime.now().millisecondsSinceEpoch}',
        amount: totalAmount,
        quantity: '$_quantity kg',
        expectedDelivery: expectedDelivery,
      );

      if (!contractResult['success']) {
        throw Exception('Failed to create smart contract');
      }

      // Step 2: Lock funds in escrow
      final escrowResult = await SmartContractService.lockEscrow(
        contractId: contractResult['contractId'],
        buyerAddress: appState.currentUser?.walletAddress ?? '0x742d35Cc6634C0532925a3b8D4C9db7f8e',
        amount: totalAmount,
      );

      if (!escrowResult['success']) {
        throw Exception('Failed to lock funds in escrow');
      }

      // Step 3: Create order with smart contract and payment details
      final newOrder = FirestoreOrder(
        id: contractResult['contractId'],
        cropId: widget.crop.id,
        buyerId: appState.currentUser?.id ?? '',
        buyerName: appState.currentUser?.name ?? '',
        sellerId: 'farmer_${widget.crop.farmerName.hashCode}',
        sellerName: widget.crop.farmerName,
        quantity: '$_quantity kg',
        totalAmount: totalAmount,
        status: OrderStatus.confirmed,
        orderDate: DateTime.now(),
        expectedDelivery: expectedDelivery,
        createdAt: DateTime.now(),
        metadata: {
          'smart_contract_id': contractResult['contractId'],
          'contract_tx_hash': contractResult['transactionHash'],
          'escrow_tx_hash': escrowResult['transactionHash'],
          'payment_method': paymentResponse['payment_method'] ?? 'Unknown',
          'transaction_id': paymentResponse['transaction_id'] ?? '',
          'payment_response': paymentResponse,
        },
      );

      appState.addOrder(newOrder);

      Navigator.pop(context); // Close the crop details sheet
      
      // Show success dialog with contract and payment details
      _showContractSuccessDialog(
        contractResult['contractId'],
        contractResult['transactionHash'],
        escrowResult['transactionHash'],
        totalAmount,
        paymentResponse,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isOrdering = false;
      });
    }
  }

  void _showContractSuccessDialog(String contractId, String contractTxHash, String escrowTxHash, double amount, [Map<String, dynamic>? paymentResponse]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Smart Contract Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your purchase is secured by a smart contract with the following details:'),
            const SizedBox(height: 16),
            _buildContractDetail('Contract ID', contractId),
            _buildContractDetail('Contract Hash', contractTxHash),
            _buildContractDetail('Escrow Hash', escrowTxHash),
            _buildContractDetail('Escrow Amount', '₹${amount.toStringAsFixed(2)}'),
            if (paymentResponse != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Payment Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              _buildContractDetail('Payment Method', paymentResponse['payment_method'] ?? 'Unknown'),
              _buildContractDetail('Transaction ID', paymentResponse['transaction_id'] ?? 'N/A'),
              if (paymentResponse['upi_id'] != null)
                _buildContractDetail('UPI ID', paymentResponse['upi_id']),
              if (paymentResponse['card_last_four'] != null)
                _buildContractDetail('Card', '**** **** **** ${paymentResponse['card_last_four']}'),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Contract Features:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Funds locked in escrow until delivery'),
                  const Text('• Automatic release on delivery confirmation'),
                  const Text('• Dispute resolution mechanism'),
                  const Text('• NFT ownership transfer on completion'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _downloadContract(contractId, contractTxHash, escrowTxHash, amount, paymentResponse),
            icon: const Icon(Icons.download),
            label: const Text('Download Contract'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadContract(String contractId, String contractTxHash, String escrowTxHash, double amount, Map<String, dynamic>? paymentResponse) async {
    try {
      // Check if widget is still mounted before showing dialog
      if (!mounted) return;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating contract PDF...'),
            ],
          ),
        ),
      );

      final appState = Provider.of<AppState>(context, listen: false);
      
      // Find the order and crop data
      final order = appState.orders.firstWhere((o) => o.id == contractId);
      final crop = appState.crops.firstWhere((c) => c.id == order.cropId);
      final buyer = appState.currentUser!;
      
      // Create a mock seller user from crop data
      final seller = FirestoreUser(
        id: order.sellerId,
        name: order.sellerName,
        email: '${order.sellerName.toLowerCase().replaceAll(' ', '.')}@agrichain.com',
        phone: '+91-XXXX-XXXXXX',
        userType: UserType.farmer,
        location: crop.location,
        walletAddress: '0x${crop.farmerName.hashCode.toRadixString(16)}',
        createdAt: DateTime.now(),
      );

      // Prepare contract data
      final contractData = {
        'contractId': contractId,
        'transactionHash': contractTxHash,
        'contractAddress': '0xabcdef1234567890abcdef1234567890abcdef12',
        'escrowAddress': '0x1234567890abcdef1234567890abcdef12345678',
        'blockNumber': 5000000 + (contractId.hashCode % 1000000),
        'gasUsed': '0.0045 ETH',
        'contractData': {
          'terms': {
            'deliveryDeadline': order.expectedDelivery?.toIso8601String() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'qualityStandards': 'Grade A organic certification required',
            'penaltyRate': 0.05,
            'refundPolicy': 'Full refund if quality standards not met',
          }
        }
      };

      // Generate PDF
      final pdfBytes = await ContractPdfService.generatePurchaseContract(
        order: order,
        crop: crop,
        buyer: buyer,
        seller: seller,
        contractData: contractData,
        paymentDetails: paymentResponse,
      );

      // Generate filename
      final fileName = ContractPdfService.generateContractFileName(contractId);

      // Check if widget is still mounted before closing dialog
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Save and share PDF
      await ContractPdfService.shareOrPrintPdf(pdfBytes, fileName);

      // Check if widget is still mounted before showing success message
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Contract PDF generated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;
      
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating contract: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildContractDetail(String label, String value) {
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
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceComparisonTab extends StatefulWidget {
  const _PriceComparisonTab();

  @override
  State<_PriceComparisonTab> createState() => _PriceComparisonTabState();
}

class _PriceComparisonTabState extends State<_PriceComparisonTab> {
  String _selectedCropType = 'All';
  String _sortBy = 'Price Low to High';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Group crops by type for price comparison
        final cropPriceData = _generatePriceComparisonData(appState.crops);
        
        return Column(
          children: [
            _buildFilterControls(),
            Expanded(
              child: cropPriceData.isEmpty
                  ? _buildEmptyPriceState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cropPriceData.length,
                      itemBuilder: (context, index) {
                        return _PriceComparisonCard(
                          priceData: cropPriceData[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterControls() {
    final cropTypes = [
      {'value': 'All', 'label': 'All Crops', 'icon': Icons.agriculture},
      {'value': 'Wheat', 'label': 'Wheat', 'icon': Icons.grass},
      {'value': 'Rice', 'label': 'Rice', 'icon': Icons.rice_bowl},
      {'value': 'Corn', 'label': 'Corn', 'icon': Icons.eco},
      {'value': 'Vegetables', 'label': 'Vegetables', 'icon': Icons.local_florist},
      {'value': 'Fruits', 'label': 'Fruits', 'icon': Icons.apple},
    ];
    
    final sortOptions = [
      {'value': 'Price Low to High', 'label': 'Lowest Price First', 'icon': Icons.arrow_upward},
      {'value': 'Price High to Low', 'label': 'Highest Price First', 'icon': Icons.arrow_downward},
      {'value': 'Alphabetical', 'label': 'A to Z', 'icon': Icons.sort_by_alpha},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort Prices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Choose Crop Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCropType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppTheme.primaryGreen.withOpacity(0.05),
                      ),
                      items: cropTypes.map((type) => DropdownMenuItem(
                        value: type['value'] as String,
                        child: Row(
                          children: [
                            Icon(type['icon'] as IconData, size: 20, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text(type['label'] as String),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCropType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Sort Prices',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppTheme.primaryGreen.withOpacity(0.05),
                      ),
                      items: sortOptions.map((option) => DropdownMenuItem(
                        value: option['value'] as String,
                        child: Row(
                          children: [
                            Icon(option['icon'] as IconData, size: 20, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text(option['label'] as String),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPriceState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No price data available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Price comparison data will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<CropPriceData> _generatePriceComparisonData(List<FirestoreCrop> crops) {
    // Group crops by name/type
    final Map<String, List<FirestoreCrop>> groupedCrops = {};
    
    for (final crop in crops) {
      final cropName = crop.name.toLowerCase();
      if (!groupedCrops.containsKey(cropName)) {
        groupedCrops[cropName] = [];
      }
      groupedCrops[cropName]!.add(crop);
    }

    // Create price comparison data
    final List<CropPriceData> priceData = [];
    
    groupedCrops.forEach((cropName, cropList) {
      if (_selectedCropType == 'All' || 
          cropName.contains(_selectedCropType.toLowerCase())) {
        
        cropList.sort((a, b) => a.price.compareTo(b.price));
        
        final minPrice = cropList.first.price;
        final maxPrice = cropList.last.price;
        final avgPrice = cropList.fold(0.0, (sum, crop) => sum + crop.price) / cropList.length;
        
        priceData.add(CropPriceData(
          cropName: cropName,
          minPrice: minPrice,
          maxPrice: maxPrice,
          averagePrice: avgPrice,
          totalListings: cropList.length,
          crops: cropList,
        ));
      }
    });

    // Sort the price data
    switch (_sortBy) {
      case 'Price Low to High':
        priceData.sort((a, b) => a.averagePrice.compareTo(b.averagePrice));
        break;
      case 'Price High to Low':
        priceData.sort((a, b) => b.averagePrice.compareTo(a.averagePrice));
        break;
      case 'Alphabetical':
        priceData.sort((a, b) => a.cropName.compareTo(b.cropName));
        break;
    }

    return priceData;
  }
}

class CropPriceData {
  final String cropName;
  final double minPrice;
  final double maxPrice;
  final double averagePrice;
  final int totalListings;
  final List<FirestoreCrop> crops;

  CropPriceData({
    required this.cropName,
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
    required this.totalListings,
    required this.crops,
  });
}

class _PriceComparisonCard extends StatelessWidget {
  final CropPriceData priceData;

  const _PriceComparisonCard({required this.priceData});

  IconData _getCropIcon(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'wheat': return Icons.grass;
      case 'rice': return Icons.rice_bowl;
      case 'corn': return Icons.eco;
      case 'vegetables': return Icons.local_florist;
      case 'fruits': return Icons.apple;
      default: return Icons.agriculture;
    }
  }

  Color _getPriceColor(double price, double minPrice, double maxPrice) {
    if (price <= minPrice + (maxPrice - minPrice) * 0.3) {
      return Colors.green; // Low price - good for buyers
    } else if (price >= maxPrice - (maxPrice - minPrice) * 0.3) {
      return Colors.orange; // High price - good for sellers
    } else {
      return AppTheme.primaryGreen; // Average price
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceColor = _getPriceColor(priceData.averagePrice, priceData.minPrice, priceData.maxPrice);
    final priceRange = priceData.maxPrice - priceData.minPrice;
    final priceVariation = priceRange > 0 ? ((priceRange / priceData.averagePrice) * 100) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.primaryGreen.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with crop info
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getCropIcon(priceData.cropName),
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceData.cropName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        Text(
                          '${priceData.totalListings} farmers selling',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Price information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceItem('Lowest Price', '₹${priceData.minPrice.toStringAsFixed(0)}', Colors.green),
                        _buildPriceItem('Average Price', '₹${priceData.averagePrice.toStringAsFixed(0)}', AppTheme.primaryGreen),
                        _buildPriceItem('Highest Price', '₹${priceData.maxPrice.toStringAsFixed(0)}', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Price difference: ₹${priceRange.toStringAsFixed(0)} per kg',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDetailedComparison(context),
                  icon: Icon(Icons.analytics, size: 20),
                  label: Text(
                    'View Detailed Analysis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }

  void _showDetailedComparison(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailedComparisonSheet(priceData: priceData),
    );
  }
}

class _DetailedComparisonSheet extends StatelessWidget {
  final CropPriceData priceData;

  const _DetailedComparisonSheet({required this.priceData});

  Color _getPriceColor(double price) {
    if (price <= priceData.minPrice + (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return Colors.green;
    } else if (price >= priceData.maxPrice - (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return Colors.orange;
    } else {
      return AppTheme.primaryGreen;
    }
  }

  String _getPriceLabel(double price) {
    if (price <= priceData.minPrice + (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return 'Low Price';
    } else if (price >= priceData.maxPrice - (priceData.maxPrice - priceData.minPrice) * 0.3) {
      return 'High Price';
    } else {
      return 'Fair Price';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort crops by price for better comparison
    final sortedCrops = List<FirestoreCrop>.from(priceData.crops)
      ..sort((a, b) => a.price.compareTo(b.price));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${priceData.cropName} Prices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${priceData.totalListings} farmers selling',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSimplePriceInfo('Lowest', '₹${priceData.minPrice.toStringAsFixed(0)}', Colors.green),
                    _buildSimplePriceInfo('Average', '₹${priceData.averagePrice.toStringAsFixed(0)}', AppTheme.primaryGreen),
                    _buildSimplePriceInfo('Highest', '₹${priceData.maxPrice.toStringAsFixed(0)}', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choose the best price for your needs',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Seller list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortedCrops.length,
              itemBuilder: (context, index) {
                final crop = sortedCrops[index];
                final priceColor = _getPriceColor(crop.price);
                final priceLabel = _getPriceLabel(crop.price);
                final isLowestPrice = crop.price == priceData.minPrice;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLowestPrice 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      width: isLowestPrice ? 2 : 1,
                    ),
                    color: isLowestPrice 
                        ? Colors.green.withOpacity(0.05)
                        : Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Farmer avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: priceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: priceColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: priceColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Farmer info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      crop.farmerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.darkGrey,
                                      ),
                                    ),
                                  ),
                                  if (isLowestPrice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'BEST DEAL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: AppTheme.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    crop.location,
                                    style: TextStyle(
                                      color: AppTheme.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.inventory, size: 14, color: AppTheme.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${crop.quantity} available',
                                    style: TextStyle(
                                      color: AppTheme.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Price info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${crop.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: priceColor,
                              ),
                            ),
                            Text(
                              'per kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: priceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                priceLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePriceInfo(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }
}

class _MyOrdersTab extends StatelessWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFarmer = appState.currentUser?.userType == UserType.farmer;
        
        // Filter orders based on user type
        final myOrders = isFarmer == true
            ? appState.orders
                .where((order) => order.sellerName == appState.currentUser?.name)
                .toList()
            : appState.orders
                .where((order) => order.buyerName == appState.currentUser?.name)
                .toList();

        if (myOrders.isEmpty) {
          return _buildEmptyState(context, isFarmer);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myOrders.length,
          itemBuilder: (context, index) {
            return _OrderCard(order: myOrders[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isFarmer) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFarmer ? Icons.agriculture : Icons.shopping_bag_outlined,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFarmer ? 'No orders received yet' : 'No orders yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFarmer 
                ? 'Orders from buyers will appear here when they purchase your crops'
                : 'Start shopping to see your orders here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FirestoreOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: _getStatusColor(order.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetail(
                  'Farmer',
                  order.sellerName,
                  Icons.person,
                ),
              ),
              Expanded(
                child: _buildOrderDetail(
                  'Quantity',
                  '${order.quantity} units',
                  Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetail(
                  'Order Date',
                  DateFormat('MMM dd').format(order.orderDate),
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildOrderDetail(
                  'Expected Delivery',
                  DateFormat('MMM dd').format(order.expectedDelivery ?? DateTime.now()),
                  Icons.local_shipping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderActions(context, order),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return AppTheme.primaryGreen;
      case OrderStatus.shipped:
        return Colors.blue;
      case OrderStatus.delivered:
        return AppTheme.accentGreen;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildOrderActions(BuildContext context, FirestoreOrder order) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    List<Widget> actions = [];
    
    // Contract download action for confirmed orders
    if (order.status == OrderStatus.confirmed || order.status == OrderStatus.shipped || order.status == OrderStatus.delivered) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _downloadOrderContract(context, order),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Contract'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }
    
    // Track order action
    actions.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () => _trackOrder(context, order),
          child: const Text('Track'),
        ),
      ),
    );
    
    actions.add(const SizedBox(width: 8));
    
    // Rating action for delivered orders
    if (order.status == OrderStatus.delivered && 
        appState.currentUser != null &&
        ((appState.currentUser!.id == order.buyerId && !order.buyerRated) ||
         (appState.currentUser!.id == order.sellerId && !order.sellerRated))) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _navigateToRating(context, order),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Rate'),
          ),
        ),
      );
    } else {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _contactFarmer(context),
            child: const Text('Contact'),
          ),
        ),
      );
    }
    
    return Row(children: actions);
  }

  void _navigateToRating(BuildContext context, FirestoreOrder order) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUserId = appState.currentUser?.id;
    
    if (currentUserId == null) return;
    
    String targetUserId;
    String targetUserName;
    RatingType ratingType;
    
    if (order.buyerId == currentUserId) {
      // Current user is buyer, rating the seller
      targetUserId = order.sellerId;
      targetUserName = order.sellerName;
      ratingType = RatingType.overall;
    } else {
      // Current user is seller, rating the buyer
      targetUserId = order.buyerId;
      targetUserName = order.buyerName;
      ratingType = RatingType.overall;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiveRatingScreen(
          toUserId: targetUserId,
          toUserName: targetUserName,
          ratingType: ratingType,
          transactionId: order.id,

        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _trackOrder(BuildContext context, FirestoreOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Order'),
        content: Text('Real-time tracking will be implemented with GPS integration. Order #${order.id.substring(0, 8)} is currently ${_getStatusText(order.status).toLowerCase()}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadOrderContract(BuildContext context, FirestoreOrder order) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating contract PDF...'),
            ],
          ),
        ),
      );

      final appState = Provider.of<AppState>(context, listen: false);
      
      // Find the crop data
      final crop = appState.crops.firstWhere((c) => c.id == order.cropId);
      final buyer = appState.currentUser!;
      
      // Create a mock seller user from order data
      final seller = FirestoreUser(
        id: order.sellerId,
        name: order.sellerName,
        email: '${order.sellerName.toLowerCase().replaceAll(' ', '.')}@agrichain.com',
        phone: '+91-XXXX-XXXXXX',
        userType: UserType.farmer,
        location: crop.location,
        walletAddress: '0x${crop.farmerName.hashCode.toRadixString(16)}',
        createdAt: DateTime.now(),
      );

      // Extract contract data from order metadata
      final metadata = order.metadata ?? {};
      final contractData = {
        'contractId': metadata['smart_contract_id'] ?? order.id,
        'transactionHash': metadata['contract_tx_hash'] ?? '0x${order.id.hashCode.toRadixString(16)}',
        'contractAddress': '0xabcdef1234567890abcdef1234567890abcdef12',
        'escrowAddress': '0x1234567890abcdef1234567890abcdef12345678',
        'blockNumber': 5000000 + (order.id.hashCode % 1000000),
        'gasUsed': '0.0045 ETH',
        'contractData': {
          'terms': {
            'deliveryDeadline': order.expectedDelivery?.toIso8601String() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'qualityStandards': 'Grade A organic certification required',
            'penaltyRate': 0.05,
            'refundPolicy': 'Full refund if quality standards not met',
          }
        }
      };

      // Generate PDF
      final pdfBytes = await ContractPdfService.generatePurchaseContract(
        order: order,
        crop: crop,
        buyer: buyer,
        seller: seller,
        contractData: contractData,
        paymentDetails: metadata['payment_response'],
      );

      // Generate filename
      final fileName = ContractPdfService.generateContractFileName(order.id);

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Save and share PDF
      await ContractPdfService.shareOrPrintPdf(pdfBytes, fileName);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Contract PDF generated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating contract: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _contactFarmer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${order.sellerName}'),
        content: const Text('Direct messaging with farmers will be implemented with real-time chat functionality.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String sortBy;
  final Function(String, String) onApply;

  const _FilterSheet({
    required this.selectedCategory,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _selectedCategory;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                              _sortBy = 'Recent';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(_selectedCategory, _sortBy);
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = ['All', 'NFT', 'Regular', 'Wheat', 'Rice', 'Corn', 'Vegetables'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    final sortOptions = ['Recent', 'Price Low to High', 'Price High to Low', 'Alphabetical'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        ...sortOptions.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
            activeColor: AppTheme.primaryGreen,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}