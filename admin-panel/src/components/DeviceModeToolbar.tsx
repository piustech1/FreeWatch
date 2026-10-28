import React, { useState } from "react";
import { Smartphone, Monitor, Sparkles, ChevronDown, ChevronUp } from "lucide-react";

export type ViewportMode = "auto" | "desktop" | "mobile";

interface DeviceModeToolbarProps {
  mode: ViewportMode;
  onModeChange: (mode: ViewportMode) => void;
}

export const DeviceModeToolbar: React.FC<DeviceModeToolbarProps> = ({
  mode,
  onModeChange,
}) => {
  const [isCollapsed, setIsCollapsed] = useState(false);

  if (isCollapsed) {
    return (
      <button
        onClick={() => setIsCollapsed(false)}
        className="fixed top-3 right-4 z-50 px-3 py-1.5 rounded-full bg-neutral-900/90 hover:bg-neutral-800 backdrop-blur-md border border-neutral-700 text-[11px] font-bold text-white shadow-xl flex items-center gap-1.5 cursor-pointer"
        title="Switch Device View (Auto / PC / Mobile)"
      >
        <span className="w-2 h-2 rounded-full bg-[#00E676]" />
        <span>View: {mode.toUpperCase()}</span>
        <ChevronDown className="w-3.5 h-3.5 text-neutral-400" />
      </button>
    );
  }

  return (
    <div className="fixed top-3 left-1/2 -translate-x-1/2 z-50 flex items-center gap-1.5 p-1 rounded-full bg-neutral-900/95 backdrop-blur-md border border-neutral-800 text-xs text-white shadow-2xl shadow-black/80">
      <div className="flex items-center gap-1 bg-black/50 p-0.5 rounded-full border border-white/5">
        <button
          onClick={() => onModeChange("auto")}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-full font-semibold transition-all cursor-pointer ${
            mode === "auto"
              ? "bg-[#00E676] text-black shadow-md shadow-[#00E676]/20 font-bold"
              : "text-neutral-400 hover:text-white"
          }`}
          title="Automatic Responsive Layout"
        >
          <Sparkles className="w-3.5 h-3.5" />
          <span>Auto Device</span>
        </button>

        <button
          onClick={() => onModeChange("desktop")}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-full font-semibold transition-all cursor-pointer ${
            mode === "desktop"
              ? "bg-[#00E676] text-black shadow-md shadow-[#00E676]/20 font-bold"
              : "text-neutral-400 hover:text-white"
          }`}
          title="PC Web & 10-Foot TV UI (Matches 1793218681981_752aed45.jpg)"
        >
          <Monitor className="w-3.5 h-3.5" />
          <span>PC Web (TV)</span>
        </button>

        <button
          onClick={() => onModeChange("mobile")}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-full font-semibold transition-all cursor-pointer ${
            mode === "mobile"
              ? "bg-[#00E676] text-black shadow-md shadow-[#00E676]/20 font-bold"
              : "text-neutral-400 hover:text-white"
          }`}
          title="Mobile Phone View"
        >
          <Smartphone className="w-3.5 h-3.5" />
          <span>Mobile</span>
        </button>
      </div>

      <button
        onClick={() => setIsCollapsed(true)}
        className="p-1.5 rounded-full hover:bg-white/10 text-neutral-400 hover:text-white transition-colors cursor-pointer"
        title="Minimize toolbar"
      >
        <ChevronUp className="w-3.5 h-3.5" />
      </button>
    </div>
  );
};
