import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
import { getConfig } from './config';

const ROOT = path.resolve(process.cwd(), '..');
const SECTIONS_DIR = path.join(ROOT, 'sections');

function readFile(filepath: string): string {
  try { return fs.readFileSync(filepath, 'utf-8'); } catch { return ''; }
}

export interface SectionMeta {
  slug: string;
  name: string;
  file: string;
}

/** Parse sections dynamically from document.md links */
export function getSections(): SectionMeta[] {
  const doc = readFile(path.join(ROOT, 'document.md'));
  const sections: SectionMeta[] = [];
  const linkRegex = /^\s*-\s*\[([^\]]+)\]\(sections\/([^)]+)\)/gm;
  let match;
  while ((match = linkRegex.exec(doc)) !== null) {
    const name = match[1];
    const file = match[2];
    if (file === 'sources.md') continue; // sources handled separately
    const slug = file.replace('.md', '');
    sections.push({ slug, name, file });
  }
  return sections;
}

export function readSection(filename: string): string {
  return readFile(path.join(SECTIONS_DIR, filename));
}

export function getHeader() {
  const doc = readFile(path.join(ROOT, 'document.md'));
  const match = doc.match(/Coverage: (\S+) \| Tasks: (\S+) \| Sources: (\S+) \| Last updated: (\S+)/);
  if (match) return { coverage: match[1], tasks: match[2], sources: match[3], updated: match[4] };
  return { coverage: '0%', tasks: '0/0', sources: '0', updated: 'N/A' };
}

export function getScore() {
  try {
    const output = execSync('bash autoresearch.sh 2>&1', { cwd: ROOT }).toString();
    const lines = output.split('\n');
    return { score: lines[0].trim(), breakdown: lines[1] || '' };
  } catch {
    return { score: '0', breakdown: '' };
  }
}

export function getStatus() {
  try {
    return JSON.parse(readFile(path.join(ROOT, 'status.json')));
  } catch {
    return {};
  }
}

export function getChangelog(): string {
  return readFile(path.join(ROOT, 'changelog.md'));
}

export interface SourceEntry {
  number: number;
  tier: 1 | 2 | 3;
  text: string;
}

export function parseSources(): { entries: SourceEntry[]; raw: string } {
  const raw = readFile(path.join(SECTIONS_DIR, 'sources.md'));
  const entries: SourceEntry[] = [];
  let currentTier: 1 | 2 | 3 = 1;
  for (const line of raw.split('\n')) {
    if (line.startsWith('### Tier 1')) { currentTier = 1; continue; }
    if (line.startsWith('### Tier 2')) { currentTier = 2; continue; }
    if (line.startsWith('### Tier 3')) { currentTier = 3; continue; }
    const match = line.match(/^- \[(\d+)\]/);
    if (match) {
      let tier = currentTier;
      if (line.includes('Tier 1')) tier = 1;
      else if (line.includes('Tier 2')) tier = 2;
      else if (line.includes('Tier 3')) tier = 3;
      entries.push({ number: parseInt(match[1]), tier, text: line.replace(/^- /, '') });
    }
  }
  return { entries, raw };
}

export interface SectionStats {
  slug: string;
  name: string;
  words: number;
  citations: number[];
  subsections: string[];
  highConf: number;
  medConf: number;
  lowConf: number;
  readingMinutes: number;
  content: string;
}

export function getSectionStats(meta: SectionMeta): SectionStats {
  const content = readSection(meta.file);
  const words = content.split(/\s+/).filter(Boolean).length;
  const citationMatches = content.match(/\[(\d+)\]/g) || [];
  const citations = [...new Set(citationMatches.map(m => parseInt(m.replace(/[\[\]]/g, ''))))];
  const subsectionMatches = content.match(/^### .+$/gm) || [];
  const subsections = subsectionMatches.map(s => s.replace(/^### /, ''));
  const highConf = (content.match(/Confidence: HIGH/g) || []).length;
  const medConf = (content.match(/Confidence: MEDIUM/g) || []).length;
  const lowConf = (content.match(/Confidence: LOW/g) || []).length;
  return {
    slug: meta.slug, name: meta.name, words, citations, subsections,
    highConf, medConf, lowConf,
    readingMinutes: Math.ceil(words / 230),
    content,
  };
}

export interface SourceDashboard {
  total: { t1: number; t2: number; t3: number };
  bySection: { slug: string; name: string; t1: number; t2: number; t3: number }[];
}

export function getSourceDashboard(): SourceDashboard {
  const { entries } = parseSources();
  const tierMap = new Map(entries.map(e => [e.number, e.tier]));
  const total = { t1: 0, t2: 0, t3: 0 };
  for (const e of entries) {
    if (e.tier === 1) total.t1++;
    else if (e.tier === 2) total.t2++;
    else total.t3++;
  }
  const sections = getSections();
  const bySection = sections.map(meta => {
    const stats = getSectionStats(meta);
    let t1 = 0, t2 = 0, t3 = 0;
    for (const num of stats.citations) {
      const tier = tierMap.get(num);
      if (tier === 1) t1++;
      else if (tier === 2) t2++;
      else if (tier === 3) t3++;
    }
    return { slug: meta.slug, name: meta.name, t1, t2, t3 };
  });
  return { total, bySection };
}
