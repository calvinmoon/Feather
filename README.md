# Featherwright

[![GitHub Release](https://img.shields.io/github/v/release/akameslayer/Featherwright?include_prereleases)](https://github.com/akameslayer/Featherwright/releases)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/akameslayer/Featherwright/total)](https://github.com/akameslayer/Featherwright/releases)
[![GitHub License](https://img.shields.io/github/license/akameslayer/Featherwright?color=%23C96FAD)](https://github.com/akameslayer/Featherwright/blob/main/LICENSE)

**Featherwright** is a community-driven fork of [Feather](https://github.com/claration/Feather) — the on-device iOS app that signs and installs applications, using certificate pairs and various installation techniques to allow apps to install to your device. This is an entirely stock application and uses built-in features to be able to do this!

A *wright* is a maker — a shipwright builds ships, a wheelwright builds wheels. **Featherwright** is where Feather gets built now, in the open, by whoever wants to help.

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="Images/Image-dark.png"><source media="(prefers-color-scheme: light)" srcset="Images/Image-light.png"><img alt="Featherwright" src="Images/Image-light.png"></picture></p>

## Why this fork exists

Upstream Feather is a great app, but its maintainer keeps a tight gate: pull requests sit unreviewed or get declined, even when they fix real problems people are having. That's a legitimate way to run a project — but it leaves users stuck without fixes, and contributors with good work that goes nowhere.

Featherwright is the answer to that:

- **If you're a user** who wanted a fix, a feature, or a tweak that upstream wouldn't take — it probably lives here.
- **If you're a developer whose PR was rejected, ignored, or closed upstream** — you are explicitly welcome here. Bring it over. Open an issue first for anything large, but the bar for "why should this exist?" is: *does someone want it?* That's the bar.

## Drop-in compatible with Feather

Featherwright deliberately keeps the **same bundle identifier** as upstream (`thewonderofyou.Feather`), so:

- Installing Featherwright over Feather keeps your certificates, signed apps, and settings.
- Want to go back to upstream? Just install it over Featherwright the same way. Switch as often as you like.
- The home screen icon says **Featherwright** so you always know which build you're running.

## Features

Everything Feather has, plus what lands here:

- User friendly, and clean UI.
- Sign and install applications.
- Supports [AltStore](https://faq.altstore.io/distribute-your-apps/make-a-source#apps) repositories.
- View detailed information about apps and your certificates.
- Configurable signing options mainly for modifying the app, such as appearance and allowing support for the files app.
  - This includes patching apps for compatibility and Liquid Glass.
- Tweak support for advanced users, using [Ellekit](https://github.com/tealbathingsuit/ellekit) for injection.
  - Supports injecting `.deb` and `.dylib` files.
- Actively maintained: always ensuring most apps get installed properly.
- No tracking or analytics, ensuring user privacy.
- Open source and free.

### What's different so far

- **Uninstall & reinstall** offered when an idevice install hits a mismatched certificate.
- **Cancel an ongoing signing/installation** by dismissing the pane.
- **Pairing file status button** in tunnel settings.
- Tap a signed app in the library to open **Get Info**.
- Option to **delete the signed app** after it's installed.
- **In-app update check** — the About page tells you when a new release is out.
- Detects when **Featherwright itself was signed** with one of your certificates, and always shows the PPQ check.
- Fixed the **app icon selection** checkmark.
- No more **indefinite hang** when connecting to a device while a VPN is unreachable.
- **Donation/sponsor prompts removed.**
- Maintenance: `IDeviceKit` forked and patched, release CI fixed.

Check the [commit history](https://github.com/akameslayer/Featherwright/commits/main/) for the latest.

## Download

Visit [releases](https://github.com/akameslayer/Featherwright/releases) and get the latest `.ipa`.

<a href="https://celloserenity.github.io/altdirect/?url=https://raw.githubusercontent.com/akameslayer/Featherwright/refs/heads/main/app-repo.json" target="_blank">
   <img src="https://github.com/CelloSerenity/altdirect/blob/main/assets/png/AltSource_Blue.png?raw=true" alt="Add AltSource" width="200">
</a>
<a href="https://github.com/akameslayer/Featherwright/releases/latest/download/Feather.ipa" target="_blank">
   <img src="https://github.com/CelloSerenity/altdirect/blob/main/assets/png/Download_Blue.png?raw=true" alt="Download .ipa" width="200">
</a>

## How does it work?

Visit the [HOW IT WORKS](./HOW_IT_WORKS.md) page.

## Building from source

Requirements: Xcode 16.0+, Swift 6.0, deployment target iOS 16.0.

```sh
git clone https://github.com/akameslayer/Featherwright --recursive
cd Feather
make iphoneos      # produces packages/Feather.ipa
```

`Zsign` is a git submodule, so `--recursive` is required. `make deps` fetches the localhost SSL cert material; `make maccatalyst` builds a Mac Catalyst build. See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## Contributing

**Rejected upstream? Welcome home.** If the upstream maintainer closed your PR — for any reason — open it here. If it fixes something, respects the stock-iOS approach, and doesn't introduce exploits or certificate theft, there's a very good chance it lands.

Please follow the [contribution rules](./CONTRIBUTING.md) and the [Code of Conduct](./CODE_OF_CONDUCT.md). Large changes: open an issue first so we can talk it through. Typo fixes, cleanups, and localizations are always welcome.

## Acknowledgements

Featherwright is a fork of [claration/Feather](https://github.com/claration/Feather). None of this exists without it.

- [Samara](https://github.com/claration) — the maker of Feather
- [idevice](https://github.com/jkcoxson/idevice) - Backend for builds with this included, used for communication with `installd`.
- [*.backloop.dev](https://backloop.dev/) - localhost with public CA signed SSL certificate
- [Vapor](https://github.com/vapor/vapor) - A server-side Swift HTTP web framework.
- [Zsign](https://github.com/zhlynn/zsign) - Allowing to sign on-device, reimplimented to work on other platforms such as iOS.
- [LiveContainer](https://github.com/LiveContainer/LiveContainer) - Fixes/some help
- [Nuke](https://github.com/kean/Nuke) - Image caching.
- [Asspp](https://github.com/Lakr233/Asspp) - Some code for setting up the http server.
- [plistserver](https://github.com/nekohaxx/plistserver) - Hosted on https://api.palera.in.

## License

This project is licensed under the GPL-3.0 license. You can see the full details of the license [here](https://github.com/akameslayer/Featherwright/blob/main/LICENSE). It's under this specific license because I wanted to make a project that is transparent to the user thats related to certificate paired sideloading, before this project there weren't any open source projects that filled in this gap.

By contributing to this project, you agree to license your code under the GPL-3.0 license as well (including agreeing to license exceptions), ensuring that your work, like all other contributions, remains freely accessible and open.
