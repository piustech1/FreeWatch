import React, { useState, useEffect } from 'react';
import { 
  Share2, ArrowLeft, Star, Download, Check, Sparkles, 
  Smartphone, Film, Tv, Play, HardDrive, 
  MessageSquare, Sun, Moon, ExternalLink, X, ChevronRight
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

export default function AppStoreLanding() {
  // Default theme is 'light' as requested
  const [theme, setTheme] = useState('light'); // 'light' | 'dark'
  const [downloadProgress, setDownloadProgress] = useState(0);
  const [downloadState, setDownloadState] = useState('idle'); // 'idle' | 'downloading' | 'completed'
  const [showVersionHistory, setShowVersionHistory] = useState(false);
  const [isNotesExpanded, setIsNotesExpanded] = useState(false);
  const [shareToast, setShareToast] = useState(false);
  const [activeLightboxImage, setActiveLightboxImage] = useState(null);

  // Intelligent Button Label: Shows 'INSTALL' on first visit, 'UPDATE' if visited/installed before
  const [hasVisitedBefore, setHasVisitedBefore] = useState(false);

  useEffect(() => {
    try {
      const visited = localStorage.getItem('freewatch_store_visited');
      if (visited) {
        setHasVisitedBefore(true);
      } else {
        localStorage.setItem('freewatch_store_visited', 'true');
      }
    } catch (_) {}
  }, []);

  // Dynamic Release Config - Mobile Application Features Only
  const [releaseInfo, setReleaseInfo] = useState({
    version: '1.0.58',
    buildNumber: 59,
    size: '83.6 MB',
    releaseDate: 'Just now',
    apkUrl: 'https://github.com/piustech1/FreeWatch/releases/download/v1.0.58/FreeWatch-release.apk',
    notes: [
      'Permanent offline movie downloads: downloaded movies now persist safely across all sign-outs, cache resets, and guest sessions.',
      'Instant live support chat alerts: receive prompt lock-screen notifications the moment a FreeWatch support moderator responds, with 1-tap jump to chat.',
      'Refined cinema video player: improved swipe-to-seek responsiveness, seamless buffering, and immersive landscape controls.',
      'Faster streaming engine: accelerated movie startup speeds and significantly reduced cellular data usage.'
    ]
  });

  // Ordered Screenshots: Main user flows first (Home, Movie, Series, Search, Category, Favorites, Chat, Profile, Notifications, Splash)
  const screenshots = [
    {
      url: '/screenshots/photo_2026-10-14_02-15-30.jpg',
      title: 'Home Page',
      caption: 'Trending Luganda dubbed movies, VJ categories, and fresh daily additions'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-44.jpg',
      title: 'Movie Details Page',
      caption: 'Watch instantly with full cast, storyline synopsis, and video player controls'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-40.jpg',
      title: 'Series Details Page',
      caption: 'Multi-season episode browser with Luganda translation and trailer playback'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-53.jpg',
      title: 'Search Page with a List of Movies',
      caption: 'Lightning-fast instant search across thousands of translated films and series'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-49.jpg',
      title: 'Search Category Page',
      caption: 'Browse genres, VJs (VJ Junior, VJ Jingo, VJ Emmie), and curated collections'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-16-00.jpg',
      title: 'Favorites Page',
      caption: 'Personal watchlist to bookmark your favorite blockbusters and resume later'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-13-23.jpg',
      title: 'Chat Page',
      caption: 'Direct 24/7 live support with WhatsApp-styled messaging and instant alerts'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-57.jpg',
      title: 'Profile Page',
      caption: 'Manage account, playback preferences, dark/light themes, and app settings'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-16-04.jpg',
      title: 'Notifications Page',
      caption: 'Stay updated on newly dubbed releases, live announcements, and support replies'
    },
    {
      url: '/screenshots/photo_2026-10-14_02-15-36.jpg',
      title: 'Splash Screen',
      caption: 'Fast opening branding and instant initialization into the FreeWatch cinema'
    }
  ];

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
    try {
      localStorage.setItem('freewatch_store_visited', 'true');
      setHasVisitedBefore(true);
    } catch (_) {}

    if (downloadState === 'downloading') return;

    if (downloadState === 'completed') {
      window.location.href = releaseInfo.apkUrl;
      return;
    }

    setDownloadState('downloading');
    setDownloadProgress(12);

    const interval = setInterval(() => {
      setDownloadProgress(prev => {
        if (prev >= 92) {
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
        return prev + 16;
      });
    }, 200);
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
    <div className={`min-h-screen transition-colors duration-300 font-sans ${isDark ? 'bg-[#000000] text-white' : 'bg-[#F2F2F7] text-[#1C1C1E]'}`}>
      
      {/* Toast Notification */}
      {shareToast && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50 px-5 py-2.5 rounded-full bg-blue-600 text-white text-xs font-semibold shadow-2xl flex items-center space-x-2 animate-bounce">
          <Check className="w-4 h-4" />
          <span>App link copied to clipboard!</span>
        </div>
      )}

      {/* Main Container - Mobile Centered Frame */}
      <div className={`max-w-md mx-auto min-h-screen relative flex flex-col shadow-2xl overflow-hidden transition-colors duration-300 ${
        isDark ? 'bg-black border-x border-neutral-800/60' : 'bg-white border-x border-neutral-200/80 shadow-slate-200/50'
      }`}>

        {/* ── 1. Top Navigation Bar (Clean Native Style, No Fake Status Bar) ── */}
        <div className="px-5 pt-4 pb-2 flex items-center justify-between">
          <button 
            onClick={() => window.history.back()}
            className={`p-2 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-900' : 'text-blue-600 hover:bg-neutral-100'}`}
            title="Go back"
          >
            <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
          </button>

          <div className="flex items-center space-x-2">
            {/* Theme Toggle (Light / Dark) */}
            <button 
              onClick={() => setTheme(isDark ? 'light' : 'dark')}
              className={`p-2 rounded-full border transition-all ${
                isDark 
                  ? 'border-neutral-800 bg-neutral-900 text-yellow-400 hover:bg-neutral-800' 
                  : 'border-neutral-200 bg-white text-neutral-800 hover:bg-neutral-100 shadow-xs'
              }`}
              title={`Switch to ${isDark ? 'Light' : 'Dark'} mode`}
            >
              {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* Share Button */}
            <button 
              onClick={handleShare}
              className={`p-2 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-900' : 'text-blue-600 hover:bg-neutral-100'}`}
              title="Share FreeWatch"
            >
              <Share2 className="w-5 h-5 stroke-[2.2]" />
            </button>
          </div>
        </div>

        {/* ── 2. App Product Header (Clean Squircle Icon - NO Red Outline) ── */}
        <div className="px-5 pt-3 pb-5 flex items-center space-x-4">
          {/* Authentic Squircle App Icon - Clean & Borderless */}
          <div className="w-24 h-24 rounded-[22px] shadow-lg flex-shrink-0 relative overflow-hidden bg-neutral-900 border border-black/5">
            <img 
              src="/app_icon.png" 
              alt="FreeWatch App Icon" 
              className="w-full h-full object-cover rounded-[22px]"
            />
          </div>

          {/* Title & Subtitle & Actions */}
          <div className="flex-1 min-w-0 flex flex-col justify-center">
            <h1 className="text-2xl font-black tracking-tight leading-tight truncate">FreeWatch</h1>
            <p className={`text-xs font-medium truncate mt-0.5 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Luganda Dubbed Movies & Series
            </p>

            <div className="flex items-center space-x-3 mt-3">
              {/* Intelligent iOS Pill Button: 'INSTALL' for new visitors, 'UPDATE' for returning users */}
              <button
                onClick={handleDownload}
                disabled={downloadState === 'downloading'}
                className="relative overflow-hidden px-6 py-1.5 rounded-full bg-[#0071E3] hover:bg-blue-600 active:scale-95 text-white font-bold text-xs uppercase tracking-wider shadow-md transition-all flex items-center justify-center min-w-[96px] h-8"
              >
                {downloadState === 'idle' && (hasVisitedBefore ? 'UPDATE' : 'INSTALL')}
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
                className={`p-1.5 rounded-full transition-colors ${isDark ? 'text-blue-400 hover:bg-neutral-800' : 'text-blue-600 hover:bg-neutral-100'}`}
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* ── 3. Stat Row Badges (1.2K RATINGS, AGE 12+, CHART #1) ── */}
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
                <Star key={i} className="w-2.5 h-2.5 fill-yellow-400" />
              ))}
            </div>
          </div>

          {/* Column 2: Age Rating */}
          <div className="px-2">
            <div className={`text-[10px] font-bold tracking-wider uppercase ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              AGE
            </div>
            <div className="text-xl font-bold tracking-tight mt-0.5">12+</div>
            <div className={`text-[10px] mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Years Old
            </div>
          </div>

          {/* Column 3: Category Chart */}
          <div className="px-2">
            <div className={`text-[10px] font-bold tracking-wider uppercase ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              CHART
            </div>
            <div className="text-xl font-bold tracking-tight mt-0.5 text-[#0071E3]">#1</div>
            <div className={`text-[10px] truncate mt-1 ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Luganda Dubbed
            </div>
          </div>
        </div>

        {/* ── 4. What's New Section (Frosted & Collapsible) ── */}
        <div className="px-5 py-3">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold tracking-tight">What's New</h2>
            <button 
              onClick={() => setShowVersionHistory(true)}
              className="text-xs font-semibold text-[#0071E3] hover:underline"
            >
              Version History
            </button>
          </div>

          <div className="flex items-baseline space-x-2 mt-1">
            <span className={`text-xs font-semibold ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
              Version {releaseInfo.version}
            </span>
            <span className={`text-[11px] ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              {releaseInfo.releaseDate}
            </span>
          </div>

          {/* Frosted Glass Container with iOS style ... more */}
          <div className={`mt-3 p-3.5 rounded-2xl border backdrop-blur-xl transition-all duration-300 ${
            isDark 
              ? 'bg-white/[0.04] border-white/10 shadow-inner text-neutral-300' 
              : 'bg-neutral-50/90 border-neutral-200/80 shadow-xs text-neutral-800'
          }`}>
            <ul className="space-y-2 text-xs leading-relaxed">
              {(isNotesExpanded ? releaseInfo.notes : releaseInfo.notes.slice(0, 2)).map((item, idx) => (
                <li key={idx} className="flex items-start space-x-2">
                  <span className="text-[#0071E3] font-bold text-sm leading-none mt-0.5">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>

            {releaseInfo.notes.length > 2 && (
              <button
                onClick={() => setIsNotesExpanded(!isNotesExpanded)}
                className="mt-2 text-xs font-semibold text-[#0071E3] hover:underline flex items-center space-x-1"
              >
                <span>{isNotesExpanded ? 'Show less' : '... more'}</span>
              </button>
            )}
          </div>
        </div>

        {/* ── 5. Preview Section (App Video & Real Screenshots in Correct Flow) ── */}
        <div className="py-3">
          <div className="px-5 pb-2.5 flex items-center justify-between">
            <h2 className="text-lg font-bold tracking-tight">Preview</h2>
            <span className={`text-[11px] font-medium ${isDark ? 'text-neutral-500' : 'text-neutral-400'}`}>
              Swipe for more
            </span>
          </div>

          <div className="flex space-x-3.5 overflow-x-auto px-5 pb-3 scrollbar-none snap-x snap-mandatory">
            {/* App Preview Video Card */}
            <div className={`snap-center flex-shrink-0 w-64 h-[440px] rounded-2xl overflow-hidden border shadow-lg relative flex flex-col ${
              isDark ? 'bg-black border-neutral-800' : 'bg-neutral-950 border-neutral-200'
            }`}>
              <div className="absolute top-3 left-3 z-20 flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/10 text-white text-[10px] font-bold">
                <Film className="w-3 h-3 text-red-500" />
                <span>App Video Preview</span>
              </div>
              <video
                src="/media/video_2026-10-14_00-44-53.mp4"
                controls
                playsInline
                preload="metadata"
                poster="/screenshots/photo_2026-10-14_02-15-30.jpg"
                className="w-full h-full object-cover"
              />
            </div>

            {/* Real App Screenshots Ordered by Priority */}
            {screenshots.map((s, idx) => (
              <div 
                key={idx}
                onClick={() => setActiveLightboxImage(s)}
                className={`snap-center flex-shrink-0 w-60 h-[440px] rounded-2xl overflow-hidden border shadow-md relative group cursor-pointer transition-transform duration-200 hover:scale-[1.01] ${
                  isDark ? 'bg-neutral-900 border-neutral-800' : 'bg-white border-neutral-200'
                }`}
              >
                <img 
                  src={s.url}
                  alt={s.title}
                  loading="lazy"
                  className="w-full h-full object-cover object-top"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity p-3.5 flex flex-col justify-end text-white">
                  <p className="text-xs font-bold leading-snug">{s.title}</p>
                  <p className="text-[10px] text-neutral-300 mt-0.5 line-clamp-2">{s.caption}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── 6. Information Section ── */}
        <div className={`px-5 py-4 border-t ${isDark ? 'border-neutral-800/60' : 'border-neutral-200/80'}`}>
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
              <span className="font-semibold text-right text-emerald-500 font-bold">Free</span>
            </div>
            <div className="py-2.5 flex justify-between">
              <span className={isDark ? 'text-neutral-500' : 'text-neutral-400'}>Copyright</span>
              <span className="font-medium text-right text-[11px] text-neutral-500">© 2026 FreeWatch Inc.</span>
            </div>
          </div>
        </div>

        {/* ── 7. Join our TikTok Community Bottom Sticky Dock ── */}
        <div className={`mt-auto sticky bottom-0 z-40 border-t backdrop-blur-xl px-4 py-3 flex items-center justify-between transition-colors ${
          isDark 
            ? 'bg-black/95 border-neutral-800 text-white' 
            : 'bg-white/95 border-neutral-200/90 text-neutral-900 shadow-[0_-4px_24px_rgba(0,0,0,0.06)]'
        }`}>
          <a 
            href="https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-3 flex-1 min-w-0 pr-3 group cursor-pointer"
          >
            {/* TikTok Icon Badge with dark styling and gradient pop */}
            <div className="w-10 h-10 rounded-xl bg-black flex items-center justify-center flex-shrink-0 shadow-md relative overflow-hidden border border-white/10 group-hover:scale-105 transition-transform">
              <svg className="w-5 h-5 fill-white" viewBox="0 0 24 24">
                <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64c.298-.002.595.042.88.13V9.4a6.33 6.33 0 0 0-1-.08A6.34 6.34 0 0 0 3 15.66a6.34 6.34 0 0 0 10.82 4.5 6.34 6.34 0 0 0 1.84-4.49V8.67a8.21 8.21 0 0 0 4.93 1.62V6.85a4.84 4.84 0 0 1-1-.16Z"/>
              </svg>
            </div>
            <div className="flex flex-col min-w-0">
              <span className="text-xs font-black tracking-tight flex items-center space-x-1.5 truncate">
                <span>Join our TikTok Community</span>
                <span className="inline-block w-1.5 h-1.5 rounded-full bg-[#FE2C55] animate-ping"></span>
              </span>
              <span className={`text-[11px] truncate font-medium ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>
                @freewatchmoviesug • Trailers & Drops
              </span>
            </div>
          </a>

          <a
            href="https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi"
            target="_blank"
            rel="noopener noreferrer"
            className="flex-shrink-0 px-4 py-2 rounded-full bg-[#FE2C55] hover:bg-[#e0264b] active:scale-95 text-white font-bold text-xs shadow-md transition-all flex items-center space-x-1.5"
          >
            <span>Follow</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>

      </div>

      {/* ── Screenshot Lightbox Modal ── */}
      {activeLightboxImage && (
        <div 
          onClick={() => setActiveLightboxImage(null)}
          className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4 cursor-pointer"
        >
          <div 
            onClick={(e) => e.stopPropagation()}
            className="relative max-w-sm w-full max-h-[90vh] flex flex-col items-center bg-black rounded-3xl overflow-hidden shadow-2xl border border-white/15"
          >
            <button
              onClick={() => setActiveLightboxImage(null)}
              className="absolute top-3 right-3 z-30 p-2 rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
            <img 
              src={activeLightboxImage.url}
              alt={activeLightboxImage.title}
              className="w-full h-auto max-h-[75vh] object-contain rounded-t-3xl"
            />
            <div className="w-full p-4 bg-neutral-950 text-white">
              <h4 className="text-sm font-bold">{activeLightboxImage.title}</h4>
              <p className="text-xs text-neutral-400 mt-0.5">{activeLightboxImage.caption}</p>
            </div>
          </div>
        </div>
      )}

      {/* ── Version History iOS Modal Sheet ── */}
      {showVersionHistory && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className={`w-full max-w-md rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl max-h-[80vh] flex flex-col ${
            isDark ? 'bg-[#1C1C1E] text-white' : 'bg-white text-[#1C1C1E]'
          }`}>
            <div className={`flex items-center justify-between pb-3 border-b ${isDark ? 'border-neutral-800' : 'border-neutral-200'}`}>
              <h3 className="text-lg font-bold">Version History</h3>
              <button 
                onClick={() => setShowVersionHistory(false)}
                className={`p-1 rounded-full ${isDark ? 'text-neutral-400 hover:text-white' : 'text-neutral-500 hover:text-neutral-900'}`}
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className={`overflow-y-auto divide-y py-3 space-y-4 ${isDark ? 'divide-neutral-800' : 'divide-neutral-100'}`}>
              <div>
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.57</span>
                  <span className={`text-xs ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>Just now</span>
                </div>
                <p className={`text-xs leading-relaxed ${isDark ? 'text-neutral-300' : 'text-neutral-600'}`}>
                  Permanent offline movie downloads, live chat reply alerts, auto-update prompt, and video player enhancements.
                </p>
              </div>

              <div className="pt-3">
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.56</span>
                  <span className={`text-xs ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>1w ago</span>
                </div>
                <p className={`text-xs leading-relaxed ${isDark ? 'text-neutral-300' : 'text-neutral-600'}`}>
                  Real-time live presence tracking, WhatsApp style support chat, and ban enforcement.
                </p>
              </div>

              <div className="pt-3">
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-bold text-sm">Version 1.0.50</span>
                  <span className={`text-xs ${isDark ? 'text-neutral-400' : 'text-neutral-500'}`}>2w ago</span>
                </div>
                <p className={`text-xs leading-relaxed ${isDark ? 'text-neutral-300' : 'text-neutral-600'}`}>
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
