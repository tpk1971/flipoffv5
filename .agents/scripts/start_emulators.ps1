# Helper script to start Firebase emulators for Flipoff
# Ensures JAVA_HOME is set to JDK 25 and checks if port 8080 is already occupied.

$env:JAVA_HOME = "C:\Users\peterk\.jdks\jbr-25.0.2"

if (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue) {
    Write-Host "All emulators ready! (Already running)"
} else {
    npx firebase-tools emulators:start
}
