# 🎬 FreeWatch Official Admin Panel

Modern, real-time web administration console for **FreeWatch (v1.0.55)** built with **React**, **Vite**, **Tailwind CSS**, and **Firebase Realtime Database**.

---

## ⚡ Features

1. **💬 Live 2-Way Support Chat**:
   - Real-time two-way messaging directly connected to the FreeWatch mobile application (`support_chats/` in Firebase RTDB).
   - Instant auditory and visual updates for incoming user messages.
   - Quick reply presets and thread filtering.
   - Updates reflect instantaneously on the user's phone in the "Chat with Admin" screen.

2. **📢 FCM Cloud Push Notification Dispatcher**:
   - Broadcast instant push alerts to all installed FreeWatch mobile devices.
   - Targets global broadcast topics: `all_users` or `new_releases`.
   - Rich notifications with custom title, body, and movie backdrop/poster images.
   - Mobile OS status bar preview simulating the pure transparent FreeWatch logo (`ic_notification.png`).
   - Dispatches history log in `push_notifications/history`.

3. **🎬 Catalog & VJ Asset Manager**:
   - Verification status of all official VJs (VJ Junior, VJ Emmy, VJ Ice P, VJ Jingo, VJ Kevin, VJ Sunny, VJ Anti, VJ Mossa, VJ Chris Sweet).
   - Tracks the dedicated Universal VJ asset (`assets/vjs/vj_universal.png`).
   - Live verified TikTok account link sync (`https://www.tiktok.com/@freewatchmoviesug?_r=1&_t=ZS-9AV8GRTNGfi`).

---

## 🚀 1-Click Deployment to Vercel

### Method 1: Via Vercel CLI (Fastest)
1. In your terminal, navigate to the `admin-panel` folder:
   ```bash
   cd admin-panel
   ```
2. Run:
   ```bash
   npx vercel
   ```
3. Follow the CLI prompt (accept defaults; `vercel.json` will automatically configure build settings and SPA rewrites).

### Method 2: Via GitHub & Vercel Dashboard
1. Push your repository to GitHub.
2. Go to [vercel.com/new](https://vercel.com/new) and import the FreeWatch repository.
3. In **Root Directory**, select `admin-panel`.
4. Framework Preset: **Vite** (Build Command: `npm run build`, Output Directory: `dist`).
5. Click **Deploy**.

---

## 💻 Local Development

```bash
cd admin-panel
npm install
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.
