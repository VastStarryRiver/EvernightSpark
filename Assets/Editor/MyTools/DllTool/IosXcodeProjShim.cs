using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;



namespace MyTools
{
    public class IosXcodeProjShim
    {
        private const string TuanjieXcodeDir = "Tuanjie-iPhone.xcodeproj";
        private const string UnityXcodeDir = "Unity-iPhone.xcodeproj";
        private const string PbxFileName = "project.pbxproj";



        /// <summary>
        /// 团结 iOS 工程名为 Tuanjie-iPhone，复制 pbxproj 供 UOS 读取 Unity-iPhone 路径
        /// </summary>
        [PostProcessBuild(87)]
        public static void CopyTuanjiePbxToUnityName(BuildTarget target, string targetPath)
        {
            if (target != BuildTarget.iOS)
            {
                return;
            }

            string tuanjiePbx = GetPbxPath(targetPath, TuanjieXcodeDir);
            string unityPbx = GetPbxPath(targetPath, UnityXcodeDir);

            if (!File.Exists(tuanjiePbx) || File.Exists(unityPbx))
            {
                return;
            }

            Directory.CreateDirectory(Path.Combine(targetPath, UnityXcodeDir));
            File.Copy(tuanjiePbx, unityPbx, false);
        }

        /// <summary>
        /// 将 UOS 改过的 Unity-iPhone pbxproj 写回 Tuanjie-iPhone
        /// </summary>
        [PostProcessBuild(89)]
        public static void CopyUnityPbxBackToTuanjie(BuildTarget target, string targetPath)
        {
            if (target != BuildTarget.iOS)
            {
                return;
            }

            string tuanjiePbx = GetPbxPath(targetPath, TuanjieXcodeDir);
            string unityPbx = GetPbxPath(targetPath, UnityXcodeDir);

            if (!File.Exists(tuanjiePbx) || !File.Exists(unityPbx))
            {
                return;
            }

            File.Copy(unityPbx, tuanjiePbx, true);
        }



        /// <summary>
        /// 拼接 xcodeproj 内 project.pbxproj 路径
        /// </summary>
        private static string GetPbxPath(string targetPath, string xcodeDir)
        {
            return Path.Combine(targetPath, xcodeDir, PbxFileName);
        }
    }
}