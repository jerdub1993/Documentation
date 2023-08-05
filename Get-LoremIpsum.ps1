function Get-LoremIpsum {
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
        param (
            [int]$Length = $(Get-Random -Minimum 1 -Maximum 10),
            [ValidateSet(
                'Upper',
                'Title',
                'Lower'
            )]
            [string]$Case = $(if ((Get-Random 10) -eq 1){'Title'}else{'Lower'})
        )
        $alphabet = @('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z')
        $LetterArr = foreach ($letter in 1..$Length){
            Get-Random $alphabet
        }
        $LetterStr = $LetterArr -join ''
        $LetterStr = switch ($Case){
            Upper   {
                $LetterStr.ToUpper()
            }
            Title   {
                $LetterStr.Substring(0,1).ToUpper() + $LetterStr.Substring(1).ToLower()
            }
            Lower   {
                $LetterStr
            }
        }
        return $LetterStr
    }
    function Get-LISentence {
        param (
            [int]$Length = $(Get-Random -Minimum 4 -Maximum 22),
            [switch]$Formatted
        )
        $WordArr = @(
            Get-LIWord -Case Title
        )
        foreach ($word in 2..$Length){
            $WordArr += Get-LIWord
        }
        return "{0}." -f ($WordArr -join ' ')
    }
    function Get-LIParagraph {
        param (
            [int]$Length = $(Get-Random -Minimum 2 -Maximum 6)
        )
        $SentenceArr = foreach ($sentence in 1..$Length){
            Get-LISentence
        }
        return $SentenceArr -join ' '
    }
    switch ($PSCmdlet.ParameterSetName){
        Paragraphs  {
            $ParArray = foreach ($Par in 1..$Paragraphs){
                Get-LIParagraph
            }
            return $ParArray -join "`n`n"
        }
        Sentences   {
            $SenArray = foreach ($Sen in 1..$Sentences){
                Get-LISentence
            }
            return $SenArray -join ' '
        }
        Words       {
            $WordArray = foreach ($Word in 1..$Words){
                Get-LIWord
            }
            return $WordArray -join ' '
        }
    }
}