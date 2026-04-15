> tl;dr: Copy files from `chrome/` into `~/Library/Application Support/Google/Chrome/Default/` on the new Mac with Chrome closed.

# Browser Settings

## Chrome

Files copied from `~/Library/Application Support/Google/Chrome/Default/`:

| File | Contents |
|------|----------|
| `Bookmarks` | All bookmarks |
| `Preferences` | Browser settings and preferences |
| `Secure Preferences` | Extension and security preferences |
| `Extensions/` | Installed extensions |

### Restore on new Mac

1. Install Chrome and launch it once, then quit
2. Copy files:
   ```bash
   DEST=~/Library/Application\ Support/Google/Chrome/Default
   SRC=~/code/home/browser-settings/chrome

   cp $SRC/Bookmarks $DEST/
   cp $SRC/Preferences $DEST/
   cp $SRC/Secure\ Preferences $DEST/
   cp -r $SRC/Extensions $DEST/
   ```
3. Launch Chrome

### Notes

- **Extensions** will be present but may need to re-authenticate or re-enable from `chrome://extensions`.
- To update these files before transferring, re-run the copy commands above with Chrome closed.
