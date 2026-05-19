# Claude Code Global Instructions

## General

- Be concise. Avoid unnecessary commentary.
- Don't explain changes unless asked.
- DO NOT add comments unless explicitly asked. Never remove existing comments.
- When moving a file, always update all imports to point to the new location. Never leave the original file as a re-export shim.

## Code Style

- Use clear, descriptive names. Avoid abbreviations except well-known ones.
- Prefer functional patterns and immutability where practical.
- Keep functions small and focused on a single responsibility.

## TypeScript

- Prefer `const` over `let`. Never use `var`.
- Use strict TypeScript — avoid `any`.

## Markdown Files

- Include a tl;dr at the top of every markdown file you create
