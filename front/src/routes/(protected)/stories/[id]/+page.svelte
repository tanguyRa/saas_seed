<script lang="ts">
    import { onMount } from "svelte";
    import { page } from "$app/stores";

    interface StoryDetail {
        id: string;
        type: string;
        title: string;
        summary: string;
        topics: string[];
        content: string;
        created_at: string;
    }

    let story = $state<StoryDetail | null>(null);
    let loading = $state(true);
    let error = $state<string | null>(null);
    let renderedContent = $state("");

    async function loadStory() {
        loading = true;
        error = null;
        const id = $page.params.id;
        const type = $page.url.searchParams.get("type") || "pipeline";
        try {
            const response = await fetch(`/api/stories/${id}?type=${type}`);
            if (!response.ok) {
                throw new Error("Failed to load story");
            }
            story = (await response.json()) as StoryDetail;
            renderedContent = story ? markdownToHtml(story.content) : "";
        } catch (err) {
            error = err instanceof Error ? err.message : "Failed to load story";
        } finally {
            loading = false;
        }
    }

    function markdownToHtml(input: string) {
        const sanitized = escapeHtml(input);
        const parts = sanitized.split("```");
        const rendered = parts.map((part, index) => {
            if (index % 2 === 1) {
                return `<pre><code>${part.trim()}</code></pre>`;
            }
            return renderBlocks(part);
        });
        return rendered.join("");
    }

    function renderBlocks(input: string) {
        const lines = input.split("\n");
        const blocks: string[] = [];
        let buffer: string[] = [];
        let listType: "ul" | "ol" | null = null;

        const flushParagraph = () => {
            if (buffer.length === 0) return;
            const text = inlineFormat(buffer.join(" ").trim());
            if (text) {
                blocks.push(`<p>${text}</p>`);
            }
            buffer = [];
        };

        const flushList = () => {
            if (!listType || buffer.length === 0) return;
            const items = buffer.map((item) => `<li>${inlineFormat(item)}</li>`).join("");
            blocks.push(`<${listType}>${items}</${listType}>`);
            buffer = [];
            listType = null;
        };

        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed) {
                flushList();
                flushParagraph();
                continue;
            }

            if (trimmed.startsWith("#")) {
                flushList();
                flushParagraph();
                const level = Math.min(trimmed.match(/^#+/)?.[0].length || 1, 3);
                const heading = trimmed.replace(/^#+\s*/, "");
                blocks.push(`<h${level}>${inlineFormat(heading)}</h${level}>`);
                continue;
            }

            const unorderedMatch = trimmed.match(/^[-*]\s+(.*)$/);
            if (unorderedMatch) {
                flushParagraph();
                if (listType && listType !== "ul") {
                    flushList();
                }
                listType = "ul";
                buffer.push(unorderedMatch[1]);
                continue;
            }

            const orderedMatch = trimmed.match(/^\d+\.\s+(.*)$/);
            if (orderedMatch) {
                flushParagraph();
                if (listType && listType !== "ol") {
                    flushList();
                }
                listType = "ol";
                buffer.push(orderedMatch[1]);
                continue;
            }

            if (listType) {
                flushList();
            }
            buffer.push(trimmed);
        }

        flushList();
        flushParagraph();
        return blocks.join("");
    }

    function inlineFormat(input: string) {
        return input
            .replace(/`([^`]+)`/g, "<code>$1</code>")
            .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
            .replace(/\*([^*]+)\*/g, "<em>$1</em>")
            .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
    }

    function escapeHtml(input: string) {
        return input
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    onMount(loadStory);
</script>

<section class="story-reader">
    <a class="back-link" href="/app">← Back to library</a>

    {#if loading}
        <div class="reader-card"><p class="muted">Loading story...</p></div>
    {:else if error}
        <div class="reader-card"><p class="error">{error}</p></div>
    {:else if story}
        <div class="reader-header">
            <h1>{story.title}</h1>
            <p>{story.summary}</p>
            {#if story.topics?.length}
                <div class="topic-row">
                    {#each story.topics as topic}
                        <span>{topic}</span>
                    {/each}
                </div>
            {/if}
            <span class="meta">{new Date(story.created_at).toLocaleString()}</span>
        </div>
        <article class="reader-card">
            <div class="markdown">{@html renderedContent}</div>
        </article>
    {/if}
</section>

<style>
    .story-reader {
        max-width: 900px;
        margin: 0 auto;
        padding: var(--spacing-2xl) var(--spacing-xl);
        display: flex;
        flex-direction: column;
        gap: var(--spacing-lg);
    }

    .back-link {
        color: var(--color-text-muted);
        text-decoration: none;
        font-size: var(--font-size-sm);
    }

    .back-link:hover {
        color: var(--color-primary);
    }

    .reader-header {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-sm);
    }

    .reader-header h1 {
        font-size: var(--font-size-3xl);
        margin: 0;
        font-family: var(--font-display);
    }

    .reader-header p {
        color: var(--color-text-muted);
        font-size: var(--font-size-lg);
    }

    .topic-row {
        display: flex;
        flex-wrap: wrap;
        gap: var(--spacing-xs);
    }

    .topic-row span {
        padding: 4px 10px;
        border-radius: var(--radius-pill);
        background: var(--color-bg-tertiary);
        font-size: var(--font-size-xs);
    }

    .meta {
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
    }

    .reader-card {
        background: var(--color-surface);
        border-radius: var(--radius-xl);
        border: 1px solid var(--color-border);
        padding: var(--spacing-xl);
        box-shadow: var(--shadow-sm);
    }

    .markdown :global(h1),
    .markdown :global(h2),
    .markdown :global(h3) {
        font-family: var(--font-display);
        margin: var(--spacing-lg) 0 var(--spacing-sm);
    }

    .markdown :global(h1) {
        font-size: var(--font-size-2xl);
    }

    .markdown :global(h2) {
        font-size: var(--font-size-xl);
    }

    .markdown :global(h3) {
        font-size: var(--font-size-lg);
    }

    .markdown :global(p) {
        margin: 0 0 var(--spacing-md);
        line-height: 1.7;
        color: var(--color-text);
    }

    .markdown :global(ul),
    .markdown :global(ol) {
        margin: 0 0 var(--spacing-md);
        padding-left: var(--spacing-lg);
        color: var(--color-text);
    }

    .markdown :global(li) {
        margin-bottom: var(--spacing-xs);
    }

    .markdown :global(pre) {
        padding: var(--spacing-md);
        border-radius: var(--radius-md);
        background: var(--color-bg-tertiary);
        overflow-x: auto;
        margin-bottom: var(--spacing-md);
    }

    .markdown :global(code) {
        font-family: var(--font-mono);
        font-size: var(--font-size-sm);
        background: var(--color-bg-tertiary);
        padding: 2px 6px;
        border-radius: var(--radius-sm);
    }

    .markdown :global(pre code) {
        background: none;
        padding: 0;
    }

    .markdown :global(a) {
        color: var(--color-primary);
        text-decoration: none;
    }

    .markdown :global(a:hover) {
        text-decoration: underline;
    }
</style>
