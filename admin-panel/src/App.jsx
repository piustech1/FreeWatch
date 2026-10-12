import React, { useState, useEffect, useRef } from 'react';
import { 
  MessageSquare, 
  Bell, 
  Film, 
  Send, 
  Search, 
  Users, 
  CheckCircle2, 
  Clock, 
  Smartphone, 
  Sparkles, 
  ExternalLink,
  ShieldCheck,
  RefreshCw,
  Flame,
  Radio
} from 'lucide-react';
import { rtdb } from './firebase';
import { ref, onValue, push, set, update, serverTimestamp } from 'firebase/database';

export default function App() {
  const [activeTab, setActiveTab] = useState('chat'); // 'chat' | 'notifications' | 'catalog'
  const [threads, setThreads] = useState([]);
  const [selectedThreadId, setSelectedThreadId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [dbConnected, setDbConnected] = useState(true);

  // Push notification state
  const [notifTarget, setNotifTarget] = useState('all_users');
  const [notifTitle, setNotifTitle] = useState('🔥 New Luganda VJ Release!');
  const [notifBody, setNotifBody] = useState('New translated blockbuster is now streaming in Full HD! Tap to watch now.');
  const [notifImageUrl, setNotifImageUrl] = useState('');
  const [notifMovieId, setNotifMovieId] = useState('');
  const [dispatchedNotifs, setDispatchedNotifs] = useState([]);
  const [isSendingNotif, setIsSendingNotif] = useState(false);
  const [notifSuccess, setNotifSuccess] = useState('');

  const messagesEndRef = useRef(null);

  // Listen for Support Chats
  useEffect(() => {
    const chatsRef = ref(rtdb, 'support_chats');
    const unsubscribe = onValue(chatsRef, (snapshot) => {
      const data = snapshot.val();
      if (!data) {
        setThreads([]);
        return;
      }

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

      // Sort by newest activity first
      parsedThreads.sort((a, b) => b.lastTimestamp - a.lastTimestamp);
      setThreads(parsedThreads);

      // Auto-select first thread if none selected
      if (!selectedThreadId && parsedThreads.length > 0) {
        setSelectedThreadId(parsedThreads[0].id);
      }
    }, (error) => {
      console.error("Firebase RTDB error:", error);
      setDbConnected(false);
    });

    return () => unsubscribe();
  }, [selectedThreadId]);

  // Listen to messages for active selected thread
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

      const list = Object.keys(data).map(k => ({
        id: k,
        ...data[k]
      }));
      list.sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
      setMessages(list);

      // Clear admin unread count when reading
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
      const list = Object.keys(data).map(k => ({ id: k, ...data[k] }));
      list.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));
      setDispatchedNotifs(list);
    });
    return () => unsubscribe();
  }, []);

  // Auto scroll chat to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

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

      // Update thread metadata
      const metaRef = ref(rtdb, `support_chats/${selectedThreadId}/metadata`);
      await update(metaRef, {
        lastMessage: text,
        lastTimestamp: now,
        unreadCountUser: 1,
        updatedAt: now
      });
    } catch (err) {
      console.error("Failed to send message:", err);
      alert("Error sending message: " + err.message);
    }
  };

  const handleSendPushNotification = async (e) => {
    e.preventDefault();
    if (!notifTitle.trim() || !notifBody.trim()) return;

    setIsSendingNotif(true);
    setNotifSuccess('');

    try {
      const historyRef = ref(rtdb, 'push_notifications/history');
      const newPushRef = push(historyRef);
      const pushRecord = {
        id: newPushRef.key,
        targetTopic: notifTarget,
        title: notifTitle,
        body: notifBody,
        imageUrl: notifImageUrl || null,
        movieId: notifMovieId || null,
        timestamp: Date.now(),
        dispatchedBy: 'Admin Web Console'
      };

      await set(newPushRef, pushRecord);

      // Also post to real-time alerts queue for mobile tracker
      const alertsRef = ref(rtdb, 'global_alerts/latest');
      await set(alertsRef, {
        ...pushRecord,
        active: true
      });

      setNotifSuccess(`Notification dispatched successfully to topic '${notifTarget}'!`);
      setTimeout(() => setNotifSuccess(''), 5000);
    } catch (err) {
      console.error("Failed to send push notification:", err);
      alert("Failed to send notification: " + err.message);
    } finally {
      setIsSendingNotif(false);
    }
  };

  const filteredThreads = threads.filter(t => 
    t.userName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.userId.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.lastMessage.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const activeThread = threads.find(t => t.id === selectedThreadId);

  return (
    <div className="flex h-screen bg-[#0A0D14] text-slate-100 antialiased overflow-hidden select-none">
      
      {/* ── Left Global Navigation Rail ─────────────────────────────── */}
      <div className="w-20 bg-[#0E121B] border-r border-white/10 flex flex-col items-center py-6 justify-between flex-shrink-0 z-20">
        <div className="flex flex-col items-center space-y-8">
          {/* Logo */}
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-[#00E676] to-[#10B981] flex items-center justify-center shadow-lg shadow-[#00E676]/20 font-black text-black text-xl tracking-tighter">
            FW
          </div>

          {/* Navigation Items */}
          <div className="flex flex-col space-y-4">
            <button
              onClick={() => setActiveTab('chat')}
              className={`p-3.5 rounded-xl transition-all relative ${
                activeTab === 'chat'
                  ? 'bg-[#00E676]/15 text-[#00E676] shadow-sm'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
              title="Live User Chat"
            >
              <MessageSquare className="w-6 h-6" />
              {threads.reduce((acc, t) => acc + (t.unreadCountAdmin || 0), 0) > 0 && (
                <span className="absolute top-2 right-2 w-2.5 h-2.5 rounded-full bg-[#00E676] ring-2 ring-[#0E121B]" />
              )}
            </button>

            <button
              onClick={() => setActiveTab('notifications')}
              className={`p-3.5 rounded-xl transition-all ${
                activeTab === 'notifications'
                  ? 'bg-[#00E676]/15 text-[#00E676]'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
              title="Push Notification Dispatcher"
            >
              <Bell className="w-6 h-6" />
            </button>

            <button
              onClick={() => setActiveTab('catalog')}
              className={`p-3.5 rounded-xl transition-all ${
                activeTab === 'catalog'
                  ? 'bg-[#00E676]/15 text-[#00E676]'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`}
              title="Catalog & VJs"
            >
              <Film className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Firebase Live Indicator */}
        <div className="flex flex-col items-center space-y-2">
          <div 
            className={`w-3 h-3 rounded-full ${dbConnected ? 'bg-[#00E676] animate-pulse' : 'bg-rose-500'}`} 
            title={dbConnected ? 'Firebase Realtime Connected' : 'Disconnected'}
          />
          <span className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">v1.0.55</span>
        </div>
      </div>

      {/* ── Main Content Area ────────────────────────────────────────── */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* TAB 1: LIVE USER CHAT */}
        {activeTab === 'chat' && (
          <div className="flex-1 flex overflow-hidden">
            
            {/* Thread List Sidebar */}
            <div className="w-80 md:w-96 bg-[#111622] border-r border-white/10 flex flex-col flex-shrink-0">
              <div className="p-5 border-b border-white/10 flex flex-col space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <h2 className="text-lg font-extrabold text-white">Live Support</h2>
                    <span className="text-xs bg-[#00E676]/20 text-[#00E676] px-2 py-0.5 rounded-full font-bold">
                      {threads.length}
                    </span>
                  </div>
                  <div className="flex items-center space-x-1.5 text-xs text-slate-400">
                    <Radio className="w-3.5 h-3.5 text-[#00E676] animate-pulse" />
                    <span>Real-time</span>
                  </div>
                </div>

                {/* Search box */}
                <div className="relative">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    placeholder="Search by user or message..."
                    className="w-full bg-[#171D2B] border border-white/10 rounded-xl pl-9 pr-4 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-[#00E676]"
                  />
                </div>
              </div>

              {/* Threads Scroll List */}
              <div className="flex-1 overflow-y-auto divide-y divide-white/5">
                {filteredThreads.length === 0 ? (
                  <div className="p-8 text-center text-slate-500 text-sm">
                    No active user chats found.
                  </div>
                ) : (
                  filteredThreads.map((thread) => {
                    const isSelected = thread.id === selectedThreadId;
                    const dateStr = new Date(thread.lastTimestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                    
                    return (
                      <div
                        key={thread.id}
                        onClick={() => setSelectedThreadId(thread.id)}
                        className={`p-4 cursor-pointer transition-colors relative flex items-start space-x-3 ${
                          isSelected ? 'bg-[#00E676]/10 border-l-4 border-[#00E676]' : 'hover:bg-white/[0.03]'
                        }`}
                      >
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-slate-700 to-slate-900 border border-white/15 flex items-center justify-center font-bold text-sm text-slate-200 flex-shrink-0">
                          {thread.userName.charAt(0).toUpperCase()}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-sm font-bold text-white truncate">
                              {thread.userName}
                            </span>
                            <span className="text-[11px] text-slate-500 flex-shrink-0">
                              {dateStr}
                            </span>
                          </div>
                          <p className="text-xs text-slate-400 truncate">
                            {thread.lastMessage}
                          </p>
                        </div>

                        {thread.unreadCountAdmin > 0 && (
                          <span className="w-5 h-5 rounded-full bg-[#00E676] text-black text-[10px] font-black flex items-center justify-center flex-shrink-0">
                            {thread.unreadCountAdmin}
                          </span>
                        )}
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            {/* Conversation Active Pane */}
            {selectedThreadId && activeThread ? (
              <div className="flex-1 flex flex-col bg-[#0A0D14] h-full overflow-hidden">
                
                {/* Chat Header */}
                <div className="h-16 border-b border-white/10 px-6 flex items-center justify-between bg-[#111622]/80 backdrop-blur-md">
                  <div className="flex items-center space-x-3">
                    <div className="w-9 h-9 rounded-full bg-slate-800 border border-white/20 flex items-center justify-center font-bold text-sm text-[#00E676]">
                      {activeThread.userName.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-white flex items-center space-x-2">
                        <span>{activeThread.userName}</span>
                        <span className="text-[11px] font-mono text-slate-500">({activeThread.userId})</span>
                      </h3>
                      <div className="flex items-center space-x-1.5 text-[11px] text-[#00E676]">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] animate-pulse" />
                        <span>Active Session</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <span className="text-xs bg-white/5 border border-white/10 px-3 py-1.5 rounded-lg text-slate-400">
                      Project: freewatch-a0bc7
                    </span>
                  </div>
                </div>

                {/* Message Bubble History */}
                <div className="flex-1 overflow-y-auto p-6 space-y-4">
                  {messages.map((msg) => {
                    const isAdmin = msg.senderRole === 'admin';
                    const timeStr = new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                    return (
                      <div
                        key={msg.id}
                        className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                      >
                        <div className="flex items-center space-x-2 mb-1">
                          <span className="text-[11px] font-semibold text-slate-400">
                            {isAdmin ? '🛡️ FreeWatch Support' : activeThread.userName}
                          </span>
                          <span className="text-[10px] text-slate-600">
                            {timeStr}
                          </span>
                        </div>

                        <div
                          className={`max-w-lg rounded-2xl px-4 py-2.5 text-sm leading-relaxed shadow-md ${
                            isAdmin
                              ? 'bg-gradient-to-r from-[#00E676] to-[#10B981] text-black font-medium rounded-tr-none'
                              : 'bg-[#181E2C] border border-white/10 text-white rounded-tl-none'
                          }`}
                        >
                          {msg.text}
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>

                {/* Quick Reply Bar */}
                <div className="px-6 py-2 border-t border-white/5 flex items-center space-x-2 overflow-x-auto text-xs">
                  <span className="text-slate-500 flex-shrink-0">Quick reply:</span>
                  {[
                    "Hello! 👋 How can we help you today?",
                    "Thanks for reporting! We are adding this movie now.",
                    "The Luganda translation is being updated right now.",
                    "Enjoy watching in Full HD on FreeWatch!"
                  ].map((preset, idx) => (
                    <button
                      key={idx}
                      onClick={() => setNewMessage(preset)}
                      className="whitespace-nowrap bg-white/5 hover:bg-white/10 text-slate-300 px-3 py-1 rounded-full border border-white/10 transition-colors"
                    >
                      {preset}
                    </button>
                  ))}
                </div>

                {/* Message Input Box */}
                <form
                  onSubmit={handleSendMessage}
                  className="p-4 border-t border-white/10 bg-[#111622] flex items-center space-x-3"
                >
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Type an instant reply to this user..."
                    className="flex-1 bg-[#171D2B] border border-white/10 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-[#00E676]"
                  />
                  <button
                    type="submit"
                    disabled={!newMessage.trim()}
                    className="bg-[#00E676] hover:bg-[#00c864] disabled:opacity-50 text-black px-6 py-3 rounded-xl font-bold flex items-center space-x-2 transition-all shadow-lg shadow-[#00E676]/20"
                  >
                    <span>Reply</span>
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-500 p-8">
                <MessageSquare className="w-12 h-12 mb-3 stroke-1" />
                <p className="text-base font-semibold">Select a user conversation from the left to start live chatting.</p>
              </div>
            )}
          </div>
        )}

        {/* TAB 2: PUSH NOTIFICATION DISPATCHER */}
        {activeTab === 'notifications' && (
          <div className="flex-1 overflow-y-auto p-8 max-w-5xl mx-auto space-y-8">
            <div>
              <h1 className="text-2xl font-black text-white flex items-center space-x-3">
                <Bell className="w-7 h-7 text-[#00E676]" />
                <span>FCM Cloud Push Notification Dispatcher</span>
              </h1>
              <p className="text-slate-400 text-sm mt-1">
                Broadcast real-time push alerts to all installed FreeWatch mobile devices with custom titles, movie banners, and deep links.
              </p>
            </div>

            {notifSuccess && (
              <div className="bg-[#00E676]/15 border border-[#00E676]/40 text-[#00E676] px-4 py-3 rounded-xl flex items-center space-x-3">
                <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
                <span className="text-sm font-semibold">{notifSuccess}</span>
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              
              {/* Dispatch Form (2 cols) */}
              <div className="md:col-span-2 bg-[#111622] border border-white/10 rounded-2xl p-6 shadow-xl space-y-5">
                <form onSubmit={handleSendPushNotification} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">
                      Target Audience / Topic
                    </label>
                    <div className="grid grid-cols-3 gap-3">
                      {[
                        { id: 'all_users', label: 'All Users (all_users)', icon: Users },
                        { id: 'new_releases', label: 'New Releases', icon: Flame },
                        { id: 'test_device', label: 'Test Devices', icon: Smartphone }
                      ].map(t => {
                        const Icon = t.icon;
                        const isSel = notifTarget === t.id;
                        return (
                          <button
                            type="button"
                            key={t.id}
                            onClick={() => setNotifTarget(t.id)}
                            className={`p-3 rounded-xl border text-left flex flex-col space-y-1 transition-all ${
                              isSel 
                                ? 'bg-[#00E676]/10 border-[#00E676] text-white' 
                                : 'bg-[#171D2B] border-white/10 text-slate-400 hover:text-white'
                            }`}
                          >
                            <Icon className={`w-4 h-4 ${isSel ? 'text-[#00E676]' : ''}`} />
                            <span className="text-xs font-bold">{t.label}</span>
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                      Notification Title
                    </label>
                    <input
                      type="text"
                      value={notifTitle}
                      onChange={(e) => setNotifTitle(e.target.value)}
                      placeholder="e.g. 🎬 John Wick Chapter 4 (VJ Junior)"
                      className="w-full bg-[#171D2B] border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#00E676]"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                      Notification Body / Synopsis
                    </label>
                    <textarea
                      value={notifBody}
                      onChange={(e) => setNotifBody(e.target.value)}
                      placeholder="Luganda translated release is now live! Tap to stream in 4K."
                      rows={3}
                      className="w-full bg-[#171D2B] border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#00E676]"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                        Backdrop / Poster Image URL (Optional)
                      </label>
                      <input
                        type="url"
                        value={notifImageUrl}
                        onChange={(e) => setNotifImageUrl(e.target.value)}
                        placeholder="https://image.tmdb.org/t/p/w780/..."
                        className="w-full bg-[#171D2B] border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                        Movie ID Payload (Optional)
                      </label>
                      <input
                        type="text"
                        value={notifMovieId}
                        onChange={(e) => setNotifMovieId(e.target.value)}
                        placeholder="e.g. 603692"
                        className="w-full bg-[#171D2B] border border-white/10 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#00E676]"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isSendingNotif}
                    className="w-full bg-[#00E676] hover:bg-[#00c864] text-black font-extrabold py-3.5 rounded-xl transition-all shadow-lg shadow-[#00E676]/25 flex items-center justify-center space-x-2"
                  >
                    {isSendingNotif ? (
                      <RefreshCw className="w-5 h-5 animate-spin" />
                    ) : (
                      <>
                        <Send className="w-5 h-5" />
                        <span>Dispatch Push Notification Now</span>
                      </>
                    )}
                  </button>
                </form>
              </div>

              {/* Mobile Preview Device (1 col) */}
              <div className="bg-[#111622] border border-white/10 rounded-2xl p-6 flex flex-col items-center">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4">
                  Mobile OS Status Bar Preview
                </span>

                {/* Mock Phone Notification Card */}
                <div className="w-full bg-[#1F2533] rounded-2xl p-4 border border-white/15 shadow-2xl relative overflow-hidden">
                  <div className="flex items-center space-x-2 mb-2">
                    <div className="w-5 h-5 rounded-md bg-[#00E676] flex items-center justify-center font-black text-[9px] text-black">
                      FW
                    </div>
                    <span className="text-xs font-bold text-slate-300">FreeWatch</span>
                    <span className="text-[10px] text-slate-500">• now</span>
                  </div>

                  <h4 className="text-sm font-bold text-white mb-1">
                    {notifTitle || 'Notification Title'}
                  </h4>
                  <p className="text-xs text-slate-300 line-clamp-2 mb-2">
                    {notifBody || 'Notification body text will appear here...'}
                  </p>

                  {notifImageUrl && (
                    <img
                      src={notifImageUrl}
                      alt="Preview"
                      className="w-full h-28 object-cover rounded-xl mt-2 border border-white/10"
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                  )}
                </div>

                <p className="text-xs text-slate-500 mt-4 text-center">
                  Will appear in device notification tray with the transparent FW icon even when the app is closed.
                </p>
              </div>
            </div>

            {/* Broadcast History */}
            <div className="bg-[#111622] border border-white/10 rounded-2xl p-6">
              <h3 className="text-base font-bold text-white mb-4 flex items-center space-x-2">
                <Clock className="w-5 h-5 text-[#00E676]" />
                <span>Recent Broadcast History</span>
              </h3>

              {dispatchedNotifs.length === 0 ? (
                <p className="text-sm text-slate-500">No broadcasts sent yet.</p>
              ) : (
                <div className="space-y-3">
                  {dispatchedNotifs.map((item) => (
                    <div
                      key={item.id}
                      className="p-4 bg-[#171D2B] rounded-xl border border-white/5 flex items-center justify-between"
                    >
                      <div>
                        <div className="flex items-center space-x-2 mb-1">
                          <span className="text-xs font-bold text-[#00E676] bg-[#00E676]/10 px-2 py-0.5 rounded-full">
                            Topic: {item.targetTopic}
                          </span>
                          <span className="text-xs text-slate-500">
                            {new Date(item.timestamp).toLocaleString()}
                          </span>
                        </div>
                        <h4 className="text-sm font-bold text-white">{item.title}</h4>
                        <p className="text-xs text-slate-400 mt-0.5">{item.body}</p>
                      </div>

                      <div className="flex items-center space-x-2">
                        <CheckCircle2 className="w-5 h-5 text-[#00E676]" />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 3: CATALOG & VJ MANAGER */}
        {activeTab === 'catalog' && (
          <div className="flex-1 overflow-y-auto p-8 max-w-5xl mx-auto space-y-8">
            <div>
              <h1 className="text-2xl font-black text-white flex items-center space-x-3">
                <Film className="w-7 h-7 text-[#00E676]" />
                <span>FreeWatch Catalog & VJ Asset Manager</span>
              </h1>
              <p className="text-slate-400 text-sm mt-1">
                Official FreeWatch roster overview with dedicated assets and studio translations.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-5">
              {[
                { name: 'VJ Junior', desc: 'The King of Translation', asset: 'assets/vjs/vj_junior.png', verified: true },
                { name: 'VJ Emmy', desc: 'Action & Drama Specialist', asset: 'assets/vjs/vj_emmy.png', verified: true },
                { name: 'VJ Ice P', desc: 'Epic Voiceover & Commentary', asset: 'assets/vjs/vj_ice_p.png', verified: true },
                { name: 'VJ Jingo', desc: 'Classic & Comedy Master', asset: 'assets/vjs/vj_jingo.png', verified: true },
                { name: 'VJ Kevin', desc: 'Sci-Fi & Thriller Stylist', asset: 'assets/vjs/vj_kevin.png', verified: true },
                { name: 'VJ Sunny', desc: 'Romance & Adventure Master', asset: 'assets/vjs/vj_sunny.png', verified: true },
                { name: 'VJ Anti', desc: 'Official Universal Studio Asset', asset: 'assets/vjs/vj_universal.png', verified: true, universal: true },
                { name: 'VJ Mossa', desc: 'Official Universal Studio Asset', asset: 'assets/vjs/vj_universal.png', verified: true, universal: true },
                { name: 'VJ Chris Sweet', desc: 'Official Universal Studio Asset', asset: 'assets/vjs/vj_universal.png', verified: true, universal: true },
              ].map((vj, idx) => (
                <div
                  key={idx}
                  className="bg-[#111622] border border-white/10 rounded-2xl p-5 flex items-center space-x-4 shadow-lg"
                >
                  <div className="w-14 h-14 rounded-2xl bg-[#171D2B] border border-white/15 flex items-center justify-center font-black text-lg text-[#00E676] overflow-hidden flex-shrink-0">
                    {vj.universal ? '🎧' : '🎙️'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-1.5">
                      <h4 className="text-sm font-bold text-white truncate">{vj.name}</h4>
                      <ShieldCheck className="w-4 h-4 text-[#00E676] flex-shrink-0" />
                    </div>
                    <p className="text-xs text-slate-400 mt-0.5 truncate">{vj.desc}</p>
                    <span className="inline-block mt-2 text-[10px] bg-white/5 border border-white/10 text-slate-400 px-2 py-0.5 rounded-md font-mono truncate">
                      {vj.asset}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* TikTok Account Sync status */}
            <div className="bg-[#111622] border border-white/10 rounded-2xl p-6 flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">Official TikTok Account Link</span>
                <p className="text-sm font-bold text-white mt-1">https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi</p>
                <p className="text-xs text-[#00E676] mt-0.5">Active across mobile app Profile and Deep Links</p>
              </div>
              <a
                href="https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi"
                target="_blank"
                rel="noreferrer"
                className="bg-white/10 hover:bg-white/15 px-4 py-2 rounded-xl text-xs font-bold text-white flex items-center space-x-2 transition-colors"
              >
                <span>Visit Channel</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
