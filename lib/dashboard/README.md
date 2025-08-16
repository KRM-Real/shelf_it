# Dashboard Module

This module contains all the components for the dashboard screen, organized for better maintainability and readability.

## Structure

```
dashboard/
├── dashboard.dart              # Main export file
├── dashboard_view.dart         # Main dashboard view component
├── widgets/                    # Reusable UI components
│   ├── dashboard_header.dart
│   ├── stats_cards.dart
│   ├── inventory_health_card.dart
│   ├── quick_actions_grid.dart
│   └── recent_products_widget.dart
├── dialogs/                    # Dialog components
│   └── dashboard_dialogs.dart
└── services/                   # Business logic and services
    └── barcode_scanner_service.dart
```

## Components

### DashboardView
Main dashboard view that orchestrates all other components.

### Widgets
- **DashboardHeader**: Top header with menu, title, and scan button
- **StatsCards**: Statistics cards showing total items and low stock
- **InventoryHealthCard**: Health status visualization
- **QuickActionsGrid**: Grid of action buttons for various dashboard operations
- **RecentProductsWidget**: List of recently added products

### Dialogs
- **DashboardDialogs**: Contains all dialog functions (transactions, item flow, low stock, analytics)

### Services
- **BarcodeScannerService**: Handles barcode scanning functionality

## Benefits of This Structure

1. **Separation of Concerns**: Each component has a single responsibility
2. **Reusability**: Components can be easily reused in other parts of the app
3. **Maintainability**: Changes to specific features are isolated to their respective files
4. **Testability**: Individual components can be tested independently
5. **Readability**: Code is easier to understand and navigate

## Usage

Import the dashboard module in your main screen:

```dart
import 'dashboard/dashboard.dart';
```

Then use the DashboardView component:

```dart
DashboardView(
  scaffoldKey: _scaffoldKey,
  onRefresh: _refreshDashboard,
  onScanPressed: _handleScanPressed,
  userMode: _userMode,
  companyName: _companyName,
  userId: _userId,
)
```
