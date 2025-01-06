## Sunshine脚本

#### 切换Sunshine配置
`
.\switch_conf.ps1 -GPU {GPU名称} -Output {显示器} -Scene {Game/Work}
`

**参数说明**
| 名称 | 说明 |
| --- | --- |
| GPU | GPU名称，通过dxgi-info获取，如"AMD Radeon 780M Graphics"，对应配置的“适配器名称”选项，不填则为推荐值 |
| Output | 显示器，通过dxgi-info获取，如"ZakoHDR"，对应配置的“输出显示器指定”选项，不填则为推荐值 |
| Scene | 投影模式，覆盖DisplayDevicePrep参数<br>**Work** - 办公场景，扩展屏幕，覆盖DisplayDevicePrep参数值为ensure_active<br>**Game** - 游戏场景，仅第二屏幕，覆盖DisplayDevicePrep参数值为ensure_only_display |
| DisplayDevicePrep | 串流时显示器组合状态设定，默认为ensure_active，如果传入了Scene参数，则该参数无效<br>**no_operation** - 无操作<br>**ensure_active** - 自动激活指定显示器<br>**ensure_primary** - 自动激活指定显示器并设置为主显示器<br>**ensure_only_display** - 禁用其他显示器，只启用指定显示器
| HostName | Sunshine主机名称，默认为电脑主机名 |

#### 如何快速切换配置？
可通过将命令作为快捷方式运行

本人的笔记本电脑使用场景如下：
- 在家的时候插上外置显卡串流到平板玩游戏
  ```powershell
  # 快捷方式，{810a36bf-750d-537d-9e40-9c683583becf}为我的显卡欺骗器
  powershell.exe -NoProfile -File D:\projects\sunshine-cmds\switch_conf.ps1 -GPU "NVIDIA GeForce RTX 2060 SUPER" -Output "{810a36bf-750d-537d-9e40-9c683583becf}" -Scene "Game" -HostName "Vnimy"
  ```

- 在办公室工作时间使用平板作为扩展屏
  ```powershell
  # 快捷方式
  powershell.exe -NoProfile -File D:\projects\sunshine-cmds\switch_conf.ps1 -GPU "AMD Radeon 780M Graphics" -Output "ZakoHDR" -Scene "Work" -HostName "Vnimy"
  ```

- 中午休息用集显串流到手机玩游戏
  ```powershell
  # 快捷方式
  powershell.exe -NoProfile -File D:\projects\sunshine-cmds\switch_conf.ps1 -GPU "AMD Radeon 780M Graphics" -Output "ZakoHDR" -Scene "Game" -HostName "Vnimy"
  ```

#### 如何添加更多分辨率？
switch_conf.ps1里面Get-Conf函数的$Conf变量，将新的分辨率添加到resolutions里面
