$cred = "protocol=https`nhost=github.com`n`n" | git credential fill
$tok = ($cred -split "`n" | Where-Object { $_ -like "password=*" }) -replace "^password=", ""
$h = @{ Authorization = "Bearer $tok"; 'User-Agent' = 'yijing' }
$jobs = Invoke-RestMethod -Uri 'https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/runs/33596444298/jobs' -Headers $h -TimeoutSec 30
$jobs.jobs | ForEach-Object { Write-Output ("{0} :: {1} :: {2}" -f $_.name, $_.conclusion, $_.steps.Count) }
$j = $jobs.jobs[0]
$log = Invoke-RestMethod -Uri ("https://api.github.com/repos/MMR-MINGriyue/yijing-app/actions/jobs/{0}/logs" -f $j.id) -Headers $h -TimeoutSec 30
$log | Out-File -Encoding utf8 'D:/workspace/yijing-app/.pwtest/flutter-analyze.log'
Write-Output "saved $($log.Length) chars"
# 找 error 段
$lines = $log -split "`n"
$errIdx = $lines | Select-String -Pattern 'error\s+-' | Select-Object -First 3 -ExpandProperty LineNumber
foreach ($i in $errIdx) {
  Write-Output "--- line $i context ---"
  $start = [Math]::Max(0, $i - 3)
  $end = [Math]::Min($lines.Count, $i + 5)
  $lines[$start..($end - 1)] | ForEach-Object { Write-Output $_ }
}