function New-Documentation
{
    <#
        .SYNOPSIS
            Generates documentation for a cmdlet, function, script, or YAML file.
        
        .DESCRIPTION
            New-Documentation generates documentation for a cmdlet, function, script, or YAML file in any of the following formats: Confluence HTML, Confluence Wiki markup, Markdown language. This utilizes PowerShell's comment-based help system to pull help information from an object such as Synopsis, Description, Examples, Parameters, etc.
        
        .PARAMETER Name
            Name of an object for which to generate documentation. Any Name that can be used with `Get-Help`.
        
        .PARAMETER File
            A File from which to generate documentation. This can be a PowerShell script (.ps1) or a YAML file (.yml/.yaml). This parameter accepts pipeline input; see examples.
        
        .PARAMETER Cmdlet
            A Cmdlet from which to generate documentation. Must be a System.Management.Automation.CmdletInfo object. This parameter accepts pipeline input; see examples.
        
        .PARAMETER Function
            A Function from which to generate documentation. Must be a System.Management.Automation.FunctionInfo object. This parameter accepts pipeline input; see examples.
        
        .PARAMETER OutputType
            The format of the returned output. Options are Markdown, ConfluenceWiki, and ConfluenceHtml. Default is Markdown.
        
        .PARAMETER LoremIpsum
            A switch parameter for enabling Lorem Ipsum text. Lorem Ipsum is auto-generated filler text to used to populate the output. This is useful for if the object doesn't already contain the help text (e.g.: Synopsis, Description, etc.), but the user wants to get the general structure of the end result.
        
        .PARAMETER HeadingLevel
            The Heading Level from which to start. All subsequent headings are incremented accordingly. Options are 1, 2, or 3. Default is 1.
        
        .LINK
            https://jerdub1993.github.io/documentation/powershell/new-documentation.html
        
        .LINK
            Confluence Wiki syntax: https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html
        
        .LINK
            Markdown syntax: https://www.markdownguide.org/cheat-sheet/
        
        .LINK
            PowerShell Comment-Based Help: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
        
        .EXAMPLE
            New-Documentation -Name New-Item -OutputType ConfluenceHtml -LoremIpsum
            Generates documentation for New-Item and returns the output in Confluence HTML format. The `-LoremIpsum` switch parameter populates any missing information with filler-text.
        
        .EXAMPLE
            Get-Item MyScript.ps1 | New-Documentation -OutputType Markdown
            Generates documentation for the MyScript.ps1 script and returns the output in Markdown format.
        
        .EXAMPLE
            Get-Item MyPlaybook.yml | New-Documentation -OutputType ConfluenceWiki -HeadingLevel 2
            Generates documentation for the MyPlaybook.yml YAML file and returns the output in Confluence Wiki markup format, with all headings starting at level 2.
        
        .EXAMPLE
            Get-Command Get-Service | New-Documentation -LoremIpsum | Out-File Get-Service.md
            Generates documentation for the Get-Service cmdlet and returns the output in the default format of Markdown. The `-LoremIpsum` switch parameter populates any missing information with filler-text. Outputs the results to the Get-Service.md Markdown file.
        
        .EXAMPLE
            Get-Command MyFunction | New-Documentation -OutputType ConfluenceHtml -HeadingLevel 2
            Generates documentation for the MyFunction function and returns the output in Confluence HTML format, with all headings starting at level 2.
        
        .NOTES
            Version: 0.0
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Name'
    )]
    param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'Name',
            Position = 0
        )]
        [System.String] $Name,
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'File'
        )]
        [System.IO.FileInfo] $File,
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'Cmdlet'
        )]
        [System.Management.Automation.CmdletInfo] $Cmdlet,
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'Function'
        )]
        [System.Management.Automation.FunctionInfo] $Function,
        [ValidateSet(
            'Markdown',
            'ConfluenceWiki',
            'ConfluenceHtml'
        )]
        [string]$OutputType = 'Markdown',
        [switch]$LoremIpsum,
        [ValidateSet(
            1,
            2,
            3
        )]
        [int]$HeadingLevel = 1
    )
    Begin {
        #region Functions
        function Get-Syntax {
            [CmdletBinding()]
            param (
                [System.Object] $Help
            )
            #region Functions
            function Get-ParameterSyntax {
                [CmdletBinding()]
                param (
                    [System.Object]$Parameter,
                    [System.Object]$SyntaxParameter
                )
                Process {
                    $Name = "-{0}" -f $Parameter.Name
                    $Type = $Parameter.Type.Name
                    $Line = if ($Type -imatch 'switch'){
                        $Name
                    } else {
                        $Named = if ($Parameter.Position -inotmatch 'Named'){
                            "[{0}]" -f $Name
                        } else {
                            $Name
                        }
                        "{0} <{1}>" -f $Named, $Type
                    }
                    $Mandatory = if ([Convert]::ToBoolean($Parameter.Required)){
                        $Line
                    } else {
                        "[{0}]" -f $Line
                    }
                    $Mandatory
                }
            }
            function Get-ParameterSetSyntax {
                [CmdletBinding()]
                param (
                    [Parameter(
                        Mandatory = $true,
                        ValueFromPipeline = $true
                    )]
                    [System.Object]$Help
                )
                Process {
                    foreach ($ParameterSet in $Help.syntax.syntaxItem){
                        $Parameters = foreach ($syntaxParameter in $ParameterSet.parameter | Sort-Object -Property Position){
                            $Parameter = $Help.parameters.parameter | Where-Object Name -eq $syntaxParameter.Name
                            Get-ParameterSyntax -Parameter $Parameter -SyntaxParameter $syntaxParameter
                        }
                        if ($Item.CommonParameters){
                            $Parameters += '[<CommonParameters>]'
                        }
                        [PSCustomObject]@{
                            ParameterSet = $Parameters
                        }
                    }
                }
            }
            #endregion Functions
            return [PSCustomObject]@{
                Command = $Help.Name
                ParameterSets = Get-ParameterSetSyntax -Help $Help
            }
        }
        function Get-TypeUri {
            [CmdletBinding()]
            param (
                [System.Reflection.TypeInfo]$Type
            )
            return "https://learn.microsoft.com/en-us/dotnet/api/{0}" -f $Type.FullName.TrimEnd('[]')
        }
        function Split-Link {
            [CmdletBinding()]
            param (
                [string]$Text
            )
            $Split = $Text -split ': '
            if ($Text -match '^.*: https?:\/\/(.+\.)+\w+\/?[^\s\t\n\r]*$' -and [System.Uri]::IsWellFormedUriString($Split[1], [System.UriKind]::Absolute)) {
                return [PSCustomObject]@{
                    Label   = $Split[0].TrimEnd(':')
                    Uri     = $Split[1]
                }
            }
        }
        function Get-Header {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [int]$HeadingLevel,
                [int]$Increment = 0
            )
            $Level = $HeadingLevel + $Increment
            $Return = switch ($OutputType){
                Markdown        {
                    "{0}" -f '#' * $Level
                }
                ConfluenceWiki  {
                    "h{0}." -f $Level
                }
                ConfluenceHtml  {
                    "h{0}" -f $Level
                }
            }
            return $Return
        }
        function Get-Assemblies {
            $Hash = @{}
            [System.AppDomain]::CurrentDomain.GetAssemblies() |
                ForEach-Object {
                    try {
                        $_.GetExportedTypes()
                    } catch {}
                } |
                ForEach-Object {
                    $Hash[$_.FullName] = $_.FullName
                    $Hash[$_.Name] = $_.FullName
                }
            return $Hash.Clone()
        }
        function Get-Types {
            [CmdletBinding()]
            param (
                [System.Collections.Hashtable]$Assemblies,
                [System.Object]$Help
            )
            function Get-InputTypes {
                [CmdletBinding()]
                param (
                    [System.Collections.Hashtable]$Assemblies,
                    [System.Object]$Help
                )
                $AllAssemblies = foreach ($typeString in (
                        @(
                            (
                                (
                                    $Help.inputTypes.inputType.type.name -split "`n" |
                                        Where-Object {
                                            ![string]::IsNullOrEmpty($_.Trim())
                                        }
                                )
                            ),
                            $Help.parameters.parameter.type.name
                        ) |
                            ForEach-Object {
                                $_
                            } |
                                Select-Object -Unique
                    )
                ){
                    $typeStringTrim = $typeString.Trim()
                    $AssemblyFullName = if ($typeStringTrim -match '\[\]$'){
                        "{0}[]" -f $Assemblies[$typeStringTrim.TrimEnd('[]')]
                    } else {
                        $Assemblies[$typeStringTrim]
                    }
                    [type]$AssemblyFullName
                }
                return $AllAssemblies | Select-Object -Unique
            }
            function Get-OutputTypes {
                [CmdletBinding()]
                param (
                    [System.Object[]]$Assemblies,
                    [System.Object]$Help
                )
                $AllAssemblies = foreach ($typeString in $Help.returnValues.returnValue.type.name | Select-Object -Unique){
                    $typeStringTrim = $typeString.Trim()
                    $AssemblyFullName = if ($typeStringTrim -match '\[\]$'){
                        "{0}[]" -f $Assemblies[$typeStringTrim.TrimEnd('[]')]
                    } else {
                        $Assemblies[$typeStringTrim]
                    }
                    [type]$AssemblyFullName
                }
                return $AllAssemblies | Select-Object -Unique
            }
            $TypesParams = @{
                Assemblies = $Assemblies
                Help = $Help
            }
            return [PSCustomObject]@{
                Inputs = Get-InputTypes @TypesParams
                Outputs = Get-OutputTypes @TypesParams
            }
        }
        #region Sections
        function Get-HeaderSection {
            [CmdletBinding()]
            param (
                [string]$Name,
                [string]$OutputType,
                [int]$HeadingLevel
            )
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 0
            }
            $Return = switch ($OutputType){
                Markdown        {
                    $Header = Get-Header @HeaderParams -OutputType $_
                    "{0} {1}" -f $Header, $Name
                }
                ConfluenceWiki  {
                    $Header = Get-Header @HeaderParams -OutputType $_
                    "{0} {1}" -f $Header, $Name
                }
                ConfluenceHtml  {
                    $Header = Get-Header @HeaderParams -OutputType $_
                    "<{0}>{1}</{0}>" -f $Header, $Name
                }
            }
            return $Return
        }
        function Get-SyntaxSection {
            [CmdletBinding()]
            param (
                [string]$Name,
                [string]$OutputType,
                [int]$HeadingLevel,
                [string]$Language,
                [System.Object]$Help
            )
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $Syntax = Get-Syntax -Help $Help
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Syntax" -f (Get-Header @HeaderParams -OutputType $_)
                    foreach ($ParameterSet in $Syntax.ParameterSets){
                        '```{0}' -f $Language
                        $Name
                        foreach ($Parameter in $ParameterSet.ParameterSet){
                            "    {0}" -f $Parameter
                        }
                        '```'
                    }
                }
                ConfluenceWiki  {
                    "{0} Syntax" -f (Get-Header @HeaderParams -OutputType $_)
                    foreach ($ParameterSet in $Syntax.ParameterSets){
                        '{0}code:language={1}{2}' -f '{', $Language, '}'
                        $Name
                        foreach ($Parameter in $ParameterSet.ParameterSet){
                            "    {0}" -f $Parameter
                        }
                        '{code}'
                    }
                }
                ConfluenceHtml  {
                    "<{0}>Syntax</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    foreach ($ParameterSet in $Syntax.ParameterSets){
                        '<ac:structured-macro ac:macro-id="{0}" ac:name="code" ac:schema-version="1">' -f [System.Guid]::NewGuid().Guid
                        '<ac:parameter ac:name="language">{0}</ac:parameter>' -f $Language
                        '<ac:plain-text-body><![CDATA[{0}' -f $Name
                        foreach ($Parameter in $ParameterSet.ParameterSet){
                            "    {0}" -f $Parameter
                        }
                        ']]></ac:plain-text-body>'
                        '</ac:structured-macro>'
                    }
                }
            }
            return $Return
        }
        function Get-DescriptionSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [System.Object]$Help
            )
            $Description = if (![string]::IsNullOrEmpty($Help.Description.Text)){
                $Help.Description.Text
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 2
            }
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Description" -f (Get-Header @HeaderParams -OutputType $_)
                    $Description -join "`n`n"
                }
                ConfluenceWiki  {
                    "{0} Description" -f (Get-Header @HeaderParams -OutputType $_)
                    $Description
                }
                ConfluenceHtml  {
                    "<{0}>Description</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    if ($Description){
                        $DescriptionLines = foreach ($line in $Description.Split("`n")){
                            [System.Web.HttpUtility]::HtmlEncode($line)
                        }
                        "<p>{0}</p>" -f ($DescriptionLines -join "<br/>")
                    }

                }
            }
            return $Return
        }
        function Get-ExamplesSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [string]$Language,
                [System.Object]$Help
            )
            function Get-CodeText {
                [CmdletBinding()]
                param (
                    [System.Object]$Example
                )
                $CodeText = @(
                    $Example.Code
                )
                if ($Example.Remarks){
                    $int = 0
                    $remarksSplit = $Example.Remarks.Text[0] -split "`n"
                    while ($remarksSplit[$int].Trim() -match '`$' -and $int -lt $remarksSplit.Count){
                        $CodeText += $remarksSplit[$int]
                        $int++
                    }
                }
                return $CodeText
            }
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $ExampleCount = 1
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Examples" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($Example in $Help.Examples.Example){
                        "{0} Example {1}" -f (Get-Header @HeaderParams -OutputType $_), $ExampleCount
                        '```{0}' -f $Language
                        Get-CodeText -Example $Example
                        '```'
                        if (![string]::IsNullOrEmpty($Example.Remarks.Text)){
                            $Example.Remarks.Text[0]
                        } elseif ($LoremIpsum){
                            Get-LoremIpsum -Sentences 1
                        }
                        $ExampleCount++
                    }
                }
                ConfluenceWiki  {
                    "{0} Examples" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($Example in $Help.Examples.Example){
                        "{0} Example {1}" -f (Get-Header @HeaderParams -OutputType $_), $ExampleCount
                        '{0}code:language={1}{2}' -f '{', $Language, '}'
                        Get-CodeText -Example $Example
                        '{code}'
                        if (![string]::IsNullOrEmpty($Example.Remarks.Text)){
                            $Example.Remarks.Text[0]
                        } elseif ($LoremIpsum){
                            Get-LoremIpsum -Sentences 1
                        }
                        $ExampleCount++
                    }
                }
                ConfluenceHtml  {
                    "<{0}>Examples</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($Example in $Help.Examples.Example){
                        "<{0}>Example {1}</{0}>" -f (Get-Header @HeaderParams -OutputType $_), $ExampleCount
                        '<ac:structured-macro ac:macro-id="{0}" ac:name="code" ac:schema-version="1">' -f [System.Guid]::NewGuid().Guid
                        '<ac:parameter ac:name="language">{0}</ac:parameter>' -f $Language
                        '<ac:plain-text-body><![CDATA[{0}]]></ac:plain-text-body>' -f (Get-CodeText -Example $Example)
                        '</ac:structured-macro>'
                        try {
                            '<p>{0}</p>' -f ($Example.Remarks[0].Split("`n") -join "<br/>")
                        } catch {}
                        $ExampleCount++
                    }
                }
            }
            return $Return
        }
        function Get-ParametersSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [System.Object]$Help
            )
            function New-ParameterTable {
                [CmdletBinding()]
                param (
                    [string]$OutputType,
                    [System.Object[]]$Parameter
                )
                Process {
                    foreach ($Param in $Parameter){
                        $DefaultValue = if ($Param.DefaultValue){
                            $Param.DefaultValue
                        } else {
                            'None'
                        }
                        $AcceptPipelineInput = [Convert]::ToBoolean($Param.PipelineInput.Split()[0])
                        $Table = switch ($OutputType){
                            Markdown        {
                                '| Attribute | Value |'
                                '| --- | --- |'
                                '| Type | {0} |' -f $Param.Type.Name
                                if ($Param.Aliases){
                                    '| Aliases | {0} |' -f $Param.Aliases
                                }
                                '| Position | {0} |' -f $Param.Position
                                '| Default value | {0} |' -f $DefaultValue
                                '| Accept pipeline input | {0} |' -f $AcceptPipelineInput
                            }
                            ConfluenceWiki  {
                                '|Type|{0}|' -f $Param.Type.Name
                                if ($Param.Aliases){
                                    '|Aliases|{0}|' -f $Param.Aliases
                                }
                                '|Position|{0}|' -f $Param.Position
                                '|Default value|{0}|' -f $DefaultValue
                                '|Accept pipeline input|{0}|' -f $AcceptPipelineInput
                            }
                            ConfluenceHtml  {
                                '<table class="wrapped"><tbody>'
                                '<tr><td><p>Type:</p></td><td><p>{0}</p></td></tr>' -f $Param.Type.Name
                                if ($Param.Aliases){
                                    '<tr><td><p>Aliases:</p></td><td><p>{0}</p></td></tr>' -f $Param.Aliases
                                }
                                '<tr><td><p>Position:</p></td><td><p>{0}</p></td></tr>' -f $Param.Position
                                '<tr><td><p>Default value:</p></td><td><p>{0}</p></td></tr>' -f $DefaultValue
                                '<tr><td><p>Accept Pipeline Input:</p></td><td><p>{0}</p></td></tr>' -f $AcceptPipelineInput
                                '</tbody></table>'
                            }
                        }
                        $Table
                    }
                }
            }
            function New-Parameter {
                [CmdletBinding()]
                param (
                    [string]$OutputType,
                    [System.Object[]]$Parameter
                )
            }
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Parameters" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($IndividualParameter in $Help.Parameters.Parameter | Sort-Object Position){
                        '{0} **-{1}**' -f (Get-Header @HeaderParams -OutputType $_), $IndividualParameter.Name
                        $ParameterText = if (![string]::IsNullOrEmpty($IndividualParameter.Description.Text)){
                            $IndividualParameter.Description.Text
                        } elseif ($LoremIpsum){
                            Get-LoremIpsum -Sentences 2
                        }
                        if ($ParameterText){
                            "{0}{1}`n`n" -f ('&ensp;' * 4), $ParameterText
                        }
                        New-ParameterTable -OutputType $_ -Parameter $IndividualParameter
                    }
                }
                ConfluenceWiki  {
                    "{0} Parameters" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($IndividualParameter in $Help.Parameters.Parameter | Sort-Object Position){
                        '{0} *{2}{2}-{1}{3}{3}*' -f (Get-Header @HeaderParams -OutputType $_), $IndividualParameter.Name, '{', '}'
                        $ParameterText = if (![string]::IsNullOrEmpty($IndividualParameter.Description.Text)){
                            $IndividualParameter.Description.Text
                        } elseif ($LoremIpsum){
                            Get-LoremIpsum -Sentences 2
                        }
                        if ($ParameterText){
                            "{0}{1}`n" -f ('&ensp;' * 4), $ParameterText
                        }
                        New-ParameterTable -OutputType $_ -Parameter $IndividualParameter
                    }
                }
                ConfluenceHtml  {
                    "<{0}>Parameters</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    $HeaderParams.Increment++
                    foreach ($IndividualParameter in $Help.Parameters.Parameter | Sort-Object Position){
                        '<{0}><strong><code>-{1}</code></strong></{0}>' -f (Get-Header @HeaderParams -OutputType $_), $IndividualParameter.Name
                        $ParameterText = if (![string]::IsNullOrEmpty($IndividualParameter.Description.Text)){
                            $IndividualParameter.Description.Text
                        } elseif ($LoremIpsum){
                            Get-LoremIpsum -Sentences 2
                        }
                        if ($ParameterText){
                            '<p>{0}{1}</p><br/>' -f ('&ensp;' * 4), $ParameterText
                        }
                        New-ParameterTable -OutputType $_ -Parameter $IndividualParameter
                    }
                }
            }
            return $Return
        }
        function Get-InputsOutputsSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [int]$HeadingLevel,
                [System.Reflection.TypeInfo[]]$Types,
                [ValidateSet(
                    'Inputs',
                    'Outputs'
                )]
                [string]$SectionType
            )
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} {1}" -f (Get-Header @HeaderParams -OutputType $_), $SectionType
                    $HeaderParams.Increment += 2
                    $Header = Get-Header @HeaderParams -OutputType $_
                    foreach ($Type in $Types){
                        "{0} [**{1}**]({2})" -f $Header, $Type.Name, (Get-TypeUri -Type $Type)
                    }
                    if (!$Types){
                        "{0} **None**" -f $Header
                    }
                }
                ConfluenceWiki  {
                    "{0} {1}" -f (Get-Header @HeaderParams -OutputType $_), $SectionType
                    $HeaderParams.Increment += 2
                    $Header = Get-Header @HeaderParams -OutputType $_
                    foreach ($Type in $Types){
                        "{0} [*{1}*|{2}]" -f $Header, $Type.Name, (Get-TypeUri -Type $Type)
                    }
                    if (!$Types){
                        "{0} *None*" -f $Header
                    }
                }
                ConfluenceHtml  {
                    "<{0}>{1}</{0}>" -f (Get-Header @HeaderParams -OutputType $_), $SectionType
                    $HeaderParams.Increment += 2
                    $Header = Get-Header @HeaderParams -OutputType $_
                    foreach ($Type in $Types){
                        '<{0}><a href="{2}"><strong>{1}</strong></a></{0}>' -f $Header, $Type.Name, (Get-TypeUri -Type $Type)
                    }
                    if (!$Types){
                        "<{0}><strong>None</strong></{0}>" -f $Header
                    }
                }
            }
            return $Return
        }
        function Get-InputsSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [int]$HeadingLevel,
                [System.Reflection.TypeInfo[]]$InputTypes
            )
            $Params = @{
                OutputType = $OutputType
                HeadingLevel = $HeadingLevel
                Types = $InputTypes
                SectionType = 'Inputs'
            }
            return Get-InputsOutputsSection @Params
        }
        function Get-OutputsSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [int]$HeadingLevel,
                [System.Reflection.TypeInfo[]]$OutputTypes
            )
            $Params = @{
                OutputType = $OutputType
                HeadingLevel = $HeadingLevel
                Types = $OutputTypes
                SectionType = 'Outputs'
            }
            return Get-InputsOutputsSection @Params
        }
        function Get-NotesSection {
            [CmdletBinding()]
            param (
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [System.Object]$Help
            )
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $AlertText = $Help.alertSet.alert.text -split "`n"
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Notes" -f (Get-Header @HeaderParams -OutputType $_)
                    if ($AlertText){
                        $Notes = foreach ($line in $AlertText){
                            switch -Regex ($line){
                                '^(-|=)+$'  {
                                    "\$line"
                                }
                                '^\s{4}'    {
                                    $line.TrimStart()
                                }
                                Default     {
                                    $line
                                }
                            }
                        }
                        $Notes -join "`n`n"
                    } elseif ($LoremIpsum) {
                        Get-LoremIpsum -Paragraphs 3
                    }
                }
                ConfluenceWiki  {
                    "{0} Notes" -f (Get-Header @HeaderParams -OutputType $_)
                    if ($AlertText){
                        $AlertText
                    } elseif ($LoremIpsum) {
                        Get-LoremIpsum -Paragraphs 3
                    }
                }
                ConfluenceHtml  {
                    "<{0}>Notes</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    if ($AlertText){
                        $Notes = foreach ($line in $AlertText){
                            [System.Web.HttpUtility]::HtmlEncode($line)
                        }
                        $Notes -join "<br/>"
                    } elseif ($LoremIpsum) {
                        Get-LoremIpsum -Paragraphs 3
                    }
                }
            }
            return $Return
        }
        function Get-RelatedLinksSection {
            [CmdletBinding()]
            param (
                [string]$Name,
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [System.Object]$Help
            )
            function Get-RelatedLinks {
                param (
                    [string]$Name,
                    [string]$OutputType,
                    [System.Object[]]$NavigationLinks
                )
                $first = $true
                foreach ($navigationLink in $NavigationLinks){
                    $Link = if ($navigationLink.Uri -and $navigationLink.linkText){
                        $labelText = $navigationLink.linkText.Trim()
                        if ($labelText -notmatch ':$'){
                            $labelText = "{0}:" -f $labelText
                        }
                        $labelText, $navigationLink.Uri -join ' '
                    } else {
                        $navigationLink.Uri, $navigationLink.linkText | Where-Object {![string]::IsNullOrEmpty($_)}
                    }
                    if ($Link -match 'https?:\/\/(.+\.)+\w+\/?[^\s\t\n\r]*'){
                        $splitLink = Split-Link -Text $Link
                        $LinkObject = if ($splitLink){
                            @{
                                Label = $splitLink.Label
                                Uri = $splitLink.Uri
                            }
                        } elseif ([System.Uri]::IsWellFormedUriString($Link, [System.UriKind]::Absolute)) {
                            @{
                                Label = if ($first){
                                    $Name
                                } else {
                                    $Link
                                }
                                Uri = $Link
                            }
                            $first = $false
                        }
                        switch ($OutputType){
                            Markdown        {
                                '- [{0}]({1})' -f $LinkObject['Label'], $LinkObject['Uri']
                            }
                            ConfluenceWiki  {
                                '* [{0}|{1}]' -f $LinkObject['Label'], $LinkObject['Uri']
                            }
                            ConfluenceHtml  {
                                '<li><a href="{1}">{0}</a></li>' -f [System.Web.HttpUtility]::HtmlEncode($LinkObject['Label']), [System.Web.HttpUtility]::HtmlEncode($LinkObject['Uri'])
                            }
                        }
                    } else {
                        switch ($OutputType){
                            Markdown        {
                                '- {0}' -f $Link
                            }
                            ConfluenceWiki  {
                                '* {0}' -f $Link
                            }
                            ConfluenceHtml  {
                                '<li>{0}</li>' -f [System.Web.HttpUtility]::HtmlEncode($Link)
                            }
                        }
                    }
                }
            }
            $HeaderParams = @{
                HeadingLevel = $HeadingLevel
                Increment = 1
            }
            $Links = Get-RelatedLinks -Name $Name -OutputType $OutputType -NavigationLinks $Help.relatedLinks.navigationLink
            $Return = switch ($OutputType){
                Markdown        {
                    "{0} Related Links" -f (Get-Header @HeaderParams -OutputType $_)
                    $Links
                }
                ConfluenceWiki  {
                    "{0} Related Links" -f (Get-Header @HeaderParams -OutputType $_)
                    $Links
                }
                ConfluenceHtml  {
                    "<{0}>Related Links</{0}>" -f (Get-Header @HeaderParams -OutputType $_)
                    "<ul>{0}</ul>" -f ($Links -join "`n")
                }
            }
            return $Return
        }
        function Get-AllSection {
            [CmdletBinding()]
            param (
                [System.String]$Name,
                [string]$OutputType,
                [switch]$LoremIpsum,
                [int]$HeadingLevel,
                [System.Object]$Help
            )
            Begin {
                #region Functions
                function Get-YAMLDocumentation {
                    [CmdletBinding()]
                    param (
                        [System.String]$Name,
                        [string]$OutputType,
                        [switch]$LoremIpsum,
                        [int]$HeadingLevel,
                        [System.Object]$Help
                    )
                    $PSDefaultParameterValues['Get-*Section:Language'] = 'yaml'
                    return  @(
                        (
                            Get-HeaderSection
                        ),
                        (
                            Get-DescriptionSection
                        ),
                        (
                            Get-ExamplesSection
                        ),
                        (
                            Get-NotesSection
                        ),
                        (
                            Get-RelatedLinksSection
                        )
                    )
                    #return $DocumentationArray

                }
                function Get-PowerShellDocumentation {
                    [CmdletBinding()]
                    param (
                        [System.String]$Name,
                        [string]$OutputType,
                        [switch]$LoremIpsum,
                        [int]$HeadingLevel,
                        [System.Object]$Help
                    )
                    $PSDefaultParameterValues['Get-*Section:Language'] = 'powershell'
                    $Types = Get-Types -Assemblies (Get-Assemblies) -Help $Help
                    return @(
                        (
                            Get-HeaderSection
                        ),
                        (
                            Get-SyntaxSection
                        ),
                        (
                            Get-DescriptionSection
                        ),
                        (
                            Get-ExamplesSection
                        ),
                        (
                            Get-ParametersSection
                        ),
                        (
                            Get-InputsSection -InputTypes $Types.Inputs
                        ),
                        (
                            Get-OutputsSection -OutputTypes $Types.Outputs
                        ),
                        (
                            Get-NotesSection
                        ),
                        (
                            Get-RelatedLinksSection
                        )
                    )
                    #return $DocumentationArray
                }
                #endregion Functions
                $Params = @{
                    Name = $Name
                    OutputType = $OutputType
                    LoremIpsum = $LoremIpsum
                    HeadingLevel = $HeadingLevel
                    Help = $Help
                }
            }
            Process {
                if ($Help -is [YAMLHelpInfo]){
                    Get-YAMLDocumentation @Params
                } else {
                    Get-PowerShellDocumentation @Params
                }
            }
        }
        #endregion Sections
        #endregion Functions
    }
    Process {
        $Help = switch ($PSCmdlet.ParameterSetName) {
            Name        {
                Get-Help -Name $Name
            }
            File        {
                $Name = $File.Name
                if ($File.Extension -match '^\.ya?ml$'){
                    Get-YAMLHelp -Path $File
                } else {
                    Get-Help -Name $File
                }
            }
            Cmdlet      {
                $Name = $Cmdlet.Name
                Get-Help -Name $Cmdlet
            }
            Function    {
                $Name = $Function.Name
                Get-Help -Name $Function
            }
        }
        $ParameterValues = @{
            'Get-*Section:Name'          = $Name
            'Get-*Section:OutputType'    = $OutputType
            'Get-*Section:LoremIpsum'    = $LoremIpsum
            'Get-*Section:HeadingLevel'  = $HeadingLevel
            'Get-*Section:Help'          = $Help
            'Get-*Section:Language'      = $null
        }
        foreach ($Value in $ParameterValues.GetEnumerator()){
            $PSDefaultParameterValues[$Value.Key] = $Value.Value
        }
        return Get-AllSection
    }
    End {
        foreach ($Value in $ParameterValues.GetEnumerator()){
            $PSDefaultParameterValues.Remove($Value.Key)
        }
    }
}