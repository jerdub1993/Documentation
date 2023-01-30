function New-CmdletDocumentation {
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Cmdlet',
            ValueFromPipeline = $true
        )]    
        [Object[]]$InputObject,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Name'
        )]    
        [string[]]$Name,
        [switch]$LoremIpsum
    )
    Begin {
        foreach ($Obj in $InputObject){
            if ($Obj.GetType() -notin [System.Management.Automation.CmdletInfo],[System.Management.Automation.FunctionInfo]){
                throw [System.Management.Automation.ParameterBindingException] "Cannot process argument transformation on parameter 'InputObject'. Cannot convert the `"$Obj`" value of type `"$($Obj.GetType().Name)`" to type `"CmdletInfo`" or `"FunctionInfo`"."
                exit 1
            }
        }
        if ($Name){
            try {
                $InputObject = Get-Command -Name $Name
            } catch {
                throw [System.Management.Automation.CommandNotFoundException] "Unable to find command '$Name'."
                exit 1
            }
        }
        $Required_Modules = @{
            'Get-LoremIpsum.ps1' = @(
                'Get-LoremIpsum'
            )
            'Get-CommandSyntax.ps1' = @(
                'Get-CommandSyntax'
            )
        }
        foreach ($Mod in $Required_Modules.GetEnumerator()){
            foreach ($indvCommand in $Mod.Value){
                try {
                    Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                } catch {
                    $ScriptPath = "{0}\{1}" -f $pwd.path, $Mod.key
                    try {
                        . $ScriptPath | Out-Null
                        Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                    } catch {
                        throw [System.Management.Automation.CommandNotFoundException] "Unable to find cmdlet '$InputObject'. Make sure the '$($Mod.Key)' module is imported."
                        exit 1
                    }
                }
            }
        }
    }
    Process {
        foreach ($Obj in $InputObject){
            $Help = Get-Help $Obj.Name
            $OutArray = @()
            $OutArray += "# {0}`n" -f $Obj.Name
            $OutArray += if ($LoremIpsum){
                Get-LoremIpsum -Sentences 1
            } else {
                ""
            }
            $OutArray += "## Syntax`n"
            $Syntax = Get-CommandSyntax -Command $Obj
            $spaces = ' ' * 4
            foreach ($set in $Syntax.ParameterSets){
                $OutArray += "{0}{1}" -f $spaces, $Obj.Name
                foreach ($param in $set.Parameters){
                    $OutArray += "{0}{1}" -f ($spaces * 2), $param
                }
                $OutArray += ''
            }
            $OutArray += "## Description`n"
            
            $OutArray += if ($Help.description){
                $Help.description
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 2
            } else {
                ""
            }
            $OutArray += "## Examples`n"
            $exCount = 1
            foreach ($example in $Help.examples.example){
                $OutArray += "### {0}`n" -f $example.title.trim('-').trim() -replace 'Example \d+', ('Example {0}' -f $exCount)
                foreach ($line in ($example.code -split "`n")){
                    $OutArray += "{0}{1}" -f $spaces, $line
                }
                $OutArray += $example.remarks
                $exCount++
            }
            $OutArray += "## Parameters`n"
            foreach ($param in $Help.Parameters.parameter){
                $OutArray += "#### **`-{0}`**`n" -f $param.name
                $OutArray += $param.Description
                $OutArray += ''
                $OutArray += "| Attribute | Value |"
                $OutArray += "| --- | --- |"
                $OutArray += "| Type | {0} |" -f $param.type.name
                $OutArray += "| Position | {0} |" -f $param.position
                $OutArray += "| AcceptPipelineInput | {0} |" -f [System.Convert]::ToBoolean($param.pipelineInput.split()[0])
            }
            $OutArray += "## Inputs`n"
            $inputText = foreach ($inputType in $Help.inputTypes.inputType){
                $Description = $inputType.description
                foreach ($indvType in ($inputType.type.name.split("`n").split(",").trim() | Where-Object {![string]::IsNullOrEmpty($_.trim())})){
                    "#### [**{0}**]()`n" -f $indvType
                    $Description
                }
            }
            $OutArray += if ($inputText.Count -gt 0){
                $inputText
            } else {
                $OutArray += "#### **None**`n"
            }
            $OutArray += "## Outputs"
            $returnValues = foreach ($returnValue in $Help.returnValues.returnValue){
                "#### [**{0}**]()`n" -f $returnValue.type.name
                if ($returnValue.Description){
                    $returnValue.Description
                }
            }
            $OutArray += if ($returnValues.Count -eq 0){
                "#### **None**`n"
            } else {
                $returnValues
            }
            $OutArray += "## Notes`n"
            $OutArray += if ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 3
            } else {
                ""
            }
            $OutArray += "## Related Links`n"
            $URIList = $help.relatedLinks.navigationLink | Where-Object { ![string]::IsNullOrEmpty($_.uri.trim()) }
            if ($URIList.Count -gt 0){
                foreach ($URI in $URIList){
                    $OutArray += "- [{0}]({1})" -f $URI.linkText, $URI.uri
                }
            } else {
                $OutArray += "- [Link 1]()"
            }
            return $OutArray
        }
    }
}