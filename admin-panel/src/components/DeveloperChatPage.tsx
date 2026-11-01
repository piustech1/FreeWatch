import React, { useState, useRef, useEffect } from "react";
import {
  ArrowLeft,
  Search as SearchIcon,
  Bell,
  CheckCircle,
  Info,
  Send,
  CheckCheck,
} from "lucide-react";
import { FreeWatchLogo } from "./HomePage";
import { AvatarGraphic } from "./AvatarGraphic";
import { UserProfileData } from "./EditProfileModal";

interface ChatMessage {
  id: string;
  sender: "user" | "developer";
  text: string;
  timestamp: string;
  quote?: {
    author: string;
    text: string;
  };
}

interface DeveloperChatPageProps {
  onBack: () => void;
  onNavigateTab: (tab: "home" | "search" | "favorites" | "downloads" | "profile") => void;
  onNavigateToNotifications?: () => void;
  onLogout?: () => void;
  userProfile?: UserProfileData;
}

const DEFAULT_WELCOME: ChatMessage[] = [
  {
    id: "welcome-1",
    sender: "developer",
    text: "Hello! Welcome to FreeWatch Support. 👋 How can we help you today with your movie playback, audio translations, or suggestions?",
    timestamp: "Online",
  },
];

export const DeveloperChatPage: React.FC<DeveloperChatPageProps> = ({
  onBack,
  onNavigateTab,
  onNavigateToNotifications,
  userProfile,
}) => {
  const [messages, setMessages] = useState<ChatMessage[]>(() => {
    try {
      const saved = localStorage.getItem("freewatch_developer_chat_v1");
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch {}
    return DEFAULT_WELCOME;
  });
  const [inputText, setInputText] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const cleanText = inputText.trim();
    if (!cleanText) return;

    const userMsg: ChatMessage = {
      id: `usr-${Date.now()}`,
      sender: "user",
      text: cleanText,
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    };

    setMessages((prev) => {
      const updated = [...prev, userMsg];
      try {
        localStorage.setItem("freewatch_developer_chat_v1", JSON.stringify(updated));
      } catch {}
      return updated;
    });
    setInputText("");

    // Simulated contextual response from FreeWatch support
    setTimeout(() => {
      let replyText = "Thank you for reaching out! The FreeWatch technical team is monitoring servers 24/7 to ensure fast playback and crisp audio.";
      const lower = cleanText.toLowerCase();
      if (lower.includes("movie") || lower.includes("series") || lower.includes("vj") || lower.includes("upload")) {
        replyText = "We're continuously uploading new Luganda dubbed releases from top VJs! Your requested titles are being indexed.";
      } else if (lower.includes("stream") || lower.includes("error") || lower.includes("play") || lower.includes("loading")) {
        replyText = "Our multi-CDN video servers have been refreshed. If you encounter any buffering, please tap Retry Stream or check your network.";
      } else if (lower.includes("hello") || lower.includes("hi") || lower.includes("hey")) {
        replyText = "Hello! Great to have you on FreeWatch. What would you like to watch today?";
      }

      const devMsg: ChatMessage = {
        id: `dev-${Date.now()}`,
        sender: "developer",
        text: replyText,
        timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      };

      setMessages((prev) => {
        const updated = [...prev, devMsg];
        try {
          localStorage.setItem("freewatch_developer_chat_v1", JSON.stringify(updated));
        } catch {}
        return updated;
      });
    }, 900);
  };

  return (
    <div className="w-full min-h-screen bg-black text-white font-sans flex flex-col justify-between select-none">
      {/* 1. TOP APP HEADER BAR */}
      <header className="sticky top-0 z-40 w-full bg-black/90 backdrop-blur-md px-4 py-3 flex items-center justify-between border-b border-white/5">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition-colors cursor-pointer"
            aria-label="Back"
          >
            <ArrowLeft className="w-4 h-4 stroke-[2.2]" />
          </button>
          <FreeWatchLogo />
        </div>

        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => onNavigateTab("search")}
            className="p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Search"
          >
            <SearchIcon className="w-5 h-5 stroke-[2.2]" />
          </button>

          <button
            type="button"
            onClick={onNavigateToNotifications}
            className="relative p-1 text-white hover:text-[#00E676] transition-colors cursor-pointer"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 stroke-[2.2]" />
          </button>

          <button
            type="button"
            onClick={() => onNavigateTab("profile")}
            title="Account Profile"
            className="w-8 h-8 rounded-full overflow-hidden border border-white/20 active:scale-95 transition-transform cursor-pointer"
          >
            <AvatarGraphic id={userProfile?.avatarId || "mirabel"} />
          </button>
        </div>
      </header>

      {/* 2. CHAT SUB-HEADER PILL (Admin Developer Support bar) */}
      <div className="px-3 pt-2">
        <div className="w-full rounded-2xl bg-[#141416] border border-white/10 px-3 py-2 flex items-center justify-between shadow-lg">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onBack}
              className="w-9 h-9 rounded-full bg-[#1c1c1f] hover:bg-[#252528] flex items-center justify-center text-white transition-colors cursor-pointer"
              aria-label="Back"
            >
              <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
            </button>

            {/* FreeWatch Avatar with glowing green online dot */}
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-[#0a1a12] border-2 border-[#00E676]/60 flex items-center justify-center shadow-md">
                <span className="text-xs font-black tracking-tight text-white">
                  F<span className="text-[#00E676]">W</span>
                </span>
              </div>
              <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-[#00E676] border-2 border-black" />
            </div>

            {/* Admin Title & Support Status */}
            <div>
              <div className="flex items-center gap-1.5">
                <span className="text-sm font-bold text-white">Admin</span>
                <CheckCircle className="w-3.5 h-3.5 fill-[#38bdf8] text-black" />
              </div>
              <div className="flex items-center gap-1.5 text-[11px] text-neutral-400">
                <span className="w-1.5 h-1.5 rounded-full bg-[#00E676] inline-block" />
                <span>Active now • Developer Support</span>
              </div>
            </div>
          </div>

          {/* Info Button */}
          <button
            type="button"
            className="w-8 h-8 rounded-full bg-[#1c1c1f] flex items-center justify-center text-neutral-400 hover:text-white transition-colors cursor-pointer"
            aria-label="Support info"
          >
            <Info className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* 3. CHAT CONTENT AREA WITH BACKGROUND MOTIFS */}
      <div className="flex-1 max-w-3xl mx-auto w-full px-4 py-4 space-y-4 overflow-y-auto relative">
        {/* Ambient chat watermark icons */}
        <div className="absolute inset-0 opacity-[0.03] pointer-events-none flex flex-wrap gap-12 p-8 overflow-hidden">
          <span className="text-6xl">🎬</span>
          <span className="text-6xl">🎧</span>
          <span className="text-6xl">⭐</span>
          <span className="text-6xl">💬</span>
          <span className="text-6xl">🍿</span>
          <span className="text-6xl">🎵</span>
          <span className="text-6xl">🔥</span>
        </div>

        {/* Date Pill: Oct 13, 2026 */}
        <div className="flex justify-center relative z-10 my-2">
          <span className="px-3.5 py-1 rounded-full bg-[#1c1c1f] border border-white/5 text-[11px] font-medium text-neutral-400 shadow-sm">
            Oct 13, 2026
          </span>
        </div>

        {/* Messages Stream */}
        <div className="space-y-3.5 relative z-10">
          {messages.map((msg) => {
            const isUser = msg.sender === "user";

            return (
              <div
                key={msg.id}
                className={`flex items-end gap-2 ${isUser ? "justify-end" : "justify-start"}`}
              >
                {/* Developer Avatar */}
                {!isUser && (
                  <div className="w-7 h-7 rounded-full bg-[#0a1a12] border border-[#00E676]/60 flex items-center justify-center shrink-0 mb-1">
                    <span className="text-[9px] font-black text-white">
                      F<span className="text-[#00E676]">W</span>
                    </span>
                  </div>
                )}

                {/* Message Bubble */}
                <div
                  className={`max-w-[78%] sm:max-w-[65%] rounded-2xl p-3 text-sm leading-relaxed shadow-md ${
                    isUser
                      ? "bg-[#058756] text-white rounded-tr-none"
                      : "bg-[#18181b] border border-white/10 text-white rounded-tl-none"
                  }`}
                >
                  {/* Quoted Message (if any) */}
                  {msg.quote && (
                    <div className="mb-2 p-2.5 rounded-xl bg-black/30 border-l-2 border-[#00E676] text-xs">
                      <div className="font-bold text-[#00E676] text-[11px] mb-0.5">
                        {msg.quote.author}
                      </div>
                      <div className="text-neutral-200 italic font-normal">
                        {msg.quote.text}
                      </div>
                    </div>
                  )}

                  {/* Main Bubble Text */}
                  <div className="text-xs sm:text-sm font-medium">{msg.text}</div>

                  {/* Timestamp & Status checks */}
                  <div
                    className={`mt-1 flex items-center justify-end gap-1 text-[10px] ${
                      isUser ? "text-emerald-200" : "text-neutral-400"
                    }`}
                  >
                    <span>{msg.timestamp}</span>
                    {isUser && <CheckCheck className="w-3.5 h-3.5 text-emerald-200" />}
                  </div>
                </div>

                {/* User Avatar */}
                {isUser && (
                  <div className="w-7 h-7 rounded-full overflow-hidden border border-white/20 shrink-0 mb-1">
                    <AvatarGraphic id={userProfile?.avatarId || "mirabel"} />
                  </div>
                )}
              </div>
            );
          })}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* 4. BOTTOM INPUT BAR */}
      <footer className="sticky bottom-0 z-40 bg-black/95 backdrop-blur-md px-3 py-3 border-t border-white/5">
        <form onSubmit={handleSendMessage} className="flex items-center gap-2 max-w-2xl mx-auto">
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="Ask developer anything..."
            className="flex-1 h-12 rounded-full bg-[#161618] border border-white/10 px-5 text-sm text-white placeholder-neutral-500 focus:outline-none focus:border-[#00E676]/60 transition-colors"
          />

          <button
            type="submit"
            disabled={!inputText.trim()}
            className="w-12 h-12 rounded-full bg-[#202024] hover:bg-[#00E676] text-white hover:text-black disabled:opacity-40 disabled:hover:bg-[#202024] disabled:hover:text-white flex items-center justify-center transition-all cursor-pointer shadow-md shrink-0 active:scale-95"
            aria-label="Send message"
          >
            <Send className="w-4 h-4 ml-0.5" />
          </button>
        </form>
      </footer>
    </div>
  );
};
