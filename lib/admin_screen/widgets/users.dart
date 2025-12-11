import 'package:flutter/material.dart';
import 'package:waygo/services/admin_service.dart';
import 'package:intl/intl.dart';

class UsersWidget extends StatefulWidget {
  const UsersWidget({Key? key}) : super(key: key);

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget> {
  String selectedRole = 'All Roles';
  String selectedStatus = 'All Status';
  final AdminService _adminService = AdminService();
  
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? userType;
      if (selectedRole != 'All Roles') {
        // Convert to lowercase to match backend expectations
        userType = selectedRole.toLowerCase();
      }

      bool? isActive;
      if (selectedStatus == 'Active') {
        isActive = true;
      } else if (selectedStatus == 'Suspended') {
        isActive = false;
      }

      final users = await _adminService.getAllUsers(
        userType: userType,
        isActive: isActive,
      );

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Open a bottom sheet containing filter controls (for mobile compact header)
  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: ['All Roles', 'Admin', 'Driver', 'Passenger']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedRole = v ?? 'All Roles'),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: ['All Status', 'Active', 'Suspended']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedStatus = v ?? 'All Status'),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _loadUsers();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                // compact mobile header
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'User Management',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter icon opens bottom sheet
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _openFilterSheet(context),
                      tooltip: 'Filters',
                    ),
                    // Add user as an icon on small screens
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () {
                        // Add user action
                      },
                      tooltip: 'Add User',
                    ),
                  ],
                );
              } else {
                // full header for wider screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'User Management',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Make the filters row take only needed space and be scrollable if necessary
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.6,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Role
                            DropdownButton<String>(
                              value: selectedRole,
                              items:
                                  ['All Roles', 'Admin', 'Driver', 'Passenger']
                                      .map(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value ?? 'All Roles';
                                });
                                _loadUsers();
                              },
                            ),
                            const SizedBox(width: 12),
                            // Status
                            DropdownButton<String>(
                              value: selectedStatus,
                              items: ['All Status', 'Active', 'Suspended']
                                  .map(
                                    (String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value ?? 'All Status';
                                });
                                _loadUsers();
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Add user action
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add User'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Loading, Error, or User Cards
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading users',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(children: _users.map((user) => _buildUserCard(user)).toList()),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final userName = user['userName'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final userType = user['userType'] ?? 'passenger';
    final isActive = user['isActive'] ?? true;
    final userId = user['_id'] ?? '';
    final createdAt = user['createdAt'] ?? '';
    
    // Format role display
    String roleDisplay = userType.substring(0, 1).toUpperCase() + userType.substring(1);
    
    // Format date
    String joinedDate = 'Unknown';
    if (createdAt != null && createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        joinedDate = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        joinedDate = createdAt.toString();
      }
    }

    final roleColor = userType == 'admin'
        ? Colors.purple
        : userType == 'driver'
        ? Colors.blue
        : Colors.green;
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusText = isActive ? 'Active' : 'Suspended';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: roleColor.withOpacity(0.2),
              radius: 28,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        roleDisplay,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined: $joinedDate',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  onPressed: () => _showEditDialog(user),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _toggleUserStatus(userId, !isActive),
                  tooltip: isActive ? 'Suspend User' : 'Activate User',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(userId, userName),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, bool newStatus) async {
    try {
      await _adminService.updateUserStatus(
        userId: userId,
        isActive: newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'User activated successfully'
                  : 'User suspended successfully',
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
            content: Text('Failed to update user status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(dynamic user) async {
    final userName = user['userName'] ?? '';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final isActive = user['isActive'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: $userName'),
              const SizedBox(height: 8),
              Text('Email: $email'),
              const SizedBox(height: 8),
              Text('Phone: ${phone.isNotEmpty ? phone : 'Not provided'}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Status: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Suspended',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleUserStatus(user['_id'], !isActive);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Suspend User' : 'Activate User'),
          ),
        ],
      ),
    );
  }
}
