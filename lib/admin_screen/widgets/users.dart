import 'package:flutter/material.dart';

class UsersWidget extends StatefulWidget {
  const UsersWidget({Key? key}) : super(key: key);

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState extends State<UsersWidget> {
  String selectedRole = 'All Roles';
  String selectedStatus = 'All Status';

  final users = [
    {
      'name': 'Alice Johnson',
      'email': 'alice@example.com',
      'role': 'Passenger',
      'status': 'Active',
      'joined': '2025-01-15',
    },
    {
      'name': 'Bob Smith',
      'email': 'bob@example.com',
      'role': 'Driver',
      'status': 'Active',
      'joined': '2024-11-20',
    },
    {
      'name': 'Carol White',
      'email': 'carol@example.com',
      'role': 'Admin',
      'status': 'Active',
      'joined': '2024-08-10',
    },
    {
      'name': 'David Brown',
      'email': 'david@example.com',
      'role': 'Passenger',
      'status': 'Suspended',
      'joined': '2025-02-05',
    },
    {
      'name': 'Emma Wilson',
      'email': 'emma@example.com',
      'role': 'Passenger',
      'status': 'Active',
      'joined': '2025-03-12',
    },
  ];

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
                        // Apply filters logic here
                        Navigator.of(ctx).pop();
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
                              onChanged: (value) => setState(() {
                                selectedRole = value ?? 'All Roles';
                              }),
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
                              onChanged: (value) => setState(() {
                                selectedStatus = value ?? 'All Status';
                              }),
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

          // User Cards
          Column(children: users.map((user) => _buildUserCard(user)).toList()),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    final roleColor = user['role'] == 'Admin'
        ? Colors.purple
        : user['role'] == 'Driver'
        ? Colors.blue
        : Colors.green;
    final statusColor = user['status'] == 'Active' ? Colors.green : Colors.red;

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
                user['name']![0],
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
                  user['name']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email']!,
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
                        user['role']!,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined: ${user['joined']}',
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
                user['status']!,
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
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    user['status'] == 'Active'
                        ? Icons.block
                        : Icons.check_circle,
                    size: 20,
                    color: user['status'] == 'Active'
                        ? Colors.red
                        : Colors.green,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.history, size: 20, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
