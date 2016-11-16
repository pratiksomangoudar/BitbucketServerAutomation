
function Get-BBServerRepository
{
    <#
    .SYNOPSIS
    Gets Bitbucket Server repositories.

    .DESCRIPTION
    The `Get-BBServerRepository` function gets Bitbucket Server repositories. Only the repositories under a specific project are returned. Pass the project's key/ID whose repositories to get with the `ProjectKey` parameter. 

    Use the `New-BBServerConnection` function to create a connection object that is passed to the `Connection` parameter.

    The returned objects have the following properties:

     * `slug`: The repository's public key/ID. Use this value when a Bitbucket Server Automation function has a `RepositorySlug` parameter.
     * `id`: Bitbucket Server's internal, numeric ID for the repository.
     * `name`
     * `scmId`: the repository's source code management system. Bitbucket Server only supports Git.
     * `state`
     * `statusMessage`
     * `forkable`: a flag that indicates if the repository supports forking
     * `project`: a project object for the repository's project
     * `public`: a flag indicating if the repository is public or not
     * `links`: an object with two properties: `clone` an array of URLs you can use to clone; and `self` an HTTP URL for viewing the repository in a web browser

    .EXAMPLE
    Get-BBServerRepository -Connection $conn -ProjectKey 'WHS'

    Demonstrates how to get all the repositories under the `WHS` project.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection information that describe what Bitbucket Server instance to connect to, what credentials to use, etc. Use the `New-BBServerConnection` function to create a connection object.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,

        [string]
        # The name of a specific repository to get.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    
    $resourcePath = 'projects/{0}/repos' -f $ProjectKey
    $findWithWildcard = $false
    if( $Name )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name) )
        {
            $findWithWildcard = $true
        }
        else
        {
            $resourcePath = '{0}/{1}' -f $resourcePath,$Name
        }
    }

    $result = $null
    #try
    #{
    $result = Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath ('{0}?limit={1}' -f $resourcePath,[int16]::MaxValue) -ErrorVariable 'errors'
    if( -not $result )
    {
        return
    }
    <#}
    catch [Net.WebException]
    {
        $ex = $_.Exception
        if( $ex.Response.StatusCode -ne [Net.HttpStatusCode]::NotFound )
        {
            throw
        }

        for( $idx = 0; $idx -lt $errors.Count; ++$idx )
        {
            if( $Global:Error.Count -gt 0 )
            {
                $Global:Error.RemoveAt(0)
            }
        }
        
        Write-Error -Message ('[{0}] [{1}] Repository ''{2}'' does not exist.' -f $Connection.Uri,$ProjectKey,$Name)
        return
    }
    #>

    
    if( ($result | Get-Member -Name 'values') )
    {
        if( $findWithWildcard )
        {
            $result = $result.values | Where-Object { return $_.Name -like $Name }
        }
        else
        {
            $result = $result.values
        }
    }

    $result | ForEach-Object {
                                    $_.pstypenames.Add('Atlassian.Bitbucket.Server.RepositoryInfo')
                                    $_
                             }
}