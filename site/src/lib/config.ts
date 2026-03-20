import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(process.cwd(), '..');
const configPath = path.join(ROOT, 'research.config.json');

export interface ResearchConfig {
  subject: string;
  tagline: string;
  image: string;
  accent: string;
  author: {
    name: string;
    title: string;
    company: string;
    company_url: string;
    logo: string;
    github: string;
    email: string;
  };
  repo: string;
  site_url: string;
  timeline: { year: string; title: string; section: string; color?: string }[];
  videos: Record<string, { id: string; title: string; desc: string }[]>;
}

let _config: ResearchConfig | null = null;

export function getConfig(): ResearchConfig {
  if (!_config) {
    try {
      _config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
    } catch {
      _config = {
        subject: 'Research Subject',
        tagline: 'Autonomous research powered by Claude',
        image: '',
        accent: 'amber',
        author: { name: 'Author', title: '', company: '', company_url: '', logo: '', github: '', email: '' },
        repo: '',
        site_url: '',
        timeline: [],
        videos: {},
      };
    }
  }
  return _config!;
}
