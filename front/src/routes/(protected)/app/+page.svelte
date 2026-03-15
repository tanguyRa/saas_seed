<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { t } from "$lib/i18n/index.svelte";
    import { useUser } from "$lib/stores/user.svelte";

    interface SidebarItem {
        id: string;
        type: "link" | "newsletter";
        title: string;
        subtitle?: string | null;
        status: string;
        created_at: string;
        story_id?: string | null;
    }

    interface StoryItem {
        id: string;
        type: "pipeline" | "newsletter";
        title: string;
        summary: string;
        topics: string[];
        created_at: string;
        read_minutes: number;
        source_url?: string | null;
    }

    interface LibraryResponse {
        sidebar_items: SidebarItem[];
        stories: StoryItem[];
    }

    interface NewsletterInboxResponse {
        address: string;
    }

    const user = useUser();

    let linkInput = $state("");
    let savingLinks = $state(false);
    let errorLinks = $state<string | null>(null);

    let inboxAddress = $state<string | null>(null);
    let loadingInbox = $state(true);
    let errorInbox = $state<string | null>(null);
    let copied = $state(false);

    let sidebarItems = $state<SidebarItem[]>([]);
    let stories = $state<StoryItem[]>([]);
    let libraryLoading = $state(true);
    let libraryRefreshing = $state(false);
    let libraryError = $state<string | null>(null);

    let refreshTimer: ReturnType<typeof setInterval> | null = null;

    const isPremium = $derived(user.state.hasActiveSubscription);

    async function loadLibrary(options: { silent?: boolean } = {}) {
        if (!options.silent) {
            libraryLoading = true;
        } else {
            libraryRefreshing = true;
        }
        libraryError = null;
        try {
            const response = await fetch("/api/library");
            if (!response.ok) {
                throw new Error(t("dashboard.errors.loadActivity"));
            }
            const data = (await response.json()) as LibraryResponse;
            sidebarItems = data.sidebar_items || [];
            stories = data.stories || [];
        } catch (err) {
            libraryError = err instanceof Error ? err.message : t("dashboard.errors.loadActivity");
        } finally {
            libraryLoading = false;
            libraryRefreshing = false;
        }
    }

    async function loadInbox() {
        loadingInbox = true;
        try {
            const response = await fetch("/api/newsletters/inbox");
            if (!response.ok) {
                throw new Error(t("dashboard.errors.loadInbox"));
            }
            const data = (await response.json()) as NewsletterInboxResponse;
            inboxAddress = data.address;
        } catch (err) {
            errorInbox = err instanceof Error ? err.message : t("dashboard.errors.loadInbox");
        } finally {
            loadingInbox = false;
        }
    }

    async function saveLinks() {
        const urls = linkInput
            .split(/\s+/)
            .map((value) => value.trim())
            .filter(Boolean);

        if (urls.length === 0) {
            errorLinks = t("dashboard.errors.addOneUrl");
            return;
        }

        savingLinks = true;
        errorLinks = null;
        try {
            const response = await fetch("/api/links", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ urls })
            });
            if (!response.ok) {
                throw new Error(t("dashboard.errors.saveLinks"));
            }
            linkInput = "";
            await loadLibrary();
        } catch (err) {
            errorLinks = err instanceof Error ? err.message : t("dashboard.errors.saveLinks");
        } finally {
            savingLinks = false;
        }
    }

    async function copyInbox() {
        if (!inboxAddress) return;
        try {
            await navigator.clipboard.writeText(inboxAddress);
            copied = true;
            setTimeout(() => (copied = false), 2000);
        } catch {
            errorInbox = t("dashboard.errors.copyInbox");
        }
    }

    function statusLabel(status: string) {
        const normalized = status.toLowerCase();
        if (normalized === "ready" || normalized === "completed") return t("dashboard.status.ready");
        if (normalized === "enriched") return t("dashboard.status.enriching");
        if (normalized === "processing") return t("dashboard.status.processing");
        if (normalized === "fetched") return t("dashboard.status.extracted");
        if (normalized === "queued") return t("dashboard.status.queued");
        if (normalized === "failed") return t("dashboard.status.failed");
        return status;
    }

    function storyTypeLabel(type: "pipeline" | "newsletter"): string {
        return type === "pipeline" ? t("dashboard.labels.article") : t("dashboard.labels.newsletter");
    }

    onMount(() => {
        loadInbox();
        loadLibrary();
        refreshTimer = setInterval(() => loadLibrary({ silent: true }), 5000);
        return () => {
            if (refreshTimer) {
                clearInterval(refreshTimer);
            }
        };
    });

    onDestroy(() => {
        if (refreshTimer) {
            clearInterval(refreshTimer);
        }
    });
</script>

<div class="dashboard">
    <header class="dashboard-header">
        <div class="header-content">
            <h1>{t("dashboard.header.welcome")} {user.state.user?.name || t("dashboard.header.userFallback")}</h1>
            {#if !isPremium}
                <span class="tier-badge free">{t("dashboard.header.freePlan")}</span>
            {:else}
                <span class="tier-badge premium">{t("dashboard.header.premiumPlan")}</span>
            {/if}
        </div>
        <div class="header-status">
            <span class:active={libraryRefreshing} class="pulse"></span>
            <span>{libraryRefreshing ? t("dashboard.header.syncing") : t("dashboard.header.live")}</span>
        </div>
    </header>

    <div class="library-layout">
        <aside class="activity-panel">
            <div class="panel-card">
                <div class="panel-header">
                    <div>
                        <h2>{t("dashboard.links.title")}</h2>
                        <p>{t("dashboard.links.subtitle")}</p>
                    </div>
                </div>
                <textarea
                    bind:value={linkInput}
                    rows="4"
                    placeholder={t("dashboard.links.placeholder")}
                ></textarea>
                <button class="btn-primary" onclick={saveLinks} disabled={savingLinks}>
                    {savingLinks ? t("dashboard.links.saving") : t("dashboard.links.save")}
                </button>
                {#if errorLinks}
                    <p class="error">{errorLinks}</p>
                {/if}
            </div>

            <div class="panel-card inbox">
                <div class="panel-header">
                    <div>
                        <h2>{t("dashboard.inbox.title")}</h2>
                        <p>{t("dashboard.inbox.subtitle")}</p>
                    </div>
                </div>
                <div class="inbox-card">
                    {#if loadingInbox}
                        <span class="muted">{t("dashboard.inbox.loading")}</span>
                    {:else if inboxAddress}
                        <span class="address">{inboxAddress}</span>
                        <button class="btn-secondary" onclick={copyInbox}>
                            {copied ? t("dashboard.inbox.copied") : t("dashboard.inbox.copy")}
                        </button>
                    {:else if errorInbox}
                        <span class="error">{errorInbox}</span>
                    {:else}
                        <span class="muted">{t("dashboard.inbox.unavailable")}</span>
                    {/if}
                </div>
            </div>

            <div class="panel-card activity">
                <div class="panel-header">
                    <div>
                        <h2>{t("dashboard.activity.title")}</h2>
                        <p>{t("dashboard.activity.subtitle")}</p>
                    </div>
                </div>

                {#if libraryLoading}
                    <p class="muted">{t("dashboard.activity.loading")}</p>
                {:else if sidebarItems.length === 0}
                    <p class="muted">{t("dashboard.activity.empty")}</p>
                {:else}
                    <ul class="activity-list">
                        {#each sidebarItems as item}
                            <li class="activity-item">
                                <div class="activity-title">
                                    {#if item.story_id}
                                        <a href={`/stories/${item.story_id}?type=pipeline`}>{item.title}</a>
                                    {:else}
                                        <span>{item.title}</span>
                                    {/if}
                                    <span class={`status-pill status-${item.status.toLowerCase()}`}>
                                        {statusLabel(item.status)}
                                    </span>
                                </div>
                                {#if item.subtitle}
                                    <p class="activity-subtitle">{item.subtitle}</p>
                                {/if}
                                <div class="activity-meta">
                                    <span class="type-pill">{item.type === "link" ? t("dashboard.labels.link") : t("dashboard.labels.newsletter")}</span>
                                    <span>{new Date(item.created_at).toLocaleString()}</span>
                                </div>
                            </li>
                        {/each}
                    </ul>
                {/if}
            </div>
        </aside>

        <section class="stories-panel">
            <div class="stories-header">
                <div>
                    <h2>{t("dashboard.stories.title")}</h2>
                    <p>{t("dashboard.stories.subtitle")}</p>
                </div>
            </div>

            {#if libraryError}
                <p class="error">{libraryError}</p>
            {:else if stories.length === 0}
                <div class="empty-state">
                    <h3>{t("dashboard.stories.emptyTitle")}</h3>
                    <p>{t("dashboard.stories.emptyBody")}</p>
                </div>
            {:else}
                <div class="story-grid">
                    {#each stories as story}
                        <a class="story-card" href={`/stories/${story.id}?type=${story.type}`}>
                            <div class="story-card-header">
                                <span class={`type-pill type-${story.type}`}>
                                    {storyTypeLabel(story.type)}
                                </span>
                                <span class="read-time">{story.read_minutes} {t("dashboard.stories.minRead")}</span>
                            </div>
                            <h3>{story.title}</h3>
                            <p>{story.summary}</p>
                            {#if story.topics?.length}
                                <div class="story-topics">
                                    {#each story.topics.slice(0, 3) as topic}
                                        <span>{topic}</span>
                                    {/each}
                                </div>
                            {/if}
                            <div class="story-footer">
                                <span>{new Date(story.created_at).toLocaleDateString()}</span>
                                <span class="cta">{t("dashboard.stories.read")}</span>
                            </div>
                        </a>
                    {/each}
                </div>
            {/if}
        </section>
    </div>
</div>

<style>
    .dashboard {
        padding: var(--spacing-2xl);
        max-width: 1280px;
        margin: 0 auto;
    }

    .dashboard-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: var(--spacing-2xl);
    }

    .header-content {
        display: flex;
        align-items: center;
        gap: var(--spacing-md);
    }

    .dashboard-header h1 {
        font-size: var(--font-size-2xl);
        font-weight: 600;
        color: var(--color-text);
    }

    .tier-badge {
        padding: var(--spacing-xs) var(--spacing-sm);
        border-radius: var(--radius-full);
        font-size: var(--font-size-xs);
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .tier-badge.free {
        background: var(--color-bg-tertiary);
        color: var(--color-text-muted);
    }

    .tier-badge.premium {
        background: var(--gradient-primary);
        color: white;
    }

    .header-status {
        display: flex;
        align-items: center;
        gap: var(--spacing-xs);
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
    }

    .pulse {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: var(--color-success);
        display: inline-block;
        box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.6);
    }

    .pulse.active {
        animation: pulse 1.4s infinite;
    }

    @keyframes pulse {
        0% {
            box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.6);
        }
        70% {
            box-shadow: 0 0 0 8px rgba(16, 185, 129, 0);
        }
        100% {
            box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
        }
    }

    .library-layout {
        display: grid;
        grid-template-columns: minmax(280px, 340px) minmax(0, 1fr);
        gap: var(--spacing-2xl);
    }

    .activity-panel {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-lg);
        position: sticky;
        top: 24px;
        align-self: start;
    }

    .panel-card {
        background: var(--color-bg-secondary);
        border-radius: var(--radius-xl);
        border: 1px solid var(--color-border);
        padding: var(--spacing-lg);
        box-shadow: var(--shadow-sm);
        display: flex;
        flex-direction: column;
        gap: var(--spacing-sm);
    }

    .panel-header h2 {
        font-size: var(--font-size-lg);
        margin-bottom: var(--spacing-xs);
    }

    .panel-header p {
        color: var(--color-text-muted);
        font-size: var(--font-size-sm);
    }

    textarea {
        width: 100%;
        padding: var(--spacing-sm);
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
        background: var(--color-bg);
        color: var(--color-text);
        resize: vertical;
        min-height: 110px;
    }

    .inbox-card {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: var(--spacing-sm);
        padding: var(--spacing-sm);
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
        background: var(--color-bg);
    }

    .address {
        font-family: var(--font-mono);
        font-size: var(--font-size-xs);
        color: var(--color-text);
        word-break: break-all;
    }

    .activity {
        max-height: 420px;
    }

    .activity-list {
        list-style: none;
        padding: 0;
        margin: 0;
        display: grid;
        gap: var(--spacing-sm);
        overflow: auto;
    }

    .activity-item {
        padding: var(--spacing-sm);
        border-radius: var(--radius-lg);
        border: 1px solid var(--color-border);
        background: var(--color-bg);
        display: grid;
        gap: var(--spacing-xs);
    }

    .activity-title {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: var(--spacing-sm);
        font-weight: 600;
        color: var(--color-text);
    }

    .activity-title a {
        color: var(--color-text);
        text-decoration: none;
    }

    .activity-title a:hover {
        color: var(--color-primary);
    }

    .activity-subtitle {
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
        word-break: break-all;
    }

    .activity-meta {
        display: flex;
        justify-content: space-between;
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
    }

    .status-pill {
        padding: 2px 8px;
        border-radius: var(--radius-pill);
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        border: 1px solid transparent;
    }

    .status-ready {
        background: var(--color-success-bg);
        color: var(--color-success);
        border-color: var(--color-success-border);
    }

    .status-enriched,
    .status-processing,
    .status-fetched,
    .status-queued {
        background: var(--color-warning-bg);
        color: var(--color-warning);
        border-color: rgba(245, 158, 11, 0.3);
    }

    .status-failed {
        background: var(--color-danger-bg);
        color: var(--color-danger);
        border-color: var(--color-danger-border);
    }

    .type-pill {
        padding: 2px 8px;
        border-radius: var(--radius-pill);
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        background: var(--color-bg-tertiary);
    }

    .type-pipeline {
        background: rgba(255, 107, 53, 0.15);
        color: var(--color-primary);
    }

    .type-newsletter {
        background: rgba(14, 116, 144, 0.15);
        color: #0e7490;
    }

    .stories-panel {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-lg);
    }

    .stories-header h2 {
        font-size: var(--font-size-2xl);
        margin-bottom: var(--spacing-xs);
    }

    .stories-header p {
        color: var(--color-text-muted);
    }

    .story-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: var(--spacing-lg);
    }

    .story-card {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-sm);
        padding: var(--spacing-lg);
        border-radius: var(--radius-xl);
        border: 1px solid var(--color-border);
        background: var(--color-surface);
        box-shadow: var(--shadow-sm);
        text-decoration: none;
        color: inherit;
        transition: transform var(--transition-fast), box-shadow var(--transition-base);
    }

    .story-card:hover {
        transform: translateY(-4px);
        box-shadow: var(--shadow-md);
    }

    .story-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
    }

    .read-time {
        font-weight: 600;
    }

    .story-card h3 {
        font-size: var(--font-size-lg);
        margin: 0;
        color: var(--color-text);
    }

    .story-card p {
        font-size: var(--font-size-sm);
        color: var(--color-text-muted);
        line-height: 1.5;
    }

    .story-topics {
        display: flex;
        flex-wrap: wrap;
        gap: var(--spacing-xs);
    }

    .story-topics span {
        padding: 2px 8px;
        border-radius: var(--radius-pill);
        font-size: 10px;
        background: var(--color-bg-tertiary);
        color: var(--color-text-muted);
    }

    .story-footer {
        display: flex;
        justify-content: space-between;
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
        margin-top: auto;
    }

    .cta {
        color: var(--color-primary);
        font-weight: 600;
    }

    .btn-secondary {
        padding: var(--spacing-xs) var(--spacing-sm);
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
        background: var(--color-bg-secondary);
        color: var(--color-text);
        cursor: pointer;
    }

    .empty-state {
        border: 1px dashed var(--color-border);
        border-radius: var(--radius-lg);
        padding: var(--spacing-xl);
        text-align: center;
        background: var(--color-bg-secondary);
    }

    @media (max-width: 1024px) {
        .library-layout {
            grid-template-columns: 1fr;
        }

        .activity-panel {
            position: static;
        }
    }
</style>
