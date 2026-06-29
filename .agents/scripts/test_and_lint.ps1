# Flutter Pinball Test & Lint runner
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Running Flutter Linter and Tester..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 1. Run Flutter Analyze (Linter)
Write-Host "`n[1/2] Analyzing codebase..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter analysis failed. Please fix lint warnings before proceeding."
    exit $LASTEXITCODE
}
Write-Host "✓ Codebase analysis passed." -ForegroundColor Green

# 2. Run Tests
Write-Host "`n[2/2] Running unit and widget tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter tests failed."
    exit $LASTEXITCODE
}
Write-Host "✓ All tests passed successfully." -ForegroundColor Green
Write-Host "`nBuild Verification: COMPLETE." -ForegroundColor Green
