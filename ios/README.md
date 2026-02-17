# node22-ios-source

This repository captures the current iOS arm64 Node.js 22 working tree, including:

- Source-level patches under `ios/patches/current-worktree.patch`
- Reproducible iOS build wrappers and scripts under `ios/scripts/`
- Debian packaging templates under `ios/packaging/`

Patch base commit:

- `a21425ba4ae0931bfe900703c14daa692b3e9b68`

## Prerequisites

- macOS with Xcode command line tools (`xcrun`, `clang`, `clang++`)
- `python3`
- `rsync`
- `dpkg-deb`
- optional for deploy/tests: `sshpass`
- optional for signing: `ldid`

## Build (iOS arm64)

```bash
./ios/scripts/build-node22-ios.sh
```

Environment knobs:

- `JOBS` (default: logical CPU count)
- `PYTHON_BIN` (default: `python3` in PATH)
- `IOS_MIN` (default: `13.0`)
- `CLEAN=0` to keep existing `out/`
- `V=1` for verbose make output

The build output binary is:

- `out/Release/node` (iOS target binary)

## Package `.deb`

```bash
VERSION=22.12.0-18 ./ios/scripts/package-node22-ios-deb.sh
```

Output:

- `ios/dist/nodejs22-ios_<version>_iphoneos-arm.deb`

Package layout:

- `/usr/local/bin/node22`
- `/usr/local/bin/npm22`
- `/usr/local/bin/npx22`
- `/usr/local/lib/node22/node_modules/npm`

## Install on device

```bash
DEVICE=root@10.0.0.9 PASS=alpine ./ios/scripts/install-node22-ios-device.sh
```

Or install a specific artifact:

```bash
DEVICE=root@10.0.0.9 PASS=alpine ./ios/scripts/install-node22-ios-device.sh ios/dist/nodejs22-ios_22.12.0-18_iphoneos-arm.deb
```

## Smoke test on device

```bash
DEVICE=root@10.0.0.9 PASS=alpine ./ios/scripts/smoke-test-device.sh
```

## Reapply patch on a fresh checkout

```bash
./ios/scripts/reapply-current-patch.sh
```
