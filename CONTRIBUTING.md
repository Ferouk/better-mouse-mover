# Contributing

Thanks for taking the time to improve Better Mouse Mover.

## Getting Started

1. Fork the repository and create a branch for your change.
2. Make sure you have macOS 13 or newer and Swift from Xcode Command Line Tools or Xcode.
3. Build the app locally:

```sh
make app
```

4. Run it locally:

```sh
make run
```

## Development Notes

- Keep changes focused and small when possible.
- Follow the existing Swift/AppKit style in `Sources/BMM/main.swift`.
- Do not add network calls. The app is intended to stay local-only.
- Keep the app lightweight and menu bar focused.
- If you add resources, include them under `Resources/` and make sure the app bundle copies them correctly.

## Testing

Before opening a pull request, run:

```sh
make app
```

Then verify:

- The app launches from `.build/release/BMM.app`.
- The menu bar item appears.
- Accessibility permission messaging still works.
- Cursor movement still happens only after the idle threshold.
- The built binary remains universal:

```sh
lipo -info .build/release/BMM.app/Contents/MacOS/BMM
```

The output should include both `arm64` and `x86_64`.

## Pull Requests

When opening a pull request, include:

- What changed.
- Why the change is useful.
- How you tested it.
- Any screenshots or screen recordings if the menu or user-facing behavior changed.
