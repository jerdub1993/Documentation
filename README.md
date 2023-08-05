# CmdletDocumentation
For automating making Cmdlet Documentation in Markdown from PowerShell's [comment-based help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help). The better the comment-based help on the command/function, the better the documentation. Use the `-LoremIpsum` parameter of `New-CmdletDocumentation` to populate the documentation with random filler text.

Everything below was drafted using the following command:

    Get-Command -Name New-CmdletDocumentation, Get-LoremIpsum, Get-CommandSyntax | New-CmdletDocumentation | Out-File -FilePath $Path

# New-CmdletDocumentation


## Syntax

    New-CmdletDocumentation
        [-LoremIpsum]
        -InputObject <Object[]>

    New-CmdletDocumentation
        [-LoremIpsum]
        -Name <String[]>

## Description


## Examples

## Parameters

#### **-InputObject**


| Attribute | Value |
| --- | --- |
| Type | Object[] |
| Position | Named |
| AcceptPipelineInput | True |
#### **-LoremIpsum**


| Attribute | Value |
| --- | --- |
| Type | switch |
| Position | Named |
| AcceptPipelineInput | False |
#### **-Name**


| Attribute | Value |
| --- | --- |
| Type | string[] |
| Position | Named |
| AcceptPipelineInput | False |
## Inputs

#### [**System.Object[]**]()

## Outputs
#### [**System.Object**]()

## Notes


## Related Links

- [Link 1]()
# Get-LoremIpsum


## Syntax

    Get-LoremIpsum
        [-Paragraphs <Int32>]

    Get-LoremIpsum
        [-Sentences <Int32>]

    Get-LoremIpsum
        [-Words <Int32>]

## Description


## Examples

## Parameters

#### **-Paragraphs**


| Attribute | Value |
| --- | --- |
| Type | int |
| Position | Named |
| AcceptPipelineInput | False |
#### **-Sentences**


| Attribute | Value |
| --- | --- |
| Type | int |
| Position | Named |
| AcceptPipelineInput | False |
#### **-Words**


| Attribute | Value |
| --- | --- |
| Type | int |
| Position | Named |
| AcceptPipelineInput | False |
## Inputs

#### [**None**]()

## Outputs
#### [**System.Object**]()

## Notes


## Related Links

- [Link 1]()
# Get-CommandSyntax


## Syntax

    Get-CommandSyntax
        -CommandName <String>

    Get-CommandSyntax
        -Command <Object>

## Description


## Examples

## Parameters

#### **-Command**


| Attribute | Value |
| --- | --- |
| Type | Object |
| Position | Named |
| AcceptPipelineInput | True |
#### **-CommandName**


| Attribute | Value |
| --- | --- |
| Type | string |
| Position | Named |
| AcceptPipelineInput | True |
## Inputs

#### [**System.String**]()

#### [**System.Object**]()

## Outputs
#### [**System.Object**]()

## Notes


## Related Links

- [Link 1]()
