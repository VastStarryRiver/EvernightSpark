# 构建、热更新与平台适配

## 1. 平台概览

项目支持：

- 编辑器模拟模式；
- 安卓 APP；
- 苹果 APP；
- 鸿蒙 APP。

切平台只切 `EditorUserBuildSettings.SwitchActiveBuildTarget`（`Android` / `iOS` / `OpenHarmony`）。不使用 Build Profile，也不使用 `SetActiveSubplatform`。运行时前缀、`GameAssets/DLL` 与本机 `CDN` / `Build` 子目录为 `Android` / `iOS` / `OpenHarmony`。编辑器 `BuildTarget.iOS.ToString()` 为 `iOS`，与 HybridCLR、YooAsset 输出及本机目录同名。贴图导入平台名仍为 `iPhone`。

先切到对应 `BuildTarget`。打包菜单仅在当前端已对齐且已装模块时可点，再跑 `PreBuildValidator`，最后 `BuildPipeline.BuildPlayer`。硬拦字段：目标端 `CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony`、`CloudHelper.Secrets.GameId`、`activeBuildTarget`、目标 `IL2CPP`、安卓 `ARM64`、安卓 `forceInternetPermission`、鸿蒙 `forceOpenHarmonyInternetPermission`、`GetApplicationIdentifier` 包名非空。签名证书只警告。远程调用模式须由用户在 UOS / Func Stateless 面板自行确认。

本机是 Windows 时可打安卓 APK、导出鸿蒙工程；完整 iOS / Xcode / IPA 通常需要 Mac。未安装对应模块时该端打包菜单不可点。Google Play AAB 不设单独菜单，需要时在 Player Settings 改 `buildAppBundle` 后自行出包。

## 2. `SdkManager` 平台能力

| 能力 | Editor | 安卓 / 苹果 / 鸿蒙 |
|---|---|---|
| 平台登录 | 返回空，跳过云 | `deviceUniqueIdentifier`，空则生成并写入 PlayerPrefs |
| 本地存储 | `PlayerPrefs` | `PlayerPrefs` |
| 云读写 | 转发本地存储 | 转发 `CloudManager` 云缓存 |
| 安全区 | 按宿主 Canvas 换算 `Screen.safeArea` | 按宿主 Canvas 换算 `Screen.safeArea` |
| 平台键 | `editor` | `android` / `ios` / `ohos` |
| DLL / 本机 CDN 前缀 | `Editor` | `Android` / `iOS` / `OpenHarmony` |
| CDN 根地址 | 空 | `CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony` |
| YooAsset | `EditorSimulateMode` | `HostPlayMode` |

业务代码用 `SdkManager.Instance.GetPlatformId()`，不要散落平台宏。

## 3. YooAsset HostPlayMode

真机必须同时提供：

- `BuildinFileSystemParameters`，并设置 `DISABLE_CATALOG_FILE=true`（工程无 `StreamingAssets/yoo`，默认读 catalog 会初始化失败）；
- `CacheFileSystemParameters`，远程根为 `{GetCDNPath()}/yoo`。

首发全远程，真机必须有网。不内置首包。编辑器仍走 `EditorSimulateMode`，不走云。

三端 Bundle 与 AOT 纹理格式不同，禁止互拷。3D Prefab / FBX 依赖也按端重打。

## 4. CDN 根地址配置

运行时 CDN 根地址由 `SdkManager.Instance.GetCDNPath()` 按端返回 `CDNPathAndroid` / `CDNPathiOS` / `CDNPathOpenHarmony`（`Assets/Scripts/Invariable/Utils/InvariableConst.cs`）。编辑器返回空。YooAsset 远程根为 `{GetCDNPath()}/yoo`。

三端常量各填该端完整 URL。留空时编辑器模拟可跑，真机 HostPlayMode 远程根无效，资源下载失败。打包前按目标硬拦对应常量。

本地暂存：`CDN/{Android|iOS|OpenHarmony}/yoo`。菜单 `VastStarryRiver/打包/复制bundle到CDN目录` 按当前 `activeBuildTarget` 复制。玩家程序在安装包内，热更只上传该端 `{GetCDNPath()}/yoo` Bundle，不上传 wasm / `unityweb.bin`。

## 5. Excel 配置导出

菜单：

```text
VastStarryRiver/Config/导出Excel配置
VastStarryRiver/Config/校验配置数据
```

纯数值改动：导表 → 构建 AssetBundle → 复制 bundle。表结构变更才需要重导 HybridCLR DLL。

## 6. HybridCLR DLL 构建

菜单：

```text
VastStarryRiver/DLL/导出所有DLL
VastStarryRiver/DLL/复制热更新DLL
VastStarryRiver/DLL/复制元数据DLL
```

必须先切到该端 `BuildTarget` 再导出。`HybridCLRData/` 由「导出所有DLL」重建，不要手建。产物写入：

```text
Assets/GameAssets/DLL/{Android|iOS|OpenHarmony}/
```

Collector DLL 组地址规则为 `AddressByFolderAndFileName`，运行时地址为 `{平台}_{文件名}`，例如 `Android_HotUpdate.dll`。`YooAssetManager` 用 `SdkManager.Instance.GetDllPlatform()` 拼前缀，闲置释放白名单同步该前缀。

AOT 清单单一事实源：`InvariableConst.AotDllNames`。团结 iOS 导出工程名为 `Tuanjie-iPhone`。UOS PostProcess 读取 `Unity-iPhone.xcodeproj`。本工程 `IosXcodeProjShim` 在 PostProcess 87 / 89 对齐两份 `project.pbxproj`。Windows 上可导出该端 HybridCLR DLL，完整 IPA 通常需要 Mac。

## 7. YooAsset 构建

菜单：`VastStarryRiver/构建AssetBundle`。

参数（本机 EditorPrefs，不进 git）：LZ4、无 Bundle 加密、`BuildinFileCopyOption.None`。新机器打开工程后核一次。

贴图：`VastStarryRiver/资源处理/设置图片和图集` 为 UI 图写入 Default 压缩与 Android / iPhone / OpenHarmony ASTC，并关闭 mipmap。该菜单不得扫 `GameAssets/Models`。3D 贴图在整理该模型文件夹时写入导入设置，不整扫 `GameAssets/Models`。

每端纹理格式进包，必须在目标平台重打 Bundle。

## 8. 复制资源到 CDN

菜单：`VastStarryRiver/打包/复制bundle到CDN目录`。

目标：`CDN/{Android|iOS|OpenHarmony}/yoo`。`ConfigUtils.GetAppPlatformFolder` 对旧名 `iPhone` 返回 `iOS`，其余原样。只复制当前端最新 YooAsset 输出，不复用其他端产物。

## 9. 安卓构建

菜单：`VastStarryRiver/打包/打包安卓`。

输出：`Build/Android/{productName}.apk`。本轮打 APK（侧载/国内渠道）。需要 AAB 时在编辑器改 `buildAppBundle` 后自行出包。

打包菜单仅在当前 `BuildTarget` 已是 `Android` 且已装模块时可点，先切平台再点。安卓须 IL2CPP、含 ARM64、强制网络权限、包名非空。keystore 本机填写，未配置只警告。

Gradle 插件与依赖经 `Assets/Plugins/Android/settingsTemplate.gradle` 解析：`pluginManagement` 与 `dependencyResolutionManagement` 均先走阿里云 `google` / `central` / `gradle-plugin` / `public`，再回落到 `gradlePluginPortal()` / `google()` / `mavenCentral()`。`ProjectSettings` 中 `useCustomGradleSettingsTemplate` 须为开启，否则编辑器忽略该文件。UOS Launcher 注入的 `Android_CN_OAID` 坐标由 `AndroidGradleLocalMaven` 在导出工程写入 `localMaven`（源在 `Assets/Editor/MyTools/CustomBuild/CustomAndroidBuild/AndroidLocalMaven`），避免打包时访问 `jitpack.io`。

## 10. 苹果构建

菜单：`VastStarryRiver/打包/打包苹果`。

输出：`Build/iOS`（Xcode 工程）。打包菜单仅在当前 `BuildTarget` 已是 `iOS` 且已装模块时可点，先切平台再点。未装 iOS 模块时该菜单不可点。切到 `BuildTarget.iOS` 后仍可在本机导出该端 HybridCLR DLL 与 YooAsset Bundle。完整 IPA 通常需要 Mac。Team / 描述文件本机填写，未配置只警告。不经 Android Gradle，不读 `settingsTemplate.gradle`。

## 11. 鸿蒙构建

菜单：`VastStarryRiver/打包/打包鸿蒙`。

输出：`Build/OpenHarmony` 导出工程，再走 DevEco 安装。打包菜单仅在当前 `BuildTarget` 已是 `OpenHarmony` 且已装模块时可点，先切平台再点。须 IL2CPP、强制网络权限、包名非空。证书与 Profile 本机填写，未配置只警告。团结 External Tools 需本机已配 OpenHarmony SDK / Node / JDK。不经 Android Gradle，不读 `settingsTemplate.gradle`。

## 12. 推荐的完整构建顺序

每端完整顺序（不能串台）：

1. 切到该端 `BuildTarget`
2. 若改过 Excel：`VastStarryRiver/Config/导出Excel配置`
3. `VastStarryRiver/DLL/导出所有DLL`
4. `VastStarryRiver/DLL/复制热更新DLL`
5. `VastStarryRiver/DLL/复制元数据DLL`
6. `VastStarryRiver/构建AssetBundle`
7. `VastStarryRiver/打包/复制bundle到CDN目录`
8. 打包安卓 / 苹果 / 鸿蒙

### 12.1 首发基础包

按上面 8 步走完该端，再上传该端 `{GetCDNPath()}/yoo`，用安装包安装。确认目标端 CDN 常量为完整 URL，云函数已上传且为远程调用，`ResetDayRank` 定时触发器已配置。

### 12.2 仅业务代码热更

共享段：导表（如有）→ 导出/复制 DLL → 构建 AssetBundle → 复制 bundle。不跑平台打包菜单。

### 12.3 仅资源热更

纯数值：导表 → 构建 AssetBundle → 复制 bundle。普通资源：共享段 5 步后复制 bundle。

## 13. 什么不能只靠热更新发布

以下修改通常需要重新发布安装包：

- `Invariable` / `CloudService` / 首包 `Resources/LocalAssets` / `Start.scene`；
- HybridCLR / YooAsset / PlayerSettings / 包名 / 权限；
- 引擎版本；
- 云函数签名变化（还须重新上传云函数并切远程调用）。

仅改 `HotUpdate`、`Excel/`、`GameAssets` 动态资源时可纯热更。

## 14. 平台功能验证矩阵

| 场景 | Editor | 安卓 | 苹果 | 鸿蒙 |
|---|---|---|---|---|
| 进游戏（无云） | 必测 | — | — | — |
| Linear 下 MainPanel 明暗 | 必测 | — | — | — |
| URP 下 UI 相机与 TMP 不粉 | 必测 | — | — | — |
| 设备访客登录 | — | 必测 | 必测 | 必测 |
| 云存档读写 | — | 必测 | 必测 | 必测 |
| CDN 热更 | — | 必测 | 必测 | 必测 |
| 世界榜/日榜 | — | 三端同一榜 | 三端同一榜 | 三端同一榜 |
| 断网启动 | — | 必测失败提示 | 必测失败提示 | 必测失败提示 |

苹果卸装重装或卸光同开发者 App 后 IDFV 可能变化，访客账号可能换号。

## 15. 构建产物与源码的对应关系

```text
DllTool
  -> GameAssets/DLL/{Android|iOS|OpenHarmony}/*.dll.bin
  -> 地址 {平台}_HotUpdate.dll / {平台}_{AotDll}.dll

AssetBundleTool
  -> Bundles/{BuildTarget}/MyPackage/{version}/
  -> CDN/{Android|iOS|OpenHarmony}/yoo

BuildPlayer
  -> Build/Android/*.apk
  -> Build/iOS/（Xcode）
  -> Build/OpenHarmony/（DevEco）
```
