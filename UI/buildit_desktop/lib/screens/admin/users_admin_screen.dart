import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/user_provider.dart';
import 'package:buildit_desktop/models/user_model.dart';
import 'package:buildit_desktop/utils/utils.dart';
import 'package:buildit_desktop/screens/admin/edit_user_screen.dart';
import 'package:buildit_desktop/screens/admin/add_user_screen.dart';
import 'package:intl/intl.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final UserProvider _userProvider = UserProvider();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Svi';
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic>? filter = {};
      
      if (_searchQuery.isNotEmpty) {
        filter!['FTS'] = _searchQuery;
      }
      
      // Apply status filter
      if (_selectedFilter == 'Aktivni') {
        filter!['isActive'] = true;
      } else if (_selectedFilter == 'Neaktivni') {
        filter!['isActive'] = false;
      }

      var result = await _userProvider.get(
        filter: filter.isNotEmpty ? filter : null,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _users = result.result;
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
            content: Text('Greška pri učitavanju korisnika: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final user = _users.firstWhere((u) => u.id == userId);
    final isDeactivating = user.isActive;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeactivating ? 'Deaktivacija korisnika' : 'Aktivacija korisnika'),
        content: Text(
          isDeactivating 
            ? 'Da li ste sigurni da želite deaktivirati ovog korisnika?'
            : 'Da li ste sigurni da želite aktivirati ovog korisnika?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isDeactivating ? 'Deaktiviraj' : 'Aktiviraj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userProvider.delete(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDeactivating 
                  ? 'Korisnik je uspješno deaktiviran'
                  : 'Korisnik je uspješno aktiviran'
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
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
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(
                            child: Text(
                              'Nema korisnika',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGray,
                              ),
                            ),
                          )
                        : _buildUsersTable(constraints),
              ),
              if (!_isLoading && _users.isNotEmpty) _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upravljanje Korisnicima',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pregled i upravljanje $_totalCount registrovanih korisnika',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSearchBar(),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: _buildFilterButtons(),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddUserScreen(),
                  ),
                );
                if (result == true) {
                  _loadUsers();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj korisnika'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterButton('Svi', _selectedFilter == 'Svi'),
          const SizedBox(width: 8),
          _buildFilterButton('Aktivni', _selectedFilter == 'Aktivni'),
          const SizedBox(width: 8),
          _buildFilterButton('Neaktivni', _selectedFilter == 'Neaktivni'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _currentPage = 1; // Reset to first page when filter changes
        });
        _loadUsers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkGray,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }


  Widget _buildUsersTable(BoxConstraints constraints) {
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
            DataColumn(label: Text('Ime')),
            DataColumn(label: Text('Prezime')),
            DataColumn(label: Text('Korisničko ime')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Telefon')),
            DataColumn(label: Text('Tip')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _users.map((user) {
            final isInactive = !user.isActive;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    user.firstName,
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.lastName,
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.username,
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.email,
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.phone ?? '-',
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.userType ?? '-',
                    style: TextStyle(
                      decoration: isInactive ? TextDecoration.lineThrough : null,
                      color: isInactive ? AppColors.darkGray : AppColors.primaryBlack,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.isActive ? 'Aktivan' : 'Neaktivan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                    ),
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
                              builder: (context) => EditUserScreen(user: user),
                            ),
                          );
                          if (result == true) {
                            _loadUsers();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          user.isActive ? Icons.delete : Icons.restore,
                          size: 20,
                        ),
                        color: user.isActive ? Colors.red : Colors.green,
                        onPressed: () => _deleteUser(user.id),
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
                    _loadUsers();
                  }
                : null,
          ),
          Text(
            'Stranica $_currentPage od $totalPages ($_totalCount)',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadUsers();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Pretraži po imenu ili email-u...',
        prefixIcon: const Icon(Icons.search, color: AppColors.darkGray),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.darkGray),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadUsers();
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
        _loadUsers();
      },
    );
  }
}

