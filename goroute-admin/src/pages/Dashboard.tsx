import React, { useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  limit,
  Timestamp
} from "firebase/firestore";
import { onAuthStateChanged, User } from "firebase/auth";
import { db, auth } from "../firebase";
import { 
  Users, 
  UserCheck, 
  UserMinus, 
  Clock, 
  ShieldCheck, 
  Mail,
  Circle
} from "lucide-react";

interface UserProfile {
  uid: string;
  name: string;
  email: string;
  role: 'passenger' | 'driver';
  isOnline: boolean;
  createdAt: Timestamp;
  lastLogin?: Timestamp;
}

const Dashboard: React.FC = () => {
  const [admin, setAdmin] = useState<User | null>(null);
  const [recentUsers, setRecentUsers] = useState<UserProfile[]>([]);
  const [counts, setCounts] = useState({
    passengers: 0,
    drivers: 0,
    online: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubAuth = onAuthStateChanged(auth, (user) => {
      setAdmin(user);
    });

    // Listen to ALL users to calculate counts
    const unsubFirestore = onSnapshot(collection(db, "users"), (snapshot) => {
      const usersData = snapshot.docs.map(doc => ({
        ...doc.data()
      } as UserProfile));

      // Calculate counts
      const pCount = usersData.filter(u => u.role === 'passenger').length;
      const dCount = usersData.filter(u => u.role === 'driver').length;
      const oCount = usersData.filter(u => u.isOnline).length;

      setCounts({
        passengers: pCount,
        drivers: dCount,
        online: oCount
      });

      // Sort manually for recent users to avoid index/missing field issues
      const sorted = [...usersData].sort((a, b) => {
        const timeA = a.createdAt?.seconds || 0;
        const timeB = b.createdAt?.seconds || 0;
        return timeB - timeA;
      }).slice(0, 10);

      setRecentUsers(sorted);
      setLoading(false);
    }, (error) => {
      console.error("Firestore error:", error);
      setLoading(false);
    });

    return () => {
      unsubAuth();
      unsubFirestore();
    };
  }, []);

  const getInitials = (name: string) => {
    return name.charAt(0).toUpperCase();
  };

  const formatDate = (timestamp: Timestamp) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate();
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Admin Dashboard</h1>
          <p className="text-gray-500 dark:text-gray-400 mt-1">Monitor real-time user activity and system status.</p>
        </div>
        
        {/* Admin Profile Card */}
        {admin && (
          <div className="flex items-center gap-4 bg-white dark:bg-gray-800 p-3 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700">
            <div className="h-12 w-12 rounded-full bg-primary text-white flex items-center justify-center text-xl font-bold shadow-sm">
              {getInitials(admin.displayName || admin.email || 'A')}
            </div>
            <div>
              <div className="flex items-center gap-1">
                <p className="text-sm font-bold text-gray-900 dark:text-white leading-none">
                  {admin.displayName || 'Admin'}
                </p>
                <ShieldCheck className="h-3 w-3 text-primary" />
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{admin.email}</p>
            </div>
          </div>
        )}
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-gray-800 p-6 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center gap-5">
          <div className="h-14 w-14 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-2xl flex items-center justify-center">
            <Users size={28} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Total Passengers</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{counts.passengers}</p>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 p-6 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center gap-5">
          <div className="h-14 w-14 bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 rounded-2xl flex items-center justify-center">
            <ShieldCheck size={28} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Total Drivers</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{counts.drivers}</p>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 p-6 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center gap-5">
          <div className="h-14 w-14 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 rounded-2xl flex items-center justify-center">
            <UserCheck size={28} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Online Now</p>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">
              {counts.online}
            </p>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 p-6 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center gap-5">
          <div className="h-14 w-14 bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400 rounded-2xl flex items-center justify-center">
            <Clock size={28} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Status</p>
            <p className="text-2xl font-bold text-green-600 dark:text-green-400">Healthy</p>
          </div>
        </div>
      </div>

      {/* Recent Users List */}
      <div className="bg-white dark:bg-gray-800 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
        <div className="p-6 border-b border-gray-50 dark:border-gray-700 flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">Recent Users Sync</h2>
          <div className="flex items-center gap-2">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
            </span>
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Live Sync</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50/50 dark:bg-gray-700/30 text-gray-500 dark:text-gray-400 text-xs font-bold uppercase tracking-wider">
                <th className="px-6 py-4">User</th>
                <th className="px-6 py-4">Role</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Created At</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
              {recentUsers.map((user) => (
                <tr key={user.uid} className="hover:bg-gray-50/50 dark:hover:bg-gray-700/20 transition-colors group">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="h-10 w-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-sm shadow-sm group-hover:scale-110 transition-transform">
                        {getInitials(user.name)}
                      </div>
                      <div>
                        <p className="text-sm font-bold text-gray-900 dark:text-white">{user.name}</p>
                        <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400">
                          <Mail size={10} />
                          <span>{user.email}</span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-[10px] font-extrabold px-2.5 py-1 rounded-full uppercase tracking-tighter ${
                      user.role === 'driver' 
                        ? 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400' 
                        : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                    }`}>
                      {user.role}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    {user.isOnline ? (
                      <div className="flex items-center gap-1.5 text-green-600 dark:text-green-400">
                        <Circle size={8} fill="currentColor" />
                        <span className="text-xs font-bold uppercase tracking-tight">Online</span>
                      </div>
                    ) : (
                      <div className="flex items-center gap-1.5 text-gray-400 dark:text-gray-500">
                        <Circle size={8} fill="currentColor" />
                        <span className="text-xs font-bold uppercase tracking-tight">Offline</span>
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-xs text-gray-500 dark:text-gray-400 font-medium">
                      {user.createdAt ? new Date(user.createdAt.seconds * 1000).toLocaleString() : 'Just now'}
                    </p>
                  </td>
                </tr>
              ))}
              
              {recentUsers.length === 0 && !loading && (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center">
                    <UserMinus className="mx-auto h-12 w-12 text-gray-300 mb-3" />
                    <p className="text-gray-500 dark:text-gray-400 font-medium">No users found in Firestore</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
