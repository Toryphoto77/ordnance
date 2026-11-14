#!/usr/bin/env python3
"""把 flutter create 生成的 Android 工程改成 Ordnance 的正式配置。

用法（仓库根目录，且已执行 flutter create 生成 android/）：
    python3 patch-android-config.py

做三件事，可重复执行：
  1. applicationId / namespace 改成 com.toryphoto77.ordnance；
  2. MainActivity 移到新包路径并改写 package 声明；
  3. 如果 android/key.properties 存在，就把 release 构建改成用正式密钥库签名
     （否则保持 Flutter 模板的 debug 签名，供本地调试与 CI 冒烟构建）。

密钥库与 key.properties 都不进仓库，由本地脚本或 CI 生成。
"""
import sys
from pathlib import Path

APP_ID = "com.toryphoto77.ordnance"
OLD_ID = "com.example.firearms_catalog"
GRADLE = Path("android/app/build.gradle.kts")
KEY_PROPS = Path("android/key.properties")
OLD_ACTIVITY_DIR = Path("android/app/src/main/kotlin") / OLD_ID.replace(".", "/")
NEW_ACTIVITY_DIR = Path("android/app/src/main/kotlin") / APP_ID.replace(".", "/")

LOADER = '''import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''

OLD_SIGNING = '''    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }'''

NEW_SIGNING = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = keystorePropertiesFile.exists()
                ? signingConfigs.getByName("release")
                : signingConfigs.getByName("debug")
        }
    }'''


def patch_ids() -> None:
    s = GRADLE.read_text()
    if APP_ID in s and OLD_ID not in s:
        print("包名已是 " + APP_ID + "，跳过")
    else:
        GRADLE.write_text(s.replace(OLD_ID, APP_ID))
        print("包名改为 " + APP_ID)


def move_activity() -> None:
    src = OLD_ACTIVITY_DIR / "MainActivity.kt"
    if not src.exists():
        if (NEW_ACTIVITY_DIR / "MainActivity.kt").exists():
            print("MainActivity 已在新包路径，跳过")
            return
        print("找不到 MainActivity.kt，模板结构可能已变", file=sys.stderr)
        sys.exit(2)
    NEW_ACTIVITY_DIR.mkdir(parents=True, exist_ok=True)
    dst = NEW_ACTIVITY_DIR / "MainActivity.kt"
    dst.write_text(src.read_text().replace("package " + OLD_ID, "package " + APP_ID))
    src.unlink()
    # 清掉空的旧包目录，避免残留 com/example 结构。
    d = OLD_ACTIVITY_DIR
    while d != Path("android/app/src/main/kotlin") and d.is_dir() and not any(d.iterdir()):
        d.rmdir()
        d = d.parent
    print("MainActivity 移到 " + str(dst.parent))


def patch_signing() -> None:
    if not KEY_PROPS.exists():
        print("没有 key.properties：release 仍用 debug 签名（仅调试用）")
        return
    s = GRADLE.read_text()
    if "keystoreProperties" in s:
        print("签名配置已存在，跳过")
        return
    if OLD_SIGNING not in s:
        print("没找到 Flutter 模板的 release buildTypes 块，模板可能已改版", file=sys.stderr)
        sys.exit(2)
    GRADLE.write_text(s.replace("android {", LOADER + "android {", 1).replace(
        OLD_SIGNING, NEW_SIGNING, 1))
    print("release 签名配置已写入")


def main() -> int:
    if not GRADLE.exists():
        print(str(GRADLE) + " 不存在，先跑 flutter create 生成脚手架", file=sys.stderr)
        return 1
    patch_ids()
    move_activity()
    patch_signing()
    return 0


if __name__ == "__main__":
    sys.exit(main())
