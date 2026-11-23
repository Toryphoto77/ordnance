# Android launcher icon

End-on muzzle on `#0C0E12`: two bore rings, six rifling grooves, one witness tick. No filled disc, so the adaptive mask does not read as a coin. Master artwork is `assets/images/app-icon.png` (512×512). Regenerate with `python3 tool/render_launcher_icon.py`.

## Layout

```
app-icon/res/
├── mipmap-mdpi … xxxhdpi/   ic_launcher.png (48/72/96/144/192) and ic_launcher_round.png
├── mipmap-anydpi-v26/       ic_launcher.xml, ic_launcher_round.xml
├── drawable-mdpi … xxxhdpi/ ic_launcher_foreground.png (108/162/216/324/432)
│                            ic_launcher_monochrome.png (same sizes, white on transparent)
└── values/                  ic_launcher_colors.xml (background #0C0E12)
```

The adaptive foreground keeps the mark inside the 66dp safe zone. `ic_launcher_round.png` is the same artwork with a circular mask. The monochrome layer is the white mark for themed icons.

## How it is applied

`build-apk.sh`, `build-apk-offline*.sh`, and Android CI copy `app-icon/res/` into `android/app/src/main/res/` after `flutter create`.
