import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { dirname, extname, join, resolve } from 'node:path'

const ignoredDirectories = new Set(['.git', 'node_modules', 'dist', 'build'])
const markdownFiles = []

function collectMarkdownFiles(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue
    const path = join(directory, entry.name)
    if (entry.isDirectory()) {
      collectMarkdownFiles(path)
      continue
    }
    if (extname(entry.name) === '.md') markdownFiles.push(path)
  }
}

function internalTargets(markdown) {
  const targets = []
  const pattern = /\[[^\]]*\]\(([^)]+)\)/g
  let match
  while ((match = pattern.exec(markdown)) !== null) {
    const rawTarget = match[1].trim()
    if (/^(https?:|mailto:|#)/.test(rawTarget)) continue
    const target = rawTarget.split('#')[0]
    if (target) targets.push(target)
  }
  return targets
}

collectMarkdownFiles('.')

const broken = []
for (const file of markdownFiles) {
  const markdown = readFileSync(file, 'utf8')
  for (const target of internalTargets(markdown)) {
    const resolved = resolve(dirname(file), decodeURIComponent(target))
    if (!existsSync(resolved)) broken.push(`${file} -> ${target}`)
  }
}

if (broken.length > 0) {
  console.error('Broken internal Markdown links:')
  for (const item of broken) console.error(`- ${item}`)
  process.exitCode = 1
} else {
  console.log(`Markdown links OK: ${markdownFiles.length} files checked`)
}
