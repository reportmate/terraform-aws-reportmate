# Seemianki Module Development Guide

## Overview

Seemianki uses a modular architecture inspired by MunkiReport, allowing for easy extension and customization of functionality. This guide will help you create your own modules.

## Architecture

### Module Types

1. **Core Modules** - Essential system functionality (device info, events)
2. **Widget Modules** - UI components for device views (hardware, software)
3. **Dashboard Modules** - Dashboard widgets and overview components
4. **Data Modules** - Data processors and API integrations
5. **Integration Modules** - Third-party service integrations

### Module Structure

```typescript
// Basic module structure
export class YourModule extends EnhancedBaseModule {
  readonly manifest: ExtendedModuleManifest = {
    id: 'your-module-id',
    name: 'Your Module Name',
    version: '1.0.0',
    description: 'What your module does',
    author: 'Your Name',
    enabled: true,
    category: 'device', // or 'dashboard', 'integration', etc.
    
    // Define what your module provides
    deviceWidgets: [...],
    dashboardWidgets: [...],
    deviceTabs: [...],
    
    // Configuration schema
    configSchema: {...}
  }
  
  async onLoad(): Promise<void> {
    // Module initialization code
  }
}
```

## Creating Device Widgets

Device widgets are the building blocks of the modular device page. Here's how to create them:

### 1. Widget Component

```typescript
const YourWidget: React.FC<DeviceWidgetProps> = ({ 
  deviceId, 
  device, 
  isExpanded, 
  onToggleExpand 
}) => {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Fetch data for your widget
    const fetchData = async () => {
      try {
        const response = await fetch(`/api/device/${deviceId}/your-endpoint`)
        const result = await response.json()
        setData(result.data)
      } catch (error) {
        console.error('Failed to fetch data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [deviceId])

  if (loading) {
    return <LoadingSpinner />
  }

  return (
    <div className="p-6">
      {/* Your widget content */}
    </div>
  )
}
```

### 2. Widget Definition

```typescript
{
  id: 'your-widget-id',
  name: 'Your Widget Name',
  description: 'What this widget shows',
  component: YourWidget,
  category: 'hardware', // or 'software', 'security', 'network', 'overview', 'custom'
  size: 'medium', // 'small', 'medium', 'large', 'full'
  order: 10, // Display order
  conditions: [
    {
      type: 'device_os',
      operator: 'contains',
      value: 'macOS' // Only show for macOS devices
    }
  ],
  refreshInterval: 60, // Auto-refresh every 60 seconds
  supportsExport: true,
  configurable: true
}
```

## Widget Categories

- **overview** - Basic device information and status
- **hardware** - CPU, memory, storage, etc.
- **software** - Applications, updates, packages
- **security** - Security status, compliance, certificates
- **network** - Network interfaces, connectivity, VPN
- **custom** - Custom functionality

## Widget Sizes

- **small** - 1 column width, minimal content
- **medium** - 1 column width, standard content
- **large** - 2 columns width, detailed content  
- **full** - Full row width, tables or complex layouts

## Conditional Display

Widgets can be shown/hidden based on conditions:

```typescript
conditions: [
  {
    type: 'device_os',
    operator: 'contains',
    value: 'Windows' // Only show for Windows devices
  },
  {
    type: 'has_data',
    field: 'managedInstalls', // Only show if device has this data
    operator: 'exists',
    value: true
  },
  {
    type: 'custom',
    customCheck: (device, user) => {
      // Custom logic
      return device.model?.includes('MacBook')
    }
  }
]
```

## Configuration Schema

Allow users to configure your module:

```typescript
configSchema: {
  title: 'Your Module Settings',
  description: 'Configure your module behavior',
  properties: {
    enableFeature: {
      type: 'boolean',
      title: 'Enable Feature',
      description: 'Turn this feature on or off',
      default: true
    },
    threshold: {
      type: 'number',
      title: 'Alert Threshold',
      description: 'When to show alerts',
      default: 80,
      validation: { min: 0, max: 100 }
    },
    mode: {
      type: 'select',
      title: 'Display Mode',
      options: [
        { label: 'Simple', value: 'simple' },
        { label: 'Detailed', value: 'detailed' }
      ],
      default: 'simple'
    }
  }
}
```

## Data Providers

Modules can register data providers for backend integration:

```typescript
dataProviders: [
  {
    id: 'your-data-provider',
    endpoint: '/api/your-endpoint',
    processor: (data) => {
      // Transform raw data
      return processedData
    },
    interval: 30000 // Poll every 30 seconds
  }
]
```

## Event Processors

Handle system events:

```typescript
eventProcessors: [
  {
    id: 'your-event-processor',
    eventTypes: ['device.connected', 'device.updated'],
    processor: (event) => {
      // Handle the event
      console.log('Device event:', event)
    }
  }
]
```

## Module Lifecycle

```typescript
export class YourModule extends EnhancedBaseModule {
  async onLoad(): Promise<void> {
    // Called when module is first loaded
    this.log('info', 'Module loaded')
  }
  
  async onEnable(): Promise<void> {
    // Called when module is enabled
  }
  
  async onDisable(): Promise<void> {
    // Called when module is disabled
  }
  
  async onConfigChange(config: any): Promise<void> {
    // Called when configuration changes
    this.log('info', 'Config updated:', config)
  }
  
  async onUnload(): Promise<void> {
    // Called when module is unloaded
    this.log('info', 'Module unloaded')
  }
}
```

## Best Practices

### 1. Error Handling
Always handle errors gracefully:

```typescript
try {
  const data = await this.fetchDeviceData(deviceId, 'endpoint')
  setData(data)
} catch (error) {
  this.log('error', 'Failed to fetch data:', error)
  setError('Unable to load data')
}
```

### 2. Loading States
Provide loading indicators:

```typescript
if (loading) {
  return (
    <div className="p-6 animate-pulse">
      <div className="h-4 bg-gray-200 rounded w-3/4 mb-4"></div>
      <div className="h-4 bg-gray-200 rounded w-1/2"></div>
    </div>
  )
}
```

### 3. Empty States
Handle cases where no data is available:

```typescript
if (!data || data.length === 0) {
  return (
    <div className="p-6 text-center">
      <div className="text-gray-500 dark:text-gray-400">
        No data available
      </div>
    </div>
  )
}
```

### 4. Responsive Design
Use Tailwind classes for responsive layouts:

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Your content */}
</div>
```

### 5. Dark Mode Support
Always include dark mode classes:

```typescript
<div className="bg-white dark:bg-gray-800 text-gray-900 dark:text-white">
  {/* Your content */}
</div>
```

## Example: Simple CPU Widget

```typescript
import React, { useState, useEffect } from 'react'
import { EnhancedBaseModule, ExtendedModuleManifest } from '../EnhancedModule'
import { DeviceWidgetProps } from '../ModuleRegistry'

const CPUWidget: React.FC<DeviceWidgetProps> = ({ deviceId }) => {
  const [cpuData, setCpuData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchCPUData = async () => {
      try {
        const response = await fetch(`/api/device/${deviceId}/cpu`)
        const data = await response.json()
        setCpuData(data.cpu)
      } catch (error) {
        console.error('Failed to fetch CPU data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchCPUData()
  }, [deviceId])

  if (loading) {
    return (
      <div className="p-6 animate-pulse">
        <div className="h-4 bg-gray-200 rounded w-1/2 mb-4"></div>
        <div className="h-8 bg-gray-200 rounded"></div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <div className="text-center">
        <div className="text-3xl font-bold text-blue-600 dark:text-blue-400">
          {cpuData?.usage || 0}%
        </div>
        <div className="text-sm text-gray-600 dark:text-gray-400">
          CPU Usage
        </div>
        <div className="mt-2 text-xs text-gray-500">
          {cpuData?.name || 'Unknown CPU'}
        </div>
      </div>
    </div>
  )
}

export class CPUModule extends EnhancedBaseModule {
  readonly manifest: ExtendedModuleManifest = {
    id: 'cpu-monitor',
    name: 'CPU Monitor',
    version: '1.0.0',
    description: 'Monitor CPU usage and information',
    author: 'Your Name',
    enabled: true,
    category: 'device',
    
    deviceWidgets: [
      {
        id: 'cpu-usage',
        name: 'CPU Usage',
        description: 'Current CPU usage percentage',
        component: CPUWidget,
        category: 'hardware',
        size: 'small',
        order: 5,
        refreshInterval: 5
      }
    ]
  }

  async onLoad(): Promise<void> {
    this.log('info', 'CPU Monitor module loaded')
  }
}
```

## Testing Your Module

1. **Development Mode**: Set `NODE_ENV=development` to see debug information
2. **Module Registry**: Check the modules page at `/modules` to verify your module is loaded
3. **Device Pages**: Test your widgets on actual device pages
4. **Configuration**: Verify configuration changes work correctly

## Publishing Modules

1. **Package Structure**: Create a proper module package
2. **Documentation**: Include README and examples
3. **Versioning**: Use semantic versioning
4. **Dependencies**: Clearly specify dependencies
5. **Testing**: Include unit tests

## Advanced Features

### Custom Routes
Add custom pages to the application:

```typescript
routes: [
  {
    path: '/your-custom-page',
    component: YourPageComponent,
    exact: true
  }
]
```

### API Endpoints
Register custom API endpoints:

```typescript
apiEndpoints: [
  {
    path: '/api/your-endpoint',
    method: 'GET',
    handler: async (req, res) => {
      // Your API logic
    }
  }
]
```

### Settings Pages
Add module-specific settings:

```typescript
settingsPages: [
  {
    id: 'your-settings',
    name: 'Your Settings',
    component: YourSettingsComponent,
    category: 'integrations'
  }
]
```

This modular architecture allows Seemianki to be easily extended and customized, just like MunkiReport, while providing a modern React-based development experience.
