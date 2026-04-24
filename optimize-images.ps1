# Image Optimization Script for KSHS Library
# Converts large JPG backgrounds to optimized WebP or compressed JPG

Add-Type -AssemblyName System.Drawing

$sourceDir = "site images"
$backupDir = "site images\original-backup"

# Create backup directory
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Get all JPG files
$images = Get-ChildItem -Path $sourceDir -Filter "*.jpg" -File

foreach ($img in $images) {
    $sourcePath = $img.FullName
    $backupPath = Join-Path $backupDir $img.Name
    
    # Backup original
    if (!(Test-Path $backupPath)) {
        Copy-Item $sourcePath $backupPath -Force
        Write-Host "Backed up: $($img.Name)" -ForegroundColor Cyan
    }
    
    # Load image
    $bitmap = [System.Drawing.Image]::FromFile($sourcePath)
    
    # Calculate target size (max 1920 width for backgrounds)
    $maxWidth = 1920
    $maxHeight = 1080
    $newWidth = $bitmap.Width
    $newHeight = $bitmap.Height
    
    if ($newWidth -gt $maxWidth -or $newHeight -gt $maxHeight) {
        $ratio = [Math]::Min($maxWidth / $newWidth, $maxHeight / $newHeight)
        $newWidth = [int]($newWidth * $ratio)
        $newHeight = [int]($newHeight * $ratio)
    }
    
    # Create resized bitmap
    $resized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($resized)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($bitmap, 0, 0, $newWidth, $newHeight)
    $graphics.Dispose()
    $bitmap.Dispose()
    
    # Save as optimized JPEG (quality 65 for backgrounds - good balance)
    $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $qualityParam = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality, 65
    )
    $encoderParams.Param[0] = $qualityParam
    
    # Overwrite original with optimized version
    $resized.Save($sourcePath, $encoder, $encoderParams)
    $resized.Dispose()
    
    $newSize = (Get-Item $sourcePath).Length
    Write-Host "Optimized: $($img.Name) -> $([math]::Round($newSize/1KB,1)) KB ($newWidth x $newHeight)" -ForegroundColor Green
}

Write-Host "`nOptimization complete! Originals backed up to: $backupDir" -ForegroundColor Yellow
