/* 完整下载 Analyze 日志到文件 */
const { execSync } = require('child_process');
const H = require('https');
const fs = require('fs');
const RUN_ID = '33596444298';
const cred = execSync('git credential fill', { input: 'protocol=https\nhost=github.com\n\n', cwd: 'D:/workspace/yijing-app', encoding: 'utf8' });
const tok = (cred.match(/^password=(.+)$/m) || [])[1];
const opts = { headers: { Authorization: 'Bearer ' + tok, 'User-Agent': 'yijing' }, rejectUnauthorized: false };

H.get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs/${RUN_ID}/jobs`, opts, r => {
  let d = ''; r.on('data', c => d += c); r.on('end', () => {
    const j = JSON.parse(d);
    const job = j.jobs[0];
    H.get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/jobs/${job.id}/logs`, opts, r2 => {
      let log = ''; r2.on('data', c => log += c); r2.on('end', () => {
        fs.writeFileSync('D:/workspace/yijing-app/.pwtest/flutter-analyze.log', log);
        console.log('saved', log.length, 'chars');
        /* 截取含 error / line 段 */
        const lines = log.split('\n');
        const errLines = lines.filter((l, i) => /error|warning|line\s+\d+/.test(l) && i > 100);
        console.log('--- error/warning context ---');
        console.log(errLines.slice(0, 30).join('\n'));
      });
    });
  });
});