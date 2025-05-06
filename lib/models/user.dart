import 'package:flutter/material.dart';
import 'event_preference.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<EventPreference> preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.preferences = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      preferences: json['preferences'] != null
          ? (json['preferences'] as List)
              .map((pref) => EventPreference.fromJson(pref))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'preferences': preferences.map((pref) => pref.toJson()).toList(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<EventPreference>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
    );
  }
}
