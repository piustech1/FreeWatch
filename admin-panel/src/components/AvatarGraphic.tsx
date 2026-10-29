import React from "react";
import { getAvatarById } from "../data/avatars";

interface AvatarGraphicProps {
  id: string;
  name?: string;
  className?: string;
}

export const AvatarGraphic: React.FC<AvatarGraphicProps> = ({
  id,
  name,
  className = "w-full h-full",
}) => {
  const avatar = getAvatarById(id);

  return (
    <div
      className={`relative rounded-full overflow-hidden flex items-center justify-center bg-neutral-900 ${className}`}
      style={{
        boxShadow: `0 0 10px ${avatar.accentColor}33`,
      }}
    >
      <img
        src={avatar.imageUrl}
        alt={name || avatar.name}
        onError={(e) => {
          // Fallback to Mirabel if any issue loading
          (e.target as HTMLImageElement).src = "/avatars/avatar_mirabel.png";
        }}
        className="w-full h-full object-cover select-none pointer-events-none"
        loading="lazy"
      />
    </div>
  );
};
