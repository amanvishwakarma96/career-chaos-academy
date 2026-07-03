import 'package:flutter/material.dart';

class RoleIconMapper {
  RoleIconMapper._();

  static IconData fromKey(String iconKey) {
    switch (iconKey) {
      case 'code':
        return Icons.code;
      case 'bug':
      case 'qa':
        return Icons.bug_report;
      case 'medical':
        return Icons.medical_services;
      case 'engineering':
        return Icons.engineering;
      case 'architecture':
        return Icons.architecture;
      case 'table':
        return Icons.table_chart;
      case 'project':
      case 'manager':
        return Icons.account_tree;
      case 'people':
      case 'hr':
        return Icons.people_alt;
      case 'business':
        return Icons.business_center;
      case 'education':
        return Icons.school;
      case 'science':
        return Icons.science;
      case 'flag':
        return Icons.flag;
      case 'menu_book':
        return Icons.menu_book;
      case 'explore':
        return Icons.explore;
      case 'build':
        return Icons.build;
      case 'verified':
        return Icons.verified;
      case 'chat':
        return Icons.chat;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'trending_up':
        return Icons.trending_up;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.work;
    }
  }
}
