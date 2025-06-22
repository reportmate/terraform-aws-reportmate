"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { useLiveEvents } from "./hooks"
import { formatRelativeTime, formatExactTime } from "../../src/lib/time"

interface Device {
  id: string
  name: string
  model?: string
  os?: string
  lastSeen: string
  status: 'online' | 'offline' | 'warning' | 'error'
  uptime?: string
  location?: string
  serialNumber?: string
  ipAddress?: string
  totalEvents: number
  lastEventTime: string
}

export default function DashboardPage() {
  const { events, connectionStatus, lastUpdateTime, mounted, addEvent } = useLiveEvents()
  const [timeUpdateCounter, setTimeUpdateCounter] = useState(0)
  const [devices, setDevices] = useState<Device[]>([])
  const [devicesLoading, setDevicesLoading] = useState(true)
  const [deviceNameMap, setDeviceNameMap] = useState<Record<string, string>>({})

  // Create device name mapping function
  const getDeviceName = (deviceId: string) => {
    return deviceNameMap[deviceId] || deviceId
  }

  // Fetch devices data
  useEffect(() => {
    const fetchDevices = async () => {
      try {
        const response = await fetch('/api/device')
        if (response.ok) {
          const data = await response.json()
          if (data.success && data.devices) {
            // Sort devices by lastSeen descending (newest first)
            const sortedDevices = data.devices.sort((a: Device, b: Device) => 
              new Date(b.lastSeen).getTime() - new Date(a.lastSeen).getTime()
            )
            setDevices(sortedDevices)
            
            // Build device name mapping (serial -> name)
            const nameMap: Record<string, string> = {}
            data.devices.forEach((device: Device) => {
              if (device.serialNumber && device.name) {
                nameMap[device.serialNumber] = device.name
              }
              // Also map by ID in case that's used
              nameMap[device.id] = device.name
            })
            setDeviceNameMap(nameMap)
          }
        }
      } catch (error) {
        console.error('Failed to fetch devices:', error)
      } finally {
        setDevicesLoading(false)
      }
    }

    fetchDevices()
  }, [])

  // Update relative times every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setTimeUpdateCounter(prev => prev + 1)
    }, 30000)
    return () => clearInterval(interval)
  }, [])

  // Calculate stats
  const stats = {
    total: events.length,
    errors: events.filter(e => e.kind.toLowerCase() === 'error').length,
    warnings: events.filter(e => e.kind.toLowerCase() === 'warning').length,
    success: events.filter(e => e.kind.toLowerCase() === 'success').length,
    devices: new Set(events.map(e => e.device)).size
  }

  // Status configuration
  const getStatusConfig = (kind: string) => {
    switch (kind.toLowerCase()) {
      case 'error': 
        return { bg: 'bg-red-500', text: 'text-red-700 dark:text-red-300', badge: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' }
      case 'warning': 
        return { bg: 'bg-yellow-500', text: 'text-yellow-700 dark:text-yellow-300', badge: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' }
      case 'success': 
        return { bg: 'bg-green-500', text: 'text-green-700 dark:text-green-300', badge: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' }
      case 'info': 
        return { bg: 'bg-blue-500', text: 'text-blue-700 dark:text-blue-300', badge: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' }
      case 'system': 
        return { bg: 'bg-purple-500', text: 'text-purple-700 dark:text-purple-300', badge: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200' }
      default: 
        return { bg: 'bg-gray-500', text: 'text-gray-700 dark:text-gray-300', badge: 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200' }
    }
  }

  const getConnectionStatus = () => {
    switch (connectionStatus) {
      case 'connected':
        return { text: 'Live', color: 'text-green-600 dark:text-green-400', dot: 'bg-green-500' }
      case 'connecting':
        return { text: 'Connecting', color: 'text-yellow-600 dark:text-yellow-400', dot: 'bg-yellow-500' }
      case 'polling':
        return { text: 'Polling', color: 'text-blue-600 dark:text-blue-400', dot: 'bg-blue-500' }
      default:
        return { text: 'Offline', color: 'text-red-600 dark:text-red-400', dot: 'bg-red-500' }
    }
  }

  const status = getConnectionStatus()

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-black" suppressHydrationWarning>
      {/* Header */}
      <header className="bg-white dark:bg-black border-b border-gray-200 dark:border-gray-700 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Brand */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                  <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
                    <path fillRule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clipRule="evenodd" />
                  </svg>
                </div>
                <div>
                  <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                    Seemianki Report
                  </h1>
                  <p className="text-sm text-gray-600 dark:text-gray-400 hidden sm:block">
                    Real-time Devices Monitoring
                  </p>
                </div>
              </div>
            </div>
            
            {/* Actions */}
            <div className="flex items-center gap-3">
              {/* Connection status */}
              <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-gray-100 dark:bg-gray-700">
                <div className={`w-2 h-2 rounded-full ${status.dot} animate-pulse`}></div>
                <span className={`text-sm font-medium ${status.color}`}>
                  {status.text}
                </span>
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </div>
              <div>
                <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {devices.length}
                </p>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Devices
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              </div>
              <div>
                <p className="text-2xl font-bold text-green-600 dark:text-green-400">
                  {stats.success}
                </p>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Success
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-yellow-100 dark:bg-yellow-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              </div>
              <div>
                <p className="text-2xl font-bold text-yellow-600 dark:text-yellow-400">
                  {stats.warnings}
                </p>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Warnings
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-red-100 dark:bg-red-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              </div>
              <div>
                <p className="text-2xl font-bold text-red-600 dark:text-red-400">
                  {stats.errors}
                </p>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Errors
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Two-column layout: New Clients (1/3) + Events (2/3) */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* New Clients Table - 1/3 width */}
          <div className="lg:col-span-1">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                      New Clients
                    </h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Recently discovered devices
                    </p>
                  </div>
                  <Link
                    href="/devices/list"
                    className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
                  >
                    <span>View All</span>
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </Link>
                </div>
              </div>

              {devicesLoading ? (
                <div className="py-8 text-center">
                  <div className="w-6 h-6 mx-auto mb-2 border-2 border-blue-200 border-t-blue-600 rounded-full animate-spin"></div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Loading devices...</p>
                </div>
              ) : devices.length === 0 ? (
                <div className="py-8 text-center">
                  <div className="w-12 h-12 mx-auto mb-3 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-1">
                    No devices found
                  </h3>
                  <p className="text-xs text-gray-600 dark:text-gray-400">
                    Devices will appear here when they report in
                  </p>
                </div>
              ) : (
                <div className="divide-y divide-gray-200 dark:divide-gray-700 max-h-96 overflow-y-auto">
                  {devices.slice(0, 8).map((device) => {
                    const getStatusColor = (status: string) => {
                      switch (status) {
                        case 'online': return 'bg-green-500'
                        case 'warning': return 'bg-yellow-500'
                        case 'error': return 'bg-red-500'
                        default: return 'bg-gray-500'
                      }
                    }

                    return (
                      <Link
                        key={device.id}
                        href={`/device/${device.id}`}
                        className="block p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-3 h-3 rounded-full ${getStatusColor(device.status)} flex-shrink-0`}></div>
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-medium text-gray-900 dark:text-white truncate">
                              {device.name}
                            </div>
                            <div className="text-xs text-gray-600 dark:text-gray-400 truncate">
                              {device.model}
                            </div>
                            <div className="text-xs text-gray-500 dark:text-gray-500 mt-1">
                              {formatRelativeTime(device.lastSeen)}
                            </div>
                          </div>
                        </div>
                      </Link>
                    )
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Events Table - 2/3 width */}
          <div className="lg:col-span-2">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                      Recent Events
                    </h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Live activity from your fleet
                    </p>
                  </div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">
                    Last update: {mounted && lastUpdateTime ? formatRelativeTime(lastUpdateTime.toISOString()) : 'Loading...'}
                  </div>
                </div>
              </div>
              
              {events.length === 0 ? (
                <div className="py-16 text-center">
                  <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
                    <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2M4 13h2m13-8l-2 2m0 0l-2-2m2 2v6" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                    No events yet
                  </h3>
                  <p className="text-gray-600 dark:text-gray-400 mb-6">
                    Waiting for fleet events to arrive. Send a test event to get started.
                  </p>
                </div>
              ) : (
                <div className="overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50 dark:bg-gray-700">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider w-20">
                          Type
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                          Device
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                          Message
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider w-32">
                          Time
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                      {events.slice(0, 50).map((event) => {
                        const statusConfig = getStatusConfig(event.kind)
                        return (
                          <tr 
                            key={event.id} 
                            className="hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                          >
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${statusConfig.badge}`}>
                                {event.kind}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <Link
                                href={`/device/${encodeURIComponent(event.device)}`}
                                className="font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors"
                              >
                                {getDeviceName(event.device)}
                              </Link>
                            </td>
                            <td className="px-6 py-4">
                              <div className="text-sm text-gray-900 dark:text-white truncate max-w-xs">
                                {typeof event.payload === 'object' && event.payload !== null ? 
                                  (event.payload as any).message || JSON.stringify(event.payload) : 
                                  String(event.payload)}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="text-sm text-gray-600 dark:text-gray-400">
                                <div className="font-medium">
                                  {formatRelativeTime(event.ts)}
                                </div>
                                <div className="text-xs opacity-75" title={formatExactTime(event.ts)}>
                                  {formatExactTime(event.ts)}
                                </div>
                              </div>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
