#!/usr/bin/env node
// Checks whether the upstream sources of a plugin's skills have moved past the
// versions the skills were verified against, and whether a project pins a
// version that differs from them.
//
// Each skill lists its sources in a sources.json next to its SKILL.md (the
// format is in the plugin README). Two checks run:
//
// - Upstream: list the tags of each source repo with `gh api`, keep the tags
//   that match `tagPattern`, and compare the newest one with `verified`. The
//   result is cached for a day. A failure (no gh, no auth, offline) gives the
//   status "unknown", never an error.
// - Project pin (with --project): read the version the project uses from its
//   node_modules, lockfile, or package.json, or from a `pinFiles` entry such as
//   `version:` in deploy.yaml, and compare it with `verified`. This needs no
//   network.
//
// The script only reports. It never opens an issue; --issue-draft prints a
// title and body for the user to review.
//
// Usage: node check-drift.mjs [paths...] [--skill <name>] [--project <dir>]
//          [--offline] [--refresh] [--max-age <hours>] [--cache-dir <dir>]
//          [--json] [--issue-draft <skill>]
//
// With no paths, it checks the skills of the plugin that holds this script.
// A path can be a sources.json file or a directory to search.

import { execFile } from 'node:child_process'
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { homedir, tmpdir } from 'node:os'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const SEMVER = /^(\d+)\.(\d+)\.(\d+)$/
const GH_TIMEOUT_MS = 30_000
const CACHE_FILE = 'drift-cache.json'

// ---------------------------------------------------------------------------
// Versions

/** Parses `X.Y.Z` into numbers, or returns undefined. */
export function parseVersion(text) {
  const m = SEMVER.exec(String(text ?? '').trim())
  return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : undefined
}

/** Compares two `X.Y.Z` strings: negative, zero, or positive. */
export function compareVersions(a, b) {
  const va = parseVersion(a)
  const vb = parseVersion(b)
  if (!va || !vb) throw new Error(`not an X.Y.Z version: ${!va ? a : b}`)
  for (let i = 0; i < 3; i++) if (va[i] !== vb[i]) return va[i] - vb[i]
  return 0
}

/**
 * Keeps the tags that match `tagPattern` and returns a map from version to
 * tag name. The first capture group of the pattern must hold `X.Y.Z`; a tag
 * whose capture is not a plain version is skipped.
 */
export function matchTags(tags, tagPattern) {
  const re = new RegExp(tagPattern)
  const versions = {}
  for (const tag of tags) {
    const m = re.exec(tag)
    if (m && parseVersion(m[1])) versions[m[1]] = tag
  }
  return versions
}

/** Returns the highest version in a list, or undefined for an empty list. */
export function highestVersion(versions) {
  return versions.reduce((best, v) => (!best || compareVersions(v, best) > 0 ? v : best), undefined)
}

/**
 * Classifies the gap from `verified` to `latest`:
 *
 * - breaking: a major bump, or a minor bump while the major is 0;
 * - additive: a minor bump on 1.0 or later;
 * - info: a patch bump;
 * - current: no newer release.
 *
 * `recommendIssue` is true for breaking drift, and for additive drift more
 * than one minor behind. A source with `notify: "minor"` (one that releases
 * several times a day) reports patch drift as current.
 */
export function classifyDrift(verified, latest, { notify = 'patch' } = {}) {
  if (compareVersions(latest, verified) <= 0) {
    return { severity: 'current', recommendIssue: false, minorsBehind: 0 }
  }
  const [vMaj, vMin] = parseVersion(verified)
  const [lMaj, lMin] = parseVersion(latest)
  if (lMaj !== vMaj) {
    return { severity: 'breaking', recommendIssue: true, minorsBehind: undefined }
  }
  const minorsBehind = lMin - vMin
  if (minorsBehind > 0) {
    if (vMaj === 0) return { severity: 'breaking', recommendIssue: true, minorsBehind }
    return { severity: 'additive', recommendIssue: minorsBehind > 1, minorsBehind }
  }
  if (notify === 'minor') return { severity: 'current', recommendIssue: false, minorsBehind: 0 }
  return { severity: 'info', recommendIssue: false, minorsBehind: 0 }
}

/** Compares a project pin with `verified`: newer, older, or same. */
export function classifyPin(pinned, verified) {
  const c = compareVersions(pinned, verified)
  return c > 0 ? 'newer' : c < 0 ? 'older' : 'same'
}

// ---------------------------------------------------------------------------
// Manifests

const MANIFEST_FIELDS = ['id', 'repo', 'tagPattern', 'packages', 'verified', 'verifiedOn']

/** Checks one sources.json entry and returns a list of problems. */
export function validateSource(source) {
  const problems = []
  for (const field of MANIFEST_FIELDS) {
    if (source[field] === undefined) problems.push(`missing "${field}"`)
  }
  if (source.tagPattern !== undefined) {
    if (!source.tagPattern.startsWith('^') || !source.tagPattern.endsWith('$')) {
      problems.push('"tagPattern" must start with ^ and end with $')
    }
    try {
      new RegExp(source.tagPattern)
    } catch (err) {
      problems.push(`"tagPattern" is not a valid regular expression: ${err.message}`)
    }
  }
  if (source.verified !== undefined && !parseVersion(source.verified)) {
    problems.push('"verified" must be X.Y.Z')
  }
  if (source.packages !== undefined && !Array.isArray(source.packages)) {
    problems.push('"packages" must be an array')
  }
  if (source.notify !== undefined && !['patch', 'minor'].includes(source.notify)) {
    problems.push('"notify" must be "patch" or "minor"')
  }
  for (const pin of source.pinFiles ?? []) {
    if (typeof pin.path !== 'string' || typeof pin.pattern !== 'string') {
      problems.push('each "pinFiles" entry needs "path" and "pattern"')
    }
  }
  return problems
}

/** Finds sources.json files under a directory, without node_modules or .git. */
export function findManifests(path) {
  if (statSync(path).isFile()) return [resolve(path)]
  const found = []
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    if (entry.name === 'node_modules' || entry.name === '.git') continue
    const full = join(path, entry.name)
    if (entry.isDirectory()) found.push(...findManifests(full))
    else if (entry.name === 'sources.json') found.push(resolve(full))
  }
  return found.sort()
}

/** Reads a sources.json. The skill name is the name of its directory. */
export function loadManifest(file) {
  const sources = JSON.parse(readFileSync(file, 'utf8'))
  if (!Array.isArray(sources)) throw new Error(`${file}: must hold a JSON array`)
  return { skill: basename(dirname(file)).replace(/^cinc:/, ''), file, sources }
}

// ---------------------------------------------------------------------------
// Project pins

function readJson(file) {
  try {
    return JSON.parse(readFileSync(file, 'utf8'))
  } catch {
    return undefined
  }
}

function readText(file) {
  try {
    return readFileSync(file, 'utf8')
  } catch {
    return undefined
  }
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

/** Returns the lowest `X.Y.Z` in a range such as `^14.5.0` or `~0.24`. */
export function versionFromRange(range) {
  const m = /(\d+)\.(\d+)(?:\.(\d+))?/.exec(String(range ?? ''))
  return m ? `${m[1]}.${m[2]}.${m[3] ?? 0}` : undefined
}

/** Finds the version of a package in a pnpm or yarn lockfile. */
export function versionFromLockText(text, name) {
  const pkg = escapeRegExp(name)
  const pnpm = new RegExp(`(?:^|[\\s/'"])${pkg}@(\\d+\\.\\d+\\.\\d+)`, 'm').exec(text)
  if (pnpm) return pnpm[1]
  const yarn = new RegExp(`^"?${pkg}@[^\\n]*\\n\\s+version:?\\s+"?(\\d+\\.\\d+\\.\\d+)`, 'm').exec(
    text,
  )
  return yarn ? yarn[1] : undefined
}

/**
 * Finds the version of one package in a project. It prefers the installed
 * copy, then the lockfile, then the lowest version of the package.json range.
 */
export function packagePin(projectDir, name) {
  const pkg = readJson(join(projectDir, 'package.json'))
  const range =
    pkg?.dependencies?.[name] ?? pkg?.devDependencies?.[name] ?? pkg?.peerDependencies?.[name]
  if (range === undefined) return undefined

  const installed = readJson(join(projectDir, 'node_modules', name, 'package.json'))?.version
  if (parseVersion(installed)) return { version: installed, from: 'node_modules', range }

  const npmLock = readJson(join(projectDir, 'package-lock.json'))
  const locked =
    npmLock?.packages?.[`node_modules/${name}`]?.version ?? npmLock?.dependencies?.[name]?.version
  if (parseVersion(locked)) return { version: locked, from: 'package-lock.json', range }

  for (const lockFile of ['pnpm-lock.yaml', 'yarn.lock']) {
    const text = readText(join(projectDir, lockFile))
    const version = text && versionFromLockText(text, name)
    if (version) return { version, from: lockFile, range }
  }

  const fromRange = versionFromRange(range)
  return fromRange ? { version: fromRange, from: 'package.json range', range } : undefined
}

/** Reads a version from a pinFiles entry, such as `version:` in deploy.yaml. */
export function filePin(projectDir, { path, pattern }) {
  const text = readText(join(projectDir, path))
  if (text === undefined) return undefined
  const m = new RegExp(pattern, 'm').exec(text)
  if (!m) return { version: undefined, from: path, range: undefined }
  return { version: versionFromRange(m[1]), from: path, range: m[1] }
}

/** Lists every pin of one source in a project. */
export function sourcePins(projectDir, source) {
  const pins = []
  for (const name of source.packages ?? []) {
    const pin = packagePin(projectDir, name)
    if (pin) pins.push({ what: name, ...pin })
  }
  for (const pinFile of source.pinFiles ?? []) {
    const pin = filePin(projectDir, pinFile)
    if (pin) pins.push({ what: pinFile.path, ...pin })
  }
  return pins.map(pin => ({
    ...pin,
    status: pin.version ? classifyPin(pin.version, source.verified) : 'no version',
  }))
}

// ---------------------------------------------------------------------------
// Upstream tags, with a cache

/** Picks the first cache directory that exists or can be made. */
export function cacheDir(explicit) {
  const candidates = [
    explicit,
    process.env.CLAUDE_PLUGIN_DATA,
    process.env.XDG_CACHE_HOME && join(process.env.XDG_CACHE_HOME, 'claude-plugins'),
    join(homedir(), '.cache', 'claude-plugins'),
    join(tmpdir(), 'claude-plugins'),
  ]
  for (const dir of candidates.filter(Boolean)) {
    try {
      mkdirSync(dir, { recursive: true })
      return dir
    } catch {
      // Try the next one.
    }
  }
  return undefined
}

function readCache(dir) {
  return (dir && readJson(join(dir, CACHE_FILE))) || {}
}

function writeCache(dir, cache) {
  if (!dir) return
  try {
    writeFileSync(join(dir, CACHE_FILE), `${JSON.stringify(cache, null, 2)}\n`)
  } catch {
    // A cache that cannot be written only costs a refetch.
  }
}

/** Lists the tag names of a repo with `gh api`. Rejects on any failure. */
export function listTags(repo) {
  return new Promise((resolvePromise, reject) => {
    execFile(
      'gh',
      ['api', '--paginate', `repos/${repo}/tags?per_page=100`, '--jq', '.[].name'],
      { timeout: GH_TIMEOUT_MS, maxBuffer: 16 * 1024 * 1024 },
      (err, stdout, stderr) => {
        if (err) {
          const detail = (stderr || err.message).trim().split('\n')[0]
          reject(new Error(err.code === 'ENOENT' ? 'gh is not installed' : detail))
        } else {
          resolvePromise(stdout.split('\n').filter(Boolean))
        }
      },
    )
  })
}

/**
 * Finds the matching tags of a source, from the cache when it is younger than
 * `maxAgeMs`. Returns `{ versions, fetchedAt, cached }` or `{ error }`.
 */
export async function upstreamVersions(source, { cache, now, maxAgeMs, fetchTags = listTags }) {
  const key = `${source.repo} ${source.tagPattern}`
  const hit = cache[key]
  if (hit && now - Date.parse(hit.fetchedAt) < maxAgeMs) return { ...hit, cached: true }
  try {
    const versions = matchTags(await fetchTags(source.repo), source.tagPattern)
    const entry = { versions, fetchedAt: new Date(now).toISOString() }
    cache[key] = entry
    return { ...entry, cached: false }
  } catch (err) {
    return { error: err.message }
  }
}

// ---------------------------------------------------------------------------
// Report

/** Checks one source: the upstream drift and, with a project, its pins. */
export async function checkSource(skill, source, options) {
  const problems = validateSource(source)
  const result = { skill, id: source.id, repo: source.repo, verified: source.verified }
  if (problems.length > 0) {
    return { ...result, severity: 'unknown', reason: `bad manifest: ${problems.join('; ')}` }
  }
  if (options.projectDir) result.pins = sourcePins(options.projectDir, source)
  if (options.offline) return { ...result, severity: 'unknown', reason: 'offline' }

  const upstream = await upstreamVersions(source, options)
  if (upstream.error) return { ...result, severity: 'unknown', reason: upstream.error }
  const latest = highestVersion(Object.keys(upstream.versions))
  if (!latest) {
    return { ...result, severity: 'unknown', reason: `no tag matches ${source.tagPattern}` }
  }
  return {
    ...result,
    latest,
    latestTag: upstream.versions[latest],
    verifiedTag: upstream.versions[source.verified],
    checkedAt: upstream.fetchedAt,
    cached: upstream.cached,
    ...classifyDrift(source.verified, latest, { notify: source.notify }),
  }
}

/** Links to the upstream changes between the verified and latest tags. */
export function changeLinks(result) {
  const links = []
  if (result.verifiedTag && result.latestTag) {
    const compare = `${result.verifiedTag}...${result.latestTag}`
    links.push(`https://github.com/${result.repo}/compare/${compare}`)
  }
  links.push(`https://github.com/${result.repo}/releases`)
  return links
}

/** Builds the title and body of an update issue for one skill. */
export function issueDraft(skill, results) {
  const drifted = results.filter(r => r.skill === skill && r.recommendIssue)
  if (drifted.length === 0) return undefined
  const names = drifted.map(r => `${r.id} ${r.latest}`).join(', ')
  const rows = drifted.map(
    r => `| \`${r.id}\` | \`${r.repo}\` | ${r.verified} | ${r.latest} | ${r.severity} |`,
  )
  const links = drifted.flatMap(r => changeLinks(r).map(link => `- \`${r.id}\`: ${link}`))
  const body = [
    `The \`${skill}\` skill is verified against upstream versions that are now behind.`,
    '',
    '| Source | Repo | Verified | Latest | Severity |',
    '| --- | --- | --- | --- | --- |',
    ...rows,
    '',
    '## Changes to review',
    '',
    ...links,
    '',
    '## Update procedure',
    '',
    '1. Read the upstream changelog and the diff from `verified` to the latest release.',
    '2. Update the skill content and its migration notes.',
    '3. Set `verified` and `verifiedOn` in `sources.json`.',
    '4. Ship the change through a release-please release.',
    '',
    `<!-- skill-drift: ${skill} -->`,
  ].join('\n')
  return { title: `docs(${skill}): update for ${names}`, label: 'skill-drift', body }
}

function pad(text, width) {
  return String(text ?? '').padEnd(width)
}

function table(header, rows) {
  const widths = header.map((h, i) =>
    Math.max(h.length, ...rows.map(r => String(r[i] ?? '').length)),
  )
  const line = cells =>
    cells
      .map((c, i) => pad(c, widths[i]))
      .join('  ')
      .trimEnd()
  return [line(header), ...rows.map(line)].join('\n')
}

const ACTION = {
  breaking: 'recommend an update issue',
  additive: 'recommend an update issue',
  info: 'mention only',
  current: '-',
  unknown: 'none (check skipped)',
}

/** Formats the results as plain-text tables. */
export function formatText(results) {
  const upstream = table(
    ['SKILL', 'SOURCE', 'VERIFIED', 'LATEST', 'SEVERITY', 'ACTION'],
    results.map(r => [
      r.skill,
      r.id,
      r.verified,
      r.latest ?? '?',
      r.severity,
      r.severity === 'additive' && !r.recommendIssue
        ? 'mention only (one minor behind)'
        : r.severity === 'unknown'
          ? `none: ${r.reason}`
          : ACTION[r.severity],
    ]),
  )
  const pins = results.flatMap(r =>
    (r.pins ?? []).map(p => [
      r.skill,
      r.id,
      p.what,
      p.version ?? '?',
      p.from,
      r.verified,
      p.status,
    ]),
  )
  const parts = [upstream]
  if (results.some(r => r.pins)) {
    parts.push(
      pins.length > 0
        ? table(['SKILL', 'SOURCE', 'PIN', 'VERSION', 'FROM', 'VERIFIED', 'STATUS'], pins)
        : 'The project pins none of these sources.',
    )
  }
  return parts.join('\n\n')
}

// ---------------------------------------------------------------------------
// CLI

export function parseArgs(argv) {
  const options = { paths: [], maxAgeHours: 24 }
  const takesValue = new Set(['--skill', '--project', '--max-age', '--cache-dir', '--issue-draft'])
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (takesValue.has(arg)) {
      const value = argv[++i]
      if (value === undefined) throw new Error(`${arg} needs a value`)
      if (arg === '--skill') options.skill = value
      if (arg === '--project') options.projectDir = resolve(value)
      if (arg === '--max-age') options.maxAgeHours = Number(value)
      if (arg === '--cache-dir') options.cacheDir = value
      if (arg === '--issue-draft') options.issueDraft = value
    } else if (arg === '--offline') options.offline = true
    else if (arg === '--refresh') options.maxAgeHours = 0
    else if (arg === '--json') options.json = true
    else if (arg === '--help' || arg === '-h') options.help = true
    else if (arg.startsWith('-')) throw new Error(`unknown option: ${arg}`)
    else options.paths.push(arg)
  }
  if (!Number.isFinite(options.maxAgeHours) || options.maxAgeHours < 0) {
    throw new Error('--max-age must be a number of hours')
  }
  if (options.issueDraft && !options.skill) options.skill = options.issueDraft
  return options
}

export async function run(argv, { now = Date.now(), fetchTags = listTags } = {}) {
  const options = parseArgs(argv)
  if (options.help) {
    const lines = readFileSync(fileURLToPath(import.meta.url), 'utf8')
      .split('\n')
      .slice(1)
    const header = lines.slice(
      0,
      lines.findIndex(l => !l.startsWith('//')),
    )
    return { output: header.map(l => l.replace(/^\/\/ ?/, '')).join('\n'), code: 0 }
  }
  const pluginRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
  const paths = options.paths.length > 0 ? options.paths : [join(pluginRoot, 'skills')]
  const manifests = paths
    .filter(p => existsSync(p))
    .flatMap(findManifests)
    .map(loadManifest)
    .filter(m => !options.skill || m.skill === options.skill)
  if (manifests.length === 0) {
    return {
      output: `No sources.json found${options.skill ? ` for ${options.skill}` : ''}.`,
      code: 2,
    }
  }

  const dir = cacheDir(options.cacheDir)
  const cache = readCache(dir)
  const context = {
    ...options,
    cache,
    now,
    maxAgeMs: options.maxAgeHours * 60 * 60 * 1000,
    fetchTags,
  }
  const results = []
  for (const manifest of manifests) {
    for (const source of manifest.sources) {
      results.push(await checkSource(manifest.skill, source, context))
    }
  }
  if (!options.offline) writeCache(dir, cache)

  if (options.issueDraft) {
    const draft = issueDraft(options.issueDraft, results)
    if (options.json) return { output: JSON.stringify(draft ?? null, null, 2), code: 0 }
    if (!draft) return { output: `No update issue is needed for ${options.issueDraft}.`, code: 0 }
    return { output: `TITLE: ${draft.title}\nLABEL: ${draft.label}\n\n${draft.body}`, code: 0 }
  }
  if (options.json) return { output: JSON.stringify(results, null, 2), code: 0 }
  return { output: formatText(results), code: 0 }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  run(process.argv.slice(2)).then(
    ({ output, code }) => {
      process.stdout.write(`${output}\n`)
      process.exitCode = code
    },
    err => {
      process.stderr.write(`check-drift: ${err.message}\n`)
      process.exitCode = 2
    },
  )
}
