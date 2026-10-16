# Vorssaint settings

`settings.plist` is Vorssaint's own export (Settings -> Advanced -> Export), which leaves out machine-specific state. `scripts/post-install.sh` restores it on a Mac where Vorssaint has no settings yet.

To update it, export again and convert it to XML so diffs stay readable:

```bash
plutil -convert xml1 -o vorssaint/settings.plist ~/Downloads/"Vorssaint Settings.plist"
```
