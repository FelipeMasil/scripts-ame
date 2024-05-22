# Definir as variáveis de origem e destino
$sourceFolders = @(
    "\\ames-fat-01\c$\APAC",
    "\\ames-fat-01\c$\BPA",
    "\\ames-fat-01\c$\datasus\SisMamaFB",
    "\\ames-fat-01\c$\Program Files (x86)\Datasus\CNES"
)
$additionalFile = "\\172.35.16.82\C$\datasus\sisMamaFB\Banco\SISCAM4FBM.FDB"
$destinationFolder = "D:\Faturamento"

# Criar o diretório de destino se não existir
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Copiar as pastas
foreach ($folder in $sourceFolders) {
    $folderName = Split-Path -Path $folder -Leaf
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $folderName

    # Verificar se o caminho de origem existe
    if (Test-Path -Path $folder) {
        Copy-Item -Path $folder -Destination $destinationPath -Recurse -Force
    } else {
        Write-Host "Caminho de origem não encontrado: $folder"
    }
}

# Copiar o arquivo adicional se o caminho de origem existir
if (Test-Path -Path $additionalFile) {
    $fileName = Split-Path -Path $additionalFile -Leaf
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName
    Copy-Item -Path $additionalFile -Destination $destinationPath -Force
} else {
    Write-Host "Caminho de origem não encontrado ou máquina desligada: $additionalFile"
}

# Definir o nome do arquivo .tar com a data atual
$date = Get-Date -Format "dd_MM_yyyy"
$tarFileName = "bkp-fat-data-$date.tar"
$tarFilePath = Join-Path -Path $destinationFolder -ChildPath $tarFileName

# Compactar as pastas em um arquivo .tar
# Necessário ter o tar.exe disponível no sistema, normalmente disponível no PowerShell 5.1+ ou via instalação do pacote tar
Start-Process tar -ArgumentList "-cvf", $tarFilePath, "-C", $destinationFolder, "." -NoNewWindow -Wait

# Verificar se o arquivo .tar foi criado
    if (Test-Path -Path $tarFilePath) {

        # Remover o arquivo SISCAM4FBM.FDB
        $additionalFileName = Split-Path -Path $additionalFile -Leaf
        $additionalFilePath = Join-Path -Path $destinationFolder -ChildPath $additionalFileName
        Remove-Item -Path $additionalFilePath -Force

    # Remover as pastas copiadas
    foreach ($folder in $sourceFolders) {
        $folderName = Split-Path -Path $folder -Leaf
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $folderName
        Remove-Item -Path $destinationPath -Recurse -Force
    }

    # Gerenciar o número de backups, mantendo apenas os 4 mais recentes
    $backupFiles = Get-ChildItem -Path $destinationFolder -Filter "bkp-fat-data-*.tar" | Sort-Object LastWriteTime
    if ($backupFiles.Count -gt 6) {
        $filesToDelete = $backupFiles | Select-Object -First ($backupFiles.Count - 6)
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file.FullName -Force
        }
    }
} else {
    Write-Host "Erro ao criar o arquivo .tar"
}