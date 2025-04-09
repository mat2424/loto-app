# Script to add Flutter to PATH
$flutterPath = "C:\Users\varta\Downloads\Horseshoe\flutter\bin"

# Get the current PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Check if Flutter path is already in PATH
if ($currentPath -notlike "*$flutterPath*") {
    # Add Flutter to PATH
    $newPath = $currentPath + ";" + $flutterPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Flutter has been added to your PATH."
} else {
    Write-Host "Flutter is already in your PATH."
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
