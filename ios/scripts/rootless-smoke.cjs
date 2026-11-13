const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const cp = require('node:child_process');
const https = require('node:https');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'node22-rootless-'));
try {
  const file = path.join(dir, 'check.json');
  fs.writeFileSync(file, JSON.stringify({answer: 42}));
  assert.equal(JSON.parse(fs.readFileSync(file)).answer, 42);
  assert.equal(cp.execFileSync('/var/jb/bin/sh', ['-c', 'printf shell-ok'], {encoding:'utf8'}), 'shell-ok');
  const bytes = Uint8Array.from([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,7,10,1,6,97,110,115,119,101,114,0,0,10,6,1,4,0,65,42,11]);
  assert.equal(new WebAssembly.Instance(new WebAssembly.Module(bytes)).exports.answer(), 42);
  console.log('PASS: filesystem, JSON, shell subprocess, WebAssembly');
} finally {
  fs.rmSync(dir, {recursive:true, force:true});
}
https.get('https://registry.npmjs.org/-/ping', {timeout:15000}, response => {
  assert.equal(response.statusCode, 200);
  response.resume();
  response.on('end', () => console.log('PASS: verified HTTPS to npm registry'));
}).on('error', error => { console.error(error); process.exitCode = 1; });
