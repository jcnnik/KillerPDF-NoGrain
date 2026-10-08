# Strips the film grain from a KillerPDF source checkout.
# Usage: ./remove-grain.ps1 -Path <KillerPDF checkout>
param([string]$Path = '.')
$ErrorActionPreference = 'Stop'

# Lever 1: every grain texture is built by a pixel loop that ends in `pixels[i + 3] = <alpha>;`
# (MainWindow, crash dialog, installer). Force alpha to 0 so the tile is fully transparent;
# all ~260 places that paint the tile then paint nothing.
$alpha = 'pixels\[i \+ 3\] = [^;]+;'
$hits = 0
Get-ChildItem $Path -Recurse -Filter *.cs | Where-Object FullName -notmatch '\\(bin|obj)\\' | ForEach-Object {
    $src = [IO.File]::ReadAllText($_.FullName)
    $n = [regex]::Matches($src, $alpha).Count
    if ($n) {
        [IO.File]::WriteAllText($_.FullName, [regex]::Replace($src, $alpha, 'pixels[i + 3] = 0;'))
        Write-Host "alpha -> 0 ($n): $($_.FullName)"
        $hits += $n
    }
}
# Upstream refactored the generator: fail loudly instead of shipping a grainy build.
if ($hits -eq 0) { throw 'No grain generator found. Upstream changed; update remove-grain.ps1.' }

# Lever 2: belt and braces, zero the per-theme grain opacity too.
Get-ChildItem (Join-Path $Path 'Themes') -Filter *.xaml | ForEach-Object {
    $src = [IO.File]::ReadAllText($_.FullName)
    $new = $src -replace '(x:Key="GrainOpacity"[^>]*>)[^<]+<', '${1}0<'
    if ($new -ne $src) { [IO.File]::WriteAllText($_.FullName, $new); Write-Host "GrainOpacity -> 0: $($_.Name)" }
}
