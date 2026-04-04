## 2024-05-24 - Unnecessary Documentation Generation and Full Git Clones during System Bootstrapping
**Learning:** Generating RI and RDoc documentation during `gem install` introduces a significant performance bottleneck (adding several seconds) during a non-interactive setup script like this repository's bootstrapping process. Similarly, performing full `git clone` operations for simple plugins (like Zsh plugins or Vundle) wastes network bandwidth and disk space, slowing down the script for history that is never needed.
**Action:** Always use the `-N` or `--no-document` flag with `gem install` in automated scripts unless documentation is explicitly requested. Always use `--depth=1` for `git clone` operations when only the latest working tree is needed, such as when installing shell or editor plugins.

## 2024-05-25 - Lack of Early Returns in Bootstrap Scripts Causes Unnecessary Repeated Execution
**Learning:** In idempotent setup scripts, failing to check if an application (like VS Code or Chrome) is already installed before downloading keys, configuring repositories, and pulling large installation files (like a 100MB+ `.deb` file) results in significant wasted bandwidth and processing time on subsequent runs.
**Action:** Always include an early return check (e.g., `if command -v <app> >/dev/null 2>&1; then return 0; fi`) at the beginning of installation functions in bootstrap scripts to skip expensive processing when the target application is already present.

## 2025-02-14 - Unconditional Apt Update and Install for Already Installed Tools
**Learning:** Unconditionally running `apt update` and `apt install` for multiple developer tools in a loop or array adds significant network overhead and execution time when the tools are already installed.
**Action:** Check if the tool is already available via `command -v <app>` before appending its package to the installation list. If the list is empty, early return or skip `apt update` and `apt install` entirely.

## 2024-05-24 - [Early Returns Before Prerequisites]
**Learning:** In setup scripts, checking application installation states (e.g., using `command -v`) before running prerequisite steps like `apt update` avoids unnecessary and expensive operations if the target application is already installed.
**Action:** Always implement early returns by checking `command -v` before downloading prerequisites or large files if the target application is already installed.

## 2025-02-14 - Cache expensive redundant external commands
**Learning:** Calling the same expensive external command (e.g., `fc-list`) multiple times in a script causes redundant sub-process overhead, unnecessarily slowing down execution, especially when the command's output is not expected to change between checks.
**Action:** Cache the result of expensive or redundant external commands in a local variable if the same check is required multiple times within a script.

## 2025-02-14 - Skip Redundant Apt Updates
**Learning:** When a setup script iteratively checks and installs multiple small packages (e.g., CLI tools via apt), running `apt update` before every single installation adds unnecessary network overhead and execution time.
**Action:** Implement a state variable (e.g., `APT_UPDATED=0`) to cache the update state. Wrap `apt update` in a check against this variable and flip it to `1` after the first run to ensure the package list is updated exactly once per script execution.
