function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Private','Public')]
        [System.String]
        $CdnType,

        [Parameter()]
        [System.Boolean]
        $ExcludeIfNoScriptDisabled = $false,

        [Parameter()]
        [System.String[]]
        $ExcludeRestrictedSiteClassifications,

        [Parameter()]
        [System.String[]]
        $IncludeFileExtensions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Getting configuration for SPOTenantCdnPolicy {$CDNType}"

    Test-MSCloudLogin -CloudCredential $GlobalAdminAccount `
                      -Platform PnP

    $Policies = Get-PnPTenantCdnPolicies -CDNType $CDNType

    return @{
        CDNType                              = $CDNType
        ExcludeIfNoScriptDisabled            = $Policies["ExcludeIfNoScriptDisabled"]
        ExcludeRestrictedSiteClassifications = $Policies["ExcludeRestrictedSiteClassifications"].Split(',')
        IncludeFileExtensions                = $Policies["IncludeFileExtensions"].Split(',')
        GlobalAdminAccount                   = $GlobalAdminAccount
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Private','Public')]
        [System.String]
        $CdnType,

        [Parameter()]
        [System.Boolean]
        $ExcludeIfNoScriptDisabled = $false,

        [Parameter()]
        [System.String[]]
        $ExcludeRestrictedSiteClassifications,

        [Parameter()]
        [System.String[]]
        $IncludeFileExtensions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Setting configuration for SPOTenantCDNPolicy {$CDNType}"

    Test-MSCloudLogin -CloudCredential $GlobalAdminAccount `
                      -Platform PnP

    $curPolicies = Get-TargetResource @PSBoundParameters

    $setParams = @{
        CDNType = $CDNType
    }

    $deltaFound = $false
    if ($null -ne  `
        (Compare-Object -ReferenceObject $curPolicies.IncludeFileExtensions -DifferenceObject $IncludeFileExtensions))
    {
        Write-Verbose "Found difference in IncludeFileExtensions"
        $setParams.Add("IncludeFileExtensions", $IncludeFileExtensions)
        $deltaFound = $true
    }

    if ($null -ne (Compare-Object -ReferenceObject $curPolicies.ExcludeRestrictedSiteClassifications `
                    -DifferenceObject $ExcludeRestrictedSiteClassifications))
    {
        Write-Verbose "Found difference in ExcludeRestrictedSiteClassifications"
        $setParams.Add("ExcludeRestrictedSiteClassifications", $ExcludeRestrictedSiteClassifications)
        $deltaFound = $true
    }

    if ($ExcludeIfNoScriptDisabled -ne $curPolicies["ExcludeIfNoScriptDisabled"])
    {
        Write-Verbose "Found difference in ExcludeIfNoScriptDisabled"
        $setParams.Add("ExcludeIfNoScriptDisabled", $ExcludeIfNoScriptDisabled)
        $deltaFound = $true
    }

    if ($delta)
    {
        Write-Verbose "Proceeding to setting new values"
        Set-PnPTenantCDNPolicy @$setParams
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Private','Public')]
        [System.String]
        $CdnType,

        [Parameter()]
        [System.Boolean]
        $ExcludeIfNoScriptDisabled = $false,

        [Parameter()]
        [System.String[]]
        $ExcludeRestrictedSiteClassifications,

        [Parameter()]
        [System.String[]]
        $IncludeFileExtensions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Testing configuration for SPO Storage Entity for $Key"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-O365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-O365DscHashtableToString -Hashtable $PSBoundParameters)"

    $TestResult = Test-Office365DSCParameterState -CurrentValues $CurrentValues `
                                                  -DesiredValues $PSBoundParameters `
                                                  -ValuesToCheck @("CDNType", `
                                                                   "ExcludeIfNoScriptDisabled", `
                                                                   "ExcludeRestrictedSiteClassifications", `
                                                                   "IncludeFileExtensions")

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    $result = Get-TargetResource @PSBoundParameters
    $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
    $content = "        SPOStorageEntity " + (New-Guid).ToString() + "`r`n"
    $content += "        {`r`n"
    $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
    $content += Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "GlobalAdminAccount"
    $content += "        }`r`n"
    return $content
}

Export-ModuleMember -Function *-TargetResource
