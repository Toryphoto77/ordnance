#!/usr/bin/env python3
"""把 flutter create 生成的 Android 工程改成用 release 密钥库签名。

用法（在仓库根目录，Android 脚手架已生成、android/key.properties 已写好）：
    python3 patch-android-signing.py

只做两件事，可重复执行：
  1. 在 android/app/build.gradle.kts 里读取 key.properties；
  2. 把 buildTypes.release 从 debug 签名改成 release 签名。

key.properties 由调用方生成（本地脚本或 CI），密钥库本身不进仓库。
"""
import sys
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")

LOADER = '''import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''

OLD = '''    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }'''

NEW = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }'''


def main() -> int:
    if not GRADLE.exists():
        print(f"{GRADLE} 不存在，先跑 flutter create 生成脚手架", file=sys.stderr)
        return 1
    if not Path("android/key.properties").exists():
        print("android/key.properties 不存在，签名会退回 debug 密钥", file=sys.stderr)
        return 1

    s = GRADLE.read_text()
    if "keystoreProperties" in s:
        print("签名配置已存在，跳过")
        return 0
    if OLD not in s:
        print("没找到 Flutter 模板的 release buildTypes 块，模板可能已改版", file=sys.stderr)
        return 2

    s = s.replace("android {", LOADER + "android {", 1)
    s = s.replace(OLD, NEW, 1)
    GRADLE.write_text(s)
    print("release 签名配置已写入")
    return 0


if __name__ == "__main__":
    sys.exit(main())
