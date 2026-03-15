<script lang="ts">
    import type { LayoutProps } from "./$types";
    import { signOut } from "$lib/auth-client";
    import LanguageSwitcher from "$lib/components/LanguageSwitcher.svelte";
    import { t } from "$lib/i18n/index.svelte";
    import { useUser, resetUserStore } from "$lib/stores/user.svelte";
    import { goto } from "$app/navigation";

    let { children }: LayoutProps = $props();

    const user = useUser();

    let sidebarCollapsed = $state(false);

    // Redirect to login if not authenticated
    $effect(() => {
        if (!user.state.isPending && !user.state.isAuthenticated) {
            goto("/login");
        }
    });

    // Load collapsed state from localStorage on mount
    $effect(() => {
        if (typeof window !== "undefined") {
            const stored = localStorage.getItem("sidebar-collapsed");
            if (stored !== null) {
                sidebarCollapsed = stored === "true";
            }
        }
    });

    // Persist collapsed state to localStorage
    function toggleSidebar() {
        sidebarCollapsed = !sidebarCollapsed;
        if (typeof window !== "undefined") {
            localStorage.setItem("sidebar-collapsed", String(sidebarCollapsed));
        }
    }

    async function handleLogout() {
        try {
            await signOut();
        } catch (e) {
            console.error("Logout error:", e);
        } finally {
            // Always reset store and redirect, even if signOut fails
            resetUserStore();
            goto("/");
        }
    }
</script>

{#if user.state.isPending || !user.state.isAuthenticated}
    <!-- Show loading while checking auth or redirecting -->
    <div class="loading-container">
        <div class="spinner spinner-dark"></div>
    </div>
{:else}
    <div class="app-layout" class:collapsed={sidebarCollapsed}>
        <aside class="sidebar">
            <div class="sidebar-header">
                <a href="/app" class="logo" aria-label="SaaS Seed home">
                    <span class="logo-mark"></span>
                    {#if !sidebarCollapsed}
                        <span class="logo-text">SaaS Seed</span>
                    {/if}
                </a>
                <button
                    class="toggle-btn"
                    onclick={toggleSidebar}
                    aria-label={t("protected.sidebar.toggle")}
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                    >
                        {#if sidebarCollapsed}
                            <polyline points="9 18 15 12 9 6"></polyline>
                        {:else}
                            <polyline points="15 18 9 12 15 6"></polyline>
                        {/if}
                    </svg>
                </button>
            </div>

            <nav class="sidebar-nav">
                <div class="nav-section"></div>

                <div class="nav-section nav-section-bottom">
                    <div class="sidebar-language">
                        <LanguageSwitcher />
                    </div>
                    <span class="nav-section-label"
                        >{sidebarCollapsed ? "" : t("protected.sidebar.settings")}</span
                    >
                    <a href="/settings/profile" class="nav-link">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        >
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"
                            ></path>
                            <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                        {#if !sidebarCollapsed}
                            <span>{t("protected.sidebar.profile")}</span>
                        {/if}
                    </a>
                    <a href="/settings/billing" class="nav-link">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        >
                            <rect
                                x="1"
                                y="4"
                                width="22"
                                height="16"
                                rx="2"
                                ry="2"
                            ></rect>
                            <line x1="1" y1="10" x2="23" y2="10"></line>
                        </svg>
                        {#if !sidebarCollapsed}
                            <span>{t("protected.sidebar.billing")}</span>
                        {/if}
                    </a>
                    <a href="/settings/api-keys" class="nav-link">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        >
                            <path
                                d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"
                            ></path>
                        </svg>
                        {#if !sidebarCollapsed}
                            <span>{t("protected.sidebar.apiKeys")}</span>
                        {/if}
                    </a>
                    <button
                        class="nav-link logout-btn"
                        onclick={handleLogout}
                        aria-label={t("protected.sidebar.logout")}
                    >
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        >
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"
                            ></path>
                            <polyline points="16 17 21 12 16 7"></polyline>
                            <line x1="21" y1="12" x2="9" y2="12"></line>
                        </svg>
                        {#if !sidebarCollapsed}
                            <span>{t("protected.sidebar.logout")}</span>
                        {/if}
                    </button>
                </div>
            </nav>
        </aside>

        <main class="main-content">
            {@render children()}
        </main>
    </div>
{/if}

<style>
    /* Loading State */
    .loading-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--color-bg-secondary);
    }

    /* App Layout */
    .app-layout {
        display: flex;
        height: 100vh;
    }

    /* Sidebar */
    .sidebar {
        width: 240px;
        height: 100%;
        background: var(--color-sand);
        border-right: 1px solid var(--color-border-light);
        display: flex;
        flex-direction: column;
        transition: width var(--transition-slow);
    }

    .app-layout.collapsed .sidebar {
        width: 72px;
    }

    .sidebar-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--spacing-lg);
        border-bottom: 1px solid var(--color-border-light);
    }

    .sidebar-header .logo {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        text-decoration: none;
        color: var(--color-ink);
        overflow: hidden;
    }

    .sidebar-header .logo-mark {
        width: 26px;
        height: 26px;
        background: var(--color-ink);
        clip-path: polygon(50% 0, 100% 50%, 50% 100%, 0 50%);
        position: relative;
        flex-shrink: 0;
    }

    .sidebar-header .logo-mark::after {
        content: "";
        position: absolute;
        inset: 6px;
        background: var(--color-primary);
        clip-path: polygon(50% 0, 100% 50%, 50% 100%, 0 50%);
    }

    .sidebar-header .logo-text {
        font-size: 1.05rem;
        font-weight: 700;
        letter-spacing: 0.02em;
        font-family: "Canela", "Iowan Old Style", "Palatino Linotype",
            "Book Antiqua", Palatino, serif;
        white-space: nowrap;
    }

    .toggle-btn {
        background: none;
        border: none;
        padding: var(--spacing-sm);
        border-radius: var(--radius-sm);
        cursor: pointer;
        color: var(--color-ink-soft);
        transition: all var(--transition-fast);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .toggle-btn:hover {
        background: var(--color-border-light);
        color: var(--color-ink);
    }

    .app-layout.collapsed .toggle-btn {
        margin-left: auto;
        margin-right: auto;
    }

    .app-layout.collapsed .sidebar-header {
        flex-direction: column;
        gap: var(--spacing-sm);
    }

    /* Sidebar Navigation */
    .sidebar-nav {
        flex: 1;
        display: flex;
        flex-direction: column;
        padding: var(--spacing-md);
        overflow-y: auto;
    }

    .nav-section {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
    }

    .nav-section-bottom {
        margin-top: auto;
        border-top: 1px solid var(--color-border-light);
        padding-top: var(--spacing-md);
    }

    .sidebar-language {
        display: flex;
        justify-content: flex-start;
        padding: 0 var(--spacing-sm);
        margin-bottom: var(--spacing-sm);
    }

    .nav-section-label {
        font-size: var(--font-size-xs);
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: var(--color-ink-soft);
        padding: var(--spacing-sm) var(--spacing-sm);
        min-height: 24px;
    }

    .nav-link {
        display: flex;
        align-items: center;
        gap: var(--spacing-md);
        padding: var(--spacing-sm) var(--spacing-md);
        border-radius: var(--radius-md);
        color: var(--color-ink-soft);
        text-decoration: none;
        font-weight: 500;
        transition: all var(--transition-fast);
        background: none;
        border: none;
        width: 100%;
        cursor: pointer;
        font-size: var(--font-size-base);
        font-family: var(--font-family);
    }

    .nav-link:hover {
        background: var(--color-border-light);
        color: var(--color-ink);
    }

    .nav-link svg {
        flex-shrink: 0;
    }

    .nav-link span {
        white-space: nowrap;
        overflow: hidden;
    }

    .app-layout.collapsed .nav-link {
        justify-content: center;
        padding: var(--spacing-sm);
    }

    .logout-btn {
        color: var(--color-error);
    }

    .logout-btn:hover {
        background: var(--color-error-bg);
        color: var(--color-error);
    }

    /* Main Content */
    .main-content {
        flex: 1;
        background: var(--color-bg-secondary);
        height: 100vh;
        transition: margin-left var(--transition-slow);
        overflow-y: auto;
    }

    /* Responsive */
    @media (max-width: 768px) {
        .sidebar {
            transform: translateX(-100%);
            width: 240px !important;
        }

        .main-content {
            margin-left: 0 !important;
        }
    }
</style>
