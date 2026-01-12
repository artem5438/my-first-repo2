# BACKUP-Powershell
$ContainerName = "edu-3kurs-db-db-1"
$DbUser = "nora_user"
$DbName = "nora_db"
$BackupDir = "C:\backups\db" # ЗАМЕНА НА СВОЮ ЛОКАЛЬ!
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFile = "$BackupDir\backup_$Date.sql"

if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir }

docker exec $ContainerName pg_dump -U $DbUser $DbName > $BackupFile

# удаляние бэкапа старше 7 дней
Get-ChildItem $BackupDir -Filter *.sql | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item