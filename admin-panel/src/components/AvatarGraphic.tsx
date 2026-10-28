import React from "react";

interface AvatarGraphicProps {
  id: string;
  name?: string;
  className?: string;
}

export const AvatarGraphic: React.FC<AvatarGraphicProps> = ({ id, className = "w-full h-full" }) => {
  switch (id) {
    case "moon-knight":
      return (
        <div className={`relative bg-gradient-to-b from-slate-700 via-slate-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Hood */}
          <div className="absolute inset-x-2 top-1 bottom-1 rounded-t-full bg-slate-300 flex items-center justify-center shadow-inner">
            <div className="w-4/5 h-4/5 rounded-t-full bg-slate-800 flex flex-col items-center justify-center relative">
              {/* Crescent Moon Emblem */}
              <div className="w-3 h-3 rounded-full border-2 border-slate-200 border-r-transparent -rotate-45 mb-1" />
              {/* Glowing White Eyes */}
              <div className="flex gap-2">
                <div className="w-2.5 h-1 bg-white rounded-full shadow-[0_0_8px_white] -rotate-6" />
                <div className="w-2.5 h-1 bg-white rounded-full shadow-[0_0_8px_white] rotate-6" />
              </div>
            </div>
          </div>
        </div>
      );

    case "mei-lee":
      return (
        <div className={`relative bg-gradient-to-b from-red-500 via-orange-600 to-amber-700 flex items-center justify-center overflow-hidden ${className}`}>
          {/* Red Panda Ears */}
          <div className="absolute top-1 left-2 w-3.5 h-3.5 rounded-full bg-red-400 border border-white/50" />
          <div className="absolute top-1 right-2 w-3.5 h-3.5 rounded-full bg-red-400 border border-white/50" />
          {/* Face */}
          <div className="w-4/5 h-4/5 rounded-full bg-red-500 flex flex-col items-center justify-center relative border border-white/20">
            {/* White eyebrow tufts */}
            <div className="flex gap-3 mb-0.5">
              <div className="w-2.5 h-1.5 rounded-full bg-white -rotate-12" />
              <div className="w-2.5 h-1.5 rounded-full bg-white rotate-12" />
            </div>
            {/* Big Smile */}
            <div className="w-6 h-3 rounded-b-full bg-amber-950 border-t-2 border-white flex items-end justify-center overflow-hidden">
              <div className="w-3 h-1.5 rounded-t-full bg-rose-400" />
            </div>
          </div>
        </div>
      );

    case "penny-proud":
      return (
        <div className={`relative bg-gradient-to-b from-purple-900 via-fuchsia-950 to-stone-900 flex items-center justify-center overflow-hidden ${className}`}>
          {/* Penny Proud Ponytails */}
          <div className="absolute top-2 left-1 w-4 h-4 rounded-full bg-[#1a0f0f]" />
          <div className="absolute top-2 right-1 w-4 h-4 rounded-full bg-[#1a0f0f]" />
          {/* Face */}
          <div className="w-3/4 h-3/4 rounded-full bg-[#a16207]/70 flex flex-col items-center justify-center relative">
            <div className="flex gap-2.5 mb-1">
              <div className="w-1.5 h-2 rounded-full bg-[#1a0f0f]" />
              <div className="w-1.5 h-2 rounded-full bg-[#1a0f0f]" />
            </div>
            <div className="w-3 h-1 rounded-full bg-rose-500" />
            {/* Burgundy Collar */}
            <div className="absolute bottom-0 w-full h-2 bg-rose-800 rounded-b-full" />
          </div>
        </div>
      );

    case "mirabel":
      return (
        <div className={`relative bg-gradient-to-b from-teal-900 via-emerald-950 to-stone-950 flex items-center justify-center overflow-hidden ${className}`}>
          {/* Curly Dark Hair */}
          <div className="absolute inset-1 rounded-full bg-[#140e0b] opacity-90" />
          {/* Face */}
          <div className="w-3/4 h-3/4 rounded-full bg-[#c28e67] flex flex-col items-center justify-center relative z-10">
            {/* Green Mirabel Glasses */}
            <div className="flex gap-1.5 mb-0.5">
              <div className="w-3.5 h-3.5 rounded-full border-2 border-emerald-400 bg-white/30 flex items-center justify-center">
                <div className="w-1.5 h-1.5 rounded-full bg-[#3d271d]" />
              </div>
              <div className="w-3.5 h-3.5 rounded-full border-2 border-emerald-400 bg-white/30 flex items-center justify-center">
                <div className="w-1.5 h-1.5 rounded-full bg-[#3d271d]" />
              </div>
            </div>
            {/* Warm Smile */}
            <div className="w-3.5 h-1.5 rounded-b-full bg-rose-500" />
            {/* Floral White & Pink Shirt Collar */}
            <div className="absolute -bottom-1 w-full h-3 bg-white rounded-b-full border-t border-pink-400 flex items-center justify-center gap-0.5">
              <span className="w-1 h-1 rounded-full bg-pink-500" />
              <span className="w-1 h-1 rounded-full bg-teal-500" />
            </div>
          </div>
        </div>
      );

    case "grogu":
      return (
        <div className={`relative bg-gradient-to-b from-stone-800 via-neutral-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Big Pointy Ears */}
          <div className="absolute top-4 left-0 w-5 h-2.5 rounded-l-full bg-lime-700/80 -rotate-12" />
          <div className="absolute top-4 right-0 w-5 h-2.5 rounded-r-full bg-lime-700/80 rotate-12" />
          {/* Head */}
          <div className="w-2/3 h-2/3 rounded-full bg-lime-600 flex flex-col items-center justify-center relative z-10 border border-lime-500/40">
            {/* Big Black Eyes */}
            <div className="flex gap-3 mb-1">
              <div className="w-2.5 h-2.5 rounded-full bg-black shadow-inner" />
              <div className="w-2.5 h-2.5 rounded-full bg-black shadow-inner" />
            </div>
            <div className="w-2 h-0.5 rounded-full bg-lime-900" />
            {/* Brown Sherpa Coat Collar */}
            <div className="absolute -bottom-1 w-full h-3 bg-[#a38059] rounded-b-full border-t-2 border-[#d6ba94]" />
          </div>
        </div>
      );

    case "boba-fett":
      return (
        <div className={`relative bg-gradient-to-b from-emerald-950 via-zinc-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Helmet */}
          <div className="w-4/5 h-4/5 rounded-t-2xl rounded-b-lg bg-[#274032] flex flex-col items-center justify-center relative border border-emerald-600/40 shadow-inner">
            {/* Red Visor Trim */}
            <div className="w-3/4 h-2/3 rounded-sm bg-rose-900/90 flex items-center justify-center p-0.5">
              {/* T-Visor Black */}
              <div className="relative w-full h-full flex flex-col items-center justify-center">
                <div className="w-full h-1 bg-black" />
                <div className="w-1.5 h-4 bg-black" />
              </div>
            </div>
            {/* Rangefinder Antenna */}
            <div className="absolute -top-1.5 right-1 w-1 h-3 bg-amber-500/80 rounded-t" />
          </div>
        </div>
      );

    case "minnie-mouse":
      return (
        <div className={`relative bg-gradient-to-b from-pink-950 via-neutral-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Black Mouse Ears */}
          <div className="absolute top-1 left-2 w-4 h-4 rounded-full bg-black border border-white/20" />
          <div className="absolute top-1 right-2 w-4 h-4 rounded-full bg-black border border-white/20" />
          {/* Pink Polka Dot Bow */}
          <div className="absolute top-1 z-20 flex items-center">
            <div className="w-3 h-2 rounded-l-full bg-pink-500" />
            <div className="w-2 h-2 rounded-full bg-pink-400 z-10" />
            <div className="w-3 h-2 rounded-r-full bg-pink-500" />
          </div>
          {/* Face */}
          <div className="w-2/3 h-2/3 rounded-full bg-[#fde047]/30 border border-white/10 flex flex-col items-center justify-center relative mt-2">
            <div className="flex gap-2 mb-0.5">
              <div className="w-1.5 h-2.5 rounded-full bg-black" />
              <div className="w-1.5 h-2.5 rounded-full bg-black" />
            </div>
            <div className="w-2 h-1.5 rounded-full bg-black" />
          </div>
        </div>
      );

    case "raya":
      return (
        <div className={`relative bg-gradient-to-b from-amber-950 via-stone-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Conical Straw Hat */}
          <div
            className="absolute top-0 inset-x-1 h-6 bg-[#b45309] shadow-md z-20"
            style={{ clipPath: "polygon(50% 0%, 0% 100%, 100% 100%)" }}
          />
          {/* Warrior Face */}
          <div className="w-2/3 h-2/3 rounded-full bg-[#9a6a43] flex flex-col items-center justify-center relative mt-2 z-10">
            <div className="flex gap-2 mb-1">
              <div className="w-1.5 h-1.5 rounded-full bg-[#17120e]" />
              <div className="w-1.5 h-1.5 rounded-full bg-[#17120e]" />
            </div>
            <div className="w-2.5 h-0.5 rounded-full bg-[#451a03]" />
          </div>
        </div>
      );

    case "tiana":
      return (
        <div className={`relative bg-gradient-to-b from-emerald-950 via-teal-950 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Silver Tiara */}
          <div className="absolute top-1 z-20 flex items-end gap-0.5">
            <div className="w-1 h-2 bg-emerald-300 rounded-t" />
            <div className="w-1.5 h-3 bg-emerald-200 rounded-t" />
            <div className="w-1 h-2 bg-emerald-300 rounded-t" />
          </div>
          {/* Updo Hair & Face */}
          <div className="w-3/4 h-3/4 rounded-full bg-[#8c593b] flex flex-col items-center justify-center relative mt-1 border border-white/10">
            <div className="flex gap-2 mb-1">
              <div className="w-1.5 h-2 rounded-full bg-[#20150e]" />
              <div className="w-1.5 h-2 rounded-full bg-[#20150e]" />
            </div>
            <div className="w-3 h-1.5 rounded-full bg-rose-400" />
            {/* Leaf Dress Collar */}
            <div className="absolute bottom-0 w-full h-2.5 bg-emerald-600 rounded-b-full" />
          </div>
        </div>
      );

    case "baymax":
      return (
        <div className={`relative bg-gradient-to-b from-slate-200 via-slate-300 to-slate-400 flex items-center justify-center overflow-hidden ${className}`}>
          {/* Smooth White Inflatable Head */}
          <div className="w-4/5 h-4/5 rounded-full bg-white shadow-md flex items-center justify-center relative">
            {/* Baymax Iconic Two Dot Eyes Connected with Line */}
            <div className="flex items-center gap-0">
              <div className="w-2 h-2 rounded-full bg-black" />
              <div className="w-6 h-0.5 bg-black" />
              <div className="w-2 h-2 rounded-full bg-black" />
            </div>
          </div>
        </div>
      );

    case "anna":
      return (
        <div className={`relative bg-gradient-to-b from-indigo-950 via-purple-950 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Auburn Braids */}
          <div className="absolute top-2 left-1.5 w-3 h-8 rounded-full bg-[#c2410c] -rotate-12" />
          <div className="absolute top-2 right-1.5 w-3 h-8 rounded-full bg-[#c2410c] rotate-12" />
          {/* Face */}
          <div className="w-2/3 h-2/3 rounded-full bg-[#fed7aa] flex flex-col items-center justify-center relative z-10 border border-white/20">
            <div className="flex gap-2 mb-1">
              <div className="w-1.5 h-2 rounded-full bg-sky-600" />
              <div className="w-1.5 h-2 rounded-full bg-sky-600" />
            </div>
            <div className="w-2.5 h-1 rounded-full bg-rose-400" />
            {/* Magenta Cloak */}
            <div className="absolute -bottom-1 w-full h-2.5 bg-fuchsia-800 rounded-b-full border-t border-amber-400" />
          </div>
        </div>
      );

    case "mickey-mouse":
    default:
      return (
        <div className={`relative bg-gradient-to-b from-zinc-900 via-neutral-900 to-black flex items-center justify-center overflow-hidden ${className}`}>
          {/* Black Mouse Ears */}
          <div className="absolute top-1 left-2 w-4 h-4 rounded-full bg-black border border-white/20" />
          <div className="absolute top-1 right-2 w-4 h-4 rounded-full bg-black border border-white/20" />
          {/* Face */}
          <div className="w-2/3 h-2/3 rounded-full bg-[#fed7aa]/90 flex flex-col items-center justify-center relative mt-2 border border-white/10">
            <div className="flex gap-2 mb-0.5">
              <div className="w-1.5 h-2.5 rounded-full bg-black" />
              <div className="w-1.5 h-2.5 rounded-full bg-black" />
            </div>
            <div className="w-2 h-1.5 rounded-full bg-black" />
            <div className="w-3.5 h-1.5 rounded-b-full bg-rose-500 mt-0.5" />
          </div>
        </div>
      );
  }
};
