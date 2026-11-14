# Ordnance

Ordnance 是一款 Flutter 枪械图鉴 App：枪械图鉴、配件目录、复装手册与社区四个 Tab，中文 / 繁体中文 / English 三语。数据只记录公开资料，查不到出处的一律留空，不现编、不推算。

## 功能

- **图鉴**：738 支真实枪械、8 个品类；按名称 / 厂商 / 口径搜索，搜索结果可再按品类筛选；品类图与名枪照片来自 Wikimedia Commons 免费授权图，详情页页脚署名。详情页可把枪登记进「我的枪柜」，记录购买日期、入手价、射弹数、归零状态、保养与故障。
- **配件目录**：163 条国内外厂商配件，按品类筛选，可装机到具体枪上；「我的配件库」只记本机件数。
- **复装手册**：子弹目录 63 个口径、装药表 34 条（只收公开手册原文）、复装组件 308 条、供应商与 SOP。
- **工具**：单位制、DOPE 数据本（归零助手）、复装成本、弹药库存、保养记录、测速导入、靶场行程与换算、天气与传感器、射手基础课。
- **社区**：本机版动态流、私信、经验等级、勋章、靶场成绩公开。账号与帖子只存在本机（SharedPreferences），换设备需重新注册；经验榜为本机数据。
- **其他**：主题色与深浅色、检查更新（GitHub Releases，仅 Android）、导出我的数据、App 日志。

## 数据规模

| 数据 | 数量 |
| --- | --- |
| 枪械 | 738（8 个品类） |
| 配件 | 163 |
| 口径（子弹目录） | 63 |
| 停售名枪鉴赏 | 12 |
| 复装组件 | 308 |
| 装药表条目 | 34 |

数字由测试自检（见 `test/data_integrity_test.dart`），改动数据后跑一遍测试即可确认没有漏。

## 技术栈与结构

Flutter 3.47.8 / Dart，Material 3，无第三方运行时依赖（只有 `flutter_test`）。

```text
lib/
  main.dart               入口、底部导航
  app_version.dart        App 版本号（单一来源，与 pubspec.yaml 同步）
  models.dart             数据模型
  data.dart               枪械 / 配件 / 口径 / 名枪 / 复装数据
  i18n.dart               三语界面文案（简体 / 繁体 / 英文）
  community_store.dart    本机社区数据（账号、帖子、等级、勋章）
  screens/                各页面
  widgets/                复用组件
assets/images/            枪图、品类图、名枪图、App 图标
assets/fonts/             Manrope 四个字重
app-icon/res/             Android 启动图标（mipmap / 自适应前景 / 背景色）
shaders/                 液体玻璃 shader
test/                    数据完整性 + 多语言完整性测试
.github/workflows/       Android CI（分析 + 测试 + debug APK）与 iOS TestFlight
build-apk.sh             本地在线编译脚本
build-apk-offline*.sh    受限网络下的离线编译脚本
fetch-mirror.py          离线 Gradle 依赖镜像抓取
```

## 构建

仓库**不提交 `android/` 目录**：它由 `flutter create` 生成，脚本会把 `lib/`、`assets/`、`app-icon/res/` 覆盖进去再编译。

```bash
bash build-apk.sh            # 在线编译，产物 app-debug.apk
bash build-apk-offline.sh    # 出站受限时先 python3 fetch-mirror.py，再跑这个
```

iOS 走 `.github/workflows/ios-testflight.yml`（需自备 Apple 开发者账号与签名 Secrets，手动触发）。

Android 的 `flutter create` 参数为 `--project-name firearms_catalog --org com.example`，随后由 `patch-android-config.py` 把 `applicationId` / `namespace` 改成 `com.toryphoto77.ordnance`，并迁移 `MainActivity` 的包路径；若 `android/key.properties` 存在，还会把 release 构建切到正式密钥签名。iOS Bundle ID 仍是 `com.wangtao969.ordnance`，更换需要 Apple 账号侧重新登记，暂未改动。

## 签名与发版

v2.x 的发布密钥已丢失且无法恢复（APK 里只有公钥证书），因此从 v3.0.0 起使用新密钥和新包名 `com.toryphoto77.ordnance`。**新旧安装包不能互相覆盖**：老用户需要安装新版，再用设置页「从旧版导入数据」粘贴旧版导出的 JSON 迁移收藏、靶场成绩与经验。

密钥材料不进仓库（`signing/` 已在 `.gitignore`）。CI 签名需要在本仓库 Settings → Secrets 配置：

| 名称 | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ordnance-release.jks` 的输出 |
| `ANDROID_KEYSTORE_PASSWORD` | 密钥库口令 |
| `ANDROID_KEY_PASSWORD` | 密钥口令（PKCS12 一般与库口令相同） |
| `ANDROID_KEY_ALIAS` | 别名，当前密钥库为 `ordnance` |

可选 Variable `ANDROID_CERT_SHA256`：填证书 SHA-256 指纹后，构建会自动核对，避免用错密钥签出无法覆盖安装的包。

命令行配置（需要仓库管理员权限）：

```bash
gh secret set ANDROID_KEYSTORE_BASE64 < signing/ordnance-release.jks.b64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_PASSWORD
gh secret set ANDROID_KEY_ALIAS
gh variable set ANDROID_CERT_SHA256 --body "37:06:2F:54:..."   # 可选
```

发版流程：先把 `pubspec.yaml` 与 `lib/app_version.dart` 改成同一版本并提交，再推 `v*` 标签。`.github/workflows/android-release.yml` 会校验 tag 与版本一致、用私钥签名、`apksigner` 验证证书、构建通用 APK 并上传到同名 GitHub Release；App 内「检查更新」即可直接下载。

想先验证链路但不发版：手动运行该 workflow 并勾选 `use_test_key`，会用一次性测试密钥构建，只上传 artifact。

## 测试与 CI

```bash
flutter analyze
flutter test
```

- `test/data_integrity_test.dart`：枪械数量、品类合法性、名称唯一性、图片与字体文件存在性、`appVersion` 与 `pubspec.yaml` 一致。
- `test/i18n_keys_test.dart`：三套语言键集合完全一致、界面里 `tr('...')` 用到的键都已登记。
- `.github/workflows/android.yml`：push / PR 时跑 `flutter analyze`、`flutter test`，再生成安卓脚手架并构建 debug APK。
- `.github/workflows/android-release.yml`：推 `v*` 标签时签正式包并发布，详见上一节。

## 版本号

发版时同时改两处：

- `pubspec.yaml` 的 `version: 3.0.0+51`（版本名 + 构建号）
- `lib/app_version.dart` 的 `appVersion`（App 内显示、检查更新比对）

`test/data_integrity_test.dart` 会校验两者一致。

## 更新检查与发布

App 内「检查更新」请求 `https://api.github.com/repos/Toryphoto77/ordnance/releases/latest`，取第一个 `.apk` 资产。发 Release 时**必须上传 APK 资产**，否则只能跳到网页。

## v3.0.0 签名迁移说明

- 原 release 密钥丢失，改用新密钥 + 新包名 `com.toryphoto77.ordnance`；新旧包可并存，但旧版不能自动升级。
- 新增「从旧版导入数据」（设置页），接受 v2.x「导出我的数据」的 JSON，合并收藏、靶场成绩并按旧经验抬升等级。
- 发版从本地手工签名改为 CI 自动签名 + 指纹校验 + 自动上传 Release。
- 已知限制：社区仍为本机版；iOS Bundle ID 未变。
