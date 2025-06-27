# 🛠️ ReportMate Development Guide

Complete guide for developing and extending the ReportMate modular architecture.

## 🏗️ Modular Architecture Overview

ReportMate uses a plugin-based modular architecture inspired by MunkiReport, enabling easy extension and customization.

### Architecture Transformation

**Before**: Monolithic device pages with 1000+ lines of hardcoded components
**After**: Widget-based components that can be mixed and matched

### Key Benefits
- ✅ **Reusable Components**: 24+ widgets across 7 modules
- ✅ **Easy Extension**: Plugin system for custom modules
- ✅ **Configurable Layouts**: Dynamic widget arrangements
- ✅ **Separation of Concerns**: Clean data/presentation split
- ✅ **Type Safety**: Full TypeScript support

---

## 🧩 Module System

### Module Types

1. **Core Modules** - Essential system functionality (device info, events)
2. **Widget Modules** - UI components for device views (hardware, software)
3. **Dashboard Modules** - Dashboard widgets and overview components
4. **Data Modules** - Data processors and API integrations
5. **Integration Modules** - Third-party service integrations

### Module Structure

```typescript
export class YourModule extends EnhancedBaseModule {
  readonly manifest: ExtendedModuleManifest = {
    id: 'your-module',
    name: 'Your Module',
    version: '1.0.0',
    description: 'Description of your module',
    
    // Widget definitions
    widgets: [
      {
        id: 'your-widget',
        name: 'Your Widget',
        component: YourWidgetComponent,
        size: 'medium',
        category: 'custom'
      }
    ]
  }
}
```

---

## 🎨 Available Widget Modules

### 1. Hardware Module
**Purpose**: Display hardware specifications and system information

**Widgets**:
- **Hardware Overview** - CPU, memory, storage summary
- **Storage Details** - Disk usage with visual indicators
- **System Information** - Comprehensive hardware specs

**Data Source**: `device.hardware`

### 2. Applications Module
**Purpose**: Display installed applications and statistics

**Widgets**:
- **Applications Overview** - Quick stats (total apps, signed apps, categories)
- **Applications Table** - Detailed searchable table
- **Application Categories** - Visual breakdown by category

**Data Source**: `device.applications.installedApps[]`

### 3. Network Module
**Purpose**: Display network configuration and connectivity

**Widgets**:
- **Network Overview** - Connection type, IP, MAC address
- **Network Details** - Interface configuration, IPv4/IPv6 settings
- **Wireless Details** - SSID, signal strength, wireless card info

**Data Source**: `device.network`, `device.ipAddress`, `device.macAddress`

### 4. Security Module
**Purpose**: Display security status and compliance information

**Widgets**:
- **Security Overview** - FileVault, Firewall, Gatekeeper status
- **System Security** - SIP, Secure Boot, Activation Lock
- **User Access** - SSH users, groups, permissions
- **Security Details** - Comprehensive security status

**Data Source**: `device.security`

### 5. MDM Module
**Purpose**: Display MDM enrollment and management information

**Widgets**:
- **MDM Overview** - Enrollment status and type
- **MDM Details** - Organization info, server details
- **MDM Profiles** - Installed configuration profiles
- **MDM Restrictions** - Device restrictions and policies

**Data Source**: `device.mdm`

### 6. Events Module
**Purpose**: Display device events and activity

**Widgets**:
- **Events Overview** - Summary and statistics
- **Events List** - Complete chronological listing
- **Events Timeline** - Visual timeline with status indicators

**Data Source**: `device.events[]`

### 7. Managed Installs Module
**Purpose**: Display software installation management

**Widgets**:
- **Managed Installs Overview** - Installation statistics
- **Package List** - Detailed package management
- **Installation Issues** - Error and warning tracking

**Data Source**: `device.managedInstalls`

---

## 🔧 Creating Custom Widgets

### Step 1: Widget Component

```typescript
import React, { useState, useEffect } from 'react'
import { DeviceWidgetProps } from '../ModuleRegistry'

const YourWidget: React.FC<DeviceWidgetProps> = ({ 
  deviceId, 
  onToggleExpand 
}) => {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(`/api/device/${deviceId}/your-data`)
        const result = await response.json()
        setData(result)
      } catch (err) {
        setError('Failed to load data')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [deviceId])

  if (loading) {
    return (
      <div className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2 mb-2"></div>
          <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow border-l-4 border-red-500">
        <p className="text-red-600 dark:text-red-400">{error}</p>
      </div>
    )
  }

  return (
    <div className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          Your Widget Title
        </h3>
      </div>
      
      <div className="space-y-2">
        {/* Your widget content */}
        {data && (
          <div className="text-sm text-gray-600 dark:text-gray-300">
            {/* Render your data */}
          </div>
        )}
      </div>
    </div>
  )
}

export default YourWidget
```

### Step 2: Module Definition

```typescript
import { EnhancedBaseModule, ExtendedModuleManifest } from '../EnhancedModule'
import YourWidget from './YourWidget'

export class YourModule extends EnhancedBaseModule {
  readonly manifest: ExtendedModuleManifest = {
    id: 'your-module',
    name: 'Your Module',
    version: '1.0.0',
    description: 'Your custom module description',
    author: 'Your Name',
    
    widgets: [
      {
        id: 'your-widget',
        name: 'Your Widget',
        description: 'Description of your widget',
        component: YourWidget,
        size: 'medium',
        category: 'custom',
        
        // Conditional display
        conditions: [
          {
            field: 'device.yourData',
            operator: 'exists'
          }
        ]
      }
    ],
    
    // Configuration schema
    configSchema: {
      title: 'Your Module Settings',
      type: 'object',
      properties: {
        showAdvancedFeatures: {
          type: 'boolean',
          title: 'Show Advanced Features',
          default: false
        },
        refreshInterval: {
          type: 'number',
          title: 'Refresh Interval (seconds)',
          default: 30,
          minimum: 5
        }
      }
    }
  }

  async onLoad(): Promise<void> {
    this.log('info', 'Your module loaded successfully')
  }

  async fetchDeviceData(deviceId: string, endpoint: string): Promise<any> {
    try {
      const response = await fetch(`/api/device/${deviceId}/${endpoint}`)
      return await response.json()
    } catch (error) {
      this.log('error', 'Failed to fetch device data:', error)
      throw error
    }
  }
}
```

### Step 3: Register Module

Add your module to `src/lib/modules/ModuleInit.ts`:

```typescript
import { YourModule } from './widgets/YourModule'

// Register modules
export const availableModules = [
  // ...existing modules...
  new YourModule()
]
```

---

## 🎛️ Widget Configuration

### Widget Sizes

- **small** - 1 column width, minimal content
- **medium** - 1 column width, standard content  
- **large** - 2 columns width, detailed content
- **full** - Full row width, tables or complex layouts

### Widget Categories

- **overview** - Basic device information and status
- **hardware** - CPU, memory, storage, etc.
- **software** - Applications, updates, packages
- **security** - Security status, compliance, certificates
- **network** - Network interfaces, connectivity, VPN
- **custom** - Custom functionality

### Conditional Display

```typescript
conditions: [
  {
    field: 'device.os.type',
    operator: 'equals',
    value: 'macOS'
  },
  {
    field: 'device.hardware.cpu',
    operator: 'exists'
  },
  {
    field: 'device.applications.count',
    operator: 'greaterThan',
    value: 0
  }
]
```

---

## 🔌 Data Integration

### API Endpoints

Create endpoints for your widget data:

```typescript
// pages/api/device/[deviceId]/your-data.ts
import { NextApiRequest, NextApiResponse } from 'next'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { deviceId } = req.query

  try {
    // Fetch data from your data source
    const data = await fetchYourData(deviceId as string)
    
    res.status(200).json(data)
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch data' })
  }
}
```

### Data Providers

Register data providers in your module:

```typescript
dataProviders: [
  {
    id: 'your-data-provider',
    endpoint: '/api/your-endpoint',
    method: 'GET',
    cacheTtl: 300 // 5 minutes
  }
]
```

### Event Processors

Handle system events:

```typescript
eventProcessors: [
  {
    eventType: 'device.your-event',
    processor: async (event, context) => {
      // Process your event
      this.log('info', 'Processing your event:', event)
    }
  }
]
```

---

## 🎨 UI Best Practices

### 1. Responsive Design

Use Tailwind classes for responsive layouts:

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Your content */}
</div>
```

### 2. Dark Mode Support

Always include dark mode classes:

```typescript
<div className="bg-white dark:bg-gray-800 text-gray-900 dark:text-white">
  {/* Your content */}
</div>
```

### 3. Loading States

Provide loading indicators:

```typescript
if (loading) {
  return (
    <div className="animate-pulse">
      <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
      <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded"></div>
    </div>
  )
}
```

### 4. Error Handling

Handle errors gracefully:

```typescript
if (error) {
  return (
    <div className="border-l-4 border-red-500 bg-red-50 dark:bg-red-900/20 p-4">
      <p className="text-red-600 dark:text-red-400">{error}</p>
    </div>
  )
}
```

### 5. Empty States

Handle cases where no data is available:

```typescript
if (!data || data.length === 0) {
  return (
    <div className="text-center py-8 text-gray-500 dark:text-gray-400">
      <p>No data available</p>
    </div>
  )
}
```

---

## 🧪 Testing Modules

### Unit Testing

```typescript
import { render, screen } from '@testing-library/react'
import YourWidget from './YourWidget'

describe('YourWidget', () => {
  it('renders widget content', () => {
    render(<YourWidget deviceId="test-device" />)
    expect(screen.getByText('Your Widget Title')).toBeInTheDocument()
  })

  it('handles loading state', () => {
    render(<YourWidget deviceId="test-device" />)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })
})
```

### Integration Testing

```typescript
import { YourModule } from './YourModule'

describe('YourModule', () => {
  let module: YourModule

  beforeEach(() => {
    module = new YourModule()
  })

  it('loads successfully', async () => {
    await module.onLoad()
    expect(module.manifest.id).toBe('your-module')
  })

  it('fetches device data', async () => {
    const data = await module.fetchDeviceData('test-device', 'test-endpoint')
    expect(data).toBeDefined()
  })
})
```

---

## 🚀 Development Workflow

### 1. Setup Development Environment

```bash
# Clone repository
git clone <repo-url>
cd ReportMate

# Install dependencies
cd apps/www
pnpm install

# Start development server
pnpm dev
```

### 2. Create New Module

```bash
# Create module file
touch src/lib/modules/widgets/YourModule.tsx

# Add to module registry
# Edit src/lib/modules/ModuleInit.ts
```

### 3. Test Module

```bash
# Run tests
pnpm test

# Test in browser
open http://localhost:3000/device-new/test-device
```

### 4. Build and Deploy

```bash
# Build application
pnpm build

# Deploy to staging
git push origin develop

# Deploy to production  
git push origin main
```

---

## 📊 Module Performance

### Optimization Tips

1. **Lazy Loading**: Load widgets only when needed
2. **Memoization**: Use React.memo for expensive components
3. **Data Caching**: Cache API responses appropriately
4. **Bundle Splitting**: Keep modules in separate chunks

### Performance Monitoring

```typescript
// Add performance tracking
const startTime = performance.now()
// Your widget logic
const endTime = performance.now()
console.log(`Widget rendered in ${endTime - startTime}ms`)
```

---

## 🤝 Contributing Modules

### Module Guidelines

1. **Follow TypeScript conventions**
2. **Include comprehensive tests**
3. **Document all props and APIs**
4. **Support both light and dark themes**
5. **Handle loading and error states**
6. **Use consistent naming conventions**

### Submission Process

1. **Fork** the repository
2. **Create** feature branch: `feature/your-module`
3. **Develop** module with tests
4. **Document** functionality
5. **Submit** pull request with examples

---

## 📚 API Reference

### ModuleRegistry

```typescript
interface DeviceWidgetProps {
  deviceId: string
  onToggleExpand?: () => void
  config?: Record<string, any>
}

interface WidgetDefinition {
  id: string
  name: string
  description?: string
  component: React.ComponentType<DeviceWidgetProps>
  size: 'small' | 'medium' | 'large' | 'full'
  category: string
  conditions?: WidgetCondition[]
}
```

### EnhancedModule

```typescript
abstract class EnhancedBaseModule {
  abstract readonly manifest: ExtendedModuleManifest
  
  async onLoad(): Promise<void>
  async fetchDeviceData(deviceId: string, endpoint: string): Promise<any>
  log(level: 'info' | 'warn' | 'error', message: string, ...args: any[]): void
}
```

---

**Your modular architecture is ready for unlimited extensibility!** 🎉

The widget system provides a clean, powerful foundation for building custom device management interfaces.
