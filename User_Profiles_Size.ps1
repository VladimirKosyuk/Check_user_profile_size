#Created by https://github.com/VladimirKosyuk

#Check user profile size on every production server into domain via SMB, if size exceeds 1 GB - out to file.
#
# Build date: 01.06.2020									   
 
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$list = Get-ADComputer -Filter * -properties *|Where-Object {$_.enabled -eq $true} | Where-Object {(($_.distinguishedname -like "*Servers*") -and ($_.LastLogonDate -ge ((Get-Date).AddDays(-14))))}| Select-Object -ExpandProperty "name"
$Date = Get-Date -Format "MM.dd.yyyy"
$Unic = Get-WmiObject -Class Win32_ComputerSystem |Select-Object -ExpandProperty "Domain"
$log = ''

foreach ($pc in $list) {
$error.Clear()

        $BigFolder = {$Items = Get-ChildItem \\$pc"\c$\Users" | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object
        foreach ($i in $Items)
        {
            $subFolderItems = Get-ChildItem $i.FullName -recurse -force -ErrorAction SilentlyContinue| Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | where {$_.sum -gt "1073741824"} 
            foreach ($s in $subFolderItems) {$i.FullName + " -- " + "{0:N2}" -f ($subFolderItems.sum / 1GB) + " GB"}
        }
    }

    If ($Result = & $BigFolder){Write-Output (($pc)+";"+(Get-Date -Format "MM.dd.yyyy HH:mm")+";"+($Result| Out-String -Stream))| out-file $log\$Unic"_"$Date"_"Profiles.txt -Append}

}

Remove-Variable -Name * -Force -ErrorAction SilentlyContinue