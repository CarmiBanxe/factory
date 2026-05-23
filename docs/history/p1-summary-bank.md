# BANXE P1 — claude-code-setup recommendations summary
Generated: 2026-05-03T03:25:13+02:00

## banxe-payment-core

### automations
```md
## Рекомендации автоматизаций для banxe-payment-core

**Профиль проекта:** Python 3.11 / FastAPI / Pydantic v2 · Ruff + Bandit + Semgrep (с BANXE-кастомными правилами I-01/I-05) · pytest 80%+ · Adapter pattern (Hyperswitch/Paymentology/Midaz) · FCA-regulated payments · Docker Compose stack.

**Существующее:** `settings.json` со слэш-командами и `deny_paths`, pre-commit только с gitleaks, Makefile c quality-gate. Главные пробелы — нет PostToolUse автоформата, нет subagent для проверки инвариантов, нет hook-enforcement для `deny_paths`.

---

### ⚡ Hooks (top 2)

#### 1. `PostToolUse` → ruff format + check на Python-файлах
**Зачем:** Сейчас форматирование/линт ловятся только в `make lint` или CI. Auto-fix на каждом Edit/Write убирает циклы «отредактировал → CI красный → переоткрыл».
**Где:** `.claude/settings.json`
```json
"hooks": {
  "PostToolUse": [{
    "matcher": "Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "if [[ \"$CLAUDE_FILE_PATHS\" == *.py ]]; then ruff format $CLAUDE_FILE_PATHS && ruff check --fix $CLAUDE_FILE_PATHS; fi"
    }]
  }]
}
```

#### 2. `PreToolUse` → блокировка edit в чувствительных путях + semgrep I-01/I-05 на трогаемых файлах
**Зачем:** `deny_paths` в `settings.json` декларативный — без hook это не enforced. Также при правке `src/authorization/` или `src/compliance_bridge/` имеет смысл прогонять `.semgrep/rules.yaml` (banxe-float-money, banxe-screening-first, banxe-no-raw-pan) до того, как diff окажется в коммите.

---

### 🤖 Subagents (top 2)

#### 1. `invariant-reviewer` — аудит I-01/I-02/I-04/I-05/I-10/I-15
**Зачем:** Инварианты из CLAUDE.md — это ровно то, что должен ловить ревьюер на каждом PR (screening first, no float for money, no raw PAN, no AGPLv3, ≥£10k → EDD/HITL). Сейчас это контролирует semgrep частично + человек. Subagent параллелит проверку всех инвариантов и возвращает прямые ссылки на нарушения.
**Где:** `.claude/agents/invariant-reviewer.md`
**Тулы:** Read, Grep, Glob, Bash (для `make semgrep`).

#### 2. `payments-security-reviewer` — PCI/PAN/секреты/Mastercard IPM
**Зачем:** Settlement-парсер Mastercard IPM — собственное ядро, его правки требуют security-фокуса (PAN handling, BIN/PAN exposure в логах, decimal arithmetic в clearing файлах, decision log append-only I-24). Bandit/semgrep — статика; subagent смотрит контекст.

```

### mcp
```md
# Рекомендуемые MCP-серверы для `banxe-payment-core`

Текущее состояние: подключён только Notion. Atlassian/Google нуждаются в авторизации, `ruflo` падает.

## Уже настроено — нужно решить
| Сервер | Статус | Действие |
|--------|--------|----------|
| **Notion** | ✓ | Держать (canon docs, ADR-015, INVARIANTS) |
| **Atlassian Rovo** | ! auth | **Авторизовать** — Jira tickets `IL-XXX` из commit format |
| **Google Drive** | ! auth | Авторизовать только если там лежат compliance-докум. Иначе отключить |
| **Gmail / Calendar** | ! auth | **Отключить** — нерелевантно payment-core |
| **ruflo** | ✗ fail | Удалить или починить SSH |

## Стоит добавить (приоритет для FCA EMI core)

| Сервер | Зачем | Приоритет |
|--------|-------|-----------|
| **filesystem** (`@modelcontextprotocol/server-filesystem`) | Доступ к `~/banxe-architecture` (canon, INVARIANTS) и `~/banxe-emi-stack` без переключения cwd | 🔴 high |
| **postgres** (`@modelcontextprotocol/server-postgres`) | Hyperswitch internal DB (`:8096`) + Midaz (`:8095`) — read-only схема для отладки | 🔴 high |
| **github** (`@modelcontextprotocol/server-github`) | PR review, CI status, issues `IL-XXX` | 🟡 med |
| **sentry** или эквивалент | Production errors из Hyperswitch/Compliance bridge | 🟡 med |
| **fetch** (`@modelcontextprotocol/server-fetch`) | Hyperswitch/Midaz/Compliance API live-проверки `:8093/:8095/:8096-8098` | 🟢 low |

## НЕ добавлять
- ❌ Любые MCP с хостингом в RU/BY/IR/KP/CU/MM/AF (I-02)
- ❌ AGPLv3-компоненты (I-15)
- ❌ Серверы, которые отправляют код/секреты во внешние LLM без TLS-pinning (PCI scope)

## Конкретный шаг сейчас

Файл `/home/mmber/banxe/banxe-payment-core/.claude/recos-mcp.md` пустой. Заполнить его этим списком?
```

### actions
```md
# GitHub Actions — рекомендации (PR review + tests)

**Текущее состояние:** есть `ci.yml`, `claude.yml` (только по @claude), `factory-guard.yml`.

---

## P0 — критично, чинить сейчас

### 1. Semgrep `continue-on-error: true` → hard fail
`ci.yml:38` нарушает **I-12 (Validators = source of truth)** и **I-15 (no AGPLv3)**. BANXE-инварианты должны блокировать merge.
```yaml
- name: Semgrep BANXE rules
  run: semgrep --config .semgrep/rules.yaml src/ --error
  # убрать continue-on-error
```

### 2. Coverage gate не enforced в CI
`pytest` запускается без `--cov-fail-under`. Добавить явно (pyproject уже имеет 80, но CI должен это echo'ить):
```yaml
- name: pytest (coverage ≥80%)
  run: pytest --tb=short --cov-fail-under=80 --junitxml=junit.xml
- uses: dorny/test-reporter@v1
  if: always()
  with: { name: pytest, path: junit.xml, reporter: java-junit }
```

### 3. Concurrency control (нет — деньги горят)
Добавить в `ci.yml` сверху:
```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

---

## P1 — auto PR review

### 4. Авто-ревью Claude на каждый PR (без @claude)
Сейчас Claude отвечает только по mention. Добавить `claude-review.yml`:
```

## banxe-ui

### automations
```md
## Claude Code Automation Recommendations — `banxe-ui`

### Codebase Profile
- **Type**: pnpm + Turbo monorepo, TS 5.4 strict
- **Apps**: web-next (Next.js 16), web-vite (React 18 + Vite 5), mobile (Expo SDK 53)
- **Stack**: Tailwind, Storybook v8, Vitest, jest-axe, MSW v2, Semgrep
- **Already configured**: MCPs (context7, figma, storybook), SessionStart + PreToolUse(inject-design-rules) + PostToolUse hooks, ~19 design/UI skills, 6 slash-commands
- **Biggest gap**: zero subagents (`.claude/agents/` отсутствует), нет post-edit typecheck/lint, нет money-safety guard

---

### 🤖 Subagents (highest leverage — пусто сейчас)

#### 1. `money-safety-reviewer`  *(I-05 invariant)*
**Why**: FCA non-negotiable — `parseFloat / Number / toFixed` на деньгах = compliance breach. Сейчас не enforced на ревью.
**Where**: `.claude/agents/money-safety-reviewer.md`
**Scope**: grep по `apps/**/src`, `packages/ui/src` → `parseFloat\(|Number\(.*amount|toFixed\(`, проверка что суммы остаются `string` до отображения, `font-mono` класс присутствует.

#### 2. `ai-content-reviewer`
**Why**: CLAUDE.md обязует `✦ AI` badge + `ConfidenceIndicator` + UNCERTAIN warning + static notice + audit log на каждом AI-блоке. Это легко пропустить вручную.
**Where**: `.claude/agents/ai-content-reviewer.md`
**Scope**: AIInsightCard usages, любые компоненты с AI-данными → checklist 5 пунктов из БЛОК 3.

---

### ⚡ Hooks

#### 1. PostToolUse: typecheck + ESLint changed file
**Why**: strict TS + `eslint-plugin-jsx-a11y` сконфигурированы, но post-edit прогоняется только `inject-design-rules`. Tight feedback loop = меньше "почему build red".
**Where**: `.claude/settings.json` → PostToolUse `Write|Edit`
```bash
pnpm exec tsc --noEmit --pretty false 2>&1 | tail -20 && pnpm exec eslint "$CLAUDE_FILE_PATHS" --max-warnings 0
```

#### 2. PreToolUse: I-05 money-safety guard
**Why**: блокирует commit запрещённых паттернов до того, как они попадают в код. Дешевле чем post-mortem ревью.
**Where**: `.claude/hooks/i05-guard.py` + PreToolUse `Write|Edit`
**Logic**: deny если в `new_string` есть `parseFloat(` / `\.toFixed\(` / `Number\(.*(amount|balance|price)` И путь под `apps/**/src/**|packages/ui/src/**`.

---
```

### mcp
```md
## Рекомендуемые MCP для banxe-ui

**Уже подключены и работают:**
- ✓ **context7** — свежие доки React/Next/Tailwind/Expo (используй `use context7` в промпте)
- ✓ **figma** — чтение дизайн-токенов и компонентов из Figma
- ✓ **storybook** — компоненты `@banxe/ui` как контекст (анти-галлюцинация)
- ✓ **Notion** — документация, IL-записи, спеки

**Требуют авторизации (стоит подключить):**
- ! **Atlassian Rovo** — если используете Jira/Confluence для тикетов
- ! **Google Drive** — если там лежат регуляторные доки (FCA/PSD2)

## Приоритет по задачам UI-репо

| Задача | MCP |
|--------|-----|
| Новый экран (W-01..W-06) | storybook + figma + context7 |
| Компонент `@banxe/ui` | storybook + context7 |
| Дизайн-токены | figma |
| Next.js 16 / Expo SDK 53 миграция | context7 (критично — свежие API) |
| Спеки экранов / IL-записи | Notion |

## Чего **не хватает** под ваш стек

- **Supabase MCP** — если бэкенд banxe-emi-stack на Postgres (есть skill `supabase-postgres-best-practices`, но MCP даст live-схему)
- **Vercel MCP** — для деплоев `web-next` (сейчас через CLI/skills)
- **Playwright/Chrome DevTools MCP** — для a11y-аудита экранов в браузере (WCAG 2.1 AA — non-negotiable)

Хочешь — настрою недостающие через `/setup-mcp` или вручную в `.claude/settings.json`?
```

### actions
```md
Проверил репо: pnpm-monorepo (web-next/web-vite/mobile + ui/shared/design-tokens), turbo, vitest, semgrep, jest-axe. Уже есть 4 workflow: `claude.yml`, `quality-gate.yml`, `factory-guard.yml`, `confluence-sync.yml`. Ниже — что реально стоит добавить/починить, отсортировано по ROI.

## Критичные баги в существующих workflow

**1. `quality-gate.yml` — поломан под pnpm-репозиторий**
- `cache: 'npm'` + `npm ci`, но проект `packageManager: pnpm@10.33.0` и есть только `pnpm-lock.yaml` → CI либо падает, либо ставит мусор.
- `|| true` на ESLint и Semgrep — гейт ничего не блокирует. I-05 (`parseFloat` на деньгах) сейчас не enforced.
- TS-чек только для `packages/ui`, игнорирует `web-next`, `web-vite`, `mobile`, `shared`.
- Нет turbo cache → каждый PR строит всё с нуля.

**Фикс (минимально):**
```yaml
- uses: pnpm/action-setup@v4
  with: { version: 10.33.0 }
- uses: actions/setup-node@v4
  with: { node-version: '20', cache: 'pnpm' }
- run: pnpm install --frozen-lockfile
- run: pnpm typecheck    # turbo run typecheck — все пакеты
- run: pnpm lint         # без || true
- run: pnpm test         # без || true
- run: pnpm semgrep      # уже есть в scripts, без || true
```
Плюс turbo remote cache (`TURBO_TOKEN`/`TURBO_TEAM` в secrets) — экономит 60–80% времени на повторных PR.

**2. `claude.yml` — нет permissions, нет sticky-комментов**
Добавить `permissions: { contents: read, pull-requests: write, issues: write }` (least privilege) и закрепить модель `claude-opus-4-7` в action inputs. Сейчас action бежит с дефолтными правами токена — потенциальный риск.

## Новые workflow, которые реально нужны

**3. `pr-review.yml` — авто-ревью без @-mention**
Сейчас Claude отвечает только на `@claude` в комменте. Для системного PR-review нужен второй workflow на `pull_request: [opened, synchronize]`, запускающий Claude с фокусом «I-05, PSD2 SCA flow, AI-badge на AI-контенте, font-mono на суммах». Это закрывает блок 3 из вашего CLAUDE.md (правила для AI/денег/a11y) автоматически.

**4. `build-check.yml` — отдельный matrix-build**
`pnpm build` сейчас не запускается в CI вообще. Matrix по `[web-next, web-vite, storybook, design-tokens]` с path-filter (`paths-ignore: ['docs/**', '*.md']`) — ловит сломанный Next.js build до merge, плюс собирает Storybook как артефакт для дизайн-ревью (можно деплоить на Vercel preview).

**5. `a11y.yml` — отдельный гейт по jest-axe**
`pnpm test:a11y` уже есть в scripts, но не вызывается в CI. Вынести в отдельный job (не падающий весь quality-gate) с PR-комментом по нарушениям WCAG AA — закрывает требование «axe-core 0 critical» из БЛОКа 8.

**6. `dependency-review.yml` — встроенный GitHub action**
`actions/dependency-review-action@v4` — блокирует PR с GPL/AGPL зависимостями и known CVE. Для FCA-регулируемого продукта это must-have, конфигурится в 5 строк.
```

## banxe-infra

### automations
```md
## Рекомендации по автоматизациям — banxe-infra

**Профиль:** Bash-инфра, shellcheck + pre-commit, Makefile quality-gate, 3 GitHub workflow (ci/claude/factory-guard), удалённые SSH-операции на GMKtec, чувствительные файлы (.env, SSH-ключи, GDPR).

---

### ⚡ Hooks (приоритет №1 — у вас уже есть quality-gate, его надо «прибить» к Edit)

**1. PreToolUse — блокировать правки секретов и ключей**
- **Зачем:** `.env`, `~/.ssh/gmktec_key`, `secrets/*` уже в `deny_paths`, но это soft-rule. Hook жёстко блокирует Edit/Write до того, как Claude к ним прикоснётся.
- **Где:** `.claude/settings.json` → `hooks.PreToolUse` с matcher по path-glob `**/.env*`, `**/secrets/**`, `**/*.pem`, `**/id_*`, `**/gmktec_key*`.

**2. PostToolUse — auto-shellcheck при правке `*.sh`**
- **Зачем:** quality-gate сейчас запускается вручную через `make`. Перевод в hook убирает разрыв между «отредактировал» и «проверил» — критично для скриптов с `ssh_gmk()`, где опечатка = выстрел в прод.
- **Команда:** `shellcheck -S warning "$CLAUDE_FILE_PATH" && bash -n "$CLAUDE_FILE_PATH"`.

---

### 🤖 Subagents

**1. `shell-safety-reviewer`**
- **Зачем:** репо целиком — bash, с SSH-вызовами на удалённую машину и работой с шифрованием (Fernet). Нужен агент, который ловит: unquoted vars, `eval`, hardcoded IP/creds, отсутствие `set -euo pipefail`, нарушения «всё через `ssh_gmk()`».
- **Где:** `.claude/agents/shell-safety-reviewer.md`, инструменты: Read, Grep, Bash(shellcheck:*).

**2. `gdpr-secrets-auditor`**
- **Зачем:** GDPR Art.25/32 заявлены в CLAUDE.md, есть PII Proxy и Fernet. Агент сверяет diff с инвариантами: ключи не в коммитах, чувствительные пути не логируются открыто, шифрование не обходится.

---

### 🎯 Skills (custom)

**1. `gmk-remote-runbook`** (user-only, `disable-model-invocation: true`)
- **Зачем:** все 5 задач setup.sh — удалённые. Скилл-обёртка для идемпотентного запуска одной задачи с dry-run, логом и rollback-инструкцией. Снимает повторяющийся ритуал «ssh → check → run → verify».
- **Инвокация:** `/gmk-remote-runbook task=2` (PII Proxy), и т.д.

**2. `infra-rollback-plan`** (Both)
- **Зачем:** перед каждым merge в master по инфра-скриптам нужен явный план отката (особенно для backup/encryption). Скилл генерирует план из diff: какие файлы тронуты, как откатить, чем валидировать.

---

```

### mcp
```md
## Рекомендуемые MCP-серверы для banxe-infra

### Критичные (must-have)

| MCP | Зачем | Приоритет |
|---|---|---|
| **filesystem** | Безопасный доступ к `~/banxe/`, `~/banxe_backups/` | P0 |
| **ssh / shell** | Удалённое выполнение на GMKtec (192.168.0.72) | P0 |
| **github** | PR, issues, code review для banxe-infra | P0 |
| **postgres** или **clickhouse-mcp** | Прямые запросы к ClickHouse без `ssh + clickhouse-client` | P0 |

### Compliance & Security (FCA / GDPR)

| MCP | Зачем |
|---|---|
| **vault / 1password** | Хранение `gmktec_key`, Fernet-ключей, API-токенов |
| **presidio-mcp** (или wrapper над PII Proxy:8090) | Анонимизация в pipeline'ах |
| **sentry** | Алерты по падениям setup.sh / backup |

### Уже подключены (вижу в окружении)

- `Atlassian Rovo` — Jira/Confluence (тикеты IL-XXX)
- `Notion` — документация (COLLAB.md, MIROFISH)
- `Gmail` / `Google Calendar` / `Drive` — координация
- ⚠️ **MetaClaw / OpenClaw** — это ваш внутренний слой, не публичный MCP

### Не нужно

- ❌ `puppeteer / playwright-mcp` — backend-репо без UI
- ❌ `slack-mcp` — нет упоминаний Slack в стеке
- ❌ MCP из санкционных юрисдикций (RU/IR/KP/BY/SY) — запрет в CLAUDE.md

### Конкретный план

1. Открыть `~/.claude/settings.json` → добавить `filesystem` + `github` + `clickhouse`
2. Vault-MCP **до** того как класть `~/.ssh/gmktec_key` в любой автоматизированный flow
3. Presidio уже работает на :8090 — обернуть в MCP-tool для вызова из агентов

Хочешь — настрою через `/update-config` сразу `filesystem` + `github` в `settings.json`?
```

### actions
```md
## Текущее состояние

Уже есть: `ci.yml` (shellcheck + gitleaks + bash -n), `claude.yml` (только по `@claude`), `factory-guard.yml`, pre-commit, Makefile.

## Рекомендации (приоритизированы)

### P0 — закрыть пробелы PR review

**1. Auto PR Review (Claude) — без ручного триггера**
Сейчас `claude.yml` срабатывает только на `@claude`. Добавить отдельный `claude-review.yml` на `pull_request: [opened, synchronize]` через `anthropics/claude-code-action@v1` с `mode: review` и фокусом на shell-безопасность (eval, IFS, quoting, set -euo pipefail).

**2. Strict ShellCheck → SARIF в Code Scanning**
`ci.yml:23` сейчас `-S warning`. Перейти на `-S style` + загрузка SARIF через `reviewdog/action-shellcheck@v1` или `redhat-plumbers-in-action/differential-shellcheck@v5` — комментарии прямо в diff PR.

**3. BATS-тесты для `banxe-infra-setup.sh`**
Скрипт 25 KB, 5 задач, проверяется только `bash -n`. Добавить `tests/*.bats` + workflow `tests.yml` с `bats-core/bats-action@3` — мокать `ssh_gmk()`, `clickhouse-client`, проверять `log/ok/err`, идемпотентность шагов.

### P1 — gates и качество

**4. Required status checks reminder**
Workflow `branch-protection-check.yml` или README-блок: `shellcheck`, `gitleaks`, `bats`, `factory-guard` обязательны для merge в `master`.

**5. Dependabot для actions**
`.github/dependabot.yml` с `package-ecosystem: github-actions` weekly — `actions/checkout@v4` и пр. сами обновляются.

**6. CODEOWNERS**
`.github/CODEOWNERS`: `banxe-infra-setup.sh @MorielCarmi`, `*.yml @MorielCarmi` — авто-ревьюер.

### P2 — DX и observability

**7. Labeler + PR size**
`actions/labeler@v5` (по путям: `infra`, `ci`, `docs`) + `codelytv/pr-size-labeler@v1`.

**8. Gitleaks SARIF**
`ci.yml:34-37` — добавить `report_format: sarif` + `github/codeql-action/upload-sarif@v3` → секреты в Security tab.

**9. Makefile smoke-test job**
Новый job в `ci.yml`: `make quality-gate` — гарантирует, что локальный gate и CI согласованы.

**10. Concurrency cancel**
```

