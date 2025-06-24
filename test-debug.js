// Test script to debug OS version processing
const devices = [
  { id: 'WS-ACC-001', name: 'Jennifer Davis', os: '11.0.22631.2861' },
  { id: 'LT-SAL-007', name: 'Marcus Thompson', os: '11.0.22631.2861' },
  { id: 'WS-IT-003', name: 'Ryan Martinez', os: '11.0.22631.2861' },
  { id: 'WS-LEG-005', name: 'Lisa Brown', os: '10.0.19045.3803' },
  { id: 'WS-HR-002', name: 'Michael Garcia', os: '10.0.19045.3803' },
  { id: 'WS-DEV-008', name: 'Angela Foster', os: '11.0.22631.3007' },
  { id: 'WS-MKT-009', name: 'Carlos Rodriguez', os: '11.0.22631.2428' },
  { id: 'WS-ENG-012', name: 'Rachel Kim', os: '11.0.22631.4602' },
  { id: 'JY93C5YGGM', name: 'Celeste Martin', os: 'macOS 15.2.0' },
  { id: 'FVFXQ2P3JM', name: 'Alex Chen', os: 'macOS 15.2.0' },
];

// Process OS versions from devices (copied from dashboard)
const processOSVersions = () => {
  console.log('DEBUG: processOSVersions called')
  console.log('DEBUG: devices array:', devices)
  
  const macOSVersions = {}
  const windowsVersions = {}

  console.log('Processing devices for OS versions:', devices.map(d => ({ name: d.name, os: d.os })))

  devices.forEach(device => {
    if (device.os) {
      const os = device.os.toLowerCase()
      
      // Check if OS is in new Windows format first (e.g., "11.0.22631.2861" or "10.0.19045.3803")
      const windowsNewFormatMatch = device.os.match(/^(\d{1,2})\.(\d+)\.(\d+)\.(\d+)$/)
      
      if (os.includes('macos') || os.includes('mac os') || os.includes('darwin')) {
        // Extract macOS version (e.g., "macOS 15.2.0" -> "15.2.0")
        const versionMatch = device.os.match(/(\d+\.\d+\.\d+)/);
        const version = versionMatch ? versionMatch[1] : 'Unknown'
        macOSVersions[version] = (macOSVersions[version] || 0) + 1
        console.log('Found macOS device:', device.name, 'version:', version)
      } else if (windowsNewFormatMatch) {
        // Already in new Windows format (e.g., "11.0.22631.2861" or "10.0.19045.3803")
        windowsVersions[device.os] = (windowsVersions[device.os] || 0) + 1
        console.log('Found Windows device (new format):', device.name, 'version:', device.os)
      } else if (os.includes('windows') || os.includes('win')) {
        console.log('Found Windows device (legacy format):', device.name, 'OS:', device.os)
      } else {
        console.log('Unknown OS format for device:', device.name, 'OS:', device.os)
      }
    }
  })

  console.log('Final macOS versions:', macOSVersions)
  console.log('Final Windows versions:', windowsVersions)

  return { macOS: macOSVersions, windows: windowsVersions }
}

const result = processOSVersions()
console.log('Final result:', result)
