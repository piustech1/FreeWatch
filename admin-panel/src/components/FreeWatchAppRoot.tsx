import React, { useState } from "react";
import { SplashScreen } from "./SplashScreen";
import { AuthPage, AuthScreenType } from "./AuthPage";
import { HomePage } from "./HomePage";
import { SearchPage } from "./SearchPage";
import { FavoritesPage } from "./FavoritesPage";
import { ProfilePage } from "./ProfilePage";
import { SeriesDetailsPage } from "./SeriesDetailsPage";
import { MovieDetailsPage } from "./MovieDetailsPage";
import { NotificationsPage } from "./NotificationsPage";
import { DeveloperChatPage } from "./DeveloperChatPage";
import { AvailableVJsPage, ALL_VJS, VJDetailItem } from "./AvailableVJsPage";
import { VjMoviesPage } from "./VjMoviesPage";
import { CategorySeeAllPage } from "./CategorySeeAllPage";
import { DownloadsPage } from "./DownloadsPage";
import { AppLaunchBannerModal } from "./AppLaunchBannerModal";
import { UserProfileData } from "./EditProfileModal";
import { DesktopNavRail, DesktopNavTarget } from "./DesktopNavRail";
import { CatalogMovie } from "../data/liveCatalog";

type ActiveTab = "home" | "search" | "favorites" | "downloads" | "profile";
type ActivePage =
  | "splash"
  | "login"
  | "signup"
  | "series-details"
  | "movie-details"
  | "notifications"
  | "developer-chat"
  | "available-vjs"
  | "vj-movies"
  | "category-see-all"
  | ActiveTab;

interface FreeWatchAppRootProps {
  onNavigateToStore?: () => void;
}
export default function FreeWatchAppRoot({ onNavigateToStore }: FreeWatchAppRootProps) {
  const [currentPage, setCurrentPage] = useState<ActivePage>("home");
  const [history, setHistory] = useState<ActivePage[]>([]);
  const [_user, setUser] = useState<string | null>("Admin2");
  const [showAppLaunchBanner, setShowAppLaunchBanner] = useState<boolean>(true);
  const [userProfile, setUserProfile] = useState<UserProfileData>(() => {
    try {
      const saved = localStorage.getItem("freewatch_user_profile");
      if (saved) return JSON.parse(saved);
    } catch {}
    return {
      displayName: "Admin2",
      bio: "Luganda dubbed movie lover • Streaming on FreeWatch",
      avatarId: "mirabel",
    };
  });
  const [selectedMovieTitle, setSelectedMovieTitle] = useState<string>("The MOST DANGEROUS GAME");
  const [selectedMovie, setSelectedMovie] = useState<CatalogMovie | undefined>(undefined);
  const [selectedVj, setSelectedVj] = useState<VJDetailItem>(ALL_VJS[0] || ALL_VJS[1]);
  const [selectedCategory, setSelectedCategory] = useState<{
    title: string;
    count: number;
    iconType: string;
  }>({
    title: "Latest on FreeWatch",
    count: 43,
    iconType: "sparkles",
  });

  const handleUpdateProfile = (newProfile: UserProfileData) => {
    setUserProfile(newProfile);
    try {
      localStorage.setItem("freewatch_user_profile", JSON.stringify(newProfile));
    } catch {}
  };

  const pushNavigation = (targetPage: ActivePage) => {
    if (targetPage === currentPage) return;
    setHistory((prev) => [...prev, currentPage]);
    setCurrentPage(targetPage);
  };

  const handleBack = () => {
    setHistory((prev) => {
      if (prev.length === 0) {
        if (currentPage === "vj-movies") {
          setCurrentPage("available-vjs");
        } else if (currentPage !== "home") {
          setCurrentPage("home");
        }
        return [];
      }
      const newStack = [...prev];
      let target = newStack.pop();
      while (target === currentPage && newStack.length > 0) {
        target = newStack.pop();
      }
      if (target && target !== currentPage) {
        setCurrentPage(target);
      } else {
        setCurrentPage("home");
      }
      return newStack;
    });
  };

  const handleAuthSuccess = (nameOrEmail?: string, avatarId?: string) => {
    const finalName = nameOrEmail || "Admin2";
    setUser(finalName);
    const updatedProfile: UserProfileData = {
      ...userProfile,
      displayName:
        nameOrEmail && nameOrEmail.includes("@")
          ? nameOrEmail.split("@")[0]
          : nameOrEmail || userProfile.displayName,
      avatarId: avatarId || userProfile.avatarId,
    };
    handleUpdateProfile(updatedProfile);
    setShowAppLaunchBanner(true);
    setHistory([]);
    setCurrentPage("home");
  };

  const handleNavigateTab = (tab: ActiveTab) => {
    pushNavigation(tab);
  };

  const handleNavigateToNotifications = () => {
    pushNavigation("notifications");
  };

  const handleNavigateToDeveloperChat = () => {
    pushNavigation("developer-chat");
  };

  const handleNavigateToAvailableVJs = () => {
    pushNavigation("available-vjs");
  };

  const handleSelectVj = (vj: VJDetailItem) => {
    setSelectedVj(vj);
    pushNavigation("vj-movies");
  };

  const handleNavigateToCategorySeeAll = (
    title: string = "Latest on FreeWatch",
    count: number = 43,
    iconType: string = "sparkles"
  ) => {
    setSelectedCategory({ title, count, iconType });
    pushNavigation("category-see-all");
  };

  const handleSelectMovie = (
    movieId?: string,
    isSeries?: boolean,
    title?: string,
    movie?: CatalogMovie
  ) => {
    if (title) {
      setSelectedMovieTitle(title);
    }
    if (movie) {
      setSelectedMovie(movie);
    } else {
      setSelectedMovie(undefined);
    }

    // Strict validation: A movie is ONLY a series if it genuinely is one!
    // A single movie (including sequels like Deadpool 2, Bad Boys 4, Dune Part 2) MUST NEVER open series-details!
    const isRealSeries = Boolean(
      (movie && (
        // Has real multiple episodes loaded
        (Array.isArray(movie.episodes) && movie.episodes.length > 0) ||
        // Has a confirmed non-zero series code from MunoWatch
        (movie.seriesCode && String(movie.seriesCode).trim().length > 0 && String(movie.seriesCode) !== '0') ||
        // Explicitly in Series category AND marked as isTv
        (movie.isTv && String(movie.category).toLowerCase().trim() === 'series')
      )) ||
      (isSeries && movie?.isTv && (
        (Array.isArray(movie?.episodes) && movie.episodes.length > 0) ||
        (movie?.seriesCode && String(movie.seriesCode).trim().length > 0 && String(movie.seriesCode) !== '0')
      ))
    );

    const targetPage: ActivePage = isRealSeries ? "series-details" : "movie-details";
    pushNavigation(targetPage);
  };

  const isAuthOrSplash =
    currentPage === "splash" || currentPage === "login" || currentPage === "signup";

  const handleDesktopNav = (target: DesktopNavTarget) => {
    if (target === "home") pushNavigation("home");
    else if (target === "search") pushNavigation("search");
    else if (target === "available-vjs") pushNavigation("available-vjs");
    else if (target === "categories")
      handleNavigateToCategorySeeAll("Latest on FreeWatch", 43, "sparkles");
    else if (target === "favorites") pushNavigation("favorites");
    else if (target === "downloads") pushNavigation("downloads");
    else if (target === "profile") pushNavigation("profile");
    else if (target === "notifications") pushNavigation("notifications");
  };

  return (
    <main className="w-full min-h-screen bg-black text-white relative selection:bg-[#00E676] selection:text-black">
      {/* PERSISTENT DESKTOP NAVIGATION RAIL (Visible on desktop lg+) */}
      {!isAuthOrSplash && (
        <DesktopNavRail
          currentNav={currentPage}
          onNavigate={handleDesktopNav}
          userProfile={userProfile}
          notificationCount={42}
        />
      )}

      {/* MAIN VIEWPORT CONTENT (Padded on desktop to accommodate left rail) */}
      <div
        className={`${
          !isAuthOrSplash ? "lg:pl-20 xl:pl-22" : ""
        } w-full min-h-screen transition-all duration-200`}
      >
        {/* 1. AVAILABLE VJS FULL PAGE */}
        {currentPage === "available-vjs" && (
          <AvailableVJsPage
            userProfile={userProfile}
            onBack={handleBack}
            onSelectVj={handleSelectVj}
            onNavigateTab={handleNavigateTab}
            onNavigateToNotifications={handleNavigateToNotifications}
            onLogout={() => setCurrentPage("splash")}
          />
        )}

        {/* 2. PARTICULAR VJ MOVIES PAGE */}
        {currentPage === "vj-movies" && (
          <VjMoviesPage
            vj={selectedVj}
            userProfile={userProfile}
            onBack={handleBack}
            onSelectMovie={handleSelectMovie}
            onNavigateTab={handleNavigateTab}
            onNavigateToNotifications={handleNavigateToNotifications}
            onLogout={() => setCurrentPage("splash")}
          />
        )}

        {/* 3. HOME SECTIONS "SEE ALL" FULL PAGE */}
        {currentPage === "category-see-all" && (
          <CategorySeeAllPage
            categoryTitle={selectedCategory.title}
            count={selectedCategory.count}
            iconType={selectedCategory.iconType}
            userProfile={userProfile}
            onBack={handleBack}
            onSelectMovie={handleSelectMovie}
            onNavigateTab={handleNavigateTab}
            onNavigateToNotifications={handleNavigateToNotifications}
            onLogout={() => setCurrentPage("splash")}
          />
        )}

        {/* 4. NOTIFICATIONS PAGE */}
        {currentPage === "notifications" && (
          <NotificationsPage
            userProfile={userProfile}
            onBack={handleBack}
            onNavigateTab={handleNavigateTab}
            onSelectMovie={handleSelectMovie}
            onLogout={() => setCurrentPage("splash")}
          />
        )}

        {/* 5. TALK TO DEVELOPER / CHAT PAGE */}
        {currentPage === "developer-chat" && (
          <DeveloperChatPage
            userProfile={userProfile}
            onBack={handleBack}
            onNavigateTab={handleNavigateTab}
            onNavigateToNotifications={handleNavigateToNotifications}
            onLogout={() => setCurrentPage("splash")}
          />
        )}

        {/* 6. SINGLE MOVIE DETAILS PAGE */}
        {currentPage === "movie-details" && (
          <MovieDetailsPage
            movieTitle={selectedMovieTitle}
            movie={selectedMovie}
            userProfile={userProfile}
            onBack={handleBack}
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
          />
        )}

        {/* 7. TV SERIES DETAILS PAGE */}
        {currentPage === "series-details" && (
          <SeriesDetailsPage
            seriesTitle={selectedMovieTitle}
            movie={selectedMovie}
            userProfile={userProfile}
            onBack={handleBack}
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
          />
        )}

        {/* 8. FAVORITES PAGE */}
        {currentPage === "favorites" && (
          <FavoritesPage
            userProfile={userProfile}
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
          />
        )}

        {/* 9. PROFILE PAGE */}
        {currentPage === "profile" && (
          <ProfilePage
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onNavigateToDeveloperChat={handleNavigateToDeveloperChat}
            onNavigateToNotifications={handleNavigateToNotifications}
            onSelectMovie={handleSelectMovie}
            userProfile={userProfile}
            onUpdateProfile={handleUpdateProfile}
          />
        )}

        {/* 10. SEARCH PAGE */}
        {currentPage === "search" && (
          <SearchPage
            userProfile={userProfile}
            onBackToHome={handleBack}
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
          />
        )}

        {/* 11. HOME PAGE */}
        {currentPage === "home" && (
          <HomePage
            userProfile={userProfile}
            onLogout={() => setCurrentPage("splash")}
            onNavigateTab={handleNavigateTab}
            onNavigateToSearch={() => setCurrentPage("search")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
            onNavigateToAvailableVJs={handleNavigateToAvailableVJs}
            onNavigateToCategorySeeAll={handleNavigateToCategorySeeAll}
            onSelectVj={(name) => {
              const found =
                ALL_VJS.find(
                  (v) =>
                    v.name.toLowerCase() === name.toLowerCase() ||
                    name.toLowerCase().includes(v.name.toLowerCase()) ||
                    v.name.toLowerCase().includes(name.toLowerCase())
                ) || ALL_VJS[0];
              handleSelectVj(found);
            }}
          />
        )}

        {/* 12. DOWNLOADS TAB */}
        {currentPage === "downloads" && (
          <DownloadsPage
            userProfile={userProfile}
            onNavigateTab={handleNavigateTab}
            onLogout={() => setCurrentPage("splash")}
            onSelectMovie={handleSelectMovie}
            onNavigateToNotifications={handleNavigateToNotifications}
          />
        )}

        {/* 13. SPLASH SCREEN */}
        {currentPage === "splash" && (
          <SplashScreen
            onGetStarted={() => setCurrentPage("signup")}
            onLogIn={() => setCurrentPage("login")}
          />
        )}

        {/* 14. AUTH PAGES */}
        {(currentPage === "login" || currentPage === "signup") && (
          <AuthPage
            initialScreen={currentPage as AuthScreenType}
            onSuccess={handleAuthSuccess}
            onBackToSplash={() => setCurrentPage("splash")}
          />
        )}
      </div>

      {/* 15. AUTOMATIC APPEARING APP LAUNCH BANNER */}
      <AppLaunchBannerModal
        isOpen={
          showAppLaunchBanner &&
          (currentPage === "home" ||
            currentPage === "profile" ||
            currentPage === "search")
        }
        onClose={() => setShowAppLaunchBanner(false)}
      />
    </main>
  );
}
