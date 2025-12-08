import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/listing_provider.dart';
import 'package:buildit_desktop/models/listing_model.dart';
import 'package:buildit_desktop/screens/admin/edit_listing_screen.dart';
import 'package:buildit_desktop/screens/admin/add_listing_screen.dart';
import 'package:intl/intl.dart';

class ListingsAdminScreen extends StatefulWidget {
  const ListingsAdminScreen({super.key});

  @override
  State<ListingsAdminScreen> createState() => _ListingsAdminScreenState();
}

class _ListingsAdminScreenState extends State<ListingsAdminScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var result = await _listingProvider.get(
        filter: _searchQuery.isNotEmpty ? {'FTS': _searchQuery} : null,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _listings = result.result;
        _totalCount = result.count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju oglasa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteListing(int listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje oglasa'),
        content: const Text('Da li ste sigurni da želite obrisati ovaj oglas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _listingProvider.delete(listingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oglas je uspješno obrisan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadListings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri brisanju oglasa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : _listings.isEmpty
                        ? const Center(
                            child: Text(
                              'Nema oglasa',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGray,
                              ),
                            ),
                          )
                        : _buildListingsTable(constraints),
              ),
              if (!_isLoading && _listings.isNotEmpty) _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Upravljanje oglasima',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddListingScreen(),
              ),
            );
            if (result == true) {
              _loadListings();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Dodaj oglas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Pretraži oglase...',
        prefixIcon: const Icon(Icons.search, color: AppColors.darkGray),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.darkGray),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadListings();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onSubmitted: (_) {
        setState(() {
          _currentPage = 1;
        });
        _loadListings();
      },
    );
  }

  Widget _buildListingsTable(BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Naslov')),
            DataColumn(label: Text('Tip')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Featured')),
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Kreiran')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _listings.map((listing) {
            return DataRow(
              cells: [
                DataCell(Text(listing.id.toString())),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      listing.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(listing.listingType)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: listing.status == 'Active'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: listing.status == 'Active' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  listing.isFeatured
                      ? const Icon(Icons.star, color: Colors.amber, size: 20)
                      : const Icon(Icons.star_border, size: 20),
                ),
                DataCell(
                  Text(listing.item?.title ?? 'N/A'),
                ),
                DataCell(
                  Text(
                    DateFormat('dd.MM.yyyy').format(listing.createdAt),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppColors.primaryOrange,
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditListingScreen(listing: listing),
                            ),
                          );
                          if (result == true) {
                            _loadListings();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        onPressed: () => _deleteListing(listing.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_totalCount / _pageSize).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadListings();
                  }
                : null,
          ),
          Text(
            'Stranica $_currentPage od $totalPages (Ukupno: $_totalCount)',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadListings();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

