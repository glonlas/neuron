# Troubleshooting

## Common errors

| Error | Fix |
|-------|-----|
| `Config not found at ~/.llm-wiki/config.yaml` | Run `make install` to create the config directory |
| `vault_path not set` | Edit `~/.llm-wiki/config.yaml` and set your vault path |
| `Vault not found at ...` | Check that the path in `config.yaml` is correct and the directory exists |
| `No user_vaults configured` | Add at least one vault path under `user_vaults:` in `config.yaml` |
| Scripts fail on Linux | Check `bash --version` is 4+; ensure scripts are executable (`chmod +x scripts/*.sh`) |

## Doctor

Run the setup validator for a comprehensive check:

```sh
scripts/doctor.sh
```

It verifies: bash version, config files, vault paths, user vaults, and script permissions.
