import { NextResponse } from 'next/server'

// Mock device database - extended to match individual device endpoint
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
    lastEventTime: new Date(Date.now() - 1800000).toISOString()
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
    lastEventTime: new Date(Date.now() - 900000).toISOString()
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
    lastEventTime: new Date(Date.now() - 43200000).toISOString()
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
    lastEventTime: new Date(Date.now() - 3600000).toISOString()
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
    lastEventTime: new Date(Date.now() - 600000).toISOString()
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
    lastEventTime: new Date(Date.now() - 7200000).toISOString()
  }
}

export async function GET() {
  try {
    // Return all devices as an array
    const devices = Object.values(deviceDatabase).map(device => ({
      id: device.id,
      name: device.name,
      model: device.model,
      os: device.os,
      lastSeen: device.lastSeen,
      status: device.status,
      uptime: device.uptime,
      location: device.location,
      serialNumber: device.serialNumber,
      assetTag: device.assetTag,
      ipAddress: device.ipAddress,
      macAddress: device.macAddress,
      totalEvents: device.totalEvents,
      lastEventTime: device.lastEventTime
    }))
    
    return NextResponse.json({
      success: true,
      devices,
      count: devices.length
    })
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: (error as Error).message
    }, { status: 500 })
  }
}
