import { NextResponse } from 'next/server'

// Comprehensive mock device database with 6 devices (3 Macs, 3 Windows)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const deviceDatabase: Record<string, any> = {
  // Mac Device 1 - Marketing Designer
  'JY93C5YGGM': {
    id: 'JY93C5YGGM',
    name: 'Celeste Martin',
    model: 'MacBook Air (15-inch, M2, 2023)',
    os: 'macOS 15.2.0',
    lastSeen: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
    status: 'online',
    uptime: '25 days, 14 hours',
    location: 'Marketing',
    serialNumber: 'JY93C5YGGM',
    assetTag: 'MAC-001',
    ipAddress: '108.172.84.175',
    macAddress: '00:9B:8F:7F:4B:D4',
    totalEvents: 1247,
    lastEventTime: new Date(Date.now() - 1800000).toISOString(),
    
    // System Information
    processor: 'Apple M2 8-Core',
    memory: '16 GB',
    storage: '512 GB SSD',
    graphics: 'Apple M2 10-Core GPU',
    diskUtilization: 68,
    memoryUtilization: 45,
    cpuUtilization: 23,
    temperature: 42,
    batteryLevel: 87,
    bootTime: new Date(Date.now() - 2160000000).toISOString(), // 25 days ago
    
    // Network Information
    networkInterfaces: [
      {
        name: 'Wi-Fi',
        type: 'Wi-Fi',
        status: 'Connected',
        ipAddress: '108.172.84.175',
        macAddress: '00:9B:8F:7F:4B:D4',
        gateway: '108.172.84.1',
        dns: ['8.8.8.8', '8.8.4.4'],
        speed: '1 Gbps'
      },
      {
        name: 'Bluetooth PAN',
        type: 'Bluetooth',
        status: 'Inactive',
        ipAddress: null,
        macAddress: '00:9B:8F:7F:4B:D5',
        gateway: null,
        dns: [],
        speed: null
      }
    ],
    
    // Security Information
    securityFeatures: {
      filevault: { enabled: true, status: 'Encrypted' },
      firewall: { enabled: true, status: 'Active' },
      gatekeeper: { enabled: true, status: 'Active' },
      sip: { enabled: true, status: 'Enabled' },
      xprotect: { enabled: true, status: 'Up to date' },
      automaticUpdates: { enabled: true, status: 'Enabled' }
    },
    
    // Managed Installs (Munki)
    managedInstalls: {
      type: 'Munki',
      lastRun: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      nextRun: new Date(Date.now() + 14400000).toISOString(), // 4 hours from now
      status: 'Success',
      config: {
        munki_repo_url: 'https://munki.company.com/repo',
        client_identifier: 'marketing-mac',
        managed_installs_dir: '/Library/Managed Installs',
        log_file: '/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log',
        install_apple_software_updates: true
      },
      messages: {
        errors: [
          {
            id: 'err-001',
            package: 'Adobe Creative Suite',
            message: 'Installation failed: Insufficient disk space',
            details: 'The installer requires 15 GB of free space, but only 8.2 GB is available.',
            timestamp: new Date(Date.now() - 86400000).toISOString() // 1 day ago
          }
        ],
        warnings: [
          {
            id: 'warn-001',
            package: 'Chrome',
            message: 'Package verification warning',
            details: 'Package signature could not be verified against known certificates.',
            timestamp: new Date(Date.now() - 43200000).toISOString() // 12 hours ago
          }
        ]
      },
      packages: [
        {
          name: 'Google Chrome',
          version: '120.0.6099.109',
          status: 'Installed',
          installDate: new Date(Date.now() - 604800000).toISOString(), // 1 week ago
          size: '245 MB'
        },
        {
          name: 'Adobe Photoshop 2024',
          version: '25.2.0',
          status: 'Installed',
          installDate: new Date(Date.now() - 1209600000).toISOString(), // 2 weeks ago
          size: '3.2 GB'
        },
        {
          name: 'Microsoft Office 365',
          version: '16.80.0',
          status: 'Pending Update',
          installDate: new Date(Date.now() - 2592000000).toISOString(), // 1 month ago
          size: '2.8 GB'
        },
        {
          name: 'Figma Desktop',
          version: '116.15.4',
          status: 'Installed',
          installDate: new Date(Date.now() - 518400000).toISOString(), // 6 days ago
          size: '185 MB'
        }
      ]
    },
    
    // Applications
    applications: [
      {
        name: 'Google Chrome',
        version: '120.0.6099.109',
        bundleId: 'com.google.Chrome',
        path: '/Applications/Google Chrome.app',
        lastOpened: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
        size: '245 MB'
      },
      {
        name: 'Adobe Photoshop 2024',
        version: '25.2.0',
        bundleId: 'com.adobe.Photoshop',
        path: '/Applications/Adobe Photoshop 2024/Adobe Photoshop 2024.app',
        lastOpened: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
        size: '3.2 GB'
      },
      {
        name: 'Figma',
        version: '116.15.4',
        bundleId: 'com.figma.Desktop',
        path: '/Applications/Figma.app',
        lastOpened: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
        size: '185 MB'
      },
      {
        name: 'Slack',
        version: '4.36.134',
        bundleId: 'com.tinyspeck.slackmacgap',
        path: '/Applications/Slack.app',
        lastOpened: new Date(Date.now() - 900000).toISOString(), // 15 minutes ago
        size: '165 MB'
      },
      {
        name: 'Microsoft Word',
        version: '16.80.0',
        bundleId: 'com.microsoft.Word',
        path: '/Applications/Microsoft Word.app',
        lastOpened: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
        size: '1.2 GB'
      }
    ]
  },

  // Mac Device 2 - Software Developer
  'FVFXQ2P3JM': {
    id: 'FVFXQ2P3JM',
    name: 'Alex Chen',
    model: 'MacBook Pro (16-inch, M3 Pro, 2023)',
    os: 'macOS 15.2.0',
    lastSeen: new Date(Date.now() - 900000).toISOString(), // 15 minutes ago
    status: 'online',
    uptime: '12 days, 8 hours',
    location: 'Engineering',
    serialNumber: 'FVFXQ2P3JM',
    assetTag: 'MAC-002',
    ipAddress: '192.168.1.142',
    macAddress: '14:7D:DA:8C:9A:2B',
    totalEvents: 2134,
    lastEventTime: new Date(Date.now() - 900000).toISOString(),
    
    processor: 'Apple M3 Pro 12-Core',
    memory: '32 GB',
    storage: '1 TB SSD',
    graphics: 'Apple M3 Pro 18-Core GPU',
    diskUtilization: 52,
    memoryUtilization: 68,
    cpuUtilization: 41,
    temperature: 48,
    batteryLevel: 76,
    bootTime: new Date(Date.now() - 1036800000).toISOString(), // 12 days ago
    
    networkInterfaces: [
      {
        name: 'Wi-Fi',
        type: 'Wi-Fi',
        status: 'Connected',
        ipAddress: '192.168.1.142',
        macAddress: '14:7D:DA:8C:9A:2B',
        gateway: '192.168.1.1',
        dns: ['1.1.1.1', '1.0.0.1'],
        speed: '1 Gbps'
      },
      {
        name: 'Thunderbolt Ethernet',
        type: 'Ethernet',
        status: 'Inactive',
        ipAddress: null,
        macAddress: '14:7D:DA:8C:9A:2C',
        gateway: null,
        dns: [],
        speed: null
      }
    ],
    
    securityFeatures: {
      filevault: { enabled: true, status: 'Encrypted' },
      firewall: { enabled: true, status: 'Active' },
      gatekeeper: { enabled: true, status: 'Active' },
      sip: { enabled: false, status: 'Disabled' },
      xprotect: { enabled: true, status: 'Up to date' },
      automaticUpdates: { enabled: false, status: 'Disabled' }
    },
    
    managedInstalls: {
      type: 'Munki',
      lastRun: new Date(Date.now() - 10800000).toISOString(), // 3 hours ago
      nextRun: new Date(Date.now() + 10800000).toISOString(), // 3 hours from now
      status: 'Warning',
      config: {
        munki_repo_url: 'https://munki.company.com/repo',
        client_identifier: 'engineering-mac',
        managed_installs_dir: '/Library/Managed Installs',
        log_file: '/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log',
        install_apple_software_updates: false
      },
      messages: {
        errors: [],
        warnings: [
          {
            id: 'warn-002',
            package: 'Xcode Command Line Tools',
            message: 'Version mismatch detected',
            details: 'Expected version 15.1.0, but found 15.0.0. This may cause compatibility issues.',
            timestamp: new Date(Date.now() - 21600000).toISOString() // 6 hours ago
          },
          {
            id: 'warn-003',
            package: 'Docker Desktop',
            message: 'Resource usage warning',
            details: 'Docker is consuming more than 8GB of memory. Consider adjusting container limits.',
            timestamp: new Date(Date.now() - 7200000).toISOString() // 2 hours ago
          }
        ]
      },
      packages: [
        {
          name: 'Visual Studio Code',
          version: '1.85.2',
          status: 'Installed',
          installDate: new Date(Date.now() - 2628000000).toISOString(), // 1 month ago
          size: '312 MB'
        },
        {
          name: 'Docker Desktop',
          version: '4.26.1',
          status: 'Installed',
          installDate: new Date(Date.now() - 1209600000).toISOString(), // 2 weeks ago
          size: '1.8 GB'
        },
        {
          name: 'Node.js LTS',
          version: '20.10.0',
          status: 'Installed',
          installDate: new Date(Date.now() - 604800000).toISOString(), // 1 week ago
          size: '67 MB'
        },
        {
          name: 'Xcode',
          version: '15.1.0',
          status: 'Pending Update',
          installDate: new Date(Date.now() - 5184000000).toISOString(), // 2 months ago
          size: '12.8 GB'
        }
      ]
    },
    
    applications: [
      {
        name: 'Visual Studio Code',
        version: '1.85.2',
        bundleId: 'com.microsoft.VSCode',
        path: '/Applications/Visual Studio Code.app',
        lastOpened: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
        size: '312 MB'
      },
      {
        name: 'Docker Desktop',
        version: '4.26.1',
        bundleId: 'com.docker.docker',
        path: '/Applications/Docker.app',
        lastOpened: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
        size: '1.8 GB'
      },
      {
        name: 'Terminal',
        version: '2.14',
        bundleId: 'com.apple.Terminal',
        path: '/System/Applications/Utilities/Terminal.app',
        lastOpened: new Date(Date.now() - 600000).toISOString(), // 10 minutes ago
        size: '18 MB'
      },
      {
        name: 'GitHub Desktop',
        version: '3.3.8',
        bundleId: 'com.github.GitHubClient',
        path: '/Applications/GitHub Desktop.app',
        lastOpened: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
        size: '145 MB'
      }
    ]
  },

  // Mac Device 3 - Executive Assistant
  'C02ZK8WVLVDQ': {
    id: 'C02ZK8WVLVDQ',
    name: 'Sarah Johnson',
    model: 'iMac (24-inch, M1, 2021)',
    os: 'macOS 15.1.0',
    lastSeen: new Date(Date.now() - 43200000).toISOString(), // 12 hours ago
    status: 'offline',
    uptime: '0 days',
    location: 'Executive Office',
    serialNumber: 'C02ZK8WVLVDQ',
    ipAddress: '192.168.1.89',
    macAddress: 'A4:83:E7:2C:45:8A',
    totalEvents: 567,
    lastEventTime: new Date(Date.now() - 43200000).toISOString(),
    
    processor: 'Apple M1 8-Core',
    memory: '16 GB',
    storage: '512 GB SSD',
    graphics: 'Apple M1 8-Core GPU',
    diskUtilization: 34,
    memoryUtilization: 0,
    cpuUtilization: 0,
    temperature: 28,
    batteryLevel: null, // Desktop
    bootTime: new Date(Date.now() - 43200000).toISOString(),
    
    networkInterfaces: [
      {
        name: 'Ethernet',
        type: 'Ethernet',
        status: 'Inactive',
        ipAddress: null,
        macAddress: 'A4:83:E7:2C:45:8A',
        gateway: null,
        dns: [],
        speed: null
      },
      {
        name: 'Wi-Fi',
        type: 'Wi-Fi',
        status: 'Inactive',
        ipAddress: null,
        macAddress: 'A4:83:E7:2C:45:8B',
        gateway: null,
        dns: [],
        speed: null
      }
    ],
    
    securityFeatures: {
      filevault: { enabled: true, status: 'Encrypted' },
      firewall: { enabled: true, status: 'Inactive' },
      gatekeeper: { enabled: true, status: 'Active' },
      sip: { enabled: true, status: 'Enabled' },
      xprotect: { enabled: true, status: 'Outdated' },
      automaticUpdates: { enabled: true, status: 'Enabled' }
    },
    
    managedInstalls: {
      type: 'Munki',
      lastRun: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
      nextRun: new Date(Date.now() + 43200000).toISOString(), // 12 hours from now
      status: 'Error',
      config: {
        munki_repo_url: 'https://munki.company.com/repo',
        client_identifier: 'executive-mac',
        managed_installs_dir: '/Library/Managed Installs',
        log_file: '/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log',
        install_apple_software_updates: true
      },
      messages: {
        errors: [
          {
            id: 'err-002',
            package: 'System Update',
            message: 'Network timeout during download',
            details: 'Failed to download macOS 15.2.0 update. Connection timed out after 30 seconds.',
            timestamp: new Date(Date.now() - 86400000).toISOString() // 1 day ago
          }
        ],
        warnings: []
      },
      packages: [
        {
          name: 'Microsoft Office 365',
          version: '16.79.0',
          status: 'Installed',
          installDate: new Date(Date.now() - 5184000000).toISOString(), // 2 months ago
          size: '2.8 GB'
        },
        {
          name: 'Zoom',
          version: '5.16.10',
          status: 'Installed',
          installDate: new Date(Date.now() - 1209600000).toISOString(), // 2 weeks ago
          size: '198 MB'
        },
        {
          name: 'Calendar Sync Tool',
          version: '2.4.1',
          status: 'Failed',
          installDate: null,
          size: '45 MB'
        }
      ]
    },
    
    applications: [
      {
        name: 'Microsoft Outlook',
        version: '16.79.0',
        bundleId: 'com.microsoft.Outlook',
        path: '/Applications/Microsoft Outlook.app',
        lastOpened: new Date(Date.now() - 43200000).toISOString(), // 12 hours ago
        size: '1.1 GB'
      },
      {
        name: 'Calendar',
        version: '14.0',
        bundleId: 'com.apple.iCal',
        path: '/System/Applications/Calendar.app',
        lastOpened: new Date(Date.now() - 43200000).toISOString(), // 12 hours ago
        size: '25 MB'
      },
      {
        name: 'Zoom',
        version: '5.16.10',
        bundleId: 'us.zoom.xos',
        path: '/Applications/zoom.us.app',
        lastOpened: new Date(Date.now() - 46800000).toISOString(), // 13 hours ago
        size: '198 MB'
      }
    ]
  },

  // Windows Device 1 - Accounting Manager
  'WS-ACC-001': {
    id: 'WS-ACC-001',
    name: 'Jennifer Davis',
    model: 'Dell OptiPlex 7090',
    os: 'Windows 11 Pro 23H2 (Build 22631.2861)',
    lastSeen: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
    status: 'warning',
    uptime: '5 days, 16 hours',
    location: 'Accounting',
    serialNumber: 'WS-ACC-001',
    assetTag: 'WIN-001',
    ipAddress: '192.168.1.156',
    macAddress: '00:0C:29:8F:A2:B4',
    totalEvents: 1089,
    lastEventTime: new Date(Date.now() - 3600000).toISOString(),
    
    processor: 'Intel Core i7-11700 @ 2.50GHz',
    memory: '32 GB DDR4',
    storage: '1 TB NVMe SSD',
    graphics: 'Intel UHD Graphics 750',
    diskUtilization: 78,
    memoryUtilization: 52,
    cpuUtilization: 15,
    temperature: 58,
    batteryLevel: null, // Desktop
    bootTime: new Date(Date.now() - 486400000).toISOString(), // 5 days ago
    
    networkInterfaces: [
      {
        name: 'Ethernet',
        type: 'Ethernet',
        status: 'Connected',
        ipAddress: '192.168.1.156',
        macAddress: '00:0C:29:8F:A2:B4',
        gateway: '192.168.1.1',
        dns: ['192.168.1.10', '8.8.8.8'],
        speed: '1 Gbps'
      },
      {
        name: 'Wi-Fi',
        type: 'Wi-Fi',
        status: 'Inactive',
        ipAddress: null,
        macAddress: '00:0C:29:8F:A2:B5',
        gateway: null,
        dns: [],
        speed: null
      }
    ],
    
    securityFeatures: {
      bitlocker: { enabled: true, status: 'Encrypted' },
      windowsDefender: { enabled: true, status: 'Active' },
      firewall: { enabled: true, status: 'Active' },
      uac: { enabled: true, status: 'Enabled' },
      windowsUpdates: { enabled: true, status: 'Up to date' },
      smartScreen: { enabled: true, status: 'Active' }
    },
    
    managedInstalls: {
      type: 'Cimian',
      lastRun: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
      nextRun: new Date(Date.now() + 7200000).toISOString(), // 2 hours from now
      status: 'Warning',
      config: {
        cimian_server_url: 'https://cimian.company.com/api',
        client_identifier: 'accounting-ws',
        managed_installs_dir: 'C:\\ProgramData\\Cimian\\ManagedInstalls',
        log_file: 'C:\\ProgramData\\Cimian\\Logs\\CimianAgent.log',
        install_windows_updates: true
      },
      messages: {
        errors: [],
        warnings: [
          {
            id: 'warn-004',
            package: 'QuickBooks Enterprise',
            message: 'License expiration warning',
            details: 'QuickBooks Enterprise license will expire in 15 days. Please contact IT to renew.',
            timestamp: new Date(Date.now() - 86400000).toISOString() // 1 day ago
          }
        ]
      },
      packages: [
        {
          name: 'Microsoft Office 365',
          version: '16.0.17029.20108',
          status: 'Installed',
          installDate: new Date(Date.now() - 2628000000).toISOString(), // 1 month ago
          size: '3.2 GB'
        },
        {
          name: 'QuickBooks Enterprise',
          version: '23.0.8',
          status: 'Installed',
          installDate: new Date(Date.now() - 5184000000).toISOString(), // 2 months ago
          size: '1.8 GB'
        },
        {
          name: 'Adobe Acrobat Pro DC',
          version: '2023.008.20458',
          status: 'Pending Update',
          installDate: new Date(Date.now() - 2628000000).toISOString(), // 1 month ago
          size: '2.1 GB'
        },
        {
          name: 'Chrome Enterprise',
          version: '120.0.6099.129',
          status: 'Installed',
          installDate: new Date(Date.now() - 604800000).toISOString(), // 1 week ago
          size: '285 MB'
        }
      ]
    },
    
    applications: [
      {
        name: 'Microsoft Excel',
        version: '16.0.17029.20108',
        bundleId: 'Microsoft.Office.Excel',
        path: 'C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE',
        lastOpened: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
        size: '45 MB'
      },
      {
        name: 'QuickBooks Enterprise',
        version: '23.0.8',
        bundleId: 'Intuit.QuickBooks.Enterprise',
        path: 'C:\\Program Files\\Intuit\\QuickBooks Enterprise Solutions 23.0\\QBW.exe',
        lastOpened: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
        size: '1.8 GB'
      },
      {
        name: 'Adobe Acrobat Pro DC',
        version: '2023.008.20458',
        bundleId: 'Adobe.Acrobat.Pro.DC',
        path: 'C:\\Program Files\\Adobe\\Acrobat DC\\Acrobat\\Acrobat.exe',
        lastOpened: new Date(Date.now() - 21600000).toISOString(), // 6 hours ago
        size: '2.1 GB'
      },
      {
        name: 'Google Chrome',
        version: '120.0.6099.129',
        bundleId: 'Google.Chrome',
        path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
        lastOpened: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
        size: '285 MB'
      }
    ]
  },

  // Windows Device 2 - Sales Representative
  'LT-SAL-007': {
    id: 'LT-SAL-007',
    name: 'Marcus Thompson',
    model: 'Lenovo ThinkPad X1 Carbon Gen 11',
    os: 'Windows 11 Pro 23H2 (Build 22631.2861)',
    lastSeen: new Date(Date.now() - 600000).toISOString(), // 10 minutes ago
    status: 'online',
    uptime: '18 days, 4 hours',
    location: 'Sales',
    serialNumber: 'LT-SAL-007',
    assetTag: 'WIN-002',
    ipAddress: '10.0.2.47',
    macAddress: '48:2A:E3:4F:7D:C1',
    totalEvents: 1756,
    lastEventTime: new Date(Date.now() - 600000).toISOString(),
    
    processor: 'Intel Core i7-1365U @ 1.30GHz',
    memory: '16 GB LPDDR5',
    storage: '512 GB NVMe SSD',
    graphics: 'Intel Iris Xe Graphics',
    diskUtilization: 45,
    memoryUtilization: 38,
    cpuUtilization: 22,
    temperature: 51,
    batteryLevel: 68,
    bootTime: new Date(Date.now() - 1555200000).toISOString(), // 18 days ago
    
    networkInterfaces: [
      {
        name: 'Wi-Fi',
        type: 'Wi-Fi',
        status: 'Connected',
        ipAddress: '10.0.2.47',
        macAddress: '48:2A:E3:4F:7D:C1',
        gateway: '10.0.2.1',
        dns: ['10.0.1.10', '1.1.1.1'],
        speed: '802.11ax (600 Mbps)'
      },
      {
        name: 'Ethernet',
        type: 'Ethernet',
        status: 'Inactive',
        ipAddress: null,
        macAddress: '48:2A:E3:4F:7D:C2',
        gateway: null,
        dns: [],
        speed: null
      }
    ],
    
    securityFeatures: {
      bitlocker: { enabled: true, status: 'Encrypted' },
      windowsDefender: { enabled: true, status: 'Active' },
      firewall: { enabled: true, status: 'Active' },
      uac: { enabled: true, status: 'Enabled' },
      windowsUpdates: { enabled: true, status: 'Up to date' },
      smartScreen: { enabled: true, status: 'Active' }
    },
    
    managedInstalls: {
      type: 'Cimian',
      lastRun: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
      nextRun: new Date(Date.now() + 12600000).toISOString(), // 3.5 hours from now
      status: 'Success',
      config: {
        cimian_server_url: 'https://cimian.company.com/api',
        client_identifier: 'sales-laptop',
        managed_installs_dir: 'C:\\ProgramData\\Cimian\\ManagedInstalls',
        log_file: 'C:\\ProgramData\\Cimian\\Logs\\CimianAgent.log',
        install_windows_updates: true
      },
      messages: {
        errors: [],
        warnings: []
      },
      packages: [
        {
          name: 'Microsoft Office 365',
          version: '16.0.17029.20108',
          status: 'Installed',
          installDate: new Date(Date.now() - 1555200000).toISOString(), // 18 days ago
          size: '3.2 GB'
        },
        {
          name: 'Salesforce Desktop',
          version: '58.4.0',
          status: 'Installed',
          installDate: new Date(Date.now() - 1209600000).toISOString(), // 2 weeks ago
          size: '145 MB'
        },
        {
          name: 'Microsoft Teams',
          version: '1.6.00.32562',
          status: 'Installed',
          installDate: new Date(Date.now() - 2628000000).toISOString(), // 1 month ago
          size: '312 MB'
        },
        {
          name: 'Zoom Client',
          version: '5.16.10.24060',
          status: 'Installed',
          installDate: new Date(Date.now() - 604800000).toISOString(), // 1 week ago
          size: '165 MB'
        }
      ]
    },
    
    applications: [
      {
        name: 'Microsoft Outlook',
        version: '16.0.17029.20108',
        bundleId: 'Microsoft.Office.Outlook',
        path: 'C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE',
        lastOpened: new Date(Date.now() - 900000).toISOString(), // 15 minutes ago
        size: '52 MB'
      },
      {
        name: 'Salesforce Desktop',
        version: '58.4.0',
        bundleId: 'Salesforce.Desktop',
        path: 'C:\\Users\\marcus.thompson\\AppData\\Local\\Programs\\SalesforceDesktop\\Salesforce.exe',
        lastOpened: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
        size: '145 MB'
      },
      {
        name: 'Microsoft Teams',
        version: '1.6.00.32562',
        bundleId: 'Microsoft.Teams',
        path: 'C:\\Users\\marcus.thompson\\AppData\\Local\\Microsoft\\Teams\\current\\Teams.exe',
        lastOpened: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
        size: '312 MB'
      },
      {
        name: 'Google Chrome',
        version: '120.0.6099.129',
        bundleId: 'Google.Chrome',
        path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
        lastOpened: new Date(Date.now() - 600000).toISOString(), // 10 minutes ago
        size: '285 MB'
      }
    ]
  },

  // Windows Device 3 - IT Technician
  'WS-IT-003': {
    id: 'WS-IT-003',
    name: 'Ryan Martinez',
    model: 'HP Z4 G5 Workstation',
    os: 'Windows 11 Pro 23H2 (Build 22631.2861)',
    lastSeen: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
    status: 'warning',
    uptime: '3 days, 22 hours',
    location: 'IT Department',
    serialNumber: 'WS-IT-003',
    assetTag: 'WIN-003',
    ipAddress: '192.168.1.203',
    macAddress: '94:C6:91:1A:2F:8E',
    totalEvents: 2945,
    lastEventTime: new Date(Date.now() - 7200000).toISOString(),
    
    processor: 'Intel Xeon W-2245 @ 3.90GHz',
    memory: '64 GB DDR4 ECC',
    storage: '2 TB NVMe SSD',
    graphics: 'NVIDIA Quadro RTX 4000',
    diskUtilization: 63,
    memoryUtilization: 71,
    cpuUtilization: 35,
    temperature: 62,
    batteryLevel: null, // Desktop workstation
    bootTime: new Date(Date.now() - 340800000).toISOString(), // 3 days ago
    
    networkInterfaces: [
      {
        name: 'Ethernet',
        type: 'Ethernet',
        status: 'Connected',
        ipAddress: '192.168.1.203',
        macAddress: '94:C6:91:1A:2F:8E',
        gateway: '192.168.1.1',
        dns: ['192.168.1.10', '192.168.1.11'],
        speed: '1 Gbps'
      },
      {
        name: 'Management Interface',
        type: 'Ethernet',
        status: 'Connected',
        ipAddress: '192.168.100.203',
        macAddress: '94:C6:91:1A:2F:8F',
        gateway: '192.168.100.1',
        dns: ['192.168.100.10'],
        speed: '100 Mbps'
      }
    ],
    
    securityFeatures: {
      bitlocker: { enabled: true, status: 'Encrypted' },
      windowsDefender: { enabled: false, status: 'Disabled' },
      firewall: { enabled: true, status: 'Active' },
      uac: { enabled: false, status: 'Disabled' },
      windowsUpdates: { enabled: false, status: 'Manual' },
      smartScreen: { enabled: false, status: 'Disabled' }
    },
    
    managedInstalls: {
      type: 'Cimian',
      lastRun: new Date(Date.now() - 21600000).toISOString(), // 6 hours ago
      nextRun: new Date(Date.now() + 3600000).toISOString(), // 1 hour from now
      status: 'Error',
      config: {
        cimian_server_url: 'https://cimian.company.com/api',
        client_identifier: 'it-workstation',
        managed_installs_dir: 'C:\\ProgramData\\Cimian\\ManagedInstalls',
        log_file: 'C:\\ProgramData\\Cimian\\Logs\\CimianAgent.log',
        install_windows_updates: false
      },
      messages: {
        errors: [
          {
            id: 'err-003',
            package: 'VMware vSphere Client',
            message: 'Installation failed: Service dependency error',
            details: 'Failed to start VMware Authorization Service. Error code: 0x80070005 - Access is denied.',
            timestamp: new Date(Date.now() - 21600000).toISOString() // 6 hours ago
          },
          {
            id: 'err-004',
            package: 'SCCM Client',
            message: 'Configuration sync failed',
            details: 'Unable to contact SCCM management point. Certificate validation failed.',
            timestamp: new Date(Date.now() - 10800000).toISOString() // 3 hours ago
          }
        ],
        warnings: [
          {
            id: 'warn-005',
            package: 'Windows Server RSAT',
            message: 'Feature compatibility warning',
            details: 'Some RSAT features may not work correctly with the current Windows build.',
            timestamp: new Date(Date.now() - 43200000).toISOString() // 12 hours ago
          }
        ]
      },
      packages: [
        {
          name: 'Microsoft System Center Configuration Manager',
          version: '5.2107.1059.1000',
          status: 'Failed',
          installDate: null,
          size: '195 MB'
        },
        {
          name: 'VMware vSphere Client',
          version: '8.0.0.21345',
          status: 'Failed',
          installDate: null,
          size: '485 MB'
        },
        {
          name: 'Windows Server RSAT',
          version: '1809.0.17763.1',
          status: 'Installed',
          installDate: new Date(Date.now() - 1209600000).toISOString(), // 2 weeks ago
          size: '125 MB'
        },
        {
          name: 'PowerShell 7',
          version: '7.4.0',
          status: 'Installed',
          installDate: new Date(Date.now() - 2628000000).toISOString(), // 1 month ago
          size: '85 MB'
        }
      ]
    },
    
    applications: [
      {
        name: 'Windows PowerShell ISE',
        version: '10.0.22621.1',
        bundleId: 'Microsoft.PowerShell.ISE',
        path: 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\PowerShell_ISE.exe',
        lastOpened: new Date(Date.now() - 10800000).toISOString(), // 3 hours ago
        size: '15 MB'
      },
      {
        name: 'Remote Desktop Connection Manager',
        version: '2.90.0',
        bundleId: 'Microsoft.RDCMan',
        path: 'C:\\Program Files\\Microsoft\\Remote Desktop Connection Manager\\RDCMan.exe',
        lastOpened: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
        size: '8 MB'
      },
      {
        name: 'Wireshark',
        version: '4.2.0',
        bundleId: 'Wireshark.Wireshark',
        path: 'C:\\Program Files\\Wireshark\\Wireshark.exe',
        lastOpened: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
        size: '145 MB'
      },
      {
        name: 'Microsoft Visual Studio Code',
        version: '1.85.2',
        bundleId: 'Microsoft.VisualStudioCode',
        path: 'C:\\Users\\ryan.martinez\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe',
        lastOpened: new Date(Date.now() - 21600000).toISOString(), // 6 hours ago
        size: '285 MB'
      }
    ]
  }
}

// Mock events data for each device
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const eventsDatabase: Record<string, any[]> = {
  'JY93C5YGGM': [
    {
      id: 'evt-001',
      ts: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
      kind: 'Software Update',
      device: 'JY93C5YGGM',
      payload: {
        package: 'Adobe Photoshop 2024',
        version: '25.2.0',
        status: 'completed'
      }
    },
    {
      id: 'evt-002',
      ts: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      kind: 'Login',
      device: 'JY93C5YGGM',
      payload: {
        user: 'celeste.martin',
        method: 'password',
        ip_address: '108.172.84.175'
      }
    },
    {
      id: 'evt-003',
      ts: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
      kind: 'Network Change',
      device: 'JY93C5YGGM',
      payload: {
        interface: 'Wi-Fi',
        old_ip: '108.172.84.174',
        new_ip: '108.172.84.175',
        ssid: 'Company-WiFi'
      }
    }
  ],
  'FVFXQ2P3JM': [
    {
      id: 'evt-004',
      ts: new Date(Date.now() - 900000).toISOString(), // 15 minutes ago
      kind: 'Application Launch',
      device: 'FVFXQ2P3JM',
      payload: {
        application: 'Docker Desktop',
        version: '4.26.1',
        user: 'alex.chen'
      }
    },
    {
      id: 'evt-005',
      ts: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      kind: 'Error',
      device: 'FVFXQ2P3JM',
      payload: {
        source: 'Docker Desktop',
        message: 'Container failed to start',
        details: 'Port 3000 already in use'
      }
    },
    {
      id: 'evt-006',
      ts: new Date(Date.now() - 10800000).toISOString(), // 3 hours ago
      kind: 'Software Install',
      device: 'FVFXQ2P3JM',
      payload: {
        package: 'Node.js LTS',
        version: '20.10.0',
        status: 'completed'
      }
    }
  ],
  'C02ZK8WVLVDQ': [
    {
      id: 'evt-007',
      ts: new Date(Date.now() - 43200000).toISOString(), // 12 hours ago
      kind: 'Logout',
      device: 'C02ZK8WVLVDQ',
      payload: {
        user: 'sarah.johnson',
        session_duration: '8h 32m'
      }
    },
    {
      id: 'evt-008',
      ts: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
      kind: 'Error',
      device: 'C02ZK8WVLVDQ',
      payload: {
        source: 'System Update',
        message: 'Network timeout during download',
        details: 'Failed to download macOS 15.2.0 update'
      }
    }
  ],
  'WS-ACC-001': [
    {
      id: 'evt-009',
      ts: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      kind: 'Application Launch',
      device: 'WS-ACC-001',
      payload: {
        application: 'QuickBooks Enterprise',
        version: '23.0.8',
        user: 'jennifer.davis'
      }
    },
    {
      id: 'evt-010',
      ts: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      kind: 'Warning',
      device: 'WS-ACC-001',
      payload: {
        source: 'QuickBooks Enterprise',
        message: 'License expiration warning',
        details: 'License expires in 15 days'
      }
    },
    {
      id: 'evt-011',
      ts: new Date(Date.now() - 14400000).toISOString(), // 4 hours ago
      kind: 'Login',
      device: 'WS-ACC-001',
      payload: {
        user: 'jennifer.davis',
        method: 'domain',
        ip_address: '192.168.1.156'
      }
    }
  ],
  'LT-SAL-007': [
    {
      id: 'evt-012',
      ts: new Date(Date.now() - 600000).toISOString(), // 10 minutes ago
      kind: 'Network Change',
      device: 'LT-SAL-007',
      payload: {
        interface: 'Wi-Fi',
        old_ip: '10.0.2.46',
        new_ip: '10.0.2.47',
        ssid: 'Company-Guest'
      }
    },
    {
      id: 'evt-013',
      ts: new Date(Date.now() - 1800000).toISOString(), // 30 minutes ago
      kind: 'Software Update',
      device: 'LT-SAL-007',
      payload: {
        package: 'Zoom Client',
        version: '5.16.10.24060',
        status: 'completed'
      }
    },
    {
      id: 'evt-014',
      ts: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      kind: 'Application Launch',
      device: 'LT-SAL-007',
      payload: {
        application: 'Microsoft Teams',
        version: '1.6.00.32562',
        user: 'marcus.thompson'
      }
    }
  ],
  'WS-IT-003': [
    {
      id: 'evt-015',
      ts: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      kind: 'Application Launch',
      device: 'WS-IT-003',
      payload: {
        application: 'Remote Desktop Connection Manager',
        version: '2.90.0',
        user: 'ryan.martinez'
      }
    },
    {
      id: 'evt-016',
      ts: new Date(Date.now() - 10800000).toISOString(), // 3 hours ago
      kind: 'Error',
      device: 'WS-IT-003',
      payload: {
        source: 'SCCM Client',
        message: 'Configuration sync failed',
        details: 'Unable to contact SCCM management point'
      }
    },
    {
      id: 'evt-017',
      ts: new Date(Date.now() - 21600000).toISOString(), // 6 hours ago
      kind: 'Error',
      device: 'WS-IT-003',
      payload: {
        source: 'VMware vSphere Client',
        message: 'Installation failed',
        details: 'Service dependency error - Access denied'
      }
    }
  ]
}

export async function GET(
  request: Request,
  { params }: { params: { deviceId: string } }
) {
  const deviceId = params.deviceId
  
  if (!deviceDatabase[deviceId]) {
    return NextResponse.json({ error: 'Device not found' }, { status: 404 })
  }

  const deviceInfo = deviceDatabase[deviceId]
  const events = eventsDatabase[deviceId] || []

  return NextResponse.json({
    deviceInfo,
    events
  })
}
