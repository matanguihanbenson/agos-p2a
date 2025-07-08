import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentCard extends StatefulWidget {
  final String? assignedUid;
  final ColorScheme cs;

  const AssignmentCard({
    Key? key,
    this.assignedUid,
    required this.cs,
  }) : super(key: key);

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  String? _userName;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.assignedUid != null && widget.assignedUid!.isNotEmpty) {
      _fetchUserName();
    }
  }

  @override
  void didUpdateWidget(AssignmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assignedUid != oldWidget.assignedUid) {
      if (widget.assignedUid != null && widget.assignedUid!.isNotEmpty) {
        _fetchUserName();
      } else {
        setState(() {
          _userName = null;
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _fetchUserName() async {
    setState(() {
      _isLoadingUser = true;
      _userName = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.assignedUid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final firstName = userData['firstname']?.toString() ?? '';
        final lastName = userData['lastname']?.toString() ?? '';
        
        String fullName = '';
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          fullName = '$firstName $lastName';
        } else if (firstName.isNotEmpty) {
          fullName = firstName;
        } else if (lastName.isNotEmpty) {
          fullName = lastName;
        }

        setState(() {
          _userName = fullName.isNotEmpty ? fullName : null;
          _isLoadingUser = false;
        });
      } else if (mounted) {
        setState(() {
          _userName = null;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = null;
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned = widget.assignedUid != null && widget.assignedUid!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.cs.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAssigned 
                  ? widget.cs.primary.withOpacity(0.1)
                  : widget.cs.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isLoadingUser
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.cs.primary,
                    ),
                  )
                : Icon(
                    isAssigned ? Icons.person : Icons.person_outline,
                    color: isAssigned ? widget.cs.primary : widget.cs.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.cs.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isAssigned 
                        ? widget.cs.onSurface
                        : widget.cs.onSurface.withOpacity(0.5),
                  ),
                ),
                if (isAssigned && _userName != null && widget.assignedUid != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${_formatUserId(widget.assignedUid!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAssigned
                  ? Colors.green.withOpacity(0.1)
                  : widget.cs.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isAssigned
                    ? Colors.green.withOpacity(0.3)
                    : widget.cs.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              isAssigned ? 'ASSIGNED' : 'AVAILABLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isAssigned
                    ? Colors.green
                    : widget.cs.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    final isAssigned = widget.assignedUid != null && widget.assignedUid!.isNotEmpty;
    
    if (!isAssigned) {
      return 'Not assigned';
    }
    
    if (_isLoadingUser) {
      return 'Loading...';
    }
    
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }
    
    // Fallback to formatted user ID if name not available
    return _formatUserId(widget.assignedUid!);
  }

  String _formatUserId(String uid) {
    // Format the user ID to be more readable
    if (uid.length > 20) {
      return '${uid.substring(0, 8)}...${uid.substring(uid.length - 8)}';
    }
    return uid;
  }
}
