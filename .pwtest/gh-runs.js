/* 轮询 GitHub Actions (取最新一个 Flutter run) */
const { execSync } = require('child_process');
const H = require('https');
const cred = execSync('git credential fill', { input: 'protocol=https\nhost=github.com\n\n', encoding: 'utf8' });
const tok = (cred.match(/^password=(.+)$/m) || [])[1];
const opts = { headers: { Authorization: 'Bearer ' + tok, 'User-Agent': 'yijing' }, rejectUnauthorized: false };
H.get('https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs?per_page=5', opts, r => {
  let d = ''; r.on('data', c => d += c); r.on('end', () => {
    const j = JSON.parse(d);
    j.workflow_runs.forEach(x => console.log(x.id, x.name, x.head_sha.slice(0,7), x.status, x.conclusion, x.created_at));
  });
});