// Real parser coverage for every bilingual template diagram. Install the test
// dependencies into an isolated prefix and pass its node_modules directory:
// npm install --prefix /tmp/ssot-mermaid mermaid@11.12.0 jsdom@26.1.0
// node tests/test-mermaid-templates.mjs /tmp/ssot-mermaid/node_modules
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const modules = process.argv[2];
assert.ok(modules, 'Pass the isolated node_modules directory');
const requireTest = createRequire(resolve(modules, '__test__.cjs'));
const { JSDOM } = requireTest('jsdom');
const dom = new JSDOM('');
globalThis.window = dom.window;
globalThis.document = dom.window.document;
const { default: mermaid } = await import(pathToFileURL(requireTest.resolve('mermaid')));
mermaid.initialize({ startOnLoad: false });

// An HTML comment inside a fence is not a Mermaid comment: the parser rejects
// it even though Markdown tooling looks fine. Keep that rejection in the
// regression so a future wrapper cannot silently strip invalid syntax.
await assert.rejects(mermaid.parse('<!-- note -->\nflowchart LR\n A --> B'));
await assert.rejects(mermaid.parse('%% note\nflowchart LR\n A -->'));

const root = resolve(fileURLToPath(new URL('..', import.meta.url)),
  'skills/ssot-bootstrap/assets/templates');
let count = 0;
for (const language of ['en', 'zh']) {
  let languageCount = 0;
  for (const filename of (await readdir(resolve(root, language))).sort()) {
    if (!filename.endsWith('.md')) continue;
    const markdown = await readFile(resolve(root, language, filename), 'utf8');
    for (const [index, match] of [...markdown.matchAll(/^```mermaid\s*\n([\s\S]*?)^```\s*$/gm)].entries()) {
      const source = match[1];
      assert.doesNotMatch(source, /<!--/, `${language}/${filename}: HTML comment inside a Mermaid fence`);
      await assert.doesNotReject(() => mermaid.parse(source), `${language}/${filename} diagram ${index + 1}`);
      count++;
      languageCount++;
    }
  }
  assert.ok(languageCount > 0, `No diagrams found for ${language}`);
}
console.log(`PASS: ${count} shipped diagrams parsed; HTML comment and malformed grammar rejected`);
dom.window.close();
