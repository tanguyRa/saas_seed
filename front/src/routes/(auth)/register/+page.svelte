<script lang="ts">
	import { signUp } from '$lib/auth-client';
	import { goto } from '$app/navigation';
	import { t, tError } from '$lib/i18n/index.svelte';

	let name = $state('');
	let email = $state('');
	let password = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		loading = true;

		try {
			const result = await signUp.email({
				email,
				password,
				name
			});

			if (result.error) {
				error = tError(result.error.message, 'auth.register.errors.failed');
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
		<h1>{t('auth.register.title')}</h1>
		<p class="auth-subtitle">{t('auth.register.subtitle')}</p>
	</div>
</div>

{#if error}
	<div class="auth-error">{error}</div>
{/if}

<form onsubmit={handleSubmit}>
	<div class="form-group">
		<label for="name">{t('auth.fields.name')}</label>
		<input
			type="text"
			id="name"
			bind:value={name}
			required
			placeholder={t('auth.fields.namePlaceholder')}
		/>
	</div>

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
			minlength="8"
		/>
	</div>

	<button type="submit" class="btn btn-primary" disabled={loading}>
		{loading
			? t('auth.register.actions.creatingAccount')
			: t('auth.register.actions.createAccount')}
	</button>
</form>

<p class="auth-footer">
	{t('auth.register.footer.hasAccount')} <a href="/login">{t('auth.register.footer.signIn')}</a>
</p>
