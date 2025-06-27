# ReportMate Module System

ReportMate uses a distributed module architecture where each module is its own GitHub repository, following the pattern `reportmate-module-NAME`. This approach is inspired by MunkiReport's modular system but adapted for modern container/WebPubSub environments.

**Status**: ✅ **Fully Implemented** - The modular system is now the default dashboard implementation.

## Current Implementation Status

- ✅ **Dashboard Migration Complete**: The main `/dashboard` now uses the modular system
- ✅ **Module Management UI**: Available at `/modules` for installing/managing modules
- ✅ **Dynamic Module Loading**: Runtime loading and configuration of modules
- ✅ **Widget System**: All dashboard widgets are now modular components
- ✅ **Settings Integration**: Module management through settings panel
- 📝 **Legacy Dashboard**: Preserved at `/dashboard-modular` for reference

## Module Repository Naming Convention

All modules follow the naming pattern:
- **Official modules**: `https://github.com/reportmate/reportmate-module-NAME`
- **Community modules**: `https://github.com/USERNAME/reportmate-module-NAME`
- **3rd party modules**: `https://github.com/COMPANY/reportmate-module-NAME`

## Individual Module Repository Structure

Each module repository contains:

```
reportmate-module-hardware/
├── manifest.json              # Module manifest (required)
├── index.js                   # Main module code (required)
├── styles.css                 # Optional styles
├── components/                # React components
│   ├── HardwareWidget.js
│   └── TemperatureAlert.js
├── utils/                     # Utility functions
│   └── hardwareUtils.js
├── README.md                  # Module documentation
├── package.json               # NPM dependencies (if any)
├── .github/                   # GitHub Actions for CI/CD
│   └── workflows/
│       └── test.yml
└── tests/                     # Unit tests
    └── hardware.test.js
```

## Module Discovery

### Registry-based Discovery

ReportMate discovers modules through a registry system similar to npm but for ReportMate modules:

1. **Official Registry**: `https://registry.reportmate.com/modules`
2. **GitHub Discovery**: Automatic scanning of `reportmate-module-*` repositories
3. **Manual Addition**: Users can add specific repository URLs

### Module Registry Format

The central registry maintains an index of all known modules:

```json
{
  "name": "ReportMate Module Registry",
  "version": "1.0.0",
  "description": "Central registry for ReportMate modules",
  "modules": [
    {
      "id": "hardware",
      "name": "Hardware Monitoring",
      "repository": "https://github.com/reportmate/reportmate-module-hardware",
      "official": true,
      "verified": true,
      "category": "hardware",
      "tags": ["hardware", "monitoring", "alerts"],
      "author": "ReportMate Team",
      "lastUpdated": "2024-12-24T00:00:00Z"
    },
    {
      "id": "security",
      "name": "Security Overview",
      "repository": "https://github.com/reportmate/reportmate-module-security",
      "official": true,
      "verified": true,
      "category": "security",
      "tags": ["security", "compliance", "overview"],
      "author": "ReportMate Team",
      "lastUpdated": "2024-12-24T00:00:00Z"
    },
    {
      "id": "custom-dashboard",
      "name": "Custom Dashboard Widgets",
      "repository": "https://github.com/acme-corp/reportmate-module-custom-dashboard",
      "official": false,
      "verified": false,
      "category": "widget",
      "tags": ["dashboard", "custom", "widgets"],
      "author": "ACME Corp",
      "lastUpdated": "2024-12-20T00:00:00Z"
    }
  ]
}
```

## Module Development

### 1. Create Module Manifest

Each module must have a `manifest.json` file:

```json
{
  "id": "hardware-monitoring",
  "name": "Hardware Monitoring",
  "version": "1.2.0",
  "description": "Advanced hardware monitoring and alerting",
  "author": "ReportMate Team",
  "repository": "official",
  "official": true,
  "category": "hardware",
  "tags": ["hardware", "monitoring", "alerts"],
  "dependencies": [],
  "peerDependencies": [],
  "main": "index.js",
  "styles": "styles.css",
  "permissions": ["device:read"],
  "configSchema": {
    "title": "Hardware Monitoring Settings",
    "properties": {
      "alertThreshold": {
        "type": "number",
        "title": "Temperature Alert Threshold (°C)",
        "default": 80
      },
      "enableNotifications": {
        "type": "boolean",
        "title": "Enable Notifications",
        "default": true
      }
    }
  },
  "defaultConfig": {
    "alertThreshold": 80,
    "enableNotifications": true
  },
  "minVersion": "1.0.0",
  "checksum": "sha256:abcdef1234567890..."
}
```

### 2. Module Entry Point

The main module file should export the module definition:

```javascript
// modules/hardware-monitoring/index.js
const HardwareMonitoringModule = {
  // Module manifest (can be imported from manifest.json)
  manifest: {
    id: 'hardware-monitoring',
    name: 'Hardware Monitoring',
    version: '1.2.0',
    // ... rest of manifest
  },

  // Widget definitions
  widgets: [
    {
      id: 'cpu-temperature',
      name: 'CPU Temperature',
      component: CPUTemperatureWidget,
      category: 'hardware',
      size: 'small'
    },
    {
      id: 'disk-health',
      name: 'Disk Health',
      component: DiskHealthWidget,
      category: 'hardware',
      size: 'medium'
    }
  ],

  // Lifecycle hooks
  onInstall() {
    console.log('Hardware monitoring module installed')
  },

  onEnable() {
    console.log('Hardware monitoring module enabled')
  },

  onDisable() {
    console.log('Hardware monitoring module disabled')
  },

  onUninstall() {
    console.log('Hardware monitoring module uninstalled')
  }
}

// Widget components
const CPUTemperatureWidget = ({ device, config }) => {
  // Widget implementation
  return React.createElement('div', {}, 'CPU Temperature Widget')
}

const DiskHealthWidget = ({ device, config }) => {
  // Widget implementation
  return React.createElement('div', {}, 'Disk Health Widget')
}

// Export for dynamic loading
if (typeof module !== 'undefined' && module.exports) {
  module.exports = HardwareMonitoringModule
} else if (typeof exports !== 'undefined') {
  exports.default = HardwareMonitoringModule
} else {
  // Browser environment
  window.HardwareMonitoringModule = HardwareMonitoringModule
}
```

## Adding Modules to ReportMate

### 1. Official Modules (Auto-discovered)

Official modules are automatically discovered from the ReportMate organization:

- **Pattern**: `https://github.com/reportmate/reportmate-module-*`
- **Trust Level**: Fully trusted and verified
- **Examples**:
  - `https://github.com/reportmate/reportmate-module-hardware`
  - `https://github.com/reportmate/reportmate-module-security`
  - `https://github.com/reportmate/reportmate-module-network`

### 2. Community Modules (Registry-based)

Community modules are discovered through the central registry:

- **Registry**: `https://registry.reportmate.com/modules`
- **Trust Level**: Verified through review process
- **Naming**: `https://github.com/USERNAME/reportmate-module-NAME`

### 3. Custom Modules (Manual Addition)

Users can add any repository that follows the naming convention:

1. Go to **Settings** → **Module Manager** → **Add Module**
2. Enter the repository URL: `https://github.com/OWNER/reportmate-module-NAME`
3. ReportMate validates the repository structure
4. Module becomes available for installation

### 4. Installation Process

1. **Repository Validation**: Check for valid `manifest.json` and structure
2. **Security Scan**: Basic static analysis and permission validation
3. **Dependency Resolution**: Check for required dependencies
4. **Download**: Fetch module files from the repository
5. **Integration**: Load module into ReportMate runtime
6. **Activation**: Enable module widgets and functionality

### 5. Module Sources

ReportMate checks multiple sources for modules:

```typescript
const moduleSources = [
  'https://registry.reportmate.com/modules',           // Central registry
  'https://github.com/reportmate/reportmate-module-*', // Official modules
  ...userAddedRepositories                             // Custom repositories
]
```

## Security Considerations

### Module Validation

- **Code Analysis**: Basic static analysis for dangerous patterns
- **Checksum Verification**: SHA-256 checksums for integrity
- **Permission System**: Modules declare required permissions
- **Sandboxing**: Modules run in isolated contexts

### Repository Trust Levels

1. **Official**: Maintained by ReportMate team
2. **Verified**: Community modules that have been reviewed
3. **Community**: Unverified community contributions
4. **Custom**: User-added repositories

## Module Development Guidelines

### Best Practices

1. **Security First**: Never use `eval()`, `innerHTML`, or other dangerous APIs
2. **Performance**: Modules should be lightweight and efficient
3. **Compatibility**: Follow semantic versioning and declare dependencies
4. **Documentation**: Provide clear README and inline documentation
5. **Testing**: Include unit tests for module functionality

### Widget Guidelines

1. **Responsive Design**: Widgets should work on all screen sizes
2. **Dark Mode**: Support both light and dark themes
3. **Loading States**: Show loading indicators for async operations
4. **Error Handling**: Gracefully handle and display errors
5. **Configuration**: Use the config schema for user customization

## Example Official Modules

Here are examples of official modules that would be created as separate repositories:

### reportmate-module-hardware
- **Repository**: `https://github.com/reportmate/reportmate-module-hardware`
- **Purpose**: Advanced hardware monitoring, temperature alerts, disk health
- **Widgets**: CPU Temperature, Memory Usage, Disk Health, Fan Speed

### reportmate-module-security  
- **Repository**: `https://github.com/reportmate/reportmate-module-security`
- **Purpose**: Security compliance monitoring, vulnerability scanning
- **Widgets**: Security Score, Patch Status, Firewall Status, Antivirus Status

### reportmate-module-network
- **Repository**: `https://github.com/reportmate/reportmate-module-network`
- **Purpose**: Network diagnostics, connectivity monitoring
- **Widgets**: Network Interfaces, WiFi Status, VPN Status, Bandwidth Usage

### reportmate-module-mdm
- **Repository**: `https://github.com/reportmate/reportmate-module-mdm`
- **Purpose**: MDM integration, policy compliance
- **Widgets**: Profile Status, Certificate Status, App Restrictions

## Community Module Examples

### reportmate-module-jamf-pro (3rd Party)
- **Repository**: `https://github.com/jamf/reportmate-module-jamf-pro`
- **Purpose**: Deep Jamf Pro integration
- **Official**: No (3rd party maintained)

### reportmate-module-munki-legacy (Community)
- **Repository**: `https://github.com/munkitools/reportmate-module-munki-legacy`
- **Purpose**: Legacy Munki compatibility layer
- **Official**: No (community maintained)

## Integration with Container/WebPubSub Architecture

The modular system is designed to work seamlessly with ReportMate's modern container and WebPubSub architecture:

### Module Loading Process

1. **Discovery**: Frontend scans GitHub for `reportmate-module-*` repositories
2. **Validation**: Module manifests are validated for security and compatibility
3. **Installation**: Module code is fetched and loaded dynamically
4. **Registration**: Modules register their widgets, data providers, and event processors
5. **Real-time Updates**: Modules can subscribe to WebPubSub events for live data

### WebPubSub Integration

Modules can subscribe to real-time events:

```javascript
// Example from reportmate-module-hardware
export default {
  manifest: { /* ... */ },
  
  onEnable() {
    // Subscribe to hardware events
    this.webPubSubClient.subscribe('hardware.temperature', (data) => {
      this.updateTemperatureWidget(data)
    })
  },
  
  widgets: [
    {
      id: 'cpu-temperature',
      component: CPUTemperatureWidget,
      refreshInterval: 30000 // Fallback to polling
    }
  ]
}
```

### Container Deployment

Each module can include:
- **Frontend Components**: React widgets loaded dynamically
- **Backend Functions**: Optional Azure Functions for data processing
- **Database Schemas**: Prisma migrations for module-specific data

## Inspiration from MunkiReport & AutoPkgr

This system draws inspiration from successful modular architectures:

### From MunkiReport:
- **Composer-like Management**: Dynamic installation/removal
- **Repository-based Distribution**: GitHub-hosted modules  
- **Declarative Configuration**: JSON manifests for module metadata
- **Community Ecosystem**: Official and community-maintained modules

### From AutoPkgr:
- **Visual Repository Management**: Check boxes to enable/disable repositories
- **Automatic Discovery**: Scan GitHub organizations for modules
- **Trust Levels**: Official, verified, and community modules
- **One-click Installation**: Simple module installation process

### Modern Enhancements:
- **Real-time Data**: WebPubSub integration for live updates
- **Container-ready**: Designed for containerized deployments
- **React Components**: Modern UI framework instead of PHP
- **TypeScript**: Type safety and better developer experience
