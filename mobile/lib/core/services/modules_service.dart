import 'package:flutter/material.dart';
import '../../shared/models/module.dart';
import '../../features/collection/presentation/screens/record_collection_screen.dart';
import '../../features/collection/presentation/screens/pending_collections_screen.dart';
import '../../features/suppliers/presentation/screens/collected_milk_screen.dart';
import '../../features/suppliers/presentation/screens/suppliers_list_screen.dart';
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/customers/presentation/screens/sold_milk_screen.dart';
import '../../features/customers/presentation/screens/add_customer_screen.dart';
import '../../features/merchant/presentation/screens/wallets_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/create_post_screen.dart';
import '../../features/market/presentation/screens/all_products_screen.dart';
import '../../features/account_access/presentation/screens/manage_account_access_screen.dart';
import '../../features/agent_reports/presentation/screens/agent_report_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/home/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/help_support_screen.dart';
import '../../features/home/presentation/screens/about_screen.dart';
import '../../features/home/presentation/screens/edit_profile_screen.dart';
import '../../core/theme/app_theme.dart';

class ModulesService {
  /// Get all available modules
  static List<AppModule> getModules(BuildContext context) {
    return [
      // Collections Module
      AppModule(
        id: 'collections',
        name: 'Collections',
        description: 'Manage milk collections from suppliers',
        icon: Icons.local_shipping,
        color: AppTheme.primaryColor,
        actions: [
          ModuleAction(
            id: 'record_collection',
            name: 'Record Collection',
            description: 'Record a new milk collection',
            icon: Icons.add_circle_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecordCollectionScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'view_collections',
            name: 'View Collections',
            description: 'View all milk collections',
            icon: Icons.list,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CollectedMilkScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'pending_collections',
            name: 'Pending Collections',
            description: 'View pending collections',
            icon: Icons.pending_actions,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PendingCollectionsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Sales Module
      AppModule(
        id: 'sales',
        name: 'Sales',
        description: 'Manage milk sales to customers',
        icon: Icons.point_of_sale,
        color: AppTheme.successColor,
        actions: [
          ModuleAction(
            id: 'record_sale',
            name: 'Record Sale',
            description: 'Record a new milk sale',
            icon: Icons.add_circle_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SoldMilkScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'view_sales',
            name: 'View Sales',
            description: 'View all milk sales',
            icon: Icons.list,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SoldMilkScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Suppliers Module
      AppModule(
        id: 'suppliers',
        name: 'Suppliers',
        description: 'Manage your suppliers',
        icon: Icons.person_add,
        color: AppTheme.primaryColor,
        actions: [
          ModuleAction(
            id: 'add_supplier',
            name: 'Add Supplier',
            description: 'Add a new supplier',
            icon: Icons.person_add,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SuppliersListScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'view_suppliers',
            name: 'View Suppliers',
            description: 'View all suppliers',
            icon: Icons.list,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SuppliersListScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Customers Module
      AppModule(
        id: 'customers',
        name: 'Customers',
        description: 'Manage your customers',
        icon: Icons.business,
        color: AppTheme.infoColor,
        actions: [
          ModuleAction(
            id: 'add_customer',
            name: 'Add Customer',
            description: 'Add a new customer',
            icon: Icons.person_add,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCustomerScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'view_customers',
            name: 'View Customers',
            description: 'View all customers',
            icon: Icons.list,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomersListScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Wallets Module
      AppModule(
        id: 'wallets',
        name: 'Wallets',
        description: 'Manage your wallets and transactions',
        icon: Icons.account_balance_wallet,
        color: AppTheme.warningColor,
        actions: [
          ModuleAction(
            id: 'view_wallets',
            name: 'View Wallets',
            description: 'View all wallets',
            icon: Icons.account_balance_wallet,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WalletsScreen(),
                ),
              );
            },
          ),
        ],
        route: '/wallets', // Direct route for simple navigation
      ),

      // Feed Module
      AppModule(
        id: 'feed',
        name: 'Feed',
        description: 'Social feed and posts',
        icon: Icons.feed,
        color: AppTheme.primaryColor,
        actions: [
          ModuleAction(
            id: 'view_feed',
            name: 'View Feed',
            description: 'Browse social feed',
            icon: Icons.feed,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'create_post',
            name: 'Create Post',
            description: 'Create a new post',
            icon: Icons.add_circle_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Market Module
      AppModule(
        id: 'market',
        name: 'Market',
        description: 'Browse and shop in the marketplace',
        icon: Icons.store,
        color: AppTheme.successColor,
        actions: [
          ModuleAction(
            id: 'view_products',
            name: 'View Products',
            description: 'Browse all products',
            icon: Icons.shopping_bag,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllProductsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Account Access Module
      AppModule(
        id: 'account_access',
        name: 'Account Access',
        description: 'Manage employee access and permissions',
        icon: Icons.people,
        color: AppTheme.primaryColor,
        actions: [
          ModuleAction(
            id: 'manage_access',
            name: 'Manage Access',
            description: 'Manage employee access',
            icon: Icons.people,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageAccountAccessScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Reports Module
      AppModule(
        id: 'reports',
        name: 'Reports',
        description: 'View analytics and reports',
        icon: Icons.analytics,
        color: AppTheme.infoColor,
        actions: [
          ModuleAction(
            id: 'view_reports',
            name: 'View Reports',
            description: 'View agent reports',
            icon: Icons.analytics,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AgentReportScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // Settings Module
      AppModule(
        id: 'settings',
        name: 'Settings',
        description: 'App settings and preferences',
        icon: Icons.settings,
        color: AppTheme.textSecondaryColor,
        actions: [
          ModuleAction(
            id: 'app_settings',
            name: 'App Settings',
            description: 'Configure app settings',
            icon: Icons.settings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'edit_profile',
            name: 'Edit Profile',
            description: 'Update your profile',
            icon: Icons.edit,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'notifications',
            name: 'Notifications',
            description: 'View notifications',
            icon: Icons.notifications,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'help_support',
            name: 'Help & Support',
            description: 'Get help and support',
            icon: Icons.help_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          ModuleAction(
            id: 'about',
            name: 'About',
            description: 'About the app',
            icon: Icons.info_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  /// Get a module by ID
  static AppModule? getModuleById(BuildContext context, String id) {
    return getModules(context).firstWhere(
      (module) => module.id == id,
      orElse: () => throw Exception('Module not found: $id'),
    );
  }
}

