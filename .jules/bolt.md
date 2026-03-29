## 2024-05-24 - Unnecessary Documentation Generation and Full Git Clones during System Bootstrapping
**Learning:** Generating RI and RDoc documentation during `gem install` introduces a significant performance bottleneck (adding several seconds) during a non-interactive setup script like this repository's bootstrapping process. Similarly, performing full `git clone` operations for simple plugins (like Zsh plugins or Vundle) wastes network bandwidth and disk space, slowing down the script for history that is never needed.
**Action:** Always use the `-N` or `--no-document` flag with `gem install` in automated scripts unless documentation is explicitly requested. Always use `--depth=1` for `git clone` operations when only the latest working tree is needed, such as when installing shell or editor plugins.

## 2024-05-25 - Lack of Early Returns in Bootstrap Scripts Causes Unnecessary Repeated Execution
**Learning:** In idempotent setup scripts, failing to check if an application (like VS Code or Chrome) is already installed before downloading keys, configuring repositories, and pulling large installation files (like a 100MB+ `.deb` file) results in significant wasted bandwidth and processing time on subsequent runs.
**Action:** Always include an early return check (e.g., `if command -v <app> >/dev/null 2>&1; then return 0; fi`) at the beginning of installation functions in bootstrap scripts to skip expensive processing when the target application is already present.

## 2025-02-14 - Unconditional Apt Update and Install for Already Installed Tools
**Learning:** Unconditionally running `apt update` and `apt install` for multiple developer tools in a loop or array adds significant network overhead and execution time when the tools are already installed.
**Action:** Check if the tool is already available via `command -v <app>` before appending its package to the installation list. If the list is empty, early return or skip `apt update` and `apt install` entirely.
