const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const docs = fs.readFileSync(path.join(root, 'SYSTEM_DOCUMENTATION.md'), 'utf8');
for (const marker of ['docs-check: lab4-ansible', '127.0.0.1', 'cleanup', 'idempotency']) {
  assert(docs.includes(marker), `Missing documentation: ${marker}`);
}
for (const file of ['inventory.ini', 'ansible.cfg', 'playbook-webserver.yml', 'playbook-full.yml']) {
  assert(docs.includes(file), `Undocumented lab file: ${file}`);
  assert(fs.existsSync(path.join(root, file)), `Missing ${file}`);
}
console.log('docs-check: PASS');
