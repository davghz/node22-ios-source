const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const cp = require('node:child_process');
const https = require('node:https');
const crypto = require('node:crypto');

assert.equal(process.versions.node, '26.13.1');
assert.equal(Temporal.PlainDate.from('2026-11-12').add({days:1}).toString(), '2026-11-13');
assert.equal(/a(b+)c/.exec('abbbc')[1], 'bbb');
assert.equal(crypto.createHash('sha256').update('abc').digest('hex'),
  'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
console.log('PASS: genuine Node.js 26.13.1, Temporal, RegExp, and crypto');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'node22-rootless-'));
try {
  const file = path.join(dir, 'check.json');
  fs.writeFileSync(file, JSON.stringify({answer: 42}));
  assert.equal(JSON.parse(fs.readFileSync(file)).answer, 42);
  assert.equal(cp.execFileSync('/var/jb/bin/sh', ['-c', 'printf shell-ok'], {encoding:'utf8'}), 'shell-ok');
  const bytes = Uint8Array.from([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,7,10,1,6,97,110,115,119,101,114,0,0,10,6,1,4,0,65,42,11]);
  assert.equal(new WebAssembly.Instance(new WebAssembly.Module(bytes)).exports.answer(), 42);
  console.log('PASS: filesystem, JSON, shell subprocess, WebAssembly');
  WebAssembly.compile(bytes).then(module => {
    assert.equal(new WebAssembly.Instance(module).exports.answer(), 42);
    console.log('PASS: Promise-based WebAssembly compilation');
  }).catch(error => { console.error(error); process.exitCode = 1; });
} finally {
  fs.rmSync(dir, {recursive:true, force:true});
}
https.get('https://registry.npmjs.org/-/ping', {timeout:15000}, response => {
  assert.equal(response.statusCode, 200);
  response.resume();
  response.on('end', () => console.log('PASS: verified HTTPS to npm registry'));
}).on('error', error => { console.error(error); process.exitCode = 1; });

fetch('https://registry.npmjs.org/-/ping', {signal:AbortSignal.timeout(15000)})
  .then(response => {
    assert.equal(response.status, 200);
    return response.json();
  })
  .then(() => console.log('PASS: global fetch and HTTP parser'))
  .catch(error => { console.error(error); process.exitCode = 1; });
