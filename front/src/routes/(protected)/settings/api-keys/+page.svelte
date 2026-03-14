<script lang="ts">
    import { onMount } from "svelte";

    interface LLMKeysResponse {
        providers: string[];
        configured: Record<string, boolean>;
        hasSystemKey: boolean;
        defaultProvider: string;
    }

    // State
    let loading = $state(true);
    let keysData = $state<LLMKeysResponse | null>(null);
    let error = $state<string | null>(null);

    // Form state
    let selectedProvider = $state("anthropic");
    let apiKey = $state("");
    let saving = $state(false);
    let deleting = $state<string | null>(null);
    let message = $state<{ type: "success" | "error"; text: string } | null>(null);

    const providerInfo: Record<string, { name: string; url: string; placeholder: string }> = {
        anthropic: {
            name: "Anthropic (Claude)",
            url: "https://console.anthropic.com/settings/keys",
            placeholder: "sk-ant-api03-..."
        },
        openai: {
            name: "OpenAI",
            url: "https://platform.openai.com/api-keys",
            placeholder: "sk-..."
        },
        gemini: {
            name: "Google (Gemini)",
            url: "https://aistudio.google.com/apikey",
            placeholder: "AIza..."
        }
    };

    onMount(async () => {
        await fetchKeys();
    });

    async function fetchKeys() {
        loading = true;
        error = null;
        try {
            const res = await fetch("/api/llm-keys");
            if (!res.ok) throw new Error("Failed to fetch API keys status");
            keysData = await res.json();
        } catch (e) {
            error = e instanceof Error ? e.message : "An error occurred";
        } finally {
            loading = false;
        }
    }

    async function handleSaveKey() {
        if (!apiKey.trim()) {
            message = { type: "error", text: "API key is required" };
            return;
        }

        message = null;
        saving = true;

        try {
            const res = await fetch("/api/llm-keys", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    provider: selectedProvider,
                    apiKey: apiKey.trim()
                })
            });

            if (!res.ok) {
                const data = await res.json().catch(() => null);
                throw new Error(data?.error?.message || "Failed to save API key");
            }

            message = { type: "success", text: `${providerInfo[selectedProvider].name} API key saved successfully` };
            apiKey = "";
            await fetchKeys();
        } catch (e) {
            message = { type: "error", text: e instanceof Error ? e.message : "Failed to save API key" };
        } finally {
            saving = false;
        }
    }

    async function handleDeleteKey(provider: string) {
        if (!confirm(`Are you sure you want to remove your ${providerInfo[provider].name} API key?`)) {
            return;
        }

        message = null;
        deleting = provider;

        try {
            const res = await fetch(`/api/llm-keys/${provider}`, {
                method: "DELETE"
            });

            if (!res.ok) {
                throw new Error("Failed to delete API key");
            }

            message = { type: "success", text: `${providerInfo[provider].name} API key removed` };
            await fetchKeys();
        } catch (e) {
            message = { type: "error", text: e instanceof Error ? e.message : "Failed to delete API key" };
        } finally {
            deleting = null;
        }
    }

    function isConfigured(provider: string): boolean {
        return keysData?.configured[provider] ?? false;
    }
</script>

<div class="settings-page">
    <header class="settings-header">
        <h1>API Keys</h1>
        <p>Manage your LLM provider API keys for the chat agents</p>
    </header>

    {#if loading}
        <div class="loading-state">
            <div class="spinner spinner-dark"></div>
        </div>
    {:else if error}
        <div class="error-state">
            <p>{error}</p>
            <button class="btn btn-secondary" onclick={fetchKeys}>Try Again</button>
        </div>
    {:else}
        <div class="settings-sections">
            <!-- Current Keys Section -->
            <section class="settings-section">
                <div class="section-header">
                    <h2>Configured Providers</h2>
                    <p>Your API keys are encrypted and stored securely</p>
                </div>

                <div class="providers-list">
                    {#each keysData?.providers ?? [] as provider}
                        <div class="provider-item" class:configured={isConfigured(provider)}>
                            <div class="provider-info">
                                <span class="provider-name">{providerInfo[provider]?.name ?? provider}</span>
                                <span class="provider-status" class:active={isConfigured(provider)}>
                                    {isConfigured(provider) ? "Configured" : "Not configured"}
                                </span>
                            </div>
                            {#if isConfigured(provider)}
                                <button
                                    class="btn btn-danger btn-sm"
                                    onclick={() => handleDeleteKey(provider)}
                                    disabled={deleting === provider}
                                >
                                    {#if deleting === provider}
                                        <span class="spinner spinner-sm"></span>
                                    {/if}
                                    Remove
                                </button>
                            {/if}
                        </div>
                    {/each}
                </div>
            </section>

            <!-- Add Key Section -->
            <section class="settings-section">
                <div class="section-header">
                    <h2>Add API Key</h2>
                    <p>Add or update an API key for a provider</p>
                </div>

                <form
                    class="settings-form"
                    onsubmit={(e) => {
                        e.preventDefault();
                        handleSaveKey();
                    }}
                >
                    <div class="form-group">
                        <label for="provider">Provider</label>
                        <select id="provider" bind:value={selectedProvider}>
                            {#each keysData?.providers ?? [] as provider}
                                <option value={provider}>{providerInfo[provider]?.name ?? provider}</option>
                            {/each}
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="api-key">API Key</label>
                        <input
                            type="password"
                            id="api-key"
                            bind:value={apiKey}
                            placeholder={providerInfo[selectedProvider]?.placeholder ?? "Enter API key"}
                            autocomplete="off"
                        />
                        <span class="form-hint">
                            Get your API key from
                            <a href={providerInfo[selectedProvider]?.url} target="_blank" rel="noopener noreferrer">
                                {providerInfo[selectedProvider]?.name} Console
                            </a>
                        </span>
                    </div>

                    {#if message}
                        <div
                            class="message"
                            class:success={message.type === "success"}
                            class:error={message.type === "error"}
                        >
                            {message.text}
                        </div>
                    {/if}

                    <button type="submit" class="btn btn-primary" disabled={saving || !apiKey.trim()}>
                        {#if saving}
                            <span class="spinner spinner-sm"></span>
                        {/if}
                        {isConfigured(selectedProvider) ? "Update Key" : "Save Key"}
                    </button>
                </form>
            </section>

            <!-- Info Section -->
            <section class="settings-section info-section">
                <div class="section-header">
                    <h2>About API Keys</h2>
                </div>
                <div class="info-content">
                    <div class="info-item">
                        <span class="info-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                            </svg>
                        </span>
                        <div>
                            <strong>Encrypted Storage</strong>
                            <p>Your API keys are encrypted using AES-256-GCM before being stored.</p>
                        </div>
                    </div>
                    <div class="info-item">
                        <span class="info-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <path d="M12 16v-4"></path>
                                <path d="M12 8h.01"></path>
                            </svg>
                        </span>
                        <div>
                            <strong>Direct Billing</strong>
                            <p>You are billed directly by the provider (Anthropic, OpenAI, Google) for API usage.</p>
                        </div>
                    </div>
                    <div class="info-item">
                        <span class="info-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                            </svg>
                        </span>
                        <div>
                            <strong>Never Shared</strong>
                            <p>Your keys are only used to communicate with the LLM provider on your behalf.</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    {/if}
</div>

<style>
    .settings-page {
        padding: var(--spacing-xl);
        max-width: 800px;
    }

    .settings-header {
        margin-bottom: var(--spacing-2xl);
    }

    .settings-header h1 {
        font-size: var(--font-size-3xl);
        color: var(--color-text);
        margin-bottom: var(--spacing-sm);
    }

    .settings-header p {
        color: var(--color-text-muted);
        font-size: var(--font-size-lg);
    }

    .settings-sections {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xl);
    }

    .settings-section {
        background: var(--color-bg);
        border-radius: var(--radius-lg);
        padding: var(--spacing-xl);
        box-shadow: var(--shadow-sm);
    }

    .section-header {
        margin-bottom: var(--spacing-lg);
        padding-bottom: var(--spacing-md);
        border-bottom: 1px solid var(--color-border);
    }

    .section-header h2 {
        font-size: var(--font-size-xl);
        color: var(--color-text);
        margin-bottom: var(--spacing-xs);
    }

    .section-header p {
        color: var(--color-text-muted);
        font-size: var(--font-size-sm);
    }

    /* Providers List */
    .providers-list {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-sm);
    }

    .provider-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: var(--spacing-md);
        background: var(--color-bg-secondary);
        border-radius: var(--radius-md);
        border: 1px solid var(--color-border);
    }

    .provider-item.configured {
        border-color: var(--color-success);
        background: var(--color-success-bg);
    }

    .provider-info {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-xs);
    }

    .provider-name {
        font-weight: 500;
        color: var(--color-text);
    }

    .provider-status {
        font-size: var(--font-size-sm);
        color: var(--color-text-muted);
    }

    .provider-status.active {
        color: var(--color-success);
    }

    /* Form */
    .settings-form {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-md);
    }

    .settings-form .btn {
        align-self: flex-start;
        margin-top: var(--spacing-sm);
    }

    .form-hint a {
        color: var(--color-primary);
        text-decoration: none;
    }

    .form-hint a:hover {
        text-decoration: underline;
    }

    select {
        width: 100%;
        padding: var(--spacing-sm) var(--spacing-md);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-md);
        background: var(--color-bg);
        color: var(--color-text);
        font-size: var(--font-size-base);
        cursor: pointer;
    }

    select:focus {
        outline: none;
        border-color: var(--color-primary);
        box-shadow: 0 0 0 3px var(--color-primary-alpha);
    }

    /* Messages */
    .message {
        padding: var(--spacing-sm) var(--spacing-md);
        border-radius: var(--radius-md);
        font-size: var(--font-size-sm);
    }

    .message.success {
        background: var(--color-success-bg);
        color: var(--color-success);
        border: 1px solid var(--color-success-border);
    }

    .message.error {
        background: var(--color-error-bg);
        color: var(--color-error);
        border: 1px solid var(--color-error-border);
    }

    /* Info Section */
    .info-section .section-header {
        border-bottom: none;
        margin-bottom: var(--spacing-md);
        padding-bottom: 0;
    }

    .info-content {
        display: flex;
        flex-direction: column;
        gap: var(--spacing-md);
    }

    .info-item {
        display: flex;
        gap: var(--spacing-md);
        align-items: flex-start;
    }

    .info-icon {
        flex-shrink: 0;
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: var(--color-bg-secondary);
        border-radius: var(--radius-md);
        color: var(--color-text-secondary);
    }

    .info-item strong {
        display: block;
        color: var(--color-text);
        margin-bottom: var(--spacing-xs);
    }

    .info-item p {
        color: var(--color-text-muted);
        font-size: var(--font-size-sm);
        margin: 0;
    }

    /* Button variants */
    .btn-danger {
        background: var(--color-error);
        color: white;
        border: none;
    }

    .btn-danger:hover:not(:disabled) {
        background: var(--color-danger);
    }

    .btn-sm {
        padding: var(--spacing-xs) var(--spacing-sm);
        font-size: var(--font-size-sm);
    }

    /* Loading/Error states */
    .loading-state,
    .error-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: var(--spacing-3xl);
        gap: var(--spacing-md);
    }

    .error-state p {
        color: var(--color-error);
    }

    @media (max-width: 768px) {
        .settings-page {
            padding: var(--spacing-md);
        }

        .settings-section {
            padding: var(--spacing-lg);
        }

        .provider-item {
            flex-direction: column;
            align-items: flex-start;
            gap: var(--spacing-sm);
        }
    }
</style>
