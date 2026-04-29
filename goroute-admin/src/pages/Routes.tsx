import React, { useEffect, useState } from 'react';
import { Route as RouteIcon, Trash2, ToggleLeft, ToggleRight, Loader2 } from 'lucide-react';
import { Route, subscribeRoutes, setRouteActive, deleteRoute } from '../services/firestore';

const Routes = () => {
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loading, setLoading] = useState(true);
  const [togglingId, setTogglingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  useEffect(() => {
    const unsub = subscribeRoutes((data) => {
      setRoutes(data);
      setLoading(false);
    });
    return unsub;
  }, []);

  const handleToggle = async (route: Route) => {
    setTogglingId(route.id);
    try {
      await setRouteActive(route.id, !route.isActive);
    } finally {
      setTogglingId(null);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this route?')) return;
    setDeletingId(id);
    try {
      await deleteRoute(id);
    } finally {
      setDeletingId(null);
    }
  };

  const active = routes.filter((r) => r.isActive).length;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Route Management</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          {routes.length} total · {active} active
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="h-12 w-12 bg-orange-50 text-orange-600 rounded-xl flex items-center justify-center">
            <RouteIcon className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs text-gray-500 font-medium">Total Routes</p>
            <p className="text-2xl font-bold text-gray-900">{routes.length}</p>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="h-12 w-12 bg-green-50 text-green-600 rounded-xl flex items-center justify-center">
            <ToggleRight className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs text-gray-500 font-medium">Active Routes</p>
            <p className="text-2xl font-bold text-gray-900">{active}</p>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-50 flex items-center justify-between">
          <h2 className="font-semibold text-gray-900">All Routes</h2>
          <span className="flex items-center gap-1.5 text-xs text-gray-400">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500" />
            </span>
            Live
          </span>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="h-6 w-6 animate-spin text-[#800000]" />
          </div>
        ) : routes.length === 0 ? (
          <div className="text-center py-16 text-gray-400">
            <RouteIcon className="h-12 w-12 mx-auto mb-3 opacity-30" />
            <p className="font-medium">No routes yet</p>
            <p className="text-sm mt-1">Routes added by drivers will appear here</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                <th className="px-6 py-3 text-left">Route</th>
                <th className="px-6 py-3 text-left">Driver</th>
                <th className="px-6 py-3 text-left">Duration</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {routes.map((route) => (
                <tr key={route.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="h-8 w-8 rounded-lg bg-orange-50 text-orange-600 flex items-center justify-center">
                        <RouteIcon className="h-4 w-4" />
                      </div>
                      <span className="font-medium text-gray-900">
                        {route.from} → {route.to}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-500">{route.driverName}</td>
                  <td className="px-6 py-4 text-gray-500">{route.estimatedTime}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${
                      route.isActive
                        ? 'bg-green-50 text-green-700'
                        : 'bg-gray-100 text-gray-500'
                    }`}>
                      <span className={`h-1.5 w-1.5 rounded-full ${route.isActive ? 'bg-green-500' : 'bg-gray-400'}`} />
                      {route.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleToggle(route)}
                        disabled={togglingId === route.id}
                        title={route.isActive ? 'Deactivate' : 'Activate'}
                        className={`p-2 rounded-lg transition-colors ${
                          route.isActive
                            ? 'text-green-600 hover:bg-green-50'
                            : 'text-gray-400 hover:bg-gray-100'
                        }`}
                      >
                        {togglingId === route.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : route.isActive ? (
                          <ToggleRight className="h-5 w-5" />
                        ) : (
                          <ToggleLeft className="h-5 w-5" />
                        )}
                      </button>
                      <button
                        onClick={() => handleDelete(route.id)}
                        disabled={deletingId === route.id}
                        className="p-2 rounded-lg text-red-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                      >
                        {deletingId === route.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default Routes;
