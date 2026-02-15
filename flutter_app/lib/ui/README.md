# Flutter UI Component Library

Reusable, production-grade components for LockFlow.

## Components

### Buttons
- `AppButton` – Primary, secondary, ghost variants with loading states
- `IconButton` – Icon-only buttons

### Cards
- `AppCard` – Elevated card with optional glassmorphism
- `AppCardHeader` – Card title + subtitle header

### Inputs
- `AppTextField` – Text input with validation, icons, error states
- `AppSelect` – Dropdown/select input
- `AppCheckbox` – Custom checkbox
- `AppSwitch` – Toggle switch

### Tables
- `AppDataTable` – Sortable, filterable, searchable table
- `AppDataTableColumn` – Column definition

### Loaders & Skeletons
- `AppSkeletonLoader` – Shimmer animation loader
- `AppSkeletonCard` – Card skeleton for content loading
- `AppLoadingOverlay` – Full-screen loading indicator

### Dialogs & Modals
- `AppDialog` – Alert/confirmation dialog
- `AppSheet` – Bottom sheet modal

### Toasts & Notifications
- `AppToast` – Toast message (success, error, info)
- `AppBanner` – Inline banner message

### Layout
- `AppContainer` – Responsive padding container
- `ResponsiveGrid` – Responsive grid layout

## Design Tokens

See `lib/core/config/theme.dart`:
- **Colors**: Light/dark mode palette
- **Spacing**: 4px to 32px scale
- **Radius**: 4px to full
- **Elevation**: Soft to XL shadows

## Usage Example

```dart
import 'package:lockflow/ui/components/buttons/app_button.dart';

AppButton(
  label: 'Save',
  onPressed: () {},
  variant: ButtonVariant.primary,
)
```

## Dark Mode

All components respect `Theme.of(context).brightness`:
- Automatically swap colors in light/dark modes
- No manual theme toggling needed

## Micro-interactions

- Hover states on web (pointer detection)
- Tap feedback on mobile
- Loading skeletons during content fetch
- Smooth transitions (300ms default)
