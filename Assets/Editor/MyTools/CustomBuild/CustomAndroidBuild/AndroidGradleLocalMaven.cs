using Invariable;
using System;
using System.IO;
using UnityEditor.Android;
using UnityEngine;



namespace MyTools
{
    public class AndroidGradleLocalMaven : IPostGenerateGradleAndroidProject
    {
        private const string RelativeMavenSrc = "Editor/MyTools/CustomBuild/CustomAndroidBuild/AndroidLocalMaven";
        private const string GeneratedMavenDir = "localMaven";
        private const string SettingsInsert = "        maven { url uri(\"${settings.rootDir}/localMaven\") }\n";

        public int callbackOrder => 10;



        public void OnPostGenerateGradleAndroidProject(string path)
        {
            string gradleRoot = Path.GetFullPath(Path.Combine(path, ".."));
            string src = Path.Combine(Application.dataPath, RelativeMavenSrc);
            string dest = Path.Combine(gradleRoot, GeneratedMavenDir);

            if (!Directory.Exists(src))
            {
                GameLog.Error($"找不到本地 Maven 目录: {src}");

                return;
            }

            CopyDirectory(src, dest);
            PatchSettingsGradle(Path.Combine(gradleRoot, "settings.gradle"));
        }



        /// <summary>
        /// 递归复制本地 Maven 目录到导出的 Gradle 工程，跳过 .meta
        /// </summary>
        private static void CopyDirectory(string src, string dest)
        {
            Directory.CreateDirectory(dest);

            foreach (string file in Directory.GetFiles(src))
            {
                if (file.EndsWith(".meta", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                File.Copy(file, Path.Combine(dest, Path.GetFileName(file)), true);
            }

            foreach (string dir in Directory.GetDirectories(src))
            {
                CopyDirectory(dir, Path.Combine(dest, Path.GetFileName(dir)));
            }
        }

        /// <summary>
        /// 在 dependencyResolutionManagement 的 repositories 开头插入本地 Maven
        /// </summary>
        private static void PatchSettingsGradle(string settingsPath)
        {
            if (!File.Exists(settingsPath))
            {
                GameLog.Error($"找不到 settings.gradle: {settingsPath}");

                return;
            }

            string text = File.ReadAllText(settingsPath);

            if (text.Contains("/localMaven"))
            {
                return;
            }

            const string marker = "dependencyResolutionManagement";
            int block = text.IndexOf(marker);

            if (block < 0)
            {
                GameLog.Error("settings.gradle 缺少 dependencyResolutionManagement");

                return;
            }

            int repos = text.IndexOf("repositories {", block);

            if (repos < 0)
            {
                GameLog.Error("settings.gradle 缺少 dependencyResolutionManagement.repositories");

                return;
            }

            int insertAt = text.IndexOf('\n', repos);

            if (insertAt < 0)
            {
                GameLog.Error("settings.gradle repositories 块无法插入本地 Maven");

                return;
            }

            text = text.Insert(insertAt + 1, SettingsInsert);
            File.WriteAllText(settingsPath, text);
            GameLog.Info("已写入 Gradle 本地 Maven: localMaven");
        }
    }
}
