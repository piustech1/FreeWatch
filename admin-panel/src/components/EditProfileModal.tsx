import React, { useState } from "react";
import { X, User, Info, Lock } from "lucide-react";
import { CHARACTER_AVATARS } from "../data/avatars";
import { AvatarGraphic } from "./AvatarGraphic";

export interface UserProfileData {
  displayName: string;
  bio: string;
  avatarId: string;
}

interface EditProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentProfile: UserProfileData;
  onSave: (data: UserProfileData) => void;
  onOpenFullAvatarPicker?: () => void;
}

export const EditProfileModal: React.FC<EditProfileModalProps> = ({
  isOpen,
  onClose,
  currentProfile,
  onSave,
}) => {
  const [displayName, setDisplayName] = useState(currentProfile.displayName);
  const [bio, setBio] = useState(currentProfile.bio);
  const [selectedAvatarId, setSelectedAvatarId] = useState(currentProfile.avatarId || "mirabel");

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      displayName: displayName.trim() || "Admin2",
      bio: bio.trim() || "Luganda dubbed movie lover • Streaming on FreeWatch",
      avatarId: selectedAvatarId,
    });
    onClose();
  };

  // 6 quick avatars shown in the modal matching Screenshot 1
  const quickAvatars = CHARACTER_AVATARS.slice(0, 6);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/75 backdrop-blur-sm animate-in fade-in duration-200">
      {/* Click outside to close */}
      <div className="absolute inset-0" onClick={onClose} />

      {/* Bottom Sheet Modal Container matching Screenshot 1 */}
      <div className="relative z-10 w-full max-w-lg rounded-t-[32px] bg-[#0c0d12] border-t border-white/10 px-5 pt-3 pb-8 shadow-2xl flex flex-col max-h-[90vh] overflow-y-auto">
        {/* Grab Handle */}
        <div className="w-12 h-1 bg-neutral-600 rounded-full mx-auto mb-3" />

        {/* Modal Header */}
        <div className="flex items-center justify-between pb-3">
          <h2 className="text-xl font-black text-white tracking-tight">Edit Profile</h2>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 text-neutral-400 hover:text-white flex items-center justify-center transition-colors cursor-pointer"
            aria-label="Close"
          >
            <X className="w-4 h-4 stroke-[2.5]" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="space-y-4 pt-1">
          {/* 1. Choose Your Avatar Row */}
          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-2.5">
              Choose Your Avatar
            </label>
            <div className="flex items-center justify-between gap-2 overflow-x-auto no-scrollbar py-1">
              {quickAvatars.map((avatar) => {
                const isSelected = selectedAvatarId === avatar.id;
                return (
                  <button
                    key={avatar.id}
                    type="button"
                    onClick={() => setSelectedAvatarId(avatar.id)}
                    className="flex flex-col items-center gap-1 cursor-pointer shrink-0 transition-transform active:scale-90"
                  >
                    <div
                      className={`w-14 h-14 rounded-full p-0.5 transition-all ${
                        isSelected
                          ? "ring-2 ring-white shadow-[0_0_12px_rgba(255,255,255,0.7)] scale-105"
                          : "opacity-75 hover:opacity-100"
                      }`}
                    >
                      <div className="w-full h-full rounded-full overflow-hidden border border-black/40">
                        <AvatarGraphic id={avatar.id} />
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 2. Display Name Input */}
          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-1.5">
              Display Name
            </label>
            <div className="relative flex items-center">
              <div className="absolute left-3.5 text-neutral-400 pointer-events-none">
                <User className="w-4 h-4 text-sky-400" />
              </div>
              <input
                type="text"
                required
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Display Name"
                className="w-full h-12 pl-10 pr-4 rounded-xl bg-[#13141a] border border-white/5 text-sm text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-500 transition-colors"
              />
            </div>
          </div>

          {/* 3. Personal Info / Bio */}
          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-1.5">
              Personal Info / Bio
            </label>
            <div className="relative flex items-start rounded-xl bg-[#13141a] border border-white/5 p-3.5 gap-2.5">
              <div className="pt-0.5 text-neutral-400 shrink-0">
                <Info className="w-4 h-4 text-purple-400" />
              </div>
              <textarea
                rows={2}
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                placeholder="Add a bio..."
                className="w-full bg-transparent text-xs sm:text-sm text-white placeholder-neutral-500 resize-none focus:outline-none leading-relaxed"
              />
            </div>
          </div>

          {/* 4. Member Since Read-only */}
          <div className="rounded-xl bg-[#13141a] border border-white/5 py-3 px-3.5 flex items-center gap-2.5 text-neutral-400 text-xs select-none">
            <Lock className="w-3.5 h-3.5 text-neutral-500 shrink-0" />
            <span className="font-medium text-neutral-400">
              Member Since: Joined Recently (Read-only)
            </span>
          </div>

          {/* 5. Save Changes Button */}
          <div className="pt-2">
            <button
              type="submit"
              className="w-full h-12 rounded-2xl bg-[#00E676] hover:bg-[#00c865] active:scale-[0.99] font-black text-black text-sm tracking-wide transition-all shadow-lg shadow-[#00E676]/20 cursor-pointer flex items-center justify-center"
            >
              Save Changes
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
