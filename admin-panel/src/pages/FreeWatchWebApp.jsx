import React, { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { 
  Play, Search, Bell, Star, Film, ChevronDown, X, 
  ArrowLeft, Plus, Check, Loader2, RotateCcw, Menu
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// Initial fallback catalog
const INITIAL_MOVIES = [
  {
    id: 67421,
    title: 'Mirzapur 16',
    vj: 'VJ Ashim',
    category: 'Series',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    rating: '9.2',
    year: '2025',
    runtime: '50m',
    isTv: true,
    seriesCode: '33624',
    synopsis: 'The thrilling climax of Mirzapur season in high-definition Luganda voice-over translation by VJ Ashim.',
    streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4'
  },
  {
    id: 67406,
    title: 'Mirzapur',
    vj: 'VJ Ashim',
    category: 'Series',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    rating: '9.1',
    year: '2025',
    runtime: '50m',
    isTv: true,
    seriesCode: '33624',
    synopsis: 'A shocking incident at a wedding procession ignites a series of events entangling two families in the lawless city of Mirzapur.',
    streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4'
  },
  {
    id: 67384,
    title: 'Living For Love',
    vj: 'VJ Sammy',
    category: 'Romance',
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    rating: '8.7',
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
    rating: '8.9',
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
    rating: '8.6',
    year: '2024',
    runtime: '1h 42m',
    isTv: false,
    synopsis: 'A young woman staying at an Airbnb rental discovers that the house is not what it seems to be.',
    streamUrl: ''
  },
  {
    id: 67342,
    title: 'Self Made: Inspired by the Life of Madam C.J. Walker',
    vj: 'VJ Aaron',
    category: 'Series',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg',
    rating: '8.8',
    year: '2024',
    runtime: '46m',
    isTv: true,
    seriesCode: '26058',
    synopsis: 'The inspiring story of trailblazing African American entrepreneur Madam C.J. Walker.',
    streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4'
  }
];

// Exact Typewriter Items from MunoWatch.com index.html
const TYPEWRITER_ITEMS = [
  "We make it",
  "Easy",
  "Comfortable",
  "To watch foreign",
  "TV shows and films",
  "Spiced up by",
  "Vj Junior",
  "vj Emmy",
  "Vj Jingo",
  "Vj Mark",
  "Omutaka Ice P",
  "Vj Sammy",
  "and more! ..."
];

// Exact Genres from MunoWatch.com
const GENRES = [
  'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 
  'Documentary', 'Drama', 'Family', 'Fantasy', 'History', 
  'Horror', 'Music', 'Mystery', 'Romance', 'Sci-Fi', 
  'Thriller', 'War', 'Western'
];

// Exact VJs from MunoWatch.com
const VJ_LIST = [
  'VJ Junior', 'VJ Emmy', 'VJ Jingo', 'VJ Ice P', 'VJ Ulio',
  'VJ Heavy Q', 'VJ Sammy', 'VJ Mark', 'VJ Aaron', 'VJ Banks',
  'VJ Muba', 'VJ Ivo', 'VJ Kevin', 'VJ Dan', 'VJ Ashim', 'VJ Smart'
];

export default function FreeWatchWebApp({ onNavigateToStore }) {
  // View mode: 'landing' (exact MunoWatch homepage video/typewriter) or 'browse' (grid catalog)
  const [viewMode, setViewMode] = useState('landing');
  const [catalog, setCatalog] = useState(INITIAL_MOVIES);
  const [catalogPage, setCatalogPage] = useState(1);
  const [hasMoreCatalog, setHasMoreCatalog] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [totalCatalogCount, setTotalCatalogCount] = useState(7097);

  // MunoWatch Navigation & Filter States
  const [pipeType, setPipeType] = useState('p'); // 'p' (latest) | 'g' (series/genre) | 'vj' | 'fr'
  const [pageTitle, setPageTitle] = useState('Latest movies');
  const [selectedGenre, setSelectedGenre] = useState('All');
  const [selectedVj, setSelectedVj] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [genreDropdownOpen, setGenreDropdownOpen] = useState(false);
  const [vjDropdownOpen, setVjDropdownOpen] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Player & Detail Modal
  const [selectedMovie, setSelectedMovie] = useState(null);
  const [activeStreamUrl, setActiveStreamUrl] = useState('');

  // Watchlist
  const [myList, setMyList] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_my_list') || '[]');
    } catch (_) {
      return [];
    }
  });

  // Typewriter text state
  const [currentTypewriterText, setCurrentTypewriterText] = useState('');
  const [typewriterIndex, setTypewriterIndex] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);

  // Typewriter animation cycle matching MunoWatch.com
  useEffect(() => {
    const fullText = TYPEWRITER_ITEMS[typewriterIndex];
    let speed = isDeleting ? 40 : 80;

    if (!isDeleting && currentTypewriterText === fullText) {
      speed = 1500; // Pause at end of text
    }

    const timer = setTimeout(() => {
      if (!isDeleting) {
        if (currentTypewriterText.length < fullText.length) {
          setCurrentTypewriterText(fullText.slice(0, currentTypewriterText.length + 1));
        } else {
          setIsDeleting(true);
        }
      } else {
        if (currentTypewriterText.length > 0) {
          setCurrentTypewriterText(fullText.slice(0, currentTypewriterText.length - 1));
        } else {
          setIsDeleting(false);
          setTypewriterIndex((prev) => (prev + 1) % TYPEWRITER_ITEMS.length);
        }
      }
    }, speed);

    return () => clearTimeout(timer);
  }, [currentTypewriterText, isDeleting, typewriterIndex]);

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
      if (viewMode !== 'browse') return;
      const scrollHeight = document.documentElement.scrollHeight;
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const clientHeight = window.innerHeight;

      if (scrollHeight - (scrollTop + clientHeight) < 850) {
        loadMoreMovies();
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [loadMoreMovies, viewMode]);

  // Initial load on mount
  useEffect(() => {
    let isMounted = true;
    fetchMoviePage(1, true);

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
                backdrop: m.backdrop || m.cover || m.image || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
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

  // Play stream resolver
  const handlePlay = async (movie) => {
    setSelectedMovie(movie);
    setActiveStreamUrl('');

    if (movie.streamUrl && movie.streamUrl.startsWith('http')) {
      setActiveStreamUrl(movie.streamUrl);
      return;
    }

    try {
      const res = await fetch(`https://mumowatch.ai.studio/movie/${movie.id}`).catch(() => null);
      if (res && res.ok) {
        const data = await res.json();
        const url = data.playingurl || data.playingUrl || data.url;
        if (url && url.startsWith('http')) {
          setActiveStreamUrl(url);
          return;
        }
      }
    } catch (_) {}

    setActiveStreamUrl('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
  };

  // Filtered movies calculation (combines pipeType, series, genre, vj, and search)
  const displayedMovies = useMemo(() => {
    let list = sortNewlyToOldy(catalog);

    if (pipeType === 'series') {
      list = list.filter(m => m.isTv || /series|season|episode/i.test(m.category + ' ' + m.title));
    } else if (pipeType === 'watchlist') {
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

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(m => 
        m.title.toLowerCase().includes(q) ||
        m.vj.toLowerCase().includes(q) ||
        (m.category && m.category.toLowerCase().includes(q))
      );
    }

    return list;
  }, [catalog, pipeType, selectedGenre, selectedVj, searchQuery, myList, sortNewlyToOldy]);

  return (
    <div className="bg-[#010318] text-gray-200 flex flex-col min-h-screen w-full font-sans select-none antialiased relative">
      
      {/* ═════════════════════════════════════════════════════════════════════
          PAGE 1: EXACT MUNOWATCH.COM LANDING HOMEPAGE
      ═════════════════════════════════════════════════════════════════════ */}
      {viewMode === 'landing' && (
        <div className="relative min-h-screen w-full flex flex-col justify-between overflow-hidden">
          {/* Top Landing Header matching munowatch.com: div class="flex justify-around bg-gradient-to-b from-[#010318] to-transparent p-4" */}
          <div className="flex justify-between sm:justify-around items-center bg-gradient-to-b from-[#010318] via-[#010318]/70 to-transparent p-4 z-20">
            {/* Wordmark Logo */}
            <div 
              onClick={() => setViewMode('landing')}
              className="cursor-pointer flex items-center"
            >
              <span className="text-2xl sm:text-3xl font-black tracking-wider text-white">
                FREE<span className="text-green-500">WATCH</span>
              </span>
            </div>

            {/* Buttons: Browse Movies & Log In */}
            <div className="flex items-center gap-3">
              <button
                onClick={() => setViewMode('browse')}
                className="p-2 px-4 border border-green-500 text-green-500 rounded-md hover:bg-green-700 hover:text-white font-bold transition-all text-sm shadow-lg"
              >
                Log In
              </button>

              <button
                onClick={() => setViewMode('browse')}
                className="p-2 px-4 bg-green-500 text-black font-extrabold rounded-md hover:bg-green-400 transition-all text-sm shadow-lg"
              >
                Browse Movies
              </button>
            </div>
          </div>

          {/* Center Main Typewriter Hero matching munowatch.com */}
          <main className="container mx-auto flex flex-col justify-center items-center p-4 z-20 flex-1 my-auto">
            <div className="h-[65vh] flex flex-col justify-center items-center text-center px-4 space-y-8">
              {/* Typewriter text container */}
              <div id="typedata" className="min-h-[120px] flex items-center justify-center">
                <h1 className="text-4xl sm:text-6xl lg:text-7xl font-bold text-white text-center leading-tight">
                  {currentTypewriterText}
                  <span className="inline-block w-1.5 h-10 sm:h-14 bg-green-500 ml-1.5 animate-pulse align-middle" />
                </h1>
              </div>

              {/* Get Started Button matching munowatch.com */}
              <button
                onClick={() => setViewMode('browse')}
                className="p-3.5 px-8 border border-white text-white rounded-full bg-white/20 hover:bg-green-500 hover:text-black font-bold text-base sm:text-lg transition-all backdrop-blur-md shadow-2xl hover:scale-105 inline-block"
              >
                Get Started
              </button>
            </div>
          </main>

          {/* Fullscreen Background Video matching munowatch.com: line 112 */}
          <video 
            playsInline 
            poster="https://munowatch.com/assets/images/playbg.jpg" 
            autoPlay 
            muted 
            loop 
            className="fixed top-0 left-0 object-cover sm:min-w-[100vw] w-full h-[100vh] -z-10"
          >
            <source src="https://munotek-vault.b-cdn.net/CLIPS/MOVIES%20HD.mp4" type="video/mp4" />
          </video>

          {/* MunoWatch Footer on Landing Page */}
          <MunoFooter onSelectTab={(tab) => { setViewMode('browse'); setPipeType(tab); }} />
        </div>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          PAGE 2: EXACT MUNOWATCH.COM BROWSE GRID & MOVIE PORTAL
      ═════════════════════════════════════════════════════════════════════ */}
      {viewMode === 'browse' && (
        <div className="min-h-screen flex flex-col w-full">
          {/* ── MunoWatch Universal Nav Bar (#universal-nav) ──────────────── */}
          <div id="nav-container" data-cantransform="0" className="sticky bg-[#010318]/90 backdrop-blur-md px-0 py-2.5 text-white flex z-40 top-0 border-b border-white/5 transition-all">
            <nav id="universal-nav" className="w-[95%] lg:w-[86%] mx-auto flex flex-col lg:flex-row justify-between items-start lg:items-center" style={{ textShadow: '2px 2px 4px rgba(0, 0, 0, 0.6)' }}>
              <div className="flex items-center justify-between w-full lg:w-auto">
                {/* Brand Logo Wordmark */}
                <div 
                  onClick={() => setViewMode('landing')}
                  className="cursor-pointer flex items-center gap-2"
                >
                  <span className="text-2xl font-black text-white">
                    FREE<span className="text-green-500">WATCH</span>
                  </span>
                </div>

                {/* Mobile hamburger button */}
                <button 
                  onClick={() => setMobileNavOpen(!mobileNavOpen)}
                  className="lg:hidden text-gray-300 hover:text-white p-2" 
                  id="open-nav-btn"
                >
                  <Menu className="w-6 h-6" />
                </button>
              </div>

              <div className={`flex-col lg:flex-row lg:items-center w-full lg:w-auto ${mobileNavOpen ? 'flex' : 'hidden lg:flex'}`}>
                {/* Main Nav Links */}
                <ul className="lg:flex items-center lg:text-xs font-bold text-left lg:text-right nav-list divide-y lg:divide-y-0 divide-gray-800 lg:divide-transparent mt-3 lg:mt-0">
                  {/* Latest movies */}
                  <li className="w-full py-2 lg:px-1">
                    <button
                      onClick={() => { setPipeType('p'); setPageTitle('Latest movies'); setSelectedGenre('All'); setSelectedVj('All'); setMobileNavOpen(false); }}
                      className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${pipeType === 'p' && selectedGenre === 'All' && selectedVj === 'All' ? 'text-green-500 font-black' : ''}`}
                    >
                      Latest movies
                    </button>
                  </li>

                  {/* Series */}
                  <li className="w-full py-2 lg:px-1">
                    <button
                      onClick={() => { setPipeType('series'); setPageTitle('Series'); setSelectedGenre('All'); setSelectedVj('All'); setMobileNavOpen(false); }}
                      className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${pipeType === 'series' ? 'text-green-500 font-black' : ''}`}
                    >
                      Series
                    </button>
                  </li>

                  {/* Genre Dropdown */}
                  <li className="w-full py-2 lg:px-1 relative">
                    <button
                      onClick={(e) => { e.stopPropagation(); setGenreDropdownOpen(!genreDropdownOpen); setVjDropdownOpen(false); }}
                      className="inline-flex items-center justify-between lg:justify-center w-full rounded-md px-4 py-2 hover:text-green-500 text-nowrap nav-dropdown-btn"
                    >
                      <span>{selectedGenre !== 'All' ? `Genre: ${selectedGenre}` : 'Genre'}</span>
                      <ChevronDown className="ml-1.5 w-4 h-4" />
                    </button>

                    {genreDropdownOpen && (
                      <div className="nav-dropdown-menu origin-top-right absolute left-0 lg:right-0 mt-2 w-72 rounded-md shadow-2xl bg-[#010318] backdrop-blur-md border border-gray-700 z-50 p-2.5 max-h-80 overflow-y-auto cinema-scroll animate-in fade-in zoom-in-95 duration-100">
                        <div className="grid grid-cols-2 gap-1">
                          <button
                            onClick={() => { setSelectedGenre('All'); setGenreDropdownOpen(false); setMobileNavOpen(false); }}
                            className="text-left px-3 py-1.5 text-xs text-gray-300 hover:text-green-500"
                          >
                            All Genres
                          </button>
                          {GENRES.map((g) => (
                            <button
                              key={g}
                              onClick={() => { setSelectedGenre(g); setPageTitle(`${g} Movies`); setPipeType('p'); setGenreDropdownOpen(false); setMobileNavOpen(false); }}
                              className={`text-left px-3 py-1.5 text-xs hover:text-green-500 ${selectedGenre === g ? 'text-green-400 font-bold' : 'text-gray-300'}`}
                            >
                              {g}
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                  </li>

                  {/* VJ Dropdown */}
                  <li className="w-full py-2 lg:px-1 relative">
                    <button
                      onClick={(e) => { e.stopPropagation(); setVjDropdownOpen(!vjDropdownOpen); setGenreDropdownOpen(false); }}
                      className="inline-flex items-center justify-between lg:justify-center w-full rounded-md px-4 py-2 hover:text-green-500 text-nowrap nav-dropdown-btn"
                    >
                      <span>{selectedVj !== 'All' ? `VJ: ${selectedVj}` : 'Vj'}</span>
                      <ChevronDown className="ml-1.5 w-4 h-4" />
                    </button>

                    {vjDropdownOpen && (
                      <div className="nav-dropdown-menu origin-top-right absolute left-0 lg:right-0 mt-2 w-72 rounded-md shadow-2xl bg-[#010318] backdrop-blur-md border border-gray-700 z-50 p-2.5 max-h-80 overflow-y-auto cinema-scroll animate-in fade-in zoom-in-95 duration-100">
                        <div className="grid grid-cols-2 gap-1">
                          <button
                            onClick={() => { setSelectedVj('All'); setVjDropdownOpen(false); setMobileNavOpen(false); }}
                            className="text-left px-3 py-1.5 text-xs text-gray-300 hover:text-green-500"
                          >
                            All VJs
                          </button>
                          {VJ_LIST.map((v) => (
                            <button
                              key={v}
                              onClick={() => { setSelectedVj(v); setPageTitle(`${v} Movies`); setPipeType('p'); setVjDropdownOpen(false); setMobileNavOpen(false); }}
                              className={`text-left px-3 py-1.5 text-xs hover:text-green-500 ${selectedVj === v ? 'text-green-400 font-bold' : 'text-gray-300'}`}
                            >
                              {v}
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                  </li>

                  {/* Watchlist */}
                  <li className="w-full py-2 lg:px-1">
                    <button
                      onClick={() => { setPipeType('watchlist'); setPageTitle('Watchlist'); setMobileNavOpen(false); }}
                      className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${pipeType === 'watchlist' ? 'text-green-500 font-black' : ''}`}
                    >
                      Watchlist ({myList.length})
                    </button>
                  </li>

                  {/* Free Movies pill */}
                  <li className="w-full py-2 lg:px-1">
                    <div 
                      onClick={() => { setPipeType('p'); setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Free movies'); setMobileNavOpen(false); }}
                      id="days-remaining" 
                      className="text-green-300 hover:text-green-500 text-nowrap font-bold px-4 py-2 cursor-pointer"
                    >
                      free movies
                    </div>
                  </li>
                </ul>

                {/* Right utility icons: notification & search */}
                <ul className="flex items-center text-sm nav-list lg:ml-2 gap-3 py-2 lg:py-0">
                  <li>
                    <button 
                      onClick={() => alert(`FreeWatch Notifications: ${totalCatalogCount.toLocaleString()} movies available freshly synced from MunoWatch!`)}
                      className="hover:text-green-500 inline-block p-1"
                      title="Notifications"
                    >
                      <Bell className="w-5 h-5" />
                    </button>
                  </li>
                  <li>
                    <button 
                      onClick={() => setShowSearch(!showSearch)}
                      className={`hover:text-green-500 inline-block p-1 ${showSearch ? 'text-green-500' : ''}`}
                      title="Search"
                    >
                      <Search className="w-5 h-5" />
                    </button>
                  </li>
                  <li>
                    <button
                      onClick={() => setViewMode('landing')}
                      className="text-xs font-bold text-gray-400 hover:text-white px-2.5 py-1 rounded border border-gray-700"
                    >
                      Home
                    </button>
                  </li>
                </ul>
              </div>
            </nav>
          </div>

          {/* ── Search Query Box (Matching search.min.js: #query-box) ───── */}
          {showSearch && (
            <div className="w-[95%] lg:w-[86%] mx-auto my-4 transition-all animate-in slide-in-from-top-2 duration-150">
              <div id="query-box" className="relative w-full">
                <input
                  id="query"
                  type="text"
                  autoFocus
                  placeholder="Search movies, TV series, or VJ name..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full p-3.5 pl-11 rounded-md bg-[#0a0d24] border border-gray-700 text-white placeholder-gray-500 text-sm focus:outline-none focus:border-green-500 shadow-xl"
                />
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                {searchQuery && (
                  <button 
                    onClick={() => setSearchQuery('')}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          )}

          {/* ── Main Catalog Grid Container (#grid-container) ─────────────── */}
          <main className="w-full max-w-[95%] lg:max-w-[86%] mx-auto py-6 flex-1">
            {/* Filter Bar with VJ & Genre dropdowns matching grid.min.js */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3.5 mb-6 border-b border-gray-800 gap-3">
              <div className="flex items-center gap-2.5">
                <span className="w-2.5 h-2.5 rounded-full bg-green-500"></span>
                <h2 className="text-xl font-bold text-white tracking-wide">
                  {pageTitle}
                </h2>
                <span className="text-xs text-green-400 bg-green-500/10 px-2.5 py-0.5 rounded-full border border-green-500/20 font-semibold ml-2">
                  {displayedMovies.length} of {totalCatalogCount.toLocaleString()}
                </span>
              </div>

              {/* Dual Filter Dropdowns (#vj-options & #genre-options) */}
              <div className="flex items-center gap-2">
                <select
                  id="vj-options"
                  value={selectedVj}
                  onChange={(e) => setSelectedVj(e.target.value)}
                  className="bg-[#0a0d24] border border-gray-700 text-xs text-white rounded p-1.5 focus:outline-none focus:border-green-500 cursor-pointer"
                >
                  <option value="All">All VJs</option>
                  {VJ_LIST.map((v) => (
                    <option key={v} value={v}>{v}</option>
                  ))}
                </select>

                <select
                  id="genre-options"
                  value={selectedGenre}
                  onChange={(e) => setSelectedGenre(e.target.value)}
                  className="bg-[#0a0d24] border border-gray-700 text-xs text-white rounded p-1.5 focus:outline-none focus:border-green-500 cursor-pointer"
                >
                  <option value="All">All Genres</option>
                  {GENRES.map((g) => (
                    <option key={g} value={g}>{g}</option>
                  ))}
                </select>

                {(selectedGenre !== 'All' || selectedVj !== 'All' || searchQuery) && (
                  <button
                    onClick={() => { setSelectedGenre('All'); setSelectedVj('All'); setSearchQuery(''); }}
                    className="p-1.5 rounded bg-gray-800 hover:bg-gray-700 text-gray-300 hover:text-white"
                    title="Reset Filters"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
            </div>

            {/* Movie Poster Grid matching output.css: lg:w-[214.5px] lg:h-[299px] */}
            {displayedMovies.length === 0 ? (
              <div className="text-center py-20 bg-white/5 rounded-lg border border-gray-800">
                <Film className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                <h3 className="text-lg font-bold text-white mb-1">No movies found</h3>
                <p className="text-xs text-gray-400 mb-4">Try clearing filters to browse more titles.</p>
                <button
                  onClick={() => { setSelectedGenre('All'); setSelectedVj('All'); setSearchQuery(''); setPipeType('p'); }}
                  className="px-5 py-2 rounded-md bg-green-500 text-black font-bold text-xs"
                >
                  Show All Movies
                </button>
              </div>
            ) : (
              <div id="grid-container" className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 2xl:grid-cols-6 gap-3.5 sm:gap-5 justify-center">
                {displayedMovies.map((movie) => (
                  <MunoMoviePosterCard
                    key={movie.id}
                    movie={movie}
                    onPlay={() => handlePlay(movie)}
                    onSelect={() => setSelectedMovie(movie)}
                  />
                ))}
              </div>
            )}

            {/* Infinite Scroll Spinner matching grid.min.js: #grid-loading-spinner */}
            <div id="grid-loading-spinner" className="mt-12 flex flex-col items-center justify-center gap-3">
              {loadingMore ? (
                <div className="flex items-center gap-2.5 px-6 py-2.5 rounded-full bg-white/10 border border-white/10 text-white text-xs font-bold shadow-lg">
                  <Loader2 className="w-4 h-4 text-green-500 animate-spin" />
                  <span>Loading more movies (Newly to Oldy)...</span>
                </div>
              ) : hasMoreCatalog ? (
                <button
                  onClick={loadMoreMovies}
                  className="flex items-center gap-2 px-8 py-2.5 rounded-full bg-[#0a0d24] hover:bg-gray-800 border border-gray-700 hover:border-green-500 text-white font-bold text-xs transition-all shadow-lg hover:scale-105"
                >
                  <span>Load More Movies (Newly to Oldy)</span>
                  <ChevronDown className="w-3.5 h-3.5 text-green-500" />
                </button>
              ) : (
                <div className="text-xs font-bold text-gray-600 uppercase tracking-widest py-4">
                  ✓ All {totalCatalogCount.toLocaleString()} movies loaded
                </div>
              )}
            </div>
          </main>

          {/* MunoWatch Footer on Browse Page */}
          <MunoFooter onSelectTab={(tab) => { setPipeType(tab); }} />
        </div>
      )}

      {/* ── Movie Detail Modal ────────────────────────────────────────── */}
      {selectedMovie && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-xl flex items-center justify-center p-4 overflow-y-auto">
          <div className="relative w-full max-w-2xl bg-[#080B1E] border border-gray-800 rounded-xl overflow-hidden shadow-2xl my-auto animate-in fade-in zoom-in-95 duration-150">
            <button
              onClick={() => setSelectedMovie(null)}
              className="absolute top-3 right-3 z-20 w-8 h-8 rounded-full bg-black/80 hover:bg-black border border-white/20 flex items-center justify-center text-white"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="relative h-56 w-full overflow-hidden">
              <img 
                src={selectedMovie.backdrop || selectedMovie.image}
                alt={selectedMovie.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#080B1E] via-[#080B1E]/60 to-transparent" />
            </div>

            <div className="p-6 -mt-14 relative z-10">
              <div className="inline-block px-2.5 py-0.5 rounded bg-green-500/20 text-green-400 border border-green-500/40 text-xs font-black mb-2">
                Translated by {selectedMovie.vj}
              </div>

              <h2 className="text-2xl sm:text-3xl font-black text-white mb-2 leading-tight">
                {selectedMovie.title}
              </h2>

              <div className="flex items-center gap-3 text-xs text-gray-400 font-medium mb-4">
                <span className="text-yellow-400 font-bold flex items-center gap-1">
                  <Star className="w-3.5 h-3.5 fill-current" />
                  {selectedMovie.rating}
                </span>
                <span>•</span>
                <span>{selectedMovie.year}</span>
                <span>•</span>
                <span>{selectedMovie.runtime}</span>
                <span>•</span>
                <span className="px-1.5 py-0.5 rounded bg-white/10 text-white font-bold text-[10px]">HD</span>
              </div>

              <div className="flex items-center gap-3 mb-5">
                <button
                  onClick={() => handlePlay(selectedMovie)}
                  className="flex items-center gap-2 bg-green-500 hover:bg-green-600 text-black font-black px-6 py-2.5 rounded-full shadow-lg transition-all uppercase text-xs tracking-wide"
                >
                  <Play className="w-4 h-4 fill-black" />
                  Watch Now
                </button>

                <button
                  onClick={() => toggleMyList(selectedMovie)}
                  className="flex items-center gap-1.5 bg-white/10 hover:bg-white/20 text-white font-bold px-4 py-2.5 rounded-full border border-white/10 transition-all text-xs"
                >
                  {myList.some(m => m.id === selectedMovie.id) ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-green-400" />
                      In Watchlist
                    </>
                  ) : (
                    <>
                      <Plus className="w-3.5 h-3.5" />
                      Watchlist
                    </>
                  )}
                </button>
              </div>

              <p className="text-xs sm:text-sm text-gray-300 leading-relaxed">
                {selectedMovie.synopsis}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* ── Fullscreen Video Player ────────────────────────────────────── */}
      {activeStreamUrl && (
        <div className="fixed inset-0 z-60 bg-black flex flex-col justify-center items-center">
          <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
            <button
              onClick={() => setActiveStreamUrl('')}
              className="flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-black/70 hover:bg-black border border-white/20 text-white text-xs font-bold"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              Close
            </button>
            {selectedMovie && (
              <span className="text-xs font-bold text-white bg-black/70 px-3 py-1.5 rounded-full border border-white/10">
                {selectedMovie.title} ({selectedMovie.vj})
              </span>
            )}
          </div>
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
      )}
    </div>
  );
}

// ── MunoWatch Movie Poster Card matching output.css & grid.min.js ───────────
function MunoMoviePosterCard({ movie, onPlay, onSelect }) {
  return (
    <div 
      onClick={onSelect}
      className="group relative flex flex-col cursor-pointer transition-all duration-300 select-none"
    >
      <div className="relative aspect-[2/3] w-full rounded-md overflow-hidden bg-[#0d0f1a] border border-gray-800/80 group-hover:border-green-500 transition-all duration-300 group-hover:scale-105 shadow-md">
        <img 
          src={movie.image}
          alt={movie.title}
          loading="lazy"
          onError={(e) => {
            e.currentTarget.src = 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop&q=80';
          }}
          className="tile-img w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
        />

        {/* Top Badges */}
        <div className="absolute top-2 left-2 px-1 py-0.5 rounded bg-black/75 text-[9px] font-bold text-white border border-white/20">
          HD
        </div>

        {movie.vj && (
          <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-green-600 text-[9px] font-black text-white shadow">
            {movie.vj}
          </div>
        )}

        {/* Hover Center Play Button */}
        <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          <button 
            onClick={(e) => { e.stopPropagation(); onPlay(); }}
            className="w-11 h-11 rounded-full bg-green-500 hover:bg-green-400 text-black flex items-center justify-center shadow-xl transform scale-75 group-hover:scale-100 transition-transform duration-200"
            title="Play"
          >
            <Play className="w-4 h-4 fill-black ml-0.5" />
          </button>
        </div>

        {/* Bottom Rating and Year */}
        <div className="absolute inset-x-0 bottom-0 p-2 bg-gradient-to-t from-black/95 via-black/50 to-transparent flex items-center justify-between">
          <span className="flex items-center gap-1 text-[10px] font-bold text-yellow-400">
            <Star className="w-2.5 h-2.5 fill-current" />
            {movie.rating}
          </span>
          <span className="text-[10px] text-gray-300 font-medium">{movie.year}</span>
        </div>
      </div>

      <h3 className="mt-1.5 text-xs font-bold text-gray-200 line-clamp-1 group-hover:text-green-400 transition-colors">
        {movie.title}
      </h3>
    </div>
  );
}

// ── Exact 4-Column Footer from MunoWatch.com (lines 116-182) ─────────────────
function MunoFooter({ onSelectTab }) {
  return (
    <footer className="bg-[#010318] p-8 text-gray-500 text-sm mt-auto print:hidden border-t border-gray-900 select-none">
      <div className="w-[95%] lg:w-[86%] mx-auto grid sm:grid-cols-2 md:grid-cols-4 gap-5 gap-y-6">
        <p className="text-xs" id="copyright">
          {new Date().getFullYear()} &copy; FreeWatch. All Rights Reserved.
        </p>
        
        <article>
          <p className="text-white font-bold pb-4">FAQ</p>
          <ul className="flex flex-col gap-y-3 text-xs">
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <a href="#about" onClick={(e) => { e.preventDefault(); onSelectTab('p'); }} className="hover:text-green-500">About</a>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <a href="#dmca" onClick={(e) => { e.preventDefault(); alert("FreeWatch indexes publicly available links provided by MunoWatch CDN."); }} className="hover:text-green-500">DMCA</a>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <a href="#privacy" onClick={(e) => { e.preventDefault(); }} className="hover:text-green-500">Privacy Policy</a>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <a href="#terms" onClick={(e) => { e.preventDefault(); }} className="hover:text-green-500">Terms &amp; Conditions</a>
            </li>
          </ul>
        </article>

        <article>
          <p className="text-white font-bold pb-4">CONTACTS</p>
          <ul className="flex flex-col gap-y-3 text-xs">
            <li className="flex gap-x-2">
              <span>✉</span>
              <a href="mailto:info@freewatchug.online" className="hover:text-green-500">info@freewatchug.online</a>
            </li>
            <li className="flex gap-x-2">
              <span>☎</span>
              <a href="https://wa.me/+256782970036" target="_blank" rel="noopener noreferrer" className="hover:text-green-500">whatsapp +256 782-970-036</a>
            </li>
          </ul>
        </article>

        <article>
          <p className="text-white font-bold pb-4">FOLLOW US</p>
          <ul className="flex gap-3">
            <li>
              <a href="https://facebook.com/munowatch" target="_blank" rel="noopener noreferrer">
                <img src="https://munowatch.com/assets/icons/social/facebook.png" alt="fb" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://x.com/muno_watch" target="_blank" rel="noopener noreferrer">
                <img src="https://munowatch.com/assets/icons/social/x.png" alt="x" className="w-7 p-1.5 rounded-md bg-gray-400 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="http://instagram.com/munowatch" target="_blank" rel="noopener noreferrer">
                <img src="https://munowatch.com/assets/icons/social/instagram.png" alt="ig" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://wa.me/+256700970036" target="_blank" rel="noopener noreferrer">
                <img src="https://munowatch.com/assets/icons/social/whatsapp.png" alt="wa" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://www.tiktok.com/@muno.watch.ug" target="_blank" rel="noopener noreferrer">
                <img src="https://munowatch.com/assets/icons/social/tiktok.png" alt="tt" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
          </ul>
        </article>
      </div>
    </footer>
  );
}
