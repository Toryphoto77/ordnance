# Android 启动图标资源

当前图标：深灰底（`#0B0F14`）上的轨道环 + 中心十字准心，母图取自 `assets/images/app-icon.png`（512×512）。

## 目录内容

```
app-icon/res/
├── mipmap-mdpi/        ic_launcher.png(48)   ic_launcher_round.png
├── mipmap-hdpi/        ic_launcher.png(72)   ic_launcher_round.png
├── mipmap-xhdpi/       ic_launcher.png(96)   ic_launcher_round.png
├── mipmap-xxhdpi/      ic_launcher.png(144)  ic_launcher_round.png
├── mipmap-xxxhdpi/     ic_launcher.png(192)  ic_launcher_round.png
├── mipmap-anydpi-v26/  ic_launcher.xml  ic_launcher_round.xml   自适应图标入口
├── drawable-mdpi … xxxhdpi/
│                       ic_launcher_foreground.png(108/162/216/324/432)
└── values/             ic_launcher_colors.xml（背景色 #0B0F14）
```

`ic_launcher_round.png` 为圆形裁切版本；自适应图标的前景层把图标内容缩进 66dp 安全区，圆外仍是同色底，任何桌面蒙版都不会切到图形。

## 用法

不需要手工拷贝：`build-apk.sh`、`build-apk-offline*.sh` 与 Android CI 都会在 `flutter create` 生成安卓工程后，把 `app-icon/res/` 合并进 `android/app/src/main/res/`。

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    ... >
```

## 重新生成

图标由 `assets/images/app-icon.png` 用 PIL 缩放生成（各密度 mipmap、圆形遮罩、自适应前景）。换母图后重新按上表尺寸导出即可，不需要改代码。
