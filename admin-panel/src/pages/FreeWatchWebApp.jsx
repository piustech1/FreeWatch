import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  Play, Search, Bell, User, Star, Sparkles, Tv, Film, 
  Flame, Heart, Ghost, Zap, Rocket, ChevronRight, X, 
  ArrowLeft, Volume2, Share2, Plus, Check, Clock, Eye,
  ExternalLink, Mic, Grid, Info, ShieldCheck, Download,
  Home, LayoutGrid, Settings, Compass, SlidersHorizontal
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// High-impact initial MunoWatch Luganda catalog (synced immediately with RTDB)
const INITIAL_MOVIES = [
  {
    id: 533535,
    title: 'Spider-Man: Brand New Day',
    vj: 'VJ Junior',
    category: 'Latest on FreeWatch',
    image: 'https://image.tmdb.org/t/p/w780/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdrop: 'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=1600&auto=format&fit=crop&q=80',
    rating: 9.4,
    year: '2026',
    runtime: '2h 15min',
    isTv: false,
    synopsis: 'Massive cinematic blurred backdrop of Spider-Man with suits new and classic, featuring his electric badge and daring multiverse battles in New York City.',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
  },
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
    title: 'Ape vs Monster',
    vj: 'VJ Junior',
    category: 'Action',
    image: 'https://image.tmdb.org/t/p/w780/9yBVqNrukuhFkrQgU9699i89k8.jpg',
    backdrop: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1600&auto=format&fit=crop&q=80',
    rating: 8.1,
    year: '2024',
    runtime: '1h 38m',
    isTv: false,
    synopsis: 'An ape crash-lands on Earth and creates a giant gila monster, leading to a catastrophic battle in Washington DC.',
    streamUrl: ''
  }
];

// Continue Watching data matching reference image
const CONTINUE_WATCHING = [
  {
    id: 'cw-1',
    title: 'Ghost Whisperer',
    vj: 'VJ Emmy',
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
    progress: 75,
    duration: '42m left'
  },
  {
    id: 'cw-2',
    title: 'Ghostbusters: Afterlife',
    vj: 'VJ Junior',
    image: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&auto=format&fit=crop&q=80',
    progress: 45,
    duration: '1h 10m left'
  },
  {
    id: 'cw-3',
    title: 'Wednesday: Season 1',
    vj: 'VJ Ulio',
    image: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
    progress: 60,
    duration: '22m left'
  },
  {
    id: 'cw-4',
    title: 'Money Heist: Part 5',
    vj: 'VJ Jingo',
    image: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&auto=format&fit=crop&q=80',
    progress: 90,
    duration: '8m left'
  }
];

// Curated VJs matching reference cards
const CURATED_VJS = [
  {
    name: 'VJ JUNIOR',
    subtitle: 'LUGANDA DUBBED',
    photo: '/vjs/vj junior.png',
    fallbackPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&auto=format&fit=crop&q=80',
    themeColor: '#7C3AED',
    accentColor: '#EC4899',
    bgColor: '#1A102E'
  },
  {
    name: 'VJ EMMY',
    subtitle: 'LUGANDA',
    photo: '/vjs/vj emmy.png',
    fallbackPhoto: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&auto=format&fit=crop&q=80',
    themeColor: '#0284C7',
    accentColor: '#38BDF8',
    bgColor: '#0C1B2E'
  },
  {
    name: 'VJ ULIO',
    subtitle: 'LUGANDA DUBBED',
    photo: '/vjs/vj ulio.jpeg',
    fallbackPhoto: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&auto=format&fit=crop&q=80',
    themeColor: '#0D9488',
    accentColor: '#2DD4BF',
    bgColor: '#0A2224'
  },
  {
    name: 'VJ JINGO',
    subtitle: 'LUGANDA DUBBED',
    photo: '/vjs/vj jingo.jpg',
    fallbackPhoto: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=300&auto=format&fit=crop&q=80',
    themeColor: '#EA580C',
    accentColor: '#FB923C',
    bgColor: '#26140D'
  },
  {
    name: 'VJ ICE P',
    subtitle: 'LUGANDA DUBBED',
    photo: '/vjs/vj iceP.jpeg',
    fallbackPhoto: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=300&auto=format&fit=crop&q=80',
    themeColor: '#4F46E5',
    accentColor: '#818CF8',
    bgColor: '#16152B'
  },
  {
    name: 'VJ HEAVY Q',
    subtitle: 'LUGANDA DUBBED',
    photo: '/vjs/Vj Heavy Q.jpeg',
    fallbackPhoto: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300&auto=format&fit=crop&q=80',
    themeColor: '#B91C1C',
    accentColor: '#F87171',
    bgColor: '#260F0F'
  }
];

export default function FreeWatchWebApp({ onNavigateToStore }) {
  const [catalog, setCatalog] = useState(INITIAL_MOVIES);
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'search' | 'vjs' | 'categories' | 'favorites' | 'settings'
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedVj, setSelectedVj] = useState('All');
  const [gridCategory, setGridCategory] = useState(null);
  const [selectedMovie, setSelectedMovie] = useState(null);
  const [activeStreamUrl, setActiveStreamUrl] = useState('');
  const [resolvingStream, setResolvingStream] = useState(false);
  const [focusedVjIndex, setFocusedVjIndex] = useState(0);
  const [focusedMovieId, setFocusedMovieId] = useState(108); // Focus Ape vs Monster by default as in screenshot
  const [myList, setMyList] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_my_list') || '[]');
    } catch (_) {
      return [];
    }
  });

  // Sync catalog with primary high-speed FreeWatch API (/api/v1/dashboard) and RTDB
  useEffect(() => {
    let isMounted = true;

    async function loadFromApi() {
      try {
        const res = await fetch('/api/v1/dashboard');
        if (res.ok) {
          const json = await res.json();
          if (json.success && json.data && isMounted) {
            const { featured, latest, categories } = json.data;
            const allItems = [
              ...(featured ? [featured] : []),
              ...(Array.isArray(latest) ? latest : []),
              ...Object.values(categories || {}).flat()
            ];
            const seen = new Set();
            const unique = [];
            for (const item of allItems) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                unique.push(item);
              }
            }
            if (unique.length > 0) {
              setCatalog(unique);
            }
          }
        }
      } catch (err) {
        console.warn('API fetch fallback to RTDB:', err);
      }
    }

    loadFromApi();

    // Secondary real-time updates from Firebase RTDB
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsubscribe = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists() && isMounted) {
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
            const hasSpiderman = normalized.some(m => /spider-man/i.test(m.title));
            if (!hasSpiderman) {
              setCatalog([INITIAL_MOVIES[0], ...normalized]);
            } else {
              setCatalog(normalized);
            }
          }
        }
      }
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, []);

  // Save favorites to local storage
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

  // Featured billboard movie (Spider-Man or top trending)
  const heroMovie = useMemo(() => {
    if (catalog.length === 0) return INITIAL_MOVIES[0];
    const spiderman = catalog.find(m => /spider-man/i.test(m.title));
    if (spiderman) return spiderman;
    return catalog[0];
  }, [catalog]);

  // Section rails
  const rails = useMemo(() => {
    const latest = catalog.slice(0, 15);
    const trending = [...catalog].sort((a, b) => (b.rating || 0) - (a.rating || 0)).slice(0, 15);
    const series = catalog.filter(m => m.isTv || /series|season|episode/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const action = catalog.filter(m => /action|war|agent|fighter|gun/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const sciFi = catalog.filter(m => /sci-fi|alien|future|dune|space/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const romance = catalog.filter(m => /romance|love|heart|wedding/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const horror = catalog.filter(m => /horror|demon|evil|dead|ghost|conjuring/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const drama = catalog.filter(m => /drama|story|life|biography|fight/i.test(m.category + ' ' + m.title)).slice(0, 15);
    const animation = catalog.filter(m => /animation|cartoon|k-pop|moana|inside out/i.test(m.category + ' ' + m.title)).slice(0, 15);

    return [
      { id: 'latest', title: 'LATEST ON FREEWATCH', icon: Sparkles, color: '#00E676', movies: latest.length ? latest : catalog.slice(0, 10) },
      { id: 'series', title: 'SERIES', icon: Tv, color: '#E50914', movies: series.length ? series : catalog.slice(0, 8) },
      { id: 'action', title: 'ACTION', icon: Zap, color: '#F97316', movies: action.length ? action : catalog.slice(0, 8) },
      { id: 'scifi', title: 'SCI-FI', icon: Rocket, color: '#A855F7', movies: sciFi.length ? sciFi : catalog.slice(0, 8) },
      { id: 'romance', title: 'ROMANCE', icon: Heart, color: '#EC4899', movies: romance.length ? romance : catalog.slice(0, 8) },
      { id: 'horror', title: 'HORROR', icon: Ghost, color: '#EF4444', movies: horror.length ? horror : catalog.slice(0, 8) },
      { id: 'drama', title: 'DRAMA', icon: Film, color: '#EAB308', movies: drama.length ? drama : catalog.slice(0, 8) },
      { id: 'animation', title: 'ANIMATION', icon: Film, color: '#06B6D4', movies: animation.length ? animation : catalog.slice(0, 8) },
    ];
  }, [catalog]);

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

    setActiveStreamUrl('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    setResolvingStream(false);
  };

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

  return (
    <div className="min-h-screen bg-[#08090C] text-white flex flex-row font-sans select-none antialiased overflow-x-hidden">
      {/* ── 1. Persistent Collapsible Navigation Rail (Left 80px) ─────────────── */}
      <aside className="fixed top-0 bottom-0 left-0 w-20 z-50 bg-[#07080B]/95 backdrop-blur-2xl border-r border-white/5 flex flex-col items-center justify-between py-6 select-none shadow-2xl">
        {/* Top: User Avatar */}
        <div className="relative group cursor-pointer" onClick={() => setActiveTab('settings')}>
          <div className="w-11 h-11 rounded-full p-0.5 border border-white/20 bg-gradient-to-tr from-[#00E676] to-transparent shadow-lg group-hover:scale-105 transition-transform overflow-hidden">
            <img 
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80" 
              alt="User Profile" 
              className="w-full h-full object-cover rounded-full"
            />
          </div>
          <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-[#00E676] border-2 border-[#07080B]" />
        </div>

        {/* Center: Vertical Action Icons */}
        <nav className="flex flex-col items-center gap-5 my-auto">
          {/* Search */}
          <button
            onClick={() => { setActiveTab('search'); setGridCategory(null); }}
            className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-all ${
              activeTab === 'search' && !gridCategory
                ? 'bg-white/15 text-white'
                : 'text-white/60 hover:text-white hover:bg-white/10'
            }`}
            title="Search"
          >
            <Search className="w-5 h-5" />
          </button>

          {/* Home: Glowing Vibrant Green Squircle (Active State) */}
          <button
            onClick={() => { setActiveTab('home'); setGridCategory(null); }}
            className={`relative flex items-center justify-center transition-transform ${
              activeTab === 'home' && !gridCategory
                ? 'w-12 h-12 rounded-2xl bg-[#00E676] text-black shadow-[0_0_22px_rgba(0,230,118,0.55)] scale-105'
                : 'w-11 h-11 rounded-2xl text-white/60 hover:text-white hover:bg-white/10'
            }`}
            title="Home"
          >
            <Home className="w-5 h-5 fill-current" />
          </button>

          {/* VJs */}
          <button
            onClick={() => { setActiveTab('vjs'); setGridCategory(null); }}
            className={`flex flex-col items-center justify-center py-1.5 px-2 rounded-2xl transition-all ${
              activeTab === 'vjs' && !gridCategory
                ? 'bg-white/15 text-[#00E676]'
                : 'text-white/60 hover:text-white hover:bg-white/10'
            }`}
            title="Available VJs"
          >
            <Mic className="w-4 h-4" />
            <span className="text-[9px] font-bold tracking-tight text-white/70 mt-1 uppercase">VJs</span>
          </button>

          {/* Categories */}
          <button
            onClick={() => { setActiveTab('categories'); setGridCategory(null); }}
            className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-all ${
              activeTab === 'categories' && !gridCategory
                ? 'bg-white/15 text-[#00E676]'
                : 'text-white/60 hover:text-white hover:bg-white/10'
            }`}
            title="Categories & Series"
          >
            <LayoutGrid className="w-5 h-5" />
          </button>

          {/* Favorites / My List */}
          <button
            onClick={() => { setActiveTab('favorites'); setGridCategory(null); }}
            className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-all ${
              activeTab === 'favorites' && !gridCategory
                ? 'bg-white/15 text-[#EC4899]'
                : 'text-white/60 hover:text-white hover:bg-white/10'
            }`}
            title="Favorites"
          >
            <Heart className="w-5 h-5" />
          </button>
        </nav>

        {/* Bottom: Settings */}
        <button
          onClick={() => { setActiveTab('settings'); setGridCategory(null); }}
          className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-all ${
            activeTab === 'settings'
              ? 'bg-white/15 text-white'
              : 'text-white/50 hover:text-white hover:bg-white/10'
          }`}
          title="Settings"
        >
          <Settings className="w-5 h-5" />
        </button>
      </aside>

      {/* ── 2. Top Right Branding & Header Controls ────────────────────────── */}
      <header className="fixed top-6 right-8 z-40 flex items-center gap-4 pointer-events-auto">
        {onNavigateToStore && (
          <button
            onClick={onNavigateToStore}
            className="hidden sm:flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 hover:bg-white/20 border border-white/15 text-white text-xs font-bold transition-all shadow-lg backdrop-blur-md hover:scale-105"
          >
            <Download className="w-3.5 h-3.5 text-[#00E676]" />
            Download App
          </button>
        )}

        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-black/40 border border-white/10 backdrop-blur-md">
          <span className="text-lg font-black tracking-widest text-white">
            FREE<span className="text-[#00E676]">WATCH</span>
          </span>
        </div>
      </header>

      {/* ── 3. Main Viewing Canvas (Left padding 80px for persistent rail) ───── */}
      <main className="flex-1 pl-20 min-h-screen overflow-y-auto overflow-x-hidden cinema-scroll">
        {/* VIEW A: Search */}
        {activeTab === 'search' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-6 lg:px-12 pt-10 pb-24">
            <div className="relative mb-8">
              <Search className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-[#9AA0B0]" />
              <input 
                type="text"
                autoFocus
                placeholder="Search movies, TV series, or VJ name (e.g. VJ Junior, Spider-Man)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-14 pr-6 py-4 rounded-2xl bg-[#101218] border border-white/10 text-white placeholder-[#555B6B] text-base focus:outline-none focus:border-[#00E676] shadow-2xl transition-all"
              />
              {searchQuery && (
                <button 
                  onClick={() => setSearchQuery('')}
                  className="absolute right-5 top-1/2 -translate-y-1/2 text-[#9AA0B0] hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>

            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold tracking-tight">
                {searchQuery ? `Search Results for "${searchQuery}"` : 'Browse Catalog'}
              </h2>
              <span className="text-xs text-[#9AA0B0] bg-white/5 px-3 py-1 rounded-lg border border-white/10">
                {searchResults.length} movies
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
              {searchResults.map((movie) => (
                <MoviePosterCard 
                  key={movie.id} 
                  movie={movie} 
                  isFocused={focusedMovieId === movie.id}
                  onClick={() => setSelectedMovie(movie)} 
                />
              ))}
            </div>
          </div>
        )}

        {/* VIEW B: Categories & Series */}
        {activeTab === 'categories' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-6 lg:px-12 pt-10 pb-24">
            <h1 className="text-2xl font-black text-white mb-6 flex items-center gap-2">
              <LayoutGrid className="w-6 h-6 text-[#00E676]" />
              Browse by Category
            </h1>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 mb-10">
              {rails.map((r) => (
                <div
                  key={r.id}
                  onClick={() => setGridCategory(r)}
                  className="p-5 rounded-2xl bg-[#101218] hover:bg-[#161822] border border-white/5 hover:border-white/20 cursor-pointer transition-all flex items-center gap-3.5 group shadow-lg"
                >
                  <div 
                    className="w-10 h-10 rounded-xl flex items-center justify-center border transition-transform group-hover:scale-110"
                    style={{ backgroundColor: `${r.color}20`, borderColor: `${r.color}50` }}
                  >
                    <r.icon className="w-5 h-5" style={{ color: r.color }} />
                  </div>
                  <div>
                    <h3 className="font-bold text-white text-sm group-hover:text-[#00E676] transition-colors">{r.title}</h3>
                    <span className="text-xs text-white/50">{r.movies.length} items</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* VIEW C: Favorites */}
        {activeTab === 'favorites' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-6 lg:px-12 pt-10 pb-24">
            <h1 className="text-2xl font-black text-white mb-6 flex items-center gap-2">
              <Heart className="w-6 h-6 text-[#EC4899] fill-[#EC4899]" />
              My Watchlist
            </h1>
            {myList.length === 0 ? (
              <div className="text-center py-20 bg-white/5 rounded-3xl border border-white/5">
                <Heart className="w-12 h-12 text-white/30 mx-auto mb-3" />
                <h3 className="text-lg font-bold text-white mb-1">Your Watchlist is Empty</h3>
                <p className="text-xs text-white/50 mb-4">Add movies and series to your favorites to watch them anytime.</p>
                <button
                  onClick={() => setActiveTab('home')}
                  className="px-6 py-2.5 rounded-full bg-[#00E676] text-black font-extrabold text-xs"
                >
                  Explore Movies
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
                {myList.map((movie) => (
                  <MoviePosterCard 
                    key={movie.id} 
                    movie={movie} 
                    onClick={() => setSelectedMovie(movie)} 
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* VIEW D: VJs View */}
        {activeTab === 'vjs' && !gridCategory && (
          <div className="max-w-6xl mx-auto px-6 lg:px-12 pt-10 pb-24">
            <h1 className="text-2xl font-black text-white mb-6 flex items-center gap-2">
              <Mic className="w-6 h-6 text-[#A855F7]" />
              Available VJ Translators
            </h1>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-5">
              {CURATED_VJS.map((vj, idx) => (
                <div
                  key={vj.name}
                  onClick={() => {
                    const matched = catalog.filter(m => m.vj.toLowerCase().includes(vj.name.toLowerCase()));
                    setGridCategory({ title: `${vj.name} Movies`, movies: matched });
                  }}
                  className="p-5 rounded-3xl bg-[#101218] border border-white/10 hover:border-[#A855F7] cursor-pointer transition-all flex items-center gap-4 group shadow-xl hover:scale-102"
                >
                  <div className="w-16 h-16 rounded-full overflow-hidden border-2 border-[#A855F7]/50 shadow-md">
                    <img 
                      src={vj.photo} 
                      onError={(e) => { e.currentTarget.src = vj.fallbackPhoto; }}
                      alt={vj.name} 
                      className="w-full h-full object-cover group-hover:scale-110 transition-transform"
                    />
                  </div>
                  <div>
                    <h3 className="font-black text-lg text-white group-hover:text-[#C084FC] transition-colors">{vj.name}</h3>
                    <p className="text-xs text-[#A78BFA] font-bold">{vj.subtitle}</p>
                    <span className="text-[11px] text-white/50 mt-1 inline-block">Exclusive Luganda Voice-Over</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* VIEW E: See All Grid View */}
        {gridCategory && (
          <div className="max-w-6xl mx-auto px-6 lg:px-12 pt-10 pb-24">
            <div className="flex items-center justify-between mb-8">
              <button
                onClick={() => setGridCategory(null)}
                className="flex items-center gap-2 text-sm font-bold text-[#9AA0B0] hover:text-white px-4 py-2 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Back to Home
              </button>
              <h1 className="text-2xl font-black text-white">{gridCategory.title}</h1>
              <span className="text-xs text-[#9AA0B0] bg-white/5 px-3 py-1 rounded-lg border border-white/10">
                {gridCategory.movies.length} items
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
              {gridCategory.movies.map((movie) => (
                <MoviePosterCard key={movie.id} movie={movie} onClick={() => setSelectedMovie(movie)} />
              ))}
            </div>
          </div>
        )}

        {/* VIEW F: Home Feed (Matching User Screenshot Exactly) */}
        {activeTab === 'home' && !gridCategory && (
          <div className="pb-24">
            {/* ── 10-Foot Cinematic Screen Hero Billboard ────────────────────── */}
            <div className="relative w-full h-[500px] lg:h-[560px] overflow-hidden select-none">
              {/* High-Res Cinematic Backdrop */}
              <img 
                src={heroMovie.backdrop || heroMovie.image}
                alt={heroMovie.title}
                className="w-full h-full object-cover object-top filter brightness-90 transform scale-102"
              />

              {/* Cinema Vignette Gradients */}
              <div className="absolute inset-0 bg-gradient-to-r from-[#08090C] via-[#08090C]/80 via-45% to-transparent" />
              <div className="absolute inset-0 bg-gradient-to-t from-[#08090C] via-[#08090C]/40 to-transparent" />

              {/* Top Right Purple VJ Badge */}
              <div className="absolute top-6 right-52 hidden lg:flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#7C3AED]/75 border border-[#A78BFA]/60 text-white backdrop-blur-md shadow-lg shadow-[#7C3AED]/30">
                <div className="w-5 h-5 rounded-full overflow-hidden border border-white/50">
                  <img 
                    src="/vjs/vj junior.png" 
                    onError={(e) => { e.currentTarget.src = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80'; }}
                    alt="VJ" 
                    className="w-full h-full object-cover"
                  />
                </div>
                <span className="text-xs font-black tracking-wider uppercase">{heroMovie.vj || 'VJ JUNIOR'}</span>
              </div>

              {/* Billboard Content (Bottom Left) */}
              <div className="absolute bottom-8 left-6 lg:left-12 max-w-2xl z-20">
                {/* Stylized Title / Logo */}
                <div className="mb-3">
                  <h1 className="text-4xl lg:text-6xl font-black tracking-tighter text-white uppercase italic drop-shadow-2xl leading-none">
                    {heroMovie.title.includes('Spider-Man') ? (
                      <span className="text-transparent bg-clip-text bg-gradient-to-r from-red-500 via-white to-blue-500">
                        SPIDER-MAN
                        <span className="block text-xl lg:text-2xl not-italic font-extrabold text-[#FCD34D] tracking-widest mt-1">
                          BRAND NEW DAY
                        </span>
                      </span>
                    ) : (
                      heroMovie.title
                    )}
                  </h1>
                </div>

                {/* Frosted Metadata Pill Tags Row */}
                <div className="flex flex-wrap items-center gap-2.5 mb-4">
                  <span className="px-2.5 py-1 rounded-md bg-white/10 border border-white/15 text-white/90 text-xs font-bold backdrop-blur-md">
                    PG-13
                  </span>
                  <span className="px-2.5 py-1 rounded-md bg-white/10 border border-white/15 text-white/90 text-xs font-bold backdrop-blur-md">
                    {heroMovie.runtime || '2h 15min'}
                  </span>
                  <span className="px-2.5 py-1 rounded-md bg-white/10 border border-white/15 text-white/90 text-xs font-bold backdrop-blur-md">
                    {heroMovie.year || '2026'}
                  </span>
                  <span className="px-2.5 py-1 rounded-md bg-white/10 border border-white/15 text-white/90 text-xs font-bold backdrop-blur-md">
                    {heroMovie.category || 'Action'}
                  </span>
                </div>

                {/* Synopsis */}
                <p className="text-xs lg:text-sm text-white/80 line-clamp-2 lg:line-clamp-3 mb-6 max-w-xl leading-relaxed">
                  {heroMovie.synopsis}
                </p>

                {/* Action Buttons */}
                <div className="flex items-center gap-3">
                  {/* ▶ PLAY Button (Vibrant Green) */}
                  <button
                    onClick={() => handlePlay(heroMovie)}
                    className="flex items-center gap-2.5 px-8 py-3.5 rounded-full bg-[#00E676] hover:bg-[#00C853] text-black font-black text-sm tracking-wide uppercase shadow-xl shadow-[#00E676]/35 hover:scale-105 transition-all"
                  >
                    <Play className="w-4 h-4 fill-black" />
                    PLAY
                  </button>

                  {/* TRAILER / DETAILS Button (Frosted Pill) */}
                  <button
                    onClick={() => setSelectedMovie(heroMovie)}
                    className="flex items-center gap-2 px-7 py-3.5 rounded-full bg-white/10 hover:bg-white/20 text-white font-extrabold text-sm tracking-wide uppercase backdrop-blur-md border border-white/20 hover:scale-105 transition-all"
                  >
                    TRAILER
                  </button>
                </div>
              </div>
            </div>

            {/* ── Content Sections (Matching Screenshot Below Billboard) ────── */}
            <div className="space-y-9 px-6 lg:px-12 mt-4">
              {/* SECTION 1: AVAILABLE VJs (Focused VJ Badge Row) */}
              <div>
                <div className="flex items-center justify-between mb-3.5">
                  <h2 className="text-sm font-black uppercase tracking-wider text-white/90 flex items-center gap-2">
                    AVAILABLE VJs
                  </h2>
                  <button 
                    onClick={() => setActiveTab('vjs')}
                    className="text-xs font-bold text-[#A855F7] hover:underline"
                  >
                    View All
                  </button>
                </div>

                {/* Panoramic Interlocking VJ Cards Row */}
                <div className="flex gap-4 overflow-x-auto pb-3 cinema-scroll snap-x">
                  {CURATED_VJS.map((vj, idx) => {
                    const isFocused = focusedVjIndex === idx;
                    return (
                      <div
                        key={vj.name}
                        onClick={() => {
                          setFocusedVjIndex(idx);
                          const matched = catalog.filter(m => m.vj.toLowerCase().includes(vj.name.toLowerCase()));
                          setGridCategory({ title: `${vj.name} Collection`, movies: matched });
                        }}
                        onMouseEnter={() => setFocusedVjIndex(idx)}
                        className={`flex-shrink-0 w-60 h-24 rounded-2xl overflow-hidden cursor-pointer relative transition-all duration-200 snap-start select-none ${
                          isFocused 
                            ? 'border-2 border-[#A855F7] shadow-[0_0_22px_rgba(168,85,247,0.5)] scale-102 ring-1 ring-[#C084FC]' 
                            : 'border border-white/10 hover:border-white/25 opacity-85 hover:opacity-100'
                        }`}
                        style={{ backgroundColor: vj.bgColor }}
                      >
                        {/* Left Portrait */}
                        <div className="absolute left-0 top-0 bottom-0 w-28 overflow-hidden">
                          <img 
                            src={vj.photo} 
                            onError={(e) => { e.currentTarget.src = vj.fallbackPhoto; }}
                            alt={vj.name} 
                            className="w-full h-full object-cover filter grayscale contrast-125"
                          />
                          <div className="absolute inset-0 bg-gradient-to-r from-transparent to-[#101218]/90" />
                        </div>

                        {/* Geometric Diagonal Accent Slice */}
                        <div 
                          className="absolute right-0 top-0 bottom-0 w-36 transform -skew-x-12 translate-x-4 opacity-25"
                          style={{ backgroundColor: vj.accentColor }}
                        />

                        {/* Right Content */}
                        <div className="absolute right-3 top-0 bottom-0 flex flex-col justify-center items-end text-right z-10">
                          <h3 className="font-black text-sm text-white tracking-wide">{vj.name}</h3>
                          <p className="text-[10px] font-extrabold tracking-wider text-white/70 uppercase">{vj.subtitle}</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* SECTION 2: CONTINUE WATCHING (16:9 Landscape Video Cards) */}
              <div>
                <div className="flex items-center justify-between mb-3.5">
                  <h2 className="text-sm font-black uppercase tracking-wider text-white/90">
                    CONTINUE WATCHING
                  </h2>
                </div>

                <div className="flex gap-4 overflow-x-auto pb-3 cinema-scroll snap-x">
                  {CONTINUE_WATCHING.map((item) => (
                    <div
                      key={item.id}
                      onClick={() => handlePlay(heroMovie)}
                      className="flex-shrink-0 w-64 md:w-72 aspect-video rounded-2xl overflow-hidden bg-[#12131A] border border-white/10 hover:border-[#00E676] hover:shadow-[0_0_20px_rgba(0,230,118,0.35)] cursor-pointer relative group transition-all duration-200 snap-start"
                    >
                      {/* Thumbnail */}
                      <img 
                        src={item.image} 
                        alt={item.title} 
                        className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />

                      {/* Center Translucent Play Icon */}
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-11 h-11 rounded-full bg-black/55 backdrop-blur-md border border-white/20 flex items-center justify-center group-hover:scale-115 group-hover:bg-[#00E676] transition-all shadow-xl">
                          <Play className="w-4 h-4 text-white group-hover:text-black fill-current ml-0.5" />
                        </div>
                      </div>

                      {/* Title & Duration Left Bottom */}
                      <div className="absolute bottom-2.5 left-3 right-3 flex items-center justify-between">
                        <div>
                          <h4 className="font-bold text-xs text-white line-clamp-1">{item.title}</h4>
                          <span className="text-[10px] text-white/60 font-medium">{item.duration}</span>
                        </div>
                        <span className="text-[10px] font-bold text-[#00E676]">{item.progress}%</span>
                      </div>

                      {/* Progress Bar at the very bottom */}
                      <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/20">
                        <div 
                          className="h-full bg-[#00E676]" 
                          style={{ width: `${item.progress}%` }} 
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* SECTION 3: Rails (Starting with LATEST ON FREEWATCH with 1.08x D-Pad Focus State) */}
              {rails.map((rail, rIdx) => (
                <div key={rail.id}>
                  <div className="flex items-center justify-between mb-3.5">
                    <h2 className="text-sm font-black uppercase tracking-wider text-white/90 flex items-center gap-2">
                      <rail.icon className="w-4 h-4" style={{ color: rail.color }} />
                      {rail.title}
                    </h2>
                    <button
                      onClick={() => setGridCategory(rail)}
                      className="px-3 py-1 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#9AA0B0] hover:text-white transition-colors border border-white/5"
                    >
                      See all
                    </button>
                  </div>

                  {/* Horizontal Posters Row with 1.08x D-Pad Focus State */}
                  <div className="flex gap-4 overflow-x-auto pb-4 pt-2 cinema-scroll snap-x">
                    {rail.movies.map((movie, mIdx) => {
                      const isFocused = focusedMovieId === movie.id;
                      return (
                        <div key={movie.id} className="flex-shrink-0 w-36 md:w-44 snap-start">
                          <MoviePosterCard 
                            movie={movie}
                            isFocused={isFocused}
                            onClick={() => {
                              setFocusedMovieId(movie.id);
                              setSelectedMovie(movie);
                            }}
                            onMouseEnter={() => setFocusedMovieId(movie.id)}
                          />
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>

      {/* ── 4. Movie Detail Modal (Matches Native Mobile & TV Sheet) ─────────── */}
      {selectedMovie && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-2xl flex items-center justify-center p-4 md:p-8 overflow-y-auto">
          <div className="relative w-full max-w-4xl bg-[#0F1117] border border-white/15 rounded-3xl overflow-hidden shadow-2xl my-auto animate-in fade-in zoom-in-95 duration-200">
            {/* Close Button */}
            <button
              onClick={() => setSelectedMovie(null)}
              className="absolute top-4 right-4 z-20 w-10 h-10 rounded-full bg-black/60 hover:bg-black/90 border border-white/20 flex items-center justify-center text-white backdrop-blur-md transition-colors"
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
              <div className="absolute inset-0 bg-gradient-to-t from-[#0F1117] via-[#0F1117]/50 to-transparent" />
            </div>

            {/* Modal Body */}
            <div className="p-6 md:p-8 -mt-20 relative z-10">
              {/* VJ Tag */}
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#7C3AED]/30 border border-[#7C3AED]/50 text-[#C4B5FD] text-xs font-bold mb-3 backdrop-blur-md">
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

              {/* Actions */}
              <div className="flex items-center gap-3 mb-6">
                <button
                  onClick={() => handlePlay(selectedMovie)}
                  className="flex items-center gap-2.5 bg-[#00E676] hover:bg-[#00C853] text-black font-black px-8 py-3.5 rounded-full shadow-lg shadow-[#00E676]/30 transition-all hover:scale-105 uppercase text-sm"
                >
                  <Play className="w-4 h-4 fill-black" />
                  Watch Now
                </button>

                <button
                  onClick={() => toggleMyList(selectedMovie)}
                  className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-5 py-3.5 rounded-full border border-white/15 transition-colors text-sm"
                >
                  {myList.some(m => m.id === selectedMovie.id) ? (
                    <>
                      <Check className="w-4 h-4 text-[#00E676]" />
                      In Watchlist
                    </>
                  ) : (
                    <>
                      <Plus className="w-4 h-4" />
                      Add to Watchlist
                    </>
                  )}
                </button>
              </div>

              {/* Synopsis */}
              <div className="mb-6">
                <h3 className="text-xs font-bold uppercase tracking-wider text-[#9AA0B0] mb-2">Synopsis</h3>
                <p className="text-sm md:text-base text-[#D0D4DF] leading-relaxed">
                  {selectedMovie.synopsis}
                </p>
              </div>

              {/* Episodes (If TV Series) */}
              {selectedMovie.isTv && selectedMovie.episodes && selectedMovie.episodes.length > 0 && (
                <div className="mb-6">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-[#9AA0B0] mb-3">Episodes</h3>
                  <div className="space-y-2 max-h-48 overflow-y-auto cinema-scroll">
                    {selectedMovie.episodes.map((ep) => (
                      <div 
                        key={ep.id}
                        onClick={() => handlePlay({ ...selectedMovie, streamUrl: ep.streamUrl, title: `${selectedMovie.title} - Episode ${ep.episodeNumber}` })}
                        className="flex items-center justify-between p-3.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/5 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-7 h-7 rounded-full bg-[#00E676]/20 text-[#00E676] flex items-center justify-center font-bold text-xs">
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
            </div>
          </div>
        </div>
      )}

      {/* ── 5. Fullscreen Video Player Modal ───────────────────────────────── */}
      {activeStreamUrl && (
        <div className="fixed inset-0 z-60 bg-black flex flex-col justify-center items-center">
          <div className="absolute top-6 left-6 right-6 z-20 flex items-center justify-between">
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
    </div>
  );
}

// ── Shared 2:3 Movie Poster Card with 1.08x D-Pad Focus State ───────────────
function MoviePosterCard({ movie, isFocused = false, onClick, onMouseEnter }) {
  return (
    <div 
      onClick={onClick}
      onMouseEnter={onMouseEnter}
      className={`group flex flex-col cursor-pointer transition-all duration-200 relative select-none ${
        isFocused 
          ? 'scale-[1.08] z-30' 
          : 'hover:scale-[1.05] z-10'
      }`}
    >
      {/* 1.08x Green Glowing Focus Ring (Annotated in Reference Screenshot) */}
      <div 
        className={`relative aspect-[2/3] w-full rounded-2xl overflow-hidden bg-[#111216] transition-all duration-200 ${
          isFocused 
            ? 'border-2 border-[#00E676] shadow-[0_0_25px_rgba(0,230,118,0.65)] ring-2 ring-[#00E676]/30' 
            : 'border border-white/10 hover:border-[#00E676]/60 hover:shadow-lg hover:shadow-[#00E676]/20'
        }`}
      >
        <img 
          src={movie.image}
          alt={movie.title}
          loading="lazy"
          className="w-full h-full object-cover"
        />

        {/* Top Badges */}
        <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded bg-black/60 text-[9px] font-bold text-white backdrop-blur-md border border-white/10">
          HD
        </div>

        {movie.vj && (
          <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-[#7C3AED]/90 text-[9px] font-black text-white shadow-md">
            {movie.vj}
          </div>
        )}

        {/* Bottom Rating Star overlay */}
        <div className="absolute inset-x-0 bottom-0 p-2 bg-gradient-to-t from-black/95 to-transparent flex items-center justify-between">
          <span className="flex items-center gap-1 text-[11px] font-bold text-[#FFB800]">
            <Star className="w-3 h-3 fill-[#FFB800]" />
            {movie.rating}
          </span>
          <span className="text-[10px] text-white/60">{movie.year}</span>
        </div>
      </div>

      {/* D-Pad Focus Crosshair Indicator if focused */}
      {isFocused && (
        <div className="flex justify-center mt-1.5 animate-pulse">
          <div className="w-2.5 h-1 rounded-full bg-[#00E676] shadow-[0_0_8px_#00E676]" />
        </div>
      )}

      {/* Title */}
      <h3 className={`mt-1.5 text-xs font-bold line-clamp-1 transition-colors ${
        isFocused ? 'text-[#00E676]' : 'text-white/90 group-hover:text-[#00E676]'
      }`}>
        {movie.title}
      </h3>
    </div>
  );
}
