## 2025-03-25 - Whiptail Checklists lack visual cues for keyboard interactions
**Learning:** CLI UI frameworks like whiptail often lack intuitive visual cues for their keyboard interactions. For example, many users don't realize they must press `<Space>` to toggle items in a `--checklist` before pressing `<Enter>`, leading them to accidentally skip all selections.
**Action:** Always include explicit, inline keyboard instructions (like `(Press <Space> to toggle, <Enter> to confirm)`) in the prompt or title of CLI interactive menus that rely on specific keystrokes.

## 2025-03-25 - Handle Empty States in CLI Prompts
**Learning:** When prompting users to select from a dynamic list in CLI scripts, displaying the prompt when the list is empty creates a confusing and broken user experience.
**Action:** Always check if a dynamic list is empty before prompting the user to select from it. If it is empty, exit gracefully and provide actionable instructions on how to populate the list instead of showing a non-functional prompt.

## 2023-11-20 - [Distinguishing cancellation from empty selection]
**Learning:** In interactive CLI prompts using `whiptail`, treating an empty checklist submission the same as a manual cancellation (`ESC`/`Cancel`) leads to misleading warnings ("Selection cancelled.") or treats intentional skips as errors.
**Action:** Always intercept the exit code of `whiptail` explicitly. If it returns non-zero, it was cancelled, so log properly and return early. If it returns 0 but the selection is empty, treat it as a successful intentional skip.

## 2025-03-25 - CLI Prompt Standardization
**Learning:** Raw `read -p` and `printf` prompts without visual distinction blend in with terminal output, causing users to miss the prompt or get confused about what input is expected. This reduces parsing speed and accessibility.
**Action:** Standardize interactive CLI prompt styling across the application using a dedicated helper function (like `log_ask`) that provides consistent, recognizable visual cues (e.g., a colored `[?]` prefix).

## $(date +%Y-%m-%d) - Add confirmation for destructive actions in CLI fallbacks
**Learning:** When falling back from interactive UI tools (like whiptail) to standard terminal I/O, developers sometimes accidentally bypass explicit user confirmation for destructive actions, causing silent overwrites.
**Action:** Always ensure that destructive actions (like file overwrites) have explicit user confirmation (e.g., using `log_ask`) in both interactive and standard terminal fallback paths, while properly handling fully non-interactive environments via `[[ ! -t 0 ]]`.

## 2025-03-25 - [Graceful Non-Interactive Prompts]
**Learning:** In CLI automation scripts, `read` commands for user input will hang indefinitely if executed in non-interactive CI/CD environments.
**Action:** Always include a `[[ ! -t 0 ]]` check at the beginning of custom prompt functions to detect non-interactive environments, returning safely and logging a warning to prevent the script from stalling.
