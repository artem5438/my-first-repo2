$ContainerName = "edu-3kurs-db-db-1"
$DbUser = "nora_user"
$DbName = "nora_db"
$BackupDir = "C:\backups\db" # ЗАМЕНА НА СВОЮ ЛОКАЛЬ!

# передача в psql
Get-Content $BackupFile | docker exec -i $ContainerName psql -U $DbUser -d $DbName