# Seemianki Modular Architecture Transformation

## Overview

Seemianki has been transformed from a monolithic device page structure to a fully modular, plugin-based architecture similar to MunkiReport. This transformation makes it easy to create, distribute, and manage custom modules.

## Before vs After

### Before: Monolithic Architecture
- ❌ 1000+ line device pages with hardcoded components
- ❌ All functionality tightly coupled in single files
- ❌ Difficult to customize or extend
- ❌ No separation between data and presentation
- ❌ Limited reusability

### After: Modular Architecture
- ✅ Widget-based components that can be mixed and matched
- ✅ Plugin system for easy extension
- ✅ Configurable layouts and ordering
- ✅ Module marketplace and management
- ✅ Separation of concerns
- ✅ Easy to create custom modules

## Key Components

### 1. Module System Foundation

```
src/lib/modules/
├── BaseModule.ts              # Base class for all modules
├── EnhancedModule.ts          # Extended module capabilities
├── ModuleRegistry.ts          # Module registration and management
├── ModuleInit.ts              # Module loading and initialization
├── ModularDeviceLayout.tsx    # Dynamic widget layout system
├── core/                      # Core system modules
│   ├── DeviceInfoModule.tsx
│   └── EventsModule.tsx
└── widgets/                   # Widget modules
    ├── ManagedInstallsModule.tsx
    ├── HardwareModule.tsx
    ├── ApplicationsModule.tsx
    ├── NetworkModuleWidget.tsx
    ├── SecurityModule.tsx
    ├── MDMModule.tsx
    └── EventsModule.tsx       # Events widgets (additional to core)
```

### 2. Widget-Based Device Pages

Instead of monolithic pages, device information is now displayed through modular widgets:

#### Hardware Module
- **Hardware Overview Widget** - CPU, memory, storage summary
- **Storage Details Widget** - Detailed disk usage with visual indicators
- **System Information Widget** - Comprehensive hardware specifications

#### Managed Installs Module
- **Managed Installs Overview** - Software installation statistics
- **Managed Packages Table** - Searchable, filterable package list
- **Installation Errors Widget** - Error tracking and diagnostics

#### Applications Module
- **Applications Overview** - Total apps, signed apps, categories count
- **Applications Table** - Detailed application listing with versions and publishers
- **Application Categories** - Visual breakdown by category

#### Network Module
- **Network Overview** - Connection type, IP address, MAC address
- **Network Details** - Interface configuration and settings
- **Wireless Details** - SSID, signal strength, wireless card info

#### Security Module
- **Security Overview** - FileVault, Firewall, Gatekeeper status
- **System Security** - SIP, Secure Boot, Activation Lock details
- **User Access** - SSH users, groups, permissions

#### MDM Module
- **MDM Overview** - Enrollment status and type
- **MDM Details** - Organization info, server details
- **MDM Profiles** - Installed configuration profiles
- **MDM Restrictions** - Device restrictions and policies

#### Events Module
- **Events Overview** - Summary of recent events and statistics
- **Events List** - Complete chronological list of device events
- **Events Timeline** - Visual timeline of events with status indicators

### 3. Dynamic Layout System

The new `ModularDeviceLayout` component:
- Automatically discovers available widgets from enabled modules
- Provides configurable column layouts (1-4 columns)
- Supports widget sizing (small, medium, large, full)
- Includes expand/collapse functionality
- Filters widgets based on device compatibility
- Sortable widget ordering

### 4. Module Configuration

Each module can define:
```typescript
configSchema: {
  title: 'Module Settings',
  properties: {
    refreshInterval: {
      type: 'number',
      title: 'Refresh Interval (seconds)',
      default: 60,
      validation: { min: 10, max: 300 }
    },
    showDetails: {
      type: 'boolean',
      title: 'Show Detailed Information',
      default: true
    }
  }
}
```

### 5. Conditional Widget Display

Widgets can be shown/hidden based on:
- Device OS type (macOS, Windows, Linux)
- Available data (only show if device has specific data)
- User permissions
- Custom logic

```typescript
conditions: [
  {
    type: 'device_os',
    operator: 'contains',
    value: 'macOS'
  },
  {
    type: 'has_data',
    field: 'managedInstalls',
    operator: 'exists',
    value: true
  }
]
```

## Benefits

### For Users
- **Customizable Interface**: Choose which widgets to display
- **Cleaner Layout**: Information organized in digestible widgets
- **Better Performance**: Only load widgets that are needed
- **Responsive Design**: Works on all screen sizes

### For Developers
- **Easy Extension**: Create new widgets without touching core code
- **Reusable Components**: Widgets can be shared across modules
- **Type Safety**: Full TypeScript support with proper interfaces
- **Testing**: Individual widgets can be tested in isolation

### For Organizations
- **Custom Modules**: Develop organization-specific functionality
- **Module Marketplace**: Share and discover community modules
- **Selective Loading**: Only enable needed functionality
- **Easier Maintenance**: Modular codebase is easier to maintain

## Migration Path

### Existing Monolithic Pages
The original device page (`/device/[deviceId]/page.tsx`) can be gradually migrated by:

1. **Extract Sections**: Convert hardcoded sections to individual widgets
2. **Create Modules**: Package related widgets into logical modules
3. **Update References**: Switch pages to use the modular layout
4. **Test & Validate**: Ensure feature parity

### Custom Functionality
Organizations with custom functionality can:

1. **Create Custom Modules**: Package existing customizations as modules
2. **Use Widget System**: Rebuild custom views using the widget framework
3. **Configuration**: Use the module configuration system for settings
4. **Distribution**: Share modules across environments

## Examples of Modular Breakdown

### Original Managed Installs Section (200+ lines)
**Converted to 3 focused widgets:**
- `ManagedInstallsOverviewWidget` - Statistics and summary
- `ManagedPackagesTableWidget` - Searchable package table
- `ManagedInstallsErrorsWidget` - Error and warning display

### Original Hardware Section (150+ lines)
**Converted to 3 focused widgets:**
- `HardwareOverviewWidget` - CPU, memory, storage cards
- `StorageDetailsWidget` - Detailed disk usage with charts
- `SystemInfoWidget` - Basic system information

## Module Development Workflow

1. **Create Module Class**: Extend `EnhancedBaseModule`
2. **Define Widgets**: Create React components for your functionality
3. **Register Components**: Add widgets to module manifest
4. **Add Configuration**: Define settings schema if needed
5. **Test**: Verify functionality and compatibility
6. **Distribute**: Share via module marketplace or direct installation

## Future Enhancements

### Planned Features
- **Drag & Drop Layout**: Visual widget arrangement
- **Widget Sharing**: Export/import widget configurations
- **Advanced Filtering**: Complex widget display rules
- **Performance Metrics**: Widget loading and render times
- **A/B Testing**: Test different widget configurations

### Community Features
- **Module Ratings**: User feedback on modules
- **Version Management**: Automatic module updates
- **Dependency Resolution**: Handle module dependencies
- **Security Scanning**: Verify module safety

## Getting Started

1. **Explore Existing Modules**: Check `/src/lib/modules/widgets/`
2. **Read Documentation**: See `MODULAR-ARCHITECTURE.md`
3. **Try New Device Page**: Visit `/device-new/[deviceId]`
4. **Create Your Module**: Follow the development guide
5. **Test & Deploy**: Use the module management interface

This modular architecture positions Seemianki to be as extensible and customizable as MunkiReport while providing a modern, React-based development experience.
