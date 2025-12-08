import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/audit_log_provider.dart';
import 'package:buildit_desktop/models/audit_log_model.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AuditLogProvider _auditLogProvider = AuditLogProvider();
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Sve';
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var result = await _auditLogProvider.get(
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _logs = result.result;
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
            content: Text('Greška pri učitavanju logova: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              const Text(
                'Logovi Aktivnosti',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prati sve aktivnosti u aplikaciji',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Pretraži logove...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.darkGray),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.darkGray),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  _loadLogs();
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
                        _loadLogs();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterButton('Sve', _selectedFilter == 'Sve'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Uspješno', _selectedFilter == 'Uspješno'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Greške', _selectedFilter == 'Greške'),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'Nema logova',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGray,
                              ),
                            ),
                          )
                        : _buildLogsTable(constraints),
              ),
              if (!_isLoading && _logs.isNotEmpty) _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTable(BoxConstraints constraints) {
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
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('Korisnik')),
            DataColumn(label: Text('Akcija')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Poruka')),
          ],
          rows: _logs.map((log) {
            return DataRow(
              cells: [
                DataCell(Text(log.id.toString())),
                DataCell(
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm:ss').format(log.timestamp),
                  ),
                ),
                DataCell(Text(log.username ?? 'N/A')),
                DataCell(Text(log.action)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: int.tryParse(log.responseStatus) != null && 
                             int.parse(log.responseStatus) >= 200 && 
                             int.parse(log.responseStatus) < 300
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.responseStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: int.tryParse(log.responseStatus) != null && 
                               int.parse(log.responseStatus) >= 200 && 
                               int.parse(log.responseStatus) < 300
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      log.message ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    _loadLogs();
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
                    _loadLogs();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _loadLogs();
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
}

