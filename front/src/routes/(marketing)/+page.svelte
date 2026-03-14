<script lang="ts">
    import { useSession } from "$lib/auth-client";
    import LanguageSwitcher from "$lib/components/LanguageSwitcher.svelte";
    import { t } from "$lib/i18n/index.svelte";

    const session = useSession();
</script>

<div class="landing">
    <header class="topbar">
        <a class="brand" href="/">SaaS Seed</a>
        <nav>
            <a href="#features">{t("landing.nav.features")}</a>
            <a href="/pricing">{t("landing.nav.pricing")}</a>
        </nav>
        <div class="actions">
            <LanguageSwitcher />
            {#if $session.data?.user}
                <a class="btn btn-ghost" href="/app">{t("landing.nav.openApp")}</a>
            {:else}
                <a class="btn btn-ghost" href="/login">{t("landing.nav.signIn")}</a>
            {/if}
            <a class="btn btn-primary" href="/register">{t("landing.nav.getStarted")}</a>
        </div>
    </header>

    <main>
        <section class="hero">
            <p class="eyebrow">{t("landing.hero.eyebrow")}</p>
            <h1>{t("landing.hero.title")}</h1>
            <p>{t("landing.hero.subtitle")}</p>
            <div class="hero-actions">
                <a class="btn btn-primary" href="/register">{t("landing.hero.primaryCta")}</a>
                <a class="btn btn-secondary" href="/pricing">{t("landing.hero.secondaryCta")}</a>
            </div>
        </section>

        <section id="features" class="features">
            <h2>{t("landing.features.title")}</h2>
            <p>{t("landing.features.subtitle")}</p>
            <div class="cards">
                <article class="card">
                    <h3>{t("landing.features.cards.i18n.title")}</h3>
                    <p>{t("landing.features.cards.i18n.body")}</p>
                </article>
                <article class="card">
                    <h3>{t("landing.features.cards.auth.title")}</h3>
                    <p>{t("landing.features.cards.auth.body")}</p>
                </article>
                <article class="card">
                    <h3>{t("landing.features.cards.billing.title")}</h3>
                    <p>{t("landing.features.cards.billing.body")}</p>
                </article>
            </div>
        </section>
    </main>

    <footer class="footer">
        <span>{t("landing.footer.text")}</span>
        <div>
            <a href="/pricing">{t("landing.footer.pricing")}</a>
            <a href="/login">{t("landing.footer.login")}</a>
            <a href="/register">{t("landing.footer.register")}</a>
        </div>
    </footer>
</div>

<style>
    .landing {
        min-height: 100vh;
        background: var(--color-bg);
        color: var(--color-text);
        display: grid;
        grid-template-rows: auto 1fr auto;
    }

    .topbar {
        max-width: var(--container-lg);
        margin: 0 auto;
        width: 100%;
        padding: var(--space-5) var(--space-6);
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: var(--space-4);
        flex-wrap: wrap;
    }

    .brand {
        font-weight: 700;
        font-size: var(--font-size-lg);
    }

    nav {
        display: flex;
        gap: var(--space-4);
        color: var(--color-text-muted);
    }

    .actions {
        display: flex;
        gap: var(--space-2);
        align-items: center;
    }

    main {
        max-width: var(--container-lg);
        margin: 0 auto;
        width: 100%;
        padding: var(--space-7) var(--space-6);
        display: grid;
        gap: var(--space-8);
    }

    .hero {
        max-width: 760px;
    }

    .eyebrow {
        color: var(--color-primary);
        font-weight: 600;
        margin-bottom: var(--space-2);
    }

    h1 {
        font-size: clamp(2rem, 6vw, 3.5rem);
        line-height: 1.1;
        margin-bottom: var(--space-4);
    }

    .hero p {
        color: var(--color-text-muted);
        max-width: 60ch;
    }

    .hero-actions {
        display: flex;
        gap: var(--space-3);
        margin-top: var(--space-5);
        flex-wrap: wrap;
    }

    .features h2 {
        margin-bottom: var(--space-2);
    }

    .features > p {
        color: var(--color-text-muted);
        margin-bottom: var(--space-5);
    }

    .cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: var(--space-4);
    }

    .card {
        padding: var(--space-5);
        background: var(--color-surface);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
    }

    .card h3 {
        margin-bottom: var(--space-2);
    }

    .card p {
        color: var(--color-text-muted);
    }

    .footer {
        max-width: var(--container-lg);
        margin: 0 auto;
        width: 100%;
        padding: var(--space-5) var(--space-6);
        border-top: 1px solid var(--color-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: var(--space-4);
        flex-wrap: wrap;
        color: var(--color-text-muted);
    }

    .footer div {
        display: flex;
        gap: var(--space-4);
    }

    @media (max-width: 768px) {
        .topbar {
            justify-content: center;
        }

        .actions {
            width: 100%;
            justify-content: center;
        }

        .footer {
            justify-content: center;
        }
    }
</style>
