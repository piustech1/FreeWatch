import React, { useState } from "react";
import { ArrowLeft } from "lucide-react";
import { CHARACTER_AVATARS, AvatarItem } from "../data/avatars";
import { AvatarGraphic } from "./AvatarGraphic";

interface ChooseAvatarPageProps {
  selectedAvatarId?: string;
  onSelectAvatar: (avatar: AvatarItem) => void;
  onBack: () => void;
  onDone?: () => void;
}

export const ChooseAvatarPage: React.FC<ChooseAvatarPageProps> = ({
  selectedAvatarId = "mirabel",
  onSelectAvatar,
  onBack,
  onDone,
}) => {
  const [currentId, setCurrentId] = useState(selectedAvatarId);

  const handleChoose = (avatar: AvatarItem) => {
    setCurrentId(avatar.id);
    onSelectAvatar(avatar);
  };

  const handleFinish = () => {
    const selected = CHARACTER_AVATARS.find((a) => a.id === currentId) || CHARACTER_AVATARS[3];
    onSelectAvatar(selected);
    if (onDone) {
      onDone();
    } else {
      onBack();
    }
  };

  return (
    <div className="w-full min-h-screen bg-[#0e1017] text-white font-sans flex flex-col pb-12 select-none">
      {/* 1. TOP HEADER BAR matching Screenshot 3 */}
      <header className="sticky top-0 z-40 w-full bg-[#0e1017]/95 backdrop-blur-md px-4 py-3 flex items-center justify-between border-b border-white/5">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="w-9 h-9 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-white transition-colors cursor-pointer"
            aria-label="Back"
          >
            <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
          </button>
          <h1 className="text-lg font-black text-white tracking-tight">Choose Avatar</h1>
        </div>

        <button
          type="button"
          onClick={handleFinish}
          className="px-4 py-1.5 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 text-xs font-black text-neutral-200 hover:text-white uppercase tracking-wider transition-colors cursor-pointer"
        >
          DONE
        </button>
      </header>

      {/* 2. 3-COLUMN AVATAR GRID matching Screenshot 3 */}
      <div className="flex-1 px-6 pt-6 pb-8">
        <div className="grid grid-cols-3 gap-y-7 gap-x-4 max-w-md mx-auto">
          {CHARACTER_AVATARS.map((avatar) => {
            const isSelected = currentId === avatar.id;
            return (
              <div
                key={avatar.id}
                onClick={() => handleChoose(avatar)}
                className="flex flex-col items-center cursor-pointer group active:scale-95 transition-transform"
              >
                {/* Circular Avatar */}
                <div
                  className={`w-20 h-20 sm:w-22 sm:h-22 rounded-full p-0.5 transition-all duration-200 ${
                    isSelected
                      ? "ring-2 ring-white shadow-[0_0_16px_rgba(255,255,255,0.85)] scale-105"
                      : "opacity-80 group-hover:opacity-100 group-hover:scale-102"
                  }`}
                >
                  <div className="w-full h-full rounded-full overflow-hidden border border-black/40 shadow-md">
                    <AvatarGraphic id={avatar.id} />
                  </div>
                </div>

                {/* Character Name Label */}
                <span
                  className={`text-xs font-semibold text-center mt-2.5 transition-colors ${
                    isSelected ? "text-white font-bold" : "text-neutral-400 group-hover:text-neutral-200"
                  }`}
                >
                  {avatar.name}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
