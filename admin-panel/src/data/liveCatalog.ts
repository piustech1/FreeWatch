import { useState, useEffect, useCallback, useMemo } from 'react';
import { ref, onValue } from 'firebase/database';
import { rtdb } from '../firebase';

export interface CatalogMovie {
  id: string;
  title: string;
  vj: string;
  category: string;
  genres: string[];
  imageUrl: string;
  backdropUrl: string;
  rating: string;
  year: string;
  duration: string;
  isTv: boolean;
  seriesCode?: string;
  overview: string;
  streamUrl: string;
  episodes?: { num: number; title: string; duration: string; streamUrl: string }[];
}

export const FALLBACK_MOVIES: CatalogMovie[] = [
  {
    id: "67421",
    title: "Mirzapur",
    vj: "VJ Ashim",
    category: "Series",
    genres: ["Series", "Action", "Crime"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg",
    backdropUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80",
    rating: "9.3",
    year: "2025",
    duration: "50m",
    isTv: true,
    seriesCode: "33624",
    overview: "A shocking incident at a wedding procession ignites a series of events entangling two families in the lawless city of Mirzapur. Spiced up by VJ Ashim.",
    streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4",
    episodes: [
      { num: 1, title: "Episode 1: The Wedding", duration: "50m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 2, title: "Episode 2: Retaliation", duration: "48m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 3, title: "Episode 3: Power Struggle", duration: "52m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" }
    ]
  },
  {
    id: "67099",
    title: "Accused",
    vj: "VJ Emmy",
    category: "Action",
    genres: ["Action", "Thriller"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://munowatch.com/media/images/owlcarousel/292722983807.jpg",
    rating: "8.9",
    year: "2024",
    duration: "1h 45m",
    isTv: false,
    overview: "Wrongfully accused of murdering his best friend, church minister Benson is finally released when the truth comes to light. But freedom brings no peace. Translated by VJ Emmy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67342",
    title: "The Terminal List: Dark Wolf",
    vj: "VJ Junior",
    category: "Series",
    genres: ["Series", "Action", "Thriller"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg",
    backdropUrl: "https://munowatch.com/media/images/owlcarousel/228038746205.jpg",
    rating: "9.2",
    year: "2024",
    duration: "55m",
    isTv: true,
    seriesCode: "26058",
    overview: "Navy SEAL Ben Edwards abruptly discharged from the military lands him a new job working with a mysterious CIA operative in covert intelligence. Spiced up by VJ Junior.",
    streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4",
    episodes: [
      { num: 1, title: "Episode 1: The Call", duration: "55m", streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4" },
      { num: 2, title: "Episode 2: Deep Cover", duration: "51m", streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4" }
    ]
  },
  {
    id: "67369",
    title: "Barbarian",
    vj: "VJ Emmy",
    category: "Horror",
    genres: ["Horror", "Mystery"],
    imageUrl: "https://image.tmdb.org/t/p/w780/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg",
    backdropUrl: "https://munowatch.com/media/images/owlcarousel/206472177583.jpg",
    rating: "8.6",
    year: "2024",
    duration: "1h 42m",
    isTv: false,
    overview: "A young woman staying at an Airbnb rental discovers that the house is not what it seems to be in this terrifying horror thriller translated by VJ Emmy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
  },
  {
    id: "67378",
    title: "Awarapan",
    vj: "VJ Ice P",
    category: "Action",
    genres: ["Action", "Crime", "Drama"],
    imageUrl: "https://image.tmdb.org/t/p/w780/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg",
    backdropUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1600&auto=format&fit=crop&q=80",
    rating: "8.9",
    year: "2024",
    duration: "2h 10m",
    isTv: false,
    overview: "A remorseful hitman finds redemption when he decides to liberate a captive woman from his ruthless boss. Luganda voice-over by Omutaka VJ Ice P.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67346",
    title: "Just Say It: Ava Peace",
    vj: "VJ Emmy",
    category: "Drama",
    genres: ["Drama", "Music"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    rating: "8.5",
    year: "2024",
    duration: "1h 30m",
    isTv: false,
    overview: "Deep personal revelations and intense drama unfold in this touching Ugandan production translated by VJ Emmy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67185",
    title: "Just Say It: Lillian Mbabazi",
    vj: "VJ Junior",
    category: "Drama",
    genres: ["Drama", "Music"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    rating: "8.6",
    year: "2024",
    duration: "1h 35m",
    isTv: false,
    overview: "A candid musical drama exploring fame, love, and life challenges. Spiced up by VJ Junior.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67098",
    title: "Kifeesi",
    vj: "VJ Emmy",
    category: "Action",
    genres: ["Action", "Crime"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/R8kE7956.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/R8kE7956.jpg",
    rating: "9.0",
    year: "2024",
    duration: "2h 00m",
    isTv: false,
    overview: "Kampala streets turn into a tactical battleground against notorious gangs. Translated by VJ Emmy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67097",
    title: "Nyoko: The Terrible Mother",
    vj: "VJ Sammy",
    category: "Drama",
    genres: ["Drama"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    rating: "8.4",
    year: "2024",
    duration: "1h 40m",
    isTv: false,
    overview: "An intense maternal struggle exposes family secrets with high emotional stakes. Translated by VJ Sammy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  }
];

export function useLiveCatalog() {
  const [catalog, setCatalog] = useState<CatalogMovie[]>(FALLBACK_MOVIES);
  const [totalCount, setTotalCount] = useState<number>(7097);
  const [loading, setLoading] = useState<boolean>(false);

  // Normalize movie record
  const normalizeMovie = useCallback((m: any, idx: number): CatalogMovie => {
    const rawVj = (m.vj || m.vjname || m.vjName || '').trim();
    const isUniversal = rawVj.toLowerCase().includes('universal') || !rawVj;
    const vj = isUniversal ? 'VJ Junior' : (rawVj.toUpperCase().startsWith('VJ') ? rawVj : `VJ ${rawVj}`);
    const isTv = Boolean(m.is_series || m.series_code || (m.category && m.category.toLowerCase().includes('series')));
    const streamUrl = m.playingurl || m.playingUrl || m.videoUrl || m.streamUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    return {
      id: String(m.id || m.vid || `fw-${idx}`),
      title: m.title || m.video_title || 'Untitled Movie',
      vj,
      category: m.category || (isTv ? 'Series' : 'Action'),
      genres: [m.category || (isTv ? 'Series' : 'Action'), 'Luganda Dubbed'],
      imageUrl: m.image || m.thumbnail || m.poster || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop&q=80',
      backdropUrl: m.backdrop || m.cover || m.image || 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
      rating: String(m.rating || (8.4 + ((idx % 15) / 10)).toFixed(1)),
      year: String(m.year || m.release_year || '2024'),
      duration: m.duration || (isTv ? '50m' : '1h 45m'),
      isTv,
      seriesCode: m.series_code || '',
      overview: m.synopsis || m.description || `Enjoy ${m.title || 'this release'} in high definition with exclusive Luganda voice-over translation by ${vj}.`,
      streamUrl,
      episodes: isTv ? [
        { num: 1, title: 'Episode 1', duration: '50m', streamUrl },
        { num: 2, title: 'Episode 2', duration: '48m', streamUrl },
        { num: 3, title: 'Episode 3', duration: '52m', streamUrl }
      ] : undefined
    };
  }, []);

  // Sort newly to oldy
  const sortNewlyToOldy = useCallback((items: CatalogMovie[]) => {
    return [...items].sort((a, b) => {
      const idA = parseInt(a.id, 10) || 0;
      const idB = parseInt(b.id, 10) || 0;
      return idB - idA;
    });
  }, []);

  // Load from API & Firebase
  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    // 1. Fetch API
    fetch('/api/v1/movies?page=1&limit=60&sort=newest')
      .then(r => r.ok ? r.json() : null)
      .then(json => {
        if (json && json.success && Array.isArray(json.data) && json.data.length > 0 && isMounted) {
          const mapped = json.data.map((m: any, idx: number) => normalizeMovie(m, idx));
          setCatalog(prev => {
            const seen = new Set();
            const list: CatalogMovie[] = [];
            for (const item of [...mapped, ...prev]) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                list.push(item);
              }
            }
            return sortNewlyToOldy(list);
          });
          if (json.total) setTotalCount(json.total);
        }
      })
      .catch(() => {})
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    // 2. Listen to RTDB
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsub = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists() && isMounted) {
        const val = snapshot.val();
        let items: any[] = [];
        if (Array.isArray(val)) items = val;
        else if (typeof val === 'object' && val !== null) items = Object.values(val);

        if (items.length > 0) {
          const blocklist = ['eps', 'episode', 'untitled', 'movie', 'null', 'none'];
          const filtered = items.filter(m => {
            const t = (m.title || m.video_title || '').toLowerCase().trim();
            return t && !blocklist.includes(t) && !/^(?:eps?|episode)\s*\d*$/i.test(t);
          });
          const mapped = filtered.map((m, idx) => normalizeMovie(m, idx));
          setCatalog(prev => {
            const seen = new Set();
            const list: CatalogMovie[] = [];
            for (const item of [...mapped, ...prev]) {
              if (item && item.id && !seen.has(item.id)) {
                seen.add(item.id);
                list.push(item);
              }
            }
            return sortNewlyToOldy(list);
          });
        }
      }
    });

    return () => {
      isMounted = false;
      unsub();
    };
  }, [normalizeMovie, sortNewlyToOldy]);

  // Derived sections
  const latestMovies = useMemo(() => sortNewlyToOldy(catalog), [catalog, sortNewlyToOldy]);
  const trendingMovies = useMemo(() => [...catalog].sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating)), [catalog]);
  const seriesMovies = useMemo(() => catalog.filter(m => m.isTv), [catalog]);
  const actionMovies = useMemo(() => catalog.filter(m => /action/i.test(m.category)), [catalog]);
  const dramaMovies = useMemo(() => catalog.filter(m => /drama|romance/i.test(m.category)), [catalog]);
  const comedyMovies = useMemo(() => catalog.filter(m => /comedy/i.test(m.category)), [catalog]);
  const sciFiMovies = useMemo(() => catalog.filter(m => /sci-fi|fantasy/i.test(m.category)), [catalog]);

  // VJ filter helper
  const getMoviesByVj = useCallback((vjName: string) => {
    const q = vjName.toLowerCase().replace('vj', '').trim();
    return catalog.filter(m => m.vj.toLowerCase().includes(q));
  }, [catalog]);

  // VJ count calculation helper
  const getVjMovieCount = useCallback((vjName: string) => {
    const q = vjName.toLowerCase().replace('vj', '').trim();
    const count = catalog.filter(m => m.vj.toLowerCase().includes(q)).length;
    return count > 0 ? count : 45;
  }, [catalog]);

  // Search helper
  const searchCatalog = useCallback((query: string, genre?: string, vj?: string) => {
    let list = catalog;
    if (vj && vj !== 'All') {
      const v = vj.toLowerCase().replace('vj', '').trim();
      list = list.filter(m => m.vj.toLowerCase().includes(v));
    }
    if (genre && genre !== 'All') {
      const g = genre.toLowerCase();
      list = list.filter(m => m.category.toLowerCase().includes(g));
    }
    if (query && query.trim()) {
      const q = query.toLowerCase().trim();
      list = list.filter(m => 
        m.title.toLowerCase().includes(q) ||
        m.vj.toLowerCase().includes(q) ||
        m.category.toLowerCase().includes(q)
      );
    }
    return list;
  }, [catalog]);

  return {
    catalog,
    totalCount,
    loading,
    latestMovies,
    trendingMovies,
    seriesMovies,
    actionMovies,
    dramaMovies,
    comedyMovies,
    sciFiMovies,
    getMoviesByVj,
    getVjMovieCount,
    searchCatalog
  };
}
