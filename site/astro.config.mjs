// @ts-check
import { defineConfig } from 'astro/config';
import svelte from '@astrojs/svelte';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import fs from 'node:fs';
import path from 'node:path';

// Read config to get site URL
let siteUrl = 'https://example.github.io';
let basePath = '/autoresearch-starter';
try {
  const config = JSON.parse(fs.readFileSync(path.resolve('..', 'research.config.json'), 'utf-8'));
  if (config.site_url) {
    const url = new URL(config.site_url);
    siteUrl = `${url.protocol}//${url.host}`;
    basePath = url.pathname.replace(/\/$/, '') || '/';
  }
} catch { /* use defaults */ }

export default defineConfig({
  site: siteUrl,
  base: basePath,
  integrations: [svelte(), sitemap()],
  outDir: '../docs',
  build: { assets: '_assets' },
  vite: {
    plugins: [tailwindcss()],
  },
});
