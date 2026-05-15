# Better Mouse Mover

A tiny native macOS menu bar app that keeps your Mac active by moving the mouse cursor only after the system has been idle.

## Requirements

- Apple Silicon or Intel Mac
- macOS 13 or newer
- Swift from Xcode Command Line Tools or Xcode

## Build

```sh
make app
```

By default, this creates a universal app with native `arm64` and `x86_64` slices. To build only one architecture:

```sh
make app ARCHS=x86_64
```

The app bundle is created at:

```text
.build/release/BMM.app
```

## Run

```sh
make run
```

Better Mouse Mover appears in the macOS menu bar. It starts automatically, checks idle state every 5 seconds, and nudges the cursor by 1 point after 60 seconds of no keyboard or mouse activity. You can also choose a custom menu bar icon from the `Tray Icon` menu.

`make run` opens the existing app bundle without rebuilding it. This helps macOS keep the Accessibility permission attached to the same signed app. Run `make app` again only when you want to rebuild.

For the most reliable Accessibility permission behavior while testing locally, install and run the app from your user Applications folder:

```sh
make install
make run-installed
```

## Accessibility Permission

macOS requires Accessibility permission before an app can post mouse movement events.

Open:

```text
System Settings > Privacy & Security > Accessibility
```

Then enable Better Mouse Mover. If it is already running, quit and reopen it after granting permission. If the permission keeps turning off, remove the old Better Mouse Mover entry, run `make install` once, open the installed app with `make run-installed`, and grant permission to that installed app.

The development build is ad-hoc signed by default. For a more stable local identity, you can sign with a local or Apple code signing certificate:

```sh
make install SIGN_IDENTITY="Your Code Signing Identity"
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, testing, and pull request guidelines.

## License

Better Mouse Mover is available under the [MIT License](LICENSE).

## Notes

- The release build targets `arm64` and `x86_64`, so it is native on Apple Silicon and Intel Macs.
- The app is not notarized or signed for distribution.
- No network calls are made by the app.
