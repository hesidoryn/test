$appName = "TestTask"
$appPool = "JuniorTaskPool"
$ip = (Get-NetIPConfiguration).IPV4Address.IPAddress
$port = 81
$repo = "https://github.com/hesidoryn/test.git"
$folderPath = "C:\SiteFolder"

Restart-Service w3svc -Force
$webServerStatus = (Get-WindowsFeature -Name "Web-Server").InstallState
if(-Not ($webServerStatus -eq "Installed")) {
  Install-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature -IncludeManagementTools
}

New-Item -Path IIS:\AppPools\$appPool
Set-ItemProperty -Path IIS:\AppPools\$appPool -Name managedRuntimeVersion -Value 'v4.0'

git clone $repo $folderPath
icacls $folderPath /setowner "Administrator" > null
icacls $folderPath /grant:r "Administrators:(F)" /T > null
icalcs $folderPath /grant:r "Users:(R)" /T > null

echo "Waiting for creating new website"
New-Website -Name $appName -Port $port -IPAddress $ip -PhysicalPath $folderPath -ApplicationPool $appPool
echo "done"

echo "Check availability new created website"
$ip = (Get-NetIPConfiguration).IPV4Address.IPAddress
$Result = Invoke-WebRequest -URI ${ip}:${port}
$status = $Result.StatusCode

if($status -eq 200){
  $body = @{
    text = "Response of test app is ${status}"
  } | ConvertTo-Json
  $uri = 'https://hooks.slack.com/services/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'

  Invoke-WebRequest -Method Post -Uri $uri -Body $body
}