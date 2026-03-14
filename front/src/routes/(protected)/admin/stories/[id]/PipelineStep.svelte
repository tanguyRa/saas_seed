<script lang="ts">
    let {
        step,
        activeStepId,
        rerunStep,
        rerunLoading,
        loadFile,
        activeFile,
        linksByKey,
    } = $props();

    const linkFiles = $derived(
        step.files?.filter((file: { type: string }) => file.type === "links") ??
            [],
    );

    const stepLinks = $derived(
        linkFiles.flatMap(
            (file: { key: string }) => linksByKey?.[file.key] ?? [],
        ),
    );
</script>

<div class={`step ${step.id === activeStepId ? "active" : ""}`}>
    <div class="step-info">
        <p class="label">{step.title}</p>
        <span class={`status status-${step.status}`}
            >{step.status === "ready" ? "✓" : "⤬"}</span
        >
    </div>

    <div class="actions">
        <button
            class="icon-btn"
            title="Rerun step"
            onclick={() => rerunStep(step)}
            disabled={rerunLoading === step.id}
            aria-label="Rerun step"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
            >
                {#if rerunLoading === step.id}
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M12 6v6l4 2"></path>
                {:else}
                    <polyline points="23 4 23 10 17 10"></polyline>
                    <polyline points="1 20 1 14 7 14"></polyline>
                    <path d="M3.51 9a9 9 0 0 1 14.13-3.36L23 10"></path>
                    <path d="M20.49 15a9 9 0 0 1-14.13 3.36L1 14"></path>
                {/if}
            </svg>
        </button>
        {#if step.files && step.files.length > 0}
            {#each step.files as file}
                <button
                    class={`icon-btn ${activeFile?.key === file.key ? "active" : ""}`}
                    onclick={() => {
                        loadFile(file, step.id);
                    }}
                    aria-label="Open {file.name}"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="14"
                        height="14"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                    >
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"
                        ></path>
                        <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                </button>
            {/each}
        {/if}
    </div>
</div>

<style>
    .step {
        padding: 0.5em;
        border-left: 3px solid transparent;
        display: flex;
        flex-direction: column;
        gap: 0.2em;
        transition:
            background-color var(--transition-fast),
            border-left var(--transition-fast);
    }

    .step.active {
        background-color: var(--color-bg-secondary);
        border-left: 3px solid var(--color-primary);
    }

    .step .label {
        font-size: var(--font-size-xs);
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: var(--color-text-muted);
    }

    .step-info {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .status {
        padding: 2px 8px;
        border-radius: var(--radius-pill);
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        background: var(--color-bg-tertiary);
    }

    .status-ready {
        background: var(--color-success-bg);
        color: var(--color-success);
    }

    .status-pending {
        background: var(--color-warning-bg);
        color: var(--color-warning);
    }

    .actions {
        display: flex;
        align-items: center;
        gap: 0.5em;
        flex-wrap: wrap;
    }

    .link-list {
        display: flex;
        flex-direction: column;
        gap: 0.25em;
        padding-left: 0.25em;
    }

    .link-list a {
        font-size: var(--font-size-xs);
        color: var(--color-text-muted);
        text-decoration: none;
        word-break: break-word;
    }

    .link-list a:hover {
        color: var(--color-text);
        text-decoration: underline;
    }

    button.icon-btn {
        background: none;
        background-color: var(--color-bg-secondary);
        border: none;
        cursor: pointer;
        padding: 0.5em;
        border-radius: var(--radius-sm);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-ink-soft);
        transition:
            background-color var(--transition-fast),
            color var(--transition-fast);
    }

    button.icon-btn.active {
        background-color: var(--color-primary);
    }

    button.icon-btn:hover {
        background-color: var(--color-primary);
    }
</style>
