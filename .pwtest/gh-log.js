/* 拉取失败的 job 日志 */
const { execSync } = require('child_process');
const H = require('https');
const RUN_ID = '33596444298';
const cred = execSync('git credential fill', { input: 'protocol=https\nhost=github.com\n\n', encoding: 'utf8' });
const tok = (cred.match(/^password=(.+)$/m) || [])[1];
const opts = { headers: { Authorization: 'Bearer ' + tok, 'User-Agent': 'yijing' }, rejectUnauthorized: false };

H.get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs/${RUN_ID}/jobs`, opts, r => {
  let d = ''; r.on('data', c => d += c); r.on('end', () => {
    const j = JSON.parse(d);
    const job = j.jobs[0];
    const failStep = job.steps.find(s => s.conclusion === 'failure');
    if (!failStep) { console.log('no fail step'); return; }
    /* job logs 端点: /jobs/{id}/logs */
    const logOpts = { ...opts, headers: { ...opts.headers, Accept: 'application/vnd.github+json' } };
    H.get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/jobs/${job.id}/logs`, logOpts, r2 => {
      let log = ''; r2.on('data', c => log += c); r2.on('end', () => {
        /* 截取失败步骤附近 (grep 上下文) */
        const idx = log.indexOf('Analyze');
        const start = Math.max(0, idx - 500);
        console.log('--- Analyze step log snippet ---');
        console.log(log.slice(start, idx + 3000));
      });
    });
  });
});