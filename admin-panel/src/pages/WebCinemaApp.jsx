import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  Play, Download, Search, Tv, Smartphone, Film, Star, 
  Sparkles, ExternalLink, Info, X, ChevronRight, Volume2, 
  ShieldCheck, ArrowRight, Flame, Layers, Heart
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// High-impact fallback catalog if RTDB is initializing or offline
const INITIAL_CURATED_MOVIES = [
  {
    id: 101,
    title: 'K-Pop: Demon Hunters',
    vj: 'VJ Junior',
    category: 'Animation',
    image: 'https://image.tmdb.org/t/p/w780/hT3lELd865o8Z6t9f3sK5p8tL8m.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/hT3lELd865o8Z6t9f3sK5p8tL8m.jpg',
    rating: 8.9,
    year: '2025',
    synopsis: 'A world-renowned K-Pop girl group balances their secret lives as trained demon hunters while staging an international stadium tour.',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
  },
  {
    id: 102,
    title: 'Dune: Part Two',
    vj: 'VJ Jingo',
    category: 'Sci-Fi',
    image: 'https://image.tmdb.org/t/p/w780/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s520fff.jpg',
    rating: 9.2,
    year: '2024',
    synopsis: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
    streamUrl: ''
  },
  {
    id: 103,
    title: 'Fallout: New Dawn',
    vj: 'VJ Emmy',
    category: 'Series',
    image: 'https://image.tmdb.org/t/p/w780/AnsPtB9LzL58QfGz0Y5k1017r.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/AnsPtB9LzL58QfGz0Y5k1017r.jpg',
    rating: 8.8,
    year: '2024',
    synopsis: 'In a post-apocalyptic Los Angeles, citizens must live in underground bunkers to protect themselves from radiation, mutants, and bandits.',
    streamUrl: ''
  },
  {
    id: 104,
    title: 'Moana 2',
    vj: 'VJ Junior',
    category: 'Animation',
    image: 'https://image.tmdb.org/t/p/w780/4YZpsylmjHbqeWzjKpUEF8gcLUV.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/9nhjGaFLKtddDPtPaX5EmK2vYeS.jpg',
    rating: 8.4,
    year: '2024',
    synopsis: 'After receiving an unexpected call from her wayfinding ancestors, Moana journeys to the far seas of Oceania on an adventure unlike anything she has ever faced.',
    streamUrl: ''
  },
  {
    id: 105,
    title: 'Deadpool & Wolverine',
    vj: 'VJ Ice P',
    category: 'Action',
    image: 'https://image.tmdb.org/t/p/w780/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/yDHYTjA3R0ne82cu403zOzZqVht.jpg',
    rating: 9.0,
    year: '2024',
    synopsis: 'A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary behind him, until the TVA pulls him into a multiverse mission.',
    streamUrl: ''
  },
  {
    id: 106,
    title: 'Alien: Romulus',
    vj: 'VJ Junior',
    category: 'Sci-Fi',
    image: 'https://image.tmdb.org/t/p/w780/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg',
    rating: 8.6,
    year: '2024',
    synopsis: 'While scavenging the deep ends of a derelict space station, a group of young space colonizers come face to face with the most terrifying life form in the universe.',
    streamUrl: ''
  },
  {
    id: 107,
    title: 'House of the Dragon',
    vj: 'VJ Emmy',
    category: 'Series',
    image: 'https://image.tmdb.org/t/p/w780/t9Xke5724fqW3429IOP2093021.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/etj5CuMuam3hD9P8G4qy0938472.jpg',
    rating: 9.1,
    year: '2024',
    synopsis: 'The Targaryen dynasty is at the absolute apex of its power, with more than 15 dragons under their yoke, sparking an epic civil war.',
    streamUrl: ''
  },
  {
    id: 108,
    title: 'Inside Out 2',
    vj: 'VJ Junior',
    category: 'Animation',
    image: 'https://image.tmdb.org/t/p/w780/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/stKGOmPAg25spsj4O32z872390.jpg',
    rating: 8.7,
    year: '2024',
    synopsis: 'Joy, Sadness, Anger, Fear and Disgust have been running a successful operation, but suddenly find themselves grappling with new emotions: Anxiety, Envy, and Ennui.',
    streamUrl: ''
  }
];

export default function WebCinemaApp({ onNavigateToStore, onNavigateToAdmin }) {
  const [catalog, setCatalog] = useState(INITIAL_CURATED_MOVIES);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedVj, setSelectedVj] = useState('All');
  const [activeMovie, setActiveMovie] = useState(null);
  const [playingVideo, setPlayingVideo] = useState(null);
  const [resolvedStreamUrl, setResolvedStreamUrl] = useState('');
  const [resolvingStream, setResolvingStream] = useState(false);
  const [streamError, setStreamError] = useState(false);
  const [favorites, setFavorites] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_web_favs') || '[]');
    } catch (_) {
      return [];
    }
  });

  const searchInputRef = useRef(null);

  // Sync catalog from Firebase RTDB (munowatch/catalog)
  useEffect(() => {
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsubscribe = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists()) {
        const val = snapshot.val();
        let items = [];
        if (Array.isArray(val)) {
          items = val;
        } else if (typeof val === 'object' && val !== null) {
          items = Object.values(val);
        }

        if (items.length > 0) {
          const normalized = items.map((m, idx) => ({
            id: m.id || m.vid || `mw-${idx}`,
            title: m.title || m.video_title || 'Untitled Movie',
            vj: m.vj || m.vjname || m.vjName || 'VJ Junior',
            category: m.category || (m.series_code || m.is_series ? 'Series' : 'Movie'),
            image: m.image || m.thumbnail || m.poster || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop&q=80',
            backdrop: m.backdrop || m.cover || m.image || m.thumbnail || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
            rating: m.rating || (8.2 + ((idx % 15) / 10)).toFixed(1),
            year: m.year || m.release_year || '2024',
            synopsis: m.synopsis || m.description || m.storyline || `Enjoy ${m.title || 'this blockbuster'} in high definition with exclusive Luganda voice-over translation by ${m.vj || 'VJ Junior'}.`,
            streamUrl: m.playingurl || m.playingUrl || m.videoUrl || m.streamUrl || ''
          }));

          setCatalog(normalized);
        }
      }
    });

    return () => unsubscribe();
  }, []);

  // Featured billboard movie (picks top trending or first item)
  const heroMovie = useMemo(() => {
    if (catalog.length === 0) return INITIAL_CURATED_MOVIES[0];
    const animatedOrSciFi = catalog.find(m => /k-pop|dune|deadpool|fallout/i.test(m.title));
    return animatedOrSciFi || catalog[0];
  }, [catalog]);

  // Categories list
  const categories = useMemo(() => {
    const set = new Set(['All', 'Trending', 'Sci-Fi', 'Action', 'Series', 'Animation']);
    catalog.forEach(m => {
      if (m.category && m.category.length < 20) set.add(m.category);
    });
    return Array.from(set);
  }, [catalog]);

  // Distinct VJs list
  const vjs = useMemo(() => {
    const counts = {};
    catalog.forEach(m => {
      const v = (m.vj || 'VJ Universal').trim();
      counts[v] = (counts[v] || 0) + 1;
    });
    return ['All', ...Object.keys(counts).sort((a, b) => counts[b] - counts[a]).slice(0, 8)];
  }, [catalog]);

  // Filtered catalog
  const filteredCatalog = useMemo(() => {
    return catalog.filter(movie => {
      // Search query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = movie.title.toLowerCase().includes(q);
        const matchesVj = movie.vj.toLowerCase().includes(q);
        const matchesCategory = movie.category.toLowerCase().includes(q);
        if (!matchesTitle && !matchesVj && !matchesCategory) return false;
      }

      // VJ Filter
      if (selectedVj !== 'All' && movie.vj !== selectedVj) {
        return false;
      }

      // Category Filter
      if (selectedCategory === 'All') return true;
      if (selectedCategory === 'Trending') return true;
      return movie.category.toLowerCase().includes(selectedCategory.toLowerCase());
    });
  }, [catalog, searchQuery, selectedCategory, selectedVj]);

  // Rails
  const trendingRail = useMemo(() => catalog.slice(0, 10), [catalog]);
  const sciFiRail = useMemo(() => catalog.filter(m => /sci-fi|action|adventure|alien|dune/i.test(m.category + ' ' + m.title)).slice(0, 10), [catalog]);
  const seriesRail = useMemo(() => catalog.filter(m => /series|season|episode|tv/i.test(m.category + ' ' + m.title)).slice(0, 10), [catalog]);
  const animationRail = useMemo(() => catalog.filter(m => /animation|family|cartoon|anime|moana/i.test(m.category + ' ' + m.title)).slice(0, 10), [catalog]);

  // Stream Resolution & Playback Trigger
  const handlePlayMovie = async (movie) => {
    setPlayingVideo(movie);
    setResolvedStreamUrl('');
    setStreamError(false);
    setResolvingStream(true);

    // If movie already has a direct valid streamUrl
    if (movie.streamUrl && movie.streamUrl.startsWith('http')) {
      setResolvedStreamUrl(movie.streamUrl);
      setResolvingStream(false);
      return;
    }

    // Attempt to resolve from MunoWatch streaming API
    try {
      const vid = movie.id;
      // 1. Try public streaming endpoint
      const res = await fetch(`https://mumowatch.ai.studio/movie/${vid}`).catch(() => null);
      if (res && res.ok) {
        const data = await res.json();
        const url = data.playingurl || data.playingUrl || data.url;
        if (url && url.startsWith('http')) {
          setResolvedStreamUrl(url);
          setResolvingStream(false);
          return;
        }
      }
    } catch (_) {}

    // Fallback sample demo stream for smooth web browser preview
    setResolvedStreamUrl('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4');
    setResolvingStream(false);
  };

  const toggleFavorite = (movieId, e) => {
    if (e) e.stopPropagation();
    setFavorites(prev => {
      let next;
      if (prev.includes(movieId)) {
        next = prev.filter(id => id !== movieId);
      } else {
        next = [...prev, movieId];
      }
      try {
        localStorage.setItem('freewatch_web_favs', JSON.stringify(next));
      } catch (_) {}
      return next;
    });
  };

  const handleDownloadAppClick = () => {
    if (onNavigateToStore) {
      onNavigateToStore();
    } else {
      window.location.href = '/store';
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0A0C] text-slate-100 font-sans selection:bg-[#0071E3] selection:text-white">
      
      {/* ── 1. Top Navigation Bar ── */}
      <header className="sticky top-0 z-40 bg-[#0A0A0C]/85 backdrop-blur-xl border-b border-white/10 transition-all">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          
          {/* Logo & Brand */}
          <div className="flex items-center space-x-6">
            <div 
              onClick={() => { setSelectedCategory('All'); setSelectedVj('All'); setSearchQuery(''); }}
              className="flex items-center space-x-3 cursor-pointer group"
            >
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#0071E3] to-blue-400 p-0.5 shadow-lg shadow-blue-500/20 group-hover:scale-105 transition-transform">
                <img 
                  src="/app_icon.png" 
                  alt="FreeWatch" 
                  className="w-full h-full object-cover rounded-[10px]"
                  onError={(e) => {
                    e.target.onerror = null;
                    e.target.src = 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=64&auto=format&fit=crop&q=80';
                  }}
                />
              </div>
              <div className="flex flex-col">
                <span className="text-lg font-black tracking-tight text-white flex items-center gap-1.5">
                  FreeWatch
                  <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-blue-500/20 text-[#38bdf8] border border-blue-500/30">
                    CINEMA
                  </span>
                </span>
                <span className="text-[10px] text-slate-400 font-medium -mt-1">Luganda Dubbed Hub</span>
              </div>
            </div>

            {/* Nav Categories */}
            <nav className="hidden md:flex items-center space-x-1 text-sm font-semibold text-slate-300">
              {['All', 'Trending', 'Sci-Fi', 'Series', 'Animation'].map(cat => (
                <button
                  key={cat}
                  onClick={() => { setSelectedCategory(cat); setSelectedVj('All'); }}
                  className={`px-3 py-1.5 rounded-lg transition-colors ${
                    selectedCategory === cat 
                      ? 'text-white bg-white/10 font-bold' 
                      : 'hover:text-white hover:bg-white/5'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </nav>
          </div>

          {/* Search Box & Download App CTA */}
          <div className="flex items-center space-x-3">
            {/* Search Input */}
            <div className="relative hidden sm:block w-48 lg:w-72">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search movies, series, or VJ..."
                className="w-full pl-9 pr-4 py-2 bg-white/5 hover:bg-white/10 focus:bg-white/10 border border-white/10 rounded-full text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-[#0071E3] transition-all"
              />
              {searchQuery && (
                <button 
                  onClick={() => setSearchQuery('')}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 p-0.5 rounded-full text-slate-400 hover:text-white"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>

            {/* DOWNLOAD APP Button (Takes user to /store) */}
            <button
              onClick={handleDownloadAppClick}
              className="relative overflow-hidden px-4 py-2 rounded-full bg-gradient-to-r from-[#0071E3] to-[#00A3FF] hover:from-blue-600 hover:to-blue-500 active:scale-95 text-white font-bold text-xs shadow-lg shadow-blue-500/25 flex items-center space-x-2 transition-all cursor-pointer"
            >
              <Download className="w-4 h-4 stroke-[2.5]" />
              <span className="tracking-wide">Download App</span>
              <span className="hidden sm:inline-block text-[10px] px-1.5 py-0.5 rounded-full bg-white/20 font-mono">
                APK
              </span>
            </button>
          </div>

        </div>
      </header>

      {/* ── 2. Mobile Search Bar ── */}
      <div className="sm:hidden px-4 pt-3">
        <div className="relative w-full">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search Luganda movies, series, VJ..."
            className="w-full pl-9 pr-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-[#0071E3]"
          />
          {searchQuery && (
            <button 
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* ── 3. Featured Hero Billboard (when no active text search) ── */}
      {!searchQuery && (
        <section className="relative w-full h-[540px] lg:h-[620px] overflow-hidden">
          {/* Backdrop Image with gradient overlay */}
          <div className="absolute inset-0">
            <img 
              src={heroMovie.backdrop} 
              alt={heroMovie.title}
              className="w-full h-full object-cover object-center filter brightness-90 scale-105 animate-pulse"
              style={{ animationDuration: '8s' }}
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#0A0A0C] via-[#0A0A0C]/60 to-transparent"></div>
            <div className="absolute inset-0 bg-gradient-to-r from-[#0A0A0C] via-[#0A0A0C]/40 to-transparent"></div>
          </div>

          {/* Hero Content */}
          <div className="relative max-w-7xl mx-auto h-full px-4 sm:px-6 lg:px-8 flex flex-col justify-end pb-16 lg:pb-20">
            <div className="max-w-2xl space-y-3.5">
              
              {/* Badges */}
              <div className="flex flex-wrap items-center gap-2">
                <span className="px-2.5 py-1 rounded-full text-xs font-black uppercase tracking-wider bg-[#0071E3] text-white flex items-center gap-1 shadow-md">
                  <Flame className="w-3.5 h-3.5 fill-current" />
                  #1 Luganda Dubbed
                </span>
                <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30 flex items-center gap-1">
                  <Star className="w-3 h-3 fill-amber-300 text-amber-300" />
                  {heroMovie.rating} Rating
                </span>
                <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-white/10 text-slate-300 backdrop-blur-sm">
                  {heroMovie.category}
                </span>
                <span className="px-2 py-0.5 rounded text-xs font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  {heroMovie.vj}
                </span>
              </div>

              {/* Title */}
              <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black text-white tracking-tight leading-tight drop-shadow-lg">
                {heroMovie.title}
              </h1>

              {/* Synopsis */}
              <p className="text-xs sm:text-sm text-slate-300 line-clamp-3 max-w-xl leading-relaxed drop-shadow">
                {heroMovie.synopsis}
              </p>

              {/* Buttons */}
              <div className="flex items-center space-x-3 pt-2">
                <button
                  onClick={() => handlePlayMovie(heroMovie)}
                  className="px-6 py-3 rounded-full bg-white text-black hover:bg-slate-200 active:scale-95 font-bold text-sm shadow-xl flex items-center space-x-2 transition-all cursor-pointer"
                >
                  <Play className="w-4 h-4 fill-black" />
                  <span>Watch Now</span>
                </button>

                <button
                  onClick={() => setActiveMovie(heroMovie)}
                  className="px-5 py-3 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 text-white font-semibold text-sm backdrop-blur-md border border-white/15 flex items-center space-x-2 transition-all"
                >
                  <Info className="w-4 h-4" />
                  <span>Details</span>
                </button>

                <button
                  onClick={handleDownloadAppClick}
                  className="hidden sm:flex px-5 py-3 rounded-full bg-blue-600/20 hover:bg-blue-600/30 border border-blue-500/30 text-[#38bdf8] font-semibold text-sm items-center space-x-2 transition-all"
                >
                  <Tv className="w-4 h-4" />
                  <span>Get for Android TV & Phone</span>
                </button>
              </div>

            </div>
          </div>
        </section>
      )}

      {/* ── 4. Dubbing VJs Filter Bar ── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex items-center justify-between pb-2">
          <h3 className="text-xs font-black uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
            <span>Filter by Dubbing VJ</span>
          </h3>
          <span className="text-[11px] text-slate-500">Popular Translators</span>
        </div>

        <div className="flex items-center space-x-2 overflow-x-auto pb-2 scrollbar-none">
          {vjs.map(vj => (
            <button
              key={vj}
              onClick={() => setSelectedVj(vj)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all border ${
                selectedVj === vj
                  ? 'bg-[#0071E3] text-white border-[#0071E3] shadow-md shadow-blue-500/20'
                  : 'bg-white/5 hover:bg-white/10 text-slate-300 border-white/10'
              }`}
            >
              {vj}
            </button>
          ))}
        </div>
      </section>

      {/* ── 5. Main Content Area ── */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-10">

        {/* Search Results Display */}
        {searchQuery && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <span>Search results for "{searchQuery}"</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-white/10 text-slate-400">
                  {filteredCatalog.length} titles
                </span>
              </h2>
              <button 
                onClick={() => setSearchQuery('')}
                className="text-xs text-[#0071E3] hover:underline"
              >
                Clear Search
              </button>
            </div>

            {filteredCatalog.length === 0 ? (
              <div className="p-12 text-center bg-white/[0.02] rounded-2xl border border-white/10 space-y-3">
                <Film className="w-12 h-12 text-slate-600 mx-auto" />
                <p className="text-base font-bold text-white">No movies found matching "{searchQuery}"</p>
                <p className="text-xs text-slate-400">Try searching for a different VJ, movie title, or genre.</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 sm:gap-4">
                {filteredCatalog.map(movie => (
                  <MovieCard 
                    key={movie.id}
                    movie={movie}
                    isFavorite={favorites.includes(movie.id)}
                    onToggleFavorite={(e) => toggleFavorite(movie.id, e)}
                    onPlay={() => handlePlayMovie(movie)}
                    onDetails={() => setActiveMovie(movie)}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Normal Rails View (when no active text search) */}
        {!searchQuery && (
          <>
            {/* Rail 1: Trending Luganda Movies */}
            <MovieRail 
              title="🔥 Trending Luganda Blockbusters" 
              subtitle="Most popular voice-over translations this week"
              movies={trendingRail}
              favorites={favorites}
              onToggleFavorite={toggleFavorite}
              onPlay={handlePlayMovie}
              onDetails={setActiveMovie}
            />

            {/* In-Feed Banner: TV & Phone App Download CTA */}
            <div className="rounded-3xl p-6 sm:p-8 bg-gradient-to-r from-blue-950/70 via-indigo-950/50 to-slate-900 border border-blue-500/20 shadow-2xl relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="absolute right-0 top-0 bottom-0 w-1/2 bg-radial from-blue-500/10 to-transparent pointer-events-none"></div>
              
              <div className="space-y-2 max-w-xl z-10 text-center md:text-left">
                <span className="inline-flex items-center space-x-1 px-3 py-1 rounded-full text-xs font-bold bg-[#0071E3]/20 text-[#38bdf8] border border-blue-500/30">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>FreeWatch Mobile & Android TV Edition</span>
                </span>
                <h3 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                  Stream Without Limits on Android TV & Phone
                </h3>
                <p className="text-xs sm:text-sm text-slate-300">
                  Download the official native application for 4K streaming, offline file downloads, and remote D-Pad controls.
                </p>
              </div>

              <div className="flex flex-col sm:flex-row items-center gap-3 z-10 shrink-0 w-full md:w-auto">
                <button
                  onClick={handleDownloadAppClick}
                  className="w-full sm:w-auto px-6 py-3.5 rounded-2xl bg-[#0071E3] hover:bg-blue-600 active:scale-95 text-white font-bold text-xs shadow-lg flex items-center justify-center space-x-2 transition-all cursor-pointer"
                >
                  <Smartphone className="w-4 h-4" />
                  <span>Download for Phone</span>
                </button>

                <button
                  onClick={handleDownloadAppClick}
                  className="w-full sm:w-auto px-6 py-3.5 rounded-2xl bg-white/10 hover:bg-white/20 active:scale-95 text-white font-bold text-xs border border-white/20 flex items-center justify-center space-x-2 transition-all cursor-pointer"
                >
                  <Tv className="w-4 h-4 text-emerald-400" />
                  <span>Download for TV</span>
                </button>
              </div>
            </div>

            {/* Rail 2: Sci-Fi & Action Blockbusters */}
            <MovieRail 
              title="🚀 Action & Sci-Fi" 
              subtitle="High-octane excitement translated in Luganda"
              movies={sciFiRail}
              favorites={favorites}
              onToggleFavorite={toggleFavorite}
              onPlay={handlePlayMovie}
              onDetails={setActiveMovie}
            />

            {/* Rail 3: Series Collections */}
            <MovieRail 
              title="🍿 Luganda Translated Series" 
              subtitle="Full multi-episode seasons with voice-over"
              movies={seriesRail}
              favorites={favorites}
              onToggleFavorite={toggleFavorite}
              onPlay={handlePlayMovie}
              onDetails={setActiveMovie}
            />

            {/* Rail 4: Animation & Family */}
            <MovieRail 
              title="🎨 Animation & Family" 
              subtitle="Fun and adventure for the whole family"
              movies={animationRail}
              favorites={favorites}
              onToggleFavorite={toggleFavorite}
              onPlay={handlePlayMovie}
              onDetails={setActiveMovie}
            />
          </>
        )}

      </main>

      {/* ── 6. Fullscreen Video Player Modal ── */}
      {playingVideo && (
        <div 
          className="fixed inset-0 z-50 bg-black/95 backdrop-blur-xl flex flex-col justify-between"
          onClick={() => setPlayingVideo(null)}
        >
          {/* Player Header Bar */}
          <div 
            onClick={(e) => e.stopPropagation()}
            className="px-6 py-4 flex items-center justify-between bg-gradient-to-b from-black/90 to-transparent z-10"
          >
            <div className="flex items-center space-x-3">
              <span className="px-2 py-0.5 rounded text-[10px] font-black uppercase bg-[#0071E3] text-white">
                PLAYING
              </span>
              <div>
                <h3 className="text-sm font-bold text-white truncate">{playingVideo.title}</h3>
                <span className="text-xs text-slate-400">{playingVideo.vj} • {playingVideo.category}</span>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <button
                onClick={handleDownloadAppClick}
                className="hidden sm:flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-white/10 hover:bg-white/20 text-xs font-semibold text-slate-200 border border-white/10"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Get on App</span>
              </button>

              <button
                onClick={() => setPlayingVideo(null)}
                className="p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
                title="Close Player"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* HTML5 Video Screen */}
          <div 
            onClick={(e) => e.stopPropagation()}
            className="flex-1 flex items-center justify-center p-2 sm:p-6"
          >
            <div className="w-full max-w-5xl aspect-video rounded-2xl overflow-hidden bg-black shadow-2xl border border-white/10 relative flex items-center justify-center">
              {resolvingStream ? (
                <div className="flex flex-col items-center space-y-3">
                  <div className="w-10 h-10 border-4 border-[#0071E3] border-t-transparent rounded-full animate-spin"></div>
                  <span className="text-xs font-semibold text-slate-300">Connecting to FreeWatch stream...</span>
                </div>
              ) : resolvedStreamUrl ? (
                <video
                  src={resolvedStreamUrl}
                  controls
                  autoPlay
                  playsInline
                  poster={playingVideo.backdrop || playingVideo.image}
                  className="w-full h-full object-contain"
                  onError={() => setStreamError(true)}
                />
              ) : (
                <div className="p-8 text-center space-y-3 max-w-md">
                  <Film className="w-12 h-12 text-slate-500 mx-auto" />
                  <p className="text-sm font-bold text-white">Streaming Optimization</p>
                  <p className="text-xs text-slate-400">
                    This stream is optimized for the FreeWatch native TV and Mobile application.
                  </p>
                  <button
                    onClick={handleDownloadAppClick}
                    className="px-5 py-2.5 rounded-full bg-[#0071E3] text-white font-bold text-xs shadow-md"
                  >
                    Open in FreeWatch App
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Player Bottom Footer */}
          <div 
            onClick={(e) => e.stopPropagation()}
            className="px-6 py-4 flex flex-col sm:flex-row items-center justify-between gap-2 bg-gradient-to-t from-black/90 to-transparent text-xs text-slate-400"
          >
            <span>Audio: Original Track with Live Luganda Voice-Over ({playingVideo.vj})</span>
            <div className="flex items-center space-x-3">
              <span className="text-emerald-400 font-semibold">● HD 1080p Web Stream</span>
              <button 
                onClick={handleDownloadAppClick}
                className="text-[#38bdf8] hover:underline font-semibold"
              >
                Switch to Android TV
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── 7. Movie Details Modal ── */}
      {activeMovie && (
        <div 
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4"
          onClick={() => setActiveMovie(null)}
        >
          <div 
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-xl bg-[#141418] rounded-3xl overflow-hidden border border-white/10 shadow-2xl relative"
          >
            <button
              onClick={() => setActiveMovie(null)}
              className="absolute top-4 right-4 z-20 p-2 rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Poster / Backdrop */}
            <div className="relative h-64 w-full">
              <img 
                src={activeMovie.backdrop || activeMovie.image}
                alt={activeMovie.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#141418] via-transparent to-transparent"></div>
              
              <div className="absolute bottom-4 left-6 right-6 flex items-end justify-between">
                <div>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#0071E3] text-white">
                    {activeMovie.category}
                  </span>
                  <h3 className="text-2xl font-black text-white mt-1 drop-shadow-md">{activeMovie.title}</h3>
                </div>
              </div>
            </div>

            {/* Body */}
            <div className="p-6 space-y-4">
              <div className="flex items-center space-x-4 text-xs font-semibold text-slate-300">
                <span className="text-amber-400 flex items-center gap-1">
                  <Star className="w-3.5 h-3.5 fill-current" />
                  {activeMovie.rating}
                </span>
                <span>{activeMovie.year}</span>
                <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-bold border border-emerald-500/30">
                  {activeMovie.vj}
                </span>
                <span>Full HD</span>
              </div>

              <p className="text-xs text-slate-300 leading-relaxed">
                {activeMovie.synopsis}
              </p>

              <div className="pt-2 flex items-center space-x-3">
                <button
                  onClick={() => {
                    const m = activeMovie;
                    setActiveMovie(null);
                    handlePlayMovie(m);
                  }}
                  className="flex-1 py-3 rounded-2xl bg-white text-black hover:bg-slate-200 active:scale-95 font-bold text-xs shadow-md flex items-center justify-center space-x-2 transition-all cursor-pointer"
                >
                  <Play className="w-4 h-4 fill-black" />
                  <span>Watch Web Preview</span>
                </button>

                <button
                  onClick={() => {
                    setActiveMovie(null);
                    handleDownloadAppClick();
                  }}
                  className="flex-1 py-3 rounded-2xl bg-[#0071E3] hover:bg-blue-600 active:scale-95 text-white font-bold text-xs shadow-md flex items-center justify-center space-x-2 transition-all cursor-pointer"
                >
                  <Download className="w-4 h-4" />
                  <span>Download Full in App</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── 8. Footer ── */}
      <footer className="border-t border-white/10 bg-[#070709] mt-16 py-12 text-slate-400 text-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-8">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-lg bg-blue-600 p-1 flex items-center justify-center text-white font-black text-sm">
                FW
              </div>
              <span className="font-bold text-white text-sm">FreeWatch Web Cinema</span>
            </div>

            <div className="flex items-center space-x-4">
              <button 
                onClick={handleDownloadAppClick}
                className="hover:text-white transition-colors flex items-center space-x-1"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Store Listing</span>
              </button>

              <a 
                href="https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                TikTok Community
              </a>

              {onNavigateToAdmin && (
                <button
                  onClick={onNavigateToAdmin}
                  className="text-slate-600 hover:text-slate-400 transition-colors"
                >
                  Admin
                </button>
              )}
            </div>
          </div>

          <div className="border-t border-white/5 pt-6 flex flex-col sm:flex-row items-center justify-between gap-2 text-[11px] text-slate-500">
            <p>© 2026 FreeWatch Inc. All rights reserved. Built for Luganda movie fans worldwide.</p>
            <p>Official releases available at freewatchug.online/store</p>
          </div>
        </div>
      </footer>

    </div>
  );
}

// ── Sub-Component: Movie Rail ──
function MovieRail({ title, subtitle, movies, favorites, onToggleFavorite, onPlay, onDetails }) {
  if (!movies || movies.length === 0) return null;

  return (
    <section className="space-y-3">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg sm:text-xl font-black text-white tracking-tight">{title}</h2>
          {subtitle && <p className="text-xs text-slate-400">{subtitle}</p>}
        </div>
        <span className="text-xs font-semibold text-slate-500">Swipe for more</span>
      </div>

      <div className="flex space-x-3.5 overflow-x-auto pb-4 pt-1 scrollbar-none snap-x snap-mandatory">
        {movies.map(movie => (
          <div key={movie.id} className="snap-start flex-shrink-0 w-36 sm:w-44">
            <MovieCard 
              movie={movie}
              isFavorite={favorites.includes(movie.id)}
              onToggleFavorite={(e) => onToggleFavorite(movie.id, e)}
              onPlay={() => onPlay(movie)}
              onDetails={() => onDetails(movie)}
            />
          </div>
        ))}
      </div>
    </section>
  );
}

// ── Sub-Component: Individual Movie Card ──
function MovieCard({ movie, isFavorite, onToggleFavorite, onPlay, onDetails }) {
  return (
    <div 
      onClick={onDetails}
      className="group relative flex flex-col cursor-pointer transition-transform duration-200 hover:-translate-y-1"
    >
      {/* Poster Image Frame */}
      <div className="aspect-[2/3] w-full rounded-2xl overflow-hidden bg-slate-800 border border-white/10 shadow-lg relative">
        <img 
          src={movie.image} 
          alt={movie.title}
          loading="lazy"
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          onError={(e) => {
            e.target.onerror = null;
            e.target.src = 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&auto=format&fit=crop&q=80';
          }}
        />

        {/* Favorite Heart Button */}
        <button
          onClick={onToggleFavorite}
          className={`absolute top-2 right-2 z-10 p-1.5 rounded-full backdrop-blur-md transition-all ${
            isFavorite 
              ? 'bg-red-500 text-white' 
              : 'bg-black/50 text-white/70 hover:text-white hover:bg-black/70'
          }`}
          title="Favorite"
        >
          <Heart className={`w-3.5 h-3.5 ${isFavorite ? 'fill-white' : ''}`} />
        </button>

        {/* VJ Tag */}
        <div className="absolute top-2 left-2 z-10">
          <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-black/70 text-emerald-400 backdrop-blur-md border border-white/10">
            {movie.vj}
          </span>
        </div>

        {/* Play Overlay On Hover */}
        <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2 p-2">
          <button
            onClick={(e) => {
              e.stopPropagation();
              onPlay();
            }}
            className="p-3 rounded-full bg-[#0071E3] hover:bg-blue-600 text-white shadow-xl transition-transform hover:scale-110 active:scale-95"
            title="Watch Now"
          >
            <Play className="w-5 h-5 fill-white" />
          </button>
        </div>
      </div>

      {/* Meta text */}
      <div className="mt-2 space-y-0.5">
        <h4 className="text-xs font-bold text-white truncate leading-tight group-hover:text-[#38bdf8] transition-colors">
          {movie.title}
        </h4>
        <div className="flex items-center justify-between text-[11px] text-slate-400">
          <span className="truncate">{movie.category}</span>
          <span className="flex items-center gap-0.5 text-amber-400 font-semibold shrink-0">
            <Star className="w-3 h-3 fill-current" />
            {movie.rating}
          </span>
        </div>
      </div>
    </div>
  );
}
