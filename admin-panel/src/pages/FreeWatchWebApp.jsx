import React, { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { 
  Play, Search, Bell, Star, Sparkles, Tv, Film, 
  Heart, ChevronDown, X, ArrowLeft, Plus, Check,
  Download, Menu, MessageCircle, ExternalLink,
  Loader2, Filter, RotateCcw
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// High-impact initial MunoWatch Luganda catalog
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
    id: 67406,
    title: 'Mirzapur',
    vj: 'VJ Ashim',
    category: 'Series',
    image: 'https://image.tmdb.org/t/p/w780/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    rating: 9.1,
    year: '2025',
    runtime: '50m',
    isTv: true,
    synopsis: 'A shocking incident at a wedding procession ignites a series of events entangling two families in the lawless city of Mirzapur.',
    streamUrl: ''
  },
  {
    id: 67384,
    title: 'Living For Love',
    vj: 'VJ Sammy',
    category: 'Romance',
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    rating: 8.7,
    year: '2024',
    runtime: '1h 55m',
    isTv: false,
    synopsis: 'Two star-crossed lovers fight against familial obligations and societal expectations in an emotional journey.',
    streamUrl: ''
  },
  {
    id: 67378,
    title: 'Awarapan',
    vj: 'VJ Ice P',
    category: 'Action',
    image: 'https://image.tmdb.org/t/p/w780/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    backdrop: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1600&auto=format&fit=crop&q=80',
    rating: 8.9,
    year: '2024',
    runtime: '2h 10m',
    isTv: false,
    synopsis: 'A remorseful hitman finds redemption when he decides to liberate a captive woman from his ruthless boss.',
    streamUrl: ''
  },
  {
    id: 67369,
    title: 'Barbarian',
    vj: 'VJ Emmy',
    category: 'Horror',
    image: 'https://image.tmdb.org/t/p/w780/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg',
    rating: 8.6,
    year: '2024',
    runtime: '1h 42m',
    isTv: false,
    synopsis: 'A young woman staying at an Airbnb rental discovers that the house is not what it seems to be.',
    streamUrl: ''
  },
  {
    id: 67359,
    title: 'Kaleidoscope',
    vj: 'VJ Ulio',
    category: 'Series',
    image: 'https://image.tmdb.org/t/p/w780/AnsPtB9LzL58QfGz0Y5k1017r.jpg',
    backdrop: 'https://image.tmdb.org/t/p/original/AnsPtB9LzL58QfGz0Y5k1017r.jpg',
    rating: 8.5,
    year: '2024',
    runtime: '48m',
    isTv: true,
    synopsis: 'A master thief and his crew attempt an epic and elaborate heist worth $7 billion dollars, but betrayal and greed threaten everything.',
    streamUrl: ''
  }
];

// Genres matching MunoWatch /browse
const GENRES = [
  'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 
  'Documentary', 'Drama', 'Family', 'Fantasy', 'History', 
  'Horror', 'Music', 'Mystery', 'Romance', 'Sci-Fi', 
  'Thriller', 'War', 'Western'
];

// Curated VJs matching MunoWatch /browse
const VJ_LIST = [
  'VJ Junior', 'VJ Emmy', 'VJ Jingo', 'VJ Ice P', 'VJ Ulio',
  'VJ Heavy Q', 'VJ Sammy', 'VJ Mark', 'VJ Aaron', 'VJ Banks',
  'VJ Muba', 'VJ Ivo', 'VJ Kevin', 'VJ Dan', 'VJ Ashim', 'VJ Smart'
];

// Typewriter Taglines (Matching MunoWatch landing tagline)
const TYPEWRITER_PHRASES = [
  'Katandika Butandisi - Twolekede Ekyatuleese',
  'Ekiseera Kyoona Woona Wooli - Watch Luganda Dubbed Movies Online',
  'Over 7,000+ Translated Movies & TV Series Streamed in HD',
  'Continuous High-Speed Streaming Powered by FreeWatch'
];

export default function FreeWatchWebApp({ onNavigateToStore }) {
  const [catalog, setCatalog] = useState(INITIAL_MOVIES);
  const [catalogPage, setCatalogPage] = useState(1);
  const [hasMoreCatalog, setHasMoreCatalog] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [totalCatalogCount, setTotalCatalogCount] = useState(7074);

  // Navigation & Filtering States (Matching MunoWatch nav.min.js & grid.min.js)
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'grid' | 'series' | 'search' | 'watchlist'
  const [selectedGenre, setSelectedGenre] = useState('All');
  const [selectedVj, setSelectedVj] = useState('All');
  const [pageTitle, setPageTitle] = useState('Latest Movies');
  const [searchQuery, setSearchQuery] = useState('');
  
  // Dropdown UI states
  const [genreDropdownOpen, setGenreDropdownOpen] = useState(false);
  const [vjDropdownOpen, setVjDropdownOpen] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Player & Detail Modal States
  const [selectedMovie, setSelectedMovie] = useState(null);
  const [activeStreamUrl, setActiveStreamUrl] = useState('');
  const [resolvingStream, setResolvingStream] = useState(false);

  // Watchlist persistence
  const [myList, setMyList] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_my_list') || '[]');
    } catch (_) {
      return [];
    }
  });

  // Typewriter ticker
  const [typewriterIndex, setTypewriterIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setTypewriterIndex((prev) => (prev + 1) % TYPEWRITER_PHRASES.length);
    }, 4500);
    return () => clearInterval(interval);
  }, []);

  // Close dropdowns on outside click
  useEffect(() => {
    const handleOutsideClick = (e) => {
      if (!e.target.closest('.nav-dropdown-btn') && !e.target.closest('.nav-dropdown-menu')) {
        setGenreDropdownOpen(false);
        setVjDropdownOpen(false);
      }
    };
    window.addEventListener('click', handleOutsideClick);
    return () => window.removeEventListener('click', handleOutsideClick);
  }, []);

  // Sort array strictly ID-descending (MunoWatch newly-to-oldy algorithm)
  const sortNewlyToOldy = useCallback((items) => {
    return [...items].sort((a, b) => {
      const idA = typeof a.id === 'number' ? a.id : parseInt(a.id, 10) || 0;
      const idB = typeof b.id === 'number' ? b.id : parseInt(b.id, 10) || 0;
      return idB - idA;
    });
  }, []);

  // Fetch paginated movie batches from FreeWatch API (/api/v1/movies)
  const fetchMoviePage = useCallback(async (pageToLoad, isInitial = false) => {
    try {
      if (!isInitial) setLoadingMore(true);
      const res = await fetch(`/api/v1/movies?page=${pageToLoad}&limit=40&sort=newest`);
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data) && json.data.length > 0) {
          setCatalog((prev) => {
            const seen = new Set();
            const merged = [];

            // Add new page items
            for (const item of json.data) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                merged.push(item);
              }
            }

            // Append previous items
            const sourcePrev = isInitial && prev === INITIAL_MOVIES ? [] : prev;
            for (const item of sourcePrev) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                merged.push(item);
              }
            }

            // Preserve hero Spider-Man release
            const hasSpiderman = merged.some(m => /spider-man/i.test(m.title));
            if (!hasSpiderman) {
              merged.push(INITIAL_MOVIES[0]);
            }

            return sortNewlyToOldy(merged);
          });

          setCatalogPage(pageToLoad);
          setHasMoreCatalog(Boolean(json.hasMore));
          if (json.total) {
            setTotalCatalogCount(json.total);
          }
        }
      }
    } catch (err) {
      console.warn('Error fetching movies page:', err);
    } finally {
      if (!isInitial) setLoadingMore(false);
    }
  }, [sortNewlyToOldy]);

  const loadMoreMovies = useCallback(() => {
    if (loadingMore || !hasMoreCatalog) return;
    fetchMoviePage(catalogPage + 1, false);
  }, [catalogPage, hasMoreCatalog, loadingMore, fetchMoviePage]);

  // Window scroll infinite pagination (matching grid.min.js: scrollTop + height >= innerHeight - 100)
  useEffect(() => {
    const handleScroll = () => {
      const scrollHeight = document.documentElement.scrollHeight;
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const clientHeight = window.innerHeight;

      if (scrollHeight - (scrollTop + clientHeight) < 850) {
        loadMoreMovies();
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [loadMoreMovies]);

  // Initial load
  useEffect(() => {
    let isMounted = true;
    fetchMoviePage(1, true);

    // RTDB listener for instant live uploads
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsubscribe = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists() && isMounted) {
        const val = snapshot.val();
        let items = [];
        if (Array.isArray(val)) items = val;
        else if (typeof val === 'object' && val !== null) items = Object.values(val);

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
            setCatalog(prev => {
              const seen = new Set();
              const list = [];
              for (const m of [...normalized, ...prev]) {
                if (m && m.id && !seen.has(m.id)) {
                  seen.add(m.id);
                  list.push(m);
                }
              }
              return sortNewlyToOldy(list);
            });
          }
        }
      }
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, [fetchMoviePage, sortNewlyToOldy]);

  // Watchlist toggle
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

  // Hero movie
  const heroMovie = useMemo(() => {
    if (catalog.length === 0) return INITIAL_MOVIES[0];
    const spiderman = catalog.find(m => /spider-man/i.test(m.title));
    if (spiderman) return spiderman;
    return catalog[0];
  }, [catalog]);

  // Play stream resolver
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

  // Filtered catalog calculation (combines tab, series, genre, vj, and search)
  const displayedMovies = useMemo(() => {
    let list = sortNewlyToOldy(catalog);

    if (activeTab === 'series') {
      list = list.filter(m => m.isTv || /series|season|episode/i.test(m.category + ' ' + m.title));
    } else if (activeTab === 'watchlist') {
      return myList;
    }

    if (selectedGenre !== 'All') {
      const g = selectedGenre.toLowerCase();
      list = list.filter(m => (m.category && m.category.toLowerCase().includes(g)) || m.title.toLowerCase().includes(g));
    }

    if (selectedVj !== 'All') {
      const v = selectedVj.toLowerCase();
      list = list.filter(m => m.vj && m.vj.toLowerCase().includes(v));
    }

    if (activeTab === 'search' && searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(m => 
        m.title.toLowerCase().includes(q) ||
        m.vj.toLowerCase().includes(q) ||
        (m.category && m.category.toLowerCase().includes(q))
      );
    }

    return list;
  }, [catalog, activeTab, selectedGenre, selectedVj, searchQuery, myList, sortNewlyToOldy]);

  return (
    <div className="min-h-screen bg-[#010318] text-gray-200 flex flex-col font-sans select-none antialiased">
      {/* ── 1. MunoWatch Sticky Universal Navigation Bar (#universal-nav) ── */}
      <header id="nav-container" className="sticky top-0 z-40 bg-[#010318]/90 backdrop-blur-md border-b border-white/5 transition-all">
        <nav id="universal-nav" className="w-[95%] lg:w-[86%] mx-auto py-3 flex items-center justify-between">
          {/* Left: Brand Logo Wordmark */}
          <div 
            onClick={() => { setActiveTab('home'); setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Latest Movies'); }}
            className="flex items-center gap-2.5 cursor-pointer group"
          >
            <div className="flex items-center">
              <span className="text-xl sm:text-2xl font-black tracking-wider text-white">
                FREE<span className="text-green-500">WATCH</span>
              </span>
              <span className="ml-2 px-1.5 py-0.5 rounded bg-green-500/20 text-green-400 text-[10px] font-black border border-green-500/40">
                LUGANDA
              </span>
            </div>
          </div>

          {/* Center: Main Navigation Links */}
          <div className="hidden lg:flex items-center space-x-1 text-sm font-bold">
            {/* Latest Movies */}
            <button
              onClick={() => { 
                setActiveTab('grid'); 
                setSelectedGenre('All'); 
                setSelectedVj('All'); 
                setPageTitle('Latest Movies'); 
              }}
              className={`px-4 py-2 rounded-md transition-colors ${
                activeTab === 'grid' && selectedGenre === 'All' && selectedVj === 'All'
                  ? 'text-green-500 font-black'
                  : 'text-gray-200 hover:text-green-500'
              }`}
            >
              Latest movies
            </button>

            {/* Series */}
            <button
              onClick={() => { 
                setActiveTab('series'); 
                setSelectedGenre('All'); 
                setSelectedVj('All'); 
                setPageTitle('Series'); 
              }}
              className={`px-4 py-2 rounded-md transition-colors ${
                activeTab === 'series'
                  ? 'text-green-500 font-black'
                  : 'text-gray-200 hover:text-green-500'
              }`}
            >
              Series
            </button>

            {/* Genre Dropdown */}
            <div className="relative inline-block text-left">
              <button
                onClick={(e) => { 
                  e.stopPropagation(); 
                  setGenreDropdownOpen(!genreDropdownOpen); 
                  setVjDropdownOpen(false); 
                }}
                className={`nav-dropdown-btn inline-flex items-center px-4 py-2 rounded-md transition-colors ${
                  genreDropdownOpen || selectedGenre !== 'All' ? 'text-green-500' : 'text-gray-200 hover:text-green-500'
                }`}
              >
                <span>{selectedGenre !== 'All' ? `Genre: ${selectedGenre}` : 'Genre'}</span>
                <ChevronDown className={`ml-1.5 w-4 h-4 transition-transform duration-200 ${genreDropdownOpen ? 'rotate-180' : ''}`} />
              </button>

              {/* Genre Menu */}
              {genreDropdownOpen && (
                <div className="nav-dropdown-menu origin-top-right absolute left-0 mt-2 w-72 rounded-xl shadow-2xl bg-[#010318]/95 backdrop-blur-xl border border-gray-700/60 z-50 p-2.5 max-h-80 overflow-y-auto cinema-scroll animate-in fade-in zoom-in-95 duration-150">
                  <div className="grid grid-cols-2 gap-1.5">
                    <button
                      onClick={() => { setSelectedGenre('All'); setGenreDropdownOpen(false); }}
                      className="text-left px-3 py-1.5 text-xs rounded-md text-gray-300 hover:text-green-400 hover:bg-white/5 font-semibold"
                    >
                      All Genres
                    </button>
                    {GENRES.map((g) => (
                      <button
                        key={g}
                        onClick={() => {
                          setSelectedGenre(g);
                          setPageTitle(`${g} Movies`);
                          setActiveTab('grid');
                          setGenreDropdownOpen(false);
                        }}
                        className={`text-left px-3 py-1.5 text-xs rounded-md font-semibold transition-colors ${
                          selectedGenre === g 
                            ? 'text-green-400 bg-green-500/10 font-bold' 
                            : 'text-gray-300 hover:text-green-400 hover:bg-white/5'
                        }`}
                      >
                        {g}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* VJ Dropdown */}
            <div className="relative inline-block text-left">
              <button
                onClick={(e) => { 
                  e.stopPropagation(); 
                  setVjDropdownOpen(!vjDropdownOpen); 
                  setGenreDropdownOpen(false); 
                }}
                className={`nav-dropdown-btn inline-flex items-center px-4 py-2 rounded-md transition-colors ${
                  vjDropdownOpen || selectedVj !== 'All' ? 'text-green-500' : 'text-gray-200 hover:text-green-500'
                }`}
              >
                <span>{selectedVj !== 'All' ? `VJ: ${selectedVj}` : 'Vj'}</span>
                <ChevronDown className={`ml-1.5 w-4 h-4 transition-transform duration-200 ${vjDropdownOpen ? 'rotate-180' : ''}`} />
              </button>

              {/* VJ Menu */}
              {vjDropdownOpen && (
                <div className="nav-dropdown-menu origin-top-right absolute left-0 mt-2 w-72 rounded-xl shadow-2xl bg-[#010318]/95 backdrop-blur-xl border border-gray-700/60 z-50 p-2.5 max-h-80 overflow-y-auto cinema-scroll animate-in fade-in zoom-in-95 duration-150">
                  <div className="grid grid-cols-2 gap-1.5">
                    <button
                      onClick={() => { setSelectedVj('All'); setVjDropdownOpen(false); }}
                      className="text-left px-3 py-1.5 text-xs rounded-md text-gray-300 hover:text-green-400 hover:bg-white/5 font-semibold"
                    >
                      All VJs
                    </button>
                    {VJ_LIST.map((v) => (
                      <button
                        key={v}
                        onClick={() => {
                          setSelectedVj(v);
                          setPageTitle(`${v} Collection`);
                          setActiveTab('grid');
                          setVjDropdownOpen(false);
                        }}
                        className={`text-left px-3 py-1.5 text-xs rounded-md font-semibold transition-colors ${
                          selectedVj === v 
                            ? 'text-green-400 bg-green-500/10 font-bold' 
                            : 'text-gray-300 hover:text-green-400 hover:bg-white/5'
                        }`}
                      >
                        {v}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Watchlist */}
            <button
              onClick={() => { setActiveTab('watchlist'); setPageTitle('My Watchlist'); }}
              className={`px-4 py-2 rounded-md transition-colors ${
                activeTab === 'watchlist'
                  ? 'text-green-500 font-black'
                  : 'text-gray-200 hover:text-green-500'
              }`}
            >
              Watchlist
            </button>

            {/* Free Movies Status Pill */}
            <div 
              onClick={() => { setActiveTab('grid'); setSelectedGenre('All'); setSelectedVj('All'); }}
              className="px-3 py-1 rounded-full bg-green-500/10 border border-green-500/30 text-green-400 font-bold text-xs cursor-pointer hover:bg-green-500/20 transition-all"
            >
              free movies
            </div>
          </div>

          {/* Right: Actions (Search, Notification, Download App, Mobile Toggle) */}
          <div className="flex items-center space-x-3">
            {/* Search Trigger */}
            <button
              onClick={() => {
                setActiveTab(activeTab === 'search' ? 'home' : 'search');
                setPageTitle('Search Catalog');
              }}
              className={`p-2 rounded-full transition-colors ${
                activeTab === 'search' ? 'bg-green-500 text-black' : 'text-gray-300 hover:text-green-500 hover:bg-white/5'
              }`}
              title="Search"
            >
              <Search className="w-5 h-5" />
            </button>

            {/* Watchlist Quick Count */}
            <button
              onClick={() => setActiveTab('watchlist')}
              className="relative p-2 rounded-full text-gray-300 hover:text-green-500 hover:bg-white/5 transition-colors hidden sm:block"
              title="Saved Watchlist"
            >
              <Heart className="w-5 h-5" />
              {myList.length > 0 && (
                <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-green-500 ring-2 ring-[#010318]" />
              )}
            </button>

            {/* Download App CTA (if available) */}
            {onNavigateToStore && (
              <button
                onClick={onNavigateToStore}
                className="hidden md:flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-green-500/60 text-green-400 hover:bg-green-500 hover:text-black text-xs font-bold transition-all shadow-md"
              >
                <Download className="w-3.5 h-3.5" />
                <span>App</span>
              </button>
            )}

            {/* Mobile Hamburger Toggle */}
            <button
              onClick={() => setMobileNavOpen(!mobileNavOpen)}
              className="p-2 rounded-lg text-gray-300 hover:text-white lg:hidden"
            >
              <Menu className="w-6 h-6" />
            </button>
          </div>
        </nav>

        {/* Mobile Nav Drawer */}
        {mobileNavOpen && (
          <div className="lg:hidden bg-[#010318] border-b border-white/10 px-6 py-4 space-y-3 animate-in slide-in-from-top-4 duration-150">
            <button
              onClick={() => { setActiveTab('grid'); setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Latest Movies'); setMobileNavOpen(false); }}
              className="block w-full text-left py-2 font-bold text-gray-200 hover:text-green-500"
            >
              Latest movies
            </button>
            <button
              onClick={() => { setActiveTab('series'); setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Series'); setMobileNavOpen(false); }}
              className="block w-full text-left py-2 font-bold text-gray-200 hover:text-green-500"
            >
              Series
            </button>
            <button
              onClick={() => { setActiveTab('watchlist'); setPageTitle('My Watchlist'); setMobileNavOpen(false); }}
              className="block w-full text-left py-2 font-bold text-gray-200 hover:text-green-500"
            >
              Watchlist ({myList.length})
            </button>
            <div className="pt-2 border-t border-white/10 flex flex-wrap gap-2">
              <span className="w-full text-xs font-black text-gray-400 uppercase">Top VJs:</span>
              {VJ_LIST.slice(0, 6).map((v) => (
                <button
                  key={v}
                  onClick={() => { setSelectedVj(v); setPageTitle(`${v} Movies`); setActiveTab('grid'); setMobileNavOpen(false); }}
                  className="px-2.5 py-1 rounded bg-white/5 text-xs text-gray-300 hover:text-green-400"
                >
                  {v}
                </button>
              ))}
            </div>
          </div>
        )}
      </header>

      {/* ── 2. Typewriter Marquee Tagline (Authentic MunoWatch Banner) ── */}
      <div className="bg-[#040722] border-b border-white/5 py-2 px-4 text-center select-none overflow-hidden">
        <p className="text-xs sm:text-sm font-semibold tracking-wide text-green-400 transition-all duration-300">
          <span className="text-gray-400 mr-2">●</span>
          {TYPEWRITER_PHRASES[typewriterIndex]}
        </p>
      </div>

      {/* ── 3. Main Content Area ── */}
      <main className="flex-1 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* VIEW A: Search Overlay / Page (search.min.js style) */}
        {activeTab === 'search' && (
          <div className="mb-10 max-w-3xl mx-auto">
            <div id="query-box" className="relative mb-4">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                id="query"
                type="text"
                autoFocus
                placeholder="Search movies, TV series, or VJ name (e.g. VJ Junior, Spider-Man)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-10 py-3.5 rounded-xl bg-[#090C22] border border-gray-700 text-white placeholder-gray-500 text-sm focus:outline-none focus:border-green-500 shadow-xl"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
            <div className="flex items-center justify-between text-xs text-gray-400 px-1">
              <span>{searchQuery ? `Search results for "${searchQuery}"` : 'Browse all catalog'}</span>
              <span>{displayedMovies.length} found</span>
            </div>
          </div>
        )}

        {/* VIEW B: Featured Marquee Hero Billboard (When on Home view without active query) */}
        {activeTab === 'home' && selectedGenre === 'All' && selectedVj === 'All' && (
          <div className="relative w-full rounded-2xl overflow-hidden mb-10 shadow-2xl bg-[#070A1E] border border-white/5">
            {/* Backdrop Banner */}
            <div className="relative h-72 sm:h-96 md:h-[420px] w-full overflow-hidden">
              <img
                src={heroMovie.backdrop || heroMovie.image}
                alt={heroMovie.title}
                className="w-full h-full object-cover object-top filter brightness-85 transform scale-102"
              />
              <div className="absolute inset-0 bg-gradient-to-r from-[#010318] via-[#010318]/75 via-40% to-transparent" />
              <div className="absolute inset-0 bg-gradient-to-t from-[#010318] via-[#010318]/30 to-transparent" />
            </div>

            {/* Hero Details */}
            <div className="absolute bottom-6 sm:bottom-10 left-6 sm:left-10 max-w-xl z-20">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-green-500/20 text-green-400 border border-green-500/40 text-xs font-black tracking-wide mb-3">
                <Sparkles className="w-3.5 h-3.5" />
                FEATURED TRANSLATED RELEASE
              </div>

              <h1 className="text-3xl sm:text-5xl font-black tracking-tight text-white uppercase italic drop-shadow-xl leading-none mb-3">
                {heroMovie.title}
              </h1>

              {/* Frosted Metadata Pill Tags */}
              <div className="flex flex-wrap items-center gap-2 mb-3.5 text-xs font-bold text-gray-300">
                <span className="px-2 py-0.5 rounded bg-white/10 border border-white/10 text-white">HD</span>
                <span className="px-2.5 py-0.5 rounded bg-green-600/90 text-white font-extrabold">{heroMovie.vj}</span>
                <span>•</span>
                <span>{heroMovie.year}</span>
                <span>•</span>
                <span>{heroMovie.runtime}</span>
                <span>•</span>
                <span className="text-yellow-400 flex items-center gap-1">
                  <Star className="w-3.5 h-3.5 fill-current" />
                  {heroMovie.rating}
                </span>
              </div>

              {/* Synopsis */}
              <p className="text-xs sm:text-sm text-gray-300 line-clamp-2 sm:line-clamp-3 mb-6 max-w-lg leading-relaxed">
                {heroMovie.synopsis}
              </p>

              {/* Action Buttons */}
              <div className="flex items-center gap-3">
                <button
                  onClick={() => handlePlay(heroMovie)}
                  className="flex items-center gap-2 bg-green-500 hover:bg-green-600 text-black font-black px-7 py-3 rounded-full shadow-lg shadow-green-500/30 transition-all hover:scale-105 uppercase text-xs sm:text-sm tracking-wide"
                >
                  <Play className="w-4 h-4 fill-black" />
                  Watch Now
                </button>

                <button
                  onClick={() => toggleMyList(heroMovie)}
                  className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white font-bold px-5 py-3 rounded-full border border-white/15 transition-all text-xs sm:text-sm"
                >
                  {myList.some(m => m.id === heroMovie.id) ? (
                    <>
                      <Check className="w-4 h-4 text-green-400" />
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
            </div>
          </div>
        )}

        {/* ── 4. MunoWatch Grid Filter Bar (#grid-filter-bar) ── */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 pb-4 border-b border-white/10">
          <div className="flex items-center gap-3">
            <h2 className="text-lg sm:text-xl font-black text-white flex items-center gap-2">
              <Film className="w-5 h-5 text-green-500" />
              {activeTab === 'series' ? 'TV Series' : (activeTab === 'watchlist' ? 'Saved Watchlist' : pageTitle)}
            </h2>
            <span className="text-xs text-green-400 bg-green-500/10 px-3 py-1 rounded-full border border-green-500/20 font-bold">
              Showing {displayedMovies.length} of {totalCatalogCount.toLocaleString()} Movies
            </span>
          </div>

          {/* Dual Select Options (#vj-options & #genre-options matching grid.min.js) */}
          <div className="flex flex-wrap items-center gap-2.5">
            {/* VJ Option Select */}
            <div className="flex items-center gap-1.5 bg-[#090C22] border border-gray-700 rounded-lg px-3 py-1.5 text-xs text-gray-300">
              <span className="text-gray-400 font-medium">VJ:</span>
              <select
                id="vj-options"
                value={selectedVj}
                onChange={(e) => {
                  setSelectedVj(e.target.value);
                  setPageTitle(e.target.value === 'All' ? 'Latest Movies' : `${e.target.value} Movies`);
                }}
                className="bg-transparent text-white font-bold focus:outline-none cursor-pointer"
              >
                <option value="All" className="bg-[#090C22] text-white">All VJs</option>
                {VJ_LIST.map((v) => (
                  <option key={v} value={v} className="bg-[#090C22] text-white">{v}</option>
                ))}
              </select>
            </div>

            {/* Genre Option Select */}
            <div className="flex items-center gap-1.5 bg-[#090C22] border border-gray-700 rounded-lg px-3 py-1.5 text-xs text-gray-300">
              <span className="text-gray-400 font-medium">Genre:</span>
              <select
                id="genre-options"
                value={selectedGenre}
                onChange={(e) => {
                  setSelectedGenre(e.target.value);
                  setPageTitle(e.target.value === 'All' ? 'Latest Movies' : `${e.target.value} Movies`);
                }}
                className="bg-transparent text-white font-bold focus:outline-none cursor-pointer"
              >
                <option value="All" className="bg-[#090C22] text-white">All Genres</option>
                {GENRES.map((g) => (
                  <option key={g} value={g} className="bg-[#090C22] text-white">{g}</option>
                ))}
              </select>
            </div>

            {/* Reset Filters Button */}
            {(selectedGenre !== 'All' || selectedVj !== 'All') && (
              <button
                onClick={() => { setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Latest Movies'); }}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-bold text-gray-200 transition-colors"
                title="Reset Filters"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                Reset
              </button>
            )}
          </div>
        </div>

        {/* ── 5. MunoWatch Movie Grid (#grid-container) ── */}
        {displayedMovies.length === 0 ? (
          <div className="text-center py-20 bg-white/5 rounded-2xl border border-white/5">
            <Film className="w-12 h-12 text-gray-500 mx-auto mb-3" />
            <h3 className="text-lg font-bold text-white mb-1">No movies match your selected filter</h3>
            <p className="text-xs text-gray-400 mb-4">Try clearing the genre or VJ filter to see more titles.</p>
            <button
              onClick={() => { setSelectedGenre('All'); setSelectedVj('All'); setActiveTab('grid'); }}
              className="px-6 py-2.5 rounded-full bg-green-500 text-black font-extrabold text-xs"
            >
              Show All Movies
            </button>
          </div>
        ) : (
          <div id="grid-container" className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 2xl:grid-cols-6 gap-4 sm:gap-5">
            {displayedMovies.map((movie) => (
              <MunoMovieCard
                key={movie.id}
                movie={movie}
                onPlay={() => handlePlay(movie)}
                onSelect={() => setSelectedMovie(movie)}
              />
            ))}
          </div>
        )}

        {/* ── 6. Infinite Scroll Loading Spinner (#grid-loading-spinner) ── */}
        <div id="grid-loading-spinner" className="mt-12 flex flex-col items-center justify-center gap-3">
          {loadingMore ? (
            <div className="flex items-center gap-3 px-6 py-3 rounded-full bg-white/10 border border-white/15 text-white text-sm font-bold backdrop-blur-md shadow-xl">
              <Loader2 className="w-5 h-5 text-green-500 animate-spin" />
              Loading more Luganda movies (Newly to Oldy)...
            </div>
          ) : hasMoreCatalog ? (
            <button
              onClick={loadMoreMovies}
              className="group flex items-center gap-2.5 px-8 py-3 rounded-full bg-[#0a0d24] hover:bg-[#12163b] border border-gray-700 hover:border-green-500 text-white font-extrabold text-sm tracking-wide transition-all shadow-xl hover:scale-105"
            >
              <span>Load More Movies (Newly to Oldy)</span>
              <ChevronDown className="w-4 h-4 text-green-500 group-hover:translate-y-0.5 transition-transform" />
            </button>
          ) : (
            <div className="text-xs font-bold text-gray-500 uppercase tracking-widest py-4">
              ✓ All {totalCatalogCount.toLocaleString()} Luganda movies loaded
            </div>
          )}
          <span className="text-[11px] text-gray-500">
            Scroll down to continuously load next batches of 40 movies
          </span>
        </div>
      </main>

      {/* ── 7. Movie Detail Modal ── */}
      {selectedMovie && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-2xl flex items-center justify-center p-4 md:p-8 overflow-y-auto">
          <div className="relative w-full max-w-3xl bg-[#080B1E] border border-white/15 rounded-3xl overflow-hidden shadow-2xl my-auto animate-in fade-in zoom-in-95 duration-200">
            {/* Close Button */}
            <button
              onClick={() => setSelectedMovie(null)}
              className="absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/70 hover:bg-black border border-white/20 flex items-center justify-center text-white backdrop-blur-md transition-colors"
            >
              <X className="w-4 h-4" />
            </button>

            {/* Modal Backdrop Banner */}
            <div className="relative h-56 md:h-72 w-full overflow-hidden">
              <img 
                src={selectedMovie.backdrop || selectedMovie.image}
                alt={selectedMovie.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#080B1E] via-[#080B1E]/60 to-transparent" />
            </div>

            {/* Modal Body */}
            <div className="p-6 md:p-8 -mt-16 relative z-10">
              {/* VJ Tag */}
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-green-500/20 border border-green-500/40 text-green-400 text-xs font-black mb-3">
                <Sparkles className="w-3.5 h-3.5 text-green-400" />
                Translated by {selectedMovie.vj}
              </div>

              <h2 className="text-2xl md:text-4xl font-black text-white mb-2 leading-tight">
                {selectedMovie.title}
              </h2>

              {/* Metadata */}
              <div className="flex flex-wrap items-center gap-3 text-xs md:text-sm text-gray-400 font-medium mb-5">
                <span className="flex items-center gap-1 text-yellow-400 font-bold">
                  <Star className="w-4 h-4 fill-yellow-400" />
                  {selectedMovie.rating}
                </span>
                <span>•</span>
                <span>{selectedMovie.year}</span>
                <span>•</span>
                <span>{selectedMovie.runtime}</span>
                <span>•</span>
                <span className="px-2 py-0.5 rounded bg-white/10 text-white font-bold text-xs">HD</span>
                <span className="px-2 py-0.5 rounded bg-green-500/10 text-green-400 border border-green-500/30 font-semibold text-xs">
                  {selectedMovie.category}
                </span>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-3 mb-6">
                <button
                  onClick={() => handlePlay(selectedMovie)}
                  className="flex items-center gap-2 bg-green-500 hover:bg-green-600 text-black font-black px-8 py-3 rounded-full shadow-lg shadow-green-500/30 transition-all hover:scale-105 uppercase text-xs sm:text-sm tracking-wide"
                >
                  <Play className="w-4 h-4 fill-black" />
                  Watch Now
                </button>

                <button
                  onClick={() => toggleMyList(selectedMovie)}
                  className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-5 py-3 rounded-full border border-white/15 transition-colors text-xs sm:text-sm"
                >
                  {myList.some(m => m.id === selectedMovie.id) ? (
                    <>
                      <Check className="w-4 h-4 text-green-400" />
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
                <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">Synopsis</h3>
                <p className="text-sm md:text-base text-gray-300 leading-relaxed">
                  {selectedMovie.synopsis}
                </p>
              </div>

              {/* Episodes (If TV Series) */}
              {selectedMovie.isTv && selectedMovie.episodes && selectedMovie.episodes.length > 0 && (
                <div className="mb-6">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">Episodes</h3>
                  <div className="space-y-2 max-h-48 overflow-y-auto cinema-scroll">
                    {selectedMovie.episodes.map((ep) => (
                      <div 
                        key={ep.id}
                        onClick={() => handlePlay({ ...selectedMovie, streamUrl: ep.streamUrl, title: `${selectedMovie.title} - Episode ${ep.episodeNumber}` })}
                        className="flex items-center justify-between p-3.5 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-6 h-6 rounded-full bg-green-500/20 text-green-400 flex items-center justify-center font-bold text-xs">
                            {ep.episodeNumber}
                          </div>
                          <span className="font-semibold text-sm text-white">{ep.name}</span>
                        </div>
                        <Play className="w-4 h-4 text-green-400 fill-green-400" />
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── 8. Fullscreen Video Player Modal ── */}
      {activeStreamUrl && (
        <div className="fixed inset-0 z-60 bg-black flex flex-col justify-center items-center">
          <div className="absolute top-6 left-6 right-6 z-20 flex items-center justify-between">
            <button
              onClick={() => setActiveStreamUrl('')}
              className="flex items-center gap-2 px-4 py-2 rounded-full bg-black/70 hover:bg-black border border-white/15 text-white backdrop-blur-md text-sm font-bold transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Close Player
            </button>

            {selectedMovie && (
              <span className="text-sm font-bold text-white bg-black/70 px-4 py-2 rounded-full border border-white/10 backdrop-blur-md">
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

      {/* ── 9. MunoWatch 4-Column Footer (Matching munowatch.com) ── */}
      <footer className="bg-[#010318] border-t border-white/10 pt-12 pb-8 text-gray-400 text-sm mt-16 select-none">
        <div className="w-[95%] lg:w-[86%] mx-auto grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8 mb-10">
          {/* Column 1: Brand & Copyright */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <span className="text-xl font-black text-white">
                FREE<span className="text-green-500">WATCH</span>
              </span>
            </div>
            <p className="text-xs text-gray-500 leading-relaxed mb-4">
              Watch translated Luganda dubbed movies and TV shows online anytime, anywhere.
            </p>
            <p className="text-xs text-gray-500">
              {new Date().getFullYear()} &copy; FreeWatch. All Rights Reserved.
            </p>
          </div>

          {/* Column 2: FAQ */}
          <div>
            <h4 className="text-white font-bold text-base mb-4">FAQ</h4>
            <ul className="space-y-2.5 text-xs text-gray-400">
              <li><a href="#about" onClick={(e) => { e.preventDefault(); setActiveTab('home'); }} className="hover:text-green-400 transition-colors">About Us</a></li>
              <li><a href="#dmca" onClick={(e) => { e.preventDefault(); alert("DMCA notice: FreeWatch indexes publicly available links provided by MunoWatch CDN."); }} className="hover:text-green-400 transition-colors">DMCA</a></li>
              <li><a href="#privacy" onClick={(e) => { e.preventDefault(); }} className="hover:text-green-400 transition-colors">Privacy Policy</a></li>
              <li><a href="#terms" onClick={(e) => { e.preventDefault(); }} className="hover:text-green-400 transition-colors">Terms &amp; Conditions</a></li>
            </ul>
          </div>

          {/* Column 3: CONTACTS */}
          <div>
            <h4 className="text-white font-bold text-base mb-4">CONTACTS</h4>
            <ul className="space-y-2.5 text-xs text-gray-400">
              <li className="flex items-center gap-2">
                <span className="text-green-400">✉</span>
                <a href="mailto:info@freewatchug.online" className="hover:text-green-400 transition-colors">info@freewatchug.online</a>
              </li>
              <li className="flex items-center gap-2">
                <MessageCircle className="w-3.5 h-3.5 text-green-400" />
                <a href="https://wa.me/+256782970036" target="_blank" rel="noopener noreferrer" className="hover:text-green-400 transition-colors">WhatsApp +256 782-970-036</a>
              </li>
              <li className="text-[11px] text-gray-500 mt-2">
                Available 24/7 for support &amp; inquiries.
              </li>
            </ul>
          </div>

          {/* Column 4: FOLLOW US */}
          <div>
            <h4 className="text-white font-bold text-base mb-4">FOLLOW US</h4>
            <div className="flex items-center gap-3">
              <a 
                href="https://facebook.com" 
                target="_blank" 
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-lg bg-white/5 hover:bg-green-500/20 border border-white/10 hover:border-green-500/50 flex items-center justify-center text-gray-300 hover:text-green-400 transition-all"
                title="Facebook"
              >
                <span className="font-bold text-xs">FB</span>
              </a>
              <a 
                href="https://x.com" 
                target="_blank" 
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-lg bg-white/5 hover:bg-green-500/20 border border-white/10 hover:border-green-500/50 flex items-center justify-center text-gray-300 hover:text-green-400 transition-all"
                title="X / Twitter"
              >
                <span className="font-bold text-xs">X</span>
              </a>
              <a 
                href="https://instagram.com" 
                target="_blank" 
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-lg bg-white/5 hover:bg-green-500/20 border border-white/10 hover:border-green-500/50 flex items-center justify-center text-gray-300 hover:text-green-400 transition-all"
                title="Instagram"
              >
                <span className="font-bold text-xs">IG</span>
              </a>
              <a 
                href="https://wa.me/+256782970036" 
                target="_blank" 
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-lg bg-white/5 hover:bg-green-500/20 border border-white/10 hover:border-green-500/50 flex items-center justify-center text-gray-300 hover:text-green-400 transition-all"
                title="WhatsApp"
              >
                <MessageCircle className="w-4 h-4" />
              </a>
            </div>
            <div className="mt-4">
              <p className="text-[11px] text-gray-500">
                Official FreeWatch Luganda Dubbed Network
              </p>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

// ── Shared MunoWatch Movie Card (2:3 Aspect Ratio, tile-img fallback, hover scale & green play) ──
function MunoMovieCard({ movie, onPlay, onSelect }) {
  return (
    <div 
      onClick={onSelect}
      className="group relative flex flex-col cursor-pointer transition-all duration-300 select-none"
    >
      {/* 2:3 Poster Frame */}
      <div className="relative aspect-[2/3] w-full rounded-xl overflow-hidden bg-[#0d0f1a] border border-white/10 group-hover:border-green-500/80 group-hover:shadow-[0_0_20px_rgba(34,197,94,0.35)] transition-all duration-300">
        <img 
          src={movie.image}
          alt={movie.title}
          loading="lazy"
          onError={(e) => {
            e.currentTarget.src = 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop&q=80';
          }}
          className="tile-img w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
        />

        {/* Top Badges: HD on left, VJ on right */}
        <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded bg-black/75 text-[9px] font-bold text-white border border-white/20 backdrop-blur-sm">
          HD
        </div>

        {movie.vj && (
          <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-green-600/90 text-[9px] font-black text-white shadow-md">
            {movie.vj}
          </div>
        )}

        {/* Hover Center Play Button */}
        <div className="absolute inset-0 flex items-center justify-center bg-black/35 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          <button 
            onClick={(e) => { e.stopPropagation(); onPlay(); }}
            className="w-12 h-12 rounded-full bg-green-500 hover:bg-green-400 text-black flex items-center justify-center shadow-2xl transform scale-75 group-hover:scale-100 transition-transform duration-200"
            title="Play Movie"
          >
            <Play className="w-5 h-5 fill-black ml-0.5" />
          </button>
        </div>

        {/* Bottom Rating and Year Overlay */}
        <div className="absolute inset-x-0 bottom-0 p-2.5 bg-gradient-to-t from-black/95 via-black/50 to-transparent flex items-center justify-between">
          <span className="flex items-center gap-1 text-[11px] font-bold text-yellow-400">
            <Star className="w-3 h-3 fill-yellow-400" />
            {movie.rating}
          </span>
          <span className="text-[10px] text-gray-300 font-medium">{movie.year}</span>
        </div>
      </div>

      {/* Movie Title */}
      <h3 className="mt-2 text-xs sm:text-sm font-bold text-gray-200 line-clamp-1 group-hover:text-green-400 transition-colors">
        {movie.title}
      </h3>
    </div>
  );
}
