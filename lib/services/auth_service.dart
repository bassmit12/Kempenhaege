import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_credentials.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  // Sample users for initial setup
  final List<Map<String, dynamic>> _sampleUsers = [
    {
      'id': '1',
      'name': 'John Doe',
      'username': 'johndoe',
      'email': 'johndoe@example.com',
      'role': 'Care Coordinator',
      'pincode': '1234',
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'username': 'janesmith',
      'email': 'janesmith@example.com',
      'role': 'Admin',
      'pincode': '5678',
    },
  ];

  AuthService() {
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    try {
      debugPrint('Initializing AuthService...');
      await _createUsersFileIfNotExists();
      await _checkSavedAuthState();
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _error = 'Failed to initialize authentication service: $e';
      notifyListeners();
    }
  }

  Future<void> _createUsersFileIfNotExists() async {
    try {
      final file = await _getUsersFile();
      final exists = await file.exists();
      
      debugPrint('Users file exists: $exists');
      
      if (!exists) {
        debugPrint('Creating users file with sample data...');
        // Create sample users
        final usersCredentials = _sampleUsers.map((user) => {
          'username': user['username'],
          'pincode': user['pincode'],
        }).toList();
        
        // Create sample user data
        final usersData = _sampleUsers.map((user) => {
          'id': user['id'],
          'name': user['name'],
          'username': user['username'],
          'email': user['email'],
          'role': user['role'],
          'preferences': [],
        }).toList();
        
        final jsonData = {
          'credentials': usersCredentials,
          'users': usersData,
        };
        
        // Convert to JSON string and write to file
        final jsonString = jsonEncode(jsonData);
        debugPrint('Writing JSON data to file: ${file.path}');
        await file.writeAsString(jsonString);
        debugPrint('Sample users created successfully');
      }
    } catch (e) {
      debugPrint('Error creating users file: $e');
      _error = 'Failed to initialize user data: $e';
      notifyListeners();
    }
  }

  Future<void> _checkSavedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');
      
      debugPrint('Saved user ID: $savedUserId');
      
      if (savedUserId != null) {
        // Try to load the user from the saved ID
        final users = await _loadUsers();
        
        if (users.isEmpty) {
          debugPrint('No users found in storage');
          return;
        }
        
        final savedUser = users.firstWhere(
          (user) => user['id'] == savedUserId,
          orElse: () => {},
        );
        
        if (savedUser.isNotEmpty) {
          debugPrint('Restoring user session for ID: $savedUserId');
          _currentUser = User.fromJson(savedUser);
          notifyListeners();
          debugPrint('User session restored successfully');
        } else {
          debugPrint('User with ID $savedUserId not found');
        }
      } else {
        debugPrint('No saved user ID found');
      }
    } catch (e) {
      debugPrint('Error checking saved auth state: $e');
      _error = 'Failed to restore login session: $e';
      notifyListeners();
    }
  }

  Future<File> _getUsersFile() async {
    try {
      Directory directory;
      
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms, use the app support directory
        directory = await getApplicationSupportDirectory();
      }
      
      final filePath = '${directory.path}/users.json';
      debugPrint('Users file path: $filePath');
      return File(filePath);
    } catch (e) {
      debugPrint('Error getting users file: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    try {
      final file = await _getUsersFile();
      final exists = await file.exists();
      
      if (!exists) {
        debugPrint('Users file does not exist');
        return [];
      }
      
      debugPrint('Reading users from file...');
      final jsonString = await file.readAsString();
      
      if (jsonString.isEmpty) {
        debugPrint('Users file is empty');
        return [];
      }
      
      final data = jsonDecode(jsonString);
      
      if (data == null || !data.containsKey('users')) {
        debugPrint('Invalid JSON format or missing users key');
        return [];
      }
      
      final users = List<Map<String, dynamic>>.from(data['users']);
      debugPrint('Loaded ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('Error loading users: $e');
      _error = 'Failed to load users: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCredentials() async {
    try {
      final file = await _getUsersFile();
      final exists = await file.exists();
      
      if (!exists) {
        debugPrint('Users file does not exist');
        return [];
      }
      
      debugPrint('Reading credentials from file...');
      final jsonString = await file.readAsString();
      
      if (jsonString.isEmpty) {
        debugPrint('Users file is empty');
        return [];
      }
      
      final data = jsonDecode(jsonString);
      
      if (data == null || !data.containsKey('credentials')) {
        debugPrint('Invalid JSON format or missing credentials key');
        return [];
      }
      
      final credentials = List<Map<String, dynamic>>.from(data['credentials']);
      debugPrint('Loaded ${credentials.length} credentials');
      return credentials;
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      _error = 'Failed to load credentials: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> login(String username, String pincode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('Attempting login with username: $username');
      
      // Get credentials and users
      final credentials = await _loadCredentials();
      final users = await _loadUsers();
      
      debugPrint('Loaded ${credentials.length} credentials and ${users.length} users');
      
      // Find matching credentials
      final userCredential = credentials.firstWhere(
        (cred) => cred['username'] == username && cred['pincode'] == pincode,
        orElse: () => {},
      );
      
      if (userCredential.isEmpty) {
        debugPrint('Invalid username or pincode');
        _error = 'Invalid username or pincode';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      debugPrint('Found matching credentials for username: $username');
      
      // Find matching user data
      final userData = users.firstWhere(
        (user) => user['username'] == username,
        orElse: () => {},
      );
      
      if (userData.isEmpty) {
        debugPrint('User data not found for username: $username');
        _error = 'User data not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      debugPrint('Found user data for username: $username');
      
      // Set current user
      _currentUser = User.fromJson(userData);
      
      debugPrint('User loaded successfully: ${_currentUser!.name}');
      
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.id);
      
      debugPrint('Login successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Logging out...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      _currentUser = null;
      notifyListeners();
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout failed: $e');
      _error = 'Logout failed: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}