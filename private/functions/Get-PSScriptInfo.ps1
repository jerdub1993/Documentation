function Get-PSScriptInfo
{
    <#
        .SYNOPSIS
            Gets information from a script for use with other functions.

        .DESCRIPTION
            This function takes a script (System.IO.FileInfo), source directory (System.IO.DirectoryInfo), and list of enabled items (System.String[]) and returns information about the script and any functions within--specifically the following:
                - Script/function name
                - Path in the source directory
                - Full path (the path, including the item name)
                - Parent item (if the item is a function, this will be the script where the function is found)
                - Item type (script/function)
                - Whether or not the item is in the provided list of enabled items
                - The script parser object

        .OUTPUTS
            PSCustomObject[]

        .PARAMETER File
            The script from which to get the information.

        .PARAMETER SourceDirectory
            Source directory where the script is found. This will be used to get the path.

        .PARAMETER EnabledItems
            A list of enabled items. The items must use the abbreviated path of the item, for example:
                The desired item is the Documentation.ps1 script, which is located at C:\Users\joe.smith\repos\canes-cloud\Utilities\Documentation\Documentation.ps1.
                The correct path to use for this parameter would be: Utilities/Documentation/Documentation.ps1
            To include a specific function as an enabled item, include the function name at the end of the path, as follows:
                The desired item is the Generate-Documentation function, from the Documentation.ps1 script located at C:\Users\joe.smith\repos\canes-cloud\Utilities\Documentation\Documentation.ps1.
                The correct path to use would be: Utilities/Documentation/Documentation.ps1/Generate-Documentation
            
            This parameter supports regular expression patterns. For example:
                The desired item(s) are all functions within the Documentation.ps1 script, located at C:\Users\joe.smith\repos\canes-cloud\Utilities\Documentation\Documentation.ps1.
                The correct pattern to use would be: Utilities/Documentation/Documentation.ps1/.*
            Note that the above won't include the Documentation.ps1 script itself--only the functions. The path "Utilities/Documentation/Documentation.ps1" doesn't match the regex pattern "Utilities/Documentation/Documentation.ps1/.*".
            To include the script and functions within:
                The desired item(s) are the Documentation.ps1 script *and* all functions within.
                The correct pattern to use would be any pattern that matches the script path plus any subsequent text (eg: function names), such as:
                    Utilities/Documentation/.*
                    Utilities/Documentation/Doc.*
                    Utilities/Documentation/Documentation.ps1.*

        .EXAMPLE
            Get-PSScriptInfo -File Documentation.ps1 -SourceDirectory C:\Users\joe.smith\repos\canes-cloud -EnabledItems @("Publish-SoftwareRelease.ps1", "Utilities/Documentation/Documentation.ps1.*")
            This example gets the script information from the Documentation.ps1 script, with the following items enabled:
                Publish-SoftwareRelease.ps1
                Utilities/Documentation/Documentation.ps1.*

        .EXAMPLE
            Get-PSScriptInfo -File Publish-SoftwareRelease.ps1 -SourceDirectory C:\Users\joe.smith\repos\canes-cloud
            This example gets the script information from the Publish-SoftwareRelease.ps1 script.


        .Notes
            Version: 0.0
    #>
    param (
        [System.IO.FileInfo]$File,
        [System.IO.DirectoryInfo]$SourceDirectory,
        [string[]]$EnabledItems
    )
    function Get-ScriptPath {
        param (
            [System.IO.FileInfo]$File,
            [System.IO.DirectoryInfo]$SourceDirectory,
            [string]$FunctionName
        )
        $Path = $File.Directory.FullName.Replace($SourceDirectory.FullName.Trim('\'), $null).Replace('\','/').Trim('\/')
        $FullPath = ($Path, $File.Name -join "/").Replace('//', '/')
        if ($FunctionName){
            $Path = $FullPath
            $FullPath = ($FullPath, $FunctionName -join '/').Replace('//', '/')
        }
        return [PSCustomObject]@{
            Path = $Path
            FullPath = $FullPath
        }
    }
    function IsEnabled {
        param (
            [string]$Path,
            [string]$Name,
            [string[]]$EnabledItems
        )
        $fullItemPath = $Path, $Name -join "/"
        switch ($EnabledItems){
            {$fullItemPath -match "^$_$"} {return $true}
        }
        return $false
    }
    $scriptParser = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
    $functionParser = $scriptParser.EndBlock.Statements.Where({$_ -is [System.Management.Automation.Language.FunctionDefinitionAst]})

    $scriptName = $File.Name
    $scriptPath = Get-ScriptPath -File $File -SourceDirectory $SourceDirectory
    $scriptInfo = @{
        Name = $scriptName
        Path = $scriptPath.Path
        FullPath = $scriptPath.FullPath
        Type = 'Script'
        Enabled = IsEnabled -Path $scriptPath.Path -Name $scriptName -EnabledItems $EnabledItems
        File = $File
        SourceDirectory = $SourceDirectory
    }
    $functions = foreach ($func in $functionParser){
        $funcName = $func.Name
        $funcPath = Get-ScriptPath -File $File -SourceDirectory $SourceDirectory -FunctionName $funcName
        [PSCustomObject]@{
            Name = $funcName
            Path = $funcPath.Path
            FullPath = $funcPath.FullPath
            Parent = [PSCustomObject]$scriptInfo
            Type = 'Function'
            Enabled = IsEnabled -Path $funcPath.Path -Name $func.Name -EnabledItems $EnabledItems
            Parser = $func
        }
    }
    $scriptInfo.Functions = $functions
    $script = [PSCustomObject]$scriptInfo

    return $script
}
