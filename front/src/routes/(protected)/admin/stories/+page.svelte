<script lang="ts">
    import { onMount } from "svelte";

    interface AdminStory {
        content_id: string;
        source_id: string;
        title: string;
        status: string;
        source_url?: string | null;
        created_at: string;
    }

    interface AdminStoriesResponse {
        stories: AdminStory[];
    }

    let stories = $state<AdminStory[]>([]);
    let loading = $state(true);
    let error = $state<string | null>(null);

    async function loadStories() {
        loading = true;
        error = null;
        try {
            const response = await fetch("/api/admin/stories");
            if (!response.ok) {
                throw new Error("Failed to load stories");
            }
            const data = (await response.json()) as AdminStoriesResponse;
            stories = data.stories || [];
        } catch (err) {
            error = err instanceof Error ? err.message : "Failed to load stories";
        } finally {
            loading = false;
        }
    }

    onMount(loadStories);
</script>

<section class="admin-wrapper">
    <header>
        <h1>Admin: Story pipeline</h1>
        <p>Inspect every story and debug each pipeline step.</p>
    </header>

    {#if loading}
        <p class="muted">Loading stories...</p>
    {:else if error}
        <p class="error">{error}</p>
    {:else if stories.length === 0}
        <p class="muted">No stories yet.</p>
    {:else}
        <div class="story-list">
            {#each stories as story}
                <a class="story-row" href={`/admin/stories/${story.content_id}`}>
                    <div>
                        <h3>{story.title}</h3>
                        {#if story.source_url}
                            <p>{story.source_url}</p>
                        {/if}
                    </div>
                    <div class="story-meta">
                        <span class={`status status-${story.status.toLowerCase()}`}>
                            {story.status}
                        </span>
                        <span>{new Date(story.created_at).toLocaleString()}</span>
                    </div>
                </a>
            {/each}
        </div>
    {/if}
</section>

<style>
    .admin-wrapper {
        max-width: 1100px;
        margin: 0 auto;
        padding: var(--spacing-2xl);
        display: flex;
        flex-direction: column;
        gap: var(--spacing-lg);
    }

    header h1 {
        font-size: var(--font-size-3xl);
        margin-bottom: var(--spacing-xs);
    }

    header p {
        color: var(--color-text-muted);
    }

    .story-list {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-md);
    }

    .story-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: var(--spacing-lg);
        padding: var(--spacing-lg);
        border-radius: var(--radius-xl);
        border: 1px solid var(--color-border);
        background: var(--color-surface);
        text-decoration: none;
        color: inherit;
        box-shadow: var(--shadow-sm);
        transition: transform var(--transition-fast), box-shadow var(--transition-base);
    }

    .story-row:hover {
        transform: translateY(-3px);
        box-shadow: var(--shadow-md);
    }

    .story-row h3 {
        margin: 0 0 var(--spacing-xs);
        font-size: var(--font-size-lg);
    }

    .story-row p {
        margin: 0;
        color: var(--color-text-muted);
        font-size: var(--font-size-sm);
        word-break: break-word;
    }

    .story-meta {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
        align-items: flex-end;
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
    }

    .status {
        padding: 2px 10px;
        border-radius: var(--radius-pill);
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        border: 1px solid transparent;
    }

    .status-ready {
        background: var(--color-success-bg);
        color: var(--color-success);
        border-color: var(--color-success-border);
    }

    .status-pending,
    .status-queued,
    .status-processing,
    .status-enriched,
    .status-fetched {
        background: var(--color-warning-bg);
        color: var(--color-warning);
        border-color: rgba(245, 158, 11, 0.3);
    }
</style>
