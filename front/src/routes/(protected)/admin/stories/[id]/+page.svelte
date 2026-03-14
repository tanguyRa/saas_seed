<script lang="ts">
    import PipelineStep from "./PipelineStep.svelte";

    import { onMount } from "svelte";
    import { page } from "$app/stores";

    interface AdminFile {
        key: string;
        label: string;
        type: string;
    }

    interface AdminStep {
        id: string;
        title: string;
        status: string;
        files: AdminFile[];
    }

    interface AdminStoryDetail {
        content_id: string;
        title: string;
        steps: AdminStep[];
    }

    interface AdminStoryDetailResponse {
        story: AdminStoryDetail;
    }

    let story = $state<AdminStoryDetail | null>(null);
    let loading = $state(true);
    let error = $state<string | null>(null);
    let activeStepId = $state<string | null>(null);
    let activeFile = $state<AdminFile | null>(null);
    let fileContent = $state<string>("");
    let renderedContent = $derived(markdownToHtml(fileContent || ""));
    let groupedSteps = $derived(groupSteps(story?.steps ?? []));
    let fileLoading = $state(false);
    let rerunLoading = $state<string | null>(null);
    let linksByKey = $state<Record<string, string[]>>({});

    async function loadStory() {
        loading = true;
        error = null;
        const id = $page.params.id;
        try {
            const response = await fetch(`/api/admin/stories/${id}`);
            if (!response.ok) {
                throw new Error("Failed to load story");
            }
            const data = (await response.json()) as AdminStoryDetailResponse;
            story = data.story;
            activeStepId = story.steps[0]?.id || null;
            activeFile = story.steps[0]?.files?.[0] || null;
            await loadLinks(story.steps);
            if (activeFile) {
                await loadFile(activeFile);
            }
        } catch (err) {
            error = err instanceof Error ? err.message : "Failed to load story";
        } finally {
            loading = false;
        }
    }

    async function loadLinks(steps: AdminStep[]) {
        const linkFiles = steps.flatMap(
            (step) => step.files?.filter((file) => file.type === "links") ?? [],
        );
        await Promise.all(
            linkFiles.map(async (file) => {
                if (linksByKey[file.key]) return;
                try {
                    const response = await fetch(
                        `/api/admin/stories/${story?.content_id}/object?key=${encodeURIComponent(file.key)}`,
                    );
                    if (!response.ok) return;
                    const text = await response.text();
                    const parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) {
                        linksByKey = { ...linksByKey, [file.key]: parsed };
                    }
                } catch {
                    return;
                }
            }),
        );
    }

    async function loadFile(file: AdminFile, stepId?: string) {
        if (!story) return;
        activeStepId = stepId || activeStepId;
        activeFile = file;
        fileLoading = true;
        fileContent = "";
        try {
            const response = await fetch(
                `/api/admin/stories/${story.content_id}/object?key=${encodeURIComponent(file.key)}`,
            );
            if (!response.ok) {
                throw new Error("Failed to load file");
            }
            const text = await response.text();
            fileContent = formatContent(text, file.type);
        } catch (err) {
            fileContent =
                err instanceof Error ? err.message : "Failed to load file";
        } finally {
            fileLoading = false;
        }
    }

    function normalizeStep(stepId: string) {
        if (stepId === "extract_markdown") {
            return "extract_content";
        }
        return stepId;
    }

    async function rerunStep(step: AdminStep) {
        if (!story) return;
        const stepId = normalizeStep(step.id);
        rerunLoading = step.id;
        try {
            const response = await fetch(
                `/api/admin/stories/${story.content_id}/rerun`,
                {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ step: stepId }),
                },
            );
            if (!response.ok) {
                throw new Error("Failed to enqueue step");
            }
        } catch (err) {
            error =
                err instanceof Error ? err.message : "Failed to enqueue step";
        } finally {
            rerunLoading = null;
            loadFile(step.files?.[0], step.id);
        }
    }

    function formatContent(raw: string, type: string) {
        if (type === "metadata") {
            try {
                const parsed = JSON.parse(raw);
                return "```json\n" + JSON.stringify(parsed, null, 2) + "\n```";
            } catch {
                return raw;
            }
        }
        if (type === "links") {
            try {
                const parsed = JSON.parse(raw);
                return "```json\n" + JSON.stringify(parsed, null, 2) + "\n```";
            } catch {
                return raw;
            }
        }
        return raw;
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
            const items = buffer
                .map((item) => `<li>${inlineFormat(item)}</li>`)
                .join("");
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
                const level = Math.min(
                    trimmed.match(/^#+/)?.[0].length || 1,
                    3,
                );
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
            .replace(
                /\[([^\]]+)\]\(([^)]+)\)/g,
                '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>',
            );
    }

    function escapeHtml(input: string) {
        return input
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function groupSteps(steps: AdminStep[]) {
        const groups: {
            title: string;
            steps: AdminStep[];
            collapsible: boolean;
        }[] = [];
        const enriched = new Map<string, AdminStep[]>();

        for (const step of steps) {
            if (
                step.title.startsWith("Enriched") &&
                step.title.includes(" — ")
            ) {
                const label = step.title.split(" — ")[0];
                if (!enriched.has(label)) {
                    enriched.set(label, []);
                }
                enriched.get(label)?.push(step);
                continue;
            }
            groups.push({
                title: step.title,
                steps: [step],
                collapsible: false,
            });
        }

        for (const [title, items] of enriched.entries()) {
            groups.push({
                title,
                steps: items,
                collapsible: true,
            });
        }

        return groups;
    }

    onMount(loadStory);
</script>

<section class="admin-detail">
    {#if loading}
        <div class="centered-container">
            <p class="muted">Loading story...</p>
        </div>
    {:else if error}
        <div class="centered-container">
            <p class="error">{error}</p>
        </div>
    {:else if story}
        <div class="detail-layout">
            <aside class="subnav">
                <div class="subnav-header">
                    <a class="back-link" href="/admin/stories">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="18"
                            height="18"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        >
                            <polyline points="15 18 9 12 15 6"></polyline>
                        </svg>
                        <span>Back</span>
                    </a>
                    <span class="subnav-title">Pipeline</span>
                </div>

                {#each groupedSteps as group}
                    <div class="nav-section">
                        {#if group.collapsible}
                            <details class="nav-group">
                                <summary class="nav-group-title">
                                    {group.title}
                                </summary>
                                <div class="nav-group-body">
                                    {#each group.steps as step}
                                        <PipelineStep
                                            {step}
                                            {activeStepId}
                                            {rerunStep}
                                            {rerunLoading}
                                            {loadFile}
                                            {activeFile}
                                            {linksByKey}
                                        ></PipelineStep>
                                    {/each}
                                </div>
                            </details>
                        {:else}
                            {#each group.steps as step}
                                <PipelineStep
                                    {step}
                                    {activeStepId}
                                    {rerunStep}
                                    {rerunLoading}
                                    {loadFile}
                                    {activeFile}
                                    {linksByKey}
                                ></PipelineStep>
                            {/each}
                        {/if}
                    </div>
                {/each}
            </aside>

            <article class="content-column">
                <header class="title-bar">
                    <div>
                        <h1>{story.title}</h1>
                        <p>Content ID: {story.content_id}</p>
                    </div>
                </header>

                <div class="viewer">
                    {#if fileLoading}
                        <p class="muted">Loading file...</p>
                    {:else if activeFile}
                        <div class="viewer-header">
                            <h2>{activeFile.label}</h2>
                            {#if activeFile.type === "links"}
                                <div class="viewer-links">
                                    {#if linksByKey[activeFile.key]}
                                        {#each linksByKey[activeFile.key] as url}
                                            <a
                                                href={url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                            >
                                                {url}
                                            </a>
                                        {/each}
                                    {/if}
                                </div>
                            {:else}
                                <span>{activeFile.key}</span>
                            {/if}
                        </div>
                        <div class="viewer-body" class:loading={fileLoading}>
                            <div class="markdown">{@html renderedContent}</div>
                        </div>
                    {:else}
                        <p class="muted">Select a file to preview.</p>
                    {/if}
                </div>
            </article>
        </div>
    {/if}
</section>

<style>
    .admin-detail {
        width: 100%;
        height: 100vh;
        display: flex;
    }

    .centered-container {
        margin: auto;
        text-align: center;
    }

    .detail-layout {
        display: flex;
        width: 100%;
        height: 100%;
        align-items: stretch;
    }

    .subnav {
        width: 240px;
        background: var(--color-sand);
        border-right: 1px solid var(--color-border-light);
        padding: var(--spacing-sm) 0;
        display: flex;
        flex-direction: column;
        flex-shrink: 0;
        min-width: 0;
        overflow-y: auto;
    }

    .subnav-header {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
    }

    .subnav-title {
        font-size: var(--font-size-xs);
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: var(--color-text-muted);
        font-weight: 600;
        padding: var(--spacing-md);
    }

    .nav-group {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-sm);
    }

    .nav-group-title {
        font-size: var(--font-size-xs);
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: var(--color-text-muted);
        padding: var(--spacing-xs) var(--spacing-md);
        cursor: pointer;
        list-style: none;
    }

    .nav-group-title::-webkit-details-marker {
        display: none;
    }

    .nav-group-body {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
        padding-bottom: var(--spacing-sm);
    }

    .back-link {
        display: flex;
        align-items: center;
        gap: var(--spacing-xs);
        color: var(--color-text-muted);
        text-decoration: none;
        font-weight: 600;
        font-size: var(--font-size-sm);
    }

    .content-column {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-lg);
        min-width: 0;
        flex: 1;
        height: 100%;
        overflow-y: auto;
        padding: var(--spacing-xl);
        box-sizing: border-box;
    }

    .title-bar {
        background: var(--color-sand);
        border: 1px solid var(--color-border-light);
        border-radius: var(--radius-lg);
        padding: var(--spacing-md) var(--spacing-lg);
    }

    .title-bar h1 {
        margin: 0 0 var(--spacing-xs);
        font-size: var(--font-size-2xl);
    }

    .title-bar p {
        margin: 0;
        color: var(--color-text-muted);
        font-size: var(--font-size-sm);
    }

    .viewer {
        border-radius: var(--radius-xl);
        border: 1px solid var(--color-border);
        background: var(--color-surface);
        padding: var(--spacing-lg);
        display: flex;
        flex-direction: column;
        gap: var(--spacing-md);
        min-height: 520px;
    }

    .viewer-header h2 {
        margin: 0 0 var(--spacing-xs);
        font-size: var(--font-size-lg);
    }

    .viewer-header span {
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
        word-break: break-all;
    }

    .viewer-links {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
        margin-top: var(--spacing-xs);
    }

    .viewer-links a {
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
        text-decoration: none;
        word-break: break-word;
    }

    .viewer-links a:hover {
        color: var(--color-text);
        text-decoration: underline;
    }

    .markdown :global(h1),
    .markdown :global(h2),
    .markdown :global(h3) {
        font-family: var(--font-display);
        margin: var(--spacing-md) 0 var(--spacing-xs);
    }

    .markdown :global(p) {
        margin: 0 0 var(--spacing-md);
        line-height: 1.7;
    }

    .markdown :global(ul),
    .markdown :global(ol) {
        margin: 0 0 var(--spacing-md);
        padding-left: var(--spacing-lg);
    }

    .markdown :global(pre) {
        background: var(--color-bg-tertiary);
        padding: var(--spacing-md);
        border-radius: var(--radius-md);
        overflow-x: auto;
    }

    .markdown :global(code) {
        font-family: var(--font-mono);
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

    @media (max-width: 1024px) {
        .detail-layout {
            flex-direction: column;
        }

        .subnav {
            width: 100%;
            height: auto;
            border-right: none;
            border-bottom: 1px solid var(--color-border-light);
        }
    }
</style>
