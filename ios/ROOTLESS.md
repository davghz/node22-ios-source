# Rootless iOS 15: Node.js 26.13.1

The current package builds genuine **Node.js 26.13.1 (Lithium LTS)** from the
pinned upstream release for arm64 iOS 15.0 and later. The source archive SHA256
is checked before extraction. The older Node.js 22 source and build scripts
remain available for reproducing the previous port.

On macOS with Xcode, Python 3, Rust 1.95.0, `dpkg-deb`, and `ldid` installed:

```sh
rustup toolchain install 1.95.0 --profile minimal
rustup target add --toolchain 1.95.0 aarch64-apple-ios
JOBS=2 bash ios/scripts/build-node26-ios.sh
bash ios/scripts/package-node26-rootless.sh ios/work/node-v26.13.1/out/Release/node
```

`IOS_SDK_PATH` selects an iPhoneOS device SDK (validated with 18.5), `IOS_MIN`
defaults to 15.0, and `NODE26_WORK`/`NODE26_SOURCE` can relocate build files.
The build keeps host macOS and target iOS compilers and Temporal Rust libraries
separate. It enables Temporal explicitly so a missing Rust toolchain fails the
build instead of silently omitting it. Node startup snapshots and code cache
are disabled for the cross build. OpenSSL uses its portable C implementation.
The iOS patch is tracked at `ios/patches/node26-ios.patch`.

TLS keeps Node’s normal bundled CA verification. On iOS, explicit
`--use-system-ca` or `--use-openssl-ca` uses the Procursus PEM certificate
store under `/var/jb/etc/ssl`, respecting `SSL_CERT_FILE`/`SSL_CERT_DIR`
overrides. Desktop-only macOS keychain trust-settings APIs are excluded;
certificate validation is never replaced with an always-success stub.

Output: `ios/dist/nodejs22-ios_26.13.1-1+rootless_iphoneos-arm64.deb`.
The package retains the `nodejs22-ios` ID for an in-place upgrade. It installs
its native executable under `/var/jb/usr/libexec/node26` and exposes `node26`,
`node`, and the legacy `node22` alias in `/var/jb/usr/bin`. All commands report
the real 26.13.1 runtime version. The wrappers retain stable V8 settings and
WebAssembly support. npm is a separate package and owns its own files.

On classic iOS 15, V8 code writes switch registered code pages between RW and
RX because the newer per-thread JIT APIs are unavailable. The wrapper uses
`--max-opt=0 --no-sparkplug --regexp-interpret-all --liftoff-only
--no-wasm-async-compilation --max-old-space-size=512
--disable-wasm-trap-handler`. JavaScript runs in the interpreter, and Wasm
compiles synchronously with Liftoff. Concurrent Wasm execution and compilation
across separate `worker_threads` isolates is unsupported on this port.

The package signs the executable with the port's iOS JIT entitlements plus the
standard CLI no-container entitlement. It also includes upstream licensing.

Run `node ios/scripts/rootless-smoke.cjs` on the device to test Temporal,
RegExp, crypto, file access, JSON, shell subprocesses, WebAssembly, verified
HTTPS to the npm registry, and the global fetch API.
The 26.13.1 build was validated on an iPhone X running rootless iOS 15.6.1,
including a JavaScript worker thread, the Procursus system/OpenSSL CA modes,
and rejection of an untrusted self-signed HTTPS certificate.
The previous 22.12.0 rootless package remains in `ios/dist` for rollback.
