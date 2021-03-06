[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\lib\Initialize-Test.ps1
$variableSets = @(
    @{ Clean = $false ; RestoreNugetPackages = $false ; LogProjectEvents = $false ; CreateLogFile = $false }
    @{ Clean = $false ; RestoreNugetPackages = $false ; LogProjectEvents = $false ; CreateLogFile = $true }
    @{ Clean = $false ; RestoreNugetPackages = $false ; LogProjectEvents = $true ; CreateLogFile = $false }
    @{ Clean = $false ; RestoreNugetPackages = $true ; LogProjectEvents = $false ; CreateLogFile = $false }
    @{ Clean = $true ; RestoreNugetPackages = $false ; LogProjectEvents = $false ; CreateLogFile = $false }
)
foreach ($variableSet in $variableSets) {
    Unregister-Mock Get-VstsInput
    Unregister-Mock Get-SolutionFiles
    Unregister-Mock Select-VSVersion
    Unregister-Mock Select-MSBuildLocation
    Unregister-Mock Format-MSBuildArguments
    Unregister-Mock Invoke-BuildTools
    Register-Mock Get-VstsInput { 'Some input VS version' } -- -Name VSVersion
    Register-Mock Get-VstsInput { 'Some input architecture' } -- -Name MSBuildArchitecture
    Register-Mock Get-VstsInput { 'Some input arguments' } -- -Name MSBuildArgs
    Register-Mock Get-VstsInput { 'Some input solution' } -- -Name Solution -Require
    Register-Mock Get-VstsInput { 'Some input platform' } -- -Name Platform
    Register-Mock Get-VstsInput { 'Some input configuration' } -- -Name Configuration
    Register-Mock Get-VstsInput { $variableSet.Clean } -- -Name Clean -AsBool
    Register-Mock Get-VstsInput { $variableSet.RestoreNuGetPackages } -- -Name RestoreNuGetPackages -AsBool
    Register-Mock Get-VstsInput { $variableSet.LogProjectEvents } -- -Name LogProjectEvents -AsBool
    Register-Mock Get-VstsInput { $variableSet.CreateLogFile } -- -Name CreateLogFile -AsBool
    Register-Mock Get-SolutionFiles { 'Some solution 1', 'Some solution 2' } -- -Solution 'Some input solution'
    Register-Mock Select-VSVersion { 'Some VS version' } -- -PreferredVersion 'Some input VS version'
    Register-Mock Select-MSBuildLocation { 'Some MSBuild location' } -- -VSVersion 'Some VS version' -Architecture 'Some input architecture'
    Register-Mock Format-MSBuildArguments { 'Some formatted arguments' } -- -MSBuildArguments 'Some input arguments' -Platform 'Some input platform' -Configuration 'Some input configuration' -VSVersion 'Some VS version'
    Register-Mock Invoke-BuildTools { 'Some build output' }

    # Act.
    $output = & $PSScriptRoot\..\..\..\Tasks\VSBuild\VSBuild.ps1

    # Assert.
    Assert-AreEqual 'Some build output' $output
    Assert-WasCalled Invoke-BuildTools -- -NuGetRestore: $variableSet.RestoreNuGetPackages -SolutionFiles @('Some solution 1', 'Some solution 2') -MSBuildLocation 'Some MSBuild location' -MSBuildArguments 'Some formatted arguments' -Clean: $variableSet.Clean -NoTimelineLogger: $(!$variableSet.LogProjectEvents) -CreateLogFile: $variableSet.CreateLogFile
}
