#
# Module manifest
#
@{
    GUID              = 'c1720150-5512-4622-886a-79f08ada55d8'
    ModuleVersion     = '1.3'
    Description       = '🍣 flows through the title bar.(This is a joke module.)'

    Author            = 'stknohg'
    CompanyName       = 'stknohg'
    Copyright         = '(c) 2016 stknohg. All rights reserved.'

    NestedModules     = @('PSSushiBar.psm1')

    # TypesToProcess = @()
    # FormatsToProcess = @()
    FunctionsToExport = @('Get-SushiCount', 'Start-SushiBar', 'Stop-SushiBar')
    #AliasesToExport = @()

    PrivateData       = @{
        PSData = @{
            ProjectUri = 'https://github.com/stknohg/PSSushiBar'
            LicenseUri = 'https://github.com/stknohg/PSSushiBar/blob/master/LICENSE'
            # IconUri = ''
            # ReleaseNotes = ''
            Tags       = @('🍣', 'sushi', '寿司')
        }
    }
}