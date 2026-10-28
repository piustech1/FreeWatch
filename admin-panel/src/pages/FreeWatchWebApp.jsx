import React, { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { 
  Play, Search, Bell, Star, Film, ChevronDown, ChevronRight, X, 
  ArrowLeft, Plus, Check, Loader2, RotateCcw, Menu, Eye, EyeOff,
  Download, Share2, Info, UserCheck, LogOut, CheckCircle2
} from 'lucide-react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

// ── Fallback Initial Catalog & Featured Banners ─────────────────────────────
const FEATURED_BANNERS = [
  {
    id: 67421,
    title: 'Mirzapur',
    vj: 'VJ Ashim',
    category: 'Series',
    rating: '9.2',
    year: '2025',
    runtime: '50m',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
    backdrop: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
    synopsis: 'A shocking incident at a wedding procession ignites a series of events entangling two families in the lawless city of Mirzapur.',
    streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4',
    isTv: true,
    episodes: [
      { num: 1, title: 'Episode 1', streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4', duration: '50m' },
      { num: 2, title: 'Episode 2', streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4', duration: '48m' },
      { num: 3, title: 'Episode 3', streamUrl: 'https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4', duration: '52m' }
    ]
  },
  {
    id: 67099,
    title: 'Accused',
    vj: 'VJ Emmy',
    category: 'Action',
    rating: '8.9',
    year: '2024',
    runtime: '1h 45m',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg',
    backdrop: 'https://munowatch.com/media/images/owlcarousel/292722983807.jpg',
    synopsis: 'Wrongfully accused of murdering his best friend, church minister Benson is finally released when the truth comes to light. But freedom brings no peace.',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    isTv: false
  },
  {
    id: 67342,
    title: 'The Terminal List: Dark Wolf',
    vj: 'VJ Junior',
    category: 'Series',
    rating: '9.0',
    year: '2024',
    runtime: '55m',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg',
    backdrop: 'https://munowatch.com/media/images/owlcarousel/228038746205.jpg',
    synopsis: 'Navy SEAL Ben Edwards abruptly discharged from the military lands him a new job working with a mysterious CIA operative.',
    streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4',
    isTv: true,
    episodes: [
      { num: 1, title: 'Episode 1', streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4', duration: '55m' },
      { num: 2, title: 'Episode 2', streamUrl: 'https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4', duration: '51m' }
    ]
  },
  {
    id: 67369,
    title: 'Barbarian',
    vj: 'VJ Emmy',
    category: 'Horror',
    rating: '8.6',
    year: '2024',
    runtime: '1h 42m',
    image: 'https://image.tmdb.org/t/p/w780/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg',
    backdrop: 'https://munowatch.com/media/images/owlcarousel/206472177583.jpg',
    synopsis: 'A young woman staying at an Airbnb rental discovers that the house is not what it seems to be.',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    isTv: false
  }
];

const INITIAL_MOVIES = [
  ...FEATURED_BANNERS,
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
    id: 67346,
    title: 'Just Say It: Ava Peace',
    vj: 'VJ Emmy',
    category: 'Drama',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg',
    rating: '8.5',
    year: '2024',
    runtime: '1h 30m',
    isTv: false,
    synopsis: 'Deep personal revelations and intense drama unfold in this touching Ugandan production.',
    streamUrl: ''
  },
  {
    id: 67185,
    title: 'Just Say It: Lillian Mbabazi',
    vj: 'VJ Junior',
    category: 'Drama',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg',
    rating: '8.6',
    year: '2024',
    runtime: '1h 35m',
    isTv: false,
    synopsis: 'A candid musical drama exploring fame, love, and life challenges.',
    streamUrl: ''
  },
  {
    id: 67098,
    title: 'Kifeesi',
    vj: 'VJ Emmy',
    category: 'Action',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/R8kE7956.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/R8kE7956.jpg',
    rating: '9.0',
    year: '2024',
    runtime: '2h 00m',
    isTv: false,
    synopsis: 'Kampala streets turn into a tactical battleground against notorious gangs.',
    streamUrl: ''
  },
  {
    id: 67097,
    title: 'Nyoko: The Terrible Mother',
    vj: 'VJ Sammy',
    category: 'Drama',
    image: 'https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg',
    backdrop: 'https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg',
    rating: '8.4',
    year: '2024',
    runtime: '1h 40m',
    isTv: false,
    synopsis: 'An intense maternal struggle exposes family secrets with high emotional stakes.',
    streamUrl: ''
  }
];

// Exact Typewriter Items from MunoWatch.com
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
  // Routes: 'landing' (/) | 'home' (/home) | 'grid' (/grid) | 'twolekede' (/twolekede) | 'login' (/login) | 'signup' (/signup) | 'forgotpassword' (/forgotpassword) | 'search' (/search) | 'myaccount' (/myaccount)
  const [currentRoute, setCurrentRoute] = useState('landing');
  const [authError, setAuthError] = useState('');
  const [authSuccess, setAuthSuccess] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // User Auth State
  const [currentUser, setCurrentUser] = useState(() => {
    try {
      const saved = localStorage.getItem('freewatch_user');
      return saved ? JSON.parse(saved) : null;
    } catch (_) {
      return null;
    }
  });

  // Movie Catalog States
  const [catalog, setCatalog] = useState(INITIAL_MOVIES);
  const [catalogPage, setCatalogPage] = useState(1);
  const [hasMoreCatalog, setHasMoreCatalog] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [totalCatalogCount, setTotalCatalogCount] = useState(7097);

  // Navigation Filter States
  const [pipeType, setPipeType] = useState('p'); // 'p' (latest) | 'series' | 'genre' | 'vj' | 'watchlist' | 'free'
  const [pageTitle, setPageTitle] = useState('Latest movies');
  const [selectedGenre, setSelectedGenre] = useState('All');
  const [selectedVj, setSelectedVj] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [genreDropdownOpen, setGenreDropdownOpen] = useState(false);
  const [vjDropdownOpen, setVjDropdownOpen] = useState(false);
  const [accountDropdownOpen, setAccountDropdownOpen] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // Active Movie & Watch Details (/twolekede)
  const [selectedMovie, setSelectedMovie] = useState(FEATURED_BANNERS[0]);
  const [activeEpisodeNum, setActiveEpisodeNum] = useState(1);
  const [activeStreamUrl, setActiveStreamUrl] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(true);

  // OwlCarousel Banner State for /home
  const [bannerIndex, setBannerIndex] = useState(0);

  // Watchlist
  const [myList, setMyList] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('freewatch_my_list') || '[]');
    } catch (_) {
      return [];
    }
  });

  // Static Policy Modals
  const [activeModal, setActiveModal] = useState(null); // 'about' | 'dmca' | 'privacy' | 'terms'

  // Form states for Auth
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const [signupUsername, setSignupUsername] = useState('');
  const [signupEmail, setSignupEmail] = useState('');
  const [signupPhone, setSignupPhone] = useState('');
  const [signupPassword, setSignupPassword] = useState('');
  const [signupConfirmPassword, setSignupConfirmPassword] = useState('');
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [acceptTerms, setAcceptTerms] = useState(true);

  const [forgotEmail, setForgotEmail] = useState('');

  // Landing Typewriter effect
  const [currentTypewriterText, setCurrentTypewriterText] = useState('');
  const [typewriterIndex, setTypewriterIndex] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const fullText = TYPEWRITER_ITEMS[typewriterIndex];
    let speed = isDeleting ? 40 : 80;
    if (!isDeleting && currentTypewriterText === fullText) {
      speed = 1500;
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

  // Banner Auto-Advance (10-second timer matching MunoWatch OwlCarousel)
  useEffect(() => {
    if (currentRoute !== 'home') return;
    const interval = setInterval(() => {
      setBannerIndex((prev) => (prev + 1) % FEATURED_BANNERS.length);
    }, 10000);
    return () => clearInterval(interval);
  }, [currentRoute]);

  // Close dropdowns on outside click
  useEffect(() => {
    const handleOutsideClick = (e) => {
      if (!e.target.closest('.nav-dropdown-btn') && !e.target.closest('.nav-dropdown-menu')) {
        setGenreDropdownOpen(false);
        setVjDropdownOpen(false);
        setAccountDropdownOpen(false);
      }
    };
    window.addEventListener('click', handleOutsideClick);
    return () => window.removeEventListener('click', handleOutsideClick);
  }, []);

  // Sort array strictly ID-descending (MunoWatch newly-to-oldy)
  const sortNewlyToOldy = useCallback((items) => {
    return [...items].sort((a, b) => {
      const idA = typeof a.id === 'number' ? a.id : parseInt(a.id, 10) || 0;
      const idB = typeof b.id === 'number' ? b.id : parseInt(b.id, 10) || 0;
      return idB - idA;
    });
  }, []);

  // Fetch paginated movie batches from API
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
            for (const item of json.data) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                merged.push(item);
              }
            }
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
          if (json.total) setTotalCatalogCount(json.total);
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

  // Window scroll infinite pagination on /grid
  useEffect(() => {
    const handleScroll = () => {
      if (currentRoute !== 'grid') return;
      const scrollHeight = document.documentElement.scrollHeight;
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const clientHeight = window.innerHeight;
      if (scrollHeight - (scrollTop + clientHeight) < 850) {
        loadMoreMovies();
      }
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [loadMoreMovies, currentRoute]);

  // Initial catalog load & sync with Firebase RTDB
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

  // Open details / watch page (/twolekede)
  const openWatchPage = (movie) => {
    setSelectedMovie(movie);
    setActiveEpisodeNum(1);
    setActiveStreamUrl(movie.streamUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    setCurrentRoute('twolekede');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // Filtered movies for Grid / Search
  const displayedMovies = useMemo(() => {
    let list = sortNewlyToOldy(catalog);
    if (pipeType === 'series') {
      list = list.filter(m => m.isTv || /series|season|episode/i.test(m.category + ' ' + m.title));
    } else if (pipeType === 'watchlist') {
      return myList;
    } else if (pipeType === 'free') {
      list = list.filter(m => m.id % 2 === 0 || m.isTv === false);
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

  // Categorized movie rows for /home
  const homeCategoryRows = useMemo(() => {
    const base = sortNewlyToOldy(catalog);
    return [
      { id: 'latest', title: 'Latest on Munowatch', pipe_type: 'p', items: base.slice(0, 15) },
      { id: 'series', title: 'Series & TV Shows', pipe_type: 'g', items: base.filter(m => m.isTv).slice(0, 15) },
      { id: 'action', title: 'Action Movies', pipe_type: 'g', items: base.filter(m => /action/i.test(m.category)).slice(0, 15) },
      { id: 'vj_junior', title: 'Translated by VJ Junior', pipe_type: 'vj', items: base.filter(m => /junior/i.test(m.vj)).slice(0, 15) },
      { id: 'vj_emmy', title: 'Translated by VJ Emmy', pipe_type: 'vj', items: base.filter(m => /emmy/i.test(m.vj)).slice(0, 15) },
      { id: 'drama', title: 'Drama & Romance', pipe_type: 'g', items: base.filter(m => /drama|romance/i.test(m.category)).slice(0, 15) }
    ];
  }, [catalog, sortNewlyToOldy]);

  // ── Authentication Handlers ─────────────────────────────────────────────
  const handleLoginSubmit = (e) => {
    e.preventDefault();
    setAuthError('');
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      const user = {
        username: loginEmail.split('@')[0] || 'User',
        email: loginEmail,
        plan: 'Free Tier',
        remainingDays: 0
      };
      setCurrentUser(user);
      localStorage.setItem('freewatch_user', JSON.stringify(user));
      setCurrentRoute('home');
    }, 600);
  };

  const handleSignupSubmit = (e) => {
    e.preventDefault();
    setAuthError('');
    if (signupPassword !== signupConfirmPassword) {
      setAuthError('Passwords do not match.');
      return;
    }
    if (!acceptTerms) {
      setAuthError('You must accept the Terms and Conditions.');
      return;
    }
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      const user = {
        username: signupUsername || signupEmail.split('@')[0] || 'User',
        email: signupEmail,
        telephone: signupPhone,
        plan: 'Standard Plan',
        remainingDays: 30
      };
      setCurrentUser(user);
      localStorage.setItem('freewatch_user', JSON.stringify(user));
      setCurrentRoute('home');
    }, 600);
  };

  const handleForgotSubmit = (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      setAuthSuccess('Password reset link has been dispatched to your email.');
    }, 600);
  };

  const handleLogout = () => {
    setCurrentUser(null);
    localStorage.removeItem('freewatch_user');
    setAccountDropdownOpen(false);
    setCurrentRoute('landing');
  };

  // Current Owl Banner
  const currentBanner = FEATURED_BANNERS[bannerIndex] || FEATURED_BANNERS[0];

  return (
    <div className="bg-[#010318] text-gray-200 flex flex-col min-h-screen w-full font-sans select-none antialiased relative">
      
      {/* ═════════════════════════════════════════════════════════════════════
          UNIVERSAL NAV (USED ACROSS /home, /grid, /twolekede, /search, /myaccount)
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute !== 'landing' && currentRoute !== 'login' && currentRoute !== 'signup' && currentRoute !== 'forgotpassword' && (
        <div id="nav-container" data-cantransform="0" className="sticky bg-[#010318]/90 backdrop-blur-md px-0 py-2.5 text-white flex z-40 top-0 border-b border-white/5 transition-all">
          <nav id="universal-nav" className="w-[95%] lg:w-[86%] mx-auto flex flex-col lg:flex-row justify-between items-start lg:items-center" style={{ textShadow: '2px 2px 4px rgba(0, 0, 0, 0.6)' }}>
            
            <div className="flex items-center justify-between w-full lg:w-auto">
              {/* Brand Wordmark Logo */}
              <div 
                onClick={() => setCurrentRoute(currentUser ? 'home' : 'landing')}
                className="cursor-pointer flex items-center gap-2"
              >
                <img 
                  src="/assets/icons/logo-word.png" 
                  alt="Munowatch" 
                  onError={(e) => { e.currentTarget.src = 'https://munowatch.com/assets/icons/logo-word.png'; }}
                  className="w-44 sm:w-48 object-contain" 
                />
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
                {/* Home link */}
                <li className="w-full py-2 lg:px-1">
                  <button
                    onClick={() => { setCurrentRoute('home'); setMobileNavOpen(false); }}
                    className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${currentRoute === 'home' ? 'text-green-500 font-black' : ''}`}
                  >
                    Home
                  </button>
                </li>

                {/* Latest movies */}
                <li className="w-full py-2 lg:px-1">
                  <button
                    onClick={() => { 
                      setPipeType('p'); 
                      setPageTitle('Latest movies'); 
                      setSelectedGenre('All'); 
                      setSelectedVj('All'); 
                      setCurrentRoute('grid'); 
                      setMobileNavOpen(false); 
                    }}
                    className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${currentRoute === 'grid' && pipeType === 'p' && selectedGenre === 'All' && selectedVj === 'All' ? 'text-green-500 font-black' : ''}`}
                  >
                    Latest movies
                  </button>
                </li>

                {/* Series */}
                <li className="w-full py-2 lg:px-1">
                  <button
                    onClick={() => { 
                      setPipeType('series'); 
                      setPageTitle('Series'); 
                      setSelectedGenre('All'); 
                      setSelectedVj('All'); 
                      setCurrentRoute('grid'); 
                      setMobileNavOpen(false); 
                    }}
                    className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${currentRoute === 'grid' && pipeType === 'series' ? 'text-green-500 font-black' : ''}`}
                  >
                    Series
                  </button>
                </li>

                {/* Genre Dropdown */}
                <li className="w-full py-2 lg:px-1 relative">
                  <button
                    onClick={(e) => { e.stopPropagation(); setGenreDropdownOpen(!genreDropdownOpen); setVjDropdownOpen(false); setAccountDropdownOpen(false); }}
                    className="inline-flex items-center justify-between lg:justify-center w-full rounded-md px-4 py-2 hover:text-green-500 text-nowrap nav-dropdown-btn"
                  >
                    <span>{selectedGenre !== 'All' ? `Genre: ${selectedGenre}` : 'Genre'}</span>
                    <ChevronDown className="ml-1.5 w-4 h-4" />
                  </button>

                  {genreDropdownOpen && (
                    <div className="nav-dropdown-menu origin-top-right absolute left-0 lg:right-0 mt-2 w-72 rounded-md shadow-2xl bg-[#010318] backdrop-blur-md border border-gray-700 z-50 p-2.5 max-h-80 overflow-y-auto animate-in fade-in zoom-in-95 duration-100">
                      <div className="grid grid-cols-2 gap-1" role="menu">
                        <button
                          onClick={() => { setSelectedGenre('All'); setGenreDropdownOpen(false); setCurrentRoute('grid'); setMobileNavOpen(false); }}
                          className="text-left px-3 py-1.5 text-xs text-gray-300 hover:text-green-500"
                        >
                          All Genres
                        </button>
                        {GENRES.map((g) => (
                          <button
                            key={g}
                            onClick={() => { setSelectedGenre(g); setPageTitle(`${g} Movies`); setPipeType('p'); setGenreDropdownOpen(false); setCurrentRoute('grid'); setMobileNavOpen(false); }}
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
                    onClick={(e) => { e.stopPropagation(); setVjDropdownOpen(!vjDropdownOpen); setGenreDropdownOpen(false); setAccountDropdownOpen(false); }}
                    className="inline-flex items-center justify-between lg:justify-center w-full rounded-md px-4 py-2 hover:text-green-500 text-nowrap nav-dropdown-btn"
                  >
                    <span>{selectedVj !== 'All' ? `VJ: ${selectedVj}` : 'Vj'}</span>
                    <ChevronDown className="ml-1.5 w-4 h-4" />
                  </button>

                  {vjDropdownOpen && (
                    <div className="nav-dropdown-menu origin-top-right absolute left-0 lg:right-0 mt-2 w-72 rounded-md shadow-2xl bg-[#010318] backdrop-blur-md border border-gray-700 z-50 p-2.5 max-h-80 overflow-y-auto animate-in fade-in zoom-in-95 duration-100">
                      <div className="grid grid-cols-2 gap-1" role="menu">
                        <button
                          onClick={() => { setSelectedVj('All'); setVjDropdownOpen(false); setCurrentRoute('grid'); setMobileNavOpen(false); }}
                          className="text-left px-3 py-1.5 text-xs text-gray-300 hover:text-green-500"
                        >
                          All VJs
                        </button>
                        {VJ_LIST.map((v) => (
                          <button
                            key={v}
                            onClick={() => { setSelectedVj(v); setPageTitle(`${v} Movies`); setPipeType('p'); setVjDropdownOpen(false); setCurrentRoute('grid'); setMobileNavOpen(false); }}
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
                    onClick={() => { setPipeType('watchlist'); setPageTitle('Watchlist'); setCurrentRoute('grid'); setMobileNavOpen(false); }}
                    className={`w-full inline-block px-4 py-2 rounded-md hover:text-green-500 text-nowrap text-left lg:text-center ${currentRoute === 'grid' && pipeType === 'watchlist' ? 'text-green-500 font-black' : ''}`}
                  >
                    Watchlist ({myList.length})
                  </button>
                </li>

                {/* My Account Dropdown if logged in */}
                {currentUser ? (
                  <li className="w-full py-2 lg:px-1 relative">
                    <button
                      onClick={(e) => { e.stopPropagation(); setAccountDropdownOpen(!accountDropdownOpen); setGenreDropdownOpen(false); setVjDropdownOpen(false); }}
                      className="inline-flex items-center justify-between lg:justify-center w-full rounded-md px-4 py-2 hover:text-green-500 text-nowrap nav-dropdown-btn text-green-400"
                    >
                      <span>My account</span>
                      <ChevronDown className="ml-1 w-3.5 h-3.5" />
                    </button>
                    {accountDropdownOpen && (
                      <div className="nav-dropdown-menu origin-top-right absolute left-0 lg:right-0 mt-2 w-56 rounded-md shadow-2xl bg-[#010318] backdrop-blur-md border border-gray-700 z-50 p-2 text-xs">
                        <button
                          onClick={() => { setCurrentRoute('myaccount'); setAccountDropdownOpen(false); setMobileNavOpen(false); }}
                          className="w-full text-left px-3 py-2 text-gray-200 hover:text-green-500 hover:bg-white/5 rounded"
                        >
                          my settings - {currentUser.username}
                        </button>
                        <button
                          onClick={handleLogout}
                          className="w-full text-left px-3 py-2 text-red-400 hover:text-red-300 hover:bg-white/5 rounded flex items-center gap-1.5"
                        >
                          <LogOut className="w-3.5 h-3.5" />
                          Logout
                        </button>
                      </div>
                    )}
                  </li>
                ) : (
                  <li className="w-full py-2 lg:px-1">
                    <button
                      onClick={() => { setCurrentRoute('login'); setMobileNavOpen(false); }}
                      className="px-4 py-2 text-green-400 font-bold hover:text-green-300"
                    >
                      Log In
                    </button>
                  </li>
                )}

                {/* Free movies badge */}
                <li className="w-full py-2 lg:px-1">
                  <div 
                    onClick={() => { setPipeType('free'); setSelectedGenre('All'); setSelectedVj('All'); setPageTitle('Free movies'); setCurrentRoute('grid'); setMobileNavOpen(false); }}
                    id="days-remaining" 
                    className="text-green-300 hover:text-green-500 text-nowrap font-bold px-4 py-2 cursor-pointer"
                  >
                    {currentUser && currentUser.remainingDays > 0 ? `${currentUser.remainingDays} days` : 'free movies'}
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
                    onClick={() => setCurrentRoute(currentRoute === 'search' ? 'grid' : 'search')}
                    className={`hover:text-green-500 inline-block p-1 ${currentRoute === 'search' ? 'text-green-500' : ''}`}
                    title="Search"
                  >
                    <Search className="w-5 h-5" />
                  </button>
                </li>
                {currentRoute !== 'landing' && (
                  <li>
                    <button
                      onClick={() => setCurrentRoute('landing')}
                      className="text-xs font-bold text-gray-400 hover:text-white px-2.5 py-1 rounded border border-gray-700"
                    >
                      Landing
                    </button>
                  </li>
                )}
              </ul>
            </div>
          </nav>
        </div>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 1: EXACT MUNOWATCH.COM LANDING HOMEPAGE (/)
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'landing' && (
        <div className="relative min-h-screen w-full flex flex-col justify-between overflow-hidden">
          {/* Top Landing Header: logo on left, Log In & Browse Movies on right */}
          <div className="flex justify-between sm:justify-around items-center bg-gradient-to-b from-[#010318] via-[#010318]/70 to-transparent p-4 z-20">
            <div 
              onClick={() => setCurrentRoute('landing')}
              className="cursor-pointer flex items-center"
            >
              <img 
                src="/assets/icons/logo-word.png" 
                alt="Munowatch" 
                onError={(e) => { e.currentTarget.src = 'https://munowatch.com/assets/icons/logo-word.png'; }}
                className="w-48 sm:w-52 object-contain" 
              />
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setCurrentRoute('login')}
                className="p-2 px-4 border border-green-500 text-green-500 rounded-md hover:bg-green-700 hover:text-white font-bold transition-all text-sm shadow-lg"
              >
                Log In
              </button>

              <button
                onClick={() => setCurrentRoute('home')}
                className="p-2 px-4 bg-green-500 text-black font-extrabold rounded-md hover:bg-green-400 transition-all text-sm shadow-lg"
              >
                Browse Movies
              </button>
            </div>
          </div>

          {/* Center Main Typewriter Hero */}
          <main className="container mx-auto flex flex-col justify-center items-center p-4 z-20 flex-1 my-auto">
            <div className="h-[65vh] flex flex-col justify-center items-center text-center px-4 space-y-8">
              <div id="typedata" className="min-h-[120px] flex items-center justify-center">
                <h1 className="text-4xl sm:text-6xl lg:text-7xl font-bold text-white text-center leading-tight">
                  {currentTypewriterText}
                  <span className="inline-block w-1.5 h-10 sm:h-14 bg-green-500 ml-1.5 animate-pulse align-middle" />
                </h1>
              </div>

              <button
                onClick={() => setCurrentRoute('home')}
                className="p-3.5 px-8 border border-white text-white rounded-full bg-white/20 hover:bg-green-500 hover:text-black font-bold text-base sm:text-lg transition-all backdrop-blur-md shadow-2xl hover:scale-105 inline-block"
              >
                Get Started
              </button>
            </div>
          </main>

          {/* Fullscreen Looping Video Background */}
          <video 
            playsInline 
            poster="/assets/images/playbg.jpg" 
            autoPlay 
            muted 
            loop 
            className="fixed top-0 left-0 object-cover sm:min-w-[100vw] w-full h-[100vh] -z-10"
          >
            <source src="https://munotek-vault.b-cdn.net/CLIPS/MOVIES%20HD.mp4" type="video/mp4" />
          </video>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </div>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 2: LOGGED-IN HOME PAGE (/home)
          Featuring OwlCarousel Auto-Rotating Banner + Infinite Horizontal Stacks
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'home' && (
        <main className="w-full flex flex-col min-h-screen">
          {/* Owl Carousel Hero Banner */}
          <div className="owl-carousel relative -mb-[15vh] overflow-hidden min-h-[85vh] w-full">
            <img 
              src={currentBanner.backdrop || currentBanner.image} 
              alt={currentBanner.title} 
              className="w-full h-[85vh] object-cover transition-opacity duration-700" 
            />
            
            <div className="absolute inset-0 bg-gradient-to-b from-transparent via-[#010318]/50 to-[#010318] flex items-center px-6 sm:px-12">
              <div className="h-full mt-[35vh] w-full md:w-[80%] mx-auto flex flex-col justify-end pb-16">
                <p className="text-3xl lg:text-5xl font-bold text-white mb-3" style={{ textShadow: '2px 2px 4px rgba(0, 0, 0, 0.6)' }}>
                  {currentBanner.title}: 
                  <span className="text-green-500 pl-2 font-light">{currentBanner.vj}</span>
                </p>
                <p className="text-base sm:text-lg text-gray-300 line-clamp-2 md:line-clamp-3 max-w-3xl mb-6" style={{ textShadow: '2px 2px 4px rgba(0, 0, 0, 0.6)' }}>
                  {currentBanner.synopsis}
                </p>
                
                <div className="flex items-center gap-4">
                  <button 
                    onClick={() => openWatchPage(currentBanner)} 
                    className="group flex items-center" 
                    style={{ textShadow: '2px 2px 4px rgba(0, 0, 0, 0.6)' }}
                  >
                    <div className="p-3 bg-green-600 rounded-full mr-3 group-hover:bg-green-500 transition-all shadow-xl group-hover:scale-110">
                      <Play className="w-6 h-6 sm:w-8 sm:h-8 fill-white text-white ml-0.5" />
                    </div>
                    <span className="group-hover:underline transition-all font-bold tracking-wider text-sm sm:text-base">
                      WATCH NOW
                    </span>
                  </button>

                  <button
                    onClick={() => toggleMyList(currentBanner)}
                    className="p-3 px-5 rounded-full bg-white/10 hover:bg-white/20 border border-white/20 text-white font-bold text-xs flex items-center gap-1.5 transition-all"
                  >
                    {myList.some(m => m.id === currentBanner.id) ? (
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

            {/* Vertical Owl Dots Navigation on the right matching MunoWatch output.css */}
            <div className="absolute right-5 top-1/2 -translate-y-1/2 flex flex-col gap-3 z-30">
              {FEATURED_BANNERS.map((banner, idx) => (
                <button
                  key={banner.id}
                  onClick={() => setBannerIndex(idx)}
                  className={`w-3 rounded-full transition-all duration-300 ${bannerIndex === idx ? 'bg-[#16a34a] h-8' : 'bg-white/30 h-3 hover:bg-white/60'}`}
                  title={banner.title}
                />
              ))}
            </div>
          </div>

          {/* Horizontal Scrolling Rows matching MunoWatch .infinite-hstack */}
          <div className="lg:w-[86%] mx-auto w-[95%] space-y-10 py-8 z-20 flex-1">
            {homeCategoryRows.map((catRow) => (
              <section key={catRow.id} className="flex flex-col">
                <div className="flex items-center justify-between mb-3">
                  <button
                    onClick={() => {
                      if (catRow.id === 'series') setPipeType('series');
                      else setPipeType('p');
                      setPageTitle(catRow.title);
                      setCurrentRoute('grid');
                    }}
                    className="group flex items-center gap-2"
                  >
                    <h3 className="text-xl sm:text-2xl font-bold text-white group-hover:text-green-500 transition-colors">
                      {catRow.title}
                    </h3>
                    <ChevronRight className="w-5 h-5 text-gray-500 group-hover:text-green-500 group-hover:translate-x-1 transition-all" />
                  </button>

                  <span className="text-xs text-gray-400 font-medium">
                    {catRow.items.length} titles
                  </span>
                </div>

                {/* Horizontal Scroll Track */}
                <div className="flex overflow-x-auto gap-3 sm:gap-4 pb-4 cinema-scroll select-none">
                  {catRow.items.map((movie) => (
                    <div
                      key={movie.id}
                      onClick={() => openWatchPage(movie)}
                      className="flex-shrink-0 cursor-pointer group"
                      style={{ width: '165px' }}
                    >
                      <div className="relative aspect-[2/3] w-full rounded-md overflow-hidden bg-[#0d0f1a] border border-gray-800/80 group-hover:border-green-500 transition-all duration-300 group-hover:scale-105 shadow-md">
                        <img 
                          src={movie.image} 
                          alt={movie.title} 
                          loading="lazy"
                          onError={(e) => { e.currentTarget.src = '/assets/images/tile-fallback.jpg'; }}
                          className="w-full h-full object-cover" 
                        />
                        <div className="absolute top-2 right-2 px-2 py-0.5 rounded-md bg-green-500/70 group-hover:bg-green-500 text-[9px] font-bold text-white">
                          {movie.vj}
                        </div>
                        <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity">
                          <div className="w-10 h-10 rounded-full bg-green-500 flex items-center justify-center text-black shadow-lg">
                            <Play className="w-4 h-4 fill-black ml-0.5" />
                          </div>
                        </div>
                      </div>
                      <h4 className="mt-1.5 text-xs font-bold text-gray-200 line-clamp-1 group-hover:text-green-400">
                        {movie.title}
                      </h4>
                    </div>
                  ))}
                </div>
              </section>
            ))}
          </div>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </main>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 3: EXACT DETAILS & WATCH PAGE (/twolekede)
          Fullscreen Player, Metadata, Episodes Accordion Drawer & Recommendations
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'twolekede' && selectedMovie && (
        <main className="w-full flex flex-col min-h-screen">
          {/* Top Video Player Container */}
          <div className="w-full bg-black relative flex flex-col items-center justify-center min-h-[50vh] lg:min-h-[65vh]">
            <video 
              key={activeStreamUrl || selectedMovie.streamUrl}
              src={activeStreamUrl || selectedMovie.streamUrl}
              controls
              autoPlay
              playsInline
              className="w-full max-h-[75vh] object-contain shadow-2xl"
            >
              Your browser does not support HTML5 video playback.
            </video>
          </div>

          {/* Details Content Container */}
          <div className="w-[95%] lg:w-[86%] mx-auto py-8 space-y-8 flex-1">
            {/* Title & Metadata Header */}
            <div className="flex flex-col md:flex-row md:items-start justify-between gap-6 pb-6 border-b border-gray-800">
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded bg-green-500/20 text-green-400 border border-green-500/40 text-xs font-black">
                    Translated by {selectedMovie.vj}
                  </span>
                  <span className="px-2 py-0.5 rounded bg-white/10 text-white text-[11px] font-bold">
                    HD
                  </span>
                  {selectedMovie.isTv && (
                    <span className="px-2 py-0.5 rounded bg-blue-500/20 text-blue-400 border border-blue-500/40 text-[11px] font-bold">
                      TV Series
                    </span>
                  )}
                </div>

                <h1 className="text-3xl sm:text-4xl font-black text-white tracking-wide">
                  {selectedMovie.title}
                </h1>

                <div className="flex items-center gap-3 text-xs text-gray-400 font-medium">
                  <span className="text-yellow-400 font-bold flex items-center gap-1">
                    <Star className="w-3.5 h-3.5 fill-current" />
                    {selectedMovie.rating}
                  </span>
                  <span>•</span>
                  <span>{selectedMovie.year}</span>
                  <span>•</span>
                  <span>{selectedMovie.runtime}</span>
                  <span>•</span>
                  <span className="text-green-400">{selectedMovie.category}</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-3">
                <button
                  onClick={() => toggleMyList(selectedMovie)}
                  className="flex items-center gap-1.5 px-4 py-2.5 rounded-md bg-white/10 hover:bg-white/20 border border-white/15 text-white font-bold text-xs transition-all shadow"
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

                <a
                  href={activeStreamUrl || selectedMovie.streamUrl}
                  download
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 px-4 py-2.5 rounded-md bg-green-600 hover:bg-green-500 text-white font-bold text-xs transition-all shadow"
                >
                  <Download className="w-4 h-4" />
                  Download
                </a>

                <button
                  onClick={() => {
                    navigator.clipboard.writeText(window.location.href);
                    alert("Movie link copied to clipboard!");
                  }}
                  className="p-2.5 rounded-md bg-white/10 hover:bg-white/20 text-white"
                  title="Share"
                >
                  <Share2 className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Synopsis */}
            <div className="max-w-4xl space-y-2">
              <h3 className="text-sm font-bold uppercase tracking-wider text-gray-400">Synopsis</h3>
              <p className="text-base text-gray-300 leading-relaxed">
                {selectedMovie.synopsis}
              </p>
            </div>

            {/* Series Episodes Drawer Accordion (matching universal.min.js handleDrawerClick) */}
            {selectedMovie.isTv && (
              <div className="border border-gray-800 rounded-lg overflow-hidden bg-[#0a0d24]">
                <button
                  onClick={() => setDrawerOpen(!drawerOpen)}
                  id="season1-drawer-button"
                  data-open={drawerOpen ? "yes" : "no"}
                  className="drawer-button w-full p-4 flex items-center justify-between text-left font-bold transition-colors hover:bg-white/5"
                >
                  <span className={`text-base ${drawerOpen ? 'text-green-500' : 'text-gray-300'}`}>
                    Season 1 Episodes
                  </span>
                  <ChevronDown className={`w-5 h-5 transition-transform ${drawerOpen ? '' : 'rotate-180'}`} id="season1-drawer-chevron" />
                </button>

                {drawerOpen && (
                  <div id="season1-drawer-slot" className="p-4 border-t border-gray-800 space-y-2.5 bg-[#080a1c]">
                    {(selectedMovie.episodes || [
                      { num: 1, title: 'Episode 1', duration: '48m', streamUrl: selectedMovie.streamUrl },
                      { num: 2, title: 'Episode 2', duration: '50m', streamUrl: selectedMovie.streamUrl },
                      { num: 3, title: 'Episode 3', duration: '52m', streamUrl: selectedMovie.streamUrl },
                      { num: 4, title: 'Episode 4', duration: '49m', streamUrl: selectedMovie.streamUrl }
                    ]).map((ep) => (
                      <div
                        key={ep.num}
                        onClick={() => {
                          setActiveEpisodeNum(ep.num);
                          if (ep.streamUrl) setActiveStreamUrl(ep.streamUrl);
                        }}
                        className={`p-3 rounded-md flex items-center justify-between cursor-pointer transition-all ${activeEpisodeNum === ep.num ? 'bg-green-500/20 border border-green-500/40 text-green-300 font-bold' : 'bg-white/5 hover:bg-white/10 text-gray-300'}`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs ${activeEpisodeNum === ep.num ? 'bg-green-500 text-black font-black' : 'bg-gray-800 text-gray-300'}`}>
                            {ep.num}
                          </div>
                          <span className="text-sm">{ep.title}</span>
                        </div>
                        <div className="flex items-center gap-2 text-xs text-gray-500">
                          <span>{ep.duration}</span>
                          <Play className={`w-3.5 h-3.5 ${activeEpisodeNum === ep.num ? 'fill-green-400 text-green-400' : ''}`} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Related Movies Recommendations */}
            <div className="space-y-4 pt-6">
              <h3 className="text-xl font-bold text-white">More Movies Translated by {selectedMovie.vj}</h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3.5">
                {catalog
                  .filter(m => m.id !== selectedMovie.id && (m.vj === selectedMovie.vj || m.category === selectedMovie.category))
                  .slice(0, 6)
                  .map(movie => (
                    <MunoMoviePosterCard
                      key={movie.id}
                      movie={movie}
                      onPlay={() => openWatchPage(movie)}
                      onSelect={() => openWatchPage(movie)}
                    />
                  ))}
              </div>
            </div>
          </div>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </main>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 4: EXACT BROWSE GRID (/grid)
          Dual Filter Bar (#vj-options & #genre-options) + Infinite Scroll
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'grid' && (
        <main className="w-full flex flex-col min-h-screen">
          <div className="w-full max-w-[95%] lg:max-w-[86%] mx-auto py-6 flex-1">
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

              {/* Dual Filter Dropdowns */}
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
                    onPlay={() => openWatchPage(movie)}
                    onSelect={() => openWatchPage(movie)}
                  />
                ))}
              </div>
            )}

            {/* Infinite Scroll Spinner matching grid.min.js: #grid-loading-spinner */}
            <div id="grid-loading-spinner" className="mt-12 flex flex-col items-center justify-center gap-3">
              {loadingMore ? (
                <div className="flex items-center gap-2.5 px-6 py-2.5 rounded-full bg-white/10 border border-white/10 text-white text-xs font-bold shadow-lg">
                  <img src="/assets/gif/waiting.gif" alt="loading" className="w-5 h-5 object-contain" />
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
          </div>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </main>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 5: SEARCH PAGE (/search)
          Sticky #query-box with Real-Time Instant Filtering
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'search' && (
        <main className="w-full flex flex-col min-h-screen">
          <div className="w-[95%] lg:w-[86%] mx-auto py-8 flex-1">
            <div id="query-box" className="relative w-full mb-8">
              <input
                id="query"
                type="text"
                autoFocus
                placeholder="Search movies, TV series, or VJ name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full p-4 pl-12 rounded-md bg-[#0a0d24] border border-gray-700 text-white placeholder-gray-500 text-base focus:outline-none focus:border-green-500 shadow-xl"
              />
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              {searchQuery && (
                <button 
                  onClick={() => setSearchQuery('')}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>

            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold text-white">
                {searchQuery ? `Search Results for "${searchQuery}"` : 'Popular Searches'}
              </h2>
              <span className="text-xs text-gray-400">
                {displayedMovies.length} results
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 2xl:grid-cols-6 gap-3.5 sm:gap-5">
              {displayedMovies.map((movie) => (
                <MunoMoviePosterCard
                  key={movie.id}
                  movie={movie}
                  onPlay={() => openWatchPage(movie)}
                  onSelect={() => openWatchPage(movie)}
                />
              ))}
            </div>
          </div>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </main>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 6: AUTHENTICATION SUITE
          Exact /login, /signup, /forgotpassword with MunoWatch DOM and CSS
      ═════════════════════════════════════════════════════════════════════ */}

      {/* ── 6A. EXACT LOGIN PAGE (/login) ─────────────────────────────────── */}
      {currentRoute === 'login' && (
        <div className="min-h-screen w-full flex flex-col justify-between relative">
          <div className="flex justify-around bg-gradient-to-b from-[#010318] to-transparent p-4 z-20">
            <img 
              src="/assets/icons/logo-word.png" 
              alt="logo" 
              onError={(e) => { e.currentTarget.src = 'https://munowatch.com/assets/icons/logo-word.png'; }}
              className="w-52 object-contain cursor-pointer" 
              onClick={() => setCurrentRoute('landing')}
            />
            <button 
              onClick={() => setCurrentRoute('signup')}
              className="p-2 px-4 border border-green-500 text-green-500 rounded-md hover:bg-green-700 hover:text-white font-bold transition-all"
            >
              Sign Up
            </button>
          </div>

          <main className="container mx-auto flex flex-col justify-center items-center p-4 z-20 flex-1 my-auto">
            <form onSubmit={handleLoginSubmit} className="p-8 bg-slate-100 rounded-sm w-full lg:w-[30vw] mb-8 text-gray-800 shadow-2xl">
              <p className="text-center text-2xl mb-2 font-bold text-gray-900">Sign In</p>

              {authError && (
                <div className="mb-4 p-2.5 rounded bg-red-100 border border-red-300 text-red-700 text-xs">
                  {authError}
                </div>
              )}

              {/* Google Sign In Button */}
              <div className="flex flex-col gap-4 items-center mb-4">
                <button 
                  type="button"
                  id="google-signin-btn"
                  onClick={() => {
                    const user = { username: 'GoogleUser', email: 'user@gmail.com', plan: 'VIP Active', remainingDays: 30 };
                    setCurrentUser(user);
                    localStorage.setItem('freewatch_user', JSON.stringify(user));
                    setCurrentRoute('home');
                  }}
                  className="bg-white text-black p-2.5 px-4 rounded shadow border border-gray-300 flex items-center gap-2 hover:bg-gray-100 font-medium text-sm w-full justify-center"
                >
                  <img src="/assets/icons/google-color-icon.svg" alt="Google" className="w-5 h-5" />
                  Sign in with Google
                </button>
              </div>

              {/* OR Divider */}
              <div id="or-divider" className="w-full relative h-6 flex justify-center py-4 mb-3">
                <hr className="border-t border-gray-300 w-60 absolute top-1/2" />
                <p className="text-center text-gray-400 absolute w-16 top-1 bg-slate-100 text-xs font-bold">OR</p>
              </div>

              {/* Email / Username field */}
              <div className="flex flex-col mt-4">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Email / username: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <input 
                  type="text" 
                  required
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3.5 text-sm" 
                  placeholder="name@example.com"
                />
              </div>

              {/* Password field with eye toggle */}
              <div className="flex flex-col mt-4 relative">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Password: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <div className="relative">
                  <input 
                    type={showPassword ? "text" : "password"} 
                    required
                    value={loginPassword}
                    onChange={(e) => setLoginPassword(e.target.value)}
                    className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3.5 pr-10 text-sm w-full" 
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-black"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div className="flex justify-between items-center mt-2">
                <button 
                  type="button" 
                  onClick={() => setCurrentRoute('forgotpassword')}
                  className="ml-auto text-right text-green-500 hover:underline text-xs mt-2"
                >
                  Forgot password?
                </button>
              </div>

              <input 
                type="submit" 
                value={isSubmitting ? "Please wait..." : "Sign In"} 
                disabled={isSubmitting}
                className="rounded-sm outline-none p-3 my-4 w-full bg-green-500 hover:bg-green-600 text-white font-bold cursor-pointer transition-all shadow-md text-sm uppercase tracking-wider" 
              />

              <p className="my-2 text-xs text-center text-gray-600">
                Don&apos;t have an account?{' '}
                <button 
                  type="button" 
                  onClick={() => setCurrentRoute('signup')}
                  className="text-green-500 hover:underline font-bold"
                >
                  signup
                </button>
              </p>
            </form>
          </main>

          <img 
            src="/assets/images/header-bg.jpg" 
            alt="background" 
            className="fixed top-0 left-0 object-cover sm:min-w-[100vw] w-full h-[100vh] -z-10" 
          />

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </div>
      )}

      {/* ── 6B. EXACT SIGN UP PAGE (/signup) ──────────────────────────────── */}
      {currentRoute === 'signup' && (
        <div className="min-h-screen w-full flex flex-col justify-between relative">
          <div className="flex justify-around bg-gradient-to-b from-[#010318] to-transparent p-4 z-20">
            <img 
              src="/assets/icons/logo-word.png" 
              alt="logo" 
              onError={(e) => { e.currentTarget.src = 'https://munowatch.com/assets/icons/logo-word.png'; }}
              className="w-52 object-contain cursor-pointer" 
              onClick={() => setCurrentRoute('landing')}
            />
            <button 
              onClick={() => setCurrentRoute('login')}
              className="p-2 px-4 border border-green-500 text-green-500 rounded-md hover:bg-green-700 hover:text-white font-bold transition-all"
            >
              Log In
            </button>
          </div>

          <main className="container mx-auto flex flex-col justify-center items-center p-4 z-20 flex-1 my-auto">
            <form onSubmit={handleSignupSubmit} className="p-8 bg-slate-100 rounded-sm w-full lg:w-[30vw] mb-8 text-gray-800 shadow-2xl">
              <p className="text-center text-2xl mb-2 font-bold text-gray-900">Create a free account</p>

              {authError && (
                <div className="mb-4 p-2.5 rounded bg-red-100 border border-red-300 text-red-700 text-xs">
                  {authError}
                </div>
              )}

              {/* Google Sign In */}
              <div className="flex flex-col gap-4 items-center mb-4">
                <button 
                  type="button"
                  id="google-signin-btn"
                  onClick={() => {
                    const user = { username: 'GoogleUser', email: 'user@gmail.com', plan: 'Standard Plan', remainingDays: 30 };
                    setCurrentUser(user);
                    localStorage.setItem('freewatch_user', JSON.stringify(user));
                    setCurrentRoute('home');
                  }}
                  className="bg-white text-black p-2.5 px-4 rounded shadow border border-gray-300 flex items-center gap-2 hover:bg-gray-100 font-medium text-sm w-full justify-center"
                >
                  <img src="/assets/icons/google-color-icon.svg" alt="Google" className="w-5 h-5" />
                  Sign in with Google
                </button>
              </div>

              {/* OR Divider */}
              <div id="or-divider" className="w-full relative h-6 flex justify-center py-4 mb-2">
                <hr className="border-t border-gray-300 w-60 absolute top-1/2" />
                <p className="text-center text-gray-400 absolute w-16 top-1 bg-slate-100 text-xs font-bold">OR</p>
              </div>

              {/* Username field */}
              <div className="flex flex-col mt-3">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Username: </span>
                </label>
                <input 
                  type="text" 
                  value={signupUsername}
                  onChange={(e) => setSignupUsername(e.target.value)}
                  className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3 text-sm" 
                  placeholder="e.g. JohnDoe"
                />
              </div>

              {/* Email field */}
              <div className="flex flex-col mt-3">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Email: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <input 
                  type="email" 
                  required
                  value={signupEmail}
                  onChange={(e) => setSignupEmail(e.target.value)}
                  className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3 text-sm" 
                  placeholder="name@example.com"
                />
              </div>

              {/* Telephone with Uganda Dial Code matching intlTelInput */}
              <div className="flex flex-col mt-3">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Telephone no: </span>
                </label>
                <div className="flex items-center rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black overflow-hidden focus-within:outline-green-500">
                  <span className="bg-gray-200 px-3 py-3 text-xs font-bold text-gray-700 border-r border-gray-300">
                    🇺🇬 +256
                  </span>
                  <input 
                    type="tel" 
                    value={signupPhone}
                    onChange={(e) => setSignupPhone(e.target.value)}
                    className="p-3 text-sm bg-transparent outline-none flex-1" 
                    placeholder="782 000 000"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="flex flex-col mt-3 relative">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Password: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <div className="relative">
                  <input 
                    type={showPassword ? "text" : "password"} 
                    required
                    value={signupPassword}
                    onChange={(e) => setSignupPassword(e.target.value)}
                    className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3 pr-10 text-sm w-full" 
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-black"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div className="flex flex-col mt-3 relative">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Confirm Password: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <div className="relative">
                  <input 
                    type={showConfirmPassword ? "text" : "password"} 
                    required
                    value={signupConfirmPassword}
                    onChange={(e) => setSignupConfirmPassword(e.target.value)}
                    className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3 pr-10 text-sm w-full" 
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-black"
                  >
                    {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Terms checkbox */}
              <div className="flex gap-x-2 my-4 items-center">
                <input 
                  type="checkbox" 
                  id="tncs" 
                  checked={acceptTerms}
                  onChange={(e) => setAcceptTerms(e.target.checked)}
                  className="outline-green-500 accent-green-600 w-4 h-4 cursor-pointer" 
                />
                <label htmlFor="tncs" className="text-xs text-gray-700 cursor-pointer">
                  I accept the{' '}
                  <button 
                    type="button" 
                    onClick={() => setActiveModal('terms')}
                    className="text-green-600 hover:underline font-bold"
                  >
                    Terms and Conditions
                  </button>
                </label>
              </div>

              <input 
                type="submit" 
                value={isSubmitting ? "Please wait..." : "Sign Up"} 
                disabled={isSubmitting || !acceptTerms}
                className="rounded-sm outline-none p-3 my-2 w-full bg-green-500 disabled:bg-green-400/40 hover:bg-green-600 text-white font-bold cursor-pointer disabled:cursor-not-allowed transition-all shadow-md text-sm uppercase tracking-wider" 
              />

              <p className="my-2 text-xs text-center text-gray-600">
                Already have an account?{' '}
                <button 
                  type="button" 
                  onClick={() => setCurrentRoute('login')}
                  className="text-green-500 hover:underline font-bold"
                >
                  sign in
                </button>
              </p>
            </form>
          </main>

          <img 
            src="/assets/images/header-bg.jpg" 
            alt="background" 
            className="fixed top-0 left-0 object-cover sm:min-w-[100vw] w-full h-[100vh] -z-10" 
          />

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </div>
      )}

      {/* ── 6C. EXACT FORGOT PASSWORD PAGE (/forgotpassword) ─────────────── */}
      {currentRoute === 'forgotpassword' && (
        <div className="min-h-screen w-full flex flex-col justify-between relative">
          <div className="flex justify-around bg-gradient-to-b from-[#010318] to-transparent p-4 z-20">
            <img 
              src="/assets/icons/logo-word.png" 
              alt="logo" 
              onError={(e) => { e.currentTarget.src = 'https://munowatch.com/assets/icons/logo-word.png'; }}
              className="w-52 object-contain cursor-pointer" 
              onClick={() => setCurrentRoute('landing')}
            />
            <button 
              onClick={() => setCurrentRoute('login')}
              className="p-2 px-4 border border-green-500 text-green-500 rounded-md hover:bg-green-700 hover:text-white font-bold transition-all"
            >
              Sign In
            </button>
          </div>

          <main className="container mx-auto flex flex-col justify-center items-center p-4 z-20 flex-1 my-auto">
            <form onSubmit={handleForgotSubmit} className="p-8 bg-slate-100 rounded-sm w-full lg:w-[30vw] mb-8 text-gray-800 shadow-2xl">
              <p className="text-center text-2xl mb-4 font-bold text-gray-900">Reset Password</p>

              {authSuccess && (
                <div className="mb-4 p-3 rounded bg-green-100 border border-green-300 text-green-800 text-xs flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-600 flex-shrink-0" />
                  <span>{authSuccess}</span>
                </div>
              )}

              <div className="flex flex-col mt-4">
                <label className="mb-1 text-sm font-medium flex items-center">
                  <span className="w-6 mr-2 h-0.5 bg-green-500 rounded-full"></span>
                  <span className="font-bold text-gray-500 text-xs uppercase">Enter your email: </span>
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <input 
                  type="email" 
                  required
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  className="rounded-sm outline outline-1 outline-gray-400/30 bg-slate-100 text-black focus:outline-green-500 p-3.5 text-sm" 
                  placeholder="name@example.com"
                />
              </div>

              <input 
                type="submit" 
                value={isSubmitting ? "Please wait..." : "Restore password"} 
                disabled={isSubmitting}
                className="rounded-sm outline-none p-3 my-4 w-full bg-green-500 hover:bg-green-600 text-white font-bold cursor-pointer transition-all shadow-md text-sm uppercase tracking-wider" 
              />

              <div className="text-center mt-2">
                <button 
                  type="button" 
                  onClick={() => setCurrentRoute('login')}
                  className="text-green-500 hover:underline text-xs"
                >
                  I remember my password
                </button>
              </div>
            </form>
          </main>

          <img 
            src="/assets/images/header-bg.jpg" 
            alt="background" 
            className="fixed top-0 left-0 object-cover sm:min-w-[100vw] w-full h-[100vh] -z-10" 
          />

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </div>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 7: MY ACCOUNT PAGE (/myaccount)
      ═════════════════════════════════════════════════════════════════════ */}
      {currentRoute === 'myaccount' && currentUser && (
        <main className="w-full flex flex-col min-h-screen">
          <div className="w-[95%] lg:w-[60%] mx-auto py-10 flex-1 space-y-6">
            <h1 className="text-2xl sm:text-3xl font-black text-white">Account Settings</h1>

            <div className="bg-[#0a0d24] border border-gray-800 rounded-xl p-6 space-y-6 shadow-xl">
              <div className="flex items-center gap-4 pb-6 border-b border-gray-800">
                <div className="w-16 h-16 rounded-full bg-green-500 text-black font-black text-2xl flex items-center justify-center">
                  {currentUser.username.charAt(0).toUpperCase()}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white">{currentUser.username}</h3>
                  <p className="text-sm text-gray-400">{currentUser.email}</p>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="p-4 rounded-lg bg-white/5 border border-white/5">
                  <p className="text-xs text-gray-400 uppercase font-bold mb-1">Current Plan</p>
                  <p className="text-lg font-bold text-green-400">{currentUser.plan}</p>
                </div>

                <div className="p-4 rounded-lg bg-white/5 border border-white/5">
                  <p className="text-xs text-gray-400 uppercase font-bold mb-1">Subscription Remaining</p>
                  <p className="text-lg font-bold text-white">{currentUser.remainingDays} Days</p>
                </div>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-gray-800">
                <button
                  onClick={() => setCurrentRoute('grid')}
                  className="text-xs text-gray-400 hover:text-white"
                >
                  ← Back to Movies
                </button>

                <button
                  onClick={handleLogout}
                  className="px-5 py-2.5 rounded-md bg-red-500/20 hover:bg-red-500 text-red-400 hover:text-white border border-red-500/40 text-xs font-bold transition-all flex items-center gap-2"
                >
                  <LogOut className="w-4 h-4" />
                  Logout
                </button>
              </div>
            </div>
          </div>

          <MunoFooter onSelectModal={(m) => setActiveModal(m)} />
        </main>
      )}

      {/* ═════════════════════════════════════════════════════════════════════
          MODULE 8: STATIC POLICY MODALS (/dmca, /privacy, /terms, /about)
      ═════════════════════════════════════════════════════════════════════ */}
      {activeModal && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="relative w-full max-w-xl bg-[#080B1E] border border-gray-800 rounded-xl p-6 text-gray-200 shadow-2xl max-h-[80vh] overflow-y-auto animate-in fade-in zoom-in-95 duration-150">
            <button
              onClick={() => setActiveModal(null)}
              className="absolute top-4 right-4 text-gray-400 hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>

            {activeModal === 'about' && (
              <div className="space-y-3">
                <h3 className="text-xl font-bold text-white">About FreeWatch</h3>
                <p className="text-sm text-gray-300 leading-relaxed">
                  FreeWatch brings together the largest catalog of Ugandan translated movies (Luganda voice-overs) by world-renowned translators including VJ Junior, VJ Emmy, VJ Jingo, VJ Ice P, VJ Mark, VJ Sammy, and more.
                </p>
              </div>
            )}

            {activeModal === 'dmca' && (
              <div className="space-y-3">
                <h3 className="text-xl font-bold text-white">DMCA Copyright Policy</h3>
                <p className="text-sm text-gray-300 leading-relaxed">
                  FreeWatch complies with 17 U.S.C. § 512 and the Digital Millennium Copyright Act (&ldquo;DMCA&rdquo;). We do not host any media files directly on our web servers; all multimedia content is indexed from publicly available upstream CDN endpoints. For copyright inquiries, contact info@munowatch.com.
                </p>
              </div>
            )}

            {activeModal === 'privacy' && (
              <div className="space-y-3">
                <h3 className="text-xl font-bold text-white">Privacy Policy</h3>
                <p className="text-sm text-gray-300 leading-relaxed">
                  We respect your privacy. We do not sell or distribute personal information. Any data stored locally (such as Watchlists or session tokens) is maintained strictly for your personalized browsing experience.
                </p>
              </div>
            )}

            {activeModal === 'terms' && (
              <div className="space-y-3">
                <h3 className="text-xl font-bold text-white">Terms &amp; Conditions</h3>
                <p className="text-sm text-gray-300 leading-relaxed">
                  By accessing FreeWatch, you agree to comply with standard acceptable use guidelines. Streamed content is strictly intended for personal, non-commercial entertainment.
                </p>
              </div>
            )}

            <button
              onClick={() => setActiveModal(null)}
              className="mt-6 w-full py-2.5 rounded bg-green-500 hover:bg-green-600 text-black font-bold text-xs"
            >
              Close
            </button>
          </div>
        </div>
      )}

    </div>
  );
}

// ── Exact MunoWatch Movie Poster Card matching output.css & grid.min.js ─────
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
            e.currentTarget.src = '/assets/images/tile-fallback.jpg';
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

// ── Exact 4-Column Footer from MunoWatch.com ────────────────────────────────
function MunoFooter({ onSelectModal }) {
  return (
    <footer className="bg-[#010318] p-8 text-gray-500 text-sm mt-auto print:hidden border-t border-gray-900 select-none z-20">
      <div className="w-[95%] lg:w-[86%] mx-auto grid sm:grid-cols-2 md:grid-cols-4 gap-5 gap-y-6">
        <p className="text-xs" id="copyright">
          {new Date().getFullYear()} &copy; FreeWatch. All Rights Reserved.
        </p>
        
        <article>
          <p className="text-white font-bold pb-4">FAQ</p>
          <ul className="flex flex-col gap-y-3 text-xs">
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <button onClick={() => onSelectModal('about')} className="hover:text-green-500 text-left">About</button>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <button onClick={() => onSelectModal('dmca')} className="hover:text-green-500 text-left">DMCA</button>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <button onClick={() => onSelectModal('privacy')} className="hover:text-green-500 text-left">Privacy Policy</button>
            </li>
            <li className="flex gap-x-1 items-center">
              <span>›</span>
              <button onClick={() => onSelectModal('terms')} className="hover:text-green-500 text-left">Terms &amp; Conditions</button>
            </li>
          </ul>
        </article>

        <article>
          <p className="text-white font-bold pb-4">CONTACTS</p>
          <ul className="flex flex-col gap-y-3 text-xs">
            <li className="flex gap-x-2">
              <span>✉</span>
              <a href="mailto:info@munowatch.com" className="hover:text-green-500">info@munowatch.com</a>
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
                <img src="/assets/icons/social/facebook.png" alt="fb" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://x.com/muno_watch" target="_blank" rel="noopener noreferrer">
                <img src="/assets/icons/social/x.png" alt="x" className="w-7 p-1.5 rounded-md bg-gray-400 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="http://instagram.com/munowatch" target="_blank" rel="noopener noreferrer">
                <img src="/assets/icons/social/instagram.png" alt="ig" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://wa.me/+256700970036" target="_blank" rel="noopener noreferrer">
                <img src="/assets/icons/social/whatsapp.png" alt="wa" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
            <li>
              <a href="https://www.tiktok.com/@muno.watch.ug" target="_blank" rel="noopener noreferrer">
                <img src="/assets/icons/social/tiktok.png" alt="tt" className="w-7 hover:scale-110 transition-transform" />
              </a>
            </li>
          </ul>
        </article>
      </div>
    </footer>
  );
}
