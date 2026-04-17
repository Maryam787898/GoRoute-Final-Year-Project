import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import Layout from './components/layout/Layout';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import ProtectedRoute from './components/ProtectedRoute';

// Placeholder component
const Placeholder = ({ title }: { title: string }) => (
  <div className="card p-6">
    <h1 className="text-2xl font-bold text-gray-800 dark:text-white">{title}</h1>
    <p className="text-gray-500 mt-2">This feature is coming soon...</p>
  </div>
);

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* Public Route */}
          <Route path="/login" element={<Login />} />

          {/* Protected Admin Routes */}
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="tracking" element={<Placeholder title="Live Tracking Map" />} />
            <Route path="routes" element={<Placeholder title="Route Management" />} />
            <Route path="drivers" element={<Placeholder title="Driver Assignment" />} />
            <Route path="users" element={<Placeholder title="User Management" />} />
            <Route path="notifications" element={<Placeholder title="Push Notifications" />} />
          </Route>

          {/* Catch-all: Redirect unknown routes to Dashboard */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;