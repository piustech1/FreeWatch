export interface AvatarItem {
  id: string;
  name: string;
  imageUrl: string;
  accentColor: string;
}

export const CHARACTER_AVATARS: AvatarItem[] = [
  {
    id: "mirabel",
    name: "Mirabel",
    imageUrl: "/avatars/avatar_mirabel.png",
    accentColor: "#00E676",
  },
  {
    id: "moon-knight",
    name: "Moon Knight",
    imageUrl: "/avatars/avatar_moon_knight.png",
    accentColor: "#94a3b8",
  },
  {
    id: "mei-lee",
    name: "Mei Lee",
    imageUrl: "/avatars/avatar_mei.png",
    accentColor: "#ef4444",
  },
  {
    id: "penny-proud",
    name: "Penny Proud",
    imageUrl: "/avatars/avatar_penny_proud.png",
    accentColor: "#f43f5e",
  },
  {
    id: "grogu",
    name: "Grogu",
    imageUrl: "/avatars/avatar_grogu.png",
    accentColor: "#84cc16",
  },
  {
    id: "boba-fett",
    name: "Boba Fett",
    imageUrl: "/avatars/avatar_boba_fett.png",
    accentColor: "#15803d",
  },
  {
    id: "minnie-mouse",
    name: "Minnie Mouse",
    imageUrl: "/avatars/avatar_minnie.png",
    accentColor: "#ec4899",
  },
  {
    id: "raya",
    name: "Raya",
    imageUrl: "/avatars/avatar_raya.png",
    accentColor: "#d97706",
  },
  {
    id: "tiana",
    name: "Tiana",
    imageUrl: "/avatars/avatar_tiana.png",
    accentColor: "#10b981",
  },
  {
    id: "baymax",
    name: "Baymax",
    imageUrl: "/avatars/avatar_baymax.png",
    accentColor: "#e2e8f0",
  },
  {
    id: "anna",
    name: "Anna",
    imageUrl: "/avatars/avatar_anna.png",
    accentColor: "#8b5cf6",
  },
  {
    id: "mickey-mouse",
    name: "Mickey Mouse",
    imageUrl: "/avatars/avatar_mickey.png",
    accentColor: "#dc2626",
  },
];

export const getAvatarById = (id?: string): AvatarItem => {
  if (!id) return CHARACTER_AVATARS[0];
  const normalized = id.toLowerCase().replace(/_/g, "-");
  return (
    CHARACTER_AVATARS.find(
      (a) =>
        a.id === normalized ||
        a.id.replace(/-/g, "") === normalized.replace(/-/g, "") ||
        normalized.includes(a.id) ||
        a.id.includes(normalized)
    ) || CHARACTER_AVATARS[0]
  );
};
