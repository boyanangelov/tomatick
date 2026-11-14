# Pomodoro

A tiny macOS menu-bar Pomodoro timer. It counts down in the menu bar and plays a sound when a session ends.

## Why

Most Pomodoro apps want an account, a window, or a subscription. This one is a single small app that lives in the menu bar:

- **Always visible, never in the way.** The countdown sits next to the clock (`🍅 24:13` while focusing, `☕ 04:59` on a break), and there's no Dock icon or window.
- **A sound when time's up.** You hear when a focus session or break ends, so you don't have to keep checking.
- **Your own rhythm.** Set focus, short break and long break lengths, and how many sessions come before a long break.
- **You stay in control.** Nothing auto-starts; press Start when you're ready for the next session.

## Download

Grab `Pomodoro.zip` from the [latest release](https://github.com/boyanangelov/pomodoro-menubar/releases/latest), unzip it and move `Pomodoro.app` to Applications.

The app isn't signed with an Apple Developer ID, so macOS blocks it the first time. To open it anyway: right-click the app and choose **Open**, or go to **System Settings ▸ Privacy & Security** and click **Open Anyway**. You can also clear the quarantine flag from a terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Pomodoro.app
```

## Requirements

- An Apple Silicon Mac (M1 or later) running macOS 13 (Ventura) or later
- To build from source: the Xcode Command Line Tools (`xcode-select --install`)

## Build & run

```sh
./build.sh
open Pomodoro.app
```

Click the 🍅 in the menu bar to start, pause, reset or skip a session, and to change durations. Settings are saved between launches.

| Setting | Range | Default |
| --- | --- | --- |
| Focus | 1–90 min | 25 min |
| Short break | 1–30 min | 5 min |
| Long break | 1–60 min | 15 min |
| Long break every | 2–8 sessions | 4 sessions |

## Start at login

Tick **Start at Login** in the menu-bar panel. It writes a LaunchAgent (`~/Library/LaunchAgents/io.github.boyanangelov.pomodoro.plist`) pointing at the running copy of the app, and unticking removes it. The change applies from your next login.

Or install it into `~/Applications` and register it for login in one go:

```sh
./install.sh
```

The script prints the uninstall command.

## License

[MIT](LICENSE)
