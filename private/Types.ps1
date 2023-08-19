enum CommentBasedHelpKeyword {
    SYNOPSIS
    DESCRIPTION
    EXAMPLE
    NOTES
    LINK
    COMPONENT
    FUNCTIONALITY
    ROLE
}
class YAMLCode {
    [string[]] $Code

    [string]ToString(){
        return ($this.Code)
    }
}
class YAMLExample {
    [YAMLCode] $Example 

    [string]ToString(){
        return ($this.Example)
    }
}
class YAMLDescription {
    [string[]] $Text

    [string]ToString(){
        return ($this.Text)
    }
}
class YAMLNavigationLinkUri {
    [string] $Uri

    [string]ToString(){
        return $this.Uri
    }
}
class YAMLNavigationLink {
    [string] $LinkText
    [string] $Uri

    [string]ToString(){
        return (
            if (![string]::IsNullOrEmpty($this.Uri)){
                $this.Uri
            } else {
                $this.LinkText
            }
        )
    }
}
class YAMLRelatedLink {
    [YAMLNavigationLink] $NavigationLink

    [string]ToString(){
        return ($this.NavigationLink)
    }
}
class YAMLAlert {
    [string[]] $Text

    [string]ToString(){
        return ($this.Text)
    }
}
class YAMLAlertSet {
    [YAMLAlert] $Alert

    [string]ToString(){
        return ($this.Alert)
    }
}
class YAMLHelpProperty {
    [CommentBasedHelpKeyword] $Keyword
    [string[]] $Value

    [string]ToString(){
        return ($this.Keyword)
    }
}
class YAMLKeywordInfo {
    [CommentBasedHelpKeyword] $Keyword
    [int] $StartIndex

    [string]ToString(){
        return ($this.Keyword)
    }
}
class YAMLHelpInfo {
    [string] $Name
    [string] $Synopsis
    [YAMLDescription] $Description
    [YAMLExample[]] $Examples
    [YAMLAlertSet[]] $AlertSet
    [YAMLRelatedLink[]] $RelatedLinks
    [string] $Component
    [string] $Functionality
    [string] $Role

    [string]ToString(){
        return ($this.Name)
    }
}
