import 'package:flutter/material.dart';

/// Represents a module in the app
class AppModule {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<ModuleAction> actions;
  final String? route; // Optional direct route for simple modules

  const AppModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.actions,
    this.route,
  });
}

/// Represents an action within a module
class ModuleAction {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge; // Optional badge (e.g., "New", "3")

  const ModuleAction({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
  });
}

