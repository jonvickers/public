#I think these computers in AD only have this NetBootGUID field because we use WDS Windows Deployment Server and Prestage the computers into AD. 
#I don't think regular AD would have these Mac Addresses.

#need to use remoting and run this script via DC.

#split this script into 2 parts..  1 get the MAC Address and Part 2 to remote and get the computer name via a DC.

#Install-WindowsFeature -Name RSAT-AD-PowerShell

Import-Module ActiveDirectory

function GetLocalMacAddress {

    #get the first physical card that is up and the local mac
    $networkCard = Get-NetAdapter -Physical | Where-Object {$_.InterfaceDescription -notlike "*remote*" -and $_.Status -eq "Up"} | Select-Object -First 1
    
    return $networkCard.MacAddress

}

#Returns the computer name as a string.
function GetCompNameFromMac {
    param(
        [string] $mac
    )

    # Check if the input parameter is null or empty, Try to Get Local Mac
    if ([string]::IsNullOrEmpty($mac)) {
        $mac = GetLocalMacAddress
    }

    # Check if the input parameter is null or empty
    if ([string]::IsNullOrEmpty($mac)) {
        # Throw a custom error message and return from the function
        throw "Mac Address Parameter null or empty."
        return
    }
    
    # Remove the hyphens from the MAC address
    $macClean = $mac -replace "-", ""

    # Construct the GUID-like string
    $guidLikeString = "00000000-0000-0000-0000-" + $macClean
    
    #add Remoting right here to get this from a DC
    #returns only computers with a NetBootGUID
    
    #older working version, required searching all computers for a hit, new search returns 1 record.
    #$computers = Get-ADComputer -Filter {netbootGUID -like '*'} -Properties Name, netBootGUID
    
    [guid]$netbootguid = $guidLikeString
    $computers = Get-ADComputer -Filter {netbootGUID -eq $netbootguid} -Properties Name, netBootGUID
      
    foreach ($computer in $computers){
        
        $macAddresses = [BitConverter]::ToString($computer.netBootGUID).Remove(0,30)
        if ($macAddresses -eq $mac){
            return $computer.Name
        }
    }
    Write-Host "This mac address was not found"
    return $null
}

#False Hit Negative Test
#GetCompNameFromMac "D8-9E-F3-7A-15-77"

#TugalooDC1 Postive Test
#GetCompNameFromMac "D8-9E-F3-7A-15-7C"

GetCompNameFromMac

