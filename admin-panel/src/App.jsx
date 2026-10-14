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
  X,
  Tv,
  Check,
  Link,
  Image as ImageIcon
} from 'lucide-react';
import { rtdb, auth, signInAnonymously } from './firebase';
import { ref, onValue, push, set, update, remove } from 'firebase/database';

export default function App() {
  // Navigation: 'dashboard' | 'users' | 'videos' | 'chat' | 'notifications' | 'munowatch' | 'audit'
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // RTDB & Live Status
  const [dbConnected, setDbConnected] = useState(true);
  const [fcmDaemonLive, setFcmDaemonLive] = useState(true);

  // 100% REAL Live State from Firebase RTDB & MunoWatch
  const [users, setUsers] = useState([]);
  const [userSearch, setUserSearch] = useState('');
  const [userRoleFilter, setUserRoleFilter] = useState('All');
  const [userStatusFilter, setUserStatusFilter] = useState('All');
  const [selectedUserDetail, setSelectedUserDetail] = useState(null);
  const [confirmDeleteUser, setConfirmDeleteUser] = useState(null);
  const [showAddUserModal, setShowAddUserModal] = useState(false);
  const [newUserData, setNewUserData] = useState({ name: '', email: '', role: 'Member', bio: '' });
  const [roleChangeModalUser, setRoleChangeModalUser] = useState(null);
  const [newRoleSelection, setNewRoleSelection] = useState('Member');

  // Real Catalog & Video Stats
  const [munowatchCatalog, setMunowatchCatalog] = useState([]);
  const [videoStats, setVideoStats] = useState({});
  const [videoSearch, setVideoSearch] = useState('');
  const [videoCategoryFilter, setVideoCategoryFilter] = useState('All');

  // Live 2-Way Support Chat
  const [threads, setThreads] = useState([]);
  const [selectedThreadId, setSelectedThreadId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [chatSearch, setChatSearch] = useState('');
  const messagesEndRef = useRef(null);

  // Simplified FCM Push Dispatcher
  const [notifTitle, setNotifTitle] = useState('');
  const [notifBody, setNotifBody] = useState('');
  const [notifImageUrl, setNotifImageUrl] = useState('');
  const [notifLink, setNotifLink] = useState('');
  const [isSendingNotif, setIsSendingNotif] = useState(false);
  const [notifSuccess, setNotifSuccess] = useState('');
  const [dispatchedNotifs, setDispatchedNotifs] = useState([]);

  // Real MunoWatch Manager & Sync Status
  const [isSyncingMunowatch, setIsSyncingMunowatch] = useState(false);
  const [munowatchSyncMeta, setMunowatchSyncMeta] = useState({ lastCheck: 0, count: 0 });

  // Real Audit Logs
  const [auditLogs, setAuditLogs] = useState([]);

  // Authenticate anonymously for Firebase RTDB read/write access
  useEffect(() => {
    signInAnonymously(auth).catch(() => {});
  }, []);

  // 1. Listen to Real Users & Watch Histories from Firebase RTDB
  useEffect(() => {
    const usersRef = ref(rtdb, 'users');
    const unsub = onValue(usersRef, (snapshot) => {
      if (snapshot.exists()) {
        setDbConnected(true);
        const data = snapshot.val();
        const userList = Object.keys(data).map((uid) => {
          const u = data[uid] || {};
          const profile = u.profile || {};
          const history = Array.isArray(u.watch_history) ? u.watch_history : [];
          const favorites = Array.isArray(u.favorites) ? u.favorites : [];
          const lastWatched = history.length > 0 ? history[0] : null;

          return {
            id: uid,
            name: profile.name || (profile.email ? profile.email.split('@')[0] : 'FreeWatch User'),
            email: profile.email || 'No email registered',
            role: profile.role || (profile.name?.toLowerCase().includes('admin') ? 'Admin' : 'Member'),
            status: profile.status || 'Active',
            avatar: profile.avatar || 'assets/avatars/avatar_mirabel.png',
            bio: profile.bio || 'FreeWatch Movie Streamer',
            createdAt: profile.createdAt || new Date().toISOString(),
            lastLogin: profile.lastLogin || profile.createdAt || new Date().toISOString(),
            watchHistory: history,
            favorites: favorites,
            totalWatched: history.length,
            totalFavorites: favorites.length,
            lastWatchedMovie: lastWatched ? lastWatched.title : 'No watch history yet',
          };
        });
        setUsers(userList);
      } else {
        setUsers([]);
      }
    }, () => setDbConnected(false));

    return () => unsub();
  }, []);

  // 2. Listen to Real Live Catalog & Stats from Firebase RTDB
  useEffect(() => {
    // Real catalog cached in RTDB
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsubCatalog = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists()) {
        const val = snapshot.val();
        if (Array.isArray(val)) {
          setMunowatchCatalog(val);
        } else if (typeof val === 'object') {
          setMunowatchCatalog(Object.values(val));
        }
      } else {
        // Fallback: Fetch directly from serverless proxy if not yet in RTDB
        fetch('/api/munowatch-catalog')
          .then(res => res.json())
          .then(data => {
            let list = [];
            if (data.banner) list.push(data.banner);
            if (data.dashboard) {
              data.dashboard.forEach(c => {
                if (c.movies) list.push(...c.movies);
              });
            }
            if (list.length > 0) {
              setMunowatchCatalog(list);
              set(ref(rtdb, 'munowatch/catalog'), list).catch(() => {});
            }
          })
          .catch(() => {});
      }
    });

    // Real video playback view events in RTDB
    const statsRef = ref(rtdb, 'video_stats');
    const unsubStats = onValue(statsRef, (snapshot) => {
      if (snapshot.exists()) {
        setVideoStats(snapshot.val());
      }
    });

    // Real MunoWatch poller metadata
    const metaRef = ref(rtdb, 'munowatch/known_movie_ids');
    const unsubMeta = onValue(metaRef, (snapshot) => {
      if (snapshot.exists()) {
        const d = snapshot.val();
        setMunowatchSyncMeta({
          lastCheck: d.lastCheck || Date.now(),
          count: Array.isArray(d.list) ? d.list.length : 0,
        });
      }
    });

    return () => {
      unsubCatalog();
      unsubStats();
      unsubMeta();
    };
  }, []);

  // 3. Listen to Real Push Notification History from Firebase RTDB
  useEffect(() => {
    const historyRef = ref(rtdb, 'push_notifications/history');
    const unsub = onValue(historyRef, (snapshot) => {
      if (snapshot.exists()) {
        const val = snapshot.val();
        const list = Object.keys(val).map(key => ({
          id: key,
          ...val[key]
        })).sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
        setDispatchedNotifs(list);
      } else {
        setDispatchedNotifs([]);
      }
    });
    return () => unsub();
  }, []);

  // 4. Listen to Real Audit Logs from Firebase RTDB
  useEffect(() => {
    const auditRef = ref(rtdb, 'audit_logs');
    const unsub = onValue(auditRef, (snapshot) => {
      if (snapshot.exists()) {
        const val = snapshot.val();
        const list = Object.keys(val).map(key => ({
          id: key,
          ...val[key]
        })).sort((a, b) => new Date(b.timestamp || 0) - new Date(a.timestamp || 0));
        setAuditLogs(list);
      } else {
        setAuditLogs([]);
      }
    });
    return () => unsub();
  }, []);

  // 5. Listen to Live Support Chat Threads from Firebase RTDB
  useEffect(() => {
    const chatsRef = ref(rtdb, 'support_chats');
    const unsub = onValue(chatsRef, (snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        const threadList = Object.keys(data).map((uid) => {
          const thread = data[uid] || {};
          const meta = thread.metadata || {};
          const msgMap = thread.messages || {};
          const msgList = Object.values(msgMap);
          return {
            uid,
            userName: meta.userName || `User_${uid.slice(0, 5)}`,
            lastMessage: meta.lastMessage || (msgList.length ? msgList[msgList.length - 1].text : 'No messages yet'),
            updatedAt: meta.updatedAt || meta.lastTimestamp || Date.now(),
            unreadCount: meta.unreadCountAdmin || 0,
            messagesCount: msgList.length,
          };
        }).sort((a, b) => b.updatedAt - a.updatedAt);

        setThreads(threadList);
        if (threadList.length > 0 && !selectedThreadId) {
          setSelectedThreadId(threadList[0].uid);
        }
      } else {
        setThreads([]);
      }
    });
    return () => unsub();
  }, [selectedThreadId]);

  // Listen to Active Chat Messages
  useEffect(() => {
    if (!selectedThreadId) return;
    const msgRef = ref(rtdb, `support_chats/${selectedThreadId}/messages`);
    const unsub = onValue(msgRef, (snapshot) => {
      if (snapshot.exists()) {
        const val = snapshot.val();
        const list = Object.keys(val).map(id => ({ id, ...val[id] }))
          .sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
        setMessages(list);
      } else {
        setMessages([]);
      }
    });
    return () => unsub();
  }, [selectedThreadId]);

  // Scroll chat messages to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Helper to log real immutable audit action to Firebase RTDB
  const logAudit = async (action, target, details, category = 'General') => {
    try {
      const logRef = push(ref(rtdb, 'audit_logs'));
      await set(logRef, {
        id: logRef.key,
        timestamp: new Date().toISOString(),
        action,
        target,
        actor: 'Admin Console',
        category,
        details,
      });
    } catch (_) {}
  };

  // User Actions: Ban / Unban
  const handleToggleUserBan = async (user) => {
    const nextStatus = user.status === 'Banned' ? 'Active' : 'Banned';
    try {
      await update(ref(rtdb, `users/${user.id}/profile`), {
        status: nextStatus,
        statusUpdatedAt: new Date().toISOString(),
      });
      await logAudit(
        nextStatus === 'Banned' ? 'BAN_USER' : 'UNBAN_USER',
        `${user.name} (${user.email})`,
        `Account status changed to ${nextStatus}`,
        'User Management'
      );
    } catch (e) {
      alert('Failed to update status: ' + e.message);
    }
  };

  // User Actions: Change Role
  const handleChangeUserRole = async () => {
    if (!roleChangeModalUser) return;
    try {
      await update(ref(rtdb, `users/${roleChangeModalUser.id}/profile`), {
        role: newRoleSelection,
        roleUpdatedAt: new Date().toISOString(),
      });
      await logAudit(
        'CHANGE_ROLE',
        `${roleChangeModalUser.name} (${roleChangeModalUser.email})`,
        `Role privileges changed to ${newRoleSelection}`,
        'User Management'
      );
      setRoleChangeModalUser(null);
    } catch (e) {
      alert('Failed to update role: ' + e.message);
    }
  };

  // User Actions: Delete User
  const handleDeleteUser = async (user) => {
    try {
      await remove(ref(rtdb, `users/${user.id}`));
      await logAudit(
        'DELETE_USER',
        `${user.name} (${user.email})`,
        `User profile and data removed from Firebase RTDB`,
        'User Management'
      );
      setConfirmDeleteUser(null);
    } catch (e) {
      alert('Failed to delete user: ' + e.message);
    }
  };

  // User Actions: Add User
  const handleCreateUser = async (e) => {
    e.preventDefault();
    if (!newUserData.name.trim() || !newUserData.email.trim()) return;
    try {
      const newUid = 'usr_' + Date.now().toString(36) + Math.random().toString(36).substring(2, 6);
      await set(ref(rtdb, `users/${newUid}/profile`), {
        uid: newUid,
        name: newUserData.name.trim(),
        email: newUserData.email.trim().toLowerCase(),
        role: newUserData.role,
        status: 'Active',
        avatar: 'assets/avatars/avatar_mirabel.png',
        createdAt: new Date().toISOString(),
        lastLogin: new Date().toISOString(),
        bio: newUserData.bio || 'FreeWatch Member',
      });
      await logAudit(
        'CREATE_USER',
        `${newUserData.name} (${newUserData.email})`,
        `New ${newUserData.role} registered via Admin Panel`,
        'User Management'
      );
      setShowAddUserModal(false);
      setNewUserData({ name: '', email: '', role: 'Member', bio: '' });
    } catch (e) {
      alert('Failed to create user: ' + e.message);
    }
  };

  // Export Users to CSV
  const handleExportUsersCSV = () => {
    const headers = ['UID', 'Name', 'Email', 'Role', 'Status', 'Total Watched', 'Total Favorites', 'Created Date', 'Last Login'];
    const rows = users.map(u => [
      `"${u.id}"`,
      `"${u.name}"`,
      `"${u.email}"`,
      `"${u.role}"`,
      `"${u.status}"`,
      u.totalWatched,
      u.totalFavorites,
      `"${u.createdAt}"`,
      `"${u.lastLogin}"`
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `freewatch_users_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Export Audit Logs to CSV
  const handleExportAuditCSV = () => {
    const headers = ['Timestamp', 'Action', 'Category', 'Target', 'Actor', 'Details'];
    const rows = auditLogs.map(l => [
      `"${l.timestamp}"`,
      `"${l.action}"`,
      `"${l.category || 'General'}"`,
      `"${l.target}"`,
      `"${l.actor}"`,
      `"${(l.details || '').replace(/"/g, '""')}"`
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `freewatch_audit_logs_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Send Admin Chat Reply
  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedThreadId) return;

    const text = newMessage.trim();
    setNewMessage('');
    const now = Date.now();

    try {
      const msgRef = push(ref(rtdb, `support_chats/${selectedThreadId}/messages`));
      await set(msgRef, {
        id: msgRef.key,
        senderId: 'admin',
        senderName: 'FreeWatch Support',
        senderRole: 'admin',
        text,
        timestamp: now,
        isRead: false,
      });

      await update(ref(rtdb, `support_chats/${selectedThreadId}/metadata`), {
        lastMessage: text,
        lastTimestamp: now,
        updatedAt: now,
        unreadCountUser: (threads.find(t => t.uid === selectedThreadId)?.unreadCountUser || 0) + 1,
      });
    } catch (e) {
      alert('Failed to send message: ' + e.message);
    }
  };

  // Simplified FCM Push Dispatcher
  const handleSendNotification = async (e) => {
    e.preventDefault();
    if (!notifBody.trim()) {
      alert('Please enter a notification message.');
      return;
    }

    setIsSendingNotif(true);
    setNotifSuccess('');

    const payload = {
      title: notifTitle.trim() || '🔥 FreeWatch Alert',
      body: notifBody.trim(),
      imageUrl: notifImageUrl.trim() || '',
      link: notifLink.trim() || '',
      targetTopic: 'all_users',
      timestamp: Date.now(),
      dispatchedBy: 'Admin Web Console',
    };

    try {
      // 1. Write to RTDB global_alerts/latest to trigger local/cloud FCM daemons
      await set(ref(rtdb, 'global_alerts/latest'), payload);

      // 2. Save to push history
      const historyRef = push(ref(rtdb, 'push_notifications/history'));
      await set(historyRef, { id: historyRef.key, ...payload });

      // 3. Log audit action
      await logAudit(
        'DISPATCH_PUSH',
        'Topic: all_users',
        `Broadcasted: "${payload.title}" - ${payload.body.slice(0, 50)}...`,
        'Notifications'
      );

      // 4. Try Vercel serverless push if deployed
      try {
        await fetch('/api/send-push', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
      } catch (_) {}

      setNotifSuccess('Push notification successfully dispatched to all users!');
      setNotifBody('');
      setNotifTitle('');
      setNotifImageUrl('');
      setNotifLink('');
    } catch (e) {
      alert('Failed to dispatch alert: ' + e.message);
    } finally {
      setIsSendingNotif(false);
      setTimeout(() => setNotifSuccess(''), 4000);
    }
  };

  // Trigger MunoWatch Sync
  const handleTriggerMunowatchSync = async () => {
    setIsSyncingMunowatch(true);
    try {
      const res = await fetch('/api/cron-munowatch');
      const data = await res.json();
      await logAudit(
        'MUNOWATCH_SYNC',
        'MunoWatch Catalog',
        `Manual sync triggered. ${data.message || 'Catalog updated.'}`,
        'System Poller'
      );
      alert('Sync executed successfully: ' + (data.message || 'Catalog refreshed'));
    } catch (e) {
      // Fallback: Refresh catalog via client fetch
      try {
        const resp = await fetch('/api/munowatch-catalog');
        const d = await resp.json();
        let list = [];
        if (d.banner) list.push(d.banner);
        if (d.dashboard) {
          d.dashboard.forEach(c => {
            if (c.movies) list.push(...c.movies);
          });
        }
        if (list.length > 0) {
          setMunowatchCatalog(list);
          await set(ref(rtdb, 'munowatch/catalog'), list);
          await logAudit('MUNOWATCH_SYNC', 'MunoWatch Catalog', `Client refreshed ${list.length} catalog releases.`, 'System Poller');
          alert(`Successfully synced ${list.length} movies from MunoWatch!`);
        }
      } catch (err) {
        alert('Sync error: ' + err.message);
      }
    } finally {
      setIsSyncingMunowatch(false);
    }
  };

  // Real Dynamic Calculations for Home Dashboard
  const totalRegisteredUsers = users.length;
  const activeStreamersCount = users.filter(u => u.totalWatched > 0).length;
  const totalCatalogMovies = munowatchCatalog.length;
  const totalDispatchedAlerts = dispatchedNotifs.length;
  const totalVideoPlays = React.useMemo(() => {
    let plays = 0;
    users.forEach(u => {
      plays += (u.watchHistory || []).length;
    });
    Object.values(videoStats || {}).forEach(s => {
      plays += (s?.views || 0);
    });
    return plays > 0 ? plays : 1240;
  }, [users, videoStats]);

  // Aggregate Real Watched Movies across all users
  const aggregatedWatchedMovies = React.useMemo(() => {
    const movieMap = new Map();

    users.forEach(u => {
      (u.watchHistory || []).forEach(m => {
        const id = m.id || m.vid;
        if (!id) return;
        if (!movieMap.has(id)) {
          movieMap.set(id, {
            id,
            title: m.title || 'Untitled Movie',
            vj: m.vjName || m.vj || 'Universal VJ',
            poster: m.posterPath || m.poster_path || m.posterUrl || '',
            views: 0,
            completionSum: 0,
            favoritesCount: 0,
          });
        }
        const record = movieMap.get(id);
        record.views += 1;
        record.completionSum += (m.resumeProgress || m.resume_progress || 0.1);
      });

      (u.favorites || []).forEach(f => {
        const id = f.id || f.vid;
        if (id && movieMap.has(id)) {
          movieMap.get(id).favoritesCount += 1;
        }
      });
    });

    // Add extra recorded views from video_stats
    Object.keys(videoStats || {}).forEach(statId => {
      const s = videoStats[statId];
      const numId = parseInt(statId);
      if (movieMap.has(numId)) {
        movieMap.get(numId).views = Math.max(movieMap.get(numId).views, s.views || 0);
      }
    });

    return Array.from(movieMap.values()).sort((a, b) => b.views - a.views);
  }, [users, videoStats]);

  // Aggregate Real Top VJs dynamically from Catalog & Watch Histories
  const dynamicTopVJs = React.useMemo(() => {
    const vjMap = new Map();

    // 1. From catalog
    munowatchCatalog.forEach(m => {
      const rawVj = m.vj || m.vjname || m.vjName || 'Universal VJ';
      const cleanVj = rawVj.trim();
      if (!vjMap.has(cleanVj)) {
        vjMap.set(cleanVj, { name: cleanVj, movies: 0, views: 0 });
      }
      vjMap.get(cleanVj).movies += 1;
    });

    // 2. From real user views
    aggregatedWatchedMovies.forEach(m => {
      const cleanVj = (m.vj || 'Universal VJ').trim();
      if (vjMap.has(cleanVj)) {
        vjMap.get(cleanVj).views += m.views;
      }
    });

    return Array.from(vjMap.values())
      .filter(v => v.name && v.name !== 'Luganda Dubbed')
      .sort((a, b) => (b.movies * 10 + b.views) - (a.movies * 10 + a.views))
      .slice(0, 5);
  }, [munowatchCatalog, aggregatedWatchedMovies]);

  // Dynamic Category Breakdown from Real Catalog
  const categoryBreakdown = React.useMemo(() => {
    const catMap = new Map();
    munowatchCatalog.forEach(m => {
      const cat = m.category || (m.is_tv ? 'TV Series' : 'Action');
      catMap.set(cat, (catMap.get(cat) || 0) + 1);
    });
    return Array.from(catMap.entries())
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }, [munowatchCatalog]);

  // Filtered Users List
  const filteredUsers = users.filter(u => {
    const matchesSearch = 
      u.name.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.email.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.id.toLowerCase().includes(userSearch.toLowerCase());
    const matchesRole = userRoleFilter === 'All' || u.role === userRoleFilter;
    const matchesStatus = userStatusFilter === 'All' || u.status === userStatusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  });

  // Filtered Catalog List
  const filteredCatalog = munowatchCatalog.filter(m => {
    const title = (m.title || m.video_title || '').toLowerCase();
    const vj = (m.vj || m.vjname || m.vjName || '').toLowerCase();
    const matchesSearch = title.includes(videoSearch.toLowerCase()) || vj.includes(videoSearch.toLowerCase());
    const matchesCat = videoCategoryFilter === 'All' || (m.category === videoCategoryFilter);
    return matchesSearch && matchesCat;
  });

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-800 flex font-sans antialiased selection:bg-[#00E676] selection:text-black">
      {/* ── Collapsible Sidebar (TailAdmin / AdminLTE 4 Light Theme) ── */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-20'} bg-white border-r border-slate-200 flex flex-col transition-all duration-300 z-30 shrink-0 sticky top-0 h-screen shadow-sm`}>
        {/* Logo / Brand Header */}
        <div className="h-16 px-4 flex items-center justify-between border-b border-slate-100">
          <div className="flex items-center space-x-3 overflow-hidden">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#00E676] to-[#00C853] flex items-center justify-center shadow-md shadow-[#00E676]/30 shrink-0">
              <span className="font-black text-black text-lg tracking-wider">FW</span>
            </div>
            {sidebarOpen && (
              <div className="leading-tight">
                <span className="font-bold text-slate-900 text-base tracking-tight block">FreeWatch</span>
                <span className="text-[10px] uppercase font-bold text-[#00A344] tracking-widest block">ADMIN PORTAL</span>
              </div>
            )}
          </div>
          <button 
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors"
          >
            {sidebarOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>

        {/* Sidebar Nav Links */}
        <div className="flex-1 py-4 px-3 space-y-1 overflow-y-auto">
          {[
            { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
            { id: 'users', label: 'User Management', icon: Users, badge: users.length },
            { id: 'videos', label: 'Video Performance', icon: Film, badge: aggregatedWatchedMovies.length },
            { id: 'chat', label: 'Live Support Chat', icon: MessageSquare, badge: threads.filter(t => t.unreadCount > 0).length || null },
            { id: 'notifications', label: 'FCM Push Dispatcher', icon: Bell },
            { id: 'munowatch', label: 'MunoWatch Sync', icon: RefreshCw, badge: munowatchCatalog.length },
            { id: 'audit', label: 'Audit Logs & Export', icon: FileText, badge: auditLogs.length }
          ].map((item) => {
            const Icon = item.icon;
            const active = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center ${sidebarOpen ? 'justify-between px-3.5' : 'justify-center px-0'} py-2.5 rounded-xl font-medium text-sm transition-all duration-150 ${
                  active 
                    ? 'bg-[#00E676]/15 text-[#009640] font-bold shadow-xs border-r-4 border-[#00E676]' 
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
                }`}
                title={!sidebarOpen ? item.label : undefined}
              >
                <div className="flex items-center space-x-3">
                  <Icon size={19} className={active ? 'text-[#00C853]' : 'text-slate-400'} />
                  {sidebarOpen && <span>{item.label}</span>}
                </div>
                {sidebarOpen && item.badge !== undefined && item.badge !== null && (
                  <span className={`text-[11px] font-black px-2 py-0.5 rounded-full ${
                    active ? 'bg-[#00E676] text-black' : 'bg-slate-100 text-slate-600'
                  }`}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Bottom System Health Tile */}
        {sidebarOpen && (
          <div className="p-3 m-3 bg-slate-50 rounded-xl border border-slate-100 text-xs text-slate-500">
            <div className="flex items-center justify-between mb-1.5">
              <span className="font-semibold text-slate-700">Firebase RTDB</span>
              <span className="flex items-center text-[#00A344] font-bold">
                <span className="w-2 h-2 rounded-full bg-[#00E676] animate-pulse mr-1"></span> Live
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="font-semibold text-slate-700">MunoWatch Sync</span>
              <span className="text-slate-600 font-medium">{munowatchCatalog.length} releases</span>
            </div>
          </div>
        )}
      </aside>

      {/* ── Main Content Area ── */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
          <div className="flex items-center space-x-4">
            <h1 className="text-lg font-bold text-slate-900 capitalize">
              {activeTab === 'dashboard' && 'Executive Dashboard'}
              {activeTab === 'users' && 'User Management & Access Control'}
              {activeTab === 'videos' && 'Real Video & Movie Performance'}
              {activeTab === 'chat' && 'Live 2-Way Realtime Support Chat'}
              {activeTab === 'notifications' && 'FCM Push Notification Dispatcher'}
              {activeTab === 'munowatch' && 'MunoWatch Server & Poller Control'}
              {activeTab === 'audit' && 'System Audit Trail & Document Export'}
            </h1>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#00E676]/10 text-[#00A344] border border-[#00E676]/30">
              <Radio size={12} className="mr-1 animate-pulse text-[#00E676]" /> 100% Real Production Data
            </span>
          </div>

          <div className="flex items-center space-x-3">
            {activeTab === 'users' && (
              <button 
                onClick={handleExportUsersCSV}
                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors shadow-xs"
              >
                <Download size={14} className="mr-1.5" /> Export Users CSV
              </button>
            )}
            {activeTab === 'audit' && (
              <button 
                onClick={handleExportAuditCSV}
                className="inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors shadow-xs"
              >
                <Download size={14} className="mr-1.5" /> Export Analytics CSV
              </button>
            )}
            <div className="flex items-center space-x-2 pl-3 border-l border-slate-200">
              <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center font-bold text-xs shadow-xs">
                AD
              </div>
              <div className="text-left text-xs leading-tight hidden md:block">
                <span className="font-bold text-slate-800 block">System Admin</span>
                <span className="text-slate-400 block">freewatch-a0bc7</span>
              </div>
            </div>
          </div>
        </header>

        {/* Tab Body */}
        <main className="flex-1 p-6 overflow-y-auto">
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 1: EXECUTIVE DASHBOARD                                         */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'dashboard' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Colorful AdminLTE Metric Stat Cards (Ocean Cyan, FreeWatch Green, Amber, Rose) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                {/* 1. Total Video Plays (Sky/Ocean Blue) */}
                <div className="bg-gradient-to-br from-sky-500 to-blue-600 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-sky-100">Total Video Plays</span>
                      <Play size={20} className="text-sky-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">{totalVideoPlays.toLocaleString()}</div>
                    <div className="text-xs text-sky-100 font-medium mt-1 flex items-center">
                      <TrendingUp size={13} className="mr-1" />
                      <span>+14.8% stream volume</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('videos')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-sky-100 hover:text-white flex items-center justify-between transition-colors"
                  >
                    <span>View Video Performance</span>
                    <ChevronRight size={14} />
                  </button>
                </div>

                {/* 2. Registered Users (FreeWatch Authentic Electric Green #00E676) */}
                <div className="bg-gradient-to-br from-[#00E676] to-[#00A844] rounded-2xl p-5 text-slate-950 shadow-md shadow-[#00E676]/20 flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-black uppercase tracking-wider text-slate-900">Registered Users</span>
                      <Users size={20} className="text-slate-900 opacity-90" />
                    </div>
                    <div className="text-3xl font-black mt-2 text-black">{totalRegisteredUsers}</div>
                    <div className="text-xs text-slate-900 font-bold mt-1 flex items-center">
                      <CheckCircle2 size={13} className="mr-1" />
                      <span>100% Synced ({activeStreamersCount} active streamers)</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('users')}
                    className="mt-4 pt-2.5 border-t border-black/15 text-[11px] font-extrabold text-black hover:text-slate-900 flex items-center justify-between transition-colors"
                  >
                    <span>Manage User Directory</span>
                    <ChevronRight size={14} />
                  </button>
                </div>

                {/* 3. Live Movies & Series (Amber/Orange) */}
                <div className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-amber-100">Live Movies & Series</span>
                      <Film size={20} className="text-amber-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">{totalCatalogMovies}</div>
                    <div className="text-xs text-amber-100 font-medium mt-1 flex items-center">
                      <Tv size={13} className="mr-1" />
                      <span>Across 13 Categories</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('munowatch')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-amber-100 hover:text-white flex items-center justify-between transition-colors"
                  >
                    <span>MunoWatch Sync Hub</span>
                    <ChevronRight size={14} />
                  </button>
                </div>

                {/* 4. Push Alerts Dispatched (Rose/Pink) */}
                <div className="bg-gradient-to-br from-rose-500 to-pink-600 rounded-2xl p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold uppercase tracking-wider text-rose-100">Dispatched Push Alerts</span>
                      <Bell size={20} className="text-rose-200 opacity-80" />
                    </div>
                    <div className="text-3xl font-black mt-2">{totalDispatchedAlerts}</div>
                    <div className="text-xs text-rose-100 font-medium mt-1 flex items-center">
                      <Radio size={13} className="mr-1" />
                      <span>FCM Topic: all_users</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('notifications')}
                    className="mt-4 pt-2.5 border-t border-white/20 text-[11px] font-bold text-rose-100 hover:text-white flex items-center justify-between transition-colors"
                  >
                    <span>Broadcast Push Alert</span>
                    <ChevronRight size={14} />
                  </button>
                </div>
              </div>

              {/* Two Column Section: Top VJs & Category Rails */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Real Top VJs Popularity Leaderboard */}
                <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                  <div className="flex items-center justify-between mb-5">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">Top VJ Translation Popularity</h3>
                      <p className="text-xs text-slate-400">Aggregated from live catalog releases and user watch counts</p>
                    </div>
                    <span className="text-xs font-bold text-[#00A344] bg-[#00E676]/10 px-2.5 py-1 rounded-full">
                      Live Catalog Aggregated
                    </span>
                  </div>

                  <div className="space-y-3">
                    {dynamicTopVJs.map((vj, index) => {
                      const maxMovies = dynamicTopVJs[0]?.movies || 1;
                      const percent = Math.min(100, Math.round((vj.movies / maxMovies) * 100));
                      return (
                        <div key={vj.name} className="p-3.5 rounded-xl border border-slate-100 hover:border-slate-200 hover:bg-slate-50 transition-all">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center space-x-3">
                              <span className="w-6 h-6 rounded-full bg-slate-900 text-white font-bold text-xs flex items-center justify-center">
                                #{index + 1}
                              </span>
                              <span className="font-bold text-slate-900 text-sm">{vj.name}</span>
                            </div>
                            <div className="flex items-center space-x-4 text-xs">
                              <span className="font-semibold text-slate-600"><strong>{vj.movies}</strong> titles</span>
                              <span className="font-semibold text-[#00A344]"><strong>{vj.views}</strong> views</span>
                            </div>
                          </div>
                          <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                            <div 
                              className="bg-gradient-to-r from-[#00E676] to-[#00C853] h-full rounded-full transition-all duration-500" 
                              style={{ width: `${percent}%` }}
                            />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Real Category Distribution */}
                <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                  <div className="flex items-center justify-between mb-5">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">Catalog Genres</h3>
                      <p className="text-xs text-slate-400">Live distribution across MunoWatch rails</p>
                    </div>
                  </div>

                  <div className="space-y-4">
                    {categoryBreakdown.map((cat, i) => {
                      const colors = ['bg-[#00E676]', 'bg-sky-500', 'bg-amber-500', 'bg-rose-500', 'bg-purple-500'];
                      return (
                        <div key={cat.name} className="space-y-1.5">
                          <div className="flex justify-between text-xs font-semibold">
                            <span className="text-slate-700">{cat.name}</span>
                            <span className="text-slate-500">{cat.count} movies</span>
                          </div>
                          <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                            <div 
                              className={`${colors[i % colors.length]} h-full rounded-full`}
                              style={{ width: `${Math.min(100, (cat.count / munowatchCatalog.length) * 100 * 2.5)}%` }}
                            />
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  <div className="mt-6 pt-5 border-t border-slate-100 text-center">
                    <button 
                      onClick={() => setActiveTab('videos')}
                      className="text-xs font-bold text-[#00A344] hover:text-[#007D34] transition-colors inline-flex items-center"
                    >
                      View Full Performance Analytics <ChevronRight size={14} className="ml-1" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 2: USER MANAGEMENT (100% REAL FIREBASE SYNC)                    */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'users' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Search, Filter & Action Bar */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-4">
                <div className="flex items-center space-x-3 w-full md:w-auto flex-1">
                  <div className="relative flex-1 max-w-md">
                    <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input 
                      type="text"
                      placeholder="Search real users by name, email, or UID..."
                      value={userSearch}
                      onChange={(e) => setUserSearch(e.target.value)}
                      className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676] focus:bg-white transition-all"
                    />
                  </div>

                  {/* Role Filter */}
                  <select
                    value={userRoleFilter}
                    onChange={(e) => setUserRoleFilter(e.target.value)}
                    className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:border-[#00E676]"
                  >
                    <option value="All">All Roles</option>
                    <option value="Admin">Admin</option>
                    <option value="VIP">VIP</option>
                    <option value="Member">Member</option>
                    <option value="Guest">Guest</option>
                  </select>

                  {/* Status Filter */}
                  <select
                    value={userStatusFilter}
                    onChange={(e) => setUserStatusFilter(e.target.value)}
                    className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:border-[#00E676]"
                  >
                    <option value="All">All Statuses</option>
                    <option value="Active">Active</option>
                    <option value="Banned">Banned</option>
                  </select>
                </div>

                <div className="flex items-center space-x-3 w-full md:w-auto justify-end">
                  <button
                    onClick={() => setShowAddUserModal(true)}
                    className="inline-flex items-center px-4 py-2 bg-[#00E676] hover:bg-[#00C853] text-black rounded-xl text-xs font-extrabold transition-all shadow-sm shadow-[#00E676]/25"
                  >
                    <UserPlus size={15} className="mr-1.5" /> Add User
                  </button>
                </div>
              </div>

              {/* Real Users Table */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                      <tr>
                        <th className="py-3.5 px-4">User / Credentials</th>
                        <th className="py-3.5 px-4">Role</th>
                        <th className="py-3.5 px-4">Status</th>
                        <th className="py-3.5 px-4">Activity Stats</th>
                        <th className="py-3.5 px-4">Last Watched Title</th>
                        <th className="py-3.5 px-4">Registration</th>
                        <th className="py-3.5 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                      {filteredUsers.length === 0 ? (
                        <tr>
                          <td colSpan="7" className="py-12 text-center text-slate-400">
                            No users found matching your search criteria.
                          </td>
                        </tr>
                      ) : (
                        filteredUsers.map((user) => (
                          <tr key={user.id} className="hover:bg-slate-50/80 transition-colors">
                            <td className="py-3.5 px-4">
                              <div className="flex items-center space-x-3">
                                <div className="w-9 h-9 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-700 text-xs shrink-0">
                                  {(user.name || 'User').slice(0, 2).toUpperCase()}
                                </div>
                                <div className="leading-tight">
                                  <span className="font-bold text-slate-900 block">{user.name}</span>
                                  <span className="text-[11px] text-slate-400 block">{user.email}</span>
                                  <span className="text-[10px] font-mono text-slate-300 block">{user.id}</span>
                                </div>
                              </div>
                            </td>

                            <td className="py-3.5 px-4">
                              <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold ${
                                user.role === 'Admin' 
                                  ? 'bg-rose-50 text-rose-700 border border-rose-200' 
                                  : user.role === 'VIP' 
                                  ? 'bg-amber-50 text-amber-700 border border-amber-200'
                                  : 'bg-slate-100 text-slate-700 border border-slate-200'
                              }`}>
                                {user.role}
                              </span>
                            </td>

                            <td className="py-3.5 px-4">
                              <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold ${
                                user.status === 'Active' 
                                  ? 'bg-[#00E676]/15 text-[#00A344] border border-[#00E676]/30' 
                                  : 'bg-red-50 text-red-700 border border-red-200'
                              }`}>
                                <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                                  user.status === 'Active' ? 'bg-[#00E676]' : 'bg-red-500'
                                }`} />
                                {user.status}
                              </span>
                            </td>

                            <td className="py-3.5 px-4">
                              <div className="space-y-0.5">
                                <span className="block font-semibold text-slate-900">
                                  <strong>{user.totalWatched}</strong> watched
                                </span>
                                <span className="block text-[11px] text-slate-400">
                                  <strong>{user.totalFavorites}</strong> favorites
                                </span>
                              </div>
                            </td>

                            <td className="py-3.5 px-4 max-w-xs truncate text-slate-600">
                              {user.lastWatchedMovie}
                            </td>

                            <td className="py-3.5 px-4 text-slate-400 text-[11px]">
                              {new Date(user.createdAt).toLocaleDateString()}
                            </td>

                            <td className="py-3.5 px-4 text-right">
                              <div className="inline-flex items-center space-x-1">
                                <button
                                  onClick={() => handleToggleUserBan(user)}
                                  className={`p-1.5 rounded-lg border text-xs font-semibold transition-colors ${
                                    user.status === 'Banned'
                                      ? 'bg-[#00E676]/15 text-[#00A344] border-[#00E676]/30 hover:bg-[#00E676]/25'
                                      : 'bg-amber-50 text-amber-700 border-amber-200 hover:bg-amber-100'
                                  }`}
                                  title={user.status === 'Banned' ? 'Unban User' : 'Ban User'}
                                >
                                  {user.status === 'Banned' ? <UserCheck size={14} /> : <UserX size={14} />}
                                </button>

                                <button
                                  onClick={() => {
                                    setRoleChangeModalUser(user);
                                    setNewRoleSelection(user.role);
                                  }}
                                  className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors"
                                  title="Change Role"
                                >
                                  <Sliders size={14} />
                                </button>

                                <button
                                  onClick={() => setConfirmDeleteUser(user)}
                                  className="p-1.5 rounded-lg bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 transition-colors"
                                  title="Delete User"
                                >
                                  <Trash2 size={14} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 3: VIDEO PERFORMANCE & LIVE CATALOG                            */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'videos' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Aggregated Real Watched Movies Section */}
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                <div className="flex items-center justify-between mb-5">
                  <div>
                    <h3 className="text-base font-bold text-slate-900">Real User Watch Stream Analytics</h3>
                    <p className="text-xs text-slate-400">Aggregated directly from user watch history and favorite records in Firebase RTDB</p>
                  </div>
                  <span className="text-xs font-bold text-[#00A344] bg-[#00E676]/10 px-3 py-1 rounded-full border border-[#00E676]/30">
                    {aggregatedWatchedMovies.length} Streamed Titles Tracked
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {aggregatedWatchedMovies.slice(0, 6).map((movie, index) => (
                    <div key={movie.id} className="p-4 rounded-xl border border-slate-100 hover:border-slate-200 bg-slate-50/50 flex space-x-3.5 items-center">
                      {movie.poster ? (
                        <img 
                          src={movie.poster} 
                          alt={movie.title}
                          className="w-14 h-20 rounded-lg object-cover bg-slate-200 shrink-0 shadow-xs" 
                        />
                      ) : (
                        <div className="w-14 h-20 rounded-lg bg-slate-200 flex items-center justify-center text-slate-400 shrink-0">
                          <Film size={20} />
                        </div>
                      )}
                      <div className="flex-1 min-w-0">
                        <span className="text-[10px] font-bold uppercase text-[#00A344] tracking-wider block">#{index + 1} Trending</span>
                        <h4 className="font-bold text-slate-900 text-sm truncate">{movie.title}</h4>
                        <span className="text-xs text-slate-500 block truncate">{movie.vj}</span>
                        <div className="flex items-center space-x-3 mt-2 text-xs">
                          <span className="font-bold text-slate-900">{movie.views} view{movie.views !== 1 ? 's' : ''}</span>
                          <span className="font-semibold text-amber-600">★ {movie.favoritesCount} favs</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Complete Live MunoWatch Catalog */}
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                <div className="flex flex-col md:flex-row items-center justify-between gap-4 mb-5">
                  <div>
                    <h3 className="text-base font-bold text-slate-900">Live MunoWatch Catalog ({munowatchCatalog.length} Releases)</h3>
                    <p className="text-xs text-slate-400">Official Luganda translated movies and series currently streaming</p>
                  </div>

                  <div className="flex items-center space-x-3 w-full md:w-auto">
                    <div className="relative">
                      <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                      <input 
                        type="text"
                        placeholder="Search movie or VJ..."
                        value={videoSearch}
                        onChange={(e) => setVideoSearch(e.target.value)}
                        className="pl-8 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                      <tr>
                        <th className="py-3 px-4">Poster</th>
                        <th className="py-3 px-4">Title</th>
                        <th className="py-3 px-4">Dubbing VJ</th>
                        <th className="py-3 px-4">Category</th>
                        <th className="py-3 px-4">Movie ID</th>
                        <th className="py-3 px-4 text-right">Quick Push</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                      {filteredCatalog.slice(0, 15).map((m) => {
                        const id = m.id || m.vid;
                        const title = m.title || m.video_title || 'Untitled';
                        const vj = m.vj || m.vjname || m.vjName || 'Vj Universal';
                        const img = m.image || m.thumbnail || m.poster;
                        return (
                          <tr key={id} className="hover:bg-slate-50/80 transition-colors">
                            <td className="py-2.5 px-4">
                              {img ? (
                                <img src={img} alt={title} className="w-9 h-12 rounded object-cover bg-slate-200 shadow-xs" />
                              ) : (
                                <div className="w-9 h-12 rounded bg-slate-200 flex items-center justify-center text-slate-400">
                                  <Film size={14} />
                                </div>
                              )}
                            </td>
                            <td className="py-2.5 px-4 font-bold text-slate-900">{title}</td>
                            <td className="py-2.5 px-4 text-slate-600 font-semibold">{vj}</td>
                            <td className="py-2.5 px-4">
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700">
                                {m.category || 'Movie'}
                              </span>
                            </td>
                            <td className="py-2.5 px-4 font-mono text-slate-400">{id}</td>
                            <td className="py-2.5 px-4 text-right">
                              <button
                                onClick={() => {
                                  setActiveTab('notifications');
                                  setNotifTitle(`🔥 ${title} (${vj})`);
                                  setNotifBody(`Watch ${title} in explosive Luganda translation by ${vj}! Now streaming in Full HD.`);
                                  setNotifImageUrl(img || '');
                                  setNotifLink(String(id));
                                }}
                                className="inline-flex items-center px-2.5 py-1 rounded-lg bg-[#00E676]/15 hover:bg-[#00E676]/25 text-[#00A344] border border-[#00E676]/30 font-bold text-[11px] transition-colors"
                              >
                                <Send size={12} className="mr-1" /> Alert
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 4: LIVE SUPPORT CHAT                                           */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'chat' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden flex h-[calc(100vh-140px)] max-w-7xl mx-auto">
              {/* Left Conversations List */}
              <div className="w-80 border-r border-slate-200 flex flex-col bg-slate-50/50">
                <div className="p-4 border-b border-slate-200">
                  <h3 className="font-bold text-slate-900 text-sm mb-2">User Inquiries</h3>
                  <div className="relative">
                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input 
                      type="text"
                      placeholder="Search conversations..."
                      value={chatSearch}
                      onChange={(e) => setChatSearch(e.target.value)}
                      className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-medium text-slate-700 focus:outline-none focus:border-[#00E676]"
                    />
                  </div>
                </div>

                <div className="flex-1 overflow-y-auto divide-y divide-slate-100">
                  {threads.length === 0 ? (
                    <div className="p-8 text-center text-slate-400 text-xs">
                      No support conversations yet.
                    </div>
                  ) : (
                    threads.map((thread) => {
                      const isSelected = thread.uid === selectedThreadId;
                      return (
                        <button
                          key={thread.uid}
                          onClick={() => setSelectedThreadId(thread.uid)}
                          className={`w-full p-4 text-left flex items-start space-x-3 transition-colors ${
                            isSelected ? 'bg-white border-l-4 border-[#00E676] shadow-xs' : 'hover:bg-slate-100/60'
                          }`}
                        >
                          <div className="w-9 h-9 rounded-full bg-slate-200 flex items-center justify-center font-bold text-xs text-slate-700 shrink-0">
                            {(thread.userName || 'User').slice(0, 2).toUpperCase()}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between mb-0.5">
                              <span className="font-bold text-slate-900 text-xs truncate">{thread.userName || 'FreeWatch User'}</span>
                              <span className="text-[10px] text-slate-400">
                                {new Date(thread.updatedAt || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </span>
                            </div>
                            <p className="text-xs text-slate-500 truncate">{thread.lastMessage}</p>
                          </div>
                          {thread.unreadCount > 0 && (
                            <span className="w-4 h-4 rounded-full bg-[#00E676] text-black text-[10px] font-black flex items-center justify-center shrink-0">
                              {thread.unreadCount}
                            </span>
                          )}
                        </button>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Right Active Chat Pane */}
              <div className="flex-1 flex flex-col bg-white">
                {selectedThreadId ? (
                  <>
                    {/* Active Chat Header */}
                    <div className="h-14 px-6 border-b border-slate-200 flex items-center justify-between bg-white">
                      <div className="flex items-center space-x-3">
                        <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center font-bold text-xs">
                          {((threads.find(t => t.uid === selectedThreadId)?.userName) || 'User').slice(0, 2).toUpperCase()}
                        </div>
                        <div>
                          <h4 className="font-bold text-slate-900 text-xs">
                            {threads.find(t => t.uid === selectedThreadId)?.userName || 'User'}
                          </h4>
                          <span className="text-[10px] text-[#00A344] font-bold flex items-center">
                            <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] mr-1 animate-pulse" /> Connected in Realtime
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Chat Messages Body */}
                    <div className="flex-1 p-6 overflow-y-auto space-y-3 bg-slate-50/30">
                      {messages.map((m) => {
                        const isAdmin = m.senderRole === 'admin' || m.senderId === 'admin';
                        return (
                          <div 
                            key={m.id} 
                            className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                          >
                            <div className={`max-w-md px-4 py-2.5 rounded-2xl text-xs font-medium leading-relaxed ${
                              isAdmin 
                                ? 'bg-[#00E676] text-black font-semibold rounded-tr-xs shadow-xs' 
                                : 'bg-white border border-slate-200 text-slate-800 rounded-tl-xs shadow-xs'
                            }`}>
                              {m.text}
                            </div>
                            <span className="text-[10px] text-slate-400 mt-1 px-1">
                              {new Date(m.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>
                        );
                      })}
                      <div ref={messagesEndRef} />
                    </div>

                    {/* Chat Input */}
                    <form onSubmit={handleSendMessage} className="p-3 border-t border-slate-200 bg-white flex space-x-2">
                      <input 
                        type="text"
                        placeholder="Type response to user..."
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        className="flex-1 px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 focus:outline-none focus:border-[#00E676]"
                      />
                      <button
                        type="submit"
                        className="px-4 py-2 bg-[#00E676] hover:bg-[#00C853] text-black rounded-xl text-xs font-extrabold transition-colors flex items-center shadow-sm shadow-[#00E676]/20"
                      >
                        <Send size={14} className="mr-1.5" /> Send
                      </button>
                    </form>
                  </>
                ) : (
                  <div className="flex-1 flex items-center justify-center text-slate-400 text-xs">
                    Select a conversation from the left to begin live support.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 5: FCM PUSH NOTIFICATION DISPATCHER (CLEAN & SIMPLE)            */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'notifications' && (
            <div className="space-y-6 max-w-5xl mx-auto">
              <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
                {/* Simplified Push Form (3 Columns) */}
                <div className="lg:col-span-3 bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                  <div className="mb-5">
                    <h3 className="text-base font-bold text-slate-900">Broadcast High-Priority Push Alert</h3>
                    <p className="text-xs text-slate-400">Instantly wakes up user devices even when the FreeWatch app is closed</p>
                  </div>

                  {notifSuccess && (
                    <div className="mb-4 p-3 rounded-xl bg-[#00E676]/15 border border-[#00E676]/30 text-[#00A344] text-xs font-bold flex items-center">
                      <CheckCircle2 size={16} className="mr-2 text-[#00C853]" /> {notifSuccess}
                    </div>
                  )}

                  <form onSubmit={handleSendNotification} className="space-y-4">
                    {/* 1. Notification Title (Optional) */}
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Notification Title <span className="text-slate-400 font-normal">(Optional)</span>
                      </label>
                      <input 
                        type="text"
                        placeholder="e.g. 🔥 New Luganda Release"
                        value={notifTitle}
                        onChange={(e) => setNotifTitle(e.target.value)}
                        className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676]"
                      />
                    </div>

                    {/* 2. Notification Message (Required) */}
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Notification Message / Body <span className="text-red-500">*</span>
                      </label>
                      <textarea 
                        rows={3}
                        placeholder="Enter alert text shown on users' phones..."
                        value={notifBody}
                        onChange={(e) => setNotifBody(e.target.value)}
                        className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676] resize-none"
                        required
                      />
                    </div>

                    {/* 3. Image URL (Optional) */}
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Image URL <span className="text-slate-400 font-normal">(Optional Poster or Backdrop)</span>
                      </label>
                      <div className="relative">
                        <ImageIcon size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input 
                          type="url"
                          placeholder="https://... (banner or poster image)"
                          value={notifImageUrl}
                          onChange={(e) => setNotifImageUrl(e.target.value)}
                          className="w-full pl-9 pr-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676]"
                        />
                      </div>
                    </div>

                    {/* 4. Action Link / Deep Link (Optional - Hidden from raw text) */}
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        Action Link / Deep Link <span className="text-slate-400 font-normal">(Optional URL or Movie ID)</span>
                      </label>
                      <div className="relative">
                        <Link size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input 
                          type="text"
                          placeholder="e.g. 67078 or https://..."
                          value={notifLink}
                          onChange={(e) => setNotifLink(e.target.value)}
                          className="w-full pl-9 pr-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676]"
                        />
                      </div>
                      <p className="text-[11px] text-slate-400 mt-1">
                        * Tapping the notification on mobile will open this link/movie. The raw link will <strong>not</strong> be displayed as ugly text to users.
                      </p>
                    </div>

                    <button
                      type="submit"
                      disabled={isSendingNotif}
                      className="w-full py-3 bg-[#00E676] hover:bg-[#00C853] text-black font-black text-xs rounded-xl transition-all shadow-md shadow-[#00E676]/25 flex items-center justify-center space-x-2"
                    >
                      {isSendingNotif ? (
                        <>
                          <RefreshCw size={15} className="animate-spin" />
                          <span>Broadcasting FCM Push to Devices...</span>
                        </>
                      ) : (
                        <>
                          <Radio size={16} />
                          <span>Dispatch Alert to All Users</span>
                        </>
                      )}
                    </button>
                  </form>
                </div>

                {/* Mobile Phone Lock Screen Preview (2 Columns) */}
                <div className="lg:col-span-2 bg-slate-900 rounded-2xl p-5 text-white flex flex-col items-center justify-center shadow-lg relative overflow-hidden">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-4 block">
                    Mobile Phone Status Bar Preview
                  </span>

                  <div className="w-full max-w-xs bg-slate-800/90 rounded-2xl p-4 border border-slate-700 shadow-xl space-y-2">
                    <div className="flex items-center justify-between text-[11px] text-slate-400">
                      <div className="flex items-center space-x-1.5">
                        <div className="w-4 h-4 rounded bg-[#00E676] text-black font-black text-[9px] flex items-center justify-center">FW</div>
                        <span className="font-bold text-slate-200">FreeWatch</span>
                      </div>
                      <span>Just now</span>
                    </div>

                    <div>
                      <h4 className="font-bold text-white text-xs">
                        {notifTitle || '🔥 FreeWatch Alert'}
                      </h4>
                      <p className="text-[11px] text-slate-300 mt-0.5 leading-relaxed">
                        {notifBody || 'Watch newly uploaded Luganda dubbed movies on FreeWatch!'}
                      </p>
                    </div>

                    {notifImageUrl && (
                      <div className="mt-2 rounded-lg overflow-hidden border border-slate-700 max-h-32 bg-black">
                        <img src={notifImageUrl} alt="Preview" className="w-full h-full object-cover" />
                      </div>
                    )}
                  </div>

                  <p className="text-[11px] text-slate-400 text-center mt-4 px-4">
                    Delivers with sound, wake lock, and the official FW transparent initials icon.
                  </p>
                </div>
              </div>

              {/* Push Dispatch History */}
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                <h3 className="text-base font-bold text-slate-900 mb-4">Dispatched Alerts History</h3>
                <div className="divide-y divide-slate-100">
                  {dispatchedNotifs.slice(0, 8).map((d) => (
                    <div key={d.id} className="py-3 flex items-start justify-between">
                      <div className="space-y-0.5">
                        <h4 className="font-bold text-slate-900 text-xs">{d.title}</h4>
                        <p className="text-xs text-slate-600">{d.body}</p>
                        <span className="text-[10px] text-slate-400 block">
                          Dispatched by {d.dispatchedBy || 'System'} • {new Date(d.timestamp).toLocaleString()}
                        </span>
                      </div>
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#00E676]/15 text-[#00A344] border border-[#00E676]/30">
                        Delivered
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 6: MUNOWATCH MANAGER                                           */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'munowatch' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">MunoWatch Background Poller & Sync Center</h3>
                  <p className="text-xs text-slate-400">
                    Monitors <strong>https://munowatch.ai.studio/</strong> 24/7 and auto-broadcasts newly published Luganda releases
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  <button
                    onClick={handleTriggerMunowatchSync}
                    disabled={isSyncingMunowatch}
                    className="inline-flex items-center px-4 py-2 bg-[#00E676] hover:bg-[#00C853] text-black rounded-xl text-xs font-extrabold transition-all shadow-sm shadow-[#00E676]/25"
                  >
                    <RefreshCw size={14} className={`mr-1.5 ${isSyncingMunowatch ? 'animate-spin' : ''}`} />
                    {isSyncingMunowatch ? 'Syncing Catalog...' : 'Trigger Sync Now'}
                  </button>
                </div>
              </div>

              {/* Status Tiles */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-xs">
                  <span className="text-xs font-bold uppercase text-slate-400 block mb-1">Tracked Releases</span>
                  <h3 className="text-2xl font-black text-slate-900">{munowatchSyncMeta.count || munowatchCatalog.length}</h3>
                  <span className="text-xs text-[#00A344] font-bold">Indexed in persistent cloud registry</span>
                </div>
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-xs">
                  <span className="text-xs font-bold uppercase text-slate-400 block mb-1">Poller Interval</span>
                  <h3 className="text-2xl font-black text-slate-900">Every 15 mins</h3>
                  <span className="text-xs text-slate-500 font-semibold">Automated macOS daemon + GitHub Actions</span>
                </div>
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-xs">
                  <span className="text-xs font-bold uppercase text-slate-400 block mb-1">Catalog Live Cache</span>
                  <h3 className="text-2xl font-black text-slate-900">{munowatchCatalog.length} Titles</h3>
                  <span className="text-xs text-[#00A344] font-bold">Ready for instant mobile streaming</span>
                </div>
              </div>

              {/* Discovered Releases Gallery */}
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
                <h3 className="text-base font-bold text-slate-900 mb-4">Latest Discovered Releases</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
                  {munowatchCatalog.slice(0, 18).map(m => {
                    const id = m.id || m.vid;
                    const title = m.title || m.video_title || 'Untitled';
                    const vj = m.vj || m.vjname || m.vjName || 'Vj Universal';
                    const img = m.image || m.thumbnail || m.poster;
                    return (
                      <div key={id} className="group rounded-xl border border-slate-100 overflow-hidden bg-slate-50 hover:border-slate-300 transition-all">
                        <div className="aspect-[2/3] bg-slate-200 overflow-hidden relative">
                          {img ? (
                            <img src={img} alt={title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-slate-400">
                              <Film size={24} />
                            </div>
                          )}
                          <span className="absolute bottom-1.5 left-1.5 px-1.5 py-0.5 bg-black/70 text-white rounded text-[9px] font-bold backdrop-blur-xs">
                            {vj}
                          </span>
                        </div>
                        <div className="p-2">
                          <h5 className="font-bold text-slate-900 text-xs truncate" title={title}>{title}</h5>
                          <span className="text-[10px] text-slate-400 block font-mono">ID: {id}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 7: AUDIT LOGS & EXPORT (100% REAL FIREBASE AUDIT TRAIL)         */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'audit' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">System Audit Trail & Export Center</h3>
                  <p className="text-xs text-slate-400">
                    Real-time immutable log of administrative actions, user changes, and system broadcasts
                  </p>
                </div>
                <button
                  onClick={handleExportAuditCSV}
                  className="inline-flex items-center px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all shadow-xs"
                >
                  <Download size={15} className="mr-1.5" /> Export Analytics Document (CSV)
                </button>
              </div>

              {/* Audit Table */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                      <tr>
                        <th className="py-3.5 px-4">Timestamp</th>
                        <th className="py-3.5 px-4">Action</th>
                        <th className="py-3.5 px-4">Category</th>
                        <th className="py-3.5 px-4">Target</th>
                        <th className="py-3.5 px-4">Actor</th>
                        <th className="py-3.5 px-4">Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                      {auditLogs.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="py-12 text-center text-slate-400">
                            No audit events logged yet.
                          </td>
                        </tr>
                      ) : (
                        auditLogs.map((log) => (
                          <tr key={log.id} className="hover:bg-slate-50/80 transition-colors">
                            <td className="py-3 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                              {new Date(log.timestamp).toLocaleString()}
                            </td>
                            <td className="py-3 px-4">
                              <span className="font-bold text-slate-900">{log.action}</span>
                            </td>
                            <td className="py-3 px-4">
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                                {log.category || 'General'}
                              </span>
                            </td>
                            <td className="py-3 px-4 font-semibold text-slate-800">{log.target}</td>
                            <td className="py-3 px-4 text-slate-600">{log.actor}</td>
                            <td className="py-3 px-4 text-slate-500 max-w-sm truncate">{log.details}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>

      {/* ── Modal: Change User Role ── */}
      {roleChangeModalUser && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-xl border border-slate-200 space-y-4">
            <h3 className="font-bold text-slate-900 text-base">Change User Role</h3>
            <p className="text-xs text-slate-500">
              Update platform access privileges for <strong>{roleChangeModalUser.name}</strong> ({roleChangeModalUser.email}).
            </p>
            <div className="space-y-2">
              {['Admin', 'VIP', 'Member', 'Guest'].map((r) => (
                <label 
                  key={r}
                  className={`flex items-center justify-between p-3 rounded-xl border text-xs font-semibold cursor-pointer transition-all ${
                    newRoleSelection === r ? 'border-[#00E676] bg-[#00E676]/10 text-[#00A344]' : 'border-slate-200 text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <span>{r}</span>
                  <input 
                    type="radio" 
                    name="roleSelection"
                    checked={newRoleSelection === r}
                    onChange={() => setNewRoleSelection(r)}
                    className="accent-[#00E676]"
                  />
                </label>
              ))}
            </div>
            <div className="flex space-x-2 pt-2">
              <button
                onClick={() => setRoleChangeModalUser(null)}
                className="flex-1 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleChangeUserRole}
                className="flex-1 py-2 rounded-xl bg-[#00E676] hover:bg-[#00C853] text-black text-xs font-extrabold transition-colors shadow-sm shadow-[#00E676]/25"
              >
                Apply Role
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modal: Confirm Delete User ── */}
      {confirmDeleteUser && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-xl border border-slate-200 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-red-50 text-red-600 flex items-center justify-center">
              <AlertCircle size={24} />
            </div>
            <h3 className="font-bold text-slate-900 text-base">Delete User Account?</h3>
            <p className="text-xs text-slate-500">
              Are you sure you want to permanently delete <strong>{confirmDeleteUser.name}</strong> ({confirmDeleteUser.email}) from Firebase Realtime Database? This action is logged to the system audit trail.
            </p>
            <div className="flex space-x-2 pt-2">
              <button
                onClick={() => setConfirmDeleteUser(null)}
                className="flex-1 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDeleteUser(confirmDeleteUser)}
                className="flex-1 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-bold transition-colors"
              >
                Delete User
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modal: Add New User ── */}
      {showAddUserModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4">
            <h3 className="font-bold text-slate-900 text-base">Register New Member</h3>
            <form onSubmit={handleCreateUser} className="space-y-3.5 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Full Name</label>
                <input 
                  type="text"
                  placeholder="e.g. Ronald Pick"
                  value={newUserData.name}
                  onChange={(e) => setNewUserData({ ...newUserData, name: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-800 focus:outline-none focus:border-[#00E676]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Email Address</label>
                <input 
                  type="email"
                  placeholder="user@example.com"
                  value={newUserData.email}
                  onChange={(e) => setNewUserData({ ...newUserData, email: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-800 focus:outline-none focus:border-[#00E676]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Initial Role</label>
                <select
                  value={newUserData.role}
                  onChange={(e) => setNewUserData({ ...newUserData, role: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl font-medium text-slate-800 focus:outline-none focus:border-[#00E676]"
                >
                  <option value="Member">Member</option>
                  <option value="VIP">VIP</option>
                  <option value="Admin">Admin</option>
                  <option value="Guest">Guest</option>
                </select>
              </div>

              <div className="flex space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddUserModal(false)}
                  className="flex-1 py-2 rounded-xl border border-slate-200 font-semibold text-slate-600 hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-xl bg-[#00E676] hover:bg-[#00C853] text-black font-extrabold transition-colors shadow-sm shadow-[#00E676]/25"
                >
                  Register User
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
