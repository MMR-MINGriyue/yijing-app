/* 轮询特定 run 完成 (Flutter 编译约 10-20 分钟) */
const { execSync } = require('child_process');
const H = require('https');
const RUN_ID = '33596444298';
const cred = execSync('git credential fill', { input: 'protocol=https\nhost=github.com\n\n', encoding: 'utf8' });
const tok = (cred.match(/^password=(.+)$/m) || [])[1];
const opts = { headers: { Authorization: 'Bearer ' + tok, 'User-Agent': 'yijing' }, rejectUnauthorized: false };

function get(url) {
  return new Promise((res, rej) => {
    H.get(url, opts, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(d)); }).on('error', rej);
  });
}

(async () => {
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 60000));
    const body = await get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs/${RUN_ID}`);
    const j = JSON.parse(body);
    console.log(`[${i + 1}] ${j.status} / ${j.conclusion || '-'} (${j.head_sha?.slice(0, 7)})`);
    if (j.status === 'completed') {
      // 拉 jobs 看哪步失败
      const jobs = await get(`https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs/${RUN_ID}/jobs`);
      const jj = JSON.parse(jobs);
      jj.jobs.forEach(job => {
        console.log(`  job: ${job.name} → ${job.conclusion} (${job.steps?.length || 0} steps)`);
        if (job.conclusion === 'failure' && job.steps) {
          job.steps.filter(s => s.conclusion === 'failure').forEach(s => console.log(`    FAIL step: ${s.name}`));
        }
      });
      break;
    }
  }
})();