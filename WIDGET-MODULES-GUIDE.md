# Seemianki Widget Module Guide

## New Modular Widgets Available

Seemianki now includes comprehensive modular widgets that replace the monolithic device page sections. Here's what's been converted and how to use them:

## Available Widget Modules

### 1. Applications Module (`ApplicationsModule.tsx`)

**Purpose**: Display installed applications and application statistics

**Widgets**:
- **Applications Overview** - Quick stats (total apps, signed apps, categories)
- **Applications Table** - Detailed searchable table of all applications
- **Application Categories** - Visual breakdown by application category

**Data Source**: `device.applications.installedApps[]`

**Configuration**:
- `showCategories`: Show/hide category breakdown
- `maxAppsInTable`: Limit applications shown in table
- `hideSystemApps`: Filter out system applications

### 2. Network Module (`NetworkModuleWidget.tsx`)

**Purpose**: Display network configuration and connectivity information

**Widgets**:
- **Network Overview** - Connection type, IP, MAC address
- **Network Details** - Interface configuration, IPv4/IPv6 settings
- **Wireless Details** - SSID, signal strength, wireless card info

**Data Source**: `device.network`, `device.ipAddress`, `device.macAddress`

**Configuration**:
- `showWirelessDetails`: Show detailed wireless information
- `showIPv6`: Display IPv6 configuration
- `hideInternalIPs`: Hide private IP addresses

### 3. Security Module (`SecurityModule.tsx`)

**Purpose**: Display security status and compliance information

**Widgets**:
- **Security Overview** - FileVault, Firewall, Gatekeeper status
- **System Security** - SIP, Secure Boot, Activation Lock
- **User Access** - SSH users, groups, permissions
- **Security Details** - Comprehensive security status page

**Data Source**: `device.security`

**Configuration**:
- `showAdvancedSecurity`: Display advanced security features
- `highlightRisks`: Use color coding for security risks
- `showUserAccess`: Show user access information

### 4. MDM Module (`MDMModule.tsx`)

**Purpose**: Display MDM enrollment status and management information

**Widgets**:
- **MDM Overview** - Enrollment status and type
- **MDM Details** - Organization info, server details
- **MDM Profiles** - Installed configuration profiles
- **MDM Restrictions** - Device restrictions and policies

**Data Source**: `device.mdm`

**Configuration**:
- `showProfiles`: Display installed MDM profiles
- `showRestrictions`: Show device restrictions
- `showServerDetails`: Display server URL and technical details

## Using the Modular System

### 1. Viewing Widgets

Navigate to `/device-new/[deviceId]` to see the new modular layout with all available widgets.

### 2. Layout Customization

The modular layout supports:
- **Column Configuration**: Choose 1-4 columns
- **Gap Spacing**: Small, medium, or large gaps
- **Widget Expansion**: Click widgets to expand/collapse
- **Dynamic Loading**: Widgets only show when relevant data exists

### 3. Widget Conditions

Widgets automatically show/hide based on:
- **Data availability**: Only display if required data exists
- **Device type**: Some widgets are device-type specific
- **Module configuration**: User preferences control visibility

## Migration from Monolithic Pages

### Before (Monolithic)
```typescript
// All in one giant component
{activeTab === 'applications' && (
  <div className="space-y-8">
    {/* 200+ lines of hardcoded JSX */}
  </div>
)}
```

### After (Modular)
```typescript
// Clean, reusable widgets
<ModularDeviceLayout deviceId={deviceId} />
```

## Benefits

### For Users
- **Faster Loading**: Only load widgets you need
- **Customizable Interface**: Choose layout and visibility
- **Better Performance**: Widgets can refresh independently

### For Developers
- **Easy Extension**: Create new widgets without touching core code
- **Reusable Components**: Widgets work across different contexts
- **Clean Architecture**: Separation of concerns and modularity

### For Organizations
- **Custom Widgets**: Build organization-specific modules
- **Module Marketplace**: Share widgets with the community
- **Flexible Deployment**: Enable only needed functionality

## Creating Custom Widgets

To create a new widget module:

1. **Create the module file**:
```typescript
// src/lib/modules/widgets/MyCustomModule.tsx
import { ExtendedModuleManifest, DeviceWidget, DeviceWidgetProps } from '../EnhancedModule';

const MyWidget: React.FC<DeviceWidgetProps> = ({ device }) => {
  return (
    <div className="p-6">
      <h3>My Custom Widget</h3>
      <p>Device: {device?.name}</p>
    </div>
  );
};

const MyCustomModule = {
  manifest: {
    id: 'my-custom-module',
    name: 'My Custom Module',
    version: '1.0.0',
    enabled: true,
    // ... other manifest properties
  },
  deviceWidgets: [
    {
      id: 'my-widget',
      name: 'My Widget',
      component: MyWidget,
      category: 'custom',
      size: 'medium',
      // ... other widget properties
    }
  ]
};

export default MyCustomModule;
```

2. **Register the module**:
```typescript
// Add to src/lib/modules/ModuleInit.ts
import MyCustomModule from './widgets/MyCustomModule'

// Add to widgetModules array
const widgetModules = [
  // ... existing modules
  MyCustomModule,
]
```

3. **Use the widget**: It will automatically appear in the modular layout!

## Widget Lifecycle

1. **Registration**: Modules register widgets during initialization
2. **Condition Check**: System evaluates if widget should be shown
3. **Rendering**: Widget component receives device data as props
4. **Refresh**: Widgets can refresh independently based on intervals
5. **Interaction**: Users can expand/collapse and configure widgets

## Future Enhancements

- **Widget Marketplace**: Centralized widget sharing
- **Drag & Drop Layout**: User-customizable widget positioning
- **Real-time Updates**: WebSocket-based live data updates
- **Module Settings UI**: Visual configuration interface
- **Widget Templates**: Easy starter templates for common patterns

## Troubleshooting

### Widget Not Showing
1. Check if module is enabled
2. Verify widget conditions are met
3. Ensure required data exists in device object
4. Check browser console for errors

### Data Not Loading
1. Verify API endpoint returns expected data structure
2. Check network requests in developer tools
3. Ensure device permissions allow data access

### Performance Issues
1. Reduce refresh intervals for widgets
2. Limit number of widgets per page
3. Use smaller widget sizes when possible
4. Enable only necessary modules
