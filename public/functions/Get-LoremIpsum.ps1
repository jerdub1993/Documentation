function Get-LoremIpsum
{
    <#
        .SYNOPSIS
            Generates randomized filler-text.
        
        .DESCRIPTION
            Lorem ipsum is a placeholder text commonly used to demonstrate the visual form of a document without relying on meaningful content. This cmdlet generates the filler text in varying amounts--words, sentences, or paragraphs.
        
        .PARAMETER Paragraphs
            Number of paragraphs to generate.
        
        .PARAMETER Sentences
            Number of sentences to generate.
        
        .PARAMETER Words
            Number of words to generate.
        
        .EXAMPLE
            Get-LoremIpsum
            Generates filler text. The default is 1 paragraph of 2 to 6 sentences.
        
        .EXAMPLE
            Get-LoremIpsum -Sentences 3
            Generates 3 sentences of filler text.
        
        .EXAMPLE
            Get-LoremIpsum -Paragraphs 2
            Generates 2 paragraphs of filler text.
        
        .EXAMPLE
            Get-LoremIpsum -Words 10
            Generates 10 words of filler text.
        
        .NOTES
            Version: 0.0
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Paragraphs'
    )]
    param (
        [Parameter(
            ParameterSetName = 'Paragraphs'
        )]
        [int]$Paragraphs = 1,
        [Parameter(
            ParameterSetName = 'Sentences'
        )]
        [int]$Sentences = 1,
        [Parameter(
            ParameterSetName = 'Words'
        )]
        [int]$Words = 1
    )
    function Get-LIWord {
        [CmdletBinding()]
        param (
            [int]$Length = $(Get-Random -Minimum 1 -Maximum 10),
            [ValidateSet(
                'Upper',
                'Title',
                'Lower'
            )]
            [string]$Case = $(if ((Get-Random 10) -eq 1){'Title'}else{'Lower'})
        )
        $alphabet = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
        $LetterStr = (Get-Random -InputObject $alphabet -Count $Length) -join ''
        $LetterStrCase = switch ($Case){
            Upper   {
                $LetterStr.ToUpper()
            }
            Title   {
                (Get-Culture).TextInfo.ToTitleCase($LetterStr)
            }
            Lower   {
                $LetterStr.ToLower()
            }
        }
        return $LetterStrCase
    }
    function Get-LISentence {
        [CmdletBinding()]
        param (
            [int]$Length = $(Get-Random -Minimum 4 -Maximum 22)
        )
        $WordArr = for ($i = 1 ; $i -le $Length ; $i++){
            if ($i -eq 1){
                Get-LIWord -Case Title
            } else {
                Get-LIWord
            }
        }
        return "{0}." -f ($WordArr -join ' ')
    }
    function Get-LIParagraph {
        [CmdletBinding()]
        param (
            [int]$Length = $(Get-Random -Minimum 2 -Maximum 6)
        )
        $SentenceArr = for ($i = 1 ; $i -le $Length ; $i++){
            Get-LISentence
        }
        return $SentenceArr -join ' '
    }
    switch ($PSCmdlet.ParameterSetName){
        Paragraphs  {
            $ParArray = for ($i = 1 ; $i -le $Paragraphs ; $i++){
                Get-LIParagraph
            }
            return $ParArray -join "`n`n"
        }
        Sentences   {
            $SenArray = for ($i = 1 ; $i -le $Sentences ; $i++){
                Get-LISentence
            }
            return $SenArray -join ' '
        }
        Words       {
            $WordArray = for ($i = 1 ; $i -le $Words ; $i++){
                Get-LIWord
            }
            return $WordArray -join ' '
        }
    }
}