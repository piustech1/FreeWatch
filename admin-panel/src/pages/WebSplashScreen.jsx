import React from 'react';
import { Download } from 'lucide-react';

export default function WebSplashScreen() {
  return (
    <div className="min-h-screen bg-white text-neutral-900 font-sans flex flex-col justify-between items-center px-6 py-12 selection:bg-black selection:text-white">
      {/* Top Header Placeholder */}
      <div className="w-full max-w-md flex justify-center">
        <span className="text-[11px] font-bold uppercase tracking-widest text-neutral-400">
          Official Web Portal
        </span>
      </div>

      {/* Main Center Content */}
      <main className="w-full max-w-md flex flex-col items-center text-center my-auto">
        {/* App Logo */}
        <div className="w-28 h-28 rounded-[28px] overflow-hidden shadow-2xl bg-black border border-black/5 flex-shrink-0">
          <img 
            src="/app_icon.png" 
            alt="FreeWatch Logo" 
            className="w-full h-full object-cover rounded-[28px]"
            onError={(e) => {
              e.target.onerror = null;
              e.target.src = '/app_icon.png';
            }}
          />
        </div>

        {/* Title & Subtitle */}
        <h1 className="text-3xl font-black text-neutral-900 tracking-tight mt-6">
          FreeWatch
        </h1>
        <p className="text-sm font-medium text-neutral-500 mt-1">
          Luganda Dubbed Movies & Series
        </p>

        {/* COMING SOON in bold white text on high-contrast pill */}
        <div className="mt-8">
          <div className="inline-flex items-center justify-center px-8 py-3 rounded-full bg-black text-white font-black text-sm tracking-[0.25em] uppercase shadow-lg">
            COMING SOON
          </div>
        </div>

        {/* CTA to Official App Store Listing */}
        <div className="mt-10 pt-4 flex flex-col items-center space-y-3 w-full">
          <p className="text-xs text-neutral-500 font-medium">
            FreeWatch for Android Phone and Android TV is available now
          </p>
          <a
            href="/store"
            className="inline-flex items-center space-x-2 px-6 py-3 rounded-full bg-[#0071E3] hover:bg-blue-600 active:scale-95 text-white font-bold text-xs shadow-md transition-all cursor-pointer"
          >
            <Download className="w-4 h-4" />
            <span>Download Official App (/store)</span>
          </a>
        </div>
      </main>

      {/* Clean Footer - Strictly NO Admin Panel links or redirects */}
      <footer className="w-full max-w-md text-center">
        <p className="text-[11px] text-neutral-400 font-medium">
          © 2026 FreeWatch Inc. All rights reserved.
        </p>
      </footer>
    </div>
  );
}
