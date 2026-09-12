# 新项目准备文档

---

## 1. 首次打开与环境恢复

1. 用与源工程**相同版本**的团结引擎打开新工程目录。源工程版本见 `ProjectSettings/ProjectVersion.txt`（`2022.3.62t11` / Tuanjie `1.9.3`）。版本不一致可能导致 HybridCLR、UOS 包行为差异。
2. 首次打开会重建 `Library/`，耗时较长，等待完成。
3. Package Manager 会按 `Packages/manifest.json` 拉取依赖（含 UOS CDN / CloudSave / Func Stateless / Launcher、YooAsset、HybridCLR、NuGetForUnity 等）。若有 git 包拉取失败，检查网络与凭据后重试。
4. 使用 NuGetForUnity 还原 `Newtonsoft.Json`（与云函数、云存档 JSON 序列化相关）。
5. 打开 Console，确认**无编译错误**后再进入后续步骤。若出现 `UOSSettings` 相关加载异常，先完成第 5 章「UOS Launcher 重新 Link」，或按编辑器提示使用 `UOS/Launcher/Fix settings by reimport` / `UOS/Launcher/Fix settings by delete`。
6. HybridCLR 包为 `com.code-philosophy.hybridclr#v8.14.1`。换引擎大版本后打开 `HybridCLR/Installer` 重新安装，再执行 `HybridCLR/Generate/All`。安卓导出 HybridCLR DLL 或打安卓包时，`Packages/manifest.json` 须保留 `com.unity.modules.androidjni`（UOS Launcher 真机 Android 包装依赖 `AndroidJavaProxy` / `AndroidJavaObject`）。
7. 团结 External Tools 核对本机 OpenHarmony SDK / Node / JDK（打鸿蒙包需要）。不在工程里写本机路径。

### 1.1 场景 GI 烘焙

日夜 `LightingData.asset` 需自行生成。第 1 章编译通过后、第 8 章构建之前，日、夜各烤一遍。Auto Generate 保持关闭。

1. 打开 `Assets/GameAssets/Scenes/CandyFantasyWorld/CandyScene_day.unity`（场景在 `GameAssets/Scenes/`，不是 `Models/.../Scenes/`）。
2. `Window` → `Rendering` → `Lighting`。
3. Lighting Settings Asset 为 `CandyScene_daySettings`。若空，拖入 `Assets/GameAssets/Models/CandyFantasyWorld/Scenes/CandyScene_daySettings.lighting`。
4. 点 **Generate Lighting**，等到 Progress 窗口无烘焙任务。
5. 保存场景。引擎在 `Assets/GameAssets/Models/CandyFantasyWorld/Scenes/CandyScene_day/` 写出 `LightingData.asset` 与 `.meta`。
6. 对 `Assets/GameAssets/Scenes/CandyFantasyWorld/CandyScene_night.unity` 重复第 1–5 步，Settings 用 `CandyScene_nightSettings`，产物在 `.../CandyScene_night/`。

不要手写 `.meta`。Lighting 窗口的 Lighting Data Asset 不是 Missing，视口间接光恢复，即生成完成。

---

## 2. 版本控制初始化

工程已有 `.gitignore`。以下文件/目录被忽略，**不会进入 git**，但对运行与打包必需，须另行备份或私密存储：

| 路径 | 用途 |
|---|---|
| `Assets/Resources/UOSSettings.asset`（及 `.meta`） | UOS AppID / AppSecret / AppServiceSecret（加密） |
| `Assets/UOSLauncherEncrypt/` | UOSSettings 加密密钥 |
| `Assets/Editor/UnityOnlineServicesData/` | UOS 编辑器数据（含 CDN 设置） |
| `Assets/Editor/UOSEnvironments.asset`（及 `.meta`） | UOS 环境配置 |

---

## 3. UOS 后台

### 3.1 创建 App 并开通服务

1. 创建新 UOS App，名称建议与 `{新游戏显示名}` 一致。
2. 为该 App 开通以下服务：
   - CDN
   - 云存档（Cloud Save）
   - 云函数（Func Stateless）

### 3.2 CDN Bucket

1. 新建 Bucket。
2. 创建 Badge（建议沿用 `latest`，可改为 `{badge}`）。
3. 复制 client_api 根地址，格式：

```text
https://a.unity.cn/client_api/v1/buckets/{bucketUuid}/release_by_badge/{badge}/content
```

将该地址按端分别记为 `{新CDN根地址安卓}` / `{新CDN根地址苹果}` / `{新CDN根地址鸿蒙}`，写入 `InvariableConst.CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony`（各为完整 URL）。运行时远程根为 `{GetCDNPath()}/yoo`。

### 3.3 记录三密钥

在 App 设置页记录（仅私密保存）：

| 占位符 | 说明 |
|---|---|
| `{UOS_AppID}` | App ID |
| `{UOS_AppSecret}` | App Secret |
| `{UOS_AppServiceSecret}` | App Service Secret |

云函数服务端会通过环境变量 `UOS_APP_ID` / `UOS_APP_SERVICE_SECRET` 使用服务密钥，无需写进客户端业务代码。

---

## 4. 商店包名、签名与网络

### 4.1 包名与方向

三端写入同一包名 `{包名}`（源工程默认 `com.VastStarryRiver.EvernightSpark`）：

- Player Settings `applicationIdentifier`：Android / iPhone / OpenHarmony
- 竖屏：`defaultScreenOrientation` 为 Portrait，关闭左右横屏自动转（与 1080×1920 Canvas 一致）

图标槽位为空，商店上架前必填，本轮不造图。

### 4.2 网络与 UOS 域名

安卓、鸿蒙强制网络权限。真机需放行下列 UOS 域名（系统网络策略 / 企业代理白名单按端配置）：

```text
https://a.unity.cn
https://a.unity3dcloud.cn
https://a2.unity3dcloud.cn
https://a3.unity3dcloud.cn
https://metrics2.unity.cn
https://p.unity.cn
https://save.unity.cn
https://stateless.unity.cn
https://uos-save-bluecloud-1301389817.cos.ap-shanghai.myqcloud.com
```

以上域名以 UOS 官方文档/控制台提示为准。若后续接入其他 UOS 服务，再按 UOS 官方文档补充。

### 4.3 签名与证书

本机填写，工程不代填：

- 安卓 keystore
- 苹果 Team / 描述文件
- 鸿蒙证书 / Profile

未配置时打包菜单只警告，不硬拦。

### 4.4 安卓 Gradle 仓库

`Assets/Plugins/Android/settingsTemplate.gradle` 随工程走：Gradle 插件与依赖先解析阿里云 `google` / `central` / `gradle-plugin` / `public`，再回落官方源。`ProjectSettings` 中 `useCustomGradleSettingsTemplate` 须为开启。UOS Launcher 注入的 `Android_CN_OAID` 走工程内 `Assets/Editor/MyTools/CustomBuild/CustomAndroidBuild/AndroidLocalMaven`，由 `AndroidGradleLocalMaven` 写入导出工程的 `localMaven`。新工程沿用这些文件即可，不必再配本机 `~/.gradle/init.gradle`。苹果与鸿蒙打包不读此模板。

---

## 5. 工程内配置修改清单

按下列顺序修改。改完后等待脚本编译成功。

### 5.1 选定游戏标识

| 占位符 | 要求 |
|---|---|
| `{新GameId}` | 每个游戏唯一的英文字符串（建议与项目/产品英文名一致）。将用于云存档 namespace：`kv_{新GameId}_player` / `kv_{新GameId}_rank` |

**三处必须相同：**

1. `CloudHelper.Secrets.GameId`
2. `CloudManager.CloudSaveGameId`
3. 由此派生的 namespace `kv_{新GameId}_player` 与 `kv_{新GameId}_rank`

### 5.2 UOS Launcher 重新绑定

1. 菜单：`UOS/Open Launcher`
2. 使用 `{UOS_AppID}` / `{UOS_AppSecret}` / `{UOS_AppServiceSecret}` 重新 Link 新 App
3. 结果写入 `Assets/Resources/UOSSettings.asset`（加密字段）
4. **禁止**手改 `UOSSettings.asset` 中的 `encrypted*` 字段；`Assets/UOSLauncherEncrypt/` 已随工程复制，一般无需改动

### 5.3 CDN 根地址

文件：`Assets/Scripts/Invariable/Utils/InvariableConst.cs`（`#region 游戏资源`）

写入完整 URL：

```csharp
public const string CDNPathAndroid = "{新CDN根地址安卓}";
public const string CDNPathiOS = "{新CDN根地址苹果}";
public const string CDNPathOpenHarmony = "{新CDN根地址鸿蒙}";
```

运行时 YooAsset 远程根为 `SdkManager.Instance.GetCDNPath() + "/yoo"`。编辑器 `GetCDNPath()` 返回空。留空后果与发布边界见 HotUpdateBuildAdapt §4。

### 5.4 DLL/配置加密密钥

文件：`Assets/Scripts/Invariable/Utils/InvariableConst.cs`（`#region 游戏资源`）

`ConfigUtils` 用这两项做 AES 加解密（`DllTool` 复制 `.dll.bin` 与运行时 `ReadSafeFile` 共用）：

```csharp
public const string EncryptKey = "{新EncryptKey}";
public const string EncryptIv = "{新EncryptIv}";
```

要求（按 UTF-8 字节计）：

- `EncryptKey`：16 / 24 / 32 字节
- `EncryptIv`：16 字节

留空时 `Encoding.UTF8.GetBytes("")` 得到 0 长度密钥，AES 直接抛异常，**DLL 加密复制与真机 DLL 解密都会失败**。

> `Invariable` 不可热更，以上改动只能随**基础包**生效。改密钥后必须重跑 DLL 导出/复制再打基础包。

### 5.5 云函数 Secrets 与云存档 GameId

**文件 A：** `Assets/Scripts/CloudService/CloudHelper.cs`

将 `Secrets` 改为：

```csharp
private static readonly GameSecrets Secrets = new GameSecrets
{
    GameId = "{新GameId}"
};
```

**文件 B：** `Assets/Scripts/Invariable/Manager/CloudManager.cs`

```csharp
private const string CloudSaveGameId = "{新GameId}"; // 必须与 CloudHelper.Secrets.GameId 一致
```

`CloudSaveNamespace` 会自动变为 `kv_{新GameId}_player`，排行榜快照为 `kv_{新GameId}_rank`，无需单独改字符串字面量。

后台显示名（仅展示，不参与定位）：

| 存档 | 显示名 |
|---|---|
| 玩家存档 | 安卓玩家数据 / 苹果玩家数据 / 鸿蒙玩家数据 |
| 排行榜快照 | 世界排行榜 / 每日排行榜 |

玩家资料字段统一为 `UserId` / `NickName` / `AvatarUrl`：玩家数据云存档直接写在 JSON 内容里；排行榜条目写在顶层，与 `UserId`、`Data` 并列（`Data` 只保留排行分数等业务数据）。世界榜快照 `userId` 为 `rank_world`，日榜为 `rank_day`。设备访客标识可被伪造，卸装或苹果 IDFV 变化可能换号。

> `CloudService` 程序集**不可热更**，以上改动只能随**基础包**生效。

### 5.6 产品名称

在 Player Settings 或 `ProjectSettings/ProjectSettings.asset` 中：

- `productName` → `{新游戏显示名}`
- `companyName` 按需保留或改为 `{公司名}`
- `applicationIdentifier` 三端 → `{包名}`

### 5.7 切平台（无 Build Profile）

安卓 / 苹果 / 鸿蒙不建 Build Profile。打包前用 `EditorUserBuildSettings.SwitchActiveBuildTarget` 切到 `Android` / `iOS` / `OpenHarmony`。运行时与本机 CDN/DLL/Build 目录为 `Android` / `iOS` / `OpenHarmony`；编辑器 `BuildTarget.iOS.ToString()` 为 `iOS`，与 HybridCLR / YooAsset 输出同名。不要只改宏文本。

### 5.8 编辑器 CDN 上传目标

打开 UOS CDN 相关面板（`UOS/CDN/Manager` 或工程内已有 CDN 工具），将上传目标切换为**新 App 下的新 Bucket**，再执行后续「复制到 CDN / 上传」步骤，避免把资源传到其他游戏 Bucket。

### 5.9 明确无需改动的项

- 运行时 DLL 前缀由 `SdkManager.Instance.GetDllPlatform()` 提供（`Android` / `iOS` / `OpenHarmony`），**不是**产品名 / GameId。编辑器 `BuildTarget.iOS.ToString()` 为 `iOS`，与本机 DLL/CDN 目录同名。
- YooAsset Package 名默认 `MyPackage`，可沿用，除非团队另有规范。
- `HotUpdate.asmdef` 引用 `Invariable` 与 `CloudService`（消费 Model DTO），统一写名称，**勿删**。项目内程序集之间用名称引用，第三方包用 GUID。

---

## 6. 游戏内容替换

按新游戏需求替换内容；与配置相关的步骤建议紧接在第 5 章之后完成。

### 6.1 Excel 配置表

1. 替换或新增 `Excel/` 下表格（.xlsx/.xls）
2. 菜单：`VastStarryRiver/Config/导出Excel配置`
3. 可选：`VastStarryRiver/Config/校验配置数据`
4. 等待生成代码编译成功（`Assets/Scripts/HotUpdate/Config/Generated/`、`Assets/GameAssets/Config/*.bytes`）

说明：

- 纯数值改动：导表后构建 AssetBundle 即可热更
- 表结构变更：导表并编译成功后，走完整 HybridCLR + YooAsset 流水线

### 6.2 动态资源

- 替换 `Assets/GameAssets` 下预制体、图集、音频等
- 需要合并多图为 Multiple Sprite PNG 时使用工程内 AtlasBuilder（`Assets/Editor/MyTools/AtlasBuilder/`，ContextMenu `BuildAtlas`；输出在 Editor 目录，与 YooAsset 收集的 `GameAssets/Atlas` UI 图集无关）
- 新增音频、图片或图集资源后，执行 `VastStarryRiver/资源处理` 对应菜单批量设置导入参数
- TMP 表情由 `Assets/ToolPackage/TextMesh Pro/Resources/Sprite Assets/emoji.asset` 提供（TMP Settings 默认表情图集），与 AtlasBuilder 无关

### 6.3 首包资源与启动内容

以下改动通常需要重新打**基础包**：

| 路径 | 说明 |
|---|---|
| `Assets/Resources/LocalAssets/Png/loading.png` | 加载图 |
| `Assets/Resources/LocalAssets/Png/age8+.png` | 适龄提示图 |
| `Assets/Resources/LocalAssets/HotUpdatePanel.prefab` | 热更/加载界面 |
| `Assets/Scenes/Start.scene` | 启动场景（按需） |
| 游戏内 UI 标题、产品名文案 | HotUpdate UI Prefab / 配置文本 |

---

## 7. 云函数部署

前置：第 5.5 节 Secrets 与 GameId 已填正确，且工程已编译通过。

1. 菜单：`UOS/Func Stateless/Open Panel`
2. 上传 `CloudHelper` 所在云函数工程（`Assets/Scripts/CloudService/`）
3. **切换为远程调用模式**
4. UOS 控制台给 `ResetDayRank` 配置定时触发器 cron `0 5 * * *`（需正式用户；控制台 cron 时区为 UTC+8（北京时间），每天凌晨 5 点触发）
5. 打包 APP 前确认处于远程模式；**禁止**以本地调用模式出正式包

提醒：

- 远程模式下客户端只保留带 `[CloudFunc]` 的方法；密钥仅在服务端执行
- 打包前置校验只在本地源码仍含 `Secrets` 赋值时扫字段；远程桩会剥掉密钥，不把缺失赋值当成未填。上传前须在本地模式确认已填齐
- 每次改 `CloudService` / 云函数体后：重新上传 → 确认远程模式 → 再出基础包

---

## 8. 首发构建流水线

新游戏首次或完整基础包发布的步骤顺序与 [HotUpdateBuildAdapt.md](./HotUpdateBuildAdapt.md) §12.1 一致，按该节执行。首发额外确认：

- `CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony` 已是各端完整 URL
- 云函数已上传且为远程调用模式，`ResetDayRank` 定时触发器已配置（第 7 章）
- UOS CDN 上传目标为各端 Bucket，Badge 与 `{新CDN根地址安卓}` / `{新CDN根地址苹果}` / `{新CDN根地址鸿蒙}` 一致
- 用对应端安装包安装，清缓存与保留缓存各测一轮

后续仅业务代码热更 / 仅资源热更，见 HotUpdateBuildAdapt §12.2 / §12.3。不能只靠热更、必须重发基础包的范围见 HotUpdateBuildAdapt §13。

---

## 9. 验证清单

### 9.1 编辑器侧（准备阶段自检）

- [ ] `CloudHelper.Secrets.GameId` 与 `CloudManager.CloudSaveGameId` 均为 `{新GameId}`
- [ ] 工程内无其他游戏 CDN bucket UUID、无其他 GameId 残留（搜索残留值）
- [ ] `CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony` 指向各端完整 URL（不可留空）
- [ ] `InvariableConst.EncryptKey` / `EncryptIv` 已填合法长度（key 16/24/32 字节、iv 16 字节）
- [ ] UOS Launcher 显示已绑定新 App
- [ ] Func Stateless 面板：云函数已上传且为远程模式
- [ ] UOS 控制台已给 `ResetDayRank` 配置日榜定时触发器 cron `0 5 * * *`（需正式用户，cron 时区 UTC+8）
- [ ] 三端包名为 `{包名}`，安卓含 ARM64，安卓/鸿蒙已开网络权限
- [ ] `useCustomGradleSettingsTemplate` 已开启，且存在 `Assets/Plugins/Android/settingsTemplate.gradle`
- [ ] Console 无编译错误
- [ ] 日夜场景 Lighting 窗口的 Lighting Data Asset 均不是 Missing（第 1.1 节）

### 9.2 真机 / 平台侧（三端均测）

| 场景 | 安卓 | 苹果 | 鸿蒙 |
|---|:---:|:---:|:---:|
| 首次无缓存启动 | 必测 | 必测 | 必测 |
| 有缓存启动 | 必测 | 必测 | 必测 |
| 设备访客登录 → 云函数换取云存档令牌 | 必测 | 必测 | 必测 |
| 云存档读写（`kv_{新GameId}_player`） | 必测 | 必测 | 必测 |
| 世界榜/日榜上报/拉取（三端同一 `kv_{新GameId}_rank`） | 必测 | 必测 | 必测 |
| CDN 热更资源下载（`{GetCDNPath()}/yoo`） | 必测 | 必测 | 必测 |
| DLL 加载与主界面 | 必测 | 必测 | 必测 |
| 本地存档 | 必测 | 必测 | 必测 |
| CDN 异常 / 断网提示 | 必测 | 必测 | 必测 |

完整矩阵另见 HotUpdateBuildAdapt §14。

---

## 附录 A：占位符汇总

| 占位符 | 获取来源 |
|---|---|
| `{新GameId}` | 团队自定，唯一英文标识 |
| `{新EncryptKey}` / `{新EncryptIv}` | 团队自定 AES 密钥（key 16/24/32 字节、iv 16 字节，按 UTF-8 计） |
| `{新游戏显示名}` | 产品命名 |
| `{公司名}` | 可选 |
| `{UOS_AppID}` / `{UOS_AppSecret}` / `{UOS_AppServiceSecret}` | UOS 控制台新 App 设置 |
| `{bucketUuid}` / `{badge}` / `{新CDN根地址安卓}` / `{新CDN根地址苹果}` / `{新CDN根地址鸿蒙}` | UOS CDN Bucket，三端各一份根地址 |
| `{包名}` | 商店应用标识，三端同一值 |
| `{新工程根}` | 复制后的本地路径 |

## 附录 B：关键菜单速查

打包安卓/苹果/鸿蒙菜单会先跑前置校验。远程调用模式须由用户在 UOS / Func Stateless 面板自行确认，工程内无法验证。

### Config

- `VastStarryRiver/Config/导出Excel配置`（产物：`GameAssets/Config/*.bytes` + `HotUpdate/Config/Generated/Config_*.cs` + `ConfigManager.Preload.cs`）
- `VastStarryRiver/Config/校验配置数据`（Excel 与 bytes 全量比对）

### DLL

- `VastStarryRiver/DLL/导出所有DLL`
- `VastStarryRiver/DLL/复制热更新DLL`
- `VastStarryRiver/DLL/复制元数据DLL`

### 资源处理

- `VastStarryRiver/资源处理/设置音频资源`（按 `Audios/Bgm` 与 `Audios/Sfx` 分别设置 CompressedInMemory / DecompressOnLoad，Sfx 强制 Force To Mono，Bgm 不改）
- `VastStarryRiver/资源处理/设置图片和图集`（Atlas 图集压缩/关可读；Atlas 源图与 Png 散图统一最佳模式：强制 Sprite、关可读、关 mipmap、压缩；三端 ASTC；不扫 `GameAssets/Models`）

### 构建

- `VastStarryRiver/构建AssetBundle`

### 打包

- `VastStarryRiver/打包/复制bundle到CDN目录`
- `VastStarryRiver/打包/打包安卓`（当前已是 `Android` 且已装模块时可点）
- `VastStarryRiver/打包/打包苹果`（当前已是 `iOS` 且已装模块时可点）
- `VastStarryRiver/打包/打包鸿蒙`（当前已是 `OpenHarmony` 且已装模块时可点）

### UOS

- `UOS/Func Stateless/Open Panel`（上传云函数；发布前需切远程调用，见 NewProjectSetup §7）
- `UOS/Open Launcher`（关联 UOS App / 凭证）
- `UOS/CDN/Manager`（切换 CDN 上传目标 Bucket）

切平台见 HotUpdateBuildAdapt §1（只切 `BuildTarget`），不要只改宏文本。

## 附录 C：准备进度勾选（可选）

- [ ] 1. 首次打开与环境恢复（含日夜场景 Generate Lighting）
- [ ] 2. 版本控制初始化与忽略文件备份策略
- [ ] 3. UOS 新 App / 三服务 / Bucket / 三密钥
- [ ] 4. 包名、签名、网络权限与 UOS 域名放行
- [ ] 5. 工程内配置（UOS Link、CDNPathAndroid/CDNPathiOS/CDNPathOpenHarmony、EncryptKey/EncryptIv、GameId、Secrets、productName、包名、CDN 目标）
- [ ] 6. 游戏内容替换与导表
- [ ] 7. 云函数上传并远程模式，ResetDayRank 定时触发器已配置
- [ ] 8. 首发构建流水线跑通
- [ ] 9. 三端验证清单通过
