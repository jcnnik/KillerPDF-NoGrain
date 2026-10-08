# KillerPDF, NO GRAIN

Unofficial build of [KillerPDF](https://github.com/SteveTheKiller/KillerPDF) with the film grain overlay removed. Everything else is untouched upstream code.

Download from [Releases](../../releases), same two files as upstream:

- `KillerPDF.exe`: installer
- `KillerPDF-Portable.exe`: runs without installing

The builds are unsigned (the upstream certificate is the author's), so Windows SmartScreen may warn on first launch: "More info", then "Run anyway".

## How the grain works upstream

The grain is not one setting. About 260 places across 50 files (main window, viewer panes, toolbars, every dialog, the installer) paint a tiled grain texture, so deleting the `GrainBrushShared` brush in `MainWindow.xaml` only removes it from popup menus.

All of those places paint the same few generated bitmaps, though. The texture is built at runtime by a pixel loop in three spots:

| File | What it textures |
|---|---|
| `Shell/ContextMenu.cs` (`ApplyGrainTexture`) | the app itself, every window and dialog |
| `App.xaml.cs` (`EnsureCrashPreviewGrain`) | the crash dialog |
| `Packaging/KillerLauncher/InstallerWizard.xaml.cs` (`CreateGrain`) | the installer/launcher |

Each loop ends with a line setting the pixel's alpha, `pixels[i + 3] = ...;`.

## The fix

[`remove-grain.ps1`](remove-grain.ps1) does two things:

1. Rewrites `pixels[i + 3] = ...;` to `pixels[i + 3] = 0;`. The texture becomes fully transparent, so all 260 places still draw it but nothing shows up. No layout or code paths change.
2. Sets `GrainOpacity` to `0` in every `Themes/*.xaml`, as a second safety net.

If step 1 finds nothing (upstream rewrote the generator), the script fails and nothing gets released, so you never get a grainy build silently.

Run it by hand on any checkout:

```powershell
./remove-grain.ps1 -Path path\to\KillerPDF
powershell -ExecutionPolicy Bypass -File path\to\KillerPDF\build\build-packages.ps1
# output: path\to\KillerPDF\bin\Release\net10.0-windows\publish\
```

## Automation

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs daily (or manually from the Actions tab). When upstream has a release this repo doesn't have yet, it checks out that tag, runs the patch, builds the installer and portable exe with upstream's own packaging script, and publishes them here as a release with the same tag.

GitHub pauses scheduled workflows after 60 days without repo activity. If releases stop showing up, re-enable the workflow in the Actions tab.

## License

KillerPDF is GPL-3.0. Each release includes the patched source as `KillerPDF-<version>-src.zip`.
