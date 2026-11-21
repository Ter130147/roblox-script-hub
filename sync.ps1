param (
    [string]$msg = "update script"
)

git add .
git commit -m "$msg"
git push origin main