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
  tmdbId?: number;
  logoUrl?: string;
  cast?: { id: number; name: string; character: string; profileUrl?: string }[];
  episodes?: { num: number; title: string; duration: string; streamUrl: string; stillUrl?: string; overview?: string }[];
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
    genres: ["Horror", "Mystery", "Thriller"],
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
    genres: ["Drama", "Romance", "Music"],
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
    genres: ["Drama", "Romance", "Music"],
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
    genres: ["Drama", "Romance"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    rating: "8.4",
    year: "2024",
    duration: "1h 40m",
    isTv: false,
    overview: "An intense maternal struggle exposes family secrets with high emotional stakes. Translated by VJ Sammy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67095",
    title: "Alien: Romulus",
    vj: "VJ Junior",
    category: "Sci-Fi",
    genres: ["Sci-Fi", "Horror", "Action"],
    imageUrl: "https://image.tmdb.org/t/p/w780/b33nnKl1GSFbao4l3fZDDqsMx0F.jpg",
    backdropUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80",
    rating: "8.8",
    year: "2024",
    duration: "1h 59m",
    isTv: false,
    overview: "While scavenging the deep ends of a derelict space station, a group of young space colonizers come face to face with the most terrifying life form in the universe. Luganda translation by VJ Junior.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67096",
    title: "Deadpool & Wolverine",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Sci-Fi", "Comedy"],
    imageUrl: "https://image.tmdb.org/t/p/w780/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg",
    backdropUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1600&auto=format&fit=crop&q=80",
    rating: "9.1",
    year: "2024",
    duration: "2h 08m",
    isTv: false,
    overview: "A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary Deadpool behind him. Translated by VJ Junior.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  },
  {
    id: "67303",
    title: "Smile 2",
    vj: "VJ Emmy",
    category: "Horror",
    genres: ["Horror", "Mystery"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://munowatch.com/media/images/owlcarousel/292722983807.jpg",
    rating: "8.7",
    year: "2024",
    duration: "2h 07m",
    isTv: false,
    overview: "About to embark on a world tour, global pop sensation Skye Riley begins experiencing increasingly terrifying and inexplicable events. Translated by VJ Emmy.",
    streamUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
  },
  {
    id: "67309",
    title: "Living For Love",
    vj: "VJ Sammy",
    category: "Series",
    genres: ["Series", "Romance", "Drama"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/vYmL3744.jpg",
    rating: "8.5",
    year: "2025",
    duration: "45m",
    isTv: true,
    seriesCode: "28490",
    overview: "Intrigue, passion, and emotional trials unfold as two lovers navigate societal pressures and family secrets. Translated by VJ Sammy.",
    streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4",
    episodes: [
      { num: 1, title: "Episode 1: The Encounter", duration: "45m", streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4" },
      { num: 2, title: "Episode 2: Forbidden Bond", duration: "47m", streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4" },
      { num: 3, title: "Episode 3: The Crossroad", duration: "44m", streamUrl: "https://lunoluno.b-cdn.net/timo28/tyu/Self.Made.Inspired.by.the.Life.of.Madam.C.J.Walker.S01E01.mp4" },
    ]
  }
];

// Helper: map MunoWatch numeric category IDs or strings to clean standard genres
export function mapMunoCategoryId(rawCatId: any, rawCategory: string = '', title: string = ''): string {
  const catId = Number(rawCatId);
  if (catId === 1 || catId === 5) return 'Action';
  if (catId === 2 || catId === 9) return 'Sci-Fi';
  if (catId === 14 || catId === 10) return 'Horror';
  if (catId === 15 || catId === 8) return 'Drama';
  if (catId === 3) return 'Romance';
  if (catId === 16) return 'Animation';
  if (catId === 20) return 'Family';
  if (catId === 27) return 'Comedy';

  const catLower = (rawCategory || '').toLowerCase();
  if (catLower.includes('action')) return 'Action';
  if (catLower.includes('sci') || catLower.includes('fiction') || catLower.includes('fantasy')) return 'Sci-Fi';
  if (catLower.includes('horror') || catLower.includes('thriller')) return 'Horror';
  if (catLower.includes('romance') || catLower.includes('love')) return 'Romance';
  if (catLower.includes('drama')) return 'Drama';
  if (catLower.includes('comedy')) return 'Comedy';
  if (catLower.includes('animation') || catLower.includes('anime')) return 'Animation';

  const t = title.toLowerCase();
  if (/alien|space|future|galaxy|cyber|robot|matrix|planet|superhero|marvel|avatar|star\s*wars/i.test(t)) return 'Sci-Fi';
  if (/horror|dead|kill|blood|ghost|evil|monster|zombie|haunt|demon|devil|slasher|curse|fear/i.test(t)) return 'Horror';
  if (/love|heart|romance|kiss|wedding|passion|forever|lover/i.test(t)) return 'Romance';
  if (/laugh|funny|comedy|joke|fun|fool|stupid/i.test(t)) return 'Comedy';
  if (/drama|life|story|tear|struggle|family|mother|father|crime|truth/i.test(t)) return 'Drama';

  return 'Action';
}

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
    const rawTitle = (m.title || m.video_title || m.name || 'Untitled Movie').trim();
    const rawVj = (m.vj || m.vjname || m.vjName || '').trim();
    const isUniversal = rawVj.toLowerCase().includes('universal') || !rawVj;
    const vj = isUniversal ? 'VJ Junior' : (rawVj.toUpperCase().startsWith('VJ') ? rawVj : `VJ ${rawVj}`);
    
    const episodeInfo = parseSeriesEpisodeInfo(rawTitle);
    const seriesCode = m.series_code || m.seriesCode || '';
    
    // Explicit series indicators
    const hasExplicitSeasonOrEp = episodeInfo.isEpisode || /season|\b(?:s\d{1,2}|ep(?:isode)?\s*\d+|part\s*\d+)\b|eps\s*\d+/i.test(rawTitle);
    const hasMultipleEpisodes = Array.isArray(m.episodes) && m.episodes.length > 1;
    const isTv = Boolean(hasExplicitSeasonOrEp || (hasMultipleEpisodes && seriesCode && String(seriesCode) !== String(m.id || m.vid)));

    // Accurate category mapping
    const category = isTv ? 'Series' : mapMunoCategoryId(m.category_id || m.categoryId, m.category, episodeInfo.baseTitle);
    const genres = [category, 'Luganda Dubbed'];
    if (isTv && !genres.includes('Series')) genres.unshift('Series');

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
      genres,
      imageUrl: m.image || m.thumbnail || m.poster || m.poster_path || 'https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg',
      backdropUrl: m.backdrop || m.backdrop_path || m.cover || m.image || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80',
      rating: String(m.rating || (8.5 + ((idx % 12) / 10)).toFixed(1)),
      year: String(m.year || m.release_year || '2025'),
      duration,
      isTv,
      seriesCode,
      overview: m.overview || m.synopsis || m.description || `Enjoy ${episodeInfo.baseTitle} in high definition with exclusive Luganda voice-over translation by ${vj}.`,
      streamUrl,
      rawEpisodes: Array.isArray(m.episodes) ? m.episodes : [],
    };
  }, []);

  // Group raw items into strictly deduplicated catalog movies
  const groupAndDeduplicate = useCallback((rawItems: any[]): CatalogMovie[] => {
    const seriesMap = new Map<string, {
      parent: CatalogMovie;
      episodesMap: Map<number, { num: number; title: string; duration: string; streamUrl: string }>;
    }>();
    const movieMap = new Map<string, CatalogMovie>();

    // Filter junk items
    const blocklist = ['eps', 'episode', 'untitled', 'null', 'none'];
    const validItems = rawItems.filter(item => {
      if (!item) return false;
      const t = (item.title || item.video_title || item.name || '').toLowerCase().trim();
      return t && !blocklist.includes(t) && !/^(?:eps?|episode)\s*\d*$/i.test(t);
    });

    validItems.forEach((raw, idx) => {
      const item = normalizeRaw(raw, idx);

      // Clean alphanumeric canonical root key for strict 1-card deduplication
      const cleanRoot = item.baseTitle
        .toLowerCase()
        .replace(/\b(?:season\s*\d+|s\d{1,2}|ep(?:isode)?\s*\d+|part\s*\d+)\b/gi, '')
        .replace(/[^a-z0-9]/g, '')
        .trim();

      if (item.isTv || item.isEpisode) {
        // Unify by canonical root title so Mirzapur, Living For Love, etc. ALWAYS map to ONE single series
        const seriesKey = cleanRoot.length > 2 ? `series-${cleanRoot}` : `series-${item.id}`;

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

        // Also incorporate any nested rawEpisodes
        if (item.rawEpisodes && item.rawEpisodes.length > 0) {
          item.rawEpisodes.forEach((re: any, eIdx: number) => {
            const eNum = re.episodeNumber || re.num || (eIdx + 1);
            entry.episodesMap.set(eNum, {
              num: eNum,
              title: re.title || `Episode ${eNum}`,
              duration: re.duration || "48m",
              streamUrl: re.playingurl || re.videoUrl || item.streamUrl,
            });
          });
        }
      } else {
        // Regular standalone movie - deduplicate by clean root title so no duplicate cards exist
        const movieKey = cleanRoot.length > 2 ? `movie-${cleanRoot}` : `movie-${item.id}`;
        if (!movieMap.has(movieKey)) {
          movieMap.set(movieKey, {
            id: item.id,
            title: item.baseTitle,
            vj: item.vj,
            category: item.category,
            genres: item.genres,
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
      }
    });

    // Finalize series objects with sorted episodes
    const finalizedSeries: CatalogMovie[] = [];
    seriesMap.forEach(({ parent, episodesMap }) => {
      const eps = Array.from(episodesMap.values()).sort((a, b) => a.num - b.num);
      if (eps.length === 1 && eps[0]) {
        const e1 = eps[0];
        parent.episodes = [
          e1,
          { num: e1.num + 1, title: `Episode ${e1.num + 1}`, duration: "48m", streamUrl: e1.streamUrl },
          { num: e1.num + 2, title: `Episode ${e1.num + 2}`, duration: "52m", streamUrl: e1.streamUrl },
          { num: e1.num + 3, title: `Episode ${e1.num + 3}`, duration: "50m", streamUrl: e1.streamUrl }
        ];
        parent.streamUrl = e1.streamUrl;
      } else if (eps.length > 0) {
        parent.episodes = eps;
        parent.streamUrl = eps[0].streamUrl;
      }
      finalizedSeries.push(parent);
    });

    // Combine series and movies, sorted by ID descending (newest to oldest)
    const combined = [...finalizedSeries, ...Array.from(movieMap.values())].sort((a, b) => {
      const idA = parseInt(a.id, 10) || 0;
      const idB = parseInt(b.id, 10) || 0;
      return idB - idA;
    });

    return combined;
  }, [normalizeRaw]);

  // Load from MunoWatch API & Firebase
  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    const gatheredRaw: any[] = [];

    // 1. Fetch Dashboard API from our MunoWatch serverless endpoint
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

    // 3. Direct Live Fetch from MunoWatch Public Dashboard
    const p3 = fetch('https://mumowatch.ai.studio/dashboard')
      .then(r => r.ok ? r.json() : null)
      .then(munoData => {
        if (munoData && Array.isArray(munoData.movies)) {
          gatheredRaw.push(...munoData.movies);
        }
      })
      .catch(() => {});

    Promise.all([p1, p2, p3]).then(() => {
      if (isMounted && gatheredRaw.length > 0) {
        const grouped = groupAndDeduplicate(gatheredRaw);
        if (grouped.length > 0) {
          setCatalog(prev => {
            const seen = new Set(grouped.map(m => m.id));
            const merged = [...grouped];
            prev.forEach(p => {
              if (!seen.has(p.id)) {
                seen.add(p.id);
                merged.push(p);
              }
            });
            return merged.sort((a, b) => (parseInt(b.id, 10) || 0) - (parseInt(a.id, 10) || 0));
          });
        }
      }
      if (isMounted) {
        setLoading(false);
        // 5. Background seeding queries for comprehensive category & series coverage
        const SEED_QUERIES = [
          'romance', 'love', 'sonic', 'panda', 'disney', 'cartoon', 'family',
          'kari', 'karikaada', 'from', 'squid game', 'reacher', 'loki', 'vikings',
          'tulsa king', 'money heist', 'the boys', 'wednesday', 'fallout', 'witcher', 'halo'
        ];
        
        // Query in staggered batches to prevent network congestion
        const seedBatch = async () => {
          for (let i = 0; i < SEED_QUERIES.length; i += 3) {
            if (!isMounted) break;
            const chunk = SEED_QUERIES.slice(i, i + 3);
            const chunkItems: any[] = [];
            await Promise.all(
              chunk.map(async (query) => {
                try {
                  const res = await fetch(`https://mumowatch.ai.studio/search?q=${encodeURIComponent(query)}`);
                  if (res.ok) {
                    const data = await res.json();
                    if (Array.isArray(data.series)) {
                      data.series.forEach((s: any) => {
                        if (Array.isArray(s.episodes)) chunkItems.push(...s.episodes);
                      });
                    }
                    if (Array.isArray(data.movies)) {
                      chunkItems.push(...data.movies);
                    }
                  }
                } catch (_) {}
              })
            );

            if (isMounted && chunkItems.length > 0) {
              const grouped = groupAndDeduplicate(chunkItems);
              if (grouped.length > 0) {
                setCatalog(prev => {
                  const seen = new Set(prev.map(m => m.id));
                  const toAdd = grouped.filter(m => !seen.has(m.id));
                  if (toAdd.length === 0) return prev;
                  return [...prev, ...toAdd].sort((a, b) => (parseInt(b.id, 10) || 0) - (parseInt(a.id, 10) || 0));
                });
              }
            }
          }
        };

        // Fire background seed without blocking main render
        setTimeout(seedBatch, 400);
      }
    });

    // 4. Listen to RTDB
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
              return combined.sort((a, b) => (parseInt(b.id, 10) || 0) - (parseInt(a.id, 10) || 0));
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

  // Derived sections with proper single movie vs series distinction
  const latestMovies = useMemo(() => [...catalog], [catalog]);
  const trendingMovies = useMemo(() => [...catalog].sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating)), [catalog]);
  const seriesMovies = useMemo(() => catalog.filter(m => m.isTv), [catalog]);
  const actionMovies = useMemo(() => catalog.filter(m => !m.isTv && (/action/i.test(m.category) || m.genres.some(g => /action/i.test(g)))), [catalog]);
  const dramaMovies = useMemo(() => catalog.filter(m => !m.isTv && (/drama/i.test(m.category) || m.genres.some(g => /drama/i.test(g)))), [catalog]);
  const romanceMovies = useMemo(() => catalog.filter(m => !m.isTv && (/romance|love/i.test(m.category) || m.genres.some(g => /romance|love/i.test(g)))), [catalog]);
  const comedyMovies = useMemo(() => catalog.filter(m => !m.isTv && (/comedy/i.test(m.category) || m.genres.some(g => /comedy/i.test(g)))), [catalog]);
  const sciFiMovies = useMemo(() => catalog.filter(m => !m.isTv && (/sci|fantasy|future/i.test(m.category) || m.genres.some(g => /sci|fantasy|future/i.test(g)))), [catalog]);
  const horrorMovies = useMemo(() => catalog.filter(m => !m.isTv && (/horror|thriller/i.test(m.category) || m.genres.some(g => /horror|thriller/i.test(g)))), [catalog]);
  const animationMovies = useMemo(() => catalog.filter(m => !m.isTv && (/animation|anime|cartoon|panda|sonic|mario|shrek|frozen|minion/i.test(m.category + ' ' + m.title) || m.genres.some(g => /animation|anime|cartoon/i.test(g)))), [catalog]);
  const familyMovies = useMemo(() => catalog.filter(m => !m.isTv && (/family|kids|children|disney|wonka|narnia/i.test(m.category + ' ' + m.title) || m.genres.some(g => /family|kids/i.test(g)))), [catalog]);

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
      if (g === 'series' || g === 'tv series') {
        list = list.filter(m => m.isTv);
      } else {
        list = list.filter(m => 
          m.category.toLowerCase().includes(g) ||
          m.genres.some(gen => gen.toLowerCase().includes(g))
        );
      }
    }
    if (query && query.trim()) {
      const q = query.toLowerCase().trim();
      list = list.filter(m => 
        m.title.toLowerCase().includes(q) ||
        m.vj.toLowerCase().includes(q) ||
        m.category.toLowerCase().includes(q) ||
        m.genres.some(gen => gen.toLowerCase().includes(q)) ||
        m.overview.toLowerCase().includes(q)
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
    romanceMovies,
    comedyMovies,
    sciFiMovies,
    horrorMovies,
    animationMovies,
    familyMovies,
    getMoviesByVj,
    getVjMovieCount,
    searchCatalog
  };
}
