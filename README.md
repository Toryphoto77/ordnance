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

Android 的 `flutter create` 参数为 `--project-name firearms_catalog --org com.example`，包名是 `com.example.firearms_catalog`；iOS Bundle ID 是 `com.wangtao969.ordnance`。**改包名会影响既有安装的升级覆盖，本次交接不动签名与包名**，需要更换时请连同原签名密钥一起处理。

## 测试与 CI

```bash
flutter analyze
flutter test
```

- `test/data_integrity_test.dart`：枪械数量、品类合法性、名称唯一性、图片与字体文件存在性、`appVersion` 与 `pubspec.yaml` 一致。
- `test/i18n_keys_test.dart`：三套语言键集合完全一致、界面里 `tr('...')` 用到的键都已登记。
- `.github/workflows/android.yml`：push / PR 时跑 `flutter analyze`、`flutter test`，再生成安卓脚手架并构建 debug APK。

## 版本号

发版时同时改两处：

- `pubspec.yaml` 的 `version: 2.4.0+49`（版本名 + 构建号）
- `lib/app_version.dart` 的 `appVersion`（App 内显示、检查更新比对）

`test/data_integrity_test.dart` 会校验两者一致。

## 更新检查与发布

App 内「检查更新」请求 `https://api.github.com/repos/Toryphoto77/ordnance/releases/latest`，取第一个 `.apk` 资产。发 Release 时**必须上传 APK 资产**，否则只能跳到网页。

## v2.4.0 交接说明

- 仓库维护从 `wangtao969` 转到 `Toryphoto77`；App 内 GitHub 链接与检查更新地址已同步。
- 补回此前未提交的 `assets/images`、`assets/fonts` 与 Android 图标（从 v2.3.2 官方 APK 还原，`media-generation-*` 中间产物不提交）。
- 版本号收敛到 `lib/app_version.dart` 单一来源。
- 清理了 v2.3.2 已下线功能遗留的未引用文件（刀具图鉴、任务 / 签到 / 通知中心），`flutter analyze` 不再报错。
- 补齐原先只有简中的 26 个界面的繁中 / 英文译文；新增搜索结果的品类筛选与数据概况卡。
- 已知限制：社区仍为本机版；本环境没有原发布签名密钥，Release 只提供未签名 / debug 构建说明，签名版需原密钥在本地或 CI Secrets 中构建。
