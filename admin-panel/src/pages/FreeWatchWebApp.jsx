import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  Play, Search, Bell, User, Star, Sparkles, Tv, Film, 
  Flame, Heart, Ghost, Zap, Rocket, ChevronRight, X, 
  ArrowLeft, Volume2, Share2, Plus, Check, Clock, Eye,
  ExternalLink, Mic, Grid, Info, ShieldCheck, Download
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// High-impact initial MunoWatch Luganda catalog (synced immediately with RTDB)
const INITIAL_MOVIES = [
  {
    id: 67342,
    title: 'Self Made: Inspired by the Life of Madam C.J. Walker',
    vj: 'VJ Aaron',
    category: 'Series',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg',
    rating: 8.8,
    year: '2024',
    runtime: '46m',
    isTv: true,
    seriesCode: '26058',
    synopsis: 'The inspiring story of trailblazing African American entrepreneur Madam C.J. Walker who built a haircare empire and became America\'s first self-made female millionaire.',
    streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4',
    episodes: [
      { id: 67342, episodeNumber: 1, name: 'The Fight for the Crown', streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4' },
      { id: 67343, episodeNumber: 2, name: 'Bootstrapping', streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4' }
    ]
  },
  {
    id: 67185,
    title: 'Just Say It: Lillian Mbabazi',
    vj: 'VJ Junior',
    category: 'Latest on FreeWatch',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg',
    rating: 8.5,
    year: '2024',
    runtime: '1h 50m',
    isTv: false,
    synopsis: 'Beyond the Music: Frank Ntambi sits down with Lillian Mbabazi for an intimate exploration of her musical legacy, resilience, and personal triumphs.',
    streamUrl: 'https://munotek-vault.b-cdn.net/ugmvs/ug2/Final_JSI_2_2.mp4'
  },
  {
    id: 101,
    title: 'K-Pop: Demon Hunters',
    vj: 'VJ Junior',
    category: 'Animation',
    image: 'https://image.tmdb.org/t/p/w780/hT3lELd865o8Z6t9f3sK5p8tL8m.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/hT3lELd865o8Z6t9f3sK5p8tL8m.jpg',
    rating: 8.9,
    year: '2025',
    runtime: '1h 44m',
    isTv: false,
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
    runtime: '2h 46m',
    isTv: false,
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
    runtime: '55m',
    isTv: true,
    seriesCode: 'fallout-s1',
    synopsis: 'In a post-apocalyptic Los Angeles, citizens must live in underground bunkers to protect themselves from radiation, mutants, and bandits.',
    streamUrl: '',
    episodes: [
      { id: 201, episodeNumber: 1, name: 'The End', streamUrl: '' },
      { id: 202, episodeNumber: 2, name: 'The Target', streamUrl: '' }
    ]
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
    runtime: '1h 40m',
    isTv: false,
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
    runtime: '2h 07m',
    isTv: false,
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
    runtime: '1h 59m',
    isTv: false,
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
    runtime: '1h 05m',
    isTv: true,
    seriesCode: 'hotd-s2',
    synopsis: 'The Targaryen dynasty is at the absolute apex of its power, with more than 15 dragons under their yoke, sparking an epic civil war.',
    streamUrl: '',
    episodes: [
      { id: 301, episodeNumber: 1, name: 'A Son for a Son', streamUrl: '' },
      { id: 302, episodeNumber: 2, name: 'Rhaenyra the Cruel', streamUrl: '' }
    ]
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
    runtime: '1h 36m',
    isTv: false,
    synopsis: 'Joy, Sadness, Anger, Fear and Disgust have been running a successful operation, but suddenly find themselves grappling with new emotions: Anxiety, Envy, and Ennui.',
    streamUrl: ''
  }
];

export default function FreeWatchWebApp({ onNavigateToStore }) {
  const [catalog, setCatalog] = useState(INITIAL_MOVIES);
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'search' | 'vjs' | 'series'
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedVj, setSelectedVj] = useState('All');
  const [gridCategory, setGridCategory] = useState(null); // When "See All" is clicked
  const [selectedMovie, setSelectedMovie] = useState(null);
  const [activeStreamUrl, setActiveStreamUrl] = useState('');
  const [resolvingStream, setResolvingStream] = useState(false);
  const [myList, setMyList] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_my_list') || '[]');
    } catch (_) {
      return [];
    }
  });

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
          const blocklist = ['eps', 'episode', 'untitled', 'movie', 'null', 'none'];
          const normalized = items
            .filter(m => {
              const t = (m.title || m.video_title || '').toLowerCase().trim();
              return t && !blocklist.includes(t) && !/^(?:eps?|episode)\s*\d*$/i.test(t);
            })
            .map((m, idx) => {
              const rawVj = (m.vj || m.vjname || m.vjName || '').trim();
              const isUniversal = rawVj.toLowerCase().includes('universal') || !rawVj;
              const vj = isUniversal ? 'VJ Junior' : (rawVj.toUpperCase().startsWith('VJ') ? rawVj : `VJ ${rawVj}`);

              return {
                id: m.id || m.vid || `fw-${idx}`,
                title: m.title || m.video_title || 'Untitled Movie',
                vj,
                category: m.category || (m.series_code || m.is_series ? 'Series' : 'Movie'),
                image: m.image || m.thumbnail || m.poster || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop&q=80',
                backdrop: m.backdrop || m.cover || m.image || m.thumbnail || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
                rating: m.rating || (8.2 + ((idx % 15) / 10)).toFixed(1),
                year: m.year || m.release_year || '2024',
                runtime: m.duration || '1h 45m',
                isTv: Boolean(m.is_series || m.series_code || (m.category && m.category.toLowerCase().includes('series'))),
                seriesCode: m.series_code || '',
                synopsis: m.synopsis || m.description || `Enjoy ${m.title || 'this release'} in high definition with exclusive Luganda voice-over translation by ${vj}.`,
                streamUrl: m.playingurl || m.playingUrl || m.videoUrl || m.streamUrl || ''
              };
            });

          if (normalized.length > 0) {
            setCatalog(normalized);
          }
        }
      }
    });

    return () => unsubscribe();
  }, []);

  // Save favorites / my list to local storage
  const toggleMyList = (movie) => {
    setMyList((prev) => {
      const exists = prev.some((m) => m.id === movie.id);
      const updated = exists ? prev.filter((m) => m.id !== movie.id) : [...prev, movie];
      try {
        localStorage.setItem('freewatch_my_list', JSON.stringify(updated));
      } catch (_) {}
      return updated;
    });
  };

  // Featured billboard movie (Hero)
  const heroMovie = useMemo(() => {
    if (catalog.length === 0) return INITIAL_MOVIES[0];
    const preferred = catalog.find(m => /self made|dune|deadpool|k-pop|moana/i.test(m.title));
    return preferred || catalog[0];
  }, [catalog]);

  // Section rails exactly matching the FreeWatch app
  const rails = useMemo(() => {
    const latest = catalog.filter(m => !m.isTv).slice(0, 15);
    const trending = [...catalog].sort((a, b) => (b.rating || 0) - (a.rating || 0)).slice(0, 15);
    const series = catalog.filter(m => m.isTv || /series|season|episode/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const action = catalog.filter(m => /action|war|agent|fighter|gun/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const sciFi = catalog.filter(m => /sci-fi|alien|future|dune|space/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const romance = catalog.filter(m => /romance|love|heart|wedding/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const horror = catalog.filter(m => /horror|demon|evil|dead|ghost|conjuring/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const drama = catalog.filter(m => /drama|story|life|biography|fight/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const animation = catalog.filter(m => /animation|cartoon|k-pop|moana|inside out/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const family = catalog.filter(m => /family|adventure|kids|comedy/i.test(m.category + ' ' + m.title)).slice(0, 15);

    return [
      { title: 'Latest on FreeWatch', icon: Sparkles, color: '#38BDF8', movies: latest.length ? latest : catalog.slice(0, 10) },
      { title: 'Trending', icon: Flame, color: '#EF4444', movies: trending.length ? trending : catalog.slice(0, 10) },
      { title: 'TV Series', icon: Tv, color: '#8B5CF6', movies: series.length ? series : catalog.slice(0, 8) },
      { title: 'Action', icon: Zap, color: '#F59E0B', movies: action.length ? action : catalog.slice(0, 8) },
      { title: 'Sci-Fi', icon: Rocket, color: '#10B981', movies: sciFi.length ? sciFi : catalog.slice(0, 8) },
      { title: 'Romance', icon: Heart, color: '#EC4899', movies: romance.length ? romance : catalog.slice(0, 8) },
      { title: 'Horror', icon: Ghost, color: '#6366F1', movies: horror.length ? horror : catalog.slice(0, 8) },
      { title: 'Drama', icon: Film, color: '#EAB308', movies: drama.length ? drama : catalog.slice(0, 8) },
      { title: 'Animation', icon: Film, color: '#06B6D4', movies: animation.length ? animation : catalog.slice(0, 8) },
      { title: 'Family', icon: Film, color: '#14B8A6', movies: family.length ? family : catalog.slice(0, 8) },
    ];
  }, [catalog]);

  // VJ list with actual movie counts
  const vjsList = useMemo(() => {
    const counts = {};
    catalog.forEach(m => {
      const v = (m.vj || 'VJ Junior').trim();
      counts[v] = (counts[v] || 0) + 1;
    });
    return Object.entries(counts)
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count);
  }, [catalog]);

  // Search Results
  const searchResults = useMemo(() => {
    if (!searchQuery.trim()) return catalog;
    const q = searchQuery.toLowerCase().trim();
    return catalog.filter(m => 
      m.title.toLowerCase().includes(q) ||
      m.vj.toLowerCase().includes(q) ||
      (m.category && m.category.toLowerCase().includes(q))
    );
  }, [catalog, searchQuery]);

  // Handle Play Stream
  const handlePlay = async (movie) => {
    setSelectedMovie(movie);
    setActiveStreamUrl('');
    setResolvingStream(true);

    if (movie.streamUrl && movie.streamUrl.startsWith('http')) {
      setActiveStreamUrl(movie.streamUrl);
      setResolvingStream(false);
      return;
    }

    // Direct lookup on MunoWatch API
    try {
      const res = await fetch(`https://mumowatch.ai.studio/movie/${movie.id}`).catch(() => null);
      if (res && res.ok) {
        const data = await res.json();
        const url = data.playingurl || data.playingUrl || data.url;
        if (url && url.startsWith('http')) {
          setActiveStreamUrl(url);
          setResolvingStream(false);
          return;
        }
      }
    } catch (_) {}

    // Fallback sample stream if demo item
    setActiveStreamUrl('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    setResolvingStream(false);
  };

  return (
    <div className="min-h-screen bg-[#000000] text-white flex flex-col font-sans select-none antialiased">
      {/* ── 1. Top App Bar (Exact FreeWatch branding & tabs) ────────────────── */}
      <header className="sticky top-0 z-50 bg-[#000000]/90 backdrop-blur-xl border-b border-white/5 px-4 md:px-8 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-6">
          {/* Logo */}
          <div 
            onClick={() => { setActiveTab('home'); setGridCategory(null); }}
            className="flex items-center gap-2 cursor-pointer group"
          >
            <div className="w-8 h-8 rounded-lg bg-[#E50914] flex items-center justify-center shadow-lg shadow-[#E50914]/30 group-hover:scale-105 transition-transform">
              <Play className="w-4 h-4 text-white fill-white ml-0.5" />
            </div>
            <span className="text-xl font-black tracking-tight text-white flex items-center">
              FreeWatch
              <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] ml-1"></span>
            </span>
          </div>

          {/* Nav Tabs */}
          <nav className="hidden md:flex items-center gap-1 text-sm font-semibold text-[#9AA0B0]">
            {[
              { id: 'home', label: 'Home' },
              { id: 'series', label: 'TV Series' },
              { id: 'vjs', label: 'VJs' },
              { id: 'search', label: 'Search' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => { setActiveTab(tab.id); setGridCategory(null); }}
                className={`px-3.5 py-1.5 rounded-full transition-colors ${
                  activeTab === tab.id && !gridCategory
                    ? 'text-white bg-white/10 font-bold' 
                    : 'hover:text-white hover:bg-white/5'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        {/* Right Actions */}
        <div className="flex items-center gap-3">
          <button
            onClick={() => { setActiveTab('search'); setGridCategory(null); }}
            className="w-9 h-9 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 flex items-center justify-center text-white transition-colors"
            title="Search"
          >
            <Search className="w-4 h-4" />
          </button>

          {onNavigateToStore && (
            <button
              onClick={onNavigateToStore}
              className="hidden sm:flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-[#00E676]/10 text-[#00E676] hover:bg-[#00E676]/20 border border-[#00E676]/30 text-xs font-bold transition-colors"
            >
              <Download className="w-3.5 h-3.5" />
              Download App
            </button>
          )}

          <div className="w-9 h-9 rounded-full bg-[#14161C] border border-white/10 flex items-center justify-center text-[#9AA0B0]">
            <User className="w-4 h-4 text-white" />
          </div>
        </div>
      </header>

      {/* ── 2. Main Content Body ───────────────────────────────────────────── */}
      <main className="flex-1 pb-24">
        {/* VIEW A: Search Screen */}
        {activeTab === 'search' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-4 md:px-8 pt-6">
            {/* Search Input Bar */}
            <div className="relative mb-8">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#9AA0B0]" />
              <input 
                type="text"
                autoFocus
                placeholder="Search movies, TV series, or VJ name (e.g. VJ Junior, Spider-Man)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3.5 rounded-2xl bg-[#0C0D0F] border border-white/10 text-white placeholder-[#555B6B] text-base focus:outline-none focus:border-[#00E676] transition-colors"
              />
              {searchQuery && (
                <button 
                  onClick={() => setSearchQuery('')}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9AA0B0] hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold tracking-tight">
                {searchQuery ? `Search Results for "${searchQuery}"` : 'Browse Catalog'}
              </h2>
              <span className="text-xs text-[#9AA0B0] bg-white/5 px-2.5 py-1 rounded-lg border border-white/10">
                {searchResults.length} movies
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3.5 md:gap-4">
              {searchResults.map((movie) => (
                <MovieCard key={movie.id} movie={movie} onClick={() => setSelectedMovie(movie)} />
              ))}
            </div>
          </div>
        )}

        {/* VIEW B: VJs Screen */}
        {activeTab === 'vjs' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-4 md:px-8 pt-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h1 className="text-2xl font-black tracking-tight flex items-center gap-2">
                  <Mic className="w-6 h-6 text-[#8B5CF6]" />
                  Luganda Translators (VJs)
                </h1>
                <p className="text-sm text-[#9AA0B0] mt-1">Select your favorite voice-over artist to stream their catalog</p>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 mb-10">
              {vjsList.map(({ name, count }) => (
                <div
                  key={name}
                  onClick={() => setSelectedVj(selectedVj === name ? 'All' : name)}
                  className={`p-4 rounded-2xl border cursor-pointer transition-all ${
                    selectedVj === name 
                      ? 'bg-[#8B5CF6]/20 border-[#8B5CF6] shadow-lg shadow-[#8B5CF6]/20 scale-102' 
                      : 'bg-[#0C0D0F] border-white/5 hover:border-white/20'
                  }`}
                >
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#8B5CF6] to-[#6D28D9] flex items-center justify-center font-bold text-lg mb-3 shadow-md">
                    {name.replace('VJ ', '').charAt(0)}
                  </div>
                  <h3 className="font-bold text-white text-base">{name}</h3>
                  <span className="text-xs text-[#9AA0B0]">{count} Translated Movies</span>
                </div>
              ))}
            </div>

            {/* Movies by selected VJ */}
            {selectedVj !== 'All' && (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-bold flex items-center gap-2">
                    Movies Translated by {selectedVj}
                  </h2>
                  <button onClick={() => setSelectedVj('All')} className="text-xs text-[#00E676] hover:underline">
                    View All VJs
                  </button>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3.5 md:gap-4">
                  {catalog.filter(m => m.vj === selectedVj).map(movie => (
                    <MovieCard key={movie.id} movie={movie} onClick={() => setSelectedMovie(movie)} />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* VIEW C: "See All" Grid View */}
        {gridCategory && (
          <div className="max-w-6xl mx-auto px-4 md:px-8 pt-6">
            <div className="flex items-center justify-between mb-6">
              <button
                onClick={() => setGridCategory(null)}
                className="flex items-center gap-2 text-sm font-bold text-[#9AA0B0] hover:text-white px-3.5 py-1.5 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Back to Home
              </button>
              <h1 className="text-xl font-black text-white">{gridCategory.title}</h1>
              <span className="text-xs text-[#9AA0B0] bg-white/5 px-2.5 py-1 rounded-lg border border-white/10">
                {gridCategory.movies.length} items
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3.5 md:gap-4">
              {gridCategory.movies.map((movie) => (
                <MovieCard key={movie.id} movie={movie} onClick={() => setSelectedMovie(movie)} />
              ))}
            </div>
          </div>
        )}

        {/* VIEW D: Home Feed (Default) */}
        {activeTab === 'home' && !gridCategory && (
          <>
            {/* ── Hero Billboard ────────────────────────────────────────── */}
            <div className="relative w-full h-[480px] md:h-[560px] overflow-hidden">
              <img 
                src={heroMovie.backdrop || heroMovie.image}
                alt={heroMovie.title}
                className="w-full h-full object-cover object-center transform scale-105"
              />
              {/* Cinema vignette gradients */}
              <div className="absolute inset-0 bg-gradient-to-t from-[#000000] via-[#000000]/50 to-transparent" />
              <div className="absolute inset-0 bg-gradient-to-r from-[#000000]/90 via-[#000000]/40 to-transparent" />

              {/* Billboard Content */}
              <div className="absolute bottom-10 left-4 md:left-12 max-w-2xl">
                {/* VJ Badge */}
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#8B5CF6]/25 border border-[#8B5CF6]/40 text-[#C4B5FD] text-xs font-bold mb-3 backdrop-blur-md">
                  <Sparkles className="w-3.5 h-3.5 text-[#C4B5FD]" />
                  {heroMovie.vj}
                </div>

                <h1 className="text-3xl md:text-5xl font-black tracking-tight text-white mb-2 leading-tight">
                  {heroMovie.title}
                </h1>

                {/* Metadata Pills */}
                <div className="flex items-center gap-3 text-xs md:text-sm text-[#9AA0B0] font-medium mb-3">
                  <span className="flex items-center gap-1 text-[#FFB800] font-bold">
                    <Star className="w-4 h-4 fill-[#FFB800]" />
                    {heroMovie.rating}
                  </span>
                  <span>•</span>
                  <span>{heroMovie.year}</span>
                  <span>•</span>
                  <span className="px-1.5 py-0.5 rounded bg-white/10 text-white font-bold text-[11px]">HD</span>
                  <span>•</span>
                  <span className="text-[#00E676] font-semibold">Luganda Translated</span>
                </div>

                <p className="text-sm text-[#D0D4DF] line-clamp-2 md:line-clamp-3 mb-6 max-w-xl">
                  {heroMovie.synopsis}
                </p>

                {/* Actions */}
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => handlePlay(heroMovie)}
                    className="flex items-center gap-2 bg-[#22C55E] hover:bg-[#16A34A] text-white font-bold px-6 py-3 rounded-full shadow-lg shadow-[#22C55E]/30 transition-all hover:scale-105"
                  >
                    <Play className="w-4 h-4 fill-white" />
                    Watch Now
                  </button>

                  <button
                    onClick={() => setSelectedMovie(heroMovie)}
                    className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-5 py-3 rounded-full backdrop-blur-md border border-white/10 transition-colors"
                  >
                    <Info className="w-4 h-4" />
                    Details
                  </button>

                  <button
                    onClick={() => toggleMyList(heroMovie)}
                    className="w-11 h-11 rounded-full bg-white/10 hover:bg-white/20 border border-white/10 flex items-center justify-center text-white backdrop-blur-md transition-colors"
                    title={myList.some(m => m.id === heroMovie.id) ? 'Remove from My List' : 'Add to My List'}
                  >
                    {myList.some(m => m.id === heroMovie.id) ? <Check className="w-5 h-5 text-[#00E676]" /> : <Plus className="w-5 h-5" />}
                  </button>
                </div>
              </div>
            </div>

            {/* ── Movie Rails / Sections ───────────────────────────────── */}
            <div className="space-y-8 px-4 md:px-8 mt-2">
              {rails.map((section) => (
                <div key={section.title} className="space-y-3">
                  {/* Row Header */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <div 
                        className="w-7 h-7 rounded-full flex items-center justify-center border"
                        style={{ backgroundColor: `${section.color}20`, borderColor: `${section.color}40` }}
                      >
                        <section.icon className="w-3.5 h-3.5" style={{ color: section.color }} />
                      </div>
                      <h2 className="text-lg md:text-xl font-bold tracking-tight text-white">
                        {section.title}
                      </h2>
                    </div>

                    <button
                      onClick={() => setGridCategory(section)}
                      className="px-3 py-1 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#9AA0B0] hover:text-white transition-colors border border-white/5"
                    >
                      See all
                    </button>
                  </div>

                  {/* Horizontal Scroll Row */}
                  <div className="flex gap-3.5 overflow-x-auto pb-2 scrollbar-none snap-x snap-mandatory">
                    {section.movies.map((movie) => (
                      <div key={movie.id} className="flex-shrink-0 w-36 md:w-44 snap-start">
                        <MovieCard movie={movie} onClick={() => setSelectedMovie(movie)} />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {/* VIEW E: TV Series Feed */}
        {activeTab === 'series' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-4 md:px-8 pt-6">
            <div className="flex items-center justify-between mb-6">
              <h1 className="text-2xl font-black flex items-center gap-2">
                <Tv className="w-6 h-6 text-[#8B5CF6]" />
                All TV Series & Seasons
              </h1>
              <span className="text-xs text-[#9AA0B0] bg-white/5 px-2.5 py-1 rounded-lg border border-white/10">
                {catalog.filter(m => m.isTv).length} Series
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3.5 md:gap-4">
              {catalog.filter(m => m.isTv).map((movie) => (
                <MovieCard key={movie.id} movie={movie} onClick={() => setSelectedMovie(movie)} />
              ))}
            </div>
          </div>
        )}
      </main>

      {/* ── 3. Movie Detail Modal (Matches MovieDetailScreen from Flutter) ─── */}
      {selectedMovie && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xl flex items-center justify-center p-0 md:p-4 overflow-y-auto">
          <div className="relative w-full max-w-4xl bg-[#0C0D0F] border border-white/10 md:rounded-3xl overflow-hidden shadow-2xl my-auto">
            {/* Close Button */}
            <button
              onClick={() => setSelectedMovie(null)}
              className="absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-black/90 border border-white/15 flex items-center justify-center text-white backdrop-blur-md transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Modal Backdrop Banner */}
            <div className="relative h-64 md:h-80 w-full overflow-hidden">
              <img 
                src={selectedMovie.backdrop || selectedMovie.image}
                alt={selectedMovie.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0C0D0F] via-[#0C0D0F]/40 to-transparent" />
            </div>

            {/* Modal Body */}
            <div className="p-6 md:p-8 -mt-20 relative z-10">
              {/* VJ Tag */}
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#8B5CF6]/25 border border-[#8B5CF6]/40 text-[#C4B5FD] text-xs font-bold mb-3 backdrop-blur-md">
                <Sparkles className="w-3.5 h-3.5 text-[#C4B5FD]" />
                Translated by {selectedMovie.vj}
              </div>

              <h2 className="text-2xl md:text-4xl font-black text-white mb-2 leading-tight">
                {selectedMovie.title}
              </h2>

              {/* Metadata */}
              <div className="flex flex-wrap items-center gap-3 text-xs md:text-sm text-[#9AA0B0] font-medium mb-5">
                <span className="flex items-center gap-1 text-[#FFB800] font-bold">
                  <Star className="w-4 h-4 fill-[#FFB800]" />
                  {selectedMovie.rating}
                </span>
                <span>•</span>
                <span>{selectedMovie.year}</span>
                <span>•</span>
                <span>{selectedMovie.runtime}</span>
                <span>•</span>
                <span className="px-2 py-0.5 rounded bg-white/10 text-white font-bold text-xs">HD</span>
                <span className="px-2 py-0.5 rounded bg-[#00E676]/10 text-[#00E676] border border-[#00E676]/30 font-semibold text-xs">
                  {selectedMovie.category}
                </span>
              </div>

              {/* Play Action Buttons */}
              <div className="flex items-center gap-3 mb-6">
                <button
                  onClick={() => handlePlay(selectedMovie)}
                  className="flex items-center gap-2 bg-[#22C55E] hover:bg-[#16A34A] text-white font-bold px-7 py-3 rounded-full shadow-lg shadow-[#22C55E]/30 transition-all hover:scale-105"
                >
                  <Play className="w-4 h-4 fill-white" />
                  Watch Now
                </button>

                <button
                  onClick={() => toggleMyList(selectedMovie)}
                  className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-5 py-3 rounded-full border border-white/10 transition-colors"
                >
                  {myList.some(m => m.id === selectedMovie.id) ? (
                    <>
                      <Check className="w-4 h-4 text-[#00E676]" />
                      In My List
                    </>
                  ) : (
                    <>
                      <Plus className="w-4 h-4" />
                      Add to List
                    </>
                  )}
                </button>
              </div>

              {/* Synopsis */}
              <div className="mb-8">
                <h3 className="text-sm font-bold uppercase tracking-wider text-[#9AA0B0] mb-2">Synopsis</h3>
                <p className="text-sm md:text-base text-[#D0D4DF] leading-relaxed">
                  {selectedMovie.synopsis}
                </p>
              </div>

              {/* Series Episodes (If episodic) */}
              {selectedMovie.isTv && selectedMovie.episodes && selectedMovie.episodes.length > 0 && (
                <div className="mb-8">
                  <h3 className="text-sm font-bold uppercase tracking-wider text-[#9AA0B0] mb-3">Episodes</h3>
                  <div className="space-y-2">
                    {selectedMovie.episodes.map((ep) => (
                      <div 
                        key={ep.id}
                        onClick={() => handlePlay({ ...selectedMovie, streamUrl: ep.streamUrl, title: `${selectedMovie.title} - Episode ${ep.episodeNumber}` })}
                        className="flex items-center justify-between p-3.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/5 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-[#00E676]/20 text-[#00E676] flex items-center justify-center font-bold text-xs">
                            {ep.episodeNumber}
                          </div>
                          <span className="font-semibold text-sm text-white">{ep.name}</span>
                        </div>
                        <Play className="w-4 h-4 text-[#00E676] fill-[#00E676]" />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Related Movies */}
              <div>
                <h3 className="text-sm font-bold uppercase tracking-wider text-[#9AA0B0] mb-3">
                  {selectedMovie.isTv ? 'More Like This' : 'Related Movies'}
                </h3>
                <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-none">
                  {catalog.filter(m => m.id !== selectedMovie.id).slice(0, 8).map(rel => (
                    <div key={rel.id} className="flex-shrink-0 w-28 md:w-32">
                      <MovieCard movie={rel} onClick={() => setSelectedMovie(rel)} compact />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── 4. Fullscreen Video Player Modal ───────────────────────────────── */}
      {activeStreamUrl && (
        <div className="fixed inset-0 z-60 bg-black flex flex-col justify-center items-center">
          {/* Player Bar */}
          <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
            <button
              onClick={() => setActiveStreamUrl('')}
              className="flex items-center gap-2 px-4 py-2 rounded-full bg-black/60 hover:bg-black/90 border border-white/15 text-white backdrop-blur-md text-sm font-bold transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Close Player
            </button>

            {selectedMovie && (
              <span className="text-sm font-bold text-white bg-black/60 px-4 py-2 rounded-full border border-white/10 backdrop-blur-md">
                {selectedMovie.title} ({selectedMovie.vj})
              </span>
            )}
          </div>

          <div className="w-full h-full flex items-center justify-center">
            <video 
              src={activeStreamUrl}
              controls
              autoPlay
              playsInline
              className="w-full h-full max-h-screen object-contain"
            >
              Your browser does not support HTML5 video playback.
            </video>
          </div>
        </div>
      )}

      {/* ── 5. Mobile Floating Bottom Navigation Pill (Matches Flutter) ────── */}
      <div className="fixed md:hidden bottom-4 left-4 right-4 z-40 flex justify-center pointer-events-none">
        <nav className="pointer-events-auto flex items-center gap-1 px-4 py-2 rounded-full bg-[#08090C]/90 backdrop-blur-2xl border border-[#00E676]/30 shadow-2xl shadow-black/80">
          {[
            { id: 'home', icon: Play, label: 'Home' },
            { id: 'series', icon: Tv, label: 'Series' },
            { id: 'vjs', icon: Mic, label: 'VJs' },
            { id: 'search', icon: Search, label: 'Search' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id); setGridCategory(null); }}
              className={`flex flex-col items-center gap-0.5 px-3 py-1 rounded-full transition-colors ${
                activeTab === tab.id && !gridCategory
                  ? 'text-[#00E676]' 
                  : 'text-[#9AA0B0] hover:text-white'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              <span className="text-[10px] font-semibold">{tab.label}</span>
            </button>
          ))}
        </nav>
      </div>
    </div>
  );
}

// ── Shared Portrait Movie Card Component (Exact Flutter Style) ───────────────
function MovieCard({ movie, onClick, compact = false }) {
  return (
    <div 
      onClick={onClick}
      className="group flex flex-col cursor-pointer transition-transform duration-200 hover:scale-103"
    >
      {/* Poster */}
      <div className="relative aspect-[2/3] w-full rounded-2xl overflow-hidden bg-[#111216] border border-white/5 group-hover:border-[#00E676] group-hover:shadow-lg group-hover:shadow-[#00E676]/20 transition-all">
        <img 
          src={movie.image}
          alt={movie.title}
          loading="lazy"
          className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
        />

        {/* Top Badges */}
        <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded bg-black/60 text-[10px] font-bold text-white backdrop-blur-md border border-white/10">
          HD
        </div>

        {movie.vj && (
          <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-[#8B5CF6]/90 text-[10px] font-black text-white shadow-md">
            {movie.vj}
          </div>
        )}

        {/* Bottom Rating Star overlay on hover */}
        <div className="absolute inset-x-0 bottom-0 p-2 bg-gradient-to-t from-black/90 to-transparent flex items-center justify-between">
          <span className="flex items-center gap-1 text-[11px] font-bold text-[#FFB800]">
            <Star className="w-3 h-3 fill-[#FFB800]" />
            {movie.rating}
          </span>
          <span className="text-[10px] text-[#9AA0B0]">{movie.year}</span>
        </div>
      </div>

      {/* Title */}
      {!compact && (
        <h3 className="mt-2 text-xs md:text-sm font-bold text-white group-hover:text-[#00E676] line-clamp-1 transition-colors">
          {movie.title}
        </h3>
      )}
    </div>
  );
}
