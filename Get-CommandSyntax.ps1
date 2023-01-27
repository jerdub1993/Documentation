function Get-CommandSyntax {
    [CmdletBinding(
        DefaultParameterSetName = 'Name'
    )]
    param (
        [Parameter(
            ParameterSetName = 'Name',
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [string]$CommandName,
        [Parameter(
            ParameterSetName = 'Command',
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        $Command
    )
    function Get-ParameterString {
        param (
            [System.Management.Automation.CommandParameterInfo]$Parameter
        )
        $Name = $Parameter.Name
        $Type = $Parameter.ParameterType.Name
        if ($Type -match '`'){
            $Type = $Type.Split('`')[0] + '[]'
        }
        $Position = $Parameter.Position
        $Mandatory = $Parameter.IsMandatory
        $NameMod = "-{0}" -f $Name
        $TypeMod = "<{0}>" -f $Type
        $Line = if ($Parameter.ParameterType -eq [System.Management.Automation.SwitchParameter]){
            $NameMod
        } else {
            if ([double]$Position -ge 0){
                $NameMod = "[{0}]" -f $NameMod
            }
            "{0} {1}" -f $NameMod, $TypeMod
        }
        $Line = if ($Mandatory){
            $Line
        } else {
            "[{0}]" -f $Line
        }
        return $Line
    }
    if ($PSCmdlet.ParameterSetName -eq 'Name'){
        try {
            $Command = Get-Command -Name $CommandName -ErrorAction Stop
        } catch [System.Management.Automation.CommandNotFoundException] {
            throw $_
            exit 1
        }
    }
    $CommonParameters = @(
        "Debug",
        "ErrorAction",
        "ErrorVariable",
        "InformationAction",
        "InformationVariable",
        "OutVariable",
        "OutBuffer",
        "PipelineVariable",
        "Verbose",
        "WarningAction",
        "WarningVariable"
    )
    $ParameterSets = foreach ($Set in $Command.ParameterSets){
        $ParameterSetName = if ($Set.Name -like "*AllParameterSets*"){
            'All'
        } else {
            $Set.Name
        }
        $ParametersRaw = $Set.Parameters | Where-Object Name -notin $CommonParameters
        $Parameters_Position = $ParametersRaw | Where-Object { [double]$_.Position -ge 0 } | Sort-Object Position
        $Parameters_NoPosition = $ParametersRaw | Where-Object { [double]$_.Position -lt 0 } | Sort-Object Position -Descending
        $Parameters = @()
        foreach ($Parameter in $Parameters_Position) {
            $Parameters += Get-ParameterString -Parameter $Parameter
        }
        foreach ($Parameter in $Parameters_NoPosition) {
            $Parameters += Get-ParameterString -Parameter $Parameter
        }
        [PSCustomObject]@{
            Name = $ParameterSetName
            Parameters = $Parameters
        }
    }
    return [PSCustomObject]@{
        Command = $Command
        ParameterSets = $ParameterSets
    }
}
function Get-DisplaySyntax {
    param (
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        $CommandName,
        [switch]$ParameterSetName,
        [switch]$Clipboard
    )
    $Syntax = Get-CommandSyntax -CommandName $CommandName
    $Name = $Syntax.Command.Name
    Write-Host "`nCommand: $Name`n"
    foreach ($Set in $Syntax.ParameterSets){
        $Msg = "ParameterSetName: $($Set.Name)"
        if ($Clipboard){
            $Msg | Set-Clipboard
            Read-Host $Msg | Out-Null
        } else {
            Write-Host $Msg
        }
        Write-Host ""
        $Array = @(
            $Name
        )
        foreach ($Param in $Set.Parameters){
            $Array += "   {0}" -f $Param
        }
        $Combined = $Array -join "`n"
        if ($Clipboard){
            $Combined | Set-Clipboard
        }
        Write-Host $Combined
        Read-Host "`nContinue" | Out-Null
    }
}
function Get-Parameters {
    [CmdletBinding(
        DefaultParameterSetName = 'Name'
    )]
    param (
        [Parameter(
            ParameterSetName = 'Name',
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [string]$CommandName,
        [Parameter(
            ParameterSetName = 'Command',
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        $Command
    )
    if ($PSCmdlet.ParameterSetName -eq 'Name'){
        try {
            $Command = Get-Command -Name $CommandName -ErrorAction Stop
        } catch [System.Management.Automation.CommandNotFoundException] {
            throw $_
            exit 1
        }
    }
    $CommonParameters = @(
        "Debug",
        "ErrorAction",
        "ErrorVariable",
        "InformationAction",
        "InformationVariable",
        "OutVariable",
        "OutBuffer",
        "PipelineVariable",
        "Verbose",
        "WarningAction",
        "WarningVariable"
    )
    $ParametersRaw = $Command.ParameterSets.Parameters | Where-Object Name -notin $CommonParameters
    $Parameters_Position = ($ParametersRaw | Where-Object { [double]$_.Position -ge 0 } | Sort-Object Position).Name | Select-Object -Unique
    $Parameters_NoPosition = ($ParametersRaw | Where-Object { [double]$_.Position -lt 0 } | Sort-Object Position -Descending).Name | Select-Object -Unique
    $Parameters = @()
    $Parameters_Position | ForEach-Object {
        $Parameters += $_
    }
    $Parameters_NoPosition | ForEach-Object {
        $Parameters += $_
    }
    return ($Parameters | Select-Object -Unique)
}