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
    id: "67492",
    title: "Rise of the Footsoldier: Retribution",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/NgMI8697.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/NgMI8697.jpg",
    rating: "9.2",
    year: "2025",
    duration: "1h 44m",
    isTv: false,
    overview: "Pat Tate travels to Ibiza, Spain to seek revenge and track down criminals who murdered his friend. Luganda translation by VJ Junior.",
    streamUrl: "http://munotech2.b-cdn.net/subaru/subaru42/Rise of The Footsoldier Retribution.mp4"
  },
  {
    id: "67469",
    title: "The Sheriffs Of Savage Wells",
    vj: "VJ Muba",
    category: "Action",
    genres: ["Action", "Western", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    rating: "8.9",
    year: "2025",
    duration: "1h 38m",
    isTv: false,
    overview: "A gripping western standoff between lawmen and ruthless outlaws in Savage Wells. Spiced up by VJ Muba.",
    streamUrl: "http://munotech3.b-cdn.net/mbaata/mbaata21/The.Sheriffs.Of.Savage.Wells..mp4"
  },
  {
    id: "67468",
    title: "Ghost in the Cell",
    vj: "VJ Muba",
    category: "Horror",
    genres: ["Horror", "Mystery", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    rating: "8.8",
    year: "2026",
    duration: "1h 40m",
    isTv: false,
    overview: "Chilling supernatural entities terrorize inmates trapped in an abandoned high-security penitentiary. Translated by VJ Muba.",
    streamUrl: "http://munotech3.b-cdn.net/mbaata/mbaata21/Ghost.In.The.Cell.2026.mp4"
  },
  {
    id: "67467",
    title: "Kill Will",
    vj: "VJ Muba",
    category: "Action",
    genres: ["Action", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg",
    rating: "8.7",
    year: "2026",
    duration: "1h 45m",
    isTv: false,
    overview: "A high-stakes manhunt turns into a deadly game of survival when an operative turns against his syndicate. Spiced up by VJ Muba.",
    streamUrl: "http://yuti.b-cdn.net/kafulaano/kafulaano42/Kill.Will.2026.mp4"
  },
  {
    id: "67465",
    title: "Theri",
    vj: "VJ Muba",
    category: "Action",
    genres: ["Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://image.tmdb.org/t/p/w500/8gVwE6xMkWZf7y7xQzXf3l4h7qV.jpg",
    backdropUrl: "https://image.tmdb.org/t/p/w1280/8gVwE6xMkWZf7y7xQzXf3l4h7qV.jpg",
    rating: "9.1",
    year: "2025",
    duration: "2h 15m",
    isTv: false,
    overview: "An honest cop goes into hiding to protect his daughter, but his dark past catches up to him. Translated by VJ Muba.",
    streamUrl: "http://yuti.b-cdn.net/kafulaano/kafulaano42/Theri Part 1-nycetv.mp4"
  },
  {
    id: "67437",
    title: "Verity",
    vj: "VJ Junior",
    category: "Drama",
    genres: ["Drama", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    rating: "9.0",
    year: "2025",
    duration: "1h 50m",
    isTv: false,
    overview: "A struggling writer uncovers shocking secrets while completing the manuscripts of an injured author. Translated by VJ Junior.",
    streamUrl: "http://nkuba.b-cdn.net/cleve48/cfr/Verity.mp4"
  },
  {
    id: "67436",
    title: "Drive - The Pretenders",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    rating: "8.9",
    year: "2025",
    duration: "1h 48m",
    isTv: false,
    overview: "Adrenaline-fueled underground getaway racing with lethal stakes. Spiced up by VJ Junior.",
    streamUrl: "http://harvetz.b-cdn.net/hvt43/kai43/Drive The Pretender.mp4"
  },
  {
    id: "67435",
    title: "The Cycle",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    rating: "8.8",
    year: "2025",
    duration: "1h 42m",
    isTv: false,
    overview: "Trapped in an inescapable temporal loop, an investigator must uncover the conspirators before time resets. Translated by VJ Junior.",
    streamUrl: "http://munotek-vault.b-cdn.net/stw42/fya/The Cycle.mp4"
  },
  {
    id: "67433",
    title: "Zero",
    vj: "VJ Soul",
    category: "Action",
    genres: ["Action", "Sci-Fi", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    rating: "8.7",
    year: "2025",
    duration: "1h 46m",
    isTv: false,
    overview: "A rogue operative with nothing left to lose takes on a global syndicate. Luganda voice-over by VJ Soul.",
    streamUrl: "http://harvetz.b-cdn.net/hvt43/kai43/ZERO-.SOUL.mp4"
  },
  {
    id: "67432",
    title: "72 Hours",
    vj: "VJ Soul",
    category: "Action",
    genres: ["Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/YaVQ3808.jpg",
    rating: "8.6",
    year: "2025",
    duration: "1h 39m",
    isTv: false,
    overview: "A frantic countdown to deliver the ransom before midnight. Voice-over by VJ Soul.",
    streamUrl: "http://harvetz.b-cdn.net/hvt43/kai43/72 HOURS-.SOUL.mp4"
  },
  {
    id: "67431",
    title: "Tad and the Magic Lamp",
    vj: "VJ Mosco",
    category: "Animation",
    genres: ["Animation", "Family", "Adventure", "Luganda Dubbed"],
    imageUrl: "https://image.tmdb.org/t/p/w500/jhWbYepehTkr7usT5b1Zz8iB84h.jpg",
    backdropUrl: "https://image.tmdb.org/t/p/w1280/jhWbYepehTkr7usT5b1Zz8iB84h.jpg",
    rating: "8.8",
    year: "2025",
    duration: "1h 32m",
    isTv: false,
    overview: "Clumsy explorer Tad unleashes ancient magic that sends him across the world. Translated by VJ Mosco.",
    streamUrl: "http://lunoluno.b-cdn.net/timo28/tyu/TAD AND THE MAGIC LAMP VJ MOSCO.mp4"
  },
  {
    id: "67430",
    title: "PAW Patrol: The Dino Movie",
    vj: "VJ Mosco",
    category: "Animation",
    genres: ["Animation", "Family", "Kids", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/Ta4l2009.jpg",
    rating: "8.9",
    year: "2025",
    duration: "1h 28m",
    isTv: false,
    overview: "Ryder and the pups head to Dino Wilds for an epic rescue mission. Translated by VJ Mosco.",
    streamUrl: "http://lunoluno.b-cdn.net/timo28/tyu/PAW PATROL THE DINO MOVIE VJ MOSCO.mp4"
  },
  {
    id: "67099",
    title: "Accused",
    vj: "VJ Emmy",
    category: "Action",
    genres: ["Action", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    rating: "8.9",
    year: "2024",
    duration: "1h 45m",
    isTv: false,
    overview: "Wrongfully accused of murdering his best friend, church minister Benson is finally released when the truth comes to light. But freedom brings no peace. Translated by VJ Emmy.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/Accused.2026.EMMY.1080.mp4"
  },
  {
    id: "67098",
    title: "Kifeesi",
    vj: "VJ Emmy",
    category: "Action",
    genres: ["Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    rating: "8.8",
    year: "2024",
    duration: "1h 35m",
    isTv: false,
    overview: "A ruthless underworld crime syndicate battles for dominance on the streets of Kampala. Translated by VJ Emmy.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/KIFEESI FINAL MOVIE-720 MP4 BY JAMES.mp4"
  },
  {
    id: "67097",
    title: "Nyoko: The Terrible Mother",
    vj: "VJ Junior",
    category: "Drama",
    genres: ["Drama", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8Md4897.jpg",
    rating: "8.6",
    year: "2024",
    duration: "1h 38m",
    isTv: false,
    overview: "A heartbreaking family conflict tests the limits of love and betrayal. Translated with Luganda narration.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/NYOKO THE TERRIBLE MOM SOUND.mp4"
  },
  {
    id: "67096",
    title: "Nabinene",
    vj: "VJ Junior",
    category: "Drama",
    genres: ["Drama", "Romance", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/SbSf9164.jpg",
    rating: "8.5",
    year: "2024",
    duration: "1h 42m",
    isTv: false,
    overview: "Dramatic tensions rise in a small village as deep-rooted secrets come to the surface. Luganda dubbed.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/NABINENE.mp4"
  },
  {
    id: "67095",
    title: "The Visit",
    vj: "VJ Emmy",
    category: "Horror",
    genres: ["Horror", "Mystery", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    rating: "8.7",
    year: "2024",
    duration: "1h 34m",
    isTv: false,
    overview: "A sister and brother are sent to their grandparents' remote Pennsylvania farm for a week trip, only to discover disturbing secrets. Voice-over by VJ Emmy.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/THE VISIT VJ EMMY.mp4"
  },
  {
    id: "67364",
    title: "Animals",
    vj: "VJ Junior",
    category: "Action",
    genres: ["Action", "Crime", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/bFX49260.jpg",
    rating: "9.1",
    year: "2025",
    duration: "2h 05m",
    isTv: false,
    overview: "Desperate to pay their son's ransom, parents embark on a dangerous and relentless rescue mission. Luganda translation by VJ Junior.",
    streamUrl: "http://lunoluno.b-cdn.net/timo28/tyu/Animals.mp4"
  },
  {
    id: "67463",
    title: "Just Say It: Alex Muhangi",
    vj: "VJ Junior",
    category: "Comedy",
    genres: ["Comedy", "Drama", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/gqxM7384.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/gqxM7384.jpg",
    rating: "8.8",
    year: "2025",
    duration: "1h 27m",
    isTv: false,
    overview: "Alex Muhangi opens up about his journey, comedy revolution, and untold stories from Uganda's entertainment industry.",
    streamUrl: "http://munotek-vault.b-cdn.net/ugmvs/ug2/AlexMuhanji_final.mp4"
  },
  {
    id: "67421",
    title: "Mirzapur",
    vj: "VJ Ashim",
    category: "Series",
    genres: ["Series", "Action", "Crime", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/gNxs2151.jpg",
    backdropUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80",
    rating: "9.3",
    year: "2025",
    duration: "50m",
    isTv: true,
    seriesCode: "33624",
    overview: "A shocking incident at a wedding procession ignites a series of events entangling two families in the lawless city of Mirzapur. Spiced up by VJ Ashim.",
    streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4",
    episodes: [
      { num: 1, title: "Episode 1", duration: "50m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/01.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 2, title: "Episode 2", duration: "48m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/02.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 3, title: "Episode 3", duration: "52m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/03.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 4, title: "Episode 4", duration: "51m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/04.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 5, title: "Episode 5", duration: "49m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/05.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 6, title: "Episode 6", duration: "53m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/06.Mirzapur.SN1.VJ.Ashim.1080.mp4" },
      { num: 7, title: "Episode 7", duration: "50m", streamUrl: "http://munotech3.b-cdn.net/gugwa/gugwa42/07.Mirzapur.SN2.VJ.Ashim.1080.mp4" }
    ]
  },
  {
    id: "28629",
    title: "Yemin",
    vj: "VJ Mox",
    category: "Series",
    genres: ["Series", "Romance", "Drama", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/Rf5j3JMy122965.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/Rf5j3JMy122965.jpg",
    rating: "9.2",
    year: "2024",
    duration: "45m",
    isTv: true,
    seriesCode: "46481",
    overview: "Reyhan was born in the countryside; is a modest, young and beautiful girl who grew up in traditional style. Reyhan remains an orphan after her mother's death, and her life changes unexpectedly. Voice-over by VJ Mox.",
    streamUrl: "http://munotek-vault.b-cdn.net/67gh/17b/Yemin - Episode 1.mp4",
    episodes: [
      { num: 1, title: "Yemin Episode 1", duration: "45m", streamUrl: "http://munotek-vault.b-cdn.net/67gh/17b/Yemin - Episode 1.mp4" },
      { num: 2, title: "Yemin Episode 2", duration: "45m", streamUrl: "http://munotek-vault.b-cdn.net/67gh/17b/Yemin - Episode 2.mp4" }
    ]
  },
  {
    id: "57029",
    title: "The Holiday",
    vj: "VJ Junior",
    category: "Romance",
    genres: ["Romance", "Comedy", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/X5n9b72PPD1298.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/X5n9b72PPD1298.jpg",
    rating: "8.8",
    year: "2024",
    duration: "2h 15m",
    isTv: false,
    overview: "Two women troubled with guy problems swap homes in countries other than their own, where they each meet a local man and fall in love. Spiced up by VJ Junior.",
    streamUrl: "https://munotech2.b-cdn.net/simo/simo22/THE%20HOLIDAY.JR.mp4"
  },
  {
    id: "55898",
    title: "Bonhoeffer: Pastor. Spy. Assassin.",
    vj: "VJ Ulio",
    category: "Drama",
    genres: ["Drama", "History", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/9W0KmHEJfb9949.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/9W0KmHEJfb9949.jpg",
    rating: "9.1",
    year: "2025",
    duration: "2h 10m",
    isTv: false,
    overview: "As the Nazi regime commits atrocities, pastor and theologian Dietrich Bonhoeffer decides to stand up and join the resistance. Translated by VJ Ulio.",
    streamUrl: "https://munotech3.b-cdn.net/klpp43/jgn43/BONHOEFFER%20HD.2025%20VJ.ULIO.mp4"
  },
  {
    id: "29447",
    title: "Rogue Agent",
    vj: "VJ Muba",
    category: "Action",
    genres: ["Action", "Thriller", "Luganda Dubbed"],
    imageUrl: "https://image.tmdb.org/t/p/w500/628Dep6AxEtDxjZoGP78TsOxYbK.jpg",
    backdropUrl: "https://image.tmdb.org/t/p/w1280/628Dep6AxEtDxjZoGP78TsOxYbK.jpg",
    rating: "8.7",
    year: "2024",
    duration: "1h 55m",
    isTv: false,
    overview: "The chilling true story of conman Robert Freegard, who posed as an undercover MI5 agent. Luganda translation by VJ Muba.",
    streamUrl: "https://munotech2.b-cdn.net/rus1/553/Rogue.Agent.mp4"
  },
  {
    id: "1531",
    title: "Damage",
    vj: "VJ Junior",
    category: "Drama",
    genres: ["Drama", "Romance", "Luganda Dubbed"],
    imageUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8c3.jpg",
    backdropUrl: "https://apposters.b-cdn.net/laba/yo/naki/a8c3.jpg",
    rating: "8.6",
    year: "2024",
    duration: "1h 51m",
    isTv: false,
    overview: "A respected member of Parliament falls passionately into an obsession that threatens to dismantle his life. Spiced up by VJ Junior.",
    streamUrl: "https://munotek-vault.b-cdn.net/bec43/flv43/Damage.1992.1080p%20JR.mp4"
  }
];

export const KNOWN_ID_MAP: Record<string, { title: string; vj: string; streamUrl?: string; image?: string }> = {
  "57029": { title: "The Holiday", vj: "VJ Junior", streamUrl: "https://munotech2.b-cdn.net/simo/simo22/THE%20HOLIDAY.JR.mp4", image: "https://apposters.b-cdn.net/laba/yo/naki/X5n9b72PPD1298.jpg" },
  "55898": { title: "Bonhoeffer: Pastor. Spy. Assassin.", vj: "VJ Ulio", streamUrl: "https://munotech3.b-cdn.net/klpp43/jgn43/BONHOEFFER%20HD.2025%20VJ.ULIO.mp4", image: "https://apposters.b-cdn.net/laba/yo/naki/9W0KmHEJfb9949.jpg" },
  "39003": { title: "Alex & Eve", vj: "VJ Junior", streamUrl: "https://nkuba.b-cdn.net/cleve48/cfr/AlexandEve.mp4" },
  "29447": { title: "Rogue Agent", vj: "VJ Muba", streamUrl: "https://munotech2.b-cdn.net/rus1/553/Rogue.Agent.mp4" },
  "9692": { title: "The Photograph", vj: "VJ Junior", streamUrl: "https://munoserver12.co/915af/79d/0b40d~22.mp4" },
  "2390": { title: "The Glimmer Man", vj: "VJ Tom", streamUrl: "https://munotech2.b-cdn.net/ca709/215/glimmar%20man%20tom.mp4" },
  "1531": { title: "Damage", vj: "VJ Junior", streamUrl: "https://munotek-vault.b-cdn.net/bec43/flv43/Damage.1992.1080p%20JR.mp4", image: "https://apposters.b-cdn.net/laba/yo/naki/a8c3.jpg" },
};

export function cleanTitleFromUrlOrId(
  id: string,
  rawTitle: string,
  streamUrl: string = "",
  vj: string = ""
): { title: string; vj: string; streamUrl: string } {
  let title = (rawTitle || "").trim();
  let cleanVj = vj;
  let finalStream = streamUrl;

  const isPlaceholder =
    !title ||
    /^(?:Movie|Series|Luganda Release)\s*#?(\d+)/i.test(title) ||
    /^(?:untitled|null|none|undefined)/i.test(title);

  if (KNOWN_ID_MAP[id]) {
    const k = KNOWN_ID_MAP[id];
    title = k.title;
    if (k.vj) cleanVj = k.vj;
    if (k.streamUrl && (!finalStream || finalStream.includes("sample"))) finalStream = k.streamUrl;
    return { title, vj: cleanVj, streamUrl: finalStream };
  }

  if (isPlaceholder && streamUrl) {
    // If stream URL is a generic fallback, do NOT parse it into the title for unrelated movies
    if ((streamUrl.includes("07.Mirzapur") || streamUrl.includes("sample")) && id !== "67406") {
      return { title, vj: cleanVj, streamUrl: finalStream };
    }
    try {
      const decoded = decodeURIComponent(streamUrl.split("?")[0]);
      const filename = decoded.substring(decoded.lastIndexOf("/") + 1);
      if (filename && filename.includes(".")) {
        let cleanName = filename.substring(0, filename.lastIndexOf("."));

        if (/vj[.\s_-]*([a-z0-9]+)/i.test(cleanName)) {
          const vjMatch = cleanName.match(/vj[.\s_-]*([a-z0-9]+)/i);
          if (vjMatch && vjMatch[1]) {
            cleanVj = `VJ ${vjMatch[1].charAt(0).toUpperCase() + vjMatch[1].slice(1).toLowerCase()}`;
          }
        } else if (/\bJR\b/i.test(cleanName)) {
          cleanVj = "VJ Junior";
        }

        cleanName = cleanName
          .replace(/\[.*?\]|\(.*?\)/g, "")
          .replace(/\b(?:1080p?|720p?|480p?|4k|uhd|hd|bluray|web-?dl|dvdrip|rip)\b/gi, "")
          .replace(/\b(?:vj[.\s_-]*[a-z0-9]+|jr|tom|emmy|junior|jingo|ice\s*p|mark|muba|ulio)\b/gi, "")
          .replace(/\b(?:19\d\d|20\d\d)\b/g, "")
          .replace(/[._-]+/g, " ")
          .replace(/\s+/g, " ")
          .trim();

        if (cleanName.length > 2 && !/^\d+$/.test(cleanName)) {
          title = cleanName.charAt(0).toUpperCase() + cleanName.slice(1);
          return { title, vj: cleanVj, streamUrl: finalStream };
        }
      }
    } catch (_) {}
  }

  return { title, vj: cleanVj, streamUrl: finalStream };
}
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
  if (/animation|anime|cartoon|panda|sonic|mario|shrek|frozen|minion|moana|inside\s*out|puss|lion\s*king|toy\s*story|dragon|zootopia|madagascar/i.test(t)) return 'Animation';
  if (/alien|space|future|galaxy|cyber|robot|matrix|planet|superhero|marvel|avatar|star\s*wars/i.test(t)) return 'Sci-Fi';
  if (/horror|dead|kill|blood|ghost|evil|monster|zombie|haunt|demon|devil|slasher|curse|fear/i.test(t)) return 'Horror';
  if (/love|heart|romance|kiss|wedding|passion|forever|lover/i.test(t)) return 'Romance';
  if (/laugh|funny|comedy|joke|fun|fool|stupid/i.test(t)) return 'Comedy';
  if (/drama|life|story|tear|struggle|family|mother|father|crime|truth/i.test(t)) return 'Drama';

  return 'Action';
}

// Helper: parse series base title and episode number
export function parseSeriesEpisodeInfo(
  rawTitle: string,
  isSeriesContext: boolean = false
): {
  isEpisode: boolean;
  baseTitle: string;
  epNum: number;
} {
  const clean = (rawTitle || '').trim();

  // Pattern A: Title S01E16, Title Season 2: Episode 2, Title S1 Ep 16
  const sPattern = /^(.*?)[.\s_:|,-]+(?:s|season)\s*(\d+)[.\s_:|,-]*(?:e|ep|episode)\s*(\d+)(.*)$/i;
  let match = clean.match(sPattern);
  if (match) {
    return {
      isEpisode: true,
      baseTitle: match[1].trim(),
      epNum: parseInt(match[3], 10) || 1,
    };
  }

  // Pattern B: Title Episode 16, Title Ep 16, Part 16, EPS 16
  const epPattern = /^(.*?)[.\s_:|,-]+(?:episode|ep|eps|part|pt)\s*(\d+)(.*)$/i;
  match = clean.match(epPattern);
  if (match) {
    return {
      isEpisode: true,
      baseTitle: match[1].trim(),
      epNum: parseInt(match[2], 10) || 1,
    };
  }

  // Pattern C: Trailing number like "Mirzapur 16", "Yemin 402", "Omuzigo 30"
  const trailingNumPattern = /^(.*?)[.\s_:|,-]+(\d{1,4})$/;
  match = clean.match(trailingNumPattern);
  if (match) {
    const candidateBase = match[1].trim();
    const num = parseInt(match[2], 10);
    const isKnownSeries = /^(?:mirzapur|yemin|living\s*for\s*love|squid\s*game|from|reacher|terminal\s*list|loki|vikings|tulsa\s*king|money\s*heist|the\s*boys|wednesday|fallout|witcher|halo|karikaada|the\s*hobbit|mobland|omuzigo|the\s*hope)/i.test(candidateBase);
    if (isSeriesContext || num > 4 || isKnownSeries) {
      return {
        isEpisode: true,
        baseTitle: candidateBase,
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

// Background healing cache & queue for unresolved Movie #... items
const healingCache = new Map<string, { title: string; vj: string; streamUrl: string; image?: string; duration?: string; overview?: string }>();
const pendingHealingIds = new Set<string>();

export function enqueueMovieHealing(
  id: string,
  onHealed?: (healed: { id: string; title: string; vj: string; streamUrl: string; image?: string; duration?: string; overview?: string }) => void
) {
  if (!id || !/^\d+$/.test(id) || pendingHealingIds.has(id)) return;
  if (healingCache.has(id)) {
    onHealed?.(healingCache.get(id)!);
    return;
  }
  pendingHealingIds.add(id);

  setTimeout(async () => {
    try {
      const res = await fetch(`https://mumowatch.ai.studio/movie/${id}`);
      if (res.ok) {
        const d = await res.json();
        if (d && d.title && !/^(?:Movie|Series)\s*#/i.test(d.title)) {
          const rawVj = (d.vj || "").trim();
          const isUniv = !rawVj || rawVj.toLowerCase().includes("universal");
          const finalVj = isUniv ? "VJ Junior" : (rawVj.toUpperCase().startsWith("VJ") ? rawVj : `VJ ${rawVj}`);
          const healed = {
            id: String(id),
            title: d.title.trim(),
            vj: finalVj,
            streamUrl: d.playingurl || "",
            image: d.image || "",
            duration: d.duration || "",
            overview: d.description || "",
          };
          healingCache.set(id, healed);
          onHealed?.(healed);
        }
      }
    } catch (_) {
    } finally {
      pendingHealingIds.delete(id);
    }
  }, 100);
}

export function useLiveCatalog() {
  const [catalog, setCatalog] = useState<CatalogMovie[]>(FALLBACK_MOVIES);
  const [munoLatestList, setMunoLatestList] = useState<CatalogMovie[]>([]);
  const [totalCount, setTotalCount] = useState<number>(7097);
  const [loading, setLoading] = useState<boolean>(false);

  const handleMovieHealed = useCallback((healed: { id: string; title: string; vj: string; streamUrl: string; image?: string; duration?: string; overview?: string }) => {
    setCatalog((prev) =>
      prev.map((m) => {
        if (m.id === healed.id) {
          return {
            ...m,
            title: healed.title,
            vj: healed.vj || m.vj,
            streamUrl: healed.streamUrl || m.streamUrl,
            imageUrl: healed.image || m.imageUrl,
            duration: healed.duration || m.duration,
            overview: healed.overview || m.overview,
          };
        }
        return m;
      })
    );
  }, []);

  // Raw normalizer for an individual movie or episode
  const normalizeRaw = useCallback((m: any, idx: number) => {
    const itemId = String(m.id || m.vid || `fw-${idx}`);
    let streamUrl = m.playingurl || m.playingUrl || m.videoUrl || m.streamUrl || '';
    let rawTitle = (m.title || m.video_title || m.name || 'Untitled Movie').trim();
    let rawVj = (m.vj || m.vjname || m.vjName || '').trim();
    let isUniversal = rawVj.toLowerCase().includes('universal') || !rawVj;
    let vj = isUniversal ? 'VJ Junior' : (rawVj.toUpperCase().startsWith('VJ') ? rawVj : `VJ ${rawVj}`);

    // Decode authentic title from URL, known map, or filename
    const cleaned = cleanTitleFromUrlOrId(itemId, rawTitle, streamUrl, vj);
    rawTitle = cleaned.title;
    vj = cleaned.vj;
    streamUrl = cleaned.streamUrl;

    // If still a placeholder, queue background healing
    if (/^(?:Movie|Series|Luganda Release)\s*#?(\d+)/i.test(rawTitle) || !rawTitle) {
      enqueueMovieHealing(itemId, handleMovieHealed);
    }
    
    const seriesCode = m.series_code || m.seriesCode || '';
    const isSeriesCat = Number(m.category_id || m.categoryId) === 5 || (typeof m.category === 'string' && m.category.toLowerCase().trim() === 'series');
    const isSeriesType = Boolean(m.type && String(m.type).toUpperCase() === 'SERIES');
    const isExplicitSeries = isSeriesCat || isSeriesType || Boolean(m.is_series && String(m.is_series).toLowerCase() !== 'no');

    // In MunoWatch, single movies frequently have series_code equal to their own id,
    // and dummy is_series: true. A genuine series code MUST be distinct from the movie's own id!
    const hasDistinctSeriesCode = Boolean(
      seriesCode &&
      String(seriesCode).trim().length > 0 &&
      String(seriesCode) !== '0' &&
      String(seriesCode) !== String(itemId)
    );

    const episodeInfo = parseSeriesEpisodeInfo(rawTitle, isExplicitSeries || hasDistinctSeriesCode);
    const hasEpisodes = Array.isArray(m.episodes) && m.episodes.length > 1;
    const hasExplicitSeasonOrEp = episodeInfo.isEpisode || /\b(?:s\d{1,2}e\d{1,2}|season\s*\d+\s*(?:ep|episode)\s*\d+)\b/i.test(rawTitle);

    // Strict TV Series determination:
    // A title is ONLY a TV series if it has a distinct seriesCode, has multiple episodes (> 1),
    // is in the Series category (category_id === 5) with episode numbering, or has explicit S01E02 numbering.
    const isTv = Boolean(
      (hasDistinctSeriesCode && hasEpisodes) ||
      hasEpisodes ||
      (isSeriesCat && (hasExplicitSeasonOrEp || (hasDistinctSeriesCode && hasEpisodes) || isSeriesType)) ||
      (episodeInfo.isEpisode && (isExplicitSeries || hasDistinctSeriesCode))
    );

    // Accurate category mapping
    const category = isTv ? 'Series' : mapMunoCategoryId(m.category_id || m.categoryId, m.category, episodeInfo.baseTitle);
    const genres = [category, 'Luganda Dubbed'];
    if (isTv && !genres.includes('Series')) genres.unshift('Series');

    const duration = m.duration || (isTv ? '50m' : '1h 45m');

    const resolvedImage = m.imageUrl || m.image || m.thumbnail || m.poster || m.poster_path || '';
    const resolvedBackdrop = m.backdropUrl || m.backdrop || m.backdrop_path || m.cover || resolvedImage || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1600&auto=format&fit=crop&q=80';

    return {
      id: itemId,
      rawTitle,
      baseTitle: episodeInfo.isEpisode ? episodeInfo.baseTitle : rawTitle,
      isEpisode: episodeInfo.isEpisode,
      epNum: episodeInfo.epNum,
      vj,
      category,
      genres,
      imageUrl: resolvedImage || 'https://apposters.b-cdn.net/laba/yo/naki/01d9.jpg',
      backdropUrl: resolvedBackdrop,
      rating: String(m.rating || (8.5 + ((idx % 12) / 10)).toFixed(1)),
      year: String(m.year || m.release_year || '2025'),
      duration,
      isTv,
      seriesCode,
      overview: m.overview || m.synopsis || m.description || `Enjoy ${episodeInfo.baseTitle} in high definition with exclusive Luganda voice-over translation by ${vj}.`,
      streamUrl,
      rawEpisodes: isTv && Array.isArray(m.episodes) ? m.episodes : [],
    };
  }, [handleMovieHealed]);

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

        // Add episode: prioritize valid epNum, fallback to next sequential number
        const resolvedEpNum = item.epNum > 0 ? item.epNum : (entry.episodesMap.size + 1);
        if (!entry.episodesMap.has(resolvedEpNum) || !entry.episodesMap.get(resolvedEpNum)?.streamUrl) {
          entry.episodesMap.set(resolvedEpNum, {
            num: resolvedEpNum,
            title: `Episode ${resolvedEpNum}`,
            duration: item.duration,
            streamUrl: item.streamUrl,
          });
        }

        // Also incorporate any nested rawEpisodes
        if (item.rawEpisodes && item.rawEpisodes.length > 0) {
          item.rawEpisodes.forEach((re: any) => {
            const eNum = re.episodeNumber || re.num || (entry.episodesMap.size + 1);
            if (!entry.episodesMap.has(eNum) || !entry.episodesMap.get(eNum)?.streamUrl) {
              entry.episodesMap.set(eNum, {
                num: eNum,
                title: re.title || `Episode ${eNum}`,
                duration: re.duration || "48m",
                streamUrl: re.playingurl || re.videoUrl || item.streamUrl,
              });
            }
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
      if (eps.length > 0) {
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
      .then(async munoData => {
        if (munoData && Array.isArray(munoData.movies)) {
          // Immediately batch-resolve the 20 newest releases via /movie/:id
          const topLatestRaw = munoData.movies.slice(0, 20);
          try {
            const enrichedLatest = await Promise.all(
              topLatestRaw.map(async (raw: any, idx: number) => {
                const movieId = raw.id || raw.vid;
                if (!movieId) return normalizeRaw(raw, idx);
                try {
                  const detRes = await fetch(`https://mumowatch.ai.studio/movie/${movieId}`);
                  if (detRes.ok) {
                    const d = await detRes.json();
                    if (d && d.title) {
                      return normalizeRaw({ ...raw, ...d, id: movieId }, idx);
                    }
                  }
                } catch (_) {}
                return normalizeRaw(raw, idx);
              })
            );
            if (isMounted && enrichedLatest.length > 0) {
              const validEnriched = enrichedLatest.filter(
                (m) => m && m.title && !/^(?:Movie|Series)\s*#/i.test(m.title)
              );
              const groupedLatest = groupAndDeduplicate(validEnriched);
              setMunoLatestList(groupedLatest);
              gatheredRaw.push(...validEnriched);
            }
          } catch (_) {
            gatheredRaw.push(...topLatestRaw);
          }
          gatheredRaw.push(...munoData.movies.slice(20));
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
          'horror', 'thriller', 'ghost', 'evil', 'zombie', 'demon', 'conjuring', 'insidious', 'saw', 'halloween', 'quiet place', 'terrif',
          'animation', 'anime', 'cartoon', 'pixar', 'dreamworks', 'disney', 'minions', 'shrek',
          'moana', 'frozen', 'lion king', 'zootopia', 'toy story', 'ice age', 'dragon',
          'kung fu panda', 'spider-verse', 'despicable me', 'madagascar', 'cars', 'incredibles',
          'romance', 'love', 'hobbit', 'the hobbit', 'sonic', 'family',
          'mirzapur', 'yemin', 'kari', 'karikaada', 'from', 'squid game', 'reacher', 'loki', 'vikings',
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
  const latestMovies = useMemo(() => {
    // Only genuine releases with authentic non-sample stream URLs and titles
    const validMuno = munoLatestList.filter(
      (m) => m && m.streamUrl && !m.streamUrl.includes('sample') && m.title && !/^(?:Movie|Series)\s*#/i.test(m.title)
    );
    if (validMuno.length > 0) {
      const seen = new Set(validMuno.map((m) => m.id));
      const rest = catalog.filter((m) => !seen.has(m.id) && m.streamUrl && !m.streamUrl.includes('sample') && m.title && !/^(?:Movie|Series)\s*#/i.test(m.title));
      return groupAndDeduplicate([...validMuno, ...rest]);
    }
    return groupAndDeduplicate(catalog.filter((m) => m.streamUrl && !m.streamUrl.includes('sample') && m.title && !/^(?:Movie|Series)\s*#/i.test(m.title)));
  }, [munoLatestList, catalog, groupAndDeduplicate]);
  const trendingMovies = useMemo(() => [...catalog].sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating)), [catalog]);
  const seriesMovies = useMemo(() => catalog.filter(m => m.isTv), [catalog]);
  const actionMovies = useMemo(() => catalog.filter(m => !m.isTv && (/action/i.test(m.category) || m.genres.some(g => /action/i.test(g)))), [catalog]);
  const dramaMovies = useMemo(() => catalog.filter(m => !m.isTv && (/drama/i.test(m.category) || m.genres.some(g => /drama/i.test(g)))), [catalog]);
  const romanceMovies = useMemo(() => catalog.filter(m => !m.isTv && (/romance|love/i.test(m.category) || m.genres.some(g => /romance|love/i.test(g)))), [catalog]);
  const comedyMovies = useMemo(() => catalog.filter(m => !m.isTv && (/comedy/i.test(m.category) || m.genres.some(g => /comedy/i.test(g)))), [catalog]);
  const sciFiMovies = useMemo(() => catalog.filter(m => !m.isTv && (/sci|fantasy|future/i.test(m.category) || m.genres.some(g => /sci|fantasy|future/i.test(g)))), [catalog]);
  const horrorMovies = useMemo(
    () =>
      catalog.filter(
        (m) =>
          !m.isTv &&
          (/horror|thriller|scary|ghost|blood|dead|evil|monster|zombie|haunt|demon|devil|slasher|curse|fear/i.test(
            m.category + " " + m.title
          ) ||
            m.genres.some((g) => /horror|thriller/i.test(g)))
      ),
    [catalog]
  );
  const animationMovies = useMemo(
    () =>
      catalog.filter(
        (m) =>
          !m.isTv &&
          (/animation|anime|cartoon|panda|sonic|mario|shrek|frozen|minion|robot|moana|inside\s*out|puss/i.test(
            m.category + " " + m.title
          ) ||
            m.genres.some((g) => /animation|anime|cartoon/i.test(g)))
      ),
    [catalog]
  );
  const familyMovies = useMemo(() => {
    const matched = catalog.filter(
      (m) =>
        !m.isTv &&
        (/family|kids|children|disney|wonka|narnia|sonic|panda|moana|despicable|minion|mario|shrek|puss|inside\s*out|robot|lion\s*king/i.test(
          m.category + " " + m.title + " " + m.genres.join(" ")
        ) ||
          m.genres.some((g) => /family|kids/i.test(g)))
    );
    if (matched.length >= 4) return matched;
    // Blend with animation to guarantee rich shelf
    const anim = catalog.filter(
      (m) =>
        !m.isTv &&
        (/animation|anime|cartoon/i.test(m.category) ||
          m.genres.some((g) => /animation/i.test(g)))
    );
    const seen = new Set(matched.map((m) => m.id));
    const combined = [...matched];
    anim.forEach((a) => {
      if (!seen.has(a.id)) {
        seen.add(a.id);
        combined.push(a);
      }
    });
    return combined;
  }, [catalog]);

  const adventureMovies = useMemo(() => {
    const matched = catalog.filter(
      (m) =>
        !m.isTv &&
        (m.category.toLowerCase().includes("adventure") ||
          m.genres.some((g) => g.toLowerCase().includes("adventure")) ||
          /adventure|journey|quest|safari|expedition|jungle|treasure|island|explore|hunter|survival|wild|tomb|lost|sheriff|wells/i.test(
            m.title + " " + m.overview
          ) ||
          (m.category === "Action" && !/romance|love/i.test(m.title)))
    );
    return matched.length > 0 ? matched : catalog.filter((m) => !m.isTv && (m.category === "Action" || m.category === "Sci-Fi"));
  }, [catalog]);

  // VJ filter helper
  const getMoviesByVj = useCallback((vjName: string) => {
    const q = vjName.toLowerCase().replace('vj', '').trim();
    return catalog.filter((m) => {
      const v = m.vj.toLowerCase();
      const t = m.title.toLowerCase();
      const s = (m.streamUrl || '').toLowerCase();
      return (
        v.includes(q) ||
        t.includes(`vj ${q}`) ||
        t.includes(`vj_${q}`) ||
        s.includes(`vj%20${q}`) ||
        s.includes(`vj_${q}`) ||
        s.includes(`.${q}.`) ||
        (q === 'junior' && (s.includes('jr') || t.includes('.jr.')))
      );
    });
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
      const g = genre.toLowerCase().trim();
      if (g === 'series' || g === 'tv series') {
        list = list.filter(m => m.isTv);
      } else if (g === 'love story' || g === 'romance') {
        list = list.filter(m =>
          m.category.toLowerCase().includes('romance') ||
          m.category.toLowerCase().includes('drama') ||
          m.genres.some(gen => /romance|love|drama/i.test(gen)) ||
          /love|romance|heart|wedding|passion/i.test(m.title)
        );
      } else if (g === 'kungu fu' || g === 'kung fu') {
        list = list.filter(m =>
          m.category.toLowerCase().includes('action') ||
          m.genres.some(gen => /action|martial/i.test(gen)) ||
          /kung|fu|shaolin|dragon|master|fist/i.test(m.title)
        );
      } else if (g === 'sci fi' || g === 'sci-fi') {
        list = list.filter(m =>
          m.category.toLowerCase().includes('sci') ||
          m.genres.some(gen => /sci|fiction|fantasy/i.test(gen))
        );
      } else if (g === 'horror') {
        const horrors = list.filter(m => 
          m.category.toLowerCase().includes('horror') ||
          m.genres.some(gen => gen.toLowerCase().includes('horror')) ||
          /horror|evil|ghost|haunt|fear|demon|witch|slasher|zombie|dead|dracula|alien/i.test(m.title + ' ' + m.overview)
        );
        list = horrors.length > 0 ? horrors : list.filter(m => m.category === 'Action' || m.category === 'Drama');
      } else if (g === 'indian') {
        const indianList = list.filter(
          m =>
            m.genres.some(gen => gen.toLowerCase().includes('indian')) ||
            /rrr|k\.?g\.?f|pushpa|jawan|pathaan|kalki|salaar|leo|baahubali|dangal|mirzapur|hindi|bollywood|tollywood|kollywood/i.test(
              m.title + ' ' + m.overview
            )
        );
        list =
          indianList.length > 0
            ? indianList
            : list.filter(
                m =>
                  m.category === 'Action' &&
                  !/^(?:Movie|Series)\s*#/i.test(m.title)
              );
      } else if (g === 'sport') {
        const sports = list.filter(m => 
          m.category.toLowerCase().includes('sport') ||
          m.genres.some(gen => gen.toLowerCase().includes('sport')) ||
          /sport|football|soccer|box|fight|race|run|ball|athlete|creed/i.test(m.title + ' ' + m.overview)
        );
        list = sports.length > 0 ? sports : list.filter(m => m.category === 'Action');
      } else if (g === 'adventure') {
        const advList = list.filter(m =>
          !m.isTv &&
          (m.category.toLowerCase().includes('adventure') ||
           m.genres.some(gen => gen.toLowerCase().includes('adventure')) ||
           /adventure|journey|quest|safari|expedition|jungle|treasure|island|explore|hunter|survival|wild|tomb|lost|sheriff|wells/i.test(m.title + ' ' + m.overview) ||
           (m.category === 'Action' && !/romance|love/i.test(m.title)))
        );
        list = advList.length > 0 ? advList : list.filter(m => !m.isTv && (m.category === 'Action' || m.category === 'Sci-Fi'));
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
    adventureMovies,
    getMoviesByVj,
    getVjMovieCount,
    searchCatalog
  };
}
