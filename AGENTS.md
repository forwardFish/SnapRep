# SnapRep Project Instructions

## Project Identity

This repository is the unfinished SnapRep project.

This is not a migration to another product.
This is not a rename project.
This is not a template extraction task.

The goal is to re-take over, audit, complete, optimize, and redevelop SnapRep itself.

## Current Phase

The current phase is project takeover audit.

No feature development is allowed until the audit documents are completed.

## Required Behavior

Before making any code change, Codex must:

1. Read this AGENTS.md file.
2. Inspect the repository structure.
3. Check package.json and framework configuration.
4. Identify evidence from actual files.
5. Produce a written plan or audit.
6. Wait for explicit approval before implementation.

## Forbidden During Audit

Do not:
- modify business code
- delete files
- install dependencies
- refactor
- redesign UI
- create new features
- rewrite architecture
- change package.json
- change lock files

## Audit Output Requirement

When auditing, every conclusion must include:

- finding
- evidence file path
- impact
- risk level
- recommended action

## SnapRep Audit Documents

The first phase must produce:

- docs/00-project-audit.md
- docs/01-product-requirements-from-code.md
- docs/02-risk-register.md
- docs/03-redevelopment-plan.md

## Working Style

Use small steps.
Prefer analysis before action.
Do not make assumptions when evidence is missing.
Mark unclear items as "待确认".