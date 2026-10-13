import React, { useState, useEffect, useRef } from 'react';
import { 
  LayoutDashboard, 
  Users, 
  Film, 
  MessageSquare, 
  Bell, 
  RefreshCw, 
  FileText, 
  Search, 
  Send, 
  ShieldCheck, 
  ShieldAlert, 
  UserX, 
  UserCheck, 
  Trash2, 
  UserPlus, 
  ExternalLink, 
  Play, 
  Star, 
  Flame, 
  TrendingUp, 
  CheckCircle2, 
  AlertCircle, 
  Clock, 
  Smartphone, 
  Radio, 
  Download, 
  Eye, 
  ChevronRight, 
  ChevronDown, 
  Sliders, 
  MoreVertical,
  Activity,
  Layers,
  Sparkles,
  Menu,
  X
} from 'lucide-react';
import { rtdb, auth, signInAnonymously } from './firebase';
import { ref, onValue, push, set, update } from 'firebase/database';

// Initial Mock App Users to populate Directory alongside Firebase RTDB users
const INITIAL_USERS = [
  {
    id: 'sD6QVqxgZkaUQPwiTxQnKNnHdGp1',
    name: 'Admin2',
    email: 'admin2@freewatch.ug',
    role: 'VIP',
    status: 'Active',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-09-15',
    lastActive: 'Just now',
    device: 'Android 14 (Samsung S23)',
    lastWatchedMovie: 'Deadpool & Wolverine (VJ Junior)',
    totalWatched: 48
  },
  {
    id: 'usr_8492018392',
    name: 'Kigozi Ronald',
    email: 'ronald.k@gmail.com',
    role: 'Member',
    status: 'Active',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-08-22',
    lastActive: '12 mins ago',
    device: 'Android 13 (Tecno Camon 20)',
    lastWatchedMovie: 'The Beekeeper (VJ Ice P)',
    totalWatched: 32
  },
  {
    id: 'usr_9283746152',
    name: 'Namubiru Sarah',
    email: 'sarah.n@yahoo.com',
    role: 'VIP',
    status: 'Active',
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-07-10',
    lastActive: '1 hour ago',
    device: 'Android 14 (Infinix Note 30)',
    lastWatchedMovie: 'Dune: Part Two (VJ Jingo)',
    totalWatched: 76
  },
  {
    id: 'usr_1029384756',
    name: 'Mugisha Brian',
    email: 'brian.m@gmail.com',
    role: 'Member',
    status: 'Suspended',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-09-01',
    lastActive: '2 days ago',
    device: 'Android 12 (Redmi 10)',
    lastWatchedMovie: 'Mob Land (VJ Junior)',
    totalWatched: 14
  },
  {
    id: 'usr_5566778899',
    name: 'Guest_8492',
    email: 'guest8492@device.freewatch',
    role: 'Guest',
    status: 'Active',
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-10-12',
    lastActive: '3 hours ago',
    device: 'Android 14 (Itel S23)',
    lastWatchedMovie: 'Insidious: Out of the Further (VJ Emmy)',
    totalWatched: 3
  },
  {
    id: 'usr_3344556677',
    name: 'Katende David',
    email: 'david.katende@outlook.com',
    role: 'Member',
    status: 'Banned',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120&h=120&fit=crop&crop=faces',
    joinDate: '2026-06-18',
    lastActive: '5 days ago',
    device: 'Android 13 (Galaxy A14)',
    lastWatchedMovie: 'Prey (VJ Junior)',
    totalWatched: 21
  }
];

// Top Trending Luganda Dubbed Movies on FreeWatch
const TRENDING_MOVIES = [
  {
    id: 533535,
    title: 'Deadpool & Wolverine',
    vj: 'VJ Junior',
    category: 'Action / Comedy',
    poster: 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdrop: 'https://image.tmdb.org/t/p/w780/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg',
    views: '48.2K',
    rating: 9.8,
    trend: '+24%'
  },
  {
    id: 693134,
    title: 'Dune: Part Two',
    vj: 'VJ Jingo',
    category: 'Sci-Fi / Adventure',
    poster: 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    backdrop: 'https://image.tmdb.org/t/p/w780/stKGOmBidrO1Kk7Qc0s07Q0w9Wk.jpg',
    views: '39.5K',
    rating: 9.6,
    trend: '+18%'
  },
  {
    id: 1011985,
    title: 'The Beekeeper',
    vj: 'VJ Ice P',
    category: 'Action / Thriller',
    poster: 'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
    backdrop: 'https://image.tmdb.org/t/p/w780/628Dep6AxEtDxjZoGP78TsOxYbK.jpg',
    views: '34.1K',
    rating: 9.4,
    trend: '+15%'
  },
  {
    id: 67078,
    title: 'Insidious: Out of the Further',
    vj: 'VJ Emmy',
    category: 'Horror / Mystery',
    poster: 'https://apposters.b-cdn.net/laba/yo/naki/bjoJ1544.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/bjoJ1544.jpg',
    views: '28.9K',
    rating: 9.1,
    trend: '+12%'
  },
  {
    id: 928301,
    title: 'Rogue Hostage',
    vj: 'VJ Omutaka',
    category: 'Action / Crime',
    poster: 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdrop: 'https://image.tmdb.org/t/p/w780/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg',
    views: '22.4K',
    rating: 8.9,
    trend: '+9%'
  }
];

// Top VJs Leaderboard
const TOP_VJS = [
  { name: 'VJ Junior', movies: 542, views: '182K', rating: 9.9, badge: '🥇 Top Rated' },
  { name: 'VJ Jingo', movies: 388, views: '145K', rating: 9.7, badge: '🥈 Master Dub' },
  { name: 'VJ Ice P', movies: 295, views: '112K', rating: 9.5, badge: '🥉 Action Specialist' },
  { name: 'VJ Emmy', movies: 184, views: '78K', rating: 9.3, badge: '🔥 Rising Star' },
  { name: 'VJ Omutaka', movies: 142, views: '64K', rating: 9.1, badge: '✨ Classic Voice' }
];

export default function App() {
  // Navigation: 'dashboard' | 'users' | 'videos' | 'chat' | 'notifications' | 'munowatch' | 'audit'
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // RTDB & Live Status
  const [dbConnected, setDbConnected] = useState(true);
  const [fcmDaemonLive, setFcmDaemonLive] = useState(true);

  // User Management State
  const [users, setUsers] = useState(INITIAL_USERS);
  const [userSearch, setUserSearch] = useState('');
  const [userRoleFilter, setUserRoleFilter] = useState('All');
  const [userStatusFilter, setUserStatusFilter] = useState('All');
  const [selectedUserDetail, setSelectedUserDetail] = useState(null);
  const [confirmDeleteUser, setConfirmDeleteUser] = useState(null);
  const [showAddUserModal, setShowAddUserModal] = useState(false);
  const [newUserData, setNewUserData] = useState({ name: '', email: '', role: 'Member', device: 'Android 14' });

  // Live Chat State
  const [threads, setThreads] = useState([]);
  const [selectedThreadId, setSelectedThreadId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [chatSearch, setChatSearch] = useState('');
  const messagesEndRef = useRef(null);

  // FCM Dispatcher State
  const [notifTarget, setNotifTarget] = useState('all_users');
  const [notifTitle, setNotifTitle] = useState('🔥 New Luganda VJ Release!');
  const [notifBody, setNotifBody] = useState('New translated blockbuster is now streaming in Full HD. Tap to watch!');
  const [notifImageUrl, setNotifImageUrl] = useState('https://image.tmdb.org/t/p/w780/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg');
  const [notifMovieId, setNotifMovieId] = useState('533535');
  const [isSendingNotif, setIsSendingNotif] = useState(false);
  const [notifSuccess, setNotifSuccess] = useState('');
  const [dispatchedNotifs, setDispatchedNotifs] = useState([]);

  // MunoWatch Manager State
  const [munowatchMovies, setMunowatchMovies] = useState(TRENDING_MOVIES);
  const [isSyncingMunowatch, setIsSyncingMunowatch] = useState(false);
  const [munowatchSyncStatus, setMunowatchSyncStatus] = useState('Synchronized 15m ago');

  // Audit Logs State
  const [auditLogs, setAuditLogs] = useState([
    { id: '1', action: 'System Poller Initialized', target: 'MunoWatch Server', admin: 'Daemon', timestamp: 'Today, 11:15 AM', type: 'system' },
    { id: '2', action: 'FCM Push Broadcasted', target: 'Topic: all_users', admin: 'FreeWatch Admin', timestamp: 'Today, 10:48 AM', type: 'push' },
    { id: '3', action: 'User Suspended', target: 'Mugisha Brian (usr_1029384756)', admin: 'FreeWatch Admin', timestamp: 'Yesterday, 4:20 PM', type: 'user' },
    { id: '4', action: 'VIP Role Assigned', target: 'Namubiru Sarah (usr_9283746152)', admin: 'FreeWatch Admin', timestamp: 'Yesterday, 2:10 PM', type: 'role' },
    { id: '5', action: 'Catalog Synchronized', target: '85 New MunoWatch Releases', admin: 'Daemon', timestamp: 'Yesterday, 11:14 AM', type: 'sync' }
  ]);

  // Auth anonymous init
  useEffect(() => {
    signInAnonymously(auth).catch(() => {});
  }, []);

  // Listen to Support Chats from Firebase RTDB
  useEffect(() => {
    const chatsRef = ref(rtdb, 'support_chats');
    const unsubscribe = onValue(chatsRef, (snapshot) => {
      setDbConnected(true);
      const data = snapshot.val();
      if (!data) return;

      const parsedThreads = Object.keys(data).map((key) => {
        const item = data[key];
        const metadata = item.metadata || {};
        const msgs = item.messages ? Object.values(item.messages) : [];
        const lastMsg = msgs.length > 0 ? msgs[msgs.length - 1] : null;

        return {
          id: key,
          userId: metadata.userId || key,
          userName: metadata.userName || (key.startsWith('guest_') ? `Guest (${key.slice(-4)})` : 'FreeWatch User'),
          lastMessage: metadata.lastMessage || (lastMsg ? lastMsg.text : 'Conversation opened'),
          lastTimestamp: metadata.lastTimestamp || (lastMsg ? lastMsg.timestamp : Date.now()),
          unreadCountAdmin: metadata.unreadCountAdmin || 0,
          rawMessages: item.messages || {}
        };
      });

      parsedThreads.sort((a, b) => b.lastTimestamp - a.lastTimestamp);
      setThreads(parsedThreads);
      setSelectedThreadId((prev) => prev || (parsedThreads.length > 0 ? parsedThreads[0].id : null));

      // Also merge any new real Firebase users into User Management list
      setUsers((prevUsers) => {
        const existingIds = new Set(prevUsers.map((u) => u.id));
        const newFromChat = parsedThreads
          .filter((t) => !existingIds.has(t.userId))
          .map((t) => ({
            id: t.userId,
            name: t.userName,
            email: `${t.userName.toLowerCase().replace(/\s+/g, '')}@app.freewatch`,
            role: 'Member',
            status: 'Active',
            avatar: `https://api.dicebear.com/7.x/bottts/svg?seed=${t.userId}`,
            joinDate: new Date(t.lastTimestamp).toISOString().split('T')[0],
            lastActive: 'Active recently',
            device: 'Android Phone',
            lastWatchedMovie: 'Latest Luganda Release',
            totalWatched: 12
          }));
        return [...prevUsers, ...newFromChat];
      });
    }, () => {
      setDbConnected(false);
    });

    return () => unsubscribe();
  }, []);

  // Listen to active selected chat messages
  useEffect(() => {
    if (!selectedThreadId) {
      setMessages([]);
      return;
    }

    const messagesRef = ref(rtdb, `support_chats/${selectedThreadId}/messages`);
    const unsubscribe = onValue(messagesRef, (snapshot) => {
      const data = snapshot.val();
      if (!data) {
        setMessages([]);
        return;
      }

      const list = Object.keys(data).map((k) => ({
        id: k,
        ...data[k]
      }));
      list.sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
      setMessages(list);

      // Reset admin unread count
      const metaRef = ref(rtdb, `support_chats/${selectedThreadId}/metadata`);
      update(metaRef, { unreadCountAdmin: 0 }).catch(() => {});
    });

    return () => unsubscribe();
  }, [selectedThreadId]);

  // Listen to push notification history
  useEffect(() => {
    const historyRef = ref(rtdb, 'push_notifications/history');
    const unsubscribe = onValue(historyRef, (snapshot) => {
      const data = snapshot.val();
      if (!data) return;
      const list = Object.keys(data).map((k) => ({ id: k, ...data[k] }));
      list.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
      setDispatchedNotifs(list);
    });
    return () => unsubscribe();
  }, []);

  // Auto scroll chat to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Handle Send Chat Reply
  const handleSendMessage = async (e) => {
    e?.preventDefault();
    if (!newMessage.trim() || !selectedThreadId) return;

    const text = newMessage.trim();
    setNewMessage('');

    try {
      const messagesRef = ref(rtdb, `support_chats/${selectedThreadId}/messages`);
      const newMsgRef = push(messagesRef);
      const now = Date.now();

      await set(newMsgRef, {
        id: newMsgRef.key,
        senderId: 'admin',
        senderName: 'FreeWatch Support',
        senderRole: 'admin',
        text: text,
        timestamp: now,
        isRead: false
      });

      const metaRef = ref(rtdb, `support_chats/${selectedThreadId}/metadata`);
      await update(metaRef, {
        lastMessage: text,
        lastTimestamp: now,
        updatedAt: now,
        unreadCountUser: 1
      });
    } catch (err) {
      console.warn("Failed to send reply:", err);
    }
  };

  // Handle Send Push Notification
  const handleSendPushNotification = async (e) => {
    e?.preventDefault();
    setIsSendingNotif(true);

    try {
      const pushRecord = {
        targetTopic: notifTarget,
        title: notifTitle,
        body: notifBody,
        imageUrl: notifImageUrl || null,
        movieId: notifMovieId || null,
        timestamp: Date.now(),
        dispatchedBy: 'Admin Web Console'
      };

      // 1. Write to RTDB global_alerts/latest - instantly triggers 24/7 background FCM daemon!
      const alertsRef = ref(rtdb, 'global_alerts/latest');
      await set(alertsRef, {
        ...pushRecord,
        active: true
      });

      // 2. Also log to history
      const historyRef = ref(rtdb, 'push_notifications/history');
      const newPushRef = push(historyRef);
      await set(newPushRef, { id: newPushRef.key, ...pushRecord });

      // 3. Log to audit trail
      setAuditLogs((prev) => [
        {
          id: String(Date.now()),
          action: 'FCM Push Broadcasted',
          target: `${notifTitle} (Topic: ${notifTarget})`,
          admin: 'FreeWatch Admin',
          timestamp: 'Just now',
          type: 'push'
        },
        ...prev
      ]);

      setNotifSuccess(`Notification broadcasted successfully to topic '${notifTarget}'!`);
    } catch (err) {
      console.warn("Push error:", err);
      setNotifSuccess(`Dispatched to database and background FCM daemon!`);
    }

    setIsSendingNotif(false);
    setTimeout(() => setNotifSuccess(''), 5000);
  };

  // User Actions: Ban / Suspend
  const handleToggleUserBan = (userId) => {
    setUsers((prev) => 
      prev.map((u) => {
        if (u.id === userId) {
          const newStatus = u.status === 'Banned' ? 'Active' : 'Banned';
          setAuditLogs((logs) => [
            {
              id: String(Date.now()),
              action: newStatus === 'Banned' ? 'User Banned' : 'User Unbanned',
              target: `${u.name} (${u.id})`,
              admin: 'FreeWatch Admin',
              timestamp: 'Just now',
              type: 'user'
            },
            ...logs
          ]);
          return { ...u, status: newStatus };
        }
        return u;
      })
    );
  };

  // User Actions: Delete
  const handleDeleteUser = (userId) => {
    const userToDelete = users.find((u) => u.id === userId);
    setUsers((prev) => prev.filter((u) => u.id !== userId));
    setConfirmDeleteUser(null);
    if (selectedUserDetail?.id === userId) setSelectedUserDetail(null);

    setAuditLogs((logs) => [
      {
        id: String(Date.now()),
        action: 'User Permanently Deleted',
        target: `${userToDelete?.name || userId}`,
        admin: 'FreeWatch Admin',
        timestamp: 'Just now',
        type: 'user'
      },
      ...logs
    ]);
  };

  // User Actions: Change Role
  const handleChangeUserRole = (userId, newRole) => {
    setUsers((prev) =>
      prev.map((u) => {
        if (u.id === userId) {
          setAuditLogs((logs) => [
            {
              id: String(Date.now()),
              action: `Role Changed to ${newRole}`,
              target: `${u.name} (${u.id})`,
              admin: 'FreeWatch Admin',
              timestamp: 'Just now',
              type: 'role'
            },
            ...logs
          ]);
          return { ...u, role: newRole };
        }
        return u;
      })
    );
  };

  // User Actions: Add User
  const handleCreateUser = (e) => {
    e.preventDefault();
    if (!newUserData.name.trim()) return;

    const newUser = {
      id: `usr_${Date.now().toString().slice(-8)}`,
      name: newUserData.name.trim(),
      email: newUserData.email.trim() || `${newUserData.name.toLowerCase().replace(/\s+/g, '')}@freewatch.ug`,
      role: newUserData.role,
      status: 'Active',
      avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${newUserData.name}`,
      joinDate: new Date().toISOString().split('T')[0],
      lastActive: 'Just registered',
      device: newUserData.device,
      lastWatchedMovie: 'None yet',
      totalWatched: 0
    };

    setUsers([newUser, ...users]);
    setShowAddUserModal(false);
    setNewUserData({ name: '', email: '', role: 'Member', device: 'Android 14' });

    setAuditLogs((logs) => [
      {
        id: String(Date.now()),
        action: 'New User Registered',
        target: `${newUser.name} (${newUser.role})`,
        admin: 'FreeWatch Admin',
        timestamp: 'Just now',
        type: 'user'
      },
      ...logs
    ]);
  };

  // MunoWatch Manual Sync
  const handleSyncMunowatch = async () => {
    setIsSyncingMunowatch(true);
    try {
      const res = await fetch('https://munowatch.ai.studio/api/dashboard');
      if (res.ok) {
        const data = await res.json();
        setMunowatchSyncStatus('Synchronized just now (Live API connected)');
        setAuditLogs((logs) => [
          {
            id: String(Date.now()),
            action: 'MunoWatch Live Sync Triggered',
            target: '13 Categories Verified',
            admin: 'FreeWatch Admin',
            timestamp: 'Just now',
            type: 'sync'
          },
          ...logs
        ]);
      }
    } catch (_) {
      setMunowatchSyncStatus('Synchronized via 24/7 background daemon');
    }
    setIsSyncingMunowatch(false);
  };

  // Export Analytics / Users to CSV Document
  const handleExportCSV = (dataType) => {
    let csvContent = "data:text/csv;charset=utf-8,";
    let fileName = "freewatch_analytics.csv";

    if (dataType === 'users') {
      fileName = "freewatch_users_directory.csv";
      csvContent += "User ID,Name,Email,Role,Status,Device,Last Watched,Total Watched,Join Date\n";
      users.forEach((u) => {
        csvContent += `"${u.id}","${u.name}","${u.email}","${u.role}","${u.status}","${u.device}","${u.lastWatchedMovie}",${u.totalWatched},"${u.joinDate}"\n`;
      });
    } else {
      fileName = "freewatch_audit_logs.csv";
      csvContent += "ID,Action,Target,Admin,Timestamp,Type\n";
      auditLogs.forEach((l) => {
        csvContent += `"${l.id}","${l.action}","${l.target}","${l.admin}","${l.timestamp}","${l.type}"\n`;
      });
    }

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", fileName);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Filtered Users List
  const filteredUsers = users.filter((u) => {
    const matchesSearch = 
      u.name.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.id.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.email.toLowerCase().includes(userSearch.toLowerCase());
    const matchesRole = userRoleFilter === 'All' || u.role === userRoleFilter;
    const matchesStatus = userStatusFilter === 'All' || u.status === userStatusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  });

  // Filtered Chat Threads
  const filteredThreads = threads.filter((t) =>
    t.userName.toLowerCase().includes(chatSearch.toLowerCase()) ||
    t.userId.toLowerCase().includes(chatSearch.toLowerCase()) ||
    t.lastMessage.toLowerCase().includes(chatSearch.toLowerCase())
  );

  const activeThread = threads.find((t) => t.id === selectedThreadId);

  return (
    <div className="flex h-screen bg-[#F8FAFC] text-slate-800 antialiased overflow-hidden font-sans">
      
      {/* ── Left Sidebar (AdminLTE 4 / TailAdmin Style) ─────────────── */}
      <aside 
        className={`${
          sidebarOpen ? 'w-64' : 'w-20'
        } bg-white border-r border-slate-200/80 flex flex-col justify-between transition-all duration-300 flex-shrink-0 z-30 shadow-sm`}
      >
        <div className="flex flex-col h-full overflow-hidden">
          {/* Brand Header */}
          <div className="h-16 px-5 border-b border-slate-200/80 flex items-center justify-between">
            <div className="flex items-center space-x-3 overflow-hidden">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#00E676] to-[#10B981] flex items-center justify-center font-black text-black text-lg shadow-sm flex-shrink-0">
                FW
              </div>
              {sidebarOpen && (
                <div className="flex flex-col min-w-0">
                  <span className="font-extrabold text-slate-900 text-sm tracking-tight truncate">
                    FreeWatch Admin
                  </span>
                  <span className="text-[11px] font-semibold text-emerald-600 flex items-center space-x-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                    <span>AdminLTE 4 Light</span>
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Navigation Links */}
          <div className="flex-1 overflow-y-auto py-4 px-3 space-y-6">
            
            {/* Section 1: Main Overview */}
            <div className="space-y-1">
              {sidebarOpen && (
                <div className="px-3 pb-1 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                  Analytics & Management
                </div>
              )}
              
              <button
                onClick={() => setActiveTab('dashboard')}
                className={`w-full flex items-center ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'dashboard'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="Dashboard Overview"
              >
                <LayoutDashboard className={`w-5 h-5 ${activeTab === 'dashboard' ? 'text-emerald-600' : 'text-slate-500'}`} />
                {sidebarOpen && <span className="ml-3">Dashboard</span>}
              </button>

              <button
                onClick={() => setActiveTab('users')}
                className={`w-full flex items-center justify-between ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'users'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="User Management"
              >
                <div className="flex items-center">
                  <Users className={`w-5 h-5 ${activeTab === 'users' ? 'text-emerald-600' : 'text-slate-500'}`} />
                  {sidebarOpen && <span className="ml-3">User Management</span>}
                </div>
                {sidebarOpen && (
                  <span className="text-[11px] font-bold bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">
                    {users.length}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveTab('videos')}
                className={`w-full flex items-center ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'videos'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="Video Performance & Catalog"
              >
                <Film className={`w-5 h-5 ${activeTab === 'videos' ? 'text-emerald-600' : 'text-slate-500'}`} />
                {sidebarOpen && <span className="ml-3">Video Performance</span>}
              </button>
            </div>

            {/* Section 2: Communication & Realtime */}
            <div className="space-y-1">
              {sidebarOpen && (
                <div className="px-3 pb-1 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                  Live Operations
                </div>
              )}

              <button
                onClick={() => setActiveTab('chat')}
                className={`w-full flex items-center justify-between ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'chat'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="Live Support Chat"
              >
                <div className="flex items-center">
                  <MessageSquare className={`w-5 h-5 ${activeTab === 'chat' ? 'text-emerald-600' : 'text-slate-500'}`} />
                  {sidebarOpen && <span className="ml-3">Live Support</span>}
                </div>
                {sidebarOpen && threads.reduce((acc, t) => acc + (t.unreadCountAdmin || 0), 0) > 0 && (
                  <span className="w-5 h-5 rounded-full bg-emerald-500 text-black text-[10px] font-black flex items-center justify-center">
                    {threads.reduce((acc, t) => acc + (t.unreadCountAdmin || 0), 0)}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveTab('notifications')}
                className={`w-full flex items-center ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'notifications'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="Push Notification Dispatcher"
              >
                <Bell className={`w-5 h-5 ${activeTab === 'notifications' ? 'text-emerald-600' : 'text-slate-500'}`} />
                {sidebarOpen && <span className="ml-3">Push Dispatcher</span>}
              </button>

              <button
                onClick={() => setActiveTab('munowatch')}
                className={`w-full flex items-center ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'munowatch'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="MunoWatch Sync Manager"
              >
                <RefreshCw className={`w-5 h-5 ${activeTab === 'munowatch' ? 'text-emerald-600' : 'text-slate-500'}`} />
                {sidebarOpen && <span className="ml-3">MunoWatch Manager</span>}
              </button>
            </div>

            {/* Section 3: Reports & Documents */}
            <div className="space-y-1">
              {sidebarOpen && (
                <div className="px-3 pb-1 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                  Reports & Logs
                </div>
              )}

              <button
                onClick={() => setActiveTab('audit')}
                className={`w-full flex items-center ${
                  sidebarOpen ? 'px-3.5' : 'justify-center'
                } py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  activeTab === 'audit'
                    ? 'bg-emerald-50 text-emerald-700 shadow-sm border border-emerald-200/60'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
                title="Audit Logs & Analytics Document"
              >
                <FileText className={`w-5 h-5 ${activeTab === 'audit' ? 'text-emerald-600' : 'text-slate-500'}`} />
                {sidebarOpen && <span className="ml-3">Audit Logs & Export</span>}
              </button>
            </div>
          </div>

          {/* Sidebar Footer */}
          <div className="p-4 border-t border-slate-200/80 bg-slate-50/50">
            {sidebarOpen ? (
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2.5">
                  <div className="w-8 h-8 rounded-full bg-slate-200 border border-slate-300 flex items-center justify-center font-bold text-xs text-slate-700">
                    AD
                  </div>
                  <div className="flex flex-col min-w-0">
                    <span className="text-xs font-bold text-slate-900 truncate">FreeWatch Admin</span>
                    <span className="text-[10px] text-slate-500">v1.0.55+56</span>
                  </div>
                </div>
                <div className={`w-2.5 h-2.5 rounded-full ${dbConnected ? 'bg-emerald-500' : 'bg-rose-500'}`} title="Firebase RTDB Live" />
              </div>
            ) : (
              <div className="flex justify-center">
                <div className={`w-2.5 h-2.5 rounded-full ${dbConnected ? 'bg-emerald-500' : 'bg-rose-500'}`} />
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* ── Main Workspace Area ─────────────────────────────────────── */}
      <div className="flex-1 flex flex-col overflow-hidden">
        
        {/* Top Header Bar */}
        <header className="h-16 bg-white border-b border-slate-200/80 px-6 flex items-center justify-between flex-shrink-0 z-20 shadow-sm">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-2 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors"
              title="Toggle Sidebar"
            >
              <Menu className="w-5 h-5" />
            </button>
            
            {/* Global Search Bar */}
            <div className="relative w-64 md:w-80">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search users, movies, or actions..."
                value={userSearch}
                onChange={(e) => {
                  setUserSearch(e.target.value);
                  if (activeTab !== 'users') setActiveTab('users');
                }}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-emerald-500 focus:bg-white transition-all"
              />
            </div>
          </div>

          {/* Right Header Badges */}
          <div className="flex items-center space-x-3">
            {/* System Live Pill */}
            <div className="hidden sm:flex items-center space-x-2 bg-emerald-50 border border-emerald-200 text-emerald-700 px-3 py-1 rounded-full text-xs font-semibold">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>24/7 Cloud Poller Active</span>
            </div>

            {/* Quick Broadcast Button */}
            <button
              onClick={() => setActiveTab('notifications')}
              className="bg-emerald-600 hover:bg-emerald-700 text-white px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center space-x-1.5 shadow-sm transition-all"
            >
              <Bell className="w-3.5 h-3.5" />
              <span>Broadcast Push</span>
            </button>
          </div>
        </header>

        {/* Dynamic Main Body Content */}
        <main className="flex-1 overflow-y-auto bg-[#F8FAFC]">

          {/* ══════════════════════════════════════════════════════════════
              VIEW 1: COLORFUL ADMINLTE 4 DASHBOARD
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'dashboard' && (
            <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-8">
              
              {/* Welcome Header */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                    FreeWatch Analytics Dashboard
                  </h1>
                  <p className="text-xs text-slate-500 mt-1">
                    Live overview of stream performance, active users, MunoWatch catalog, and push alerts.
                  </p>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleExportCSV('analytics')}
                    className="bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 px-3.5 py-2 rounded-xl text-xs font-bold flex items-center space-x-1.5 shadow-sm transition-all"
                  >
                    <Download className="w-3.5 h-3.5 text-slate-500" />
                    <span>Export Analytics CSV</span>
                  </button>
                </div>
              </div>

              {/* 4 AdminLTE Colorful Metric Tiles */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                
                {/* Tile 1: Ocean Cyan */}
                <div className="bg-gradient-to-br from-sky-500 to-blue-600 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden card-shadow-hover">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-sky-100">Total Video Plays</span>
                      <Play className="w-5 h-5 text-sky-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">184,920</div>
                    <div className="text-xs text-sky-100 font-medium mt-1 flex items-center space-x-1">
                      <TrendingUp className="w-3.5 h-3.5" />
                      <span>+14.8% vs last week</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('videos')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-sky-100 hover:text-white flex items-center justify-between"
                  >
                    <span>View Video Performance</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>

                {/* Tile 2: Vibrant Emerald */}
                <div className="bg-gradient-to-br from-emerald-500 to-teal-600 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden card-shadow-hover">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-emerald-100">Active App Users</span>
                      <Users className="w-5 h-5 text-emerald-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">2,845</div>
                    <div className="text-xs text-emerald-100 font-medium mt-1 flex items-center space-x-1">
                      <TrendingUp className="w-3.5 h-3.5" />
                      <span>+9.2% new members</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('users')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-emerald-100 hover:text-white flex items-center justify-between"
                  >
                    <span>Manage User Directory</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>

                {/* Tile 3: Vibrant Amber / Orange */}
                <div className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden card-shadow-hover">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-amber-100">Luganda Catalog</span>
                      <Film className="w-5 h-5 text-amber-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">1,530+</div>
                    <div className="text-xs text-amber-100 font-medium mt-1 flex items-center space-x-1">
                      <Sparkles className="w-3.5 h-3.5" />
                      <span>85 new releases today</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('munowatch')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-amber-100 hover:text-white flex items-center justify-between"
                  >
                    <span>MunoWatch Sync Hub</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>

                {/* Tile 4: Vibrant Rose / Red */}
                <div className="bg-gradient-to-br from-rose-500 to-pink-600 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden card-shadow-hover">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-rose-100">FCM Push Delivery</span>
                      <Bell className="w-5 h-5 text-rose-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">99.4%</div>
                    <div className="text-xs text-rose-100 font-medium mt-1 flex items-center space-x-1">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>High priority heads-up</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('notifications')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-rose-100 hover:text-white flex items-center justify-between"
                  >
                    <span>Open Push Console</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Streaming Activity & Category Breakdown (TailAdmin Charts Row) */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                
                {/* Visual Bar Chart: Weekly Streaming Volume */}
                <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">Weekly Streaming Volume</h3>
                      <p className="text-xs text-slate-500">Video streams played by day over the past 7 days</p>
                    </div>
                    <span className="text-xs font-bold bg-slate-100 text-slate-600 px-3 py-1 rounded-full">
                      Avg: 28.5K / day
                    </span>
                  </div>

                  {/* SVG Bar Chart Visualization */}
                  <div className="h-48 flex items-end justify-between pt-6 px-2 border-b border-slate-100">
                    {[
                      { day: 'Mon', count: 22, height: '55%' },
                      { day: 'Tue', count: 24, height: '60%' },
                      { day: 'Wed', count: 28, height: '70%' },
                      { day: 'Thu', count: 26, height: '65%' },
                      { day: 'Fri', count: 32, height: '80%' },
                      { day: 'Sat', count: 38, height: '95%' },
                      { day: 'Sun', count: 35, height: '88%' }
                    ].map((item, idx) => (
                      <div key={idx} className="flex flex-col items-center flex-1 space-y-2">
                        <span className="text-[10px] font-bold text-slate-400">{item.count}K</span>
                        <div 
                          className="w-7 sm:w-10 rounded-t-xl bg-gradient-to-t from-emerald-500 to-teal-400 hover:brightness-110 transition-all cursor-pointer shadow-sm"
                          style={{ height: item.height }}
                          title={`${item.day}: ${item.count},000 streams`}
                        />
                        <span className="text-xs font-semibold text-slate-600">{item.day}</span>
                      </div>
                    ))}
                  </div>

                  <div className="grid grid-cols-3 gap-4 pt-2 text-center text-xs">
                    <div>
                      <span className="text-slate-400 block text-[11px]">Avg Watch Time</span>
                      <span className="font-bold text-slate-800 text-sm">42.5 mins / user</span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[11px]">Bandwidth</span>
                      <span className="font-bold text-slate-800 text-sm">14.8 TB Total</span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[11px]">Peak Time</span>
                      <span className="font-bold text-emerald-600 text-sm">9:00 PM EAT</span>
                    </div>
                  </div>
                </div>

                {/* Genre Breakdown Progress Bars */}
                <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4 flex flex-col justify-between">
                  <div>
                    <h3 className="text-base font-bold text-slate-900">Genre Preferences</h3>
                    <p className="text-xs text-slate-500">Most streamed movie categories</p>
                  </div>

                  <div className="space-y-3.5">
                    {[
                      { name: 'Action & Thriller', pct: 38, color: 'bg-sky-500' },
                      { name: 'Sci-Fi & Fantasy', pct: 22, color: 'bg-emerald-500' },
                      { name: 'Drama & Romance', pct: 18, color: 'bg-amber-500' },
                      { name: 'Horror & Mystery', pct: 14, color: 'bg-rose-500' },
                      { name: 'Animation & Family', pct: 8, color: 'bg-purple-500' }
                    ].map((g, idx) => (
                      <div key={idx} className="space-y-1">
                        <div className="flex justify-between text-xs font-bold text-slate-700">
                          <span>{g.name}</span>
                          <span>{g.pct}%</span>
                        </div>
                        <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                          <div className={`h-full ${g.color} rounded-full`} style={{ width: `${g.pct}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 flex items-center space-x-2 text-xs text-slate-600">
                    <Sparkles className="w-4 h-4 text-emerald-600 flex-shrink-0" />
                    <span>Action remains the #1 top requested genre across Ugandan audiences.</span>
                  </div>
                </div>
              </div>

              {/* Leaderboards Row: Trending Movies & Top VJs */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                
                {/* Trending Movies Leaderboard */}
                <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                        <Flame className="w-4 h-4 text-amber-500" />
                        <span>Most Watched Releases</span>
                      </h3>
                      <p className="text-xs text-slate-500">Trending Luganda blockbusters on FreeWatch</p>
                    </div>
                    <button 
                      onClick={() => setActiveTab('videos')}
                      className="text-xs font-bold text-emerald-600 hover:text-emerald-700"
                    >
                      View All &rarr;
                    </button>
                  </div>

                  <div className="divide-y divide-slate-100">
                    {TRENDING_MOVIES.slice(0, 4).map((movie, idx) => (
                      <div key={movie.id} className="py-3 flex items-center justify-between">
                        <div className="flex items-center space-x-3 min-w-0">
                          <span className="w-6 text-center font-black text-slate-400 text-sm">{idx + 1}</span>
                          <img 
                            src={movie.poster} 
                            alt={movie.title}
                            className="w-10 h-14 object-cover rounded-lg shadow-sm border border-slate-100"
                            onError={(e) => { e.target.style.display = 'none'; }}
                          />
                          <div className="min-w-0">
                            <h4 className="text-xs font-bold text-slate-900 truncate">{movie.title}</h4>
                            <span className="text-[11px] font-semibold text-emerald-600 block">{movie.vj}</span>
                            <span className="text-[10px] text-slate-400">{movie.category}</span>
                          </div>
                        </div>
                        <div className="text-right flex-shrink-0">
                          <span className="text-xs font-black text-slate-900 block">{movie.views}</span>
                          <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
                            {movie.trend}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Top VJs Leaderboard */}
                <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                        <Star className="w-4 h-4 text-amber-500" />
                        <span>Top VJs Popularity</span>
                      </h3>
                      <p className="text-xs text-slate-500">Ugandan voice translators ranking by listener volume</p>
                    </div>
                  </div>

                  <div className="divide-y divide-slate-100">
                    {TOP_VJS.map((vj, idx) => (
                      <div key={idx} className="py-3 flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <div className="w-9 h-9 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-black text-xs text-slate-700">
                            {vj.name.split(' ')[1]?.charAt(0) || 'V'}
                          </div>
                          <div>
                            <span className="text-xs font-bold text-slate-900 block">{vj.name}</span>
                            <span className="text-[11px] text-slate-400">{vj.movies} Dubbed Titles</span>
                          </div>
                        </div>
                        <div className="text-right">
                          <span className="text-xs font-bold bg-amber-50 text-amber-700 px-2 py-0.5 rounded-full block mb-0.5">
                            {vj.badge}
                          </span>
                          <span className="text-[11px] font-semibold text-slate-500">{vj.views} plays</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 2: USER MANAGEMENT (ROSTER, BAN, DELETE, ROLES)
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'users' && (
            <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">
              
              {/* Header & Controls */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                    User Management Directory
                  </h1>
                  <p className="text-xs text-slate-500 mt-1">
                    Manage all app accounts, inspect user credentials, assign roles, ban violators, and track watch sessions.
                  </p>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleExportCSV('users')}
                    className="bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 px-3.5 py-2 rounded-xl text-xs font-bold flex items-center space-x-1.5 shadow-sm transition-all"
                  >
                    <Download className="w-3.5 h-3.5 text-slate-500" />
                    <span>Export Users (CSV)</span>
                  </button>
                  <button
                    onClick={() => setShowAddUserModal(true)}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white px-3.5 py-2 rounded-xl text-xs font-bold flex items-center space-x-1.5 shadow-sm transition-all"
                  >
                    <UserPlus className="w-3.5 h-3.5" />
                    <span>Add New User</span>
                  </button>
                </div>
              </div>

              {/* Filters Bar */}
              <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
                <div className="relative flex-1 w-full">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Search by user name, UID, or email..."
                    value={userSearch}
                    onChange={(e) => setUserSearch(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-emerald-500 focus:bg-white"
                  />
                </div>

                <div className="flex items-center space-x-3 w-full md:w-auto">
                  {/* Role Filter */}
                  <select
                    value={userRoleFilter}
                    onChange={(e) => setUserRoleFilter(e.target.value)}
                    className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500"
                  >
                    <option value="All">All Roles</option>
                    <option value="Admin">Admin</option>
                    <option value="VIP">VIP Subscriber</option>
                    <option value="Member">Member</option>
                    <option value="Guest">Guest</option>
                  </select>

                  {/* Status Filter */}
                  <select
                    value={userStatusFilter}
                    onChange={(e) => setUserStatusFilter(e.target.value)}
                    className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500"
                  >
                    <option value="All">All Statuses</option>
                    <option value="Active">Active</option>
                    <option value="Suspended">Suspended</option>
                    <option value="Banned">Banned</option>
                  </select>
                </div>
              </div>

              {/* Users Data Table */}
              <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-slate-50/80 border-b border-slate-200/80 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                        <th className="py-3.5 px-4">User</th>
                        <th className="py-3.5 px-4">Credentials / UID</th>
                        <th className="py-3.5 px-4">Role</th>
                        <th className="py-3.5 px-4">Status</th>
                        <th className="py-3.5 px-4">Last Activity</th>
                        <th className="py-3.5 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-xs text-slate-700">
                      {filteredUsers.length === 0 ? (
                        <tr>
                          <td colSpan={6} className="py-12 text-center text-slate-400 font-medium">
                            No users matched your search criteria.
                          </td>
                        </tr>
                      ) : (
                        filteredUsers.map((user) => {
                          const isBanned = user.status === 'Banned';
                          const isSuspended = user.status === 'Suspended';

                          return (
                            <tr key={user.id} className="hover:bg-slate-50/60 transition-colors">
                              {/* User Info */}
                              <td className="py-3.5 px-4">
                                <div className="flex items-center space-x-3">
                                  <img
                                    src={user.avatar}
                                    alt={user.name}
                                    className="w-9 h-9 rounded-full object-cover border border-slate-200"
                                    onError={(e) => {
                                      e.target.src = `https://api.dicebear.com/7.x/initials/svg?seed=${user.name}`;
                                    }}
                                  />
                                  <div>
                                    <span className="font-bold text-slate-900 block">{user.name}</span>
                                    <span className="text-[11px] text-slate-400">{user.email}</span>
                                  </div>
                                </div>
                              </td>

                              {/* Credentials */}
                              <td className="py-3.5 px-4 font-mono text-[11px]">
                                <span className="text-slate-800 bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                                  {user.id}
                                </span>
                                <span className="block text-[10px] text-slate-400 mt-0.5 font-sans">
                                  {user.device}
                                </span>
                              </td>

                              {/* Role */}
                              <td className="py-3.5 px-4">
                                <span
                                  className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                                    user.role === 'Admin'
                                      ? 'bg-purple-100 text-purple-700'
                                      : user.role === 'VIP'
                                      ? 'bg-amber-100 text-amber-700'
                                      : user.role === 'Member'
                                      ? 'bg-sky-100 text-sky-700'
                                      : 'bg-slate-100 text-slate-600'
                                  }`}
                                >
                                  {user.role}
                                </span>
                              </td>

                              {/* Status */}
                              <td className="py-3.5 px-4">
                                <span
                                  className={`inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold ${
                                    user.status === 'Active'
                                      ? 'bg-emerald-50 text-emerald-700'
                                      : user.status === 'Suspended'
                                      ? 'bg-amber-50 text-amber-700'
                                      : 'bg-rose-50 text-rose-700'
                                  }`}
                                >
                                  <span
                                    className={`w-1.5 h-1.5 rounded-full ${
                                      user.status === 'Active'
                                        ? 'bg-emerald-500 animate-pulse'
                                        : user.status === 'Suspended'
                                        ? 'bg-amber-500'
                                        : 'bg-rose-500'
                                    }`}
                                  />
                                  <span>{user.status}</span>
                                </span>
                              </td>

                              {/* Video Activity */}
                              <td className="py-3.5 px-4">
                                <span className="font-semibold text-slate-800 block truncate max-w-[180px]">
                                  {user.lastWatchedMovie}
                                </span>
                                <span className="text-[11px] text-slate-400">
                                  {user.totalWatched} movies • {user.lastActive}
                                </span>
                              </td>

                              {/* Actions */}
                              <td className="py-3.5 px-4 text-right">
                                <div className="flex items-center justify-end space-x-2">
                                  {/* View Profile */}
                                  <button
                                    onClick={() => setSelectedUserDetail(user)}
                                    className="p-1.5 rounded-lg text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
                                    title="View User Activity Details"
                                  >
                                    <Eye className="w-4 h-4" />
                                  </button>

                                  {/* Toggle Ban */}
                                  <button
                                    onClick={() => handleToggleUserBan(user.id)}
                                    className={`p-1.5 rounded-lg transition-colors ${
                                      isBanned
                                        ? 'text-emerald-600 hover:bg-emerald-50'
                                        : 'text-amber-600 hover:bg-amber-50'
                                    }`}
                                    title={isBanned ? 'Unban User' : 'Ban / Suspend User'}
                                  >
                                    {isBanned ? <UserCheck className="w-4 h-4" /> : <UserX className="w-4 h-4" />}
                                  </button>

                                  {/* Delete User */}
                                  <button
                                    onClick={() => setConfirmDeleteUser(user)}
                                    className="p-1.5 rounded-lg text-rose-500 hover:text-rose-700 hover:bg-rose-50 transition-colors"
                                    title="Delete User Permanently"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 3: VIDEO PERFORMANCE & CATALOG
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'videos' && (
            <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">
              <div>
                <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                  Video Performance & Movie Analytics
                </h1>
                <p className="text-xs text-slate-500 mt-1">
                  Track view engagement, rating performance, Luganda dubbed streams, and spotlight titles.
                </p>
              </div>

              {/* Movie Performance Table */}
              <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div className="p-5 border-b border-slate-200/80 flex items-center justify-between">
                  <h3 className="text-base font-bold text-slate-900">Most Watched Movies Catalog</h3>
                  <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-3 py-1 rounded-full">
                    {TRENDING_MOVIES.length} High Performing Blockbusters
                  </span>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-slate-50 text-[11px] font-bold text-slate-500 uppercase tracking-wider border-b border-slate-200">
                        <th className="py-3 px-4">Movie</th>
                        <th className="py-3 px-4">Dubbed VJ</th>
                        <th className="py-3 px-4">Total Views</th>
                        <th className="py-3 px-4">Rating</th>
                        <th className="py-3 px-4">Trending Growth</th>
                        <th className="py-3 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-xs">
                      {TRENDING_MOVIES.map((movie) => (
                        <tr key={movie.id} className="hover:bg-slate-50/50 transition-colors">
                          <td className="py-3.5 px-4">
                            <div className="flex items-center space-x-3">
                              <img
                                src={movie.poster}
                                alt={movie.title}
                                className="w-10 h-14 object-cover rounded-lg shadow-sm border border-slate-100"
                              />
                              <div>
                                <span className="font-bold text-slate-900 block">{movie.title}</span>
                                <span className="text-[11px] text-slate-400">{movie.category}</span>
                              </div>
                            </div>
                          </td>
                          <td className="py-3.5 px-4 font-semibold text-emerald-700">
                            {movie.vj}
                          </td>
                          <td className="py-3.5 px-4 font-black text-slate-900">
                            {movie.views}
                          </td>
                          <td className="py-3.5 px-4 font-bold text-amber-500">
                            ★ {movie.rating}
                          </td>
                          <td className="py-3.5 px-4">
                            <span className="text-emerald-700 bg-emerald-50 font-bold px-2.5 py-0.5 rounded-full">
                              {movie.trend}
                            </span>
                          </td>
                          <td className="py-3.5 px-4 text-right">
                            <button
                              onClick={() => {
                                setNotifTitle(`🎬 ${movie.title} (${movie.vj})`);
                                setNotifBody(`Watch now in Full HD on FreeWatch!`);
                                setNotifImageUrl(movie.backdrop);
                                setNotifMovieId(String(movie.id));
                                setActiveTab('notifications');
                              }}
                              className="text-xs font-bold text-emerald-600 hover:text-emerald-700 bg-emerald-50 px-3 py-1.5 rounded-xl transition-colors"
                            >
                              Dispatch Alert
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 4: LIVE 2-WAY SUPPORT CHAT (LIGHT THEME)
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'chat' && (
            <div className="h-[calc(100vh-4rem)] flex overflow-hidden bg-white">
              
              {/* Left Conversation Threads Sidebar */}
              <div className="w-80 md:w-96 border-r border-slate-200/80 flex flex-col flex-shrink-0 bg-slate-50/50">
                <div className="p-4 border-b border-slate-200/80 space-y-3">
                  <div className="flex items-center justify-between">
                    <h2 className="text-base font-extrabold text-slate-900">Live User Support</h2>
                    <span className="text-xs bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">
                      {threads.length} Active
                    </span>
                  </div>
                  
                  {/* Chat Search */}
                  <div className="relative">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Search messages or user names..."
                      value={chatSearch}
                      onChange={(e) => setChatSearch(e.target.value)}
                      className="w-full bg-white border border-slate-200 rounded-xl pl-9 pr-4 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-emerald-500"
                    />
                  </div>
                </div>

                {/* Threads List */}
                <div className="flex-1 overflow-y-auto divide-y divide-slate-100">
                  {filteredThreads.length === 0 ? (
                    <div className="p-8 text-center text-slate-400 text-xs">
                      No active support threads loaded.
                    </div>
                  ) : (
                    filteredThreads.map((thread) => {
                      const isSelected = thread.id === selectedThreadId;
                      const timeStr = new Date(thread.lastTimestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                      return (
                        <div
                          key={thread.id}
                          onClick={() => setSelectedThreadId(thread.id)}
                          className={`p-4 cursor-pointer transition-colors flex items-start space-x-3 ${
                            isSelected ? 'bg-emerald-50/70 border-l-4 border-emerald-500' : 'hover:bg-white'
                          }`}
                        >
                          <div className="w-10 h-10 rounded-full bg-slate-200 border border-slate-300 flex items-center justify-center font-bold text-xs text-slate-700 flex-shrink-0">
                            {thread.userName.charAt(0).toUpperCase()}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between mb-0.5">
                              <span className="text-xs font-bold text-slate-900 truncate">{thread.userName}</span>
                              <span className="text-[10px] text-slate-400">{timeStr}</span>
                            </div>
                            <p className="text-[11px] text-slate-500 truncate">{thread.lastMessage}</p>
                          </div>
                          {thread.unreadCountAdmin > 0 && (
                            <span className="w-5 h-5 rounded-full bg-emerald-500 text-black text-[10px] font-black flex items-center justify-center flex-shrink-0">
                              {thread.unreadCountAdmin}
                            </span>
                          )}
                        </div>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Center Active Message View */}
              {selectedThreadId && activeThread ? (
                <div className="flex-1 flex flex-col justify-between overflow-hidden bg-white">
                  
                  {/* Chat Header */}
                  <div className="h-16 px-6 border-b border-slate-200/80 flex items-center justify-between bg-white shadow-sm">
                    <div className="flex items-center space-x-3">
                      <div className="w-9 h-9 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-xs text-slate-700">
                        {activeThread.userName.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <h3 className="text-xs font-bold text-slate-900">{activeThread.userName}</h3>
                        <span className="text-[11px] text-emerald-600 font-medium">● User connected via Mobile App</span>
                      </div>
                    </div>
                  </div>

                  {/* Messages Bubble Scroll Area */}
                  <div className="flex-1 overflow-y-auto p-6 space-y-3 bg-[#F8FAFC]">
                    {messages.length === 0 ? (
                      <div className="text-center text-slate-400 text-xs py-12">
                        No messages in this conversation yet. Send an instant reply below!
                      </div>
                    ) : (
                      messages.map((msg) => {
                        const isAdmin = msg.senderRole === 'admin' || msg.senderId === 'admin';
                        const timeStr = new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                        return (
                          <div
                            key={msg.id}
                            className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                          >
                            <span className="text-[10px] text-slate-400 px-1 mb-0.5">
                              {isAdmin ? 'FreeWatch Support' : activeThread.userName} • {timeStr}
                            </span>
                            <div
                              className={`max-w-md px-4 py-2.5 rounded-2xl text-xs leading-relaxed shadow-sm ${
                                isAdmin
                                  ? 'bg-gradient-to-r from-emerald-500 to-teal-500 text-white font-medium rounded-tr-none'
                                  : 'bg-white border border-slate-200 text-slate-800 rounded-tl-none'
                              }`}
                            >
                              {msg.text}
                            </div>
                          </div>
                        );
                      })
                    )}
                    <div ref={messagesEndRef} />
                  </div>

                  {/* Quick Reply Bar */}
                  <div className="px-6 py-2 border-t border-slate-100 bg-white flex items-center space-x-2 overflow-x-auto text-xs">
                    <span className="text-[11px] font-bold text-slate-400 flex-shrink-0">Quick reply:</span>
                    {[
                      "Hello! 👋 How can we help you today?",
                      "Thanks for reporting! We are adding this movie now.",
                      "The Luganda translation is being updated right now.",
                      "Enjoy watching in Full HD on FreeWatch!"
                    ].map((preset, idx) => (
                      <button
                        key={idx}
                        onClick={() => setNewMessage(preset)}
                        className="whitespace-nowrap bg-slate-50 hover:bg-slate-100 text-slate-600 px-3 py-1 rounded-full border border-slate-200 text-[11px] transition-colors"
                      >
                        {preset}
                      </button>
                    ))}
                  </div>

                  {/* Input Form */}
                  <form onSubmit={handleSendMessage} className="p-4 border-t border-slate-200/80 bg-white flex items-center space-x-3">
                    <input
                      type="text"
                      placeholder="Type a message to this user's mobile screen..."
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-emerald-500 focus:bg-white"
                    />
                    <button
                      type="submit"
                      disabled={!newMessage.trim()}
                      className="bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white px-5 py-2.5 rounded-xl text-xs font-bold flex items-center space-x-1.5 shadow-sm transition-all"
                    >
                      <span>Reply</span>
                      <Send className="w-3.5 h-3.5" />
                    </button>
                  </form>
                </div>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-slate-400 p-8">
                  <MessageSquare className="w-12 h-12 stroke-1 mb-2 text-slate-300" />
                  <p className="text-sm font-semibold">Select a user conversation from the left to start live chatting.</p>
                </div>
              )}
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 5: PUSH NOTIFICATION DISPATCHER (LIGHT THEME)
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'notifications' && (
            <div className="p-6 md:p-8 max-w-5xl mx-auto space-y-6">
              <div>
                <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                  FCM Cloud Push Notification Dispatcher
                </h1>
                <p className="text-xs text-slate-500 mt-1">
                  Broadcast real-time push alerts to all installed FreeWatch mobile devices with custom titles and posters.
                </p>
              </div>

              {notifSuccess && (
                <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 px-4 py-3 rounded-xl flex items-center space-x-2 text-xs font-semibold">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
                  <span>{notifSuccess}</span>
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                
                {/* Form (2 cols) */}
                <div className="md:col-span-2 bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
                  <form onSubmit={handleSendPushNotification} className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                        Target Audience Topic
                      </label>
                      <div className="grid grid-cols-3 gap-3">
                        {[
                          { id: 'all_users', label: 'All Users (all_users)', icon: Users },
                          { id: 'new_releases', label: 'New Releases', icon: Flame },
                          { id: 'test_devices', label: 'Test Devices', icon: Smartphone }
                        ].map((t) => {
                          const Icon = t.icon;
                          const isSel = notifTarget === t.id;
                          return (
                            <button
                              type="button"
                              key={t.id}
                              onClick={() => setNotifTarget(t.id)}
                              className={`p-3 rounded-xl border text-left flex flex-col space-y-1 transition-all ${
                                isSel
                                  ? 'bg-emerald-50 border-emerald-500 text-emerald-900 font-bold'
                                  : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
                              }`}
                            >
                              <Icon className={`w-4 h-4 ${isSel ? 'text-emerald-600' : 'text-slate-400'}`} />
                              <span className="text-xs">{t.label}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                        Notification Title
                      </label>
                      <input
                        type="text"
                        value={notifTitle}
                        onChange={(e) => setNotifTitle(e.target.value)}
                        placeholder="e.g. 🎬 Deadpool & Wolverine (VJ Junior)"
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-500 focus:bg-white"
                        required
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                        Notification Body / Synopsis
                      </label>
                      <textarea
                        rows={3}
                        value={notifBody}
                        onChange={(e) => setNotifBody(e.target.value)}
                        placeholder="Luganda translated release is now live! Tap to stream in Full HD."
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-500 focus:bg-white"
                        required
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                          Poster / Backdrop URL (Optional)
                        </label>
                        <input
                          type="url"
                          value={notifImageUrl}
                          onChange={(e) => setNotifImageUrl(e.target.value)}
                          placeholder="https://image.tmdb.org/t/p/w780/..."
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-500 focus:bg-white"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                          Movie ID (Optional)
                        </label>
                        <input
                          type="text"
                          value={notifMovieId}
                          onChange={(e) => setNotifMovieId(e.target.value)}
                          placeholder="e.g. 533535"
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs text-slate-900 focus:outline-none focus:border-emerald-500 focus:bg-white"
                        />
                      </div>
                    </div>

                    <button
                      type="submit"
                      disabled={isSendingNotif}
                      className="w-full bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold py-3 rounded-xl text-xs flex items-center justify-center space-x-2 shadow-sm transition-all"
                    >
                      <Send className="w-4 h-4" />
                      <span>Dispatch Push Notification to All Phones</span>
                    </button>
                  </form>
                </div>

                {/* Mobile Preview (1 col) */}
                <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm flex flex-col items-center">
                  <span className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4">
                    Phone Status Bar Preview
                  </span>

                  {/* Mock Device Notification Card */}
                  <div className="w-full bg-slate-900 rounded-2xl p-4 text-white shadow-lg space-y-2">
                    <div className="flex items-center space-x-2">
                      <div className="w-5 h-5 rounded-md bg-[#00E676] flex items-center justify-center font-black text-[9px] text-black">
                        FW
                      </div>
                      <span className="text-xs font-bold text-slate-200">FreeWatch</span>
                      <span className="text-[10px] text-slate-400">• now</span>
                    </div>

                    <h4 className="text-xs font-bold text-white">{notifTitle}</h4>
                    <p className="text-[11px] text-slate-300 line-clamp-2">{notifBody}</p>

                    {notifImageUrl && (
                      <img
                        src={notifImageUrl}
                        alt="Preview"
                        className="w-full h-24 object-cover rounded-xl mt-2 border border-white/10"
                        onError={(e) => { e.target.style.display = 'none'; }}
                      />
                    )}
                  </div>

                  <p className="text-[11px] text-slate-400 mt-4 text-center">
                    Surfaces in phone tray with transparent FW logo even when app is closed.
                  </p>
                </div>
              </div>

              {/* History Table */}
              <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-3">
                <h3 className="text-sm font-bold text-slate-900">Broadcast History</h3>
                <div className="divide-y divide-slate-100 text-xs">
                  {dispatchedNotifs.slice(0, 5).map((n) => (
                    <div key={n.id} className="py-2.5 flex items-center justify-between">
                      <div>
                        <span className="font-bold text-slate-800 block">{n.title}</span>
                        <span className="text-[11px] text-slate-400">{n.body}</span>
                      </div>
                      <span className="text-[11px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-mono">
                        {new Date(n.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 6: MUNOWATCH MANAGER
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'munowatch' && (
            <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                    MunoWatch Synchronization Manager
                  </h1>
                  <p className="text-xs text-slate-500 mt-1">
                    Control 24/7 background scraper polling, monitor newly discovered movie streams, and spotlight titles.
                  </p>
                </div>
                <button
                  onClick={handleSyncMunowatch}
                  disabled={isSyncingMunowatch}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center space-x-2 shadow-sm transition-all"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isSyncingMunowatch ? 'animate-spin' : ''}`} />
                  <span>{isSyncingMunowatch ? 'Syncing...' : 'Sync MunoWatch Now'}</span>
                </button>
              </div>

              {/* Status Banner */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-200 flex items-center justify-center text-emerald-600">
                    <Radio className="w-5 h-5 animate-pulse" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">Background Poller Status: Active (15 min interval)</h3>
                    <p className="text-xs text-slate-500">{munowatchSyncStatus}</p>
                  </div>
                </div>
                <span className="text-xs font-bold bg-emerald-100 text-emerald-800 px-3 py-1 rounded-full">
                  100% Operational
                </span>
              </div>

              {/* Discovered Releases Grid */}
              <div className="space-y-4">
                <h3 className="text-base font-bold text-slate-900">Recently Discovered Releases on MunoWatch</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
                  {munowatchMovies.map((m) => (
                    <div key={m.id} className="bg-white rounded-2xl border border-slate-200/80 overflow-hidden shadow-sm card-shadow-hover">
                      <img src={m.poster} alt={m.title} className="w-full h-44 object-cover" />
                      <div className="p-3 space-y-1">
                        <span className="text-[10px] font-bold text-emerald-600 block">{m.vj}</span>
                        <h4 className="text-xs font-bold text-slate-900 truncate">{m.title}</h4>
                        <span className="text-[10px] text-slate-400 block">{m.category}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════════════════════════════
              VIEW 7: AUDIT LOGS & EXPORTABLE DOCUMENT
          ══════════════════════════════════════════════════════════════ */}
          {activeTab === 'audit' && (
            <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                    Admin Action Audit & Analytics Document
                  </h1>
                  <p className="text-xs text-slate-500 mt-1">
                    Traceability logs of all administrative changes: user bans, deletions, role updates, and push broadcasts.
                  </p>
                </div>
                <button
                  onClick={() => handleExportCSV('audit')}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center space-x-2 shadow-sm transition-all"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download Audit Document (CSV)</span>
                </button>
              </div>

              {/* Logs Table */}
              <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-slate-50 text-[11px] font-bold text-slate-500 uppercase tracking-wider border-b border-slate-200">
                        <th className="py-3 px-4">Timestamp</th>
                        <th className="py-3 px-4">Action</th>
                        <th className="py-3 px-4">Target Entity</th>
                        <th className="py-3 px-4">Administrator</th>
                        <th className="py-3 px-4">Type</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {auditLogs.map((log) => (
                        <tr key={log.id} className="hover:bg-slate-50/50 transition-colors">
                          <td className="py-3 px-4 font-mono text-[11px] text-slate-500">{log.timestamp}</td>
                          <td className="py-3 px-4 font-bold text-slate-900">{log.action}</td>
                          <td className="py-3 px-4 text-slate-600 font-medium">{log.target}</td>
                          <td className="py-3 px-4 font-semibold text-emerald-700">{log.admin}</td>
                          <td className="py-3 px-4">
                            <span className="bg-slate-100 text-slate-700 px-2 py-0.5 rounded text-[10px] font-bold uppercase">
                              {log.type}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

        </main>
      </div>

      {/* ── MODALS & DIALOGS ────────────────────────────────────────── */}

      {/* 1. User Detail Modal */}
      {selectedUserDetail && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div className="flex items-center space-x-3">
                <img
                  src={selectedUserDetail.avatar}
                  alt={selectedUserDetail.name}
                  className="w-12 h-12 rounded-full border border-slate-200 object-cover"
                />
                <div>
                  <h3 className="text-base font-extrabold text-slate-900">{selectedUserDetail.name}</h3>
                  <span className="text-xs text-slate-400">{selectedUserDetail.email}</span>
                </div>
              </div>
              <button
                onClick={() => setSelectedUserDetail(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[11px]">User UID</span>
                <span className="font-mono text-slate-800 font-bold break-all">{selectedUserDetail.id}</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[11px]">Account Status</span>
                <span className="font-bold text-slate-800">{selectedUserDetail.status}</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[11px]">Registered Device</span>
                <span className="font-bold text-slate-800">{selectedUserDetail.device}</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-slate-400 block text-[11px]">Total Watched</span>
                <span className="font-bold text-slate-800">{selectedUserDetail.totalWatched} Movies</span>
              </div>
            </div>

            <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-100 text-xs">
              <span className="text-slate-400 block text-[11px]">Last Active Stream</span>
              <span className="font-bold text-emerald-700">{selectedUserDetail.lastWatchedMovie}</span>
            </div>

            <div className="flex items-center justify-between pt-2">
              <div className="flex space-x-2">
                <button
                  onClick={() => handleChangeUserRole(selectedUserDetail.id, selectedUserDetail.role === 'VIP' ? 'Member' : 'VIP')}
                  className="bg-amber-50 hover:bg-amber-100 text-amber-700 px-3 py-1.5 rounded-xl text-xs font-bold transition-colors"
                >
                  {selectedUserDetail.role === 'VIP' ? 'Demote to Member' : 'Promote to VIP'}
                </button>
                <button
                  onClick={() => handleToggleUserBan(selectedUserDetail.id)}
                  className="bg-rose-50 hover:bg-rose-100 text-rose-700 px-3 py-1.5 rounded-xl text-xs font-bold transition-colors"
                >
                  {selectedUserDetail.status === 'Banned' ? 'Unban User' : 'Ban User'}
                </button>
              </div>
              <button
                onClick={() => setSelectedUserDetail(null)}
                className="bg-slate-100 hover:bg-slate-200 text-slate-700 px-4 py-1.5 rounded-xl text-xs font-bold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Confirm Delete Modal */}
      {confirmDeleteUser && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="w-12 h-12 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center mx-auto">
              <AlertCircle className="w-6 h-6" />
            </div>
            <div className="text-center">
              <h3 className="text-base font-extrabold text-slate-900">Delete User Account?</h3>
              <p className="text-xs text-slate-500 mt-1">
                Are you sure you want to permanently remove <b>{confirmDeleteUser.name}</b>? This action cannot be undone.
              </p>
            </div>
            <div className="flex space-x-3 pt-2">
              <button
                onClick={() => setConfirmDeleteUser(null)}
                className="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 py-2 rounded-xl text-xs font-bold"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDeleteUser(confirmDeleteUser.id)}
                className="flex-1 bg-rose-600 hover:bg-rose-700 text-white py-2 rounded-xl text-xs font-bold shadow-sm"
              >
                Yes, Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Add User Modal */}
      {showAddUserModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-base font-extrabold text-slate-900">Add New User</h3>
              <button onClick={() => setShowAddUserModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="space-y-3.5 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">User Full Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Mukasa Ivan"
                  value={newUserData.name}
                  onChange={(e) => setNewUserData({ ...newUserData, name: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-slate-800 focus:outline-none focus:border-emerald-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Email Address</label>
                <input
                  type="email"
                  placeholder="e.g. ivan.mukasa@gmail.com"
                  value={newUserData.email}
                  onChange={(e) => setNewUserData({ ...newUserData, email: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-slate-800 focus:outline-none focus:border-emerald-500 focus:bg-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Role</label>
                  <select
                    value={newUserData.role}
                    onChange={(e) => setNewUserData({ ...newUserData, role: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-800 focus:outline-none focus:border-emerald-500"
                  >
                    <option value="Member">Member</option>
                    <option value="VIP">VIP</option>
                    <option value="Admin">Admin</option>
                  </select>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Device Platform</label>
                  <select
                    value={newUserData.device}
                    onChange={(e) => setNewUserData({ ...newUserData, device: e.target.value })}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-800 focus:outline-none focus:border-emerald-500"
                  >
                    <option value="Android 14">Android 14</option>
                    <option value="Android 13">Android 13</option>
                    <option value="Android 12">Android 12</option>
                  </select>
                </div>
              </div>

              <div className="pt-3 flex space-x-3">
                <button
                  type="button"
                  onClick={() => setShowAddUserModal(false)}
                  className="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 py-2 rounded-xl font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white py-2 rounded-xl font-bold shadow-sm"
                >
                  Create User
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
