$collectionPath = "postman/collections/LTX"
$files = Get-ChildItem -Path $collectionPath -Recurse -Filter "*.request.yaml"
$modifiedFiles = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match '"isCreate"') {
        $lines = Get-Content -Path $file.FullName
        $newLines = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '^\s*"isCreate"\s*:\s*(true|false)\s*,?\s*$') {
                # This line is being removed.
                # Check if previous non-empty line ends with a comma and next non-empty line is a closing bracket/brace
                # We need to handle trailing comma: if previous line ends with comma and this was the last property
                # Find next non-blank line
                $nextLineIndex = $i + 1
                while ($nextLineIndex -lt $lines.Count -and $lines[$nextLineIndex] -match '^\s*$') {
                    $nextLineIndex++
                }
                $nextLine = if ($nextLineIndex -lt $lines.Count) { $lines[$nextLineIndex] } else { "" }

                # Find previous non-blank line index in newLines
                $prevIndex = $newLines.Count - 1
                while ($prevIndex -ge 0 -and $newLines[$prevIndex] -match '^\s*$') {
                    $prevIndex--
                }

                if ($prevIndex -ge 0) {
                    $prevLine = $newLines[$prevIndex]
                    # If next line is a closing bracket/brace and previous line ends with comma, remove trailing comma
                    if ($nextLine -match '^\s*[\]\}]' -and $prevLine -match ',\s*$') {
                        $newLines[$prevIndex] = $prevLine -replace ',\s*$', ''
                    }
                    # If next line is NOT a closing bracket/brace and previous line does NOT end with comma, add comma
                    # (this handles case where isCreate had no trailing comma but was not the last property)
                    # Actually: if isCreate line had a comma (meaning more props follow) but prev line has no comma - add one
                    if ($line -match ',\s*$' -and $nextLine -notmatch '^\s*[\]\}]' -and $prevLine -notmatch ',\s*$') {
                        $newLines[$prevIndex] = $prevLine.TrimEnd() + ","
                    }
                }
                # Skip this line (don't add to newLines)
                continue
            }
            $newLines += $line
        }
        $newContent = $newLines -join "`r`n"
        # Preserve trailing newline if original had one
        if ($content.EndsWith("`n")) {
            $newContent += "`r`n"
        }
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        $modifiedFiles += $file.FullName
    }
}

Write-Output "Modified $($modifiedFiles.Count) file(s):"
foreach ($f in $modifiedFiles) {
    Write-Output "  $f"
}
