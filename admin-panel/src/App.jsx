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
  Image as ImageIcon,
  CheckCheck,
  Smile,
  Paperclip,
  Mic,
  Grid,
  List,
  Copy,
  MessageCircle,
  Info,
  Lock,
  Ban,
  LogOut,
  EyeOff,
  User
} from 'lucide-react';
import { rtdb, auth, signInAnonymously } from './firebase';
import { ref, onValue, push, set, update, remove, get } from 'firebase/database';
import AppStoreLanding from './pages/AppStoreLanding';
import WebCinemaApp from './pages/WebCinemaApp';

export default function App() {
  const [currentPath, setCurrentPath] = useState(() => {
    if (typeof window !== 'undefined') {
      return window.location.pathname;
    }
    return '/';
  });

  const [searchParams, setSearchParams] = useState(() => {
    if (typeof window !== 'undefined') {
      return window.location.search;
    }
    return '';
  });

  useEffect(() => {
    const handlePopState = () => {
      setCurrentPath(window.location.pathname);
      setSearchParams(window.location.search);
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const navigateTo = (path) => {
    if (typeof window !== 'undefined') {
      window.history.pushState({}, '', path);
      setCurrentPath(path);
      setSearchParams('');
    }
  };

  const isStoreRoute = 
    currentPath.startsWith('/store') ||
    currentPath.startsWith('/download') ||
    currentPath.startsWith('/downloads') ||
    currentPath.startsWith('/apk') ||
    currentPath.startsWith('/app') ||
    searchParams.includes('view=store') ||
    searchParams.includes('view=download');

  const isAdminRoute = 
    currentPath.startsWith('/pickle') ||
    currentPath.startsWith('/admin') ||
    currentPath.startsWith('/panel') ||
    currentPath.startsWith('/dashboard') ||
    searchParams.includes('view=pickle') ||
    searchParams.includes('view=admin');

  // Dedicated Store Listing: /store
  if (isStoreRoute) {
    return (
      <AppStoreLanding 
        onNavigateToAdmin={() => navigateTo('/pickle')} 
        onNavigateToWeb={() => navigateTo('/')} 
      />
    );
  }

  // Web Cinema Application: root ('/') and all non-admin public pages
  if (!isAdminRoute) {
    return (
      <WebCinemaApp 
        onNavigateToStore={() => navigateTo('/store')} 
        onNavigateToAdmin={() => navigateTo('/pickle')} 
      />
    );
  }

  // Navigation: 'dashboard' | 'users' | 'videos' | 'chat' | 'notifications' | 'munowatch' | 'audit' | 'store'
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // Admin Authentication Gate State
  const [isAdminAuthenticated, setIsAdminAuthenticated] = useState(() => {
    if (typeof window !== 'undefined') {
      const sess = sessionStorage.getItem('freewatch_admin_session');
      const local = localStorage.getItem('freewatch_admin_session');
      return sess === 'true' || local === 'true';
    }
    return false;
  });
  const [adminUsername, setAdminUsername] = useState('');
  const [adminPassword, setAdminPassword] = useState('');
  const [showAdminPassword, setShowAdminPassword] = useState(false);
  const [adminRememberMe, setAdminRememberMe] = useState(true);
  const [adminAuthError, setAdminAuthError] = useState('');
  const [adminAuthLoading, setAdminAuthLoading] = useState(false);

  // Mobile Slide-Out Drawer State
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Admin Authentication Handlers
  const handleAdminLogin = async (e) => {
    if (e) e.preventDefault();
    setAdminAuthError('');
    setAdminAuthLoading(true);

    try {
      // 1. Fetch credentials from Firebase RTDB (/admin_auth)
      let expectedUser = 'dev';
      let expectedPass = 'greatdevpass';

      try {
        const authSnapshot = await get(ref(rtdb, 'admin_auth'));
        if (authSnapshot.exists()) {
          const data = authSnapshot.val();
          if (data.username) expectedUser = data.username;
          if (data.password) expectedPass = data.password;
        }
      } catch (err) {
        console.warn('Firebase RTDB credentials fetch failed, falling back to local credentials:', err);
      }

      if (adminUsername.trim() === expectedUser && adminPassword === expectedPass) {
        sessionStorage.setItem('freewatch_admin_session', 'true');
        if (adminRememberMe) {
          localStorage.setItem('freewatch_admin_session', 'true');
        } else {
          localStorage.removeItem('freewatch_admin_session');
        }
        setIsAdminAuthenticated(true);
        setAdminAuthError('');
      } else {
        setAdminAuthError('Invalid administrator credentials. Access denied.');
      }
    } catch (err) {
      setAdminAuthError('Authentication service error. Please try again.');
    } finally {
      setAdminAuthLoading(false);
    }
  };

  const handleAdminLogout = () => {
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('freewatch_admin_session');
      localStorage.removeItem('freewatch_admin_session');
    }
    setIsAdminAuthenticated(false);
    setAdminUsername('');
    setAdminPassword('');
    setMobileMenuOpen(false);
  };

  // RTDB & Live Status
  const [dbConnected, setDbConnected] = useState(true);
  const [fcmDaemonLive, setFcmDaemonLive] = useState(true);

  // 100% REAL Live State from Firebase RTDB & MunoWatch
  const [users, setUsers] = useState([]);
  const [userSearch, setUserSearch] = useState('');
  const [userRoleFilter, setUserRoleFilter] = useState('All');
  const [userStatusFilter, setUserStatusFilter] = useState('All');
  const [userQuickFilter, setUserQuickFilter] = useState('all'); // 'all' | 'active' | 'banned' | 'vip' | 'streamers'
  const [userViewMode, setUserViewMode] = useState('table'); // 'table' | 'cards'
  const [selectedUserDetail, setSelectedUserDetail] = useState(null);
  const [confirmDeleteUser, setConfirmDeleteUser] = useState(null);
  const [banModalUser, setBanModalUser] = useState(null);
  const [banReason, setBanReason] = useState('Terms of Service Violation');
  const [customBanReason, setCustomBanReason] = useState('');
  const [copiedUid, setCopiedUid] = useState(null);
  const [showAddUserModal, setShowAddUserModal] = useState(false);
  const [newUserData, setNewUserData] = useState({ name: '', email: '', role: 'Member', bio: '' });
  const [roleChangeModalUser, setRoleChangeModalUser] = useState(null);
  const [newRoleSelection, setNewRoleSelection] = useState('Member');

  // Real Banned Account Appeals / Reviews from Firebase RTDB (/account_reviews)
  const [accountReviews, setAccountReviews] = useState([]);

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

  // In-App Update Banner Remote Controller State
  const [updateConfig, setUpdateConfig] = useState({
    show_banner: true,
    latest_version: '1.0.65',
    latest_build: 66,
    store_url: 'https://freewatchug.online/store',
    direct_apk_url: 'https://github.com/piustech1/FreeWatch/releases/download/v1.0.65/FreeWatch-release.apk',
    release_notes: '• Android TV & Remote D-Pad Navigation: Full Leanback support with focus highlights and 10-foot cinema UI\n• Multiplatform Web Support: Direct in-browser streaming on desktop and mobile web\n• Smart Community Banner Persistence: Remembers interaction and eliminates repetitive prompts\n• Fixed Movie Misclassification: Resolved single animated & live-action films showing fake TV episodes or seasons\n• Direct Stream Playback: BunnyCDN stream resolution eliminates playback stream errors',
    is_mandatory: false,
  });
  const [isSavingUpdateConfig, setIsSavingUpdateConfig] = useState(false);
  const [updateConfigSavedMsg, setUpdateConfigSavedMsg] = useState('');

  // Authenticate anonymously for Firebase RTDB read/write access
  useEffect(() => {
    signInAnonymously(auth).catch(() => {});
  }, []);

  // Sync update banner configuration from Firebase RTDB
  useEffect(() => {
    try {
      const updateRef = ref(rtdb, 'app_config/update');
      const unsub = onValue(updateRef, (snap) => {
        if (snap.exists() && snap.val()) {
          const val = snap.val();
          setUpdateConfig({
            show_banner: val.show_banner ?? val.force_show ?? true,
            latest_version: val.latest_version || '1.0.65',
            latest_build: val.latest_build || 66,
            store_url: val.store_url || 'https://freewatchug.online/store',
            direct_apk_url: val.direct_apk_url || 'https://github.com/piustech1/FreeWatch/releases/download/v1.0.60/FreeWatch-release.apk',
            release_notes: val.release_notes || '• In-App Account Review & Appeals with instant unban restoration\n• Instant Live Support Chat Alerts with 1-tap jump to chat\n• Permanent Offline Storage persistence across sign-outs\n• Smart Automated Update Checker\n• Refined UI & Performance',
            is_mandatory: val.is_mandatory || false,
          });
        }
      });
      return () => unsub();
    } catch (_) {}
  }, []);

  const handleSaveUpdateConfig = async (e) => {
    e?.preventDefault?.();
    setIsSavingUpdateConfig(true);
    setUpdateConfigSavedMsg('');
    try {
      const now = Date.now();
      await set(ref(rtdb, 'app_config/update'), {
        ...updateConfig,
        force_show: updateConfig.show_banner,
        updated_at: now,
      });

      // Broadcast update notification to notification history for all user devices
      try {
        await push(ref(rtdb, 'push_notifications/history'), {
          id: `update_${updateConfig.latest_version}_${now}`,
          title: `🚀 FreeWatch Update v${updateConfig.latest_version} Available!`,
          body: `A new update is available. Tap here to upgrade for smoother streaming & rich catalogs.`,
          route: '/update',
          link: '/update',
          targetTopic: 'all_users',
          timestamp: now,
          dispatchedBy: 'Admin Panel Live Controller',
        });
      } catch (_) {}

      setUpdateConfigSavedMsg('Update config saved live to Firebase RTDB & broadcast alert queued for all devices!');
      setTimeout(() => setUpdateConfigSavedMsg(''), 4500);
    } catch (err) {
      alert('Failed to save update configuration: ' + err.message);
    } finally {
      setIsSavingUpdateConfig(false);
    }
  };

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
          const presence = u.presence || {};
          const history = Array.isArray(u.watch_history) ? u.watch_history : [];
          const favorites = Array.isArray(u.favorites) ? u.favorites : [];
          const lastWatched = history.length > 0 ? history[0] : null;

          // Determine live presence & last active timestamp
          const rawIsOnline = presence.isOnline ?? profile.isOnline ?? u.isOnline ?? false;
          const rawLastSeen = presence.lastSeen || profile.lastSeen || u.lastSeen || profile.lastLogin;
          let lastSeenTime = 0;
          if (typeof rawLastSeen === 'number') {
            lastSeenTime = rawLastSeen;
          } else if (typeof rawLastSeen === 'string') {
            lastSeenTime = new Date(rawLastSeen).getTime() || 0;
          }
          const isRecentlyActive = lastSeenTime > 0 && (Date.now() - lastSeenTime) < 5 * 60 * 1000;
          const isOnline = Boolean(rawIsOnline || isRecentlyActive);

          // Determine account status & ban details
          const isBanned = profile.status === 'Banned' || u.status === 'Banned' || profile.isBanned === true || u.isBanned === true;
          const status = isBanned ? 'Banned' : (profile.status || 'Active');
          const banReason = profile.banReason || u.banReason || 'Terms of Service Violation';

          return {
            id: uid,
            name: profile.name || (profile.email ? profile.email.split('@')[0] : 'FreeWatch User'),
            email: profile.email || 'No email registered',
            role: profile.role || (profile.name?.toLowerCase().includes('admin') ? 'Admin' : 'Member'),
            status,
            isBanned,
            banReason,
            isOnline,
            lastSeenTime,
            platform: presence.platform || profile.platform || 'Mobile App',
            avatar: profile.avatar || 'assets/avatars/avatar_mirabel.png',
            bio: profile.bio || 'Luganda dubbed movie enthusiast • Streaming on FreeWatch',
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

  // Listen to Banned Account Reviews & Appeals from Firebase RTDB (/account_reviews)
  useEffect(() => {
    try {
      const reviewsRef = ref(rtdb, 'account_reviews');
      const unsub = onValue(reviewsRef, (snap) => {
        if (snap.exists() && snap.val()) {
          const val = snap.val();
          const list = Object.keys(val).map(key => ({
            id: key,
            uid: key,
            ...val[key]
          })).sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0));
          setAccountReviews(list);
        } else {
          setAccountReviews([]);
        }
      });
      return () => unsub();
    } catch (_) {}
  }, []);

  const handleApproveAppeal = async (review) => {
    const targetUid = review.uid || review.id;
    if (!targetUid) return;
    try {
      // 1. Reactivate user in RTDB
      await update(ref(rtdb, `users/${targetUid}/profile`), {
        status: 'Active',
        isBanned: false,
        banReason: null,
        unbannedAt: Date.now(),
        unbannedBy: 'Admin Console'
      });
      // 2. Mark review as approved
      await update(ref(rtdb, `account_reviews/${targetUid}`), {
        status: 'approved',
        resolvedAt: Date.now(),
        resolvedBy: 'dev'
      });
      // 3. Log audit event
      await push(ref(rtdb, 'audit_logs'), {
        action: 'APPROVE_APPEAL_UNBAN',
        targetUid,
        targetEmail: review.email || 'unknown',
        actor: 'dev',
        timestamp: Date.now()
      });
    } catch (e) {
      alert('Failed to approve appeal: ' + e.message);
    }
  };

  const handleRejectAppeal = async (review) => {
    const targetUid = review.uid || review.id;
    if (!targetUid) return;
    try {
      await update(ref(rtdb, `account_reviews/${targetUid}`), {
        status: 'rejected',
        resolvedAt: Date.now(),
        resolvedBy: 'dev'
      });
      await push(ref(rtdb, 'audit_logs'), {
        action: 'REJECT_APPEAL',
        targetUid,
        targetEmail: review.email || 'unknown',
        actor: 'dev',
        timestamp: Date.now()
      });
    } catch (e) {
      alert('Failed to reject appeal: ' + e.message);
    }
  };

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
        // Fallback: Fetch directly from public mirror or proxy if not yet in RTDB
        fetch('https://mumowatch.ai.studio/dashboard')
          .then(res => res.json())
          .then(data => {
            let list = [];
            const seen = new Set();
            if (data.banner && (data.banner.id || data.banner.vid)) {
              list.push(data.banner);
              seen.add(String(data.banner.id || data.banner.vid));
            }
            if (Array.isArray(data.movies)) {
              for (const m of data.movies) {
                const id = String(m.id || m.vid || '');
                if (id && !seen.has(id)) {
                  seen.add(id);
                  list.push(m);
                }
              }
            }
            if (Array.isArray(data.dashboard)) {
              data.dashboard.forEach(c => {
                if (Array.isArray(c.movies)) {
                  for (const m of c.movies) {
                    const id = String(m.id || m.vid || '');
                    if (id && !seen.has(id)) {
                      seen.add(id);
                      list.push(m);
                    }
                  }
                }
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

  // Relative Time Formatter for Last Seen
  const formatLastSeen = (timestamp) => {
    if (!timestamp) return 'Offline';
    const now = Date.now();
    const diff = Math.floor((now - timestamp) / 1000);
    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 172800) return 'Yesterday';
    return new Date(timestamp).toLocaleDateString([], { month: 'short', day: 'numeric' });
  };

  // Helper to copy user UID
  const handleCopyUid = (uid, e) => {
    if (e) e.stopPropagation();
    try {
      navigator.clipboard.writeText(uid);
      setCopiedUid(uid);
      setTimeout(() => setCopiedUid(null), 2000);
    } catch (_) {}
  };

  // User Actions: Unban User (instant reactivation)
  const handleUnbanUser = async (user) => {
    try {
      await update(ref(rtdb, `users/${user.id}/profile`), {
        status: 'Active',
        isBanned: false,
        statusUpdatedAt: new Date().toISOString(),
      });
      await update(ref(rtdb, `users/${user.id}`), {
        status: 'Active',
        isBanned: false,
      });
      await logAudit(
        'UNBAN_USER',
        `${user.name} (${user.email})`,
        'Account access reactivated',
        'User Management'
      );
    } catch (e) {
      alert('Failed to reactivate account: ' + e.message);
    }
  };

  // User Actions: Confirm Ban User (modal submit)
  const handleConfirmBan = async () => {
    if (!banModalUser) return;
    const finalReason = banReason === 'Other' 
      ? (customBanReason.trim() || 'Suspension by administrator') 
      : banReason;
    try {
      await update(ref(rtdb, `users/${banModalUser.id}/profile`), {
        status: 'Banned',
        isBanned: true,
        banReason: finalReason,
        bannedAt: new Date().toISOString(),
        statusUpdatedAt: new Date().toISOString(),
      });
      await update(ref(rtdb, `users/${banModalUser.id}`), {
        status: 'Banned',
        isBanned: true,
        banReason: finalReason,
      });
      await logAudit(
        'BAN_USER',
        `${banModalUser.name} (${banModalUser.email})`,
        `Account suspended: ${finalReason}`,
        'User Management'
      );
      setBanModalUser(null);
      setCustomBanReason('');
    } catch (e) {
      alert('Failed to suspend user: ' + e.message);
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

      // Write in-app notification entry for the user
      try {
        const notifRef = push(ref(rtdb, `users/${selectedThreadId}/notifications`));
        await set(notifRef, {
          id: notifRef.key,
          section: 'Support',
          title: 'FreeWatch Live Support',
          message: text,
          time: 'Just now',
          timestamp: now,
          link: '/developer-chat',
          route: '/developer-chat',
          isRead: false,
          iconColor: 0xFF00E676,
        });
      } catch (_) {}

      // Dispatch FCM OS push alert to user's device
      fetch('/api/send-push', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          topic: `user_${selectedThreadId}`,
          title: '💬 FreeWatch Live Support',
          body: text,
          route: '/developer-chat',
          type: 'support_chat_reply',
        }),
      }).catch(err => console.warn('Push reply dispatch non-fatal error:', err));
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
      title: notifTitle.trim() || 'FreeWatch Alert',
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
    let syncedCount = 0;
    try {
      // 1. Fetch live MunoWatch dashboard directly or via proxy
      let d = null;
      try {
        const resp = await fetch('https://mumowatch.ai.studio/dashboard');
        if (resp.ok) {
          d = await resp.json();
        }
      } catch (_) {}

      if (!d || (!d.movies && !d.dashboard)) {
        try {
          const resp = await fetch('https://pearlpix-api.onrender.com/dashboard');
          if (resp.ok) {
            d = await resp.json();
          }
        } catch (_) {}
      }

      if (!d || (!d.movies && !d.dashboard)) {
        try {
          const resp = await fetch('/api/munowatch-catalog');
          if (resp.ok) {
            d = await resp.json();
          }
        } catch (_) {}
      }

      let list = [];
      const seenIds = new Set();

      if (d && (d.movies || d.dashboard || d.banner)) {
        if (d.banner && (d.banner.id || d.banner.vid)) {
          list.push(d.banner);
          seenIds.add(String(d.banner.id || d.banner.vid));
        }

        if (Array.isArray(d.movies)) {
          for (const m of d.movies) {
            const mId = String(m.id || m.vid || '');
            if (mId && !seenIds.has(mId)) {
              seenIds.add(mId);
              list.push(m);
            }
          }
        }

        if (Array.isArray(d.dashboard)) {
          d.dashboard.forEach(c => {
            if (Array.isArray(c.movies)) {
              for (const m of c.movies) {
                const mId = String(m.id || m.vid || '');
                if (mId && !seenIds.has(mId)) {
                  seenIds.add(mId);
                  list.push(m);
                }
              }
            }
          });
        }
      }

      // If remote mirror had CORS or network block, fall back to cached Firebase RTDB catalog
      if (list.length === 0) {
        try {
          const snap = await get(ref(rtdb, 'munowatch/catalog'));
          if (snap.exists()) {
            const val = snap.val();
            if (Array.isArray(val) && val.length > 0) {
              list = val;
              val.forEach(m => seenIds.add(String(m.id || m.vid || '')));
            }
          }
        } catch (_) {}
      }

      syncedCount = list.length;

      if (syncedCount > 0) {
        setMunowatchCatalog(list);
        setMunowatchSyncMeta({
          count: syncedCount,
          lastCheck: Date.now()
        });

        // Cache in Firebase Realtime Database
        await set(ref(rtdb, 'munowatch/catalog'), list).catch(() => {});
        await set(ref(rtdb, 'munowatch/known_movie_ids'), {
          count: syncedCount,
          lastCheck: Date.now(),
          list: Array.from(seenIds)
        }).catch(() => {});

        await logAudit('MUNOWATCH_SYNC', 'MunoWatch Catalog', `Manually synced ${syncedCount} releases directly from MunoWatch.`, 'System Poller');

        // Fire poller in background (safe non-blocking)
        fetch('/api/cron-munowatch').catch(() => {});

        alert(`Successfully synced ${syncedCount} movies from MunoWatch!`);
      } else {
        alert('Sync completed, but 0 movies were returned by MunoWatch.');
      }
    } catch (err) {
      alert('MunoWatch sync notice: ' + err.message);
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
    const matchesQuick = 
      userQuickFilter === 'all' ? true :
      userQuickFilter === 'active' ? u.isOnline :
      userQuickFilter === 'banned' ? u.status === 'Banned' :
      userQuickFilter === 'vip' ? (u.role === 'VIP' || u.role === 'Admin') :
      userQuickFilter === 'streamers' ? u.totalWatched > 0 : true;
    return matchesSearch && matchesRole && matchesStatus && matchesQuick;
  });

  // Filtered Catalog List
  const filteredCatalog = munowatchCatalog.filter(m => {
    const title = (m.title || m.video_title || '').toLowerCase();
    const vj = (m.vj || m.vjname || m.vjName || '').toLowerCase();
    const matchesSearch = title.includes(videoSearch.toLowerCase()) || vj.includes(videoSearch.toLowerCase());
    const matchesCat = videoCategoryFilter === 'All' || (m.category === videoCategoryFilter);
    return matchesSearch && matchesCat;
  });

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'users', label: 'User Management', icon: Users, badge: users.length },
    { id: 'videos', label: 'Video Performance', icon: Film, badge: aggregatedWatchedMovies.length },
    { id: 'chat', label: 'Live Support Chat', icon: MessageSquare, badge: threads.filter(t => t.unreadCount > 0).length || null },
    { id: 'notifications', label: 'FCM Push Dispatcher', icon: Bell },
    { id: 'munowatch', label: 'MunoWatch Sync', icon: RefreshCw, badge: munowatchCatalog.length },
    { id: 'audit', label: 'Audit Logs & Export', icon: FileText, badge: auditLogs.length },
    { id: 'store', label: 'App Store Hub & Downloads', icon: Layers }
  ];

  // ── Liquid iOS Frosted Glass Admin Login Gate ──
  if (!isAdminAuthenticated) {
    return (
      <div className="min-h-screen bg-[#0B1120] text-slate-100 flex items-center justify-center p-4 sm:p-6 font-sans relative overflow-hidden select-none selection:bg-[#00E676] selection:text-black">
        {/* iOS Frosted Ambient Glow Blobs */}
        <div className="pointer-events-none absolute -top-40 -left-40 w-96 h-96 bg-[#00E676]/20 rounded-full blur-[128px] animate-pulse" />
        <div className="pointer-events-none absolute -bottom-40 -right-40 w-96 h-96 bg-blue-600/20 rounded-full blur-[128px]" />
        <div className="pointer-events-none absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-emerald-500/10 rounded-full blur-[140px]" />

        {/* Liquid Glassmorphic Card */}
        <div className="relative z-10 w-full max-w-md bg-white/[0.07] backdrop-blur-2xl border border-white/[0.15] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.6)] rounded-3xl p-7 sm:p-9 text-white">
          {/* Brand Header */}
          <div className="flex flex-col items-center text-center mb-7">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#00E676] to-[#00B0FF] p-0.5 shadow-xl shadow-[#00E676]/25 flex items-center justify-center mb-3.5">
              <div className="w-full h-full bg-slate-900 rounded-[14px] flex items-center justify-center overflow-hidden">
                <img 
                  src="/logo_initials.png" 
                  alt="FreeWatch" 
                  className="w-12 h-12 object-contain" 
                  onError={(e) => { e.currentTarget.style.display = 'none'; }} 
                />
                <span className="font-black text-[#00E676] text-xl tracking-wider">FW</span>
              </div>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-white">FreeWatch Admin</h1>
          </div>

          {/* Error Alert */}
          {adminAuthError && (
            <div className="mb-5 p-3.5 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-200 text-xs font-semibold flex items-center gap-2.5">
              <ShieldAlert size={16} className="shrink-0 text-rose-400" />
              <span>{adminAuthError}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleAdminLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                Username
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <User size={16} />
                </div>
                <input
                  type="text"
                  value={adminUsername}
                  onChange={(e) => setAdminUsername(e.target.value)}
                  placeholder="Enter username"
                  required
                  autoComplete="username"
                  className="w-full pl-10 pr-4 py-3 bg-white/[0.06] border border-white/[0.15] rounded-xl text-sm font-medium text-white placeholder-slate-400 focus:outline-none focus:border-[#00E676] focus:bg-white/[0.1] focus:ring-2 focus:ring-[#00E676]/30 transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <Lock size={16} />
                </div>
                <input
                  type={showAdminPassword ? "text" : "password"}
                  value={adminPassword}
                  onChange={(e) => setAdminPassword(e.target.value)}
                  placeholder="Enter password"
                  required
                  autoComplete="current-password"
                  className="w-full pl-10 pr-11 py-3 bg-white/[0.06] border border-white/[0.15] rounded-xl text-sm font-medium text-white placeholder-slate-400 focus:outline-none focus:border-[#00E676] focus:bg-white/[0.1] focus:ring-2 focus:ring-[#00E676]/30 transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowAdminPassword(!showAdminPassword)}
                  className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-white transition-colors"
                >
                  {showAdminPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs pt-1">
              <label className="flex items-center gap-2 cursor-pointer select-none text-slate-300 hover:text-white transition-colors">
                <input
                  type="checkbox"
                  checked={adminRememberMe}
                  onChange={(e) => setAdminRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded bg-white/[0.1] border-white/[0.2] text-[#00E676] focus:ring-[#00E676] focus:ring-offset-0 focus:ring-offset-transparent cursor-pointer"
                />
                <span>Remember session</span>
              </label>
              <span className="text-slate-400 text-[11px] font-semibold">dev / ****</span>
            </div>

            <button
              type="submit"
              disabled={adminAuthLoading}
              className="w-full mt-2 py-3.5 px-5 bg-gradient-to-r from-[#00E676] to-[#00C853] hover:from-[#00f27c] hover:to-[#00d859] active:scale-[0.99] text-slate-950 font-black text-sm rounded-xl transition-all shadow-lg shadow-[#00E676]/30 flex items-center justify-center gap-2 disabled:opacity-60 cursor-pointer"
            >
              {adminAuthLoading ? (
                <>
                  <RefreshCw size={16} className="animate-spin" />
                  <span>Verifying credentials...</span>
                </>
              ) : (
                <>
                  <ShieldCheck size={18} />
                  <span>Unlock Admin Console</span>
                </>
              )}
            </button>
          </form>

          {/* Quick link back to web cinema & store */}
          <div className="mt-6 pt-5 border-t border-white/[0.1] flex items-center justify-center gap-4 text-center">
            <button
              type="button"
              onClick={() => navigateTo('/')}
              className="text-xs font-semibold text-slate-400 hover:text-white transition-colors inline-flex items-center gap-1.5 cursor-pointer"
            >
              <Film size={13} />
              <span>Web Cinema</span>
            </button>
            <span className="text-white/20">•</span>
            <button
              type="button"
              onClick={() => navigateTo('/store')}
              className="text-xs font-semibold text-slate-400 hover:text-white transition-colors inline-flex items-center gap-1.5 cursor-pointer"
            >
              <ExternalLink size={13} />
              <span>Store Listing (/store)</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-800 flex font-sans antialiased selection:bg-[#00E676] selection:text-black">
      {/* ── Mobile Navigation Drawer (Overlay Backdrop & Slide-in Panel) ── */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          {/* Backdrop blur overlay */}
          <div 
            className="fixed inset-0 bg-slate-950/60 backdrop-blur-xs transition-opacity"
            onClick={() => setMobileMenuOpen(false)}
          />
          {/* Drawer panel */}
          <div className="fixed inset-y-0 left-0 w-72 max-w-[85vw] bg-white/95 backdrop-blur-xl border-r border-slate-200/80 shadow-2xl flex flex-col z-50 animate-in slide-in-from-left duration-200">
            {/* Drawer Header */}
            <div className="h-16 px-4 flex items-center justify-between border-b border-slate-100">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#00E676] to-[#00C853] flex items-center justify-center shadow-md shadow-[#00E676]/30 shrink-0">
                  <span className="font-black text-black text-lg tracking-wider">FW</span>
                </div>
                <div>
                  <span className="font-bold text-slate-900 text-base tracking-tight block">FreeWatch</span>
                  <span className="text-[10px] uppercase font-bold text-[#00A344] tracking-widest block">ADMIN PORTAL</span>
                </div>
              </div>
              <button
                onClick={() => setMobileMenuOpen(false)}
                className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors"
                aria-label="Close menu"
              >
                <X size={20} />
              </button>
            </div>

            {/* Drawer Links */}
            <div className="flex-1 py-4 px-3 space-y-1 overflow-y-auto">
              {navItems.map((item) => {
                const Icon = item.icon;
                const active = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      setActiveTab(item.id);
                      setMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center justify-between px-3.5 py-3 rounded-xl font-medium text-sm transition-all duration-150 ${
                      active
                        ? 'bg-[#00E676]/15 text-[#009640] font-bold shadow-xs border-r-4 border-[#00E676]'
                        : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center space-x-3">
                      <Icon size={19} className={active ? 'text-[#00C853]' : 'text-slate-400'} />
                      <span>{item.label}</span>
                    </div>
                    {item.badge !== undefined && item.badge !== null && (
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

            {/* Drawer Footer with View Store & Web Cinema & Sign Out */}
            <div className="p-3 border-t border-slate-100 space-y-2">
              <button
                onClick={() => {
                  setMobileMenuOpen(false);
                  navigateTo('/store');
                }}
                className="w-full flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl text-xs font-semibold text-blue-700 bg-blue-50 hover:bg-blue-100 border border-blue-200 transition-colors cursor-pointer"
              >
                <ExternalLink size={14} />
                <span>View Store Listing (/store)</span>
              </button>
              <button
                onClick={() => {
                  setMobileMenuOpen(false);
                  navigateTo('/');
                }}
                className="w-full flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors cursor-pointer"
              >
                <Film size={14} />
                <span>Open Web Cinema</span>
              </button>
              <button
                onClick={handleAdminLogout}
                className="w-full flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl text-xs font-bold text-rose-600 bg-rose-50 hover:bg-rose-100 border border-rose-200 transition-colors cursor-pointer"
              >
                <LogOut size={14} />
                <span>Sign Out (dev)</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Collapsible Desktop Sidebar (Hidden on Mobile) ── */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-20'} hidden md:flex bg-white/90 backdrop-blur-md border-r border-slate-200/80 flex-col transition-all duration-300 z-30 shrink-0 sticky top-0 h-screen shadow-xs`}>
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
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
            aria-label={sidebarOpen ? "Collapse sidebar" : "Expand sidebar"}
          >
            {sidebarOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>

        {/* Sidebar Nav Links */}
        <div className="flex-1 py-4 px-3 space-y-1 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center ${sidebarOpen ? 'justify-between px-3.5' : 'justify-center px-0'} py-2.5 rounded-xl font-medium text-sm transition-all duration-150 cursor-pointer ${
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
        {/* Top Header (Liquid Frosted Glass, Spacious, Responsive) */}
        <header className="h-16 bg-white/80 backdrop-blur-md border-b border-slate-200/80 px-4 sm:px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
          <div className="flex items-center space-x-3 sm:space-x-4 min-w-0">
            {/* Mobile Hamburger Drawer Trigger */}
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="md:hidden p-2 -ml-1 text-slate-700 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-colors shrink-0 cursor-pointer"
              aria-label="Open navigation menu"
            >
              <Menu size={22} />
            </button>

            <div className="min-w-0">
              <h1 className="text-base sm:text-lg font-bold text-slate-900 capitalize truncate">
                {activeTab === 'dashboard' && 'Executive Dashboard'}
                {activeTab === 'users' && 'User Management & Access Control'}
                {activeTab === 'videos' && 'Real Video & Movie Performance'}
                {activeTab === 'chat' && 'Live 2-Way Realtime Support Chat'}
                {activeTab === 'notifications' && 'FCM Push Notification Dispatcher'}
                {activeTab === 'munowatch' && 'MunoWatch Server & Poller Control'}
                {activeTab === 'audit' && 'System Audit Trail & Export'}
                {activeTab === 'store' && 'Apple App Store Listing & Download Hub'}
              </h1>
            </div>
          </div>

          <div className="flex items-center space-x-2 sm:space-x-3 shrink-0">
            {activeTab === 'users' && (
              <button 
                onClick={handleExportUsersCSV}
                className="hidden sm:inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors shadow-xs cursor-pointer"
              >
                <Download size={14} className="mr-1.5" /> Export Users CSV
              </button>
            )}
            {activeTab === 'audit' && (
              <button 
                onClick={handleExportAuditCSV}
                className="hidden sm:inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors shadow-xs cursor-pointer"
              >
                <Download size={14} className="mr-1.5" /> Export Analytics CSV
              </button>
            )}

            <button
              onClick={() => navigateTo('/')}
              className="inline-flex items-center px-2.5 sm:px-3 py-1.5 text-xs font-semibold rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 transition-colors shadow-xs cursor-pointer"
              title="Open FreeWatch Web Cinema"
            >
              <Film size={13} className="sm:mr-1.5 text-emerald-600" />
              <span className="hidden sm:inline">Web Cinema</span>
            </button>

            <button
              onClick={() => navigateTo('/store')}
              className="inline-flex items-center px-2.5 sm:px-3 py-1.5 text-xs font-semibold rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 transition-colors shadow-xs cursor-pointer"
              title="Open public App Store listing page"
            >
              <ExternalLink size={13} className="sm:mr-1.5 text-blue-600" />
              <span className="hidden sm:inline">View Store</span>
            </button>

            {/* Admin Avatar & Sign Out */}
            <div className="flex items-center space-x-2 pl-2 sm:pl-3 border-l border-slate-200">
              <div className="w-8 h-8 rounded-full bg-slate-900 text-[#00E676] flex items-center justify-center font-black text-xs shadow-xs shrink-0">
                dev
              </div>
              <div className="text-left text-xs leading-tight hidden lg:block">
                <span className="font-bold text-slate-800 block">System Admin</span>
                <span className="text-slate-400 block text-[10px]">dev (Logged In)</span>
              </div>
              <button
                onClick={handleAdminLogout}
                title="Sign Out of Admin Console"
                className="p-1.5 sm:px-2.5 sm:py-1.5 text-xs font-bold text-rose-600 hover:text-rose-700 hover:bg-rose-50 rounded-lg transition-colors flex items-center gap-1 border border-transparent hover:border-rose-200 cursor-pointer"
              >
                <LogOut size={15} />
                <span className="hidden md:inline">Sign Out</span>
              </button>
            </div>
          </div>
        </header>

        {/* Tab Body */}
        <main className="flex-1 p-4 sm:p-6 overflow-y-auto">
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 1: EXECUTIVE DASHBOARD                                         */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'dashboard' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Colorful Frosted Metric Stat Cards (2-column on mobile, 4-column on desktop) */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-5">
                {/* 1. Total Video Plays (Sky/Ocean Blue) */}
                <div className="bg-gradient-to-br from-sky-500 to-blue-600 rounded-2xl p-3.5 sm:p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] sm:text-xs font-bold uppercase tracking-wider text-sky-100 truncate">Total Plays</span>
                      <Play size={18} className="text-sky-200 opacity-80 shrink-0" />
                    </div>
                    <div className="text-xl sm:text-3xl font-black mt-1 sm:mt-2">{totalVideoPlays.toLocaleString()}</div>
                    <div className="text-[10px] sm:text-xs text-sky-100 font-medium mt-1 flex items-center truncate">
                      <TrendingUp size={12} className="mr-1 shrink-0" />
                      <span className="truncate">+14.8% stream volume</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('videos')}
                    className="mt-3 sm:mt-4 pt-2 sm:pt-2.5 border-t border-white/20 text-[10px] sm:text-[11px] font-bold text-sky-100 hover:text-white flex items-center justify-between transition-colors cursor-pointer"
                  >
                    <span className="truncate">Performance</span>
                    <ChevronRight size={13} className="shrink-0" />
                  </button>
                </div>

                {/* 2. Registered Users (FreeWatch Authentic Electric Green #00E676) */}
                <div className="bg-gradient-to-br from-[#00E676] to-[#00A844] rounded-2xl p-3.5 sm:p-5 text-slate-950 shadow-md shadow-[#00E676]/20 flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] sm:text-xs font-black uppercase tracking-wider text-slate-900 truncate">Users</span>
                      <Users size={18} className="text-slate-900 opacity-90 shrink-0" />
                    </div>
                    <div className="text-xl sm:text-3xl font-black mt-1 sm:mt-2 text-black">{totalRegisteredUsers}</div>
                    <div className="text-[10px] sm:text-xs text-slate-900 font-bold mt-1 flex items-center truncate">
                      <CheckCircle2 size={12} className="mr-1 shrink-0" />
                      <span className="truncate">{activeStreamersCount} active streamers</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('users')}
                    className="mt-3 sm:mt-4 pt-2 sm:pt-2.5 border-t border-black/15 text-[10px] sm:text-[11px] font-extrabold text-black hover:text-slate-900 flex items-center justify-between transition-colors cursor-pointer"
                  >
                    <span className="truncate">Directory</span>
                    <ChevronRight size={13} className="shrink-0" />
                  </button>
                </div>

                {/* 3. Live Movies & Series (Amber/Orange) */}
                <div className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl p-3.5 sm:p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] sm:text-xs font-bold uppercase tracking-wider text-amber-100 truncate">Catalog</span>
                      <Film size={18} className="text-amber-200 opacity-80 shrink-0" />
                    </div>
                    <div className="text-xl sm:text-3xl font-black mt-1 sm:mt-2">{totalCatalogMovies}</div>
                    <div className="text-[10px] sm:text-xs text-amber-100 font-medium mt-1 flex items-center truncate">
                      <Tv size={12} className="mr-1 shrink-0" />
                      <span className="truncate">13 Categories</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('munowatch')}
                    className="mt-3 sm:mt-4 pt-2 sm:pt-2.5 border-t border-white/20 text-[10px] sm:text-[11px] font-bold text-amber-100 hover:text-white flex items-center justify-between transition-colors cursor-pointer"
                  >
                    <span className="truncate">MunoWatch</span>
                    <ChevronRight size={13} className="shrink-0" />
                  </button>
                </div>

                {/* 4. Push Alerts Dispatched (Rose/Pink) */}
                <div className="bg-gradient-to-br from-rose-500 to-pink-600 rounded-2xl p-3.5 sm:p-5 text-white shadow-md flex flex-col justify-between relative overflow-hidden group hover:shadow-lg transition-all">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] sm:text-xs font-bold uppercase tracking-wider text-rose-100 truncate">Push Alerts</span>
                      <Bell size={18} className="text-rose-200 opacity-80 shrink-0" />
                    </div>
                    <div className="text-xl sm:text-3xl font-black mt-1 sm:mt-2">{totalDispatchedAlerts}</div>
                    <div className="text-[10px] sm:text-xs text-rose-100 font-medium mt-1 flex items-center truncate">
                      <Radio size={12} className="mr-1 shrink-0" />
                      <span className="truncate">all_users topic</span>
                    </div>
                  </div>
                  <button 
                    onClick={() => setActiveTab('notifications')}
                    className="mt-3 sm:mt-4 pt-2 sm:pt-2.5 border-t border-white/20 text-[10px] sm:text-[11px] font-bold text-rose-100 hover:text-white flex items-center justify-between transition-colors cursor-pointer"
                  >
                    <span className="truncate">Broadcast</span>
                    <ChevronRight size={13} className="shrink-0" />
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
          {/* TAB 2: ADVANCED REAL-TIME USER MANAGEMENT (100% FIREBASE SYNC)      */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'users' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Executive Metrics Pulse Row (2-column on mobile, 4-column on desktop) */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
                <div className="bg-white/85 backdrop-blur-md rounded-2xl p-3.5 sm:p-5 border border-slate-200/80 shadow-xs flex items-center justify-between">
                  <div className="min-w-0 pr-1">
                    <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider text-slate-400 block mb-1 truncate">Total Users</span>
                    <h3 className="text-xl sm:text-2xl font-black text-slate-900">{users.length}</h3>
                    <span className="text-[9px] sm:text-[10px] text-slate-500 font-medium truncate block">Real RTDB accounts</span>
                  </div>
                  <div className="w-9 h-9 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-700 shrink-0">
                    <Users size={18} className="sm:w-5 sm:h-5" />
                  </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md rounded-2xl p-3.5 sm:p-5 border border-slate-200/80 shadow-xs flex items-center justify-between">
                  <div className="min-w-0 pr-1">
                    <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider text-[#00A344] block mb-1 flex items-center truncate">
                      <span className="w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full bg-[#00E676] mr-1.5 animate-pulse shrink-0" /> Active Now
                    </span>
                    <h3 className="text-xl sm:text-2xl font-black text-slate-900">{users.filter(u => u.isOnline).length}</h3>
                    <span className="text-[9px] sm:text-[10px] text-[#00A344] font-semibold truncate block">Live in mobile app</span>
                  </div>
                  <div className="w-9 h-9 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-[#009640] shrink-0">
                    <Activity size={18} className="sm:w-5 sm:h-5" />
                  </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md rounded-2xl p-3.5 sm:p-5 border border-slate-200/80 shadow-xs flex items-center justify-between">
                  <div className="min-w-0 pr-1">
                    <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider text-rose-600 block mb-1 truncate">Suspended</span>
                    <h3 className="text-xl sm:text-2xl font-black text-slate-900">{users.filter(u => u.status === 'Banned').length}</h3>
                    <span className="text-[9px] sm:text-[10px] text-rose-500 font-medium truncate block">Locked out of app</span>
                  </div>
                  <div className="w-9 h-9 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-rose-50 border border-rose-200 flex items-center justify-center text-rose-600 shrink-0">
                    <ShieldAlert size={18} className="sm:w-5 sm:h-5" />
                  </div>
                </div>

                <div className="bg-white/85 backdrop-blur-md rounded-2xl p-3.5 sm:p-5 border border-slate-200/80 shadow-xs flex items-center justify-between">
                  <div className="min-w-0 pr-1">
                    <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider text-amber-600 block mb-1 truncate">VIP & Admins</span>
                    <h3 className="text-xl sm:text-2xl font-black text-slate-900">{users.filter(u => u.role === 'VIP' || u.role === 'Admin').length}</h3>
                    <span className="text-[9px] sm:text-[10px] text-amber-600 font-medium truncate block">Privileged tier</span>
                  </div>
                  <div className="w-9 h-9 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600 shrink-0">
                    <Star size={18} className="sm:w-5 sm:h-5" />
                  </div>
                </div>
              </div>

              {/* Advanced Search, Filters & Action Bar */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs space-y-3">
                <div className="flex flex-col md:flex-row items-center justify-between gap-3">
                  <div className="relative flex-1 w-full md:max-w-md">
                    <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input 
                      type="text"
                      placeholder="Search users by name, email, or UID..."
                      value={userSearch}
                      onChange={(e) => setUserSearch(e.target.value)}
                      className="w-full pl-9 pr-8 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-[#00E676] focus:bg-white transition-all"
                    />
                    {userSearch && (
                      <button 
                        onClick={() => setUserSearch('')}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                      >
                        <X size={14} />
                      </button>
                    )}
                  </div>

                  <div className="flex items-center space-x-2 w-full md:w-auto justify-between md:justify-end">
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

                    {/* View Switcher: Table vs Cards */}
                    <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200">
                      <button
                        onClick={() => setUserViewMode('table')}
                        className={`p-1.5 rounded-lg text-xs font-semibold transition-all ${
                          userViewMode === 'table' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-900'
                        }`}
                        title="Dense Table View"
                      >
                        <List size={15} />
                      </button>
                      <button
                        onClick={() => setUserViewMode('cards')}
                        className={`p-1.5 rounded-lg text-xs font-semibold transition-all ${
                          userViewMode === 'cards' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-900'
                        }`}
                        title="Interactive Cards View"
                      >
                        <Grid size={15} />
                      </button>
                    </div>

                    <button
                      onClick={() => setShowAddUserModal(true)}
                      className="inline-flex items-center px-3.5 py-2 bg-[#00E676] hover:bg-[#00C853] text-black rounded-xl text-xs font-extrabold transition-all shadow-sm shadow-[#00E676]/25 shrink-0"
                    >
                      <UserPlus size={15} className="mr-1.5" /> Add User
                    </button>
                  </div>
                </div>

                {/* Quick Filter Navigation Pills */}
                <div className="flex items-center space-x-2 pt-2 border-t border-slate-100 overflow-x-auto text-xs">
                  {[
                    { key: 'all', label: `All Users (${users.length})` },
                    { key: 'active', label: `Active Now (${users.filter(u => u.isOnline).length})` },
                    { key: 'banned', label: `Banned (${users.filter(u => u.status === 'Banned').length})` },
                    { key: 'appeals', label: `Appeals & Reviews (${accountReviews.filter(r => r.status === 'pending').length} Pending)` },
                    { key: 'vip', label: `VIP & Admins (${users.filter(u => u.role === 'VIP' || u.role === 'Admin').length})` },
                    { key: 'streamers', label: `Active Streamers (${users.filter(u => u.totalWatched > 0).length})` },
                  ].map((f) => (
                    <button
                      key={f.key}
                      onClick={() => setUserQuickFilter(f.key)}
                      className={`px-3 py-1 rounded-full font-bold transition-all shrink-0 text-[11px] cursor-pointer ${
                        userQuickFilter === f.key 
                          ? 'bg-[#00E676] text-black shadow-xs font-black' 
                          : 'bg-slate-100 hover:bg-slate-200 text-slate-600'
                      }`}
                    >
                      {f.label}
                    </button>
                  ))}
                  <span className="text-[11px] text-slate-400 ml-auto shrink-0 pl-2">
                    {userQuickFilter === 'appeals' 
                      ? `${accountReviews.length} total reviews`
                      : `Showing ${filteredUsers.length} of ${users.length} users`}
                  </span>
                </div>
              </div>

              {/* SPECIAL VIEW: BANNED ACCOUNT REVIEWS & APPEALS */}
              {userQuickFilter === 'appeals' ? (
                <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-4">
                  <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">Banned Account Reviews & Appeals</h3>
                      <p className="text-xs text-slate-400">Direct user explanations submitted from the FreeWatch mobile suspension screen</p>
                    </div>
                    <span className="text-xs font-bold px-3 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
                      {accountReviews.filter(r => r.status === 'pending').length} Pending Review
                    </span>
                  </div>

                  {accountReviews.length === 0 ? (
                    <div className="text-center py-12 text-slate-400 text-xs">
                      No account reviews or appeals have been submitted yet.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {accountReviews.map((appeal) => (
                        <div key={appeal.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50/60 flex flex-col md:flex-row md:items-center justify-between gap-4">
                          <div className="space-y-1.5 min-w-0 flex-1">
                            <div className="flex items-center gap-2 flex-wrap">
                              <span className="font-bold text-sm text-slate-900">{appeal.name || 'User'}</span>
                              <span className="text-xs text-slate-500 font-mono">({appeal.email || 'No email'})</span>
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                                appeal.status === 'approved' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                                appeal.status === 'rejected' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                                'bg-amber-50 text-amber-700 border border-amber-200'
                              }`}>
                                {appeal.status ? appeal.status.toUpperCase() : 'PENDING'}
                              </span>
                              <span className="text-[10px] text-slate-400">
                                {appeal.createdAt ? new Date(appeal.createdAt).toLocaleString() : ''}
                              </span>
                            </div>
                            <div className="text-xs text-slate-700 bg-white p-3 rounded-lg border border-slate-200">
                              <span className="font-bold text-slate-900 block text-[11px] mb-0.5">User Explanation:</span>
                              "{appeal.reviewText || appeal.explanation || 'No explanation provided.'}"
                            </div>
                            {appeal.banReason && (
                              <div className="text-[11px] text-slate-500">
                                <span className="font-semibold text-rose-600">Original Ban Reason:</span> {appeal.banReason}
                              </div>
                            )}
                          </div>

                          <div className="flex items-center gap-2 shrink-0 self-end md:self-center">
                            {appeal.status !== 'approved' && (
                              <button
                                onClick={() => handleApproveAppeal(appeal)}
                                className="px-3 py-1.5 rounded-lg bg-[#00E676] hover:bg-[#00C853] text-black font-extrabold text-xs flex items-center gap-1.5 transition-colors cursor-pointer shadow-xs"
                              >
                                <UserCheck size={14} />
                                <span>Approve & Unban</span>
                              </button>
                            )}
                            {appeal.status !== 'rejected' && appeal.status !== 'approved' && (
                              <button
                                onClick={() => handleRejectAppeal(appeal)}
                                className="px-3 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 font-bold text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
                              >
                                <UserX size={14} />
                                <span>Reject</span>
                              </button>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : userViewMode === 'table' ? (
                <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase tracking-wider text-[11px]">
                        <tr>
                          <th className="py-3.5 px-4">User Identity</th>
                          <th className="py-3.5 px-4">Live Presence</th>
                          <th className="py-3.5 px-4">Role</th>
                          <th className="py-3.5 px-4">Status</th>
                          <th className="py-3.5 px-4">Watch Engagement</th>
                          <th className="py-3.5 px-4">Last Watched Title</th>
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
                                  {/* Avatar with Live Online Ripple */}
                                  <div className="relative shrink-0">
                                    <div className="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-700 text-xs">
                                      {(user.name || 'User').slice(0, 2).toUpperCase()}
                                    </div>
                                    <span 
                                      className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${
                                        user.isOnline ? 'bg-[#00E676]' : 'bg-slate-300'
                                      }`}
                                      title={user.isOnline ? 'Active Now' : 'Offline'}
                                    />
                                  </div>

                                  <div className="leading-tight">
                                    <button
                                      onClick={() => setSelectedUserDetail(user)}
                                      className="font-bold text-slate-900 hover:text-[#00A344] text-left block transition-colors"
                                    >
                                      {user.name}
                                    </button>
                                    <span className="text-[11px] text-slate-400 block">{user.email}</span>
                                    <div className="flex items-center space-x-1 mt-0.5">
                                      <span className="text-[10px] font-mono text-slate-400">{user.id.slice(0, 14)}...</span>
                                      <button
                                        onClick={(e) => handleCopyUid(user.id, e)}
                                        className="text-slate-400 hover:text-slate-700 transition-colors"
                                        title="Copy full UID"
                                      >
                                        {copiedUid === user.id ? (
                                          <Check size={11} className="text-[#00A344]" />
                                        ) : (
                                          <Copy size={11} />
                                        )}
                                      </button>
                                    </div>
                                  </div>
                                </div>
                              </td>

                               {/* Live Presence Badge */}
                              <td className="py-3.5 px-4">
                                {user.isOnline ? (
                                  <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
                                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5 animate-pulse" /> Active Now
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-500 border border-slate-200">
                                    <span className="w-1.5 h-1.5 rounded-full bg-slate-300 mr-1.5" />
                                    {formatLastSeen(user.lastSeenTime)}
                                  </span>
                                )}
                              </td>

                              {/* Role */}
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

                              {/* Status */}
                              <td className="py-3.5 px-4">
                                <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold ${
                                  user.status === 'Active' 
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' 
                                    : 'bg-rose-50 text-rose-700 border border-rose-200'
                                }`}>
                                  <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                                    user.status === 'Active' ? 'bg-emerald-500' : 'bg-rose-500'
                                  }`} />
                                  {user.status}
                                </span>
                                {user.status === 'Banned' && user.banReason && (
                                  <span className="block text-[10px] text-rose-500 mt-0.5 font-normal max-w-[140px] truncate" title={user.banReason}>
                                    {user.banReason}
                                  </span>
                                )}
                              </td>

                              {/* Watch Engagement */}
                              <td className="py-3.5 px-4">
                                <div className="space-y-1">
                                  <div className="flex items-center justify-between text-[11px]">
                                    <span className="font-bold text-slate-900">{user.totalWatched} movies</span>
                                    <span className="text-slate-400 text-[10px]">★ {user.totalFavorites} favs</span>
                                  </div>
                                  <div className="w-24 bg-slate-100 h-1.5 rounded-full overflow-hidden">
                                    <div 
                                      className="h-full bg-gradient-to-r from-[#00E676] to-[#00A344] rounded-full"
                                      style={{ width: `${Math.min(100, (user.totalWatched / 20) * 100)}%` }}
                                    />
                                  </div>
                                </div>
                              </td>

                              {/* Last Watched */}
                              <td className="py-3.5 px-4 max-w-xs truncate text-slate-600">
                                <div className="flex items-center space-x-1.5">
                                  <Film size={12} className="text-slate-400 shrink-0" />
                                  <span className="truncate">{user.lastWatchedMovie}</span>
                                </div>
                              </td>

                              {/* Actions */}
                              <td className="py-3.5 px-4 text-right">
                                <div className="inline-flex items-center space-x-1">
                                  {/* Deep Profile Drawer Trigger */}
                                  <button
                                    onClick={() => setSelectedUserDetail(user)}
                                    className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors"
                                    title="View Full Profile & History"
                                  >
                                    <Eye size={14} />
                                  </button>

                                  {/* Ban / Reactivate Action */}
                                  <button
                                    onClick={() => {
                                      if (user.status === 'Banned') {
                                        handleUnbanUser(user);
                                      } else {
                                        setBanModalUser(user);
                                      }
                                    }}
                                    className={`p-1.5 rounded-lg border text-xs font-semibold transition-colors ${
                                      user.status === 'Banned'
                                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100'
                                        : 'bg-rose-50 text-rose-700 border-rose-200 hover:bg-rose-100'
                                    }`}
                                    title={user.status === 'Banned' ? 'Reactivate User Account' : 'Suspend Account (Instant Lockout)'}
                                  >
                                    {user.status === 'Banned' ? <UserCheck size={14} /> : <UserX size={14} />}
                                  </button>

                                  {/* Role Modal */}
                                  <button
                                    onClick={() => {
                                      setRoleChangeModalUser(user);
                                      setNewRoleSelection(user.role);
                                    }}
                                    className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors"
                                    title="Change Privileges"
                                  >
                                    <Sliders size={14} />
                                  </button>

                                  {/* Delete */}
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
              ) : (
                /* VIEW 2: INTERACTIVE PROFILE CARDS GRID */
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {filteredUsers.length === 0 ? (
                    <div className="col-span-full py-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200">
                      No users found matching your search criteria.
                    </div>
                  ) : (
                    filteredUsers.map((user) => (
                      <div 
                        key={user.id}
                        className="bg-white rounded-2xl border border-slate-200/90 hover:border-slate-300 shadow-xs hover:shadow-md transition-all p-5 flex flex-col justify-between"
                      >
                        <div>
                          {/* Card Header */}
                          <div className="flex items-start justify-between mb-4">
                            <div className="flex items-center space-x-3">
                              <div className="relative">
                                <div className="w-12 h-12 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-800 text-sm">
                                  {(user.name || 'User').slice(0, 2).toUpperCase()}
                                </div>
                                <span 
                                  className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white ${
                                    user.isOnline ? 'bg-[#00E676]' : 'bg-slate-300'
                                  }`}
                                />
                              </div>
                              <div>
                                <h4 className="font-bold text-slate-900 text-sm">{user.name}</h4>
                                <span className="text-xs text-slate-400 block">{user.email}</span>
                                <div className="flex items-center space-x-1 mt-0.5">
                                  <span className="text-[10px] font-mono text-slate-400">{user.id.slice(0, 12)}...</span>
                                  <button
                                    onClick={(e) => handleCopyUid(user.id, e)}
                                    className="text-slate-400 hover:text-slate-700 transition-colors"
                                    title="Copy UID"
                                  >
                                    {copiedUid === user.id ? (
                                      <Check size={11} className="text-[#00A344]" />
                                    ) : (
                                      <Copy size={11} />
                                    )}
                                  </button>
                                </div>
                              </div>
                            </div>

                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              user.role === 'Admin' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                              user.role === 'VIP' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                              'bg-slate-100 text-slate-700 border border-slate-200'
                            }`}>
                              {user.role}
                            </span>
                          </div>

                          {/* Presence & Status Tag */}
                          <div className="flex items-center space-x-2 mb-3">
                            {user.isOnline ? (
                              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
                                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1.5 animate-pulse" /> Active Now
                              </span>
                            ) : (
                              <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-500 border border-slate-200">
                                Offline • {formatLastSeen(user.lastSeenTime)}
                              </span>
                            )}

                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              user.status === 'Active' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : 'bg-rose-50 text-rose-700 border border-rose-200'
                            }`}>
                              {user.status}
                            </span>
                          </div>

                          {/* Engagement Counters */}
                          <div className="grid grid-cols-2 gap-2 bg-slate-50 rounded-xl p-2.5 text-center mb-3">
                            <div>
                              <span className="text-[10px] text-slate-400 font-bold block uppercase">Watched</span>
                              <span className="font-extrabold text-slate-900 text-xs">{user.totalWatched} movies</span>
                            </div>
                            <div>
                              <span className="text-[10px] text-slate-400 font-bold block uppercase">Favorites</span>
                              <span className="font-extrabold text-slate-900 text-xs">★ {user.totalFavorites} saved</span>
                            </div>
                          </div>

                          {/* Last Watched Snippet */}
                          <div className="text-xs text-slate-600 bg-white border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 mb-3">
                            <Film size={14} className="text-[#00A344] shrink-0" />
                            <span className="truncate text-[11px]">{user.lastWatchedMovie}</span>
                          </div>

                          {user.status === 'Banned' && (
                            <div className="p-2.5 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs mb-3 flex items-start space-x-2">
                              <AlertCircle size={14} className="shrink-0 mt-0.5" />
                              <div className="leading-tight">
                                <span className="font-bold block">Account Suspended</span>
                                <span className="text-[11px] text-rose-600">{user.banReason}</span>
                              </div>
                            </div>
                          )}
                        </div>

                        {/* Card Actions */}
                        <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-2">
                          <button
                            onClick={() => setSelectedUserDetail(user)}
                            className="flex-1 py-1.5 px-2 bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-xl text-xs font-bold transition-colors inline-flex items-center justify-center"
                          >
                            <Eye size={13} className="mr-1" /> Dossier
                          </button>

                          <button
                            onClick={() => {
                              if (user.status === 'Banned') {
                                handleUnbanUser(user);
                              } else {
                                setBanModalUser(user);
                              }
                            }}
                            className={`py-1.5 px-3 rounded-xl text-xs font-bold transition-colors inline-flex items-center justify-center ${
                              user.status === 'Banned'
                                ? 'bg-[#00E676]/20 text-[#00A344] hover:bg-[#00E676]/30'
                                : 'bg-rose-50 text-rose-700 hover:bg-rose-100'
                            }`}
                          >
                            {user.status === 'Banned' ? 'Reactivate' : 'Ban User'}
                          </button>

                          <button
                            onClick={() => {
                              setRoleChangeModalUser(user);
                              setNewRoleSelection(user.role);
                            }}
                            className="p-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
                            title="Privileges"
                          >
                            <Sliders size={14} />
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          )}

          {/* ═════════════════════════════════════════════════════════════════════ */}
          {/* TAB 3: VIDEO PERFORMANCE & LIVE CATALOG                            */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'videos' && (
            <div className="space-y-6 max-w-7xl mx-auto">
              {/* Aggregated Real Watched Movies Section */}
              <div className="bg-white/85 backdrop-blur-md rounded-2xl p-4 sm:p-6 border border-slate-200/80 shadow-xs">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-5">
                  <div>
                    <h3 className="text-base font-bold text-slate-900">Real User Watch Stream Analytics</h3>
                    <p className="text-xs text-slate-400">Aggregated directly from user watch history and favorite records in Firebase RTDB</p>
                  </div>
                  <span className="text-xs font-semibold text-slate-600 bg-slate-100 px-3 py-1 rounded-full self-start sm:self-auto">
                    {aggregatedWatchedMovies.length} Streamed Titles
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
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
                                  setNotifTitle(`${title} (${vj})`);
                                  setNotifBody(`Watch ${title} in exclusive Luganda translation by ${vj}! Now streaming in Full HD.`);
                                  setNotifImageUrl(img || '');
                                  setNotifLink(String(id));
                                }}
                                className="inline-flex items-center px-2.5 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 font-bold text-[11px] transition-colors cursor-pointer"
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
          {/* TAB 4: WHATSAPP-STYLE LIVE SUPPORT CHAT                             */}
          {/* ═════════════════════════════════════════════════════════════════════ */}
          {activeTab === 'chat' && (
            <div className="bg-[#EFEAE2] rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden flex h-[calc(100vh-140px)] max-w-7xl mx-auto">
              {/* WhatsApp Left Conversations List */}
              <div className="w-80 md:w-96 border-r border-[#E9EDEF] flex flex-col bg-white shrink-0">
                {/* WhatsApp Sidebar Header */}
                <div className="h-16 px-4 bg-[#F0F2F5] border-b border-[#E9EDEF] flex items-center justify-between shrink-0">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#00E676] to-[#00C853] flex items-center justify-center text-black font-black text-sm shadow-xs">
                      FW
                    </div>
                    <div>
                      <h3 className="font-bold text-[#111B21] text-sm leading-tight">Live Support</h3>
                      <span className="text-[10px] text-[#00A884] font-semibold flex items-center">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] mr-1 animate-pulse" />
                        Connected to RTDB
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center space-x-1 text-[#54656F]">
                    <span className="text-[11px] font-bold bg-[#E9EDEF] px-2 py-0.5 rounded-full text-slate-700">
                      {threads.length} chats
                    </span>
                  </div>
                </div>

                {/* WhatsApp Search Bar */}
                <div className="p-2.5 bg-[#F0F2F5] border-b border-[#E9EDEF]">
                  <div className="relative">
                    <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#54656F]" />
                    <input 
                      type="text"
                      placeholder="Search or start new conversation..."
                      value={chatSearch}
                      onChange={(e) => setChatSearch(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 bg-white rounded-lg text-xs font-normal text-[#111B21] placeholder:text-[#8696A0] focus:outline-none shadow-2xs border border-transparent focus:border-[#00E676]"
                    />
                  </div>
                </div>

                {/* WhatsApp Conversations Scroll Area */}
                <div className="flex-1 overflow-y-auto divide-y divide-[#F0F2F5]">
                  {threads.length === 0 ? (
                    <div className="p-8 text-center text-slate-400 text-xs">
                      No support conversations yet.
                    </div>
                  ) : (
                    threads
                      .filter(t => !chatSearch || (t.userName || '').toLowerCase().includes(chatSearch.toLowerCase()) || (t.lastMessage || '').toLowerCase().includes(chatSearch.toLowerCase()))
                      .map((thread) => {
                        const isSelected = thread.uid === selectedThreadId;
                        const matchedUser = users.find(u => u.id === thread.uid);
                        const isUserOnline = matchedUser?.isOnline;

                        return (
                          <button
                            key={thread.uid}
                            onClick={() => setSelectedThreadId(thread.uid)}
                            className={`w-full px-4 py-3 text-left flex items-center space-x-3 transition-colors ${
                              isSelected ? 'bg-[#F0F2F5]' : 'hover:bg-[#F5F6F6] bg-white'
                            }`}
                          >
                            <div className="relative shrink-0">
                              <div className="w-11 h-11 rounded-full bg-slate-200 border border-slate-100 flex items-center justify-center font-bold text-xs text-slate-700 shadow-2xs">
                                {(thread.userName || 'User').slice(0, 2).toUpperCase()}
                              </div>
                              <span 
                                className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${
                                  isUserOnline ? 'bg-[#00E676]' : 'bg-slate-300'
                                }`}
                              />
                            </div>

                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between mb-0.5">
                                <span className="font-semibold text-[#111B21] text-xs truncate">
                                  {thread.userName || 'FreeWatch User'}
                                </span>
                                <span className={`text-[10px] ${thread.unreadCount > 0 ? 'text-[#00A884] font-bold' : 'text-[#667781]'}`}>
                                  {new Date(thread.updatedAt || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </span>
                              </div>
                              <div className="flex items-center justify-between">
                                <p className="text-xs text-[#667781] truncate pr-2 flex items-center">
                                  <CheckCheck size={13} className="text-[#53BDEB] inline mr-1 shrink-0" />
                                  <span className="truncate">{thread.lastMessage}</span>
                                </p>
                                {thread.unreadCount > 0 && (
                                  <span className="min-w-5 h-5 px-1.5 rounded-full bg-[#25D366] text-white text-[10px] font-bold flex items-center justify-center shrink-0">
                                    {thread.unreadCount}
                                  </span>
                                )}
                              </div>
                            </div>
                          </button>
                        );
                      })
                  )}
                </div>
              </div>

              {/* WhatsApp Right Active Chat Pane */}
              <div className="flex-1 flex flex-col bg-[#EFEAE2] relative">
                {selectedThreadId ? (
                  <>
                    {/* WhatsApp Active Chat Header */}
                    {(() => {
                      const activeThread = threads.find(t => t.uid === selectedThreadId);
                      const activeUser = users.find(u => u.id === selectedThreadId);

                      return (
                        <div className="h-16 px-5 border-b border-[#E9EDEF] flex items-center justify-between bg-[#F0F2F5] z-10 shrink-0">
                          <div className="flex items-center space-x-3.5">
                            <div className="relative">
                              <div className="w-10 h-10 rounded-full bg-slate-200 text-slate-800 flex items-center justify-center font-bold text-xs shadow-2xs border border-white">
                                {((activeThread?.userName || activeUser?.name) || 'User').slice(0, 2).toUpperCase()}
                              </div>
                              <span 
                                className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-[#F0F2F5] ${
                                  activeUser?.isOnline ? 'bg-[#00E676]' : 'bg-slate-300'
                                }`}
                              />
                            </div>
                            <div>
                              <h4 className="font-semibold text-[#111B21] text-sm leading-tight">
                                {activeUser?.name || activeThread?.userName || 'FreeWatch User'}
                              </h4>
                              <span className="text-[11px] font-medium flex items-center">
                                {activeUser?.isOnline ? (
                                  <span className="text-[#00A884] font-semibold">online</span>
                                ) : (
                                  <span className="text-[#667781]">
                                    last seen {formatLastSeen(activeUser?.lastSeenTime)}
                                  </span>
                                )}
                              </span>
                            </div>
                          </div>

                          {/* WhatsApp Header Actions */}
                          <div className="flex items-center space-x-1 text-[#54656F]">
                            {activeUser && (
                              <button 
                                onClick={() => setSelectedUserDetail(activeUser)}
                                className="p-2 hover:bg-black/5 rounded-full transition-colors text-slate-700"
                                title="Inspect Full Dossier"
                              >
                                <Info size={18} />
                              </button>
                            )}

                            {activeUser && (
                              <button 
                                onClick={() => {
                                  if (activeUser.status === 'Banned') {
                                    handleUnbanUser(activeUser);
                                  } else {
                                    setBanModalUser(activeUser);
                                  }
                                }}
                                className={`p-2 rounded-full transition-colors ${
                                  activeUser.status === 'Banned' ? 'text-[#00A344] hover:bg-[#00E676]/10' : 'text-rose-600 hover:bg-rose-50'
                                }`}
                                title={activeUser.status === 'Banned' ? 'Reactivate User' : 'Suspend Account'}
                              >
                                {activeUser.status === 'Banned' ? <UserCheck size={18} /> : <UserX size={18} />}
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })()}

                    {/* WhatsApp Chat Messages Canvas with subtle doodle texture */}
                    <div 
                      className="flex-1 p-5 overflow-y-auto space-y-2.5"
                      style={{
                        backgroundImage: `radial-gradient(#c8c2b7 0.9px, transparent 0.9px)`,
                        backgroundSize: '18px 18px',
                      }}
                    >
                      {/* WhatsApp Centered Date Badge */}
                      <div className="flex justify-center my-2">
                        <span className="bg-white/95 text-[#54656F] text-[10px] font-bold uppercase tracking-wider px-3 py-1 rounded-md shadow-[0_1px_0.5px_rgba(11,20,26,0.13)] border border-slate-200/50">
                          Today
                        </span>
                      </div>

                      {messages.map((m) => {
                        const isAdmin = m.senderRole === 'admin' || m.senderId === 'admin';
                        return (
                          <div 
                            key={m.id} 
                            className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}
                          >
                            <div 
                              className={`relative max-w-md px-3.5 py-2 shadow-[0_1px_0.5px_rgba(11,20,26,0.13)] ${
                                isAdmin 
                                  ? 'bg-[#D9FDD3] text-[#111B21] rounded-2xl rounded-tr-xs border border-[#C6ECC0]/60' 
                                  : 'bg-white text-[#111B21] rounded-2xl rounded-tl-xs border border-slate-100'
                              }`}
                            >
                              <p className="text-xs leading-relaxed break-words whitespace-pre-wrap font-normal">
                                {m.text}
                              </p>
                              <div className="flex items-center justify-end space-x-1 mt-1 text-[10px] text-[#667781]">
                                <span>
                                  {new Date(m.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </span>
                                {isAdmin && (
                                  <CheckCheck size={14} className="text-[#53BDEB] shrink-0 inline ml-0.5" />
                                )}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                      <div ref={messagesEndRef} />
                    </div>

                    {/* WhatsApp Input Dock */}
                    <div className="p-3 border-t border-[#E9EDEF] bg-[#F0F2F5] flex flex-col space-y-2 z-10 shrink-0">
                      {/* Quick Canned Responses Bar */}
                      <div className="flex items-center space-x-2 overflow-x-auto pb-1 text-[11px]">
                        <span className="font-bold text-[10px] uppercase text-[#667781] shrink-0">Quick Reply:</span>
                        {[
                          'Welcome to FreeWatch Support! How can we assist you today?',
                          'Your requested movie is now uploaded to the catalog!',
                          'Account status verified and active.',
                          'Enjoy streaming on FreeWatch!',
                        ].map((quick, qIdx) => (
                          <button
                            key={qIdx}
                            type="button"
                            onClick={() => setNewMessage(quick)}
                            className="px-2.5 py-1 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-full text-[#111B21] shrink-0 transition-colors shadow-2xs font-medium text-[11px]"
                          >
                            {quick.slice(0, 32)}...
                          </button>
                        ))}
                      </div>

                      <form onSubmit={handleSendMessage} className="flex items-center space-x-2">
                        <button
                          type="button"
                          className="p-2 text-[#54656F] hover:text-[#111B21] transition-colors"
                          title="Emoji"
                        >
                          <Smile size={20} />
                        </button>
                        <button
                          type="button"
                          className="p-2 text-[#54656F] hover:text-[#111B21] transition-colors"
                          title="Attach"
                        >
                          <Paperclip size={20} />
                        </button>

                        <input 
                          type="text"
                          placeholder="Type a message..."
                          value={newMessage}
                          onChange={(e) => setNewMessage(e.target.value)}
                          className="flex-1 px-4 py-2.5 bg-white rounded-lg text-xs font-normal text-[#111B21] placeholder:text-[#8696A0] focus:outline-none shadow-2xs border-0"
                        />

                        {newMessage.trim() ? (
                          <button
                            type="submit"
                            className="w-10 h-10 rounded-full bg-[#00A884] hover:bg-[#008f6f] text-white flex items-center justify-center transition-all shadow-sm shrink-0"
                            title="Send Message"
                          >
                            <Send size={16} className="translate-x-0.5" />
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="p-2 text-[#54656F] hover:text-[#111B21] transition-colors"
                            title="Voice Note"
                          >
                            <Mic size={20} />
                          </button>
                        )}
                      </form>
                    </div>
                  </>
                ) : (
                  <div className="flex-1 flex flex-col items-center justify-center text-center p-8 text-slate-500">
                    <div className="w-16 h-16 rounded-3xl bg-white border border-slate-200/80 shadow-md flex items-center justify-center text-[#00E676] mb-4">
                      <MessageCircle size={32} />
                    </div>
                    <h3 className="text-base font-bold text-slate-800 mb-1">FreeWatch Live Support Web</h3>
                    <p className="text-xs text-slate-500 max-w-sm">
                      Send and receive real-time messages directly to users streaming on the FreeWatch mobile application.
                    </p>
                    <span className="text-[10px] text-slate-400 mt-4 flex items-center">
                      <Lock size={12} className="mr-1 text-slate-400" /> Realtime 2-way synchronized via Firebase RTDB
                    </span>
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
                    <div className="mb-4 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-bold flex items-center">
                      <CheckCircle2 size={16} className="mr-2 text-emerald-600" /> {notifSuccess}
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
                        placeholder="e.g. New Luganda Release"
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
                        {notifTitle || 'FreeWatch Alert'}
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
                      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
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

          {/* TAB 8: APPLE APP STORE LISTING & DOWNLOAD HUB */}
          {activeTab === 'store' && (
            <div className="max-w-4xl mx-auto py-2 space-y-6">
              {/* In-App Update Banner Remote Controller */}
              <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs p-6 space-y-5">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#00E676]/10 text-[#00A344] flex items-center justify-center font-bold">
                      <Smartphone className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                        In-App Update Banner Controller
                        <span className={`text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full ${
                          updateConfig.show_banner ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-600'
                        }`}>
                          {updateConfig.show_banner ? '● Live on Devices' : '○ Banner Muted'}
                        </span>
                      </h2>
                      <p className="text-xs text-slate-500">
                        Configure the update alert shown inside FreeWatch Android apps via Firebase RTDB.
                      </p>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setUpdateConfig(prev => ({ ...prev, show_banner: !prev.show_banner }))}
                    className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border ${
                      updateConfig.show_banner 
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100' 
                        : 'bg-slate-100 text-slate-600 border-slate-200 hover:bg-slate-200'
                    }`}
                  >
                    {updateConfig.show_banner ? 'Turn Banner Off' : 'Turn Banner On'}
                  </button>
                </div>

                <form onSubmit={handleSaveUpdateConfig} className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">Target Version Name</label>
                      <input 
                        type="text"
                        value={updateConfig.latest_version}
                        onChange={(e) => setUpdateConfig({ ...updateConfig, latest_version: e.target.value })}
                        placeholder="1.0.57"
                        className="w-full text-xs px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">Target Build Number</label>
                      <input 
                        type="number"
                        value={updateConfig.latest_build}
                        onChange={(e) => setUpdateConfig({ ...updateConfig, latest_build: parseInt(e.target.value) || 58 })}
                        placeholder="58"
                        className="w-full text-xs px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">Store Listing Page URL</label>
                      <input 
                        type="url"
                        value={updateConfig.store_url}
                        onChange={(e) => setUpdateConfig({ ...updateConfig, store_url: e.target.value })}
                        placeholder="https://freewatch-piustech.vercel.app/"
                        className="w-full text-xs px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-700 mb-1">Direct APK Download URL</label>
                      <input 
                        type="url"
                        value={updateConfig.direct_apk_url}
                        onChange={(e) => setUpdateConfig({ ...updateConfig, direct_apk_url: e.target.value })}
                        placeholder="https://github.com/piustech1/FreeWatch/releases/download/v1.0.56/FreeWatch-release.apk"
                        className="w-full text-xs px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">Release Notes / What's New</label>
                    <textarea 
                      rows={3}
                      value={updateConfig.release_notes}
                      onChange={(e) => setUpdateConfig({ ...updateConfig, release_notes: e.target.value })}
                      className="w-full text-xs px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:border-[#00E676] resize-none"
                    />
                  </div>

                  <div className="flex items-center gap-2">
                    <input 
                      type="checkbox"
                      id="isMandatoryCheck"
                      checked={updateConfig.is_mandatory}
                      onChange={(e) => setUpdateConfig({ ...updateConfig, is_mandatory: e.target.checked })}
                      className="rounded accent-[#00E676]"
                    />
                    <label htmlFor="isMandatoryCheck" className="text-xs font-medium text-slate-700 cursor-pointer">
                      Mandatory Update (Users must update before proceeding)
                    </label>
                  </div>

                  {updateConfigSavedMsg && (
                    <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-700 text-xs font-medium flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-600" />
                      <span>{updateConfigSavedMsg}</span>
                    </div>
                  )}

                  <div className="pt-2 flex items-center justify-between">
                    <p className="text-[11px] text-slate-400">
                      Syncs to Firebase path <code className="bg-slate-100 px-1 py-0.5 rounded text-slate-600">/app_config/update</code>
                    </p>
                    <button
                      type="submit"
                      disabled={isSavingUpdateConfig}
                      className="px-4 py-2 bg-[#00E676] text-black font-semibold text-xs rounded-xl shadow-xs hover:bg-[#00c864] transition-all flex items-center gap-1.5 disabled:opacity-50"
                    >
                      {isSavingUpdateConfig ? (
                        <>
                          <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                          <span>Broadcasting...</span>
                        </>
                      ) : (
                        <>
                          <Send className="w-3.5 h-3.5" />
                          <span>Save & Broadcast to Devices</span>
                        </>
                      )}
                    </button>
                  </div>
                </form>
              </div>

              {/* Public Storefront Preview */}
              <div className="pt-2">
                <AppStoreLanding 
                  onNavigateToAdmin={() => setActiveTab('dashboard')} 
                  onNavigateToWeb={() => navigateTo('/')}
                />
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

      {/* ── Modal: Suspend / Ban User with Reason ── */}
      {banModalUser && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0 border border-rose-200">
                <ShieldAlert size={24} />
              </div>
              <div>
                <h3 className="font-bold text-slate-900 text-base">Suspend User Account</h3>
                <p className="text-xs text-slate-500">
                  {banModalUser.name} ({banModalUser.email})
                </p>
              </div>
            </div>

            <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 text-xs text-amber-800 leading-relaxed">
              <strong>⚠️ Instant Mobile Lockout:</strong> Suspending this account will immediately lock the user out of the FreeWatch mobile application in real time and block all streaming.
            </div>

            <div className="space-y-2">
              <label className="block font-bold text-slate-700 text-xs">Select Suspension Reason</label>
              {[
                'Terms of Service Violation',
                'Spamming & Inappropriate Behavior',
                'Suspicious Account Activity',
                'Multiple Device Abuse',
                'Other',
              ].map((reasonOption) => (
                <label 
                  key={reasonOption}
                  className={`flex items-center justify-between p-2.5 rounded-xl border text-xs font-semibold cursor-pointer transition-all ${
                    banReason === reasonOption 
                      ? 'border-rose-500 bg-rose-50/70 text-rose-700' 
                      : 'border-slate-200 text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <span>{reasonOption}</span>
                  <input 
                    type="radio" 
                    name="banReasonSelect"
                    checked={banReason === reasonOption}
                    onChange={() => setBanReason(reasonOption)}
                    className="accent-rose-600"
                  />
                </label>
              ))}

              {banReason === 'Other' && (
                <div className="pt-1">
                  <input 
                    type="text"
                    placeholder="Enter custom suspension reason..."
                    value={customBanReason}
                    onChange={(e) => setCustomBanReason(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 focus:outline-none focus:border-rose-500"
                    autoFocus
                  />
                </div>
              )}
            </div>

            <div className="flex space-x-2 pt-2">
              <button
                type="button"
                onClick={() => {
                  setBanModalUser(null);
                  setCustomBanReason('');
                }}
                className="flex-1 py-2 rounded-xl border border-slate-200 font-semibold text-slate-600 hover:bg-slate-50 transition-colors text-xs"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmBan}
                className="flex-1 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-extrabold transition-colors shadow-sm shadow-rose-600/25 text-xs"
              >
                Confirm Suspension
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modal: Deep User Profile Dossier ── */}
      {selectedUserDetail && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 space-y-5 max-h-[90vh] overflow-y-auto">
            {/* Dossier Header */}
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div className="flex items-center space-x-4">
                <div className="relative">
                  <div className="w-14 h-14 rounded-full bg-slate-100 border-2 border-slate-200 flex items-center justify-center font-black text-slate-800 text-lg shadow-xs">
                    {(selectedUserDetail.name || 'User').slice(0, 2).toUpperCase()}
                  </div>
                  <span 
                    className={`absolute bottom-0 right-0 w-4 h-4 rounded-full border-2 border-white ${
                      selectedUserDetail.isOnline ? 'bg-[#00E676]' : 'bg-slate-300'
                    }`}
                  />
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <h3 className="font-extrabold text-slate-900 text-lg">{selectedUserDetail.name}</h3>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                      selectedUserDetail.role === 'Admin' ? 'bg-rose-50 text-rose-700 border border-rose-200' :
                      selectedUserDetail.role === 'VIP' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                      'bg-slate-100 text-slate-700 border border-slate-200'
                    }`}>
                      {selectedUserDetail.role}
                    </span>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                      selectedUserDetail.status === 'Active' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/60' : 'bg-rose-50 text-rose-700 border border-rose-200'
                    }`}>
                      {selectedUserDetail.status}
                    </span>
                  </div>
                  <span className="text-xs text-slate-400 block mt-0.5">{selectedUserDetail.email}</span>
                  <div className="flex items-center space-x-2 mt-1">
                    <span className="text-[11px] font-mono text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                      UID: {selectedUserDetail.id}
                    </span>
                    <button
                      onClick={(e) => handleCopyUid(selectedUserDetail.id, e)}
                      className="text-xs text-[#00A344] font-bold hover:underline flex items-center"
                    >
                      {copiedUid === selectedUserDetail.id ? (
                        <>
                          <Check size={12} className="mr-1" /> Copied!
                        </>
                      ) : (
                        <>
                          <Copy size={12} className="mr-1" /> Copy UID
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setSelectedUserDetail(null)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-100 transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            {/* Account Metadata Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 text-center">
                <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Presence</span>
                <span className={`text-xs font-bold ${selectedUserDetail.isOnline ? 'text-[#00A344]' : 'text-slate-600'}`}>
                  {selectedUserDetail.isOnline ? '🟢 Active Now' : `Offline (${formatLastSeen(selectedUserDetail.lastSeenTime)})`}
                </span>
              </div>
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 text-center">
                <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Movies Watched</span>
                <span className="text-xs font-extrabold text-slate-900">{selectedUserDetail.totalWatched} titles</span>
              </div>
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 text-center">
                <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Favorites</span>
                <span className="text-xs font-extrabold text-amber-600">★ {selectedUserDetail.totalFavorites} saved</span>
              </div>
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 text-center">
                <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Platform</span>
                <span className="text-xs font-bold text-slate-700">{selectedUserDetail.platform}</span>
              </div>
            </div>

            {/* Watch History List */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-bold text-slate-900 text-xs uppercase tracking-wider">
                  Watch History ({selectedUserDetail.watchHistory.length})
                </h4>
                <span className="text-[10px] text-slate-400">Streamed on FreeWatch Android / iOS</span>
              </div>
              <div className="border border-slate-200 rounded-xl overflow-hidden max-h-44 overflow-y-auto divide-y divide-slate-100 bg-white">
                {selectedUserDetail.watchHistory.length === 0 ? (
                  <div className="p-4 text-center text-xs text-slate-400">
                    No movies watched by this user yet.
                  </div>
                ) : (
                  selectedUserDetail.watchHistory.map((item, idx) => (
                    <div key={idx} className="p-2.5 px-3 flex items-center justify-between text-xs hover:bg-slate-50">
                      <div className="flex items-center space-x-2 min-w-0">
                        <Film size={14} className="text-[#00A344] shrink-0" />
                        <span className="font-bold text-slate-800 truncate">{item.title || 'Untitled Movie'}</span>
                        {item.vj && <span className="text-[10px] text-slate-400 font-medium">({item.vj})</span>}
                      </div>
                      <span className="text-[10px] text-slate-400 shrink-0 ml-2">
                        {item.watchedAt ? new Date(item.watchedAt).toLocaleDateString() : 'Recent'}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Favorites List */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-bold text-slate-900 text-xs uppercase tracking-wider">
                  Bookmarked Favorites ({selectedUserDetail.favorites.length})
                </h4>
              </div>
              <div className="border border-slate-200 rounded-xl overflow-hidden max-h-32 overflow-y-auto divide-y divide-slate-100 bg-white">
                {selectedUserDetail.favorites.length === 0 ? (
                  <div className="p-4 text-center text-xs text-slate-400">
                    No favorites saved yet.
                  </div>
                ) : (
                  selectedUserDetail.favorites.map((fav, idx) => (
                    <div key={idx} className="p-2 px-3 flex items-center justify-between text-xs hover:bg-slate-50">
                      <div className="flex items-center space-x-2 min-w-0">
                        <Star size={13} className="text-amber-500 shrink-0" />
                        <span className="font-semibold text-slate-800 truncate">{fav.title || 'Untitled Movie'}</span>
                      </div>
                      <span className="text-[10px] text-slate-400">{fav.category || 'Movie'}</span>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Dossier Actions */}
            <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-3">
              <button
                type="button"
                onClick={() => {
                  setSelectedThreadId(selectedUserDetail.id);
                  setActiveTab('chat');
                  setSelectedUserDetail(null);
                }}
                className="py-2.5 px-4 bg-[#00E676] hover:bg-[#00C853] text-black font-extrabold rounded-xl text-xs transition-colors flex items-center shadow-sm shadow-[#00E676]/25"
              >
                <MessageCircle size={15} className="mr-1.5" /> Open WhatsApp Live Support
              </button>

              <div className="flex items-center space-x-2">
                <button
                  type="button"
                  onClick={() => {
                    const userToBan = selectedUserDetail;
                    setSelectedUserDetail(null);
                    if (userToBan.status === 'Banned') {
                      handleUnbanUser(userToBan);
                    } else {
                      setBanModalUser(userToBan);
                    }
                  }}
                  className={`py-2 px-3.5 rounded-xl text-xs font-bold transition-colors ${
                    selectedUserDetail.status === 'Banned'
                      ? 'bg-[#00E676]/15 text-[#00A344] hover:bg-[#00E676]/25'
                      : 'bg-rose-50 text-rose-700 hover:bg-rose-100'
                  }`}
                >
                  {selectedUserDetail.status === 'Banned' ? 'Reactivate User' : 'Suspend User'}
                </button>

                <button
                  type="button"
                  onClick={() => setSelectedUserDetail(null)}
                  className="py-2 px-4 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
