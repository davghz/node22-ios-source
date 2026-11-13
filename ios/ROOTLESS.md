# Rootless iOS 15

`ios/scripts/package-rootless-deb.sh` repackages the tested `v22.12.0-26-ios`
release for rootless iOS. The interpreter remains Node.js **22.12.0**; this is
a packaging update, not an upgrade to a newer Node release.

```sh
gh release download v22.12.0-26-ios -R davghz/node22-ios-source -p '*.deb'
bash ios/scripts/package-rootless-deb.sh nodejs22-ios_22.12.0-26_iphoneos-arm.deb
```

Output: `ios/dist/nodejs22-ios_22.12.0-27+rootless_iphoneos-arm64.deb`.

The package installs `/var/jb/usr/bin/node22` and a `node` wrapper retaining
the port's stable V8 flags. npm is a separate package from `npm-ios-source`.
The binary retains its iOS JIT entitlements and gains the standard CLI
no-container entitlement. It only links to Apple system libraries.

Validated as `mobile` on an iPhone X running rootless palera1n and iOS 15.6.1:
version, JavaScript, file access, JSON, shell subprocesses, WebAssembly, and
verified HTTPS to the npm registry, using both `node` and `node22`.
