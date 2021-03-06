[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$Platform,

    [Parameter(Mandatory=$True)]
    [string]$Configuration
)

If ($Platform -ne "Any CPU")
{
    Exit
}

$dir = "src\Corale.Colore.Tests\bin\$Configuration"
$dll = "Corale.Colore.Tests.dll"
$nunit = "src\packages\NUnit.ConsoleRunner.3.2.1\tools\nunit3-console.exe"
$filter = "+[Corale.Colore*]* -[*Tests]* -[*]*Constants -[*]Corale.Colore.Native* -[*]*NativeMethods -[*]*NativeWrapper -[*]Corale.Colore.Annotations*"
$targetArgs = "$dll"

$Env:NUNIT_EXEC = $nunit
$Env:OPENCOVER_FILTER = $filter
$Env:TARGET_DIR = $dir
$Env:TARGET_ARGS = $targetArgs

$git_log = git --% log -1 --format=%H;%an;%ae;%s
$git_info = $git_log -split ';'

$Env:GIT_HASH = $git_info[0]
$Env:GIT_NAME = $git_info[1]
$Env:GIT_EMAIL = $git_info[2]
$Env:GIT_SUBJECT = $git_info[3]
$Env:GIT_BRANCH = git --% name-rev --name-only HEAD

If ($Env:GIT_BRANCH -eq "undefined")
{
    # If the branch is undefined we are most likely building a PR
    # and the coveralls tool does not yet support sending PR
    # data to coveralls properly
    Exit
}

.\src\packages\OpenCover.4.6.519\tools\OpenCover.Console.exe --% -register "-filter:%OPENCOVER_FILTER%" "-target:%NUNIT_EXEC%" "-targetargs:%TARGET_ARGS%" "-targetdir:%TARGET_DIR%" -output:coverage.xml

.\src\packages\coveralls.net.0.6.0\tools\csmacnz.Coveralls.exe --% --opencover -i coverage.xml --useRelativePaths --repoTokenVariable COVERALLS_REPO_TOKEN --jobId %CI_JOB_ID% --serviceName TeamCity --commitId "%GIT_HASH%" --commitBranch "%GIT_BRANCH%" --commitAuthor "%GIT_NAME%" --commitEmail "%GIT_EMAIL%" --commitMessage "%GIT_SUBJECT%"
