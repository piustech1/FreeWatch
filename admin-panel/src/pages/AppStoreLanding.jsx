import React, { useState, useEffect } from 'react';
import { 
  Share2, ArrowLeft, Star, Download, Check, Sparkles, 
  Smartphone, ShieldCheck, Film, Tv, Play, HardDrive, 
  MessageSquare, Sun, Moon, ExternalLink, X, ChevronRight,
  Layers, Search, Compass, Gamepad2, Award
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

export default function AppStoreLanding({ onNavigateToAdmin }) {
  const [theme, setTheme] = useState('dark'); // 'dark' | 'light'
  const [downloadProgress, setDownloadProgress] = useState(0);
  const [downloadState, setDownloadState] = useState('idle'); // 'idle' | 'downloading' | 'completed'
  const [showVersionHistory, setShowVersionHistory] = useState(false);
  const [shareToast, setShareToast] = useState(false);

  // Dynamic Release Config
  const [releaseInfo, setReleaseInfo] = useState({
    version: '1.0.56',
    buildNumber: 57,
    size: '83.6 MB',
    releaseDate: 'Just now',
    apkUrl: 'https://github.com/piustech1/FreeWatch/releases/download/v1.0.56/FreeWatch_Release_v1.0.56.apk',
    notes: [
      'Permanent offline movie downloads: downloads now persist across all sign-outs & guest sessions.',
      'Instant Live Support chat reply alerts: get notified the moment an admin responds, with direct 1-tap navigation.',
      'Auto-updating engine: seamless in-app notifications whenever a new build is released.',
      'Enhanced video player with responsive HUD, swipe-to-seek, and landscape mode improvements.',
      'Optimized database listeners for lower data usage and faster movie stream initiation.'
    ]
  });

  useEffect(() => {
    let unsub = () => {};
    // 1. Listen to Firebase RTDB app_config/update
    try {
      const updateRef = ref(rtdb, 'app_config/update');
      unsub = onValue(updateRef, (snapshot) => {
        if (snapshot.exists()) {
          const val = snapshot.val();
          setReleaseInfo(prev => ({
            ...prev,
            version: val.latest_version || prev.version,
            buildNumber: val.latest_build || prev.buildNumber,
            apkUrl: val.direct_apk_url || prev.apkUrl,
            notes: val.release_notes ? val.release_notes.split('\n').filter(Boolean) : prev.notes
          }));
        }
      });
    } catch (_) {}

    // 2. Also fetch latest release info from GitHub API dynamically
    fetch('https://api.github.com/repos/piustech1/FreeWatch/releases/latest')
      .then(res => res.json())
      .then(data => {
        if (data && data.tag_name) {
          const cleanTag = data.tag_name.replace('v', '').trim();
          let apk = releaseInfo.apkUrl;
          if (Array.isArray(data.assets)) {
            const asset = data.assets.find(a => a.name && a.name.endsWith('.apk'));
            if (asset && asset.browser_download_url) {
              apk = asset.browser_download_url;
            }
          }
          setReleaseInfo(prev => ({
            ...prev,
            version: cleanTag,
            apkUrl: apk,
            notes: data.body ? data.body.split('\n').filter(Boolean) : prev.notes
          }));
        }
      })
      .catch(() => {});

    return () => unsub();
  }, []);

  const handleDownload = () => {
    if (downloadState === 'downloading') return;

    if (downloadState === 'completed') {
      window.location.href = releaseInfo.apkUrl;
      return;
    }

    setDownloadState('downloading');
    setDownloadProgress(10);

    const interval = setInterval(() => {
      setDownloadProgress(prev => {
        if (prev >= 90) {
          clearInterval(interval);
          setDownloadState('completed');
          // Trigger actual APK download
          const link = document.createElement('a');
          link.href = releaseInfo.apkUrl;
          link.setAttribute('download', `FreeWatch_Release_v${releaseInfo.version}.apk`);
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
          return 100;
        }
        return prev + 18;
      });
    }, 240);
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'FreeWatch - Luganda Dubbed Movies & Series',
          text: `Download FreeWatch v${releaseInfo.version} for free. Stream unlimited Luganda translated movies!`,
          url: window.location.href,
        });
        return;
      } catch (_) {}
    }
    navigator.clipboard.writeText(window.location.href);
    setShareToast(true);
    setTimeout(() => setShareToast(false), 2500);
  };

  const isDark = theme === 'dark';

  return (
    <div className={`min-h-screen transition-colors duration-300 font-sans ${isDark ? 'bg-black text-white' : 'bg-[#F2F2F7] text-[#1C1C1E]'}`}>
      
      {/* Toast Notification */}
      {shareToast && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50 px-5 py-2.5 rounded-full bg-blue-600 text-white text-xs font-semibold shadow-2xl flex items-center space-x-2 animate-bounce">
          <Check className="w-4 h-4" />
          <span>App Store link copied to clipboard!</span>
        </div>
      )}

      {/* Main Container - Mobile Centered Frame */}
      <div className="max-w-md mx-auto min-h-screen relative flex flex-col shadow-2xl overflow-hidden border-x border-neutral-800/40">

        {/* ── 1. iOS Status Bar ── */}
        <div className={`px-6 pt-3 pb-2 flex items-center justify-between text-xs font-semibold select-none ${isDark ? 'text-white' : 'text-black'}`}>
          <span className="font-bold tracking-tight">9:41</span>
          
          {/* Dynamic Island Notch */}
          <div className="w-28 h-6 bg-black rounded-full mx-auto flex items-center justify-end px-2 space-x-1.5 shadow-inner">
            <div className="w-2.5 h-2.5 bg-neutral-900 rounded-full border border-neutral-800"></div>
          </div>

          <div className="flex items-center space-x-1.5">
            {/* Cellular */}
            <div className="flex items-end space-x-0.5 h-2.5">
              <span className="w-0.5 h-1 bg-current rounded-full"></span>
              <span className="w-0.5 h-1.5 bg-current rounded-full"></span>
              <span className="w-0.5 h-2 bg-current rounded-full"></span>
              <span className="w-0.5 h-2.5 bg-current rounded-full"></span>
            </div>
            {/* WiFi */}
            <span className="text-[11px]">5G</span>
            {/* Battery */}
            <div className="w-5 h-2.5 border border-current rounded-sm p-0.5 flex items-center">
              <div className="h-full w-3/4 bg-current rounded-2xs"></div>
            </div>
          </div>
        </div>

        {/* ── 2. Navigation Header Bar ── */}
        <div className="px-5 py-2 flex items-center justify-between">
          <button 
            onClick={() => window.history.back()}
            className={`p-2 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-900' : 'text-blue-600 hover:bg-neutral-200'}`}
            title="Go back"
          >
            <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
          </button>

          <div className="flex items-center space-x-2">
            {/* Admin Console Shortcut */}
            {onNavigateToAdmin ? (
              <button 
                onClick={onNavigateToAdmin}
                className={`p-2 rounded-full border transition-all ${
                  isDark 
                    ? 'border-neutral-800 bg-neutral-900 text-emerald-400 hover:bg-neutral-800' 
                    : 'border-neutral-300 bg-white text-emerald-600 hover:bg-neutral-100 shadow-sm'
                }`}
                title="Open Admin Console"
              >
                <ShieldCheck className="w-4 h-4" />
              </button>
            ) : (
              <a 
                href="/admin"
                className={`p-2 rounded-full border transition-all ${
                  isDark 
                    ? 'border-neutral-800 bg-neutral-900 text-emerald-400 hover:bg-neutral-800' 
                    : 'border-neutral-300 bg-white text-emerald-600 hover:bg-neutral-100 shadow-sm'
                }`}
                title="Open Admin Console"
              >
                <ShieldCheck className="w-4 h-4" />
              </a>
            )}

            {/* Theme Toggle (Light / Dark) */}
            <button 
              onClick={() => setTheme(isDark ? 'light' : 'dark')}
              className={`p-2 rounded-full border transition-all ${
                isDark 
                  ? 'border-neutral-800 bg-neutral-900 text-yellow-400 hover:bg-neutral-800' 
                  : 'border-neutral-300 bg-white text-neutral-800 hover:bg-neutral-100 shadow-sm'
              }`}
              title={`Switch to ${isDark ? 'Light' : 'Dark'} mode`}
            >
              {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* Share Button */}
            <button 
              onClick={handleShare}
              className={`p-2 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-900' : 'text-blue-600 hover:bg-neutral-200'}`}
              title="Share FreeWatch"
            >
              <Share2 className="w-5 h-5 stroke-[2.2]" />
            </button>
          </div>
        </div>

        {/* ── 3. App Product Header (Squircle, Title, GET / UPDATE Button) ── */}
        <div className="px-5 pt-3 pb-5 flex items-center space-x-4">
          {/* Squircle App Icon */}
          <div className="w-24 h-24 rounded-[22px] bg-gradient-to-br from-red-600 via-rose-700 to-black p-1 shadow-2xl flex-shrink-0 relative overflow-hidden border border-white/10">
            <div className="w-full h-full rounded-[18px] bg-black flex flex-col items-center justify-center relative overflow-hidden">
              <Film className="w-10 h-10 text-red-500 drop-shadow-md" />
              <span className="text-[10px] font-black tracking-widest text-white mt-1">FREEWATCH</span>
              {/* Glossy overlay reflection */}
              <div className="absolute -top-6 -right-6 w-16 h-16 bg-white/15 rounded-full blur-md"></div>
            </div>
          </div>

          {/* Title & Subtitle & Actions */}
          <div className="flex-1 min-w-0 flex flex-col justify-center">
            <h1 className="text-2xl font-black tracking-tight leading-tight truncate">FreeWatch</h1>
            <p className={`text-xs font-medium truncate mt-0.5 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Luganda Dubbed Movies & Series
            </p>

            <div className="flex items-center space-x-3 mt-3">
              {/* iOS Pill Download Button */}
              <button
                onClick={handleDownload}
                disabled={downloadState === 'downloading'}
                className="relative overflow-hidden px-6 py-1.5 rounded-full bg-[#0071E3] hover:bg-blue-600 active:scale-95 text-white font-bold text-xs uppercase tracking-wider shadow-md transition-all flex items-center justify-center min-w-[96px] h-8"
              >
                {downloadState === 'idle' && 'UPDATE'}
                {downloadState === 'downloading' && (
                  <div className="flex items-center space-x-1.5">
                    <svg className="animate-spin h-3.5 w-3.5 text-white" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <span>{downloadProgress}%</span>
                  </div>
                )}
                {downloadState === 'completed' && 'OPEN'}
              </button>

              <button 
                onClick={handleShare}
                className={`p-1.5 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-800' : 'text-blue-600 hover:bg-neutral-200'}`}
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* ── 4. Stat Row Badges (1.2K RATINGS, AGE 12+, CHART #1) ── */}
        <div className={`mx-5 py-3 border-y grid grid-cols-3 text-center divide-x ${
          isDark ? 'border-neutral-800 divide-neutral-800' : 'border-neutral-200 divide-neutral-200'
        }`}>
          {/* Column 1: Ratings */}
          <div className="px-2">
            <div className={`text-[10px] font-bold tracking-wider uppercase ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              1.2K RATINGS
            </div>
            <div className="text-xl font-bold tracking-tight mt-0.5">4.9</div>
            <div className="flex items-center justify-center space-x-0.5 text-yellow-400 mt-1">
              {[...Array(5)].map((_, i) => (
                <Star key={i} className="w-3 h-3 fill-yellow-400 text-yellow-400" />
              ))}
            </div>
          </div>

          {/* Column 2: Age */}
          <div className="px-2">
            <div className={`text-[10px] font-bold tracking-wider uppercase ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              AGE
            </div>
            <div className="text-xl font-bold tracking-tight mt-0.5">12+</div>
            <div className={`text-[10px] font-medium mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Years Old
            </div>
          </div>

          {/* Column 3: Chart */}
          <div className="px-2">
            <div className={`text-[10px] font-bold tracking-wider uppercase ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              CHART
            </div>
            <div className="text-xl font-bold tracking-tight mt-0.5 text-blue-500">#1</div>
            <div className={`text-[10px] font-medium mt-1 truncate ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Luganda Dubbed
            </div>
          </div>
        </div>

        {/* ── 5. What's New Section ── */}
        <div className="px-5 py-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold tracking-tight">What's New</h2>
            <button 
              onClick={() => setShowVersionHistory(true)}
              className="text-xs font-semibold text-[#0071E3] hover:underline"
            >
              Version History
            </button>
          </div>

          <div className="flex items-center justify-between text-xs mt-1">
            <span className={isDark ? 'text-neutral-400 font-medium' : 'text-neutral-500 font-medium'}>
              Version {releaseInfo.version}
            </span>
            <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>
              {releaseInfo.releaseDate}
            </span>
          </div>

          <ul className={`mt-2.5 space-y-1.5 text-xs leading-relaxed ${isDark ? 'text-neutral-300' : 'text-neutral-700'}`}>
            {releaseInfo.notes.map((item, idx) => (
              <li key={idx} className="flex items-start space-x-2">
                <span className="text-[#0071E3] font-bold">•</span>
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* ── 6. Preview Screenshots Carousel ── */}
        <div className="py-2">
          <div className="px-5 mb-2.5">
            <h2 className="text-lg font-bold tracking-tight">Preview</h2>
          </div>

          <div className="flex space-x-3 overflow-x-auto px-5 pb-3 scrollbar-none snap-x snap-mandatory">
            {/* Screen 1: Home Feed */}
            <div className={`snap-center flex-shrink-0 w-52 h-96 rounded-2xl p-3 flex flex-col justify-between border shadow-lg relative overflow-hidden ${
              isDark ? 'bg-[#1C1C1E] border-neutral-800' : 'bg-white border-neutral-200'
            }`}>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="text-xs font-bold text-red-500">FREEWATCH</span>
                <span className="text-[10px] bg-red-600 text-white px-1.5 py-0.5 rounded font-bold">LIVE</span>
              </div>
              <div className="flex-1 flex flex-col justify-center items-center text-center px-2">
                <Tv className="w-12 h-12 text-blue-500 mb-2" />
                <h4 className="text-xs font-bold">Trending Movies</h4>
                <p className={`text-[10px] mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
                  VJ Junior • VJ Jingo • VJ Emmie translated blockbusters in HD.
                </p>
              </div>
              <div className="bg-red-500/10 text-red-500 rounded-lg p-2 text-center text-[10px] font-semibold">
                Daily New Releases
              </div>
            </div>

            {/* Screen 2: Landscape Cinema Player */}
            <div className={`snap-center flex-shrink-0 w-52 h-96 rounded-2xl p-3 flex flex-col justify-between border shadow-lg relative overflow-hidden ${
              isDark ? 'bg-[#1C1C1E] border-neutral-800' : 'bg-white border-neutral-200'
            }`}>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="text-xs font-bold text-blue-400">Cinematic Player</span>
                <span className="text-[10px] bg-blue-600 text-white px-1.5 py-0.5 rounded font-bold">1080p</span>
              </div>
              <div className="flex-1 flex flex-col justify-center items-center text-center px-2">
                <div className="w-12 h-12 rounded-full bg-blue-500/20 flex items-center justify-center mb-2">
                  <Play className="w-6 h-6 text-blue-500 fill-blue-500" />
                </div>
                <h4 className="text-xs font-bold">Landscape Gesture Controls</h4>
                <p className={`text-[10px] mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
                  Auto-disappearing controls, 10s seek jump & volume swipes.
                </p>
              </div>
              <div className="bg-blue-500/10 text-blue-400 rounded-lg p-2 text-center text-[10px] font-semibold">
                OLED Pure Black
              </div>
            </div>

            {/* Screen 3: WhatsApp Support */}
            <div className={`snap-center flex-shrink-0 w-52 h-96 rounded-2xl p-3 flex flex-col justify-between border shadow-lg relative overflow-hidden ${
              isDark ? 'bg-[#1C1C1E] border-neutral-800' : 'bg-white border-neutral-200'
            }`}>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="text-xs font-bold text-emerald-500">Live Support</span>
                <span className="text-[10px] bg-emerald-600 text-white px-1.5 py-0.5 rounded font-bold">24/7</span>
              </div>
              <div className="flex-1 flex flex-col justify-center items-center text-center px-2">
                <MessageSquare className="w-12 h-12 text-emerald-500 mb-2" />
                <h4 className="text-xs font-bold">WhatsApp Styled Chat</h4>
                <p className={`text-[10px] mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
                  Direct line to admin team with real-time push notifications.
                </p>
              </div>
              <div className="bg-emerald-500/10 text-emerald-500 rounded-lg p-2 text-center text-[10px] font-semibold">
                Instant Admin Responses
              </div>
            </div>

            {/* Screen 4: Offline Downloads */}
            <div className={`snap-center flex-shrink-0 w-52 h-96 rounded-2xl p-3 flex flex-col justify-between border shadow-lg relative overflow-hidden ${
              isDark ? 'bg-[#1C1C1E] border-neutral-800' : 'bg-white border-neutral-200'
            }`}>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="text-xs font-bold text-purple-400">Downloads</span>
                <span className="text-[10px] bg-purple-600 text-white px-1.5 py-0.5 rounded font-bold">Offline</span>
              </div>
              <div className="flex-1 flex flex-col justify-center items-center text-center px-2">
                <HardDrive className="w-12 h-12 text-purple-400 mb-2" />
                <h4 className="text-xs font-bold">Permanent Device Storage</h4>
                <p className={`text-[10px] mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
                  Watch anywhere without Wi-Fi. Downloads persist across logouts!
                </p>
              </div>
              <div className="bg-purple-500/10 text-purple-400 rounded-lg p-2 text-center text-[10px] font-semibold">
                Zero Data Mode
              </div>
            </div>
          </div>
        </div>

        {/* ── 7. Information Section ── */}
        <div className="px-5 py-4 border-t border-neutral-800/40">
          <h2 className="text-lg font-bold tracking-tight mb-2.5">Information</h2>

          <div className={`divide-y text-xs ${isDark ? 'divide-neutral-800/80 text-neutral-300' : 'divide-neutral-200 text-neutral-700'}`}>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Provider</span>
              <span className="font-semibold text-right">FreeWatch Media Ltd</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Size</span>
              <span className="font-semibold text-right">{releaseInfo.size}</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Category</span>
              <span className="font-semibold text-right text-blue-500">Entertainment</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Compatibility</span>
              <span className="font-semibold text-right">Android 6.0 and later</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Languages</span>
              <span className="font-semibold text-right">English, Luganda</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Age Rating</span>
              <span className="font-semibold text-right">12+</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Price</span>
              <span className="font-semibold text-right text-emerald-500">Free</span>
            </div>
            <div className="py-2.5 flex justify-between items-center">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Admin Console</span>
              {onNavigateToAdmin ? (
                <button 
                  onClick={onNavigateToAdmin}
                  className="font-semibold text-right text-xs text-blue-500 hover:underline"
                >
                  Sign In to Portal &rarr;
                </button>
              ) : (
                <a 
                  href="/admin" 
                  className="font-semibold text-right text-xs text-blue-500 hover:underline"
                >
                  Sign In to Portal &rarr;
                </a>
              )}
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Copyright</span>
              <span className="font-medium text-right text-[11px] text-neutral-500">© 2026 FreeWatch Inc.</span>
            </div>
          </div>
        </div>

        {/* ── 8. Bottom App Store Navigation Tab Bar ── */}
        <div className={`mt-auto border-t py-2 px-6 grid grid-cols-5 text-center select-none ${
          isDark ? 'bg-black/90 border-neutral-800 text-neutral-400' : 'bg-white/90 border-neutral-200 text-neutral-500'
        }`}>
          <div className="flex flex-col items-center cursor-pointer hover:opacity-80">
            <Compass className="w-5 h-5" />
            <span className="text-[10px] mt-0.5 font-medium">Today</span>
          </div>
          <div className="flex flex-col items-center cursor-pointer hover:opacity-80">
            <Gamepad2 className="w-5 h-5" />
            <span className="text-[10px] mt-0.5 font-medium">Games</span>
          </div>
          <div className="flex flex-col items-center cursor-pointer text-[#0071E3]">
            <Layers className="w-5 h-5 stroke-[2.5]" />
            <span className="text-[10px] mt-0.5 font-bold">Apps</span>
          </div>
          <div className="flex flex-col items-center cursor-pointer hover:opacity-80">
            <Award className="w-5 h-5" />
            <span className="text-[10px] mt-0.5 font-medium">Arcade</span>
          </div>
          <div className="flex flex-col items-center cursor-pointer hover:opacity-80">
            <Search className="w-5 h-5" />
            <span className="text-[10px] mt-0.5 font-medium">Search</span>
          </div>
        </div>

      </div>

      {/* ── Version History iOS Modal Sheet ── */}
      {showVersionHistory && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className={`w-full max-w-md rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl max-h-[80vh] flex flex-col ${
            isDark ? 'bg-[#1C1C1E] text-white' : 'bg-white text-[#1C1C1E]'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-neutral-800">
              <h3 className="text-lg font-bold">Version History</h3>
              <button 
                onClick={() => setShowVersionHistory(false)}
                className="p-1 rounded-full text-neutral-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="overflow-y-auto divide-y divide-neutral-800 py-3 space-y-4">
              <div>
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.56</span>
                  <span className="text-xs text-neutral-400">Just now</span>
                </div>
                <p className="text-xs text-neutral-300 leading-relaxed">
                  Permanent offline movie downloads, live chat reply alerts, auto-update prompt, and video player enhancements.
                </p>
              </div>

              <div className="pt-3">
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.55</span>
                  <span className="text-xs text-neutral-400">1w ago</span>
                </div>
                <p className="text-xs text-neutral-300 leading-relaxed">
                  Real-time live presence tracking, WhatsApp style support chat, and ban enforcement.
                </p>
              </div>

              <div className="pt-3">
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.50</span>
                  <span className="text-xs text-neutral-400">2w ago</span>
                </div>
                <p className="text-xs text-neutral-300 leading-relaxed">
                  FreeWatch live streaming engine, MunoWatch synchronization cron, and rich movie catalog.
                </p>
              </div>
            </div>

            <button
              onClick={() => setShowVersionHistory(false)}
              className="mt-3 w-full py-2.5 rounded-xl bg-[#0071E3] text-white font-bold text-sm"
            >
              Done
            </button>
          </div>
        </div>
      )}

    </div>
  );
}
