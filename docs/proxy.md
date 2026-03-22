# Proxy Configuration

If your network requires a proxy, create one or more profiles under `proxy/` and activate one of them with the `proxy` step.

## Quick Start

```bash
mkdir -p proxy
cp .proxy.env.example proxy/work.env
```

Then edit the profile with your actual values:

```bash
HTTP_PROXY=http://proxy.example.com:8080
HTTPS_PROXY=http://proxy.example.com:8080
NO_PROXY=localhost,127.0.0.1,::1
```

Activate it with:

```bash
./scripts/proxy.sh
```

Or directly:

```bash
./scripts/proxy.sh use work
```

When `./setup.sh full` runs, the `proxy` step only auto-selects a profile when:

- `.proxy.env` is already active, or
- exactly one `proxy/*.env` profile exists

## Behavior

- The active profile is exposed as repository-local `.proxy.env`.
- `.proxy.env` is loaded automatically by setup steps that use the network.
- Both uppercase and lowercase proxy environment variables are synchronized.
- `sudo apt ...` and `sudo gem ...` commands receive the proxy variables as well.
- If you already export proxy variables in your shell, the scripts will use them even without `.proxy.env`.
- If multiple profiles exist, the `proxy` step lets you choose one with `whiptail` or a terminal prompt.
