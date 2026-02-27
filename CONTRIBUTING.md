# Contributing to DragonToast

Thank you for your interest in contributing to DragonToast! This is an open-source World of Warcraft addon that provides an animated loot feed with toast notifications. Contributions of all kinds are welcome - bug reports, feature suggestions, documentation improvements, and code.

Please note that this project follows a [Code of Conduct](https://github.com/Xerrion/DragonToast/blob/master/CODE_OF_CONDUCT.md). By participating, you are expected to uphold it.

---

## How to Contribute

### Report Bugs

Found a bug? Please [open an issue](https://github.com/Xerrion/DragonToast/issues/new/choose) on GitHub using the existing bug report template. Include as much detail as possible - your WoW version, steps to reproduce, and any Lua errors you see.

### Suggest Features

Have an idea for a new feature or improvement? [Open an issue](https://github.com/Xerrion/DragonToast/issues/new/choose) on GitHub and describe what you'd like to see and why it would be useful.

### Submit Code

Ready to write some code? Read on for setup instructions, then submit a Pull Request.

---

## Prerequisites

- A **World of Warcraft** client (TBC Anniversary, MoP Classic, or Retail)
- **Lua 5.1** knowledge
- **Luacheck** installed for linting
- **Git** with submodule support

---

## Development Setup

1. **Fork and clone** the repository:

   ```bash
   git clone https://github.com/<your-username>/DragonToast.git
   ```

2. **Initialize submodules** (pulls in Ace3 and other embedded libraries):

   ```bash
   git submodule update --init --recursive
   ```

3. **Symlink or copy** the addon folder into your WoW AddOns directory:
   - `World of Warcraft/_retail_/Interface/AddOns/DragonToast/`
   - or the equivalent path for TBC Anniversary / MoP Classic

4. **Reload WoW** with `/reload` to pick up the addon.

---

## Code Style

### Formatting

- **4 spaces** for indentation (no tabs)
- **120 characters** max line length
- Spaces around operators: `local x = 1 + 2`
- No trailing whitespace
- Use dashes (`-`), not em-dashes or en-dashes, in comments and documentation

### File Header

Every `.lua` file must start with this header block:

```lua
-------------------------------------------------------------------------------
-- FileName.lua
-- Brief description of the file
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------
```

### Naming Conventions

| Type             | Convention        | Example                             |
|------------------|-------------------|-------------------------------------|
| Files            | PascalCase        | `ToastFrame.lua`                    |
| Public functions | PascalCase        | `ns.ToastFrame.Acquire()`           |
| Local variables  | camelCase         | `local frameCount`                  |
| Local functions  | PascalCase        | `local function CreateToastFrame()` |
| Constants        | UPPER_SNAKE       | `local MAX_RETRIES = 5`             |
| Unused args      | Underscore prefix | `local _unused`                     |

### Libraries

Use the **Ace3 library stack** - never the raw alternatives:

| Library            | Replaces                                 |
|--------------------|------------------------------------------|
| AceEvent           | `frame:RegisterEvent()`                  |
| AceTimer           | `C_Timer.After()` / `C_Timer.NewTimer()` |
| AceDB              | Raw `SavedVariables`                     |
| AceConsole         | `SLASH_*` globals                        |
| LibSharedMedia-3.0 | Hardcoded font/texture paths             |

### Error Handling

- **`GetItemInfo` may return nil** on first call for uncached items. Always use the AceTimer retry pattern (up to 5 retries, 0.2s each).
- Defensive nil checks before calling optional module functions.
- Cancel AceTimers before nullifying references.

---

## Linting

```bash
# Lint the entire addon
luacheck .

# Lint a single file
luacheck Core/Init.lua
```

All Luacheck warnings **must pass** before merge. CI runs Luacheck automatically on every Pull Request.

---

## Testing

There is no automated test framework. Test manually in-game:

| Command        | Description                                           |
|----------------|-------------------------------------------------------|
| `/dt test`     | Show a single test toast                              |
| `/dt testmode` | Toggle continuous test toasts for live config preview |
| `/dt clear`    | Dismiss all active toasts                             |
| `/dt config`   | Open the configuration window                         |

Additional testing steps:

- Rapid-fire `/dt test` (10+ times) to stress the frame pool
- Hover and unhover during animations to verify pause/resume behavior
- Enable script errors to surface Lua errors:

  ```text
  /console scriptErrors 1
  ```

- Test on at least one supported WoW version before submitting

---

## Submitting Changes

1. **Create a feature branch** from `master`:

   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make your changes** following the code style guidelines above.

3. **Run Luacheck** and fix any warnings:

   ```bash
   luacheck .
   ```

4. **Test in-game** on at least one supported WoW version.

5. **Commit** with conventional commit messages:
   - `feat: add new feature`
   - `fix: resolve toast stacking bug`
   - `docs: update contributing guide`
   - `refactor: simplify animation queue`

6. **Push** your branch and **open a Pull Request** against `master`.

7. **Fill out the PR template** completely.

8. **Wait for CI** (Luacheck) to pass and for a maintainer review.

---

## Branch Naming

| Prefix                 | Use                   |
|------------------------|-----------------------|
| `feat/description`     | New features          |
| `fix/description`      | Bug fixes             |
| `docs/description`     | Documentation changes |
| `refactor/description` | Code refactoring      |

---

## What Happens After Your PR

- **CI** runs Luacheck automatically on your Pull Request.
- A **maintainer** will review your changes and may request revisions.
- Approved PRs are **squash-merged** into `master`.
- **release-please** handles versioning and changelog generation automatically - you do not need to update version numbers or changelogs manually.

---

## Thank You

Every contribution - whether it is a bug report, a feature idea, or a code change - helps make DragonToast better for the entire WoW community. Thank you for taking the time to contribute!
