param
(
    [Parameter()]
    [System.String]
    $GlobalAdminUser,

    [Parameter()]
    [System.String]
    $GlobalAdminPassword,

    [Parameter(Mandatory=$true)]
    [System.String]
    $Domain
)

Configuration Master
{
    param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdmin,

        [Parameter(Mandatory=$true)]
        [System.String]
        $Domain
    )

    Import-DscResource -ModuleName Office365DSC

    Node Localhost
    {
        O365User JohnSmith
        {
            UserPrincipalName    = "John.Smith@$Domain"
            DisplayName          = "John Smith"
            FirstName            = "John"
            LastName             = "Smith"
            City                 = "Gatineau"
            Country              = "Canada"
            Office               = "HQ"
            PostalCode           = "5K5 K5K"
            GlobalAdminAccount   = $GlobalAdmin
            Ensure               = "Present"
        }

        TeamsTeam TeamAlpha
        {
            DisplayName          = "Alpha Team"
            AllowAddRemoveApps   = $true
            AllowChannelMentions = $false
            GlobalAdminAccount   = $GlobalAdmin
            Ensure               = "Present"
        }

        TeamsChannel ChannelAlpha1
        {
            DisplayName        = "Channel Alpha"
            Description        = "Test Channel"
            TeamName           = "Alpha Team"
            GlobalAdminAccount = $GlobalAdmin
            Ensure             = "Present"
            DependsON          = "[TeamsTeam]TeamAlpha"
        }

        TeamsUser MemberJohn
        {
            TeamName           = "Alpha Team"
            User               = "John.Smith@$($Domain)"
            GlobalAdminAccount = $GlobalAdmin
            Ensure             = "Present"
            DependsON          = @("[O365User]JohnSmith","[TeamsTeam]TeamAlpha")
        }
    }
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = "Localhost"
            PSDSCAllowPlaintextPassword = $true
        }
    )
}

# Compile and deploy configuration
$password = ConvertTo-SecureString $GlobalAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($GlobalAdminUser, $password)
Master -ConfigurationData $ConfigurationData -GlobalAdmin $credential -Domain $Domain
Start-DscConfiguration Master -Wait -Force -Verbose
