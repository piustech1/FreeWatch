import React, { useState } from "react";
import { Mic } from "lucide-react";
import { ALL_VJS } from "./AvailableVJsPage";

interface VjBadgeProps {
  vjName?: string;
  size?: "sm" | "md";
  className?: string;
}

export const VjBadge: React.FC<VjBadgeProps> = ({ vjName, size = "sm", className = "" }) => {
  const [imgError, setImgError] = useState(false);

  if (!vjName || !vjName.trim()) return null;

  const cleanRaw = vjName.trim();
  const lower = cleanRaw.toLowerCase();

  // Filter out meaningless placeholder names or generic dubbed branding
  if (
    lower === "na" ||
    lower === "n/a" ||
    lower === "null" ||
    lower === "general" ||
    lower === "unknown" ||
    lower.includes("universal") ||
    lower.includes("luganda dubbed") ||
    lower.includes("vj luganda") ||
    lower === "luganda" ||
    lower === "vj dubbed" ||
    lower.includes("translation")
  ) {
    return null;
  }

  const displayName = cleanRaw.toUpperCase().startsWith("VJ ")
    ? cleanRaw
    : `VJ ${cleanRaw}`;

  // Match against ALL_VJS list
  const matched = ALL_VJS.find((v) => {
    const vLower = v.name.toLowerCase();
    const vNoPrefix = vLower.replace(/^vj\s+/, "");
    const curNoPrefix = lower.replace(/^vj\s+/, "");
    return (
      vLower === lower ||
      vNoPrefix === curNoPrefix ||
      lower.includes(vNoPrefix) ||
      vLower.includes(curNoPrefix)
    );
  });

  const photoUrl = matched ? matched.photoUrl : "/vjs/vj_universal.png";

  const isSmall = size === "sm";

  return (
    <div
      className={`inline-flex items-center gap-1 rounded-xl bg-[#7C3AED]/80 border border-[#A78BFA]/50 shadow-md backdrop-blur-sm select-none ${
        isSmall ? "px-1.5 py-0.5" : "px-2.5 py-1"
      } ${className}`}
    >
      <div
        className={`rounded-full overflow-hidden shrink-0 border border-[#A78BFA]/60 bg-[#1E2130] flex items-center justify-center ${
          isSmall ? "w-3.5 h-3.5" : "w-5 h-5"
        }`}
      >
        {!imgError && photoUrl ? (
          <img
            src={photoUrl}
            alt={displayName}
            className="w-full h-full object-cover filter grayscale contrast-125"
            onError={() => setImgError(true)}
          />
        ) : (
          <Mic className={`text-white ${isSmall ? "w-2.5 h-2.5" : "w-3.5 h-3.5"}`} />
        )}
      </div>
      <span
        className={`font-bold text-white tracking-tight leading-none whitespace-nowrap ${
          isSmall ? "text-[9.5px]" : "text-xs"
        }`}
      >
        {displayName}
      </span>
    </div>
  );
};
