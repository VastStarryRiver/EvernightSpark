using Invariable;
using System.IO;
using System.Linq;
using UnityEditor;



namespace MyTools
{
    public class CustomBuildScript
    {
        /// <summary>
        /// 打包安卓 APK
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包安卓", false, 30)]
        public static void PackageProject_Android()
        {
            PackageProject(PreBuildValidator.AppPackTarget.Android);
        }

        /// <summary>
        /// 当前已是安卓且已装模块时菜单可点
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包安卓", true, 30)]
        public static bool PackageProject_Android_Enable()
        {
            return CanPack(PreBuildValidator.AppPackTarget.Android);
        }

        /// <summary>
        /// 打包苹果 Xcode 工程
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包苹果", false, 31)]
        public static void PackageProject_iOS()
        {
            PackageProject(PreBuildValidator.AppPackTarget.iOS);
        }

        /// <summary>
        /// 当前已是苹果且已装模块时菜单可点
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包苹果", true, 31)]
        public static bool PackageProject_iOS_Enable()
        {
            return CanPack(PreBuildValidator.AppPackTarget.iOS);
        }

        /// <summary>
        /// 打包鸿蒙 DevEco 工程
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包鸿蒙", false, 32)]
        public static void PackageProject_OpenHarmony()
        {
            PackageProject(PreBuildValidator.AppPackTarget.OpenHarmony);
        }

        /// <summary>
        /// 当前已是鸿蒙且已装模块时菜单可点
        /// </summary>
        [MenuItem("VastStarryRiver/打包/打包鸿蒙", true, 32)]
        public static bool PackageProject_OpenHarmony_Enable()
        {
            return CanPack(PreBuildValidator.AppPackTarget.OpenHarmony);
        }

        /// <summary>
        /// 复制最新 bundle 到当前 BuildTarget 的 CDN 目录
        /// </summary>
        [MenuItem("VastStarryRiver/打包/复制bundle到CDN目录", false, 33)]
        public static void MoveBundleFileToCDN()
        {
            string platform = ConfigUtils.GetAppPlatformFolder(EditorUserBuildSettings.activeBuildTarget.ToString());
            string targetDir = $"{ConfigUtils.CdnPath}/{platform}/yoo";

            if (Directory.Exists(targetDir))
            {
                Directory.Delete(targetDir, true);
            }

            ConfigUtils.InitDirectory(targetDir);

            string sourceDir = AssetBundleTool.GetOutPath();

            if (!Directory.Exists(sourceDir))
            {
                GameLog.Error($"找不到 YooAsset 输出目录: {sourceDir}");

                return;
            }

            DirectoryInfo directoryInfo = new DirectoryInfo(sourceDir);
            FileInfo[] fileInfos = directoryInfo.GetFiles();

            foreach (FileInfo item in fileInfos)
            {
                string sourceFilePath = item.FullName.Replace("\\", "/");
                string targetFilePath = $"{targetDir}/{Path.GetFileName(sourceFilePath)}";
                File.Copy(sourceFilePath, targetFilePath);
            }

            GameLog.Info($"已复制 bundle 到 {targetDir}");
        }



        /// <summary>
        /// 在当前 BuildTarget 已对齐时执行 BuildPlayer
        /// </summary>
        private static void PackageProject(PreBuildValidator.AppPackTarget target)
        {
            BuildTarget buildTarget = PreBuildValidator.GetBuildTarget(target);
            BuildTargetGroup buildTargetGroup = PreBuildValidator.GetBuildTargetGroup(target);

            if (!BuildPipeline.IsBuildTargetSupported(buildTargetGroup, buildTarget))
            {
                GameLog.Error($"当前编辑器未安装 {buildTarget} 模块，无法出包");

                return;
            }

            if (EditorUserBuildSettings.activeBuildTarget != buildTarget)
            {
                GameLog.Error($"当前 BuildTarget 为 {EditorUserBuildSettings.activeBuildTarget}，与 {buildTarget} 不一致，先切平台再打包");

                return;
            }

            if (!PreBuildValidator.ConfirmReadyToPack(target))
            {
                return;
            }

            string folderName = ConfigUtils.GetAppPlatformFolder(buildTarget.ToString());
            string outputRoot = $"{ConfigUtils.AppBuildPath}/{folderName}";

            if (Directory.Exists(outputRoot))
            {
                Directory.Delete(outputRoot, true);
            }

            ConfigUtils.InitDirectory(outputRoot);

            if (buildTarget == BuildTarget.Android)
            {
                EditorUserBuildSettings.buildAppBundle = false;
            }

            string locationPathName = buildTarget == BuildTarget.Android
                ? $"{outputRoot}/{PlayerSettings.productName}.apk"
                : outputRoot;

            string[] scenes = EditorBuildSettings.scenes
                .Where(scene => scene.enabled)
                .Select(scene => scene.path)
                .ToArray();

            if (scenes.Length == 0)
            {
                GameLog.Error("没有已启用的打包场景");

                return;
            }

            BuildPlayerOptions options = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = locationPathName,
                target = buildTarget,
                targetGroup = buildTargetGroup,
                options = BuildOptions.None
            };

            UnityEditor.Build.Reporting.BuildReport report = BuildPipeline.BuildPlayer(options);

            if (report.summary.result == UnityEditor.Build.Reporting.BuildResult.Succeeded)
            {
                GameLog.Info($"{folderName} 构建完成: {locationPathName}");
            }
            else
            {
                GameLog.Error($"{folderName} 构建失败: {report.summary.result}");
            }
        }

        /// <summary>
        /// 当前 BuildTarget 已是该端且编辑器已装该端模块
        /// </summary>
        private static bool CanPack(PreBuildValidator.AppPackTarget target)
        {
            BuildTarget buildTarget = PreBuildValidator.GetBuildTarget(target);
            BuildTargetGroup buildTargetGroup = PreBuildValidator.GetBuildTargetGroup(target);

            if (!BuildPipeline.IsBuildTargetSupported(buildTargetGroup, buildTarget))
            {
                return false;
            }

            return EditorUserBuildSettings.activeBuildTarget == buildTarget;
        }
    }
}