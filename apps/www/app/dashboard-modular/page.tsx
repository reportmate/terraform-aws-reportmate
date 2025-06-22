"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { useModules } from "../../src/lib/modules/ModuleRegistry"
import { initializeModules, getModuleSourcesFromConfig } from "../../src/lib/modules/ModuleInit"

export default function ModularDashboardPage() {
  const { dashboardWidgets } = useModules()
  const [initialized, setInitialized] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const init = async () => {
      try {
        const customSources = getModuleSourcesFromConfig()
        await initializeModules(customSources)
        setInitialized(true)
      } catch (error) {
        console.error('Failed to initialize modules:', error)
      } finally {
        setLoading(false)
      }
    }

    init()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-black">
        <div className="flex items-center justify-center h-64">
          <div className="text-gray-500 dark:text-gray-400">Initializing modules...</div>
        </div>
      </div>
    )
  }

  if (!initialized) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-black">
        <div className="flex items-center justify-center h-64">
          <div className="text-red-500">Failed to initialize module system</div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-black">
      {/* Header */}
      <header className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <h1 className="text-xl font-semibold text-gray-900 dark:text-gray-100">
                Seemianki Fleet Dashboard
              </h1>
              <span className="text-sm text-gray-500 dark:text-gray-400">
                {dashboardWidgets.length} widgets loaded
              </span>
            </div>
            
            <nav className="flex items-center gap-4">
              <Link
                href="/devices"
                className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium"
              >
                Devices
              </Link>
              <Link
                href="/modules"
                className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium"
              >
                Modules
              </Link>
              <Link
                href="/settings"
                className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium"
              >
                Settings
              </Link>
            </nav>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
            Fleet Overview
          </h2>
          <p className="mt-1 text-gray-600 dark:text-gray-400">
            Monitor your fleet status and recent activity
          </p>
        </div>

        {/* Modular Widget Grid */}
        {dashboardWidgets.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-gray-500 dark:text-gray-400 mb-4">
              No dashboard widgets available
            </div>
            <Link
              href="/modules"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Manage Modules
            </Link>
          </div>
        ) : (
          <div className="grid gap-6 grid-cols-1 lg:grid-cols-2 xl:grid-cols-3">
            {dashboardWidgets.map((widget) => {
              const Component = widget.component
              
              // Determine grid span based on widget size
              const sizeClasses = {
                small: 'lg:col-span-1',
                medium: 'lg:col-span-1',
                large: 'lg:col-span-2',
                full: 'lg:col-span-3',
              }
              
              const sizeClass = sizeClasses[widget.size || 'medium']
              
              return (
                <div key={widget.id} className={`${sizeClass}`}>
                  <Component {...(widget.defaultProps || {})} />
                </div>
              )
            })}
          </div>
        )}

        {/* Module Debug Info (only in development) */}
        {process.env.NODE_ENV === 'development' && (
          <div className="mt-12 p-6 bg-gray-100 dark:bg-gray-800 rounded-lg">
            <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
              Debug: Loaded Modules
            </h3>
            <div className="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
              {dashboardWidgets.map((widget) => (
                <div key={widget.id} className="p-3 bg-white dark:bg-gray-700 rounded border">
                  <div className="font-medium text-sm text-gray-900 dark:text-gray-100">
                    {widget.name}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    ID: {widget.id} | Size: {widget.size || 'medium'} | Order: {widget.order || 999}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  )
}
