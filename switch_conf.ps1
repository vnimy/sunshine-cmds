param(
    [string]$GPU="", # GPU名称，通过dxgi-info获取，如"AMD Radeon 780M Graphics"

    [string]$Output="", # 显示器，通过dxgi-info获取，如"ZakoHDR"
    
    <#
    投影模式，覆盖DisplayDevicePrep参数
    Work - 办公场景，扩展屏幕，覆盖DisplayDevicePrep参数值为ensure_active
    Game - 游戏场景，仅第二屏幕，覆盖DisplayDevicePrep参数值为ensure_only_display
    #>
    [string]$Scene="Game",

    <#
    串流时显示器组合状态设定
    no_operation - 无操作
    ensure_active - 自动激活指定显示器
    ensure_primary - 自动激活指定显示器并设置为主显示器
    ensure_only_display - 禁用其他显示器，只启用指定显示器
    #>
    [string]$DisplayDevicePrep="ensure_active",

    [string]$HostName=$env:COMPUTERNAME # 主机名称
)

# 检查是否有管理员权限
function Check-IsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
    { Write-Output $true }
    else
    { Write-Output $false }
}

# 重置记忆显示设备组合态
function Reset-Display-Device-Persistence {
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    Invoke-RestMethod 'https://localhost:47990/api/reset-display-device-persistence' -Method 'POST' -Headers $headers
}

# 获取配置文件
function Get-Conf {
    param(
        [string]$SunshineName=$env:COMPUTERNAME, # Sunshine 主机名称
        [string]$AdapterName="", # 适配器名称，如"AMD Radeon 780M Graphics"
        [string]$OutputName="", # 输出显示器指定，如"ZakoHDR"

        <#
        最低 CPU 线程数
        提高该值会略微降低编码效率，但为了获得更多的 CPU 内核用于编码，
        通常是值得的。理想值是在您的硬件配置上以所需的串流设置进行可靠编码的最低值。
        #>
        [int]$MinThreads=2,

        <#
        FEC (前向纠错) 参数
        每个视频帧中的错误纠正数据包百分比。
        较高的值可纠正更多的网络数据包丢失，但代价是增加带宽使用量。
        #>
        [int]$FECPercentage=20,

        <#
        串流时显示器组合状态设定
        no_operation - 无操作
        ensure_active - 自动激活指定显示器
        ensure_primary - 自动激活指定显示器并设置为主显示器
        ensure_only_display - 禁用其他显示器，只启用指定显示器
        #>
        [string]$DisplayDevicePrep="ensure_active",

        <#
        HEVC 支持
        0 - Sunshine 将根据编码器能力通告对 HEVC 的支持（推荐）
        1 - Sunshine 将不会通告对 HEVC 的支持
        2 - Sunshine 将通告 HEVC Main 配置支持
        3 - Sunshine 将通告 HEVC Main 和 Main10 (HDR) 配置支持
        #>
        [int]$HEVCMode=0
    )

    $Conf = @"
hevc_mode = $HEVCMode
notify_pre_releases = enabled
display_device_prep = $DisplayDevicePrep
fec_percentage = $FECPercentage
upnp = enabled
resolutions = [
    1280x720,
    1920x1080,
    2560x1080,
    2560x1440,
    2560x1600,
    3440x1440,
    1920x1200,
    3840x2160,
    3840x1600,
    2316x1080,
    2388x1668,
    2480x1116,
    2670x1200,
    2800x1260,
    2880x1920,
    3200x1440,
    5120x2880,
    7680x4320,
    2400x1080,
    2310x1080,
    2736x1824,
    1800x1200
]
address_family = both
locale = zh
fps = [30,60,90,120]
wan_encryption_mode = 0
min_threads = $MinThreads
"@

    if ($SunshineName) {
        $Conf += "`nsunshine_name = $SunshineName"
    }
    if ($AdapterName) {
        $Conf += "`nadapter_name = $AdapterName"
    }
    if ($OutputName) {
        $Conf += "`noutput_name = $OutputName"
    }

    return $Conf
}

# 切换模式
function Switch-Mode {
    $DisplayDevicePrep = "ensure_active"
    if ($Scene -eq "Work") {
        $DisplayDevicePrep = "ensure_active"
    } elseif ($Scene -eq "Game") {
        $DisplayDevicePrep = "ensure_only_display"
    }

    $ConfigFile = "C:\Program Files\Sunshine\config\sunshine.conf"


    Write-Output @"
切换到场景：$Scene
主机名称：$HostName
适配器名称：$GPU
输出显示器：$Output
显示模式：$DisplayDevicePrep
"@

    Get-Conf `
        -SunshineName $HostName `
        -AdapterName $GPU `
        -OutputName $Output `
        -DisplayDevicePrep $DisplayDevicePrep `
        | Out-File "$ConfigFile" -Encoding utf8

    Write-Output "重启Sunshine服务"
    # 重启 Sunshine
    Restart-Service SunshineService
    Start-Sleep 5

    Write-Output "重置记忆显示设备组合态"
    # 重置记忆显示设备组合态
    Reset-Display-Device-Persistence
}

# 提权运行
if (-not(Check-IsElevated)) { 
    $ScriptPath = $MyInvocation.MyCommand.Path
    $ScriptArgsString =  ($MyInvocation.BoundParameters.Keys | ForEach-Object {
     "-{0} `"{1}`"" -f  $_ ,$MyInvocation.BoundParameters[$_]} ) -join " "
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $ScriptArgsString"
}
else {
    Switch-Mode
}