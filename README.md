# node22-ios-source

Node.js v22.12.0 cross-compiled for jailbroken iOS (arm64).

## What it is

This repository contains the Node.js v22.12.0 source tree with iOS-specific patches,
build scripts, and DEBIAN packaging to produce a side-by-side install as `node22` on
jailbroken iPhones.

- Installs to `/usr/local/bin/node22`
- Bundled npm available at `/usr/local/lib/node22/node_modules/npm`
- Binary is signed on-device with JIT + unsigned-exec entitlements via `ldid`

**Tested device:** iPhone X (`iPhone10,3`), iOS 13.2.3

## Toolchain overview

```
node22-ios-source  →  build  →  nodejs22-ios.deb  (Node runtime)
                                       ↓ (dependency)
npm-ios-source     →  build  →  npm22-ios.deb     (package manager)
```

Install `nodejs22-ios` first, then install `npm22-ios`. See:
[npm-ios-source](https://github.com/davghz/npm-ios-source)

## Build requirements

- macOS with Xcode command line tools (`xcrun`)
- `python3` in PATH (or set `PYTHON_BIN`)
- `ldid` (can be installed via Homebrew: `brew install ldid`)
- iOS SDK — script defaults to `~/theos/sdks/iPhoneOS13.7.sdk`
  (set `IOS_SDK_PATH` to override)

## Build steps

```bash
# Clone this repo
git clone https://github.com/davghz/node22-ios-source.git
cd node22-ios-source

# Run the cross-compilation script
bash ios/scripts/build-node22-ios.sh

# Output binary
# out/Release/node
```

Optional environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `JOBS` | logical CPU count | Parallel make jobs |
| `PYTHON_BIN` | `python3` | Python interpreter |
| `IOS_MIN` | `13.0` | Minimum iOS version |
| `IOS_SDK_PATH` | `~/theos/sdks/iPhoneOS13.7.sdk` | iOS SDK path |
| `CLEAN` | `1` | Set to `0` to skip `rm -rf out` |

## Package the deb

After building, use `ios/scripts/package-node22-ios-deb.sh` to assemble the deb:

```bash
bash ios/scripts/package-node22-ios-deb.sh
# Output: nodejs22-ios_22.12.0-18_iphoneos-arm.deb
```

The `DEBIAN/` directory at the repo root contains the packaging metadata used by this script.

## Install on device

```bash
# Copy and install
scp nodejs22-ios_22.12.0-18_iphoneos-arm.deb root@<device-ip>:/tmp/
ssh root@<device-ip> dpkg -i /tmp/nodejs22-ios_22.12.0-18_iphoneos-arm.deb
```

The `postinst` script runs `ldid` automatically to sign the binary with iOS JIT entitlements.

Or use the deploy helper:

```bash
DEVICE=root@<device-ip> bash ios/scripts/install-node22-ios-device.sh nodejs22-ios_22.12.0-18_iphoneos-arm.deb
```

## Verify on device

```bash
/usr/local/bin/node22 --version
# v22.12.0
```

## Next step

Install npm: [npm-ios-source](https://github.com/davghz/npm-ios-source)

```bash
dpkg -i npm22-ios_10.9.0-2_iphoneos-arm.deb
/usr/local/bin/npm22 -v   # 10.9.0
/usr/local/bin/npx22 -v   # 10.9.0
```
