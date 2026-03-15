<script lang="ts">
	import { signIn } from '$lib/auth-client';
	import { goto } from '$app/navigation';
	import { t, tError } from '$lib/i18n/index.svelte';

	let email = $state('');
	let password = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		loading = true;

		try {
			const result = await signIn.email({
				email,
				password
			});

			if (result.error) {
				error = tError(result.error.message, 'auth.login.errors.failed');
			} else {
				goto('/app');
			}
		} catch (err) {
			error = tError(err instanceof Error ? err.message : null, 'common.errors.unexpected');
		} finally {
			loading = false;
		}
	}
</script>

<div class="auth-header">
	<a href="/" class="auth-logo">SaaS Seed</a>
	<div>
		<h1>{t('auth.login.title')}</h1>
		<p class="auth-subtitle">{t('auth.login.subtitle')}</p>
	</div>
</div>

{#if error}
	<div class="auth-error">{error}</div>
{/if}

<form onsubmit={handleSubmit}>
	<div class="form-group">
		<label for="email">{t('auth.fields.email')}</label>
		<input
			type="email"
			id="email"
			bind:value={email}
			required
			placeholder={t('auth.fields.emailPlaceholder')}
		/>
	</div>

	<div class="form-group">
		<label for="password">{t('auth.fields.password')}</label>
		<input
			type="password"
			id="password"
			bind:value={password}
			required
			placeholder={t('auth.fields.passwordPlaceholder')}
		/>
	</div>

	<button type="submit" class="btn btn-primary" disabled={loading}>
		{loading ? t('auth.login.actions.signingIn') : t('auth.login.actions.signIn')}
	</button>
</form>

<p class="auth-footer">
	{t('auth.login.footer.noAccount')} <a href="/register">{t('auth.login.footer.signUp')}</a>
</p>
