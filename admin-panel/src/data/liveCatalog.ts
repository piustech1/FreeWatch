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
    streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4",
    episodes: [
      { num: 1, title: "Episode 1", duration: "50m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 2, title: "Episode 2", duration: "48m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/02.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
      { num: 3, title: "Episode 3", duration: "52m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/03.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
      { num: 4, title: "Episode 4", duration: "51m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/04.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
      { num: 5, title: "Episode 5", duration: "49m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/05.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
      { num: 6, title: "Episode 6", duration: "53m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/06.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
      { num: 7, title: "Episode 7", duration: "50m", streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4" },
    ]
  },
  {
    id: "67364",
    title: "Animals",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Crime", "Thriller"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    rating: "9.1",
    year: "2025",
    duration: "2h 05m",
    isTv: false,
    overview: "Desperate to pay their son's ransom, parents embark on a dangerous and relentless rescue mission. Luganda translation by VJ Junior.",
    streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4"
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
    streamUrl: "https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4"
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

// Helper: parse series base title and episode number
export function parseSeriesEpisodeInfo(rawTitle: string): {
  isEpisode: boolean;
  baseTitle: string;
  epNum: number;
} {
  const clean = (rawTitle || '').trim();

  // Pattern A: Title S01E16, Title S1 Ep 16
  const sPattern = /^(.*?)[.\s_-]+(?:s|season)\s*(\d+)[.\s_-]*(?:e|ep|episode)\s*(\d+)(.*)$/i;
  let match = clean.match(sPattern);
  if (match) {
    return {
      isEpisode: true,
      baseTitle: match[1].trim(),
      epNum: parseInt(match[3], 10) || 1,
    };
  }

  // Pattern B: Title Episode 16, Title Ep 16, Title Part 3
  const epPattern = /^(.*?)[.\s_-]+(?:episode|ep|part)\s*(\d+)(.*)$/i;
  match = clean.match(epPattern);
  if (match) {
    return {
      isEpisode: true,
      baseTitle: match[1].trim(),
      epNum: parseInt(match[2], 10) || 1,
    };
  }

  // Pattern C: Title 16, Title 02 (e.g. Mirzapur 16, Mirzapur 15)
  const numPattern = /^(.*?)\s+(\d{1,3})$/i;
  match = clean.match(numPattern);
  if (match) {
    const num = parseInt(match[2], 10);
    // Ignore 4-digit years (1980-2030)
    if (num > 0 && num <= 100) {
      return {
        isEpisode: true,
        baseTitle: match[1].trim(),
        epNum: num,
      };
    }
  }

  return {
    isEpisode: false,
    baseTitle: clean,
    epNum: 1,
  };
}

export function useLiveCatalog() {
  const [catalog, setCatalog] = useState<CatalogMovie[]>(FALLBACK_MOVIES);
  const [totalCount, setTotalCount] = useState<number>(7097);
  const [loading, setLoading] = useState<boolean>(false);

  // Raw normalizer for an individual movie or episode
  const normalizeRaw = useCallback((m: any, idx: number) => {
    const rawTitle = (m.title || m.video_title || 'Untitled Movie').trim();
    const rawVj = (m.vj || m.vjname || m.vjName || '').trim();
    const isUniversal = rawVj.toLowerCase().includes('universal') || !rawVj;
    const vj = isUniversal ? 'VJ Junior' : (rawVj.toUpperCase().startsWith('VJ') ? rawVj : `VJ ${rawVj}`);
    
    const seriesCode = m.series_code || m.seriesCode || '';
    const category = m.category || (m.is_series || seriesCode ? 'Series' : 'Action');
    const isDeclaredSeries = Boolean(
      m.is_series === true ||
      m.is_series === 1 ||
      m.is_series === '1' ||
      (seriesCode && seriesCode !== '0') ||
      /series/i.test(category)
    );

    const episodeInfo = parseSeriesEpisodeInfo(rawTitle);
    const isTv = isDeclaredSeries || episodeInfo.isEpisode;
    const streamUrl = m.playingurl || m.playingUrl || m.videoUrl || m.streamUrl || 'https://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4';
    const duration = m.duration || (isTv ? '50m' : '1h 45m');

    return {
      id: String(m.id || m.vid || `fw-${idx}`),
      rawTitle,
      baseTitle: episodeInfo.isEpisode ? episodeInfo.baseTitle : rawTitle,
      isEpisode: episodeInfo.isEpisode,
      epNum: episodeInfo.epNum,
      vj,
      category,
      imageUrl: m.image || m.thumbnail || m.poster || m.poster_path || 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
      backdropUrl: m.backdrop || m.backdrop_path || m.cover || m.image || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
      rating: String(m.rating || (8.5 + ((idx % 12) / 10)).toFixed(1)),
      year: String(m.year || m.release_year || '2025'),
      duration,
      isTv,
      seriesCode,
      overview: m.overview || m.synopsis || m.description || `Enjoy ${episodeInfo.baseTitle} in high definition with exclusive Luganda voice-over translation by ${vj}.`,
      streamUrl,
    };
  }, []);

  // Group raw items into deduplicated catalog movies
  const groupAndDeduplicate = useCallback((rawItems: any[]): CatalogMovie[] => {
    const seriesMap = new Map<string, {
      parent: CatalogMovie;
      episodesMap: Map<number, { num: number; title: string; duration: string; streamUrl: string }>;
    }>();
    const movieList: CatalogMovie[] = [];

    // Filter junk items
    const blocklist = ['eps', 'episode', 'untitled', 'movie', 'null', 'none'];
    const validItems = rawItems.filter(item => {
      if (!item) return false;
      const t = (item.title || item.video_title || '').toLowerCase().trim();
      return t && !blocklist.includes(t) && !/^(?:eps?|episode)\s*\d*$/i.test(t);
    });

    validItems.forEach((raw, idx) => {
      const item = normalizeRaw(raw, idx);

      if (item.isTv || item.isEpisode) {
        // Group key for TV Series
        const seriesKey = item.seriesCode && item.seriesCode !== '0'
          ? `series-code-${item.seriesCode}`
          : `series-title-${item.baseTitle.toLowerCase()}`;

        if (!seriesMap.has(seriesKey)) {
          seriesMap.set(seriesKey, {
            parent: {
              id: item.id,
              title: item.baseTitle,
              vj: item.vj,
              category: 'Series',
              genres: ['Series', 'Luganda Dubbed'],
              imageUrl: item.imageUrl,
              backdropUrl: item.backdropUrl,
              rating: item.rating,
              year: item.year,
              duration: item.duration,
              isTv: true,
              seriesCode: item.seriesCode,
              overview: item.overview,
              streamUrl: item.streamUrl,
              episodes: [],
            },
            episodesMap: new Map(),
          });
        }

        const entry = seriesMap.get(seriesKey)!;
        // Keep highest rating or newest backdrop if current is richer
        if (item.imageUrl && !entry.parent.imageUrl) {
          entry.parent.imageUrl = item.imageUrl;
        }

        // Add episode
        entry.episodesMap.set(item.epNum, {
          num: item.epNum,
          title: `Episode ${item.epNum}`,
          duration: item.duration,
          streamUrl: item.streamUrl,
        });
      } else {
        // Regular standalone movie
        movieList.push({
          id: item.id,
          title: item.baseTitle,
          vj: item.vj,
          category: item.category,
          genres: [item.category, 'Luganda Dubbed'],
          imageUrl: item.imageUrl,
          backdropUrl: item.backdropUrl,
          rating: item.rating,
          year: item.year,
          duration: item.duration,
          isTv: false,
          overview: item.overview,
          streamUrl: item.streamUrl,
        });
      }
    });

    // Finalize series objects with sorted episodes
    const finalizedSeries: CatalogMovie[] = [];
    seriesMap.forEach(({ parent, episodesMap }) => {
      const eps = Array.from(episodesMap.values()).sort((a, b) => a.num - b.num);
      // If only 1 episode was loaded from API slice, generate adjacent episode references
      if (eps.length === 1 && eps[0]) {
        const baseStream = eps[0].streamUrl;
        const e1 = eps[0];
        parent.episodes = [
          e1,
          { num: e1.num + 1, title: `Episode ${e1.num + 1}`, duration: "48m", streamUrl: baseStream },
          { num: e1.num + 2, title: `Episode ${e1.num + 2}`, duration: "52m", streamUrl: baseStream },
          { num: e1.num + 3, title: `Episode ${e1.num + 3}`, duration: "50m", streamUrl: baseStream }
        ];
        parent.streamUrl = e1.streamUrl;
      } else if (eps.length > 0) {
        parent.episodes = eps;
        // Stream URL defaults to Episode 1
        parent.streamUrl = eps[0].streamUrl;
      }
      finalizedSeries.push(parent);
    });

    // Merge series and movies, sorted by ID descending (newest to oldest)
    const combined = [...finalizedSeries, ...movieList].sort((a, b) => {
      const idA = parseInt(a.id, 10) || 0;
      const idB = parseInt(b.id, 10) || 0;
      return idB - idA;
    });

    return combined;
  }, [normalizeRaw]);

  // Load from API & Firebase
  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    const gatheredRaw: any[] = [];

    // 1. Fetch Dashboard API (Featured + Latest + Categories)
    const p1 = fetch('/api/v1/dashboard')
      .then(r => r.ok ? r.json() : null)
      .then(json => {
        if (json && json.success && json.data) {
          const d = json.data;
          if (d.featured) gatheredRaw.push(d.featured);
          if (Array.isArray(d.latest)) gatheredRaw.push(...d.latest);
          if (d.categories && typeof d.categories === 'object') {
            Object.values(d.categories).forEach((catList: any) => {
              if (Array.isArray(catList)) gatheredRaw.push(...catList);
            });
          }
          if (d.totalMovies && isMounted) {
            setTotalCount(d.totalMovies);
          }
        }
      })
      .catch(() => {});

    // 2. Fetch Movies API (Page 1)
    const p2 = fetch('/api/v1/movies?page=1&limit=60&sort=newest')
      .then(r => r.ok ? r.json() : null)
      .then(json => {
        if (json && json.success && Array.isArray(json.data)) {
          gatheredRaw.push(...json.data);
          if (json.total && isMounted) setTotalCount(json.total);
        }
      })
      .catch(() => {});

    Promise.all([p1, p2]).then(() => {
      if (isMounted && gatheredRaw.length > 0) {
        const grouped = groupAndDeduplicate(gatheredRaw);
        if (grouped.length > 0) {
          setCatalog(grouped);
        }
      }
      if (isMounted) setLoading(false);
    });

    // 3. Listen to RTDB
    const catalogRef = ref(rtdb, 'munowatch/catalog');
    const unsub = onValue(catalogRef, (snapshot) => {
      if (snapshot.exists() && isMounted) {
        const val = snapshot.val();
        let items: any[] = [];
        if (Array.isArray(val)) items = val;
        else if (typeof val === 'object' && val !== null) items = Object.values(val);

        if (items.length > 0) {
          const grouped = groupAndDeduplicate(items);
          if (grouped.length > 0) {
            setCatalog(prev => {
              const seen = new Set(grouped.map(m => m.id));
              const combined = [...grouped];
              prev.forEach(p => {
                if (!seen.has(p.id)) {
                  seen.add(p.id);
                  combined.push(p);
                }
              });
              return combined.sort((a, b) => {
                const idA = parseInt(a.id, 10) || 0;
                const idB = parseInt(b.id, 10) || 0;
                return idB - idA;
              });
            });
          }
        }
      }
    });

    return () => {
      isMounted = false;
      unsub();
    };
  }, [groupAndDeduplicate]);

  // Derived sections
  const latestMovies = useMemo(() => [...catalog], [catalog]);
  const trendingMovies = useMemo(() => [...catalog].sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating)), [catalog]);
  const seriesMovies = useMemo(() => catalog.filter(m => m.isTv), [catalog]);
  const actionMovies = useMemo(() => catalog.filter(m => /action/i.test(m.category)), [catalog]);
  const dramaMovies = useMemo(() => catalog.filter(m => /drama|romance/i.test(m.category)), [catalog]);
  const comedyMovies = useMemo(() => catalog.filter(m => /comedy/i.test(m.category)), [catalog]);
  const sciFiMovies = useMemo(() => catalog.filter(m => /sci-fi|fantasy/i.test(m.category)), [catalog]);
  const horrorMovies = useMemo(() => catalog.filter(m => /horror|thriller/i.test(m.category)), [catalog]);
  const animationMovies = useMemo(() => catalog.filter(m => /animation|anime/i.test(m.category)), [catalog]);

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
    horrorMovies,
    animationMovies,
    getMoviesByVj,
    getVjMovieCount,
    searchCatalog
  };
}
