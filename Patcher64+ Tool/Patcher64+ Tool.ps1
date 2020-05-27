#==============================================================================================================================================================================================
$ScriptName = 'Patcher64+ Tool'



#=============================================================================================================================================================================================
# Patcher By     :  Admentus
# Concept By     :  Bighead
# Testing By     :  Admentus, GhostlyDark



#==============================================================================================================================================================================================
Add-Type -AssemblyName 'System.Windows.Forms'
Add-Type -AssemblyName 'System.Drawing'



#==============================================================================================================================================================================================
# Setup global variables

$global:Version = '27-05-2020'

$global:ContinuePatching = $true
$global:GameID = ''
$global:ChannelTitle = ''
$global:ChannelTitleLength = 40
$global:GameType = $null
$global:IsInject = $false
$global:IsBPS = $false
$global:IsVCPatch = $false
$global:IsExtract = $false
$global:IsRedux = $false
$global:IsWiiVC = $true
$global:PatchBootDol = $false
$global:PatchedFileName = ''

$global:CurrentModeFont = [System.Drawing.Font]::new("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$global:VCPatchFont = [System.Drawing.Font]::new("Microsoft Sans Serif", 8, [System.Drawing.FontStyle]::Bold)



#==============================================================================================================================================================================================
# Set file paths

# The path this script is found in.
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $BasePath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
  $ThisPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
  if (!$BasePath) { $BasePath = "." }
}

# Set the master path to where the files will be located.
$global:MasterPath = $BasePath + '\Files'



#==============================================================================================================================================================================================
# Files to patch and use

$global:WADFilePath = $null
$global:Z64FilePath = $null
$global:BPSFilePath = $null
$global:PatchFile = $null
$global:ROMFile = $null
$global:OutputROMFile = $null



#==============================================================================================================================================================================================
# Import code

Import-Module -Name ($BasePath + '\Extension.psm1')



#==============================================================================================================================================================================================
$HidePSConsole = @"
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
"@
Add-Type -Namespace Console -Name Window -MemberDefinition $HidePSConsole



#==============================================================================================================================================================================================
# Function that shows or hides the console window.
function ShowPowerShellConsole([bool]$ShowConsole) {

    switch ($ShowConsole) {
        $true   { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 5) | Out-Null }
        $false  { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0) | Out-Null }
    }

}



#==============================================================================================================================================================================================
function ExtendString([string]$InputString, [int]$Length) {

    # Count the number of characters in the input string.
    $Count = ($InputString | Measure-Object -Character).Characters

    # Check the number of characters against the desired amount.
    if ($Count -lt $Length) {
        # If the string is to be lengthened, find out by how much.
        $AddLength = $Length - $Count
        
        # Loop until the string matches the desired number of characters.
        for ($i = 1 ; $i -le $AddLength ; $i++) {
            # Add an empty space to the end of the string.
            $InputString += ' '
        }
    }

    # Return the modified string.
    return $InputString

}



#==============================================================================================================================================================================================
<#
function PrintHexArray([byte[]]$ByteArray) {

    # Initial Values
    $Offset = $Loop  = 0
    $String = $Extra = ''

    # Create a header
    Write-Host ' ------------------------------------------------------------------------------'
    Write-Host ' Offset      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F'
    Write-Host ' ------------------------------------------------------------------------------'

    # Loop through each value in the byte array.
    foreach($Value in $ByteArray) {
        # Convert the value to a hex value.
        $Character = ('{0:X}' -f $Value)

        # Make sure it's at least 2 digits long for alignment.
        if ($Character.Length -lt 2) {
            $Character = '0' + $Character
        }

        # Update the string with the current characters.
        $String += ($Character + ' ')

        # Add the character to the "Extra" string if it's a valid ASCII format.
        # If it's a value that makes PowerShell freak out, just make it a period.
        if (($Value -gt 32) -and ($Value -lt 126)) {
            $Extra += [char][byte]$Value } else { $Extra += '.'
        }

        # If we haven't stored at least 16 digits, just keep adding up for now.
        if ($Loop -lt 15) {
            $Loop++
        }

        # If 16 digits have been reached.
        else {
        # Write the line of values.
        Write-Host ((' ' + '{0:X8}' -f $Offset) + ' :: ' + $String + '  ' + $Extra)

        # Reset the values and start counting again.
        $String = $Extra = ''
        $Loop = 0
        $Offset += 16
        }
    }

    # If there are any leftovers, write it out.
    if ($String -ne '') {
        $FinalString = ((' ' + '{0:X8}' -f $Offset) + ' :: ' + $String)
        Write-Host ((ExtendString -InputString $FinalString -Length 61) + '  ' + $Extra)
    }

}
#>



#==============================================================================================================================================================================================
function MainFunctionRomInject() {
    
    MainFunctionReset

    $IsInject = $true
    $PatchedFileName = '_injected'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionBPSPatch() {
    
    MainFunctionReset

    $IsBPS = $true
    $PatchFile = $BPSFilePath
    $PatchedFileName = '_bps_patched'

    MainFunction

}

#==============================================================================================================================================================================================
function MainFunctionPatchVC() {
    
    MainFunctionReset

    $IsVCPatch = $true
    $PatchedFileName = '_vc_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionExtractROM() {
    
    MainFunctionReset

    $IsExtract = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionReset() {
    
    if ($GameType -eq "Ocarina of Time" -and !$InputCustomGameIDCheckbox.Checked) {
        SetOcarinaOfTimeModeActive
    }
    elseif ($GameType -eq "Majora's Mask" -and !$InputCustomGameIDCheckbox.Checked) {
        SetMajorasMaskModeActive
    }
    elseif ($GameType -eq "Super Mario 64" -and !$InputCustomGameIDCheckbox.Checked) {
        SetSuperMario64ModeActive
    }
    elseif ($GameType -eq "Paper Mario" -and !$InputCustomGameIDCheckbox.Checked) {
        SetPaperMarioModeActive
    }
    elseif ($GameType -eq "Free" -and !$InputCustomGameIDCheckbox.Checked) {
        SetFreeModeActive
    }

    $IsInject = $false
    $IsBPS = $false
    $IsVCPatch = $false
    $IsExtract = $false
    $IsRedux = $false
    $PatchBootDol = $false
    $PatchFile = $null
    $PatchedFileName = "_patched"

}



#==============================================================================================================================================================================================
function MainFunctionOoTRedux() {
    
    MainFunctionReset

    $GameID = "NAC0"
    $ChannelTitle = "Redux: Ocarina"
    $PatchFile = $Files.bpspatch_oot_redux
    $PatchedFileName = '_redux_patched'
    $IsRedux = $true

    $PatchVCExpandMemory.Checked = $true
    $PatchVCRemapDPad.Checked = $true
    $PatchVCDowngrade.Checked = $true

    if (!$PatchVCRemapCDown.Checked -and !$PatchVCRemapZ.Checked) {
        $PatchVCLeaveDPadUp.Checked = $true
    }

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionOoTDawn() {
    
    MainFunctionReset

    $GameID = "NAC1"
    $ChannelTitle = "Zelda: Dawn & Dusk"
    $PatchFile = $Files.bpspatch_oot_dawn
    $PatchedFileName = '_dawn_&_dusk_patched'

    MainFunctionPatchButton
    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionOoTSpa() {
    
    MainFunctionReset

    $GameID = "NACS"
    $ChannelTitle = "Zelda: Ocarina (Spa)"
    $PatchFile = $Files.bpspatch_oot_spa
    $PatchedFileName = '_spanish_patched'

    $PatchVCDowngrade.Checked = $true

    MainFunctionPatchButton
    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionOoTPol() {
    
    MainFunctionReset

    $GameID = 'NACO'
    $ChannelTitle = 'Zelda: Ocarina (Pol)'
    $PatchFile = $Files.bpspatch_oot_pol
    $PatchedFileName = '_polish_patched'

    $PatchVCDowngrade.Checked = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionOoTRus() {
    
    MainFunctionReset

    $GameID = "NACR"
    $ChannelTitle = "Zelda: Ocarina (Rus)"
    $PatchFile = $Files.bpspatch_oot_rus
    $PatchedFileName = '_russian_patched'

    $PatchVCDowngrade.Checked = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionOoTChi() {

    MainFunctionReset
    
    $GameID = "NACC"
    $ChannelTitle = "Zelda: Ocarina (Chi)"
    $PatchFile = $Files.bpspatch_oot_chi
    $PatchedFileName = '_chinese_patched'

    $PatchVCDowngrade.Checked = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionMMRedux() {
    
    MainFunctionReset

    $GameID = "NAR0"
    $ChannelTitle = "Redux: Majora's"
    $PatchFile = $Files.bpspatch_mm_redux
    $PatchedFileName = '_redux_patched'
    $IsRedux = $true

    $PatchVCRemapDPad.Checked = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionMMMaskedQuest() {
    
    MainFunctionReset

    $GameID = "NAR1"
    $ChannelTitle = "Zelda: Masked Quest"
    $PatchFile = $Files.bpspatch_mm_masked_quest
    $PatchedFileName = '_masked_quest_patched'

    $PatchVCRemapDPad.Checked = $true

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionMMPol() {
    
    MainFunctionReset

    $GameID = "NARO"
    $ChannelTitle = "Zelda: Majora's (Pol)"
    $PatchFile = $Files.bpspatch_mm_pol
    $PatchedFileName = '_polish_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionMMRus() {
    
    MainFunctionReset

    $GameID = "NARR"
    $ChannelTitle = "Zelda: Majora's (Rus)"
    $PatchFile = $Files.bpspatch_mm_rus
    $PatchedFileName = '_russian_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionSM64FPS() {
    
    MainFunctionReset

    $GameID = 'NAAX'
    $ChannelTitle = "Super Mario 64: 60 FPS v2"
    $PatchFile = $Files.bpspatch_sm64_fps
    $PatchedFileName = '_60_fps_v2_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionSM64Cam() {
    
    MainFunctionReset

    $GameID = 'NAAY'
    $ChannelTitle = "Super Mario 64: Free Cam"
    $PatchFile = $Files.bpspatch_sm64_cam
    $PatchedFileName = '_analog_camera_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionSM64Multiplayer() {
    
    MainFunctionReset

    $PatchBootDol = $true
    $GameID = 'NAAM'
    $ChannelTitle = "SM64: Multiplayer"
    $PatchFile = $Files.bpspatch_sm64_multiplayer
    $PatchedFileName = '_multiplayer__v1.4.2_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionPPHardMode() {
    
    MainFunctionReset

    $GameID = 'NAE0'
    $ChannelTitle = "Paper Mario: Hard Mode"
    $PatchFile = $Files.bpspatch_pp_hard_mode
    $PatchedFileName = '_hard_mode_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionPPHardModePlus() {
    
    MainFunctionReset

    $GameID = 'NAE1'
    $ChannelTitle = "Paper Mario: Hard Mode+"
    $PatchFile = $Files.bpspatch_pp_hard_mode_plus
    $PatchedFileName = '_hard_mode_plus_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunctionPPInsaneMode() {
    
    MainFunctionReset

    $GameID = 'NAE2'
    $ChannelTitle = "Paper Mario: Insane Mode"
    $PatchFile = $Files.bpspatch_pp_insane_mode
    $PatchedFileName = '_insane_mode_patched'

    MainFunction

}



#==============================================================================================================================================================================================
function MainFunction() {
    
    # Step 01: Disable the main dialog and delete files if they still exist.
    DeleteAllFiles
    $MainDialog.Enabled = $false

    # Step 02: Create all the files.
    CreateFiles

    # Only continue with these steps in VC WAD mode. Otherwise ignore these steps.
    if ($IsWiiVC) {
        
        # Step 03: Extract the contents of the WAD file.
        ExtractWADFile

        # Step 04: Check the GameID to be vanilla.
        CheckGameID

        # Step 05: Stop if the GameID is not vanilla.
        if (!$ContinuePatching) {
            DeleteAllFiles
            return
        }

        # Step 06: Replace the Virtual Console emulator within the WAD file.
        PatchVCEmulator

        # Step 07: Extract "00000005.app" file to get the ROM.
        ExtractU8AppFile

        # Step 08: Do some initial patching stuff for the ROM for VC WAD files.
        PreparePatchROM
    }
    else {
        # Step 09: Set the initial ROM File for N64 mode
        $global:Z64File = SetZ64Parameters -Z64Path $GameZ64 -FolderName $Folder.Name
    }

    # Step 10: Patch and extend the ROM file with the patch through Floating IPS.
    PatchROM

    # Step 11: Stop here is there is an issue or the ROM is just being extracted.
    if (!$ContinuePatching -or $IsExtract) {
        DeleteAllFiles
        return
    }

    # Step 12: Decompress a patched REDUX ROM and apply additional patches on top. Afterward compress it again.
    PatchRedux

    # Only continue with these steps in VC WAD mode. Otherwise ignore these steps.
    if ($IsWiiVC) {
        # Step 13: Extend a ROM if it is neccesary for the Virtual Console. Mostly applies to decompressed ROMC files
        ExtendROM

        # Step 14: Compress the ROMC again if possible.
        CompressROM

        # Step 15: Apply Custom Channel Title and GameID if enabled.
        SetCustomGameID

        # Step 16: Hack the Channel Title.
        HackOpeningBNRTitle

        # Step 17: Repack the "00000005.app" with the updated ROM file.
        RepackU8AppFile

        # Step 18: Repack the WAD file with the updated APP file.
        RepackWADFile
    }

    # Step 19: Get rid of everything.
    DeleteAllFiles

    # Step 20: Final message.
    if ($IsWiiVC) {
        UpdateStatusLabelDuringPatching -Text ('Finished patching the ' + $GameType + ' VC WAD file.')
    }
    else {
        UpdateStatusLabelDuringPatching -Text ('Finished patching the ' + $GameType + ' ROM file.')
    }

    # Step 21: Enable the main dialog.
    $MainDialog.Enabled = $true

}



#==============================================================================================================================================================================================
function DeleteAllFiles() {
    
    RemovePath -LiteralPath $MasterPath
    RemovePath -LiteralPath ($BasePath + '\cygdrive')

    if ($IsWiiCC) {
        RemovePath -LiteralPath $WADFile.Folder
    }

    if ($IsRedux) {
        $dmaTable = "dmaTable.dat"
        if (Test-Path $dmaTable -PathType leaf) {
            Remove-Item $dmaTable
        }

        $archive = "ARCHIVE.bin"
        if (Test-Path $archive -PathType leaf) {
            Remove-Item $archive
        }
    }

    $MainDialog.Enabled = $true

}



#==============================================================================================================================================================================================
function RemovePath([string]$LiteralPath) {
    
    # Make sure the path isn't null to avoid errors.
    if ($LiteralPath -ne '') {
        # Check to see if the path exists.
        if (Test-Path -LiteralPath $LiteralPath) {
            # Remove the path.
            Remove-Item -LiteralPath $LiteralPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }

}



#==============================================================================================================================================================================================
function TestPath([string]$LiteralPath, [string]$PathType = 'Any') {
    
    # Make sure the path isn't null to avoid errors.
    if ($LiteralPath -ne '') {
        # Check to see if the path exists.
        if (Test-Path -LiteralPath $LiteralPath -PathType $PathType -ErrorAction 'SilentlyContinue') {
            # The path exists.
            return $true
        }
    }

    # The path is bunk.
    return $false

}



#==============================================================================================================================================================================================
function Get-FileName([string]$Path, [string[]]$Description, [string[]]$FileName) {
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $Path
    
    for($i = 0; $i -lt $FileName.Count; $i++) {
        $FilterString += $Description[$i] + '|' + $FileName[$i] + '|'
    }
    
    $OpenFileDialog.Filter = $FilterString.TrimEnd('|')
    $OpenFileDialog.ShowDialog() | Out-Null
    
    return $OpenFileDialog.FileName

}



#==============================================================================================================================================================================================
function SetFileParameters() {
    
    # Create a hash table.
    $Files = @{}

    # Store all files by their name.
    $Files.flips                         = $MasterPath + "\flips.exe"
    $Files.wadpacker                     = $MasterPath + "\wadpacker.exe"
    $Files.wadunpacker                   = $MasterPath + "\wadunpacker.exe"
    $Files.wszst                         = $MasterPath + "\wszst.exe"
    $Files.cygcrypto                     = $MasterPath + "\cygcrypto-0.9.8.dll"
    $Files.cyggccs1                      = $MasterPath + "\cyggcc_s-1.dll"
    $Files.cygncursesw10                 = $MasterPath + "\cygncursesw-10.dll"
    $Files.cygpng1616                    = $MasterPath + "\cygpng16-16.dll"
    $Files.cygwin1                       = $MasterPath + "\cygwin1.dll"
    $Files.cygz                          = $MasterPath + "\cygz.dll"
    $Files.romc                          = $MasterPath + "\romc.exe"
    $Files.romchu                        = $MasterPath + "\romchu.exe"
    $Files.lzss                          = $MasterPath + "\lzss.exe"
    $Files.Compress                      = $MasterPath + "\Compress.exe"
    $Files.ndec                          = $MasterPath + "\ndec.exe"
    $Files.TabExt                        = $MasterPath + "\TabExt.exe"
    $Files.ckey                          = $MasterPath + "\common-key.bin"

    $Files.bpspatch_oot_1_0              = $MasterPath + "\oot_1_0.bps"
    $Files.bpspatch_oot_redux            = $MasterPath + "\oot_redux.bps"
    $Files.bpspatch_oot_dawn             = $MasterPath + "\oot_dawn.bps"
    $Files.bpspatch_oot_spa              = $MasterPath + "\oot_spa.bps"
    $Files.bpspatch_oot_pol              = $MasterPath + "\oot_pol.bps"
    $Files.bpspatch_oot_rus              = $MasterPath + "\oot_rus.bps"
    $Files.bpspatch_oot_chi              = $MasterPath + "\oot_chi.bps"

    $Files.bpspatch_mm_redux             = $MasterPath + "\mm_redux.bps"
    $Files.bpspatch_mm_masked_quest      = $MasterPath + "\mm_masked_quest.bps"
    $Files.bpspatch_mm_pol               = $MasterPath + "\mm_pol.bps"
    $Files.bpspatch_mm_rus               = $MasterPath + "\mm_rus.bps"

    $Files.bpspatch_sm64_fps             = $MasterPath + "\sm64_fps.bps"
    $Files.bpspatch_sm64_cam             = $MasterPath + "\sm64_cam.bps"
    $Files.bpspatch_sm64_multiplayer     = $MasterPath + "\sm64_multiplayer.bps"

    $Files.bpspatch_pp_hard_mode         = $MasterPath + "\pp_hard_mode.bps"
    $Files.bpspatch_pp_hard_mode_plus    = $MasterPath + "\pp_hard_mode_plus.bps"
    $Files.bpspatch_pp_insane_mode       = $MasterPath + "\pp_insane_mode.bps"

    $Files.bpspatch_sm64_appFile_01      = $MasterPath + "\sm64_appFile_01.bps"

    # Set it to a global value.
    return $Files

}



#==============================================================================================================================================================================================
function SetWADParameters([string]$WADPath, [string]$FolderName) {
    
    # Create a hash table.
    $WADFile = @{}

    # Get the WAD as an item object.
    $WADItem = Get-Item -LiteralPath $WADPath
    
    # Store some stuff about the WAD that I'll probably reference.
    $WADFile.Name      = $WADItem.BaseName
    $WADFile.Path      = $WADItem.DirectoryName
    $WADFile.Folder    = $WADFile.Path + '\' + $FolderName

    $WADFile.AppFile00 = $WADFile.Folder + '\00000000.app'
    $WADFile.AppPath00 = $WADFile.Folder + '\00000000'
    $WADFile.AppFile01 = $WADFile.Folder + '\00000001.app'
    $WADFile.AppPath01 = $WADFile.Folder + '\00000001'
    $WADFile.AppFile05 = $WADFile.Folder + '\00000005.app'
    $WADFile.AppPath05 = $WADFile.Folder + '\00000005'

    $WADFile.cert      = $WADFile.Folder + '\' + $FolderName + '.cert'
    $WADFile.tik       = $WADFile.Folder + '\' + $FolderName + '.tik'
    $WADFile.tmd       = $WADFile.Folder + '\' + $FolderName + '.tmd'
    $WADFile.trailer   = $WADFile.Folder + '\' + $FolderName + '.trailer'
    
    if ($gameType -eq "Majora's Mask" -or $gameType -eq "Paper Mario") {
        $global:ROMFile = $WADFile.AppPath05 + '\romc'
    }
    else {
        $global:ROMFile = $WADFile.AppPath05 + '\rom'
    }

    $WADFile.Patched   = $WADFile.Path + '\' + $WADFile.Name + $PatchedFileName + '.wad'

    # Set it to a global value.
    return $WADFile

}



#==============================================================================================================================================================================================
function SetZ64Parameters([string]$Z64Path, [string]$FolderName) {
    
    # Create a hash table.
    $Z64File = @{}

    # Get the WAD as an item object.
    $Z64Item = Get-Item -LiteralPath $Z64Path
    
    # Store some stuff about the Z64 that I'll probably reference.
    $Z64File.Name      = $Z64Item.BaseName
    $Z64File.Path      = $Z64Item.DirectoryName
    $Z64File.Folder    = $Z64File.Path + '\' + $FolderName

    $global:ROMFile = $Z64Path

    $Z64File.Patched   = $Z64File.Path + '\' + $Z64File.Name + $PatchedFileName + '.z64'

    # Set it to a global value.
    return $Z64File

}



#==============================================================================================================================================================================================
function ExtractWADFile() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Extracting WAD file...'
    
    # We need to be in the same path as some files so just jump there.
    Push-Location $MasterPath

    # Run the program to extract the wad file.
    & $Files.wadunpacker $GameWAD # | Out-Host

    # Find the extracted folder by looping through all files in the folder.
    foreach($Folder in Get-ChildItem -LiteralPath $MasterPath -Force) {
        # There will only be one folder, the one we want.
        if ($Folder.PSIsContainer) {
            # Remember the path to this folder.
            $global:WADFile = SetWADParameters -WADPath $GameWAD -FolderName $Folder.Name

            # If it already exists remove it first. Helps me with testing this out.
            if (TestPath -LiteralPath $WADFile.Folder) { RemovePath -LiteralPath $WADFile.Folder }

            # Move this folder to where the WAD file is located.
            Move-Item -LiteralPath $Folder.FullName -Destination $WADFile.Path -Force
        }
    }

    # Doesn't matter, but return to where we were.
    Pop-Location

}



#==============================================================================================================================================================================================
function ExtractU8AppFile() {

    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Extracting "00000005.app" file...'
    
    # Unpack the file using wszst.
    & $Files.wszst 'X' $WADFile.AppFile05 '-d' $WADFile.AppPath05 # | Out-Host

    # Remove all .T64 files when selected
    if ($PatchVCRemoveT64.Checked) {
        Get-ChildItem $WADFile.AppPath05 -Include *.T64 -Recurse | Remove-Item
    }

}



#==============================================================================================================================================================================================
function PatchVCEmulator() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text ('Patching ' + $GameType + ' VC Emulator...')

    $HasBootDolOptions = CheckBootDolOptions

    if ($GameType -eq "Ocarina of Time" -and $HasBootDolOptions) {
        
        $ByteArray = [IO.File]::ReadAllBytes($WadFile.AppFile01)

        if ($PatchVCExpandMemory.Checked) {
            $ByteArray[(GetDecimal -Hex "0x2EB0")] = (GetDecimal -Hex "0x60")
            $ByteArray[(GetDecimal -Hex "0x2EB1")] = 0
            $ByteArray[(GetDecimal -Hex "0x2EB2")] = 0
            $ByteArray[(GetDecimal -Hex "0x2EB3")] = 0

            $ByteArray[(GetDecimal -Hex "0x5BF44")] = (GetDecimal -Hex "0x3C")
            $ByteArray[(GetDecimal -Hex "0x5BF45")] = (GetDecimal -Hex "0x80")
            $ByteArray[(GetDecimal -Hex "0x5BF46")] = (GetDecimal -Hex "0x72")
            $ByteArray[(GetDecimal -Hex "0x5BF47")] = 0

            $ByteArray[(GetDecimal -Hex "0x5BFD7")] = 0
        }

        if ($PatchVCRemapDPad.Checked) {
            if (!$PatchLeaveDPadUp.Checked) {
                $ByteArray[(GetDecimal -Hex "0x16BAF0")] = 8
                $ByteArray[(GetDecimal -Hex "0x16BAF1")] = 0
            }

            $ByteArray[(GetDecimal -Hex "0x16BAF4")] = 4
            $ByteArray[(GetDecimal -Hex "0x16BAF5")] = 0

            $ByteArray[(GetDecimal -Hex "0x16BAF8")] = 2
            $ByteArray[(GetDecimal -Hex "0x16BAF9")] = 0

            $ByteArray[(GetDecimal -Hex "0x16BAFC")] = 1
            $ByteArray[(GetDecimal -Hex "0x16BAFD")] = 0
        }

        if ($PatchVCRemapCDown.Checked) {
            $ByteArray[(GetDecimal -Hex "0x16BB04")] = 0
            $ByteArray[(GetDecimal -Hex "0x16BB05")] = (GetDecimal -Hex "0x20")
        }

        if ($PatchVCRemapZ.Checked) {
            $ByteArray[(GetDecimal -Hex "0x16BAD8")] = 0
            $ByteArray[(GetDecimal -Hex "0x16BAD9")] = (GetDecimal -Hex "0x20")
        }

        [io.file]::WriteAllBytes($WADFile.AppFile01, $ByteArray)

    }

    elseif ($GameType -eq "Majora's Mask" -and $HasBootDolOptions) {
        
        & $Files.lzss -d $WADFile.AppFile01 | Out-Host
        $ByteArray = [IO.File]::ReadAllBytes($WadFile.AppFile01)

        if ($PatchVCExpandMemory.Checked) {
            $ByteArray[(GetDecimal -Hex "0x10B58")] = (GetDecimal -Hex "0x3C")
            $ByteArray[(GetDecimal -Hex "0x10B59")] = (GetDecimal -Hex "0x80")
            $ByteArray[(GetDecimal -Hex "0x10B5A")] = 0
            $ByteArray[(GetDecimal -Hex "0x10B5B")] = (GetDecimal -Hex "0xC0")

            $ByteArray[(GetDecimal -Hex "0x4BD20")] = (GetDecimal -Hex "0x67")
            $ByteArray[(GetDecimal -Hex "0x4BD21")] = (GetDecimal -Hex "0xE4")
            $ByteArray[(GetDecimal -Hex "0x4BD22")] = (GetDecimal -Hex "0x70")
            $ByteArray[(GetDecimal -Hex "0x4BD23")] = 0

            $ByteArray[(GetDecimal -Hex "0x4BC80")] = (GetDecimal -Hex "0x3C")
            $ByteArray[(GetDecimal -Hex "0x4BC81")] = (GetDecimal -Hex "0xA0")
            $ByteArray[(GetDecimal -Hex "0x4BC82")] = 1
            $ByteArray[(GetDecimal -Hex "0x4BC83")] = 0
        }

        if ($PatchVCRemapDPad.Checked) {
            $ByteArray[(GetDecimal -Hex "0x148514")] = 8
            $ByteArray[(GetDecimal -Hex "0x148515")] = 0

            $ByteArray[(GetDecimal -Hex "0x148518")] = 4
            $ByteArray[(GetDecimal -Hex "0x148519")] = 0

            $ByteArray[(GetDecimal -Hex "0x14851C")] = 2
            $ByteArray[(GetDecimal -Hex "0x14851D")] = 0

            $ByteArray[(GetDecimal -Hex "0x148520")] = 1
            $ByteArray[(GetDecimal -Hex "0x148521")] = 0
        }

        if ($PatchVCRemapCDown.Checked) {
            $ByteArray[(GetDecimal -Hex "0x148528")] = 0
            $ByteArray[(GetDecimal -Hex "0x148529")] = (GetDecimal -Hex "0x20")
        }

        if ($PatchVCRemapZ.Checked ) {
            $ByteArray[(GetDecimal -Hex "0x1484F8")] = 0
            $ByteArray[(GetDecimal -Hex "0x1484F9")] = (GetDecimal -Hex "0x20")
        }

        [io.file]::WriteAllBytes($WADFile.AppFile01, $ByteArray)
        # & $Files.lzss -evn $WADFile.AppFile01 | Out-Host

    }

    elseif ($GameType -eq "Super Mario 64" -and $PatchBootDol) {
        & $Files.flips $Files.bpspatch_sm64_appFile_01 $WADFile.AppFile01 | Out-Host
    }

}


#==============================================================================================================================================================================================
function PreparePatchROM() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text ('Initial patching of ' + $GameType + ' ROM...')
    
    # Replace ROM if needed
    if ($IsInject) {
        Remove-Item $ROMFile
        Copy-Item $Z64FilePath -Destination $ROMFile
    }

    # Decompress romc if needed
    if (!$IsInject) {
        if ($GameType -eq "Majora's Mask" -or $GameType -eq "Paper Mario") {
            if ($IsWiiVC) { $global:OutputROMFile = $WADFile.AppPath05 + "\out.n64" } else { "out.n64" }

            if ($GameType -eq "Majora's Mask") {
                & $Files.romchu $ROMFile $OutputROMFile | Out-Host
            }
            elseif ($GameType -eq "Paper Mario") {
                & $Files.romc d $ROMFile $outputROMFile | Out-Host
            }

            Remove-Item $ROMFile
            Rename-Item -Path $outputROMFile -NewName "romc"
        }
    }

    if ($IsExtract) {
        if ($GameType -ne "Free") { $ROMTitle = $GameType + ".z64" } else { $ROMTitle = "rom.z64" }
        Move-Item $ROMFile -Destination $ROMTitle
        return
    }

    # Get the file as a byte array so the size can be analyzed.
    $ByteArray = [IO.File]::ReadAllBytes($ROMFile)
    
    # Create an empty byte array that matches the size of the ROM byte array.
    $NewByteArray = New-Object Byte[] $ByteArray.Length
    
    # Fill the entire array with junk data. The patched ROM is slightly smaller than 8MB but we need an 8MB ROM.
    for ($i=0 ; $i-lt $ByteArray.Length; $i++) {
        $NewByteArray[$i] = 255
    }

    # Downgrade a ROM if it is required first
    if ($GameType -eq "Ocarina of Time" -and $PatchVCDowngrade.Checked) {
         & $Files.flips $Files.bpspatch_oot_1_0 $ROMFile | Out-Host
    }

}


#==============================================================================================================================================================================================
function PatchROM() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text ('BPS Patching ' + $GameType + ' ROM...')

    # Apply the selected patch to the ROM.
    if ($PatchFile -ne $null -and !$IsBPS) {
        if ($IsWiiVC) {
            & $Files.flips $PatchFile $ROMFile | Out-Host
        }
        else {
            & $Files.flips --apply $PatchFile $ROMFile $Z64File.Patched | Out-Host
       }
    }
    elseif ($IsBPS) {
        if ($IsWiiVC) {
            $OldChecksum = Get-FileHash -Algorithm SHA256 $ROMFile
            if ($IsWiiVC) {
                & $Files.flips $PatchFile $ROMFile | Out-Host
            }
            $NewChecksum = Get-FileHash -Algorithm SHA256 $ROMFile

            if ($OldChecksum.Hash -eq $NewChecksum.Hash) {
                $global:ContinuePatching = $false
                UpdateStatusLabelDuringPatching -Text 'Failed! BPS or IPS Patch does not match. ROM has left unchanged.'
                if ($GameType -eq "Ocarina of Time" -and !$PatchVCDowngrade.Checked) {
                    UpdateStatusLabelDuringPatching -Text 'Failed! BPS or IPS Patch does not match. ROM has left unchanged. Enable Downgrade Ocarina of Time?'
                }
                elseif ($GameType -eq "Ocarina of Time" -and $PatchVCDowngrade.Checked) {
                    UpdateStatusLabelDuringPatching -Text = 'Failed! BPS or IPS Patch does not match. ROM has left unchanged. Disable Downgrade Ocarina of Time?'
                }
            }
        }
        else {
            & $Files.flips --apply $PatchFile $ROMFile $Z64File.Patched | Out-Host
        }

    }

}



#==============================================================================================================================================================================================
function CompressROM() {

    if (!$IsInject -and $GameType -eq "Paper Mario") {
        & $Files.romc e $ROMFile $outputROMFile | Out-Host
        Remove-Item $ROMFile
        Rename-Item -Path $outputROMFile -NewName "romc"
    }

}



#==============================================================================================================================================================================================
function PatchRedux() {
    
    $HasReduxOptions = CheckReduxOptions
    if (!$IsRedux -or !$HasReduxOptions) {
        return
    }

    UpdateStatusLabelDuringPatching -Text ('Patching ' + $GameType + ' REDUX...')
    
    if ($IsWiiVC) {
        $global:OutputROMFile = $WADFile.AppPath05 + "\out"
        & $Files.TabExt $ROMFile | Out-Host
        & $Files.ndec $ROMFile $OutputROMFile | Out-Host
        Remove-Item $ROMFile
    }
    else {
        $global:OutputROMFile = "out"
        & $Files.TabExt $Z64File.Patched | Out-Host
        & $Files.ndec $Z64File.Patched $OutputROMFile | Out-Host
    }

    $ByteArray = [IO.File]::ReadAllBytes($OutputROMFile)

    if ($GameType -eq "Ocarina of Time") {
        
        if ($1xTextOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xB5006F")] = 1
        }
        elseif ($3xTextOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0x93B6E7")] = (GetDecimal -Hex "0x05")
            $ByteArray[(GetDecimal -Hex "0x93B6E8")] = (GetDecimal -Hex "0x40")
            $ByteArray[(GetDecimal -Hex "0x93B6E9")] = (GetDecimal -Hex "0x2E")
            $ByteArray[(GetDecimal -Hex "0x93B6EA")] = (GetDecimal -Hex "0x05")
            $ByteArray[(GetDecimal -Hex "0x93B6EB")] = (GetDecimal -Hex "0x46")
            $ByteArray[(GetDecimal -Hex "0x93B6EC")] = (GetDecimal -Hex "0x01")
            $ByteArray[(GetDecimal -Hex "0x93B6ED")] = (GetDecimal -Hex "0x05")
            $ByteArray[(GetDecimal -Hex "0x93B6EE")] = (GetDecimal -Hex "0x40")
            $ByteArray[(GetDecimal -Hex "0x93B6EF")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B6F1")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B71E")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B71D")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B722")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B74C")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B74D")] = (GetDecimal -Hex "0x21")
            $ByteArray[(GetDecimal -Hex "0x93B74E")] = (GetDecimal -Hex "0x05")
            $ByteArray[(GetDecimal -Hex "0x93B74F")] = (GetDecimal -Hex "0x42")

            $ByteArray[(GetDecimal -Hex "0x93B752")] = (GetDecimal -Hex "0x01")
            $ByteArray[(GetDecimal -Hex "0x93B753")] = (GetDecimal -Hex "0x05")
            $ByteArray[(GetDecimal -Hex "0x93B754")] = (GetDecimal -Hex "0x40")

            $ByteArray[(GetDecimal -Hex "0x93B776")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B777")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B77A")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B7A1")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B7A2")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B7A5")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B7A8")] = (GetDecimal -Hex "0x1A")

            $ByteArray[(GetDecimal -Hex "0x93B7C9")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B7CA")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B7CD")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B7F2")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B7F3")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B7F6")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B81C")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B81D")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B820")] = (GetDecimal -Hex "0x1")

            $ByteArray[(GetDecimal -Hex "0x93B849")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B84A")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B84D")] = (GetDecimal -Hex "0x1")

            $ByteArray[(GetDecimal -Hex "0x93B86D")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B86E")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B871")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B88F")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B890")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B893")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B8BE")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B8BF")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B8C2")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B8EF")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B8F0")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B8F3")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B91A")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B91B")] = (GetDecimal -Hex "0x21")

            $ByteArray[(GetDecimal -Hex "0x93B91E")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B94E")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0x93B94F")] = (GetDecimal -Hex "0x2E")

            $ByteArray[(GetDecimal -Hex "0x93B952")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0x93B728")] = (GetDecimal -Hex "0x10")
            $ByteArray[(GetDecimal -Hex "0x93B72A")] = (GetDecimal -Hex "0x01")

            $ByteArray[(GetDecimal -Hex "0xB5006F")] = (GetDecimal -Hex "0x03")
        }



        # HERO MODE #

        if ($OHKOModeOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xAE8073")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0xAE8083")] = (GetDecimal -Hex "0x04")
            $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x82")
            $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xAE8099")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xAE809A")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xAE809B")] = (GetDecimal -Hex "0x00")
        }
        elseif (!$1xDamageOoT.Checked -and !$NormalRecoveryOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xAE8073")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0xAE8083")] = (GetDecimal -Hex "0x04")
            if ($NormalRecoveryOoT.Checked) {                
                $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                if ($2xDamageOoT.Checked ) {
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x40")
                }
                elseif ($4xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x80")
                }
                elseif ($8xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0xC0")
                }

                $ByteArray[(GetDecimal -Hex "0xAE8099")] = (GetDecimal -Hex "0x00")
                $ByteArray[(GetDecimal -Hex "0xAE809A")] = (GetDecimal -Hex "0x00")
                $ByteArray[(GetDecimal -Hex "0xAE809B")] = (GetDecimal -Hex "0x00")
            }
            elseif ($HalfRecoveryOoT.Checked) {               
                if ($1xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x40")
                }
                elseif ($2xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x80")
                }
                elseif ($4xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($8xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x00")
                }

                $ByteArray[(GetDecimal -Hex "0xAE8099")] = (GetDecimal -Hex "0x10")
                $ByteArray[(GetDecimal -Hex "0xAE809A")] = (GetDecimal -Hex "0x80")
                $ByteArray[(GetDecimal -Hex "0xAE809B")] = (GetDecimal -Hex "0x43")
            }
            elseif ($QuarterRecoveryOoT.Checked) {                
                if ($1xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x80")
                }
                elseif ($2xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x80")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($4xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x00")
                }
                elseif ($8xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x40")
                }
                $ByteArray[(GetDecimal -Hex "0xAE8099")] = (GetDecimal -Hex "0x10")
                $ByteArray[(GetDecimal -Hex "0xAE809A")] = (GetDecimal -Hex "0x80")
                $ByteArray[(GetDecimal -Hex "0xAE809B")] = (GetDecimal -Hex "0x83")

            }
            elseif ($NoRecoveryOoT.Checked) {                
                if ($1xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x40")
                }
                elseif ($2xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x80")
                }
                elseif ($4xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x81")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($8xDamageOoT.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xAE8096")] = (GetDecimal -Hex "0x82")
                    $ByteArray[(GetDecimal -Hex "0xAE8097")] = (GetDecimal -Hex "0x00")
                }
                $ByteArray[(GetDecimal -Hex "0xAE8099")] = (GetDecimal -Hex "0x10")
                $ByteArray[(GetDecimal -Hex "0xAE809A")] = (GetDecimal -Hex "0x81")
                $ByteArray[(GetDecimal -Hex "0xAE809B")] = (GetDecimal -Hex "0x43")
            }
        }

        if ($ExtendedDrawOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xA9A970")] = 0
            $ByteArray[(GetDecimal -Hex "0xA9A971")] = 1
        }

        if ($MedallionsOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xE2B454")] = (GetDecimal -Hex "0x80")
            $ByteArray[(GetDecimal -Hex "0xE2B455")] = (GetDecimal -Hex "0xEA")
            $ByteArray[(GetDecimal -Hex "0xE2B456")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B457")] = (GetDecimal -Hex "0xA7")
            $ByteArray[(GetDecimal -Hex "0xE2B458")] = (GetDecimal -Hex "0x24")
            $ByteArray[(GetDecimal -Hex "0xE2B459")] = 1
            $ByteArray[(GetDecimal -Hex "0xE2B45A")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B45B")] = (GetDecimal -Hex "0x3F")
            $ByteArray[(GetDecimal -Hex "0xE2B45C")] = (GetDecimal -Hex "0x31")
            $ByteArray[(GetDecimal -Hex "0xE2B45D")] = (GetDecimal -Hex "0x4A")
            $ByteArray[(GetDecimal -Hex "0xE2B45E")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B45F")] = (GetDecimal -Hex "0x3F")
            $ByteArray[(GetDecimal -Hex "0xE2B460")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B461")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B462")] = 0
            $ByteArray[(GetDecimal -Hex "0xE2B463")] = 0
        }

        if ($ReturnChildOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xCB6844")] = (GetDecimal -Hex "0x35")
            $ByteArray[(GetDecimal -Hex "0x253C0E2")] = 3
        }

        if ($HiresModelOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBE608B")] = 0
        }

        if ($UnlockSwordOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBC77AD")] = 9
            $ByteArray[(GetDecimal -Hex "0xBC77F7")] = 9
        }

        if ($UnlockTunicsOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBC77B6")] = 9
            $ByteArray[(GetDecimal -Hex "0xBC77B7")] = 9

            $ByteArray[(GetDecimal -Hex "0xBC77FE")] = 9
            $ByteArray[(GetDecimal -Hex "0xBC77FF")] = 9
        }

        if ($UnlockBootsOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBC77BA")] = 9
            $ByteArray[(GetDecimal -Hex "0xBC77BB")] = 9

            $ByteArray[(GetDecimal -Hex "0xBC7801")] = 9
            $ByteArray[(GetDecimal -Hex "0xBC7802")] = 9
        }

        if ($DisableLowHPSoundOoT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xADBA1A")] = 0
            $ByteArray[(GetDecimal -Hex "0xADBA1B")] = 0
        }

        if ($DisableNaviooT.Checked) {
            $ByteArray[(GetDecimal -Hex "0xDF8B84")] = 0
            $ByteArray[(GetDecimal -Hex "0xDF8B85")] = 0
            $ByteArray[(GetDecimal -Hex "0xDF8B86")] = 0
            $ByteArray[(GetDecimal -Hex "0xDF8B87")] = 0
        }

        if ($HideDPadOOT.Checked) {
            $ByteArray[(GetDecimal -Hex "0x348086E")] = (GetDecimal -Hex "0x00")
        }

    }

    elseif ($GameType -eq "Majora's Mask") {
        
        # HERO MODE #

        if ($OHKOModeMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBABE7F")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0xBABE8F")] = (GetDecimal -Hex "0x04")
            $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x2A")
            $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xBABEA5")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xBABEA6")] = (GetDecimal -Hex "0x00")
            $ByteArray[(GetDecimal -Hex "0xBABEA7")] = (GetDecimal -Hex "0x00")
        }
        elseif (!$1xDamageMM.Checked -and !$NormalRecoveryMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBABE7F")] = (GetDecimal -Hex "0x09")
            $ByteArray[(GetDecimal -Hex "0xBABE8F")] = (GetDecimal -Hex "0x04")
            if ($NormalRecoveryMM.Checked) {
                $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                if ($2xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x40")
                }
                elseif ($4xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x80")
                }
                elseif ($8xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0xC0")
                }
                $ByteArray[(GetDecimal -Hex "0xBABEA5")] = (GetDecimal -Hex "0x00")
                $ByteArray[(GetDecimal -Hex "0xBABEA6")] = (GetDecimal -Hex "0x00")
                $ByteArray[(GetDecimal -Hex "0xBABEA7")] = (GetDecimal -Hex "0x00")
            }
            elseif ($HalfRecoveryMM.Checked) {
                if ($1xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x40")
                }
                elseif ($2xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x80")
                }
                elseif ($4xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($8xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x00")
                }
                $ByteArray[(GetDecimal -Hex "0xBABEA5")] = (GetDecimal -Hex "0x05")
                $ByteArray[(GetDecimal -Hex "0xBABEA6")] = (GetDecimal -Hex "0x28")
                $ByteArray[(GetDecimal -Hex "0xBABEA7")] = (GetDecimal -Hex "0x43")
            }
            elseif ($QuarterRecoveryMM.Checked) {
                if ($1xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x80")
                }
                elseif ($2xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x28")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($4xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x00")
                }
                elseif ($8xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x40")
                }
                $ByteArray[(GetDecimal -Hex "0xBABEA5")] = (GetDecimal -Hex "0x05")
                $ByteArray[(GetDecimal -Hex "0xBABEA6")] = (GetDecimal -Hex "0x28")
                $ByteArray[(GetDecimal -Hex "0xBABEA7")] = (GetDecimal -Hex "0x83")
            }
            elseif ($NoRecoveryMM.Checked) {
                if ($1xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x40")
                }
                elseif ($2xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x80")
                }
                elseif ($4xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x29")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0xC0")
                }
                elseif ($8xDamageMM.Checked) {
                    $ByteArray[(GetDecimal -Hex "0xBABEA2")] = (GetDecimal -Hex "0x2A")
                    $ByteArray[(GetDecimal -Hex "0xBABEA3")] = (GetDecimal -Hex "0x00")
                }
                $ByteArray[(GetDecimal -Hex "0xBABEA5")] = (GetDecimal -Hex "0x05")
                $ByteArray[(GetDecimal -Hex "0xBABEA6")] = (GetDecimal -Hex "0x29")
                $ByteArray[(GetDecimal -Hex "0xBABEA7")] = (GetDecimal -Hex "0x43")
            }
        }

        if ($ExtendedDrawMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0xB50874")] = 0
            $ByteArray[(GetDecimal -Hex "0xB50875")] = 0
            $ByteArray[(GetDecimal -Hex "0xB50876")] = 0
            $ByteArray[(GetDecimal -Hex "0xB50877")] = 0
        }

        if ($LeftDPadMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0x3806365")] = 1
        }
        elseif ($HideDPadMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0x3806365")] = 0
        }

        if ($RazorSwordMM.Checked) {
            # Prevent losing hits
            $ByteArray[(GetDecimal -Hex "0xCBA496")] = 0
            $ByteArray[(GetDecimal -Hex "0xCBA497")] = 0

            # Keep sword after Song of Time
            $ByteArray[(GetDecimal -Hex "0xBDA6B7")] = 1
        }

        if ($DisableLowHPSoundMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0xB97E2A")] = 0
            $ByteArray[(GetDecimal -Hex "0xB97E2B")] = 0
        }

        if ($PieceOfHeartSoundMM.Checked) {
            $ByteArray[(GetDecimal -Hex "0xBA94C8")] = (GetDecimal -Hex "0x10")
            $ByteArray[(GetDecimal -Hex "0xBA94C9")] = (GetDecimal -Hex "0x00")
        }

    }

    [io.file]::WriteAllBytes($OutputROMFile, $ByteArray)

    if ($IsWiiVC) {
        & $Files.Compress $OutputROMFile $ROMFile # | Out-Host
    }
    else {
        & $Files.Compress $OutputROMFile $Z64File.Patched # | Out-Host
    }

    Remove-Item $OutputROMFile

}



#==============================================================================================================================================================================================
function ExtendROM() {
    
    if ($GameType -eq "Majora's Mask") {
        $Bytes = @(08, 00, 00, 00)
        $ByteArray = [IO.File]::ReadAllBytes($ROMFile)
        [io.file]::WriteAllBytes($ROMFile, $Bytes + $ByteArray)
    }

}



#==============================================================================================================================================================================================
function CheckGameID() {
    
    # Return if freely patching
    if ($GameType -eq "Free") {
        return
    }

    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Checking GameID in .tmd...'

    # Get the ".tmd" file as a byte array.
    $ByteArray = [IO.File]::ReadAllBytes($WadFile.tmd)
    
    $global:ContinuePatching = $true
    $CompareArray = $null

    if ($GameType -eq "Ocarina of Time") {
        $CompareArray = @(78, 65, 67, 69)
    }
    elseif ($GameType -eq "Majora's Mask") {
        $CompareArray = @(78, 65, 82, 69)
    }
    elseif ($GameType -eq "Super Mario 64") {
        $CompareArray = @(78, 65, 65, 69)
    }
    elseif ($GameType -eq "Paper Mario 64") {
        $CompareArray = @(78, 65, 69, 69)
    }

    $CompareAgainst = $ByteArray[400..(403)]

    # Check each value of the array.
    for ($i=0; $i-le 4; $i++) {
        # The current values do not match
        if ($CompareArray[$i] -ne $CompareAgainst[$i]) {
            # This is not a "NACE", "NARE", "NAAE" or "NAEE" entry.
            $global:ContinuePatching = $false
            UpdateStatusLabelDuringPatching -Text ('Failed! This is not an vanilla ' + $GameType + ' USA VC WAD file.')
            # Stop wasting time.
            break
        }
    }

}



#==============================================================================================================================================================================================
function SetCustomGameID() {
    
    if (!$InputCustomGameIDCheckbox.Checked) {
        return
    }

    if ($InputCustomGameIDTextbox.TextLength -eq 4) {
        $GameID = $InputCustomGameIDTextBox.Text
    }

    if ($InputCustomChannelTitleTextBox.TextLength -gt 0 -and $GameType -ne "Free") {
        $ChannelTitle = $InputCustomChannelTitleTextBox.Text
    }

}



#==============================================================================================================================================================================================
function HackOpeningBNRTitle() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Hacking in Opening.bnr custom title...'

    # Get the "00000000.app" file as a byte array.
    $ByteArray = [IO.File]::ReadAllBytes($WadFile.AppFile00)

    # Initially assume the two chunks of data are identical.
    $Identical = $true

    $Start = 0

    # Scan only the contents of the IMET header within the file.
    for ($i=128; $i-lt 1583; $i++) {
        # Search each byte for hex 5A (90 decimal) which is a capital "Z".
        if ($ByteArray[$i] -eq 90 -and $GameType -eq "Ocarina of Time") {
            
            # This actually spells "Zelda: Ocarina" in a weird way. It will be used to find matches.
            $CompareArray = @(90, 00, 101, 00, 108, 00, 100, 00, 97, 00, 58, 00, 32, 00, 79, 00, 99, 00, 97, 00, 114, 00, 105, 00, 110, 00, 97)

            # Grab a chunk of the header starting with the byte matching "Z".
            $CompareAgainst = $ByteArray[$i..($i+26)]
            
            # Check each value of the array.
            for ($z=0; $z-le $CompareAgainst.Length; $z++) {
                # The current values do not match.
                if ($CompareArray[$z] -ne $CompareAgainst[$z]) {
                    # This is not a "Zelda: Ocarina" entry.
                    $Identical = $false
                    break
                }
            }

            if ($Identical = $false) {
                return
            }

            if ($ByteArray[$i-2] -eq 00) {
                $Start = $i
            }

            for ($j=0; $j-lt $ChannelTitleLength; $j++) {
                $ByteArray[$Start + ($j*2)] = 00
            }

            for ($j=0; $j-lt $ChannelTitle.Length; $j++) {
                $Dec = [int][char]$ChannelTitle.Substring($j, 1)
                $ByteArray[$Start + ($j*2)] = $Dec
            }

            # Overwrite the patch file with the extended file.
            [IO.File]::WriteAllBytes($WadFile.AppFile00, $ByteArray)

        }

        # Search each byte for hex 5A (90 decimal) which is a capital "Z".
        elseif ($ByteArray[$i] -eq 90 -and $GameType -eq "Majora's Mask") {
            
            # This actually spells "Zelda: Majora's" in a weird way. It will be used to find matches.
            $CompareArray = @(90, 00, 101, 00, 108, 00, 100, 00, 97, 00, 58, 00, 32, 00, 77, 00, 97, 00, 106, 00, 111, 00, 114, 00, 97, 00, 39, 00, 115)

            # Grab a chunk of the header starting with the byte matching "Z".
            $CompareAgainst = $ByteArray[$i..($i+28)]

            # Check each value of the array.
            for ($z=0; $z-le $CompareAgainst.Length; $z++) {
                # The current values do not match.
                if ($CompareArray[$z] -ne $CompareAgainst[$z]) {
                    # This is not a "Zelda: Majora's" entry.
                    $Identical = $false
                    break
                }
            }

            if ($Identical = $false) {
                return
            }

            if ($ByteArray[$i-2] -eq 00) {
                $Start = $i
            }

            for ($j=0; $j-lt $ChannelTitleLength; $j++) {
                $ByteArray[$Start + ($j*2)] = 00
            }

            for ($j=0; $j-lt $ChannelTitle.Length; $j++) {
                $Dec = [int][char]$ChannelTitle.Substring($j, 1)
                $ByteArray[$Start + ($j*2)] = $Dec
            }

            # Overwrite the patch file with the extended file.
            [IO.File]::WriteAllBytes($WadFile.AppFile00, $ByteArray)

        }

        # Search each byte for hex 53 (83 decimal) which is a capital "S".
        elseif ($ByteArray[$i] -eq 83 -and $GameType -eq "Super Mario 64") {
            
            # This actually spells "Super Mario 64" in a weird way. It will be used to find matches.
            $CompareArray = @(83, 00, 117, 00, 112, 00, 101, 00, 114, 00, 32, 00, 77, 00, 97, 00, 114, 00, 105, 00, 111, 00, 32, 00, 54, 00, 52)

            # Grab a chunk of the header starting with the byte matching "S".
            $CompareAgainst = $ByteArray[$i..($i+26)]

            # Check each value of the array.
            for ($z=0; $z-le $CompareAgainst.Length; $z++) {
                # The current values do not match.
                if ($CompareArray[$z] -ne $CompareAgainst[$z]) {
                    # This is not a "Super Mario 64" entry.
                    $Identical = $false
                    break
                }
            }

            if ($Identical = $false) {
                return
            }

            if ($ByteArray[$i-2] -eq 00) {
                $Start = $i
            }

            for ($j=0; $j-lt $ChannelTitleLength; $j++) {
                $ByteArray[$Start + ($j*2)] = 00
            }

            for ($j=0; $j-lt $ChannelTitle.Length; $j++) {
                $Dec = [int][char]$ChannelTitle.Substring($j, 1)
                $ByteArray[$Start + ($j*2)] = $Dec
            }

            # Overwrite the patch file with the extended file.
            [IO.File]::WriteAllBytes($WadFile.AppFile00, $ByteArray)

        }

        # Search each byte for hex 50 (80 decimal) which is a capital "P".
        elseif ($ByteArray[$i] -eq 80 -and $GameType -eq "Paper Mario") {
            
            # This actually spells "Paper Mario" in a weird way. It will be used to find matches.
            $CompareArray = @(80, 00, 97, 00, 112, 00, 101, 00, 114, 00, 32, 00, 77, 00, 97, 00, 114, 00, 105, 00, 111)

            # Grab a chunk of the header starting with the byte matching "P".
            $CompareAgainst = $ByteArray[$i..($i+20)]

            # Check each value of the array.
            for ($z=0; $z-le $CompareAgainst.Length; $z++) {
                # The current values do not match.
                if ($CompareArray[$z] -ne $CompareAgainst[$z]) {
                    # This is not a "Paper Mario" entry.
                    $Identical = $false
                    break
                }
            }

            if ($Identical = $false) {
                return
            }

            if ($ByteArray[$i-2] -eq 00) {
                $Start = $i
            }

            for ($j=0; $j-lt $ChannelTitleLength; $j++) {
                $ByteArray[$Start + ($j*2)] = 00
            }

            for ($j=0; $j-lt $ChannelTitle.Length; $j++) {
                $Dec = [int][char]$ChannelTitle.Substring($j, 1)
                $ByteArray[$Start + ($j*2)] = $Dec
            }

            # Overwrite the patch file with the extended file.
            [IO.File]::WriteAllBytes($WadFile.AppFile00, $ByteArray)

        }

    }

}



#==============================================================================================================================================================================================
function RepackU8AppFile() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Repacking "00000005.app" file...'

    # Remove the original app file as its going to be replaced.
    RemovePath -LiteralPath $WadFile.AppFile05

    # Repack the file using wszst.
    & $Files.wszst 'C' $WadFile.AppPath05 '-d' $WadFile.AppFile05 # | Out-Host

    # Get the file as a byte array.
    $AppByteArray = [IO.File]::ReadAllBytes($WadFile.AppFile05)

    # Overwrite the values in 0x10 with zeroes. I don't know why, I'm just matching the output from another program.
    for ($i = 16 ; $i -le 31 ; $i++) { $AppByteArray[$i] = 0 }

    # Overwrite the patch file with the extended file.
    [IO.File]::WriteAllBytes($WadFile.AppFile05, $AppByteArray)
    
    # Remove the extracted WAD folder.
    RemovePath -LiteralPath $WadFile.AppPath05

}



#==============================================================================================================================================================================================
function RepackWADFile() {
    
    # Set the status label.
    UpdateStatusLabelDuringPatching -Text 'Repacking patched WAD file...'
    
    # Loop through all files in the extracted WAD folder.
    foreach($File in Get-ChildItem -LiteralPath $WadFile.Folder -Force) {
        # Move the file to the same folder as the unpacker tool.
        Move-Item -LiteralPath $File.FullName -Destination $MasterPath
        
        # Create an entry for the database.
        $ListEntry = $MasterPath + '\' + $File.Name
        
        # Some files need to be fed into the tool so keep track of them.
        switch ($File.Extension) {
            '.tik'  { $tik  = $MasterPath + '\' + $File.Name }
            '.tmd'  { $tmd  = $MasterPath + '\' + $File.Name }
            '.cert' { $cert = $MasterPath + '\' + $File.Name }
        }
    }

    # We need to be in the same path as some files so just jump there.
    Push-Location $MasterPath

    # Repack the WAD using the new files.
    & $Files.wadpacker $tik $tmd $cert $WadFile.Patched '-sign' '-i' $GameID

    # If the patched file was created.
    if (TestPath -LiteralPath $WadFile.Patched) {
        # Play a sound when it is finished.
        [Media.SystemSounds]::Beep.Play()
  
        # Set the status label.
        UpdateStatusLabelDuringPatching -Text 'Complete! File successfully patched.'
    }
    # If the patched file failed to be created, set the status label to failed.
    elseif ($IsWiiVC) {
        UpdateStatusLabelDuringPatching -Text 'Failed! Patched Wii VC WAD was not created.'
    }
    else {
        UpdateStatusLabelDuringPatching -Text 'Failed! Nintendo 64 ROM was not patched.'
    }

    # Remove the folder the extracted files were in.
    RemovePath -LiteralPath $WadFile.Folder

    # Doesn't matter, but return to where we were.
    Pop-Location

}



#==================================================================================================================================================================================================================================================================
function WADPath_Finish([object]$TextBox, [string]$VarName, [string]$WADPath) {
    
    # Set the "GameWAD" variable that tracks the path.
    Set-Variable -Name $VarName -Value $WADPath -Scope 'Global'
    $global:WADFilePath =  $WADPath

    # Update the textbox to the current WAD.
    $TextBox.Text = $WADPath

    EnablePatchButtons -Enable $true

    # Check if both a .WAD and .Z64 have been provided for ROM injection
    if ($global:Z64FilePath -ne $null) {
        $InjectROMButton.Enabled = $true
    }

    # Check if both a .WAD and .BPS have been provided for BPS patching
    if ($global:BPSFilePath -ne $null) {
        $PatchBPSButton.Enabled = $true
    }

}



#==================================================================================================================================================================================================================================================================
function EnablePatchButtons([boolean]$Enable) {
    
    # Set the status that we are ready to roll... Or not...
    if ($Enable) {
        $StatusLabel.Text = 'Ready to patch!'
    }
    elseif ($IsWiiVC) {
        $StatusLabel.Text = 'Select your Virtual Console WAD file to continue.'
    }
    else {
        $StatusLabel.Text = 'Select your Nintendo 64 ROM file to continue.'
        
    }

    if ($IsWiiVC) { $InjectROMButton.Enabled = ($WADFilePath -ne $null -and $Z64FilePath -ne $null) }
    if ($IsWiiVC) { $PatchBPSButton.Enabled = ($WADFilePath -ne $null -and $BPSFilePath -ne $null) } else { $PatchBPSButton.Enabled = ($Z64FilePath -ne $null -and $BPSFilePath -ne $null) }
    
    # Enable patcher buttons.
    $PatchOoTReduxButton.Enabled = $Enable
    $PatchOoTReduxOptionsButton.Enabled = $Enable
    $PatchOoTDawnButton.Enabled = $Enable
    $PatchOoTSpaButton.Enabled = $Enable
    $PatchOoTPolButton.Enabled = $Enable
    $PatchOoTRusButton.Enabled = $Enable
    $PatchOoTChiButton.Enabled = $Enable

    $PatchMMReduxButton.Enabled = $bool
    $PatchMMReduxOptionsButton.Enabled = $Enable
    $PatchMMMaskedQuestButton.Enabled = $Enable
    $PatchMMPolButton.Enabled = $Enable
    $PatchMMRusButton.Enabled = $Enable

    $PatchSM64FPSButton.Enabled = $Enable
    $PatchSM64CamButton.Enabled = $Enable
    $PatchSM64MultiplayerButton.Enabled = $Enable

    $PatchPPHardMode.Enabled = $Enable
    $PatchPPHardModePlus.Enabled = $Enable
    $PatchPPInsaneMode.Enabled = $Enable

    # Enable ROM extract
    $ExtractROMButton.Enabled = $Enable

    

}



#==================================================================================================================================================================================================================================================================
function Z64Path_Finish([object]$TextBox, [string]$VarName, [string]$Z64Path) {
    
    # Set the "Z64 ROM" variable that tracks the path.
    Set-Variable -Name $VarName -Value $Z64Path -Scope 'Global'
    $global:Z64FilePath =  $Z64Path

    # Update the textbox to the current WAD.
    $TextBox.Text = $Z64Path

    if (!$IsWiiVC) {
        EnablePatchButtons -Enable $true
    }
    
    # Check if both a .WAD and .Z64 have been provided for ROM injection
    if ($WADFilePath -ne $null -and $IsWiiVC) {
        $InjectROMButton.Enabled = $true
    }

    # Check if both a .Z64 and .BPS have been provided for BPS patching
    elseif ($BPSFilePath -ne $null -and !$IsWiiVC) {
        $PatchBPSButton.Enabled = $true
    }

}



#==================================================================================================================================================================================================================================================================
function BPSPath_Finish([object]$TextBox, [string]$VarName, [string]$BPSPath) {
    
    # Set the "BPS File" variable that tracks the path.
    Set-Variable -Name $VarName -Value $BPSPath -Scope 'Global'
    $global:BPSFilePath =  $BPSPath

    # Update the textbox to the current WAD.
    $TextBox.Text = $BPSPath

    # Check if both a .WAD and .BPS have been provided for BPS patching
    if ($WADFilePath -ne $null -and $IsWiiVC) {
        $PatchBPSButton.Enabled = $true
    }
    elseif ($Z64FilePath -ne $null -and !$IsWiiVC) {
        $PatchBPSButton.Enabled = $true
    }

}



#==================================================================================================================================================================================================================================================================
function WADPath_DragDrop() {
    
    # Check for drag and drop data.
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # Get the first item in the list.
        $DroppedPath = [string]($_.Data.GetData([Windows.Forms.DataFormats]::FileDrop))
        
        # See if the dropped item is a file.
        if (Test-Path -LiteralPath $DroppedPath -PathType Leaf) {
            # Get the extension of the dropped file.
            $DroppedExtn = (Get-Item -LiteralPath $DroppedPath).Extension

            # Make sure it is a WAD file.
            if ($DroppedExtn -eq '.wad') {
                # Finish everything up.
                WADPath_Finish -TextBox $InputWADTextBox -VarName $this.Name -WADPath $DroppedPath
            }
        }
    }

}



#==================================================================================================================================================================================================================================================================
function Z64Path_DragDrop() {
    
    # Check for drag and drop data.
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # Get the first item in the list.
        $DroppedPath = [string]($_.Data.GetData([Windows.Forms.DataFormats]::FileDrop))
        
        # See if the dropped item is a file.
        if (Test-Path -LiteralPath $DroppedPath -PathType Leaf) {
            # Get the extension of the dropped file.
            $DroppedExtn = (Get-Item -LiteralPath $DroppedPath).Extension

            # Make sure it is a Z64 ROM.
            if ($DroppedExtn -eq '.z64' -or $DroppedExtn -eq '.n64' -or $DroppedExtn -eq '.v64') {
                # Finish everything up.
                Z64Path_Finish -TextBox $InputROMTextBox -VarName $this.Name -Z64Path $DroppedPath
            }
        }
    }

}



#==================================================================================================================================================================================================================================================================
function BPSPath_DragDrop() {
    
    # Check for drag and drop data.
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # Get the first item in the list.
        $DroppedPath = [string]($_.Data.GetData([Windows.Forms.DataFormats]::FileDrop))
        
        # See if the dropped item is a file.
        if (Test-Path -LiteralPath $DroppedPath -PathType Leaf) {
            # Get the extension of the dropped file.
            $DroppedExtn = (Get-Item -LiteralPath $DroppedPath).Extension

            # Make sure it is a BPS File.
            if ($DroppedExtn -eq '.bps' -or $DroppedExtn -eq '.ips') {
                # Finish everything up.
                BPSPath_Finish -TextBox $InputBPSTextBox -VarName $this.Name -BPSPath $DroppedPath
            }
        }
    }

}



#==================================================================================================================================================================================================================================================================
function WADPath_Button([object]$TextBox, [string[]]$Description, [string[]]$FileName) {
        # Allow the user to select a file.
    $SelectedPath = Get-FileName -Path $BasePath -Description $Description -FileName $FileName

    # Make sure the path is not blank and also test that the path exists.
    if (($SelectedPath -ne '') -and (TestPath -LiteralPath $SelectedPath)) {
        # Finish everything up.
        WADPath_Finish -TextBox $TextBox -VarName $this.Name -WADPath $SelectedPath
    }

}



#==================================================================================================================================================================================================================================================================
function Z64Path_Button([object]$TextBox, [string[]]$Description, [string[]]$FileName) {
        # Allow the user to select a file.
    $SelectedPath = Get-FileName -Path $BasePath -Description $Description -FileName $FileName

    # Make sure the path is not blank and also test that the path exists.
    if (($SelectedPath -ne '') -and (TestPath -LiteralPath $SelectedPath)) {
        # Finish everything up.
        Z64Path_Finish -TextBox $TextBox -VarName $this.Name -Z64Path $SelectedPath
    }

}



#==================================================================================================================================================================================================================================================================
function BPSPath_Button([object]$TextBox, [string[]]$Description, [string[]]$FileName) {
        # Allow the user to select a file.
    $SelectedPath = Get-FileName -Path $BasePath -Description $Description -FileName $FileName

    # Make sure the path is not blank and also test that the path exists.
    if (($SelectedPath -ne '') -and (TestPath -LiteralPath $SelectedPath)) {
        # Finish everything up.
        BPSPath_Finish -TextBox $TextBox -VarName $this.Name -BPSPath $SelectedPath
    }

}



#==================================================================================================================================================================================================================================================================
function GetDecimal([string]$Hex) {
    
    $decimal = [uint32]$hex
    return $decimal

}



#==============================================================================================================================================================================================
function CreateMainDialog() {

    # Create the main dialog that is shown to the user.
    $global:MainDialog = New-Object System.Windows.Forms.Form
    $MainDialog.Text = $ScriptName
    $MainDialog.Size = New-Object System.Drawing.Size(625, 745)
    $MainDialog.MaximizeBox = $false
    $MainDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    $MainDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MainDialog.StartPosition = "CenterScreen"
    $MainDialog.KeyPreview = $true
    $MainDialog.Add_Shown({ $MainDialog.Activate() })
    $MainDialog.Icon = $VIcon

    
    # Create Tooltip
    $ToolTip = new-Object System.Windows.Forms.ToolTip
    $ToolTip.AutoPopDelay = 32767
    $ToolTip.InitialDelay = 500
    $ToolTip.ReshowDelay = 0
    $ToolTip.ShowAlways = $true



    ##############
    # Main Panel #
    ##############

    # Create a label to show current mode.
    $global:CurrentModeLabel = New-Object System.Windows.Forms.Label
    $CurrentModeLabel.AutoSize = $true
    $CurrentModeLabel.Font = $CurrentModeFont
    $MainDialog.Controls.Add($CurrentModeLabel)

    # Create a label to show current version.
    $global:VersionLabel = New-Object System.Windows.Forms.Label
    $VersionLabel.Size = New-Object System.Drawing.Size(120, 20)
    $VersionLabel.Location = New-Object System.Drawing.Size(15, 10)
    $VersionLabel.Text = "Version: " + $Version
    $VersionLabel.Font = $VCPatchFont
    $MainDialog.Controls.Add($VersionLabel)



    ############
    # WAD Path #
    ############

    # Create the panel that holds the WAD path.
    $global:InputWADPanel = New-Object System.Windows.Forms.Panel
    $InputWADPanel.Size = New-Object System.Drawing.Size(590, 50)
    $MainDialog.Controls.Add($InputWADPanel)

    # Create the groupbox that holds the WAD path.
    $global:InputWADGroup = New-Object System.Windows.Forms.GroupBox
    $InputWADGroup.Name = 'GameWAD'
    $InputWADGroup.Size = New-Object System.Drawing.Size($InputWADPanel.Width, $InputWADPanel.Height)
    $InputWADGroup.Location = New-Object System.Drawing.Size(0, 0)
    $InputWADGroup.Text = " WAD Path "
    $InputWADGroup.AllowDrop = $true
    $InputWADGroup.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputWADGroup.Add_DragDrop({ WADPath_DragDrop })
    $InputWADPanel.Controls.Add($InputWADGroup)

    # Create a textbox to display the selected WAD.
    $global:InputWADTextBox = New-Object System.Windows.Forms.TextBox
    $InputWADTextBox.Name = 'GameWAD'
    $InputWADTextBox.Size = New-Object System.Drawing.Size(540, 22)
    $InputWADTextBox.Location = New-Object System.Drawing.Size(10, 20)
    $InputWADTextBox.Text = "Select or drag and drop your Virtual Console WAD file..."
    $InputWADTextBox.AllowDrop = $true
    $InputWADTextBox.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputWADTextBox.Add_DragDrop({ WADPath_DragDrop })
    $InputWADGroup.Controls.Add($InputWADTextBox)

    # Create a button to allow manually selecting a WAD.
    $global:InputWADButton = New-Object System.Windows.Forms.Button
    $InputWADButton.Name = 'GameWAD'
    $InputWADButton.Size = New-Object System.Drawing.Size(24, 22)
    $InputWADButton.Location = New-Object System.Drawing.Size(556, 18)
    $InputWADButton.Text = "..."
    $InputWADButton.Add_Click({ WADPath_Button -TextBox $InputWADTextBox -Description 'VC WAD File' -FileName '*.wad' })
    $InputWADGroup.Controls.Add($InputWADButton)
    $ToolTip.SetToolTip($InputWADButton, "Select your VC WAD File using file explorer")



    ############
    # ROM Path #
    ############

    # Create the panel that holds the ROM path.
    $global:InputROMPanel = New-Object System.Windows.Forms.Panel
    $InputROMPanel.Size = New-Object System.Drawing.Size(590, 50)
    $MainDialog.Controls.Add($InputROMPanel)

    # Create the groupbox that holds the ROM path.
    $InputROMGroup = New-Object System.Windows.Forms.GroupBox
    $InputROMGroup.Name = 'GameZ64'
    $InputROMGroup.Size = New-Object System.Drawing.Size($InputROMPanel.Width, $InputROMPanel.Height)
    $InputROMGroup.Location = New-Object System.Drawing.Size(0, 0)
    $InputROMGroup.Text = " ROM Path "
    $InputROMGroup.AllowDrop = $true
    $InputROMGroup.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputROMGroup.Add_DragDrop({ Z64Path_DragDrop })
    $InputROMPanel.Controls.Add($InputROMGroup)

    # Create a textbox to display the selected ROM.
    $global:InputROMTextBox = New-Object System.Windows.Forms.TextBox
    $InputROMTextBox.Name = 'GameZ64'
    $InputROMTextBox.Size = New-Object System.Drawing.Size(440, 22)
    $InputROMTextBox.Location = New-Object System.Drawing.Size(10, 20)
    $InputROMTextBox.Text = "Select or drag and drop your Z64, N64 or V64 ROM..."
    $InputROMTextBox.AllowDrop = $true
    $InputROMTextBox.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputROMTextBox.Add_DragDrop({ Z64Path_DragDrop })
    $InputROMGroup.Controls.Add($InputROMTextBox)

    # Create a button to allow manually selecting a ROM.
    $global:InputROMButton = New-Object System.Windows.Forms.Button
    $InputROMButton.Name = 'GameZ64'
    $InputROMButton.Size = New-Object System.Drawing.Size(24, 22)
    $InputROMButton.Location = New-Object System.Drawing.Size(456, 18)
    $InputROMButton.Text = "..."
    $InputROMButton.Add_Click({ z64Path_Button -TextBox $InputROMTextBox -Description @('Z64 ROM', 'N64 ROM', 'V64 ROM') -FileName @('*.z64', '*.n64', '*.v64') })
    $InputROMGroup.Controls.Add($InputROMButton)
    $ToolTip.SetToolTip($InputROMButton, "Select your Z64, N64 or V64 ROM File using file explorer")
    
    # Create a button to allow patch the WAD with a ROM file.
    $global:InjectROMButton = New-Object System.Windows.Forms.Button
    $InjectROMButton.Size = New-Object System.Drawing.Size(80, 22)
    $InjectROMButton.Location = New-Object System.Drawing.Size(495, 18)
    $InjectROMButton.Text = "Inject ROM"
    $InjectROMButton.Add_Click({ MainFunctionInjectROM })
    $InputROMGroup.Controls.Add($InjectROMButton)
    $ToolTip.SetToolTip($InjectROMButton, "Replace the ROM in your selected WAD File with your selected Z64, N64 or V64 ROM File")
    


    ############
    # BPS Path #
    ############
    
    # Create the panel that holds the BPS path.
    $global:InputBPSPanel = New-Object System.Windows.Forms.Panel
    $InputBPSPanel.Size = New-Object System.Drawing.Size(590, 50)
    $MainDialog.Controls.Add($InputBPSPanel)

    # Create the groupbox that holds the BPS path.
    $InputBPSGroup = New-Object System.Windows.Forms.GroupBox
    $InputBPSGroup.Name = 'GameBPS'
    $InputBPSGroup.Size = New-Object System.Drawing.Size($InputBPSPanel.Width, $InputBPSPanel.Height)
    $InputBPSGroup.Location = New-Object System.Drawing.Size(0, 0)
    $InputBPSGroup.Text = " BPS Path "
    $InputBPSGroup.AllowDrop = $true
    $InputBPSGroup.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputBPSGroup.Add_DragDrop({ BPSPath_DragDrop })
    $InputBPSPanel.Controls.Add($InputBPSGroup)
    
    # Create a textbox to display the selected BPS.
    $global:InputBPSTextBox = New-Object System.Windows.Forms.TextBox
    $InputBPSTextBox.Name = 'GameBPS'
    $InputBPSTextBox.Size = New-Object System.Drawing.Size(440, 22)
    $InputBPSTextBox.Location = New-Object System.Drawing.Size(10, 20)
    $InputBPSTextBox.Text = "Select or drag and drop your BPS or IPS Patch File..."
    $InputBPSTextBox.AllowDrop = $true
    $InputBPSTextBox.Add_DragEnter({ $_.Effect = [Windows.Forms.DragDropEffects]::Copy })
    $InputBPSTextBox.Add_DragDrop({ BPSPath_DragDrop })
    $InputBPSGroup.Controls.Add($InputBPSTextBox)

    # Create a button to allow manually selecting a ROM.
    $global:InputBPSButton = New-Object System.Windows.Forms.Button
    $InputBPSButton.Name = 'GameBPS'
    $InputBPSButton.Size = New-Object System.Drawing.Size(24, 22)
    $InputBPSButton.Location = New-Object System.Drawing.Size(456, 18)
    $InputBPSButton.Text = "..."
    $InputBPSButton.Add_Click({ BPSPath_Button -TextBox $InputBPSTextBox -Description @('BPS Patch File', 'IPS Patch File') -FileName @('*.bps', '*.ips') })
    $InputBPSGroup.Controls.Add($InputBPSButton)
    $ToolTip.SetToolTip($InputBPSButton, "Select your BPS or IPS Patch File using file explorer")
    
    # Create a button to allow patch the WAD with a BPS file.
    $global:PatchBPSButton = New-Object System.Windows.Forms.Button
    $PatchBPSButton.Size = New-Object System.Drawing.Size(80, 22)
    $PatchBPSButton.Location = New-Object System.Drawing.Size(495, 18)
    $PatchBPSButton.Text = "Patch BPS"
    $PatchBPSButton.Add_Click({ MainFunctionBPSPatch })
    $InputBPSGroup.Controls.Add($PatchBPSButton)
    $ToolTip.SetToolTip($PatchBPSButton, "Patch your selected WAD File with your selected BPS or IPS Patch File")


    ##################
    # Custom Game ID #
    ##################

    # Create the panel that holds the Custom GameID.
    $global:CustomGameIDPanel = New-Object System.Windows.Forms.Panel
    $CustomGameIDPanel.Size = New-Object System.Drawing.Size(590, 50)
    $MainDialog.Controls.Add($CustomGameIDPanel)

    # Create the groupbox that holds the Custom GameID.
    $CustomGameIDGroup = New-Object System.Windows.Forms.GroupBox
    $CustomGameIDGroup.Name = 'CustomGameID'
    $CustomGameIDGroup.Size = New-Object System.Drawing.Size($CustomGameIDPanel.Width, $CustomGameIDPanel.Height)
    $CustomGameIDGroup.Location = New-Object System.Drawing.Size(0, 0)
    $CustomGameIDGroup.Text = " Custom Channel Title and GameID"
    $CustomGameIDPanel.Controls.Add($CustomGameIDGroup)

    # Create a label to show Custom Channel Title description.
    $global:InputCustomChannelTitleTextBoxLabel = New-Object System.Windows.Forms.Label
    $InputCustomChannelTitleTextBoxLabel.Size = New-Object System.Drawing.Size(75, 15)
    $InputCustomChannelTitleTextBoxLabel.Location = New-Object System.Drawing.Size(8, 22)
    $InputCustomChannelTitleTextBoxLabel.Text = "Channel Title:"
    $CustomGameIDGroup.Controls.Add($InputCustomChannelTitleTextBoxLabel)

    # Create a textbox to display the selected Custom Channel Title.
    $global:InputCustomChannelTitleTextBox = New-Object System.Windows.Forms.Textbox
    $InputCustomChannelTitleTextBox.Name = 'CustomGameID'
    $InputCustomChannelTitleTextBox.Size = New-Object System.Drawing.Size(260, 22)
    $InputCustomChannelTitleTextBox.Location = New-Object System.Drawing.Size(85, 20)
    $InputCustomChannelTitleTextBox.Text = "Zelda: Ocarina"
    $InputCustomChannelTitleTextBox.MaxLength = $global:ChannelTitleLength

    $InputCustomChannelTitleTextBox.Add_TextChanged({
        if ($this.Text -match "[^a-z 0-9 : - ']") {
            $cursorPos = $this.SelectionStart
            $this.Text = $this.Text -replace "[^a-z 0-9 : - ']",''
            $this.SelectionStart = $cursorPos - 1
            $this.SelectionLength = 0
        }
    })

    $CustomGameIDGroup.Controls.Add($InputCustomChannelTitleTextBox)

    # Create a label to show Custom GameID description
    $global:InputCustomGameIDTextBoxLabel = New-Object System.Windows.Forms.Label
    $InputCustomGameIDTextBoxLabel.Size = New-Object System.Drawing.Size(50, 15)
    $InputCustomGameIDTextBoxLabel.Location = New-Object System.Drawing.Size(370, 22)
    $InputCustomGameIDTextBoxLabel.Text = "GameID:"
    $CustomGameIDGroup.Controls.Add($InputCustomGameIDTextBoxLabel)

    # Create a textbox to display the selected Custom GameID.
    $global:InputCustomGameIDTextBox = New-Object System.Windows.Forms.TextBox
    $InputCustomGameIDTextBox.Name = 'CustomGameID'
    $InputCustomGameIDTextBox.Size = New-Object System.Drawing.Size(55, 22)
    $InputCustomGameIDTextBox.Location = New-Object System.Drawing.Size(425, 20)
    $InputCustomGameIDTextBox.Text = "NACE"
    $InputCustomGameIDTextBox.MaxLength = 4

    $InputCustomGameIDTextBox.Add_TextChanged({
        if ($this.Text -cmatch "[^A-Z 0-9]") {
            $this.Text = $this.Text.ToUpper() -replace "[^A-Z 0-9]",''
            $this.Select($this.Text.Length, $this.Text.Length)
        }
    })

    $CustomGameIDGroup.Controls.Add($InputCustomGameIDTextBox)

    # Create a label to show Custom GameID description
    $global:InputCustomGameIDCheckboxLabel = New-Object System.Windows.Forms.Label
    $InputCustomGameIDCheckboxLabel.Size = New-Object System.Drawing.Size(50, 15)
    $InputCustomGameIDCheckboxLabel.Location = New-Object System.Drawing.Size(510, 22)
    $InputCustomGameIDCheckboxLabel.Text = "Enable:"
    $CustomGameIDGroup.Controls.Add($InputCustomGameIDCheckboxLabel)

    # Create a checkbox to allow Custom Channel Title & GameID.
    $global:InputCustomGameIDCheckbox = New-Object System.Windows.Forms.Checkbox
    $InputCustomGameIDCheckbox.Name = 'CustomGameID'
    $InputCustomGameIDCheckbox.Size = New-Object System.Drawing.Size(20, 20)
    $InputCustomGameIDCheckbox.Location = New-Object System.Drawing.Size(560, 20)
    $CustomGameIDGroup.Controls.Add($InputCustomGameIDCheckbox)



    ###############################
    # OoT Patch Buttons (General) #
    ###############################

    # Create a panel to contain everything for SM64.
    $global:PatchOoTPanel = New-Object System.Windows.Forms.Panel
    $PatchOoTPanel.Size = New-Object System.Drawing.Size(590, 120)
    $MainDialog.Controls.Add($PatchOoTPanel)

    # Create a groupbox to show the OoT patching buttons.
    $PatchOoTGroup = New-Object System.Windows.Forms.GroupBox
    $PatchOoTGroup.Size = New-Object System.Drawing.Size($PatchOoTPanel.Width, $PatchOoTPanel.Height)
    $PatchOoTGroup.Location = New-Object System.Drawing.Size(0, 0)
    $PatchOoTGroup.Text = " Ocarina of Time - Patch Buttons "
    $PatchOoTPanel.Controls.Add($PatchOoTGroup)

    # Create a button to allow patching the WAD (OoT Redux).
    $global:PatchOoTReduxButton = New-Object System.Windows.Forms.Button
    $PatchOoTReduxButton.Size = New-Object System.Drawing.Size(80, 35)
    $PatchOoTReduxButton.Location = New-Object System.Drawing.Size(190, 25)
    $PatchOoTReduxButton.Text = "OoT Redux"
    $PatchOoTReduxButton.Add_Click({ MainFunctionOoTRedux })
    $PatchOoTGroup.Controls.Add($PatchOoTReduxButton)
    $ToolTip.SetToolTip($PatchOoTReduxButton, "A romhack that improves mechanics for Ocarina of Time`nIt includes the use of the D-Pad for additional dedicated item buttons")

    # Create a button to select additional Redux options.
    $global:PatchOoTReduxOptionsButton = New-Object System.Windows.Forms.Button
    $PatchOoTReduxOptionsButton.Size = New-Object System.Drawing.Size(20, 35)
    $PatchOoTReduxOptionsButton.Location = New-Object System.Drawing.Size($PatchOoTReduxButton.Right, $PatchOoTReduxButton.Top)
    $PatchOoTReduxOptionsButton.Text = "+"
    $PatchOoTReduxOptionsButton.Add_Click({ $OoTReduxOptionsDialog.ShowDialog() })
    $PatchOoTGroup.Controls.Add($PatchOoTReduxOptionsButton)
    $ToolTip.SetToolTip($PatchOoTReduxOptionsButton, "Toggle additional features for the Ocarina of Time REDUX romhack")

    # Create a button to allow patching the WAD (OoT Dawn and Dusk).
    $global:PatchOoTDawnButton = New-Object System.Windows.Forms.Button
    $PatchOoTDawnButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchOoTDawnButton.Location = New-Object System.Drawing.Size(($PatchOoTReduxOptionsButton.Right + 15), $PatchOoTReduxButton.Top)
    $PatchOoTDawnButton.Text = 'Dawn and Dusk'
    $PatchOoTDawnButton.Add_Click({ MainFunctionOoTDawn })
    $PatchOoTGroup.Controls.Add($PatchOoTDawnButton)
    $ToolTip.SetToolTip($PatchOoTDawnButton, "A small-sized romhack in a completely new setting")



    ###################################
    # OoT Patch Buttons (Translation) #
    ###################################

    # Create a button to allow patching the WAD (OoT Spanish).
    $global:PatchOoTSpaButton = New-Object System.Windows.Forms.Button
    $PatchOoTSpaButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchOoTSpaButton.Location = New-Object System.Drawing.Size(75, 70)
    $PatchOoTSpaButton.Text = "Spanish Translation"
    $PatchOoTSpaButton.Add_Click({ MainFunctionOoTSpa })
    $PatchOoTGroup.Controls.Add($PatchOoTSpaButton)
    $ToolTip.SetToolTip($PatchOoTSpaButton, "Spanish Fan-Translation of Ocarina of Time")

    # Create a button to allow patching the WAD (OoT Polish).
    $global:PatchOoTPolButton = New-Object System.Windows.Forms.Button
    $PatchOoTPolButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchOoTPolButton.Location = New-Object System.Drawing.Size(($PatchOoTSpaButton.Right + 15), $PatchOoTSpaButton.Top)
    $PatchOoTPolButton.Text = "Polish Translation"
    $PatchOoTPolButton.Add_Click({ MainFunctionOoTPol })
    $PatchOoTGroup.Controls.Add($PatchOoTPolButton)
    $ToolTip.SetToolTip($PatchOoTPolButton, "Polish Fan-Translation of Ocarina of Time")

    # Create a button to allow patching the WAD (OoT Russian).
    $global:PatchOoTRusButton = New-Object System.Windows.Forms.Button
    $PatchOoTRusButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchOoTRusButton.Location = New-Object System.Drawing.Size(($PatchOoTPolButton.Right + 15), $PatchOoTSpaButton.Top)
    $PatchOoTRusButton.Text = "Russian Translation"
    $PatchOoTRusButton.Add_Click({ MainFunctionOoTRus })
    $PatchOoTGroup.Controls.Add($PatchOoTRusButton)
    $ToolTip.SetToolTip($PatchOoTRusButton, "Russian Fan-Translation of Ocarina of Time")

    # Create a button to allow patching the WAD (OoT Chinese Simplified).
    $global:PatchOoTChiButton = New-Object System.Windows.Forms.Button
    $PatchOoTChiButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchOoTChiButton.Location = New-Object System.Drawing.Size(($PatchOoTRusButton.Right + 15), $PatchOoTSpaButton.Top)
    $PatchOoTChiButton.Text = "Chinese Translation"
    $PatchOoTChiButton.Add_Click({ MainFunctionOoTChi })
    $PatchOoTGroup.Controls.Add($PatchOoTChiButton)
    $ToolTip.SetToolTip($PatchOoTChiButton, "Chinese Fan-Translation of Ocarina of Time")


    
    ##############################
    # MM Patch Buttons (General) #
    ##############################

    # Create a panel to contain everything for SM64.
    $global:PatchMMPanel = New-Object System.Windows.Forms.Panel
    $PatchMMPanel.Size = New-Object System.Drawing.Size(590, 120)
    $MainDialog.Controls.Add($PatchMMPanel)

    # Create a groupbox to show the MM patching buttons.
    $PatchMMGroup = New-Object System.Windows.Forms.GroupBox
    $PatchMMGroup.Size = New-Object System.Drawing.Size($PatchMMPanel.Width, $PatchMMPanel.Height)
    $PatchMMGroup.Location = New-Object System.Drawing.Size(0, 0)
    $PatchMMGroup.Text = " Majora's Mask - Patch Buttons "
    $PatchMMPanel.Controls.Add($PatchMMGroup)

    # Create a button to allow patching the WAD (MM Redux).
    $global:PatchMMReduxButton = New-Object System.Windows.Forms.Button
    $PatchMMReduxButton.Size = New-Object System.Drawing.Size(80, 35)
    $PatchMMReduxButton.Location = New-Object System.Drawing.Size(190, 25)
    $PatchMMReduxButton.Text = "MM Redux"
    $PatchMMReduxButton.Add_Click({ MainFunctionMMRedux })
    $PatchMMGroup.Controls.Add($PatchMMReduxButton)
    $ToolTip.SetToolTip($PatchMMReduxButton, "A romhack that improves mechanics for Majorea's Mask`nIt includes the use of the D-Pad for additional dedicated item buttons")

    # Create a button to select additional Redux options.
    $global:PatchMMReduxOptionsButton = New-Object System.Windows.Forms.Button
    $PatchMMReduxOptionsButton.Size = New-Object System.Drawing.Size(20, 35)
    $PatchMMReduxOptionsButton.Location = New-Object System.Drawing.Size($PatchMMReduxButton.Right, $PatchMMReduxButton.Top)
    $PatchMMReduxOptionsButton.Text = "+"
    $PatchMMReduxOptionsButton.Add_Click({ $MMReduxOptionsDialog.ShowDialog() })
    $PatchMMGroup.Controls.Add($PatchMMReduxOptionsButton)
    $ToolTip.SetToolTip($PatchMMReduxOptionsButton, "Toggle additional features for the Majora's Mask REDUX romhack")

    # Create a button to allow patching the WAD (MM Masked Quest).
    $global:PatchMMMaskedQuestButton = New-Object System.Windows.Forms.Button
    $PatchMMMaskedQuestButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchMMMaskedQuestButton.Location = New-Object System.Drawing.Size(($PatchMMReduxButton.Right + 35), $PatchMMReduxButton.Top)
    $PatchMMMaskedQuestButton.Text = "Masked Quest"
    $PatchMMMaskedQuestButton.Add_Click({ MainFunctionMMMaskedQuest })
    $PatchMMGroup.Controls.Add($PatchMMMaskedQuestButton)
    $ToolTip.SetToolTip($PatchMMMaskedQuestButton, "A Master Quest style romhack for Majora's Mask, offering a higher difficulty")



    ###################################
    # MM Patch Buttons (Translations) #
    ###################################

    # Create a button to allow patching the WAD (MM Polish).
    $global:PatchMMPolButton = New-Object System.Windows.Forms.Button
    $PatchMMPolButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchMMPolButton.Location = New-Object System.Drawing.Size($PatchMMReduxButton.Left, ($PatchMMReduxButton.Bottom + 10))
    $PatchMMPolButton.Text = "Polish Translation"
    $PatchMMPolButton.Add_Click({ MainFunctionMMPol })
    $PatchMMGroup.Controls.Add($PatchMMPolButton)
    $ToolTip.SetToolTip($PatchMMPolButton, "Polish Fan-Translation of Majora's Mask")

    # Create a button to allow patching the WAD (MM Russian).
    $global:PatchMMRusButton = New-Object System.Windows.Forms.Button
    $PatchMMRusButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchMMRusButton.Location = New-Object System.Drawing.Size(($PatchMMPolButton.Right + 15), $PatchMMPolButton.Top)
    $PatchMMRusButton.Text = "Russian Translation"
    $PatchMMRusButton.Add_Click({ MainFunctionMMRus })
    $PatchMMGroup.Controls.Add($PatchMMRusButton)
    $ToolTip.SetToolTip($PatchMMRusButton, "Polish Fan-Translation of Majora's Mask")



    ################################
    # SM64 Patch Buttons (General) #
    ################################

    # Create a panel to contain everything for SM64.
    $global:PatchSM64Panel = New-Object System.Windows.Forms.Panel
    $PatchSM64Panel.Size = New-Object System.Drawing.Size(590, 120)
    $MainDialog.Controls.Add($PatchSM64Panel)

    # Create a groupbox to show the SM64 patching buttons.
    $PatchSM64Group = New-Object System.Windows.Forms.GroupBox
    $PatchSM64Group.Size = New-Object System.Drawing.Size($PatchSM64Panel.Width, $PatchSM64Panel.Height)
    $PatchSM64Group.Location = New-Object System.Drawing.Size(0, 0)
    $PatchSM64Group.Text = " Super Mario - Patch Buttons "
    $PatchSM64Panel.Controls.Add($PatchSM64Group)

    # Create a button to allow patching the WAD (SM64 60 FPS V2).
    $global:PatchSM64FPSButton = New-Object System.Windows.Forms.Button
    $PatchSM64FPSButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchSM64FPSButton.Location = New-Object System.Drawing.Size(130, 25)
    $PatchSM64FPSButton.Text = "60 FPS v2"
    $PatchSM64FPSButton.Add_Click({ MainFunctionSM64FPS })
    $PatchSM64Group.Controls.Add($PatchSM64FPSButton)
    $ToolTip.SetToolTip($PatchSM64FPSButton, "Increases the FPS from 30 to 60`nWtiness Super Mario 64 in glorious 60 FPS")

    # Create a button to allow patching the WAD (SM64 Analog Camera).
    $global:PatchSM64CamButton = New-Object System.Windows.Forms.Button
    $PatchSM64CamButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchSM64CamButton.Location = New-Object System.Drawing.Size(($PatchSM64FPSButton.Right + 15), $PatchSM64FPSButton.Top)
    $PatchSM64CamButton.Text = "Analog Camera"
    $PatchSM64CamButton.Add_Click({ MainFunctionSM64Cam })
    $PatchSM64Group.Controls.Add($PatchSM64CamButton)
    $ToolTip.SetToolTip($PatchSM64CamButton, "Enable full 360 degrees sideways analog camera`nEnable a second emulated controller and bind the Analog stick to the C-Stick on the first emulated controller")

    # Create a button to allow patching the WAD (SM64 Multiplayer).
    $global:PatchSM64MultiplayerButton = New-Object System.Windows.Forms.Button
    $PatchSM64MultiplayerButton.Size = New-Object System.Drawing.Size(100, 35)
    $PatchSM64MultiplayerButton.Location = New-Object System.Drawing.Size(($PatchSM64CamButton.Right + 15), $PatchSM64FPSButton.Top)
    $PatchSM64MultiplayerButton.Text = "Multiplayer v1.4.2"
    $PatchSM64MultiplayerButton.Add_Click({ MainFunctionSM64Multiplayer })
    $PatchSM64Group.Controls.Add($PatchSM64MultiplayerButton)
    $ToolTip.SetToolTip($PatchSM64MultiplayerButton, "Single-Screen Multiplayer with Mario and Luigi`nPlugin a second emulated controller for Luigi")



    ##############################
    # PP Patch Buttons (General) #
    ##############################

    # Create a panel to contain everything for PP.
    $global:PatchPPPanel = New-Object System.Windows.Forms.Panel
    $PatchPPPanel.Size = New-Object System.Drawing.Size(590, 120)
    $MainDialog.Controls.Add($PatchPPPanel)

    # Create a groupbox to show the PP patching buttons.
    $PatchPPGroup = New-Object System.Windows.Forms.GroupBox
    $PatchPPGroup.Size = New-Object System.Drawing.Size($PatchPPPanel.Width, $PatchPPPanel.Height)
    $PatchPPGroup.Location = New-Object System.Drawing.Size(0, 0)
    $PatchPPGroup.Text = " Paper Mario - Patch Buttons "
    $PatchPPPanel.Controls.Add($PatchPPGroup)

    # Create a button to allow patching the WAD (PP 60 Hard Mode).
    $global:PatchPPHardMode = New-Object System.Windows.Forms.Button
    $PatchPPHardMode.Size = New-Object System.Drawing.Size(100, 35)
    $PatchPPHardMode.Location = New-Object System.Drawing.Size(130, 25)
    $PatchPPHardMode.Text = "Hard Mode"
    $PatchPPHardMode.Add_Click({ MainFunctionPPHardMode })
    $PatchPPGroup.Controls.Add($PatchPPHardMode)
    $ToolTip.SetToolTip($PatchPPHardMode, "Increases the damage dealt by enemies by 1.5x")

    # Create a button to allow patching the WAD (PP 60 Hard Mode+).
    $global:PatchPPHardModePlus = New-Object System.Windows.Forms.Button
    $PatchPPHardModePlus.Size = New-Object System.Drawing.Size(100, 35)
    $PatchPPHardModePlus.Location = New-Object System.Drawing.Size(($PatchPPHardMode.Right + 15), $PatchPPHardMode.Top)
    $PatchPPHardModePlus.Text = "Hard Mode+"
    $PatchPPHardModePlus.Add_Click({ MainFunctionPPHardModePlus })
    $PatchPPGroup.Controls.Add($PatchPPHardModePlus)
    $ToolTip.SetToolTip($PatchPPHardModePlus, "Increases the damage dealt by enemies by 1.5x`nAlso increases the HP of enemies")

    # Create a button to allow patching the WAD (PP 60 Insane Mode).
    $global:PatchPPInsaneMode = New-Object System.Windows.Forms.Button
    $PatchPPInsaneMode.Size = New-Object System.Drawing.Size(100, 35)
    $PatchPPInsaneMode.Location = New-Object System.Drawing.Size(($PatchPPHardModePlus.Right + 15), $PatchPPHardMode.Top)
    $PatchPPInsaneMode.Text = "Insane Mode"
    $PatchPPInsaneMode.Add_Click({ MainFunctionPPInsaneMode })
    $PatchPPGroup.Controls.Add($PatchPPInsaneMode)
    $ToolTip.SetToolTip($PatchPPInsaneMode, "Increases the damage dealt by enemies by 2x")



    ####################
    # Patch VC Options #
    ####################

    # Create a panel to show the patch options.
    $global:PatchVCPanel = New-Object System.Windows.Forms.Panel
    $PatchVCPanel.Size = New-Object System.Drawing.Size(590, 105)
    $MainDialog.Controls.Add($PatchVCPanel)

    # Create a groupbox to show the patch options.
    $global:PatchVCGroup = New-Object System.Windows.Forms.GroupBox
    $PatchVCGroup.Size = New-Object System.Drawing.Size($PatchVCPanel.Width, $PatchVCPanel.Height)
    $PatchVCGroup.Location = New-Object System.Drawing.Size(0, 0)
    $PatchVCGroup.Text = 'Virtual Console - Patch Options'
    $PatchVCPanel.Controls.Add($PatchVCGroup)



    # Create a label for Core patches
    $global:PatchVCCoreLabel = New-Object System.Windows.Forms.Label
    $PatchVCCoreLabel.Size = New-Object System.Drawing.Size(50, 15)
    $PatchVCCoreLabel.Location = New-Object System.Drawing.Size(10, (22))
    $PatchVCCoreLabel.Text = "Core"
    $PatchVCCoreLabel.Font = $VCPatchFont
    $PatchVCGroup.Controls.Add($PatchVCCoreLabel)

    # Create a label to show Remove T64 description
    $global:PatchVCRemoveT64Label = New-Object System.Windows.Forms.Label
    $PatchVCRemoveT64Label.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCRemoveT64Label.Location = New-Object System.Drawing.Size(($PatchVCCoreLabel.Right + 20), $PatchVCCoreLabel.Top)
    $PatchVCRemoveT64Label.Text = "Remove All T64:"
    $ToolTip.SetToolTip($PatchVCRemoveT64Label, "Remove all injected T64 format textures")
    $PatchVCGroup.Controls.Add($global:PatchVCRemoveT64Label)

    # Create a checkbox to Remove T64
    $global:PatchVCRemoveT64 = New-Object System.Windows.Forms.Checkbox
    $PatchVCRemoveT64.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCRemoveT64.Location = New-Object System.Drawing.Size($PatchVCRemoveT64Label.Right, ($PatchVCCoreLabel.Top - 2))
    $PatchVCRemoveT64.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($global:PatchVCRemoveT64)
    $ToolTip.SetToolTip($PatchVCRemoveT64Label, "Remove all injected T64 format textures")
    
    # Create a label to show Expand Memory description
    $global:PatchVCExpandMemoryLabel = New-Object System.Windows.Forms.Label
    $PatchVCExpandMemoryLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCExpandMemoryLabel.Location = New-Object System.Drawing.Size(($PatchVCRemoveT64.Right + 10), $PatchVCCoreLabel.Top)
    $PatchVCExpandMemoryLabel.Text = "Expand Memory:"
    $PatchVCGroup.Controls.Add($global:PatchVCExpandMemoryLabel)
    $ToolTip.SetToolTip($PatchVCExpandMemoryLabel, "Expand the game's memory by 4MB")

    # Create a checkbox to Expand Memory
    $global:PatchVCExpandMemory = New-Object System.Windows.Forms.Checkbox
    $PatchVCExpandMemory.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCExpandMemory.Location = New-Object System.Drawing.Size($PatchVCExpandMemoryLabel.Right, ($PatchVCCoreLabel.Top - 2))
    $PatchVCExpandMemory.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($global:PatchVCExpandMemory)
    $ToolTip.SetToolTip($PatchVCExpandMemory, "Expand the game's memory by 4MB")
    
    # Create a label to show Remap D-Pad description
    $global:PatchVCRemapDPadLabel = New-Object System.Windows.Forms.Label
    $PatchVCRemapDPadLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCRemapDPadLabel.Location = New-Object System.Drawing.Size(($PatchVCExpandMemory.Right + 10), $PatchVCCoreLabel.Top)
    $PatchVCRemapDPadLabel.Text = "Remap D-Pad:"
    $PatchVCGroup.Controls.Add($PatchVCRemapDPadLabel)
    $ToolTip.SetToolTip($PatchVCRemapDPadLabel, "Remap the D-Pad to the actual four D-Pad directional buttons instead of toggling the minimap")

    # Create a checkbox to Remap D-Pad
    $global:PatchVCRemapDPad = New-Object System.Windows.Forms.Checkbox
    $PatchVCRemapDPad.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCRemapDPad.Location = New-Object System.Drawing.Size($PatchVCRemapDPadLabel.Right, ($PatchVCCoreLabel.Top - 2))
    $PatchVCRemapDPad.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($PatchVCRemapDPad)
    $ToolTip.SetToolTip($PatchVCRemapDPad, "Remap the D-Pad to the actual four D-Pad directional buttons instead of toggling the minimap")

    # Create a label to show Downgrade description
    $global:PatchVCDowngradeLabel = New-Object System.Windows.Forms.Label
    $PatchVCDowngradeLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCDowngradeLabel.Location = New-Object System.Drawing.Size(($PatchVCRemapDPad.Right + 10), $PatchVCCoreLabel.Top)
    $PatchVCDowngradeLabel.Text = "Downgrade:"
    $PatchVCGroup.Controls.Add($PatchVCDowngradeLabel)
    $ToolTip.SetToolTip($PatchVCDowngradeLabel, "Downgrade Ocarina of Time from version 1.2 US to 1.0 US")

    # Create a checkbox to Downgrade
    $global:PatchVCDowngrade = New-Object System.Windows.Forms.Checkbox
    $PatchVCDowngrade.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCDowngrade.Location = New-Object System.Drawing.Size($PatchVCDowngradeLabel.Right, ($PatchVCCoreLabel.Top - 2))
    $PatchVCDowngrade.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($PatchVCDowngrade)
    $ToolTip.SetToolTip($PatchVCDowngrade, "Downgrade Ocarina of Time from version 1.2 US to 1.0 US")



    # Create a label for Minimap
    $global:PatchVCMinimapLabel = New-Object System.Windows.Forms.Label
    $PatchVCMinimapLabel.Size = New-Object System.Drawing.Size(50, 15)
    $PatchVCMinimapLabel.Location = New-Object System.Drawing.Size(10, ($PatchVCCoreLabel.Bottom + 5))
    $PatchVCMinimapLabel.Text = "Minimap"
    $PatchVCMinimapLabel.Font = $VCPatchFont
    $PatchVCGroup.Controls.Add($PatchVCMinimapLabel)

    # Create a label to show Remap C-Down description
    $global:PatchVCRemapCDownLabel = New-Object System.Windows.Forms.Label
    $PatchVCRemapCDownLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCRemapCDownLabel.Location = New-Object System.Drawing.Size(80, $PatchVCMinimapLabel.Top)
    $PatchVCRemapCDownLabel.Text = "Remap C-Down:"
    $PatchVCGroup.Controls.Add($PatchVCRemapCDownLabel)
    $ToolTip.SetToolTip($PatchVCRemapCDownLabel, "Remap the C-Down button for toggling the minimap instead of using an item")

    # Create a checkbox to Remap C-Down
    $global:PatchVCRemapCDown = New-Object System.Windows.Forms.Checkbox
    $PatchVCRemapCDown.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCRemapCDown.Location = New-Object System.Drawing.Size($PatchVCRemapCDownLabel.Right, ($PatchVCMinimapLabel.Top - 2))
    $PatchVCRemapCDown.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($PatchVCRemapCDown)
    $ToolTip.SetToolTip($PatchVCRemapCDown, "Remap the C-Down button for toggling the minimap instead of using an item")

    # Create a label to show Remap Z description
    $global:PatchVCRemapZLabel = New-Object System.Windows.Forms.Label
    $PatchVCRemapZLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCRemapZLabel.Location = New-Object System.Drawing.Size(205, $PatchVCMinimapLabel.Top)
    $PatchVCRemapZLabel.Text = "Remap Z:"
    $PatchVCGroup.Controls.Add($PatchVCRemapZLabel)
    $ToolTip.SetToolTip($PatchVCRemapZLabel, "Remap the Z (GameCube) or ZL and ZR (Classic) buttons for toggling the minimap instead of using an item")

    # Create a checkbox to Remap Z
    $global:PatchVCRemapZ = New-Object System.Windows.Forms.Checkbox
    $PatchVCRemapZ.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCRemapZ.Location = New-Object System.Drawing.Size($PatchVCRemapZLabel.Right, ($PatchVCMinimapLabel.Top - 2))
    $PatchVCRemapZ.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($PatchVCRemapZ)
    $ToolTip.SetToolTip($PatchVCRemapZ, "Remap the Z (GameCube) or ZL and ZR (Classic) buttons for toggling the minimap instead of using an item")

    # Create a label to show Leave D-Pad Up description
    $global:PatchVCLeaveDPadUpLabel = New-Object System.Windows.Forms.Label
    $PatchVCLeaveDPadUpLabel.Size = New-Object System.Drawing.Size(95, 15)
    $PatchVCLeaveDPadUpLabel.Location = New-Object System.Drawing.Size(330, $PatchVCMinimapLabel.Top)
    $PatchVCLeaveDPadUpLabel.Text = "Leave D-Pad Up:"
    $PatchVCGroup.Controls.Add($PatchVCLeaveDPadUpLabel)
    $ToolTip.SetToolTip($PatchVCLeaveDPadUpLabel, "Leave the D-Pad untouched so it can be used to toggle the minimap")

    # Create a checkbox to Leave D-Pad Up
    $global:PatchVCLeaveDPadUp = New-Object System.Windows.Forms.Checkbox
    $PatchVCLeaveDPadUp.Size = New-Object System.Drawing.Size(20, 20)
    $PatchVCLeaveDPadUp.Location = New-Object System.Drawing.Size($PatchVCLeaveDPadUpLabel.Right, ($PatchVCMinimapLabel.Top - 2))
    $PatchVCLeaveDPadUp.Add_CheckStateChanged({ CheckForCheckboxes })
    $PatchVCGroup.Controls.Add($PatchVCLeaveDPadUp)
    $ToolTip.SetToolTip($PatchVCLeaveDPadUp, "Leave the D-Pad untouched so it can be used to toggle the minimap")



    # Create a label for Patch VC Buttons
    $global:PatchVCMinimapLabel = New-Object System.Windows.Forms.Label
    $PatchVCMinimapLabel.Size = New-Object System.Drawing.Size(50, 15)
    $PatchVCMinimapLabel.Location = New-Object System.Drawing.Size(10, 72)
    $PatchVCMinimapLabel.Text = "Actions"
    $PatchVCMinimapLabel.Font = $VCPatchFont
    $PatchVCGroup.Controls.Add($PatchVCMinimapLabel)

    # Create a button to patch the VC
    $global:PatchVCButton = New-Object System.Windows.Forms.Button
    $PatchVCButton.Size = New-Object System.Drawing.Size(150, 30)
    $PatchVCButton.Location = New-Object System.Drawing.Size(80, 65)
    $PatchVCButton.Text = "Patch VC Emulator Only"
    $PatchVCButton.Add_Click({ MainFunctionPatchVC })
    $PatchVCButton.Enabled = $false
    $PatchVCGroup.Controls.Add($PatchVCButton)
    $ToolTip.SetToolTip($PatchVCButton, "Ignore any patches and only patches the Virtual Console emulator`nDowngrading and channing the Channel Title or GameID is still accepted")

    # Create a button to extract the ROM
    $global:ExtractROMButton = New-Object System.Windows.Forms.Button
    $ExtractROMButton.Size = New-Object System.Drawing.Size(150, 30)
    $ExtractROMButton.Location = New-Object System.Drawing.Size(240, 65)
    $ExtractROMButton.Text = "Extract ROM Only"
    $ExtractROMButton.Add_Click({ MainFunctionExtractROM })
    $PatchVCGroup.Controls.Add($ExtractROMButton)
    $ToolTip.SetToolTip($ExtractROMButton, "Only extract the .Z64 ROM from the WAD file`nUseful for native N64 emulators")



    ##############
    # Misc Panel #
    ##############

    # Create a panel to contain everything for other.
    $global:MiscPanel = New-Object System.Windows.Forms.Panel
    $MiscPanel.Size = New-Object System.Drawing.Size(625, 205)
    $MainDialog.Controls.Add($MiscPanel)



    ########################
    # Game Options Buttons #
    ########################

    # Create a groupbox to show the game option buttons.
    $global:GameOptionsGroup = New-Object System.Windows.Forms.Groupbox
    $GameOptionsGroup.Size = New-Object System.Drawing.Size(400, 90)
    $GameOptionsGroup.Location = New-Object System.Drawing.Size(0, 0)
    $GameOptionsGroup.Text = " Set Game Mode "
    $MiscPanel.Controls.Add($GameOptionsGroup)

    # Create a button to switch to OoT.
    $OoTGameOptionButton = New-Object System.Windows.Forms.Button
    $OoTGameOptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $OoTGameOptionButton.Location = New-Object System.Drawing.Size(40, 25)
    $OoTGameOptionButton.Text = "Ocarina of Time"
    $OoTGameOptionButton.Add_Click({ SetOcarinaOfTimeModeActive })
    $GameOptionsGroup.Controls.Add($OoTGameOptionButton)
    $ToolTip.SetToolTip($OoTGameOptionButton, "Switch to Ocarina of Time Patching Mode")

    # Create a button to switch to MM.
    $MMGameOptionButton = New-Object System.Windows.Forms.Button
    $MMGameOptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $MMGameOptionButton.Location = New-Object System.Drawing.Size($OoTGameOptionButton.Left, ($OoTGameOptionButton.Bottom + 10))
    $MMGameOptionButton.Text = "Majora's Mask"
    $MMGameOptionButton.Add_Click({ SetMajorasMaskModeActive })
    $GameOptionsGroup.Controls.Add($MMGameOptionButton)
    $ToolTip.SetToolTip($MMGameOptionButton, "Switch to Majora's Mask Patching Mode")

    # Create a button to switch to SM64.
    $SM64GameOptionButton = New-Object System.Windows.Forms.Button
    $SM64GameOptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $SM64GameOptionButton.Location = New-Object System.Drawing.Size(($MMGameOptionButton.Right + 15), $OoTGameOptionButton.Top)
    $SM64GameOptionButton.Text = 'Super Mario 64'
    $SM64GameOptionButton.Add_Click({ SetSuperMario64ModeActive })
    $GameOptionsGroup.Controls.Add($SM64GameOptionButton)
    $ToolTip.SetToolTip($SM64GameOptionButton, "Switch to Super Mario 64 Patching Mode")

    # Create a button to switch to PP.
    $PPGameOptionButton = New-Object System.Windows.Forms.Button
    $PPGameOptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $PPGameOptionButton.Location = New-Object System.Drawing.Size(($MMGameOptionButton.Right + 15), ($OoTGameOptionButton.Bottom + 10))
    $PPGameOptionButton.Text = 'Paper Mario'
    $PPGameOptionButton.Add_Click({ SetPaperMarioModeActive })
    $GameOptionsGroup.Controls.Add($PPGameOptionButton)
    $ToolTip.SetToolTip($PPGameOptionButton, "Switch to Paper Mario Patching Mode")

    # Create a button to switch to Free.
    $FreeGameOptionButton = New-Object System.Windows.Forms.Button
    $FreeGameOptionButton.Size = New-Object System.Drawing.Size(100, 52)
    $FreeGameOptionButton.Location = New-Object System.Drawing.Size(($PPGameOptionButton.Right + 15), $OoTGameOptionButton.Top)
    $FreeGameOptionButton.Text = 'Free (N64)'
    $FreeGameOptionButton.Add_Click({ SetFreeModeActive })
    $GameOptionsGroup.Controls.Add($FreeGameOptionButton)
    $ToolTip.SetToolTip($FreeGameOptionButton, "Switch to Free Patching Mode for other Nintendo 64 titles")



    ###################
    # Console Buttons #
    ###################

    # Create a groupbox to show the game option buttons.
    $global:ConsoleOptionsGroup = New-Object System.Windows.Forms.Groupbox
    $ConsoleOptionsGroup.Size = New-Object System.Drawing.Size(180, 90)
    $ConsoleOptionsGroup.Location = New-Object System.Drawing.Size(($GameOptionsGroup.Right + 10), 0)
    $ConsoleOptionsGroup.Text = " Set Console "
    $MiscPanel.Controls.Add($ConsoleOptionsGroup)

    # Create a button to switch to VC WAD format.
    $WiiVCOptionButton = New-Object System.Windows.Forms.Button
    $WiiVCOptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $WiiVCOptionButton.Location = New-Object System.Drawing.Size(40, 25)
    $WiiVCOptionButton.Text = "Wii VC (N64)"
    $WiiVCOptionButton.Add_Click({ SetWiiVCMode -Bool $true })
    $ConsoleOptionsGroup.Controls.Add($WiiVCOptionButton)
    $ToolTip.SetToolTip($WiiVCOptionButton, "Switch to patching Wii Virtual Console WAD files")

    # Create a button to switch to N64 format.
    $N64OptionButton = New-Object System.Windows.Forms.Button
    $N64OptionButton.Size = New-Object System.Drawing.Size(100, 22)
    $N64OptionButton.Location = New-Object System.Drawing.Size($WiiVCOptionButton.Left, ($WiiVCOptionButton.Bottom + 10))
    $N64OptionButton.Text = "Nintendo 64"
    $N64OptionButton.Add_Click({ SetWiiVCMode -Bool $false })
    $ConsoleOptionsGroup.Controls.Add($N64OptionButton)
    $ToolTip.SetToolTip($N64OptionButton, "Switch to patching Nintendo 64 ROMS in the format Z64, N64 or V64")



    ################
    # Misc Buttons #
    ################

    # Create a groupbox to show the misc buttons.
    $global:MiscGroup = New-Object System.Windows.Forms.Groupbox
    $MiscGroup.Size = New-Object System.Drawing.Size(590, 75)
    $MiscGroup.Location = New-Object System.Drawing.Size(0, 95)
    $MiscGroup.Text = " Other Buttons "
    $MiscPanel.Controls.Add($MiscGroup)

    # Create a button to show info about which GameID to use.
    $InfoGameIDButton = New-Object System.Windows.Forms.Button
    $InfoGameIDButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoGameIDButton.Location = New-Object System.Drawing.Size(75, 25)
    $InfoGameIDButton.Text = "GameID's"
    $InfoGameIDButton.Add_Click({ $InfoGameIDDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoGameIDButton)
    $ToolTip.SetToolTip($InfoGameIDButton, "Open the list with official, used and recommend GameID values to refer to")

    # Create a button to show information about the patches.
    $global:InfoOcarinaOfTimeButton = New-Object System.Windows.Forms.Button
    $InfoOcarinaOfTimeButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoOcarinaOfTimeButton.Location = New-Object System.Drawing.Size(($InfoGameIDButton.Right + 15), $InfoGameIDButton.Top)
    $InfoOcarinaOfTimeButton.Text = "Info              Zelda 64"
    $InfoOcarinaOfTimeButton.Add_Click({ $InfoOcarinaOfTimeDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoOcarinaOfTimeButton)
    $ToolTip.SetToolTip($InfoOcarinaOfTimeButton, "Open the list with information about the Ocarina of Time patching mode")

    # Create a button to show information about the patches.
    $global:InfoMajorasMaskButton = New-Object System.Windows.Forms.Button
    $InfoMajorasMaskButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoMajorasMaskButton.Location = New-Object System.Drawing.Size(($InfoGameIDButton.Right + 15), $InfoGameIDButton.Top)
    $InfoMajorasMaskButton.Text = "Info              Majora's Mask"
    $InfoMajorasMaskButton.Add_Click({ $InfoMajorasMaskDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoMajorasMaskButton)
    $ToolTip.SetToolTip($InfoMajorasMaskButton, "Open the list with information about the Majora's Mask patching mode")

    # Create a button to show information about the patches.
    $global:InfoSuperMario64Button = New-Object System.Windows.Forms.Button
    $InfoSuperMario64Button.Size = New-Object System.Drawing.Size(100, 35)
    $InfoSuperMario64Button.Location = New-Object System.Drawing.Size(($InfoGameIDButton.Right + 15), $InfoGameIDButton.Top)
    $InfoSuperMario64Button.Text = "Info              Super Mario 64"
    $InfoSuperMario64Button.Add_Click({ $InfoSuperMario64Dialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoSuperMario64Button)
    $ToolTip.SetToolTip($InfoSuperMario64Button, "Open the list with information about the Super Mario 64 patching mode")

    # Create a button to show information about the patches.
    $global:InfoPaperMarioButton = New-Object System.Windows.Forms.Button
    $InfoPaperMarioButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoPaperMarioButton.Location = New-Object System.Drawing.Size(($InfoGameIDButton.Right + 15), $InfoGameIDButton.Top)
    $InfoPaperMarioButton.Text = "Info              Paper Mario"
    $InfoPaperMarioButton.Add_Click({ $InfoPaperMarioDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoPaperMarioButton)
    $ToolTip.SetToolTip($InfoPaperMarioButton, "Open the list with information about the Paper Mario patching mode")

    # Create a button to show information about the patches.
    $global:InfoFreeButton = New-Object System.Windows.Forms.Button
    $InfoFreeButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoFreeButton.Location = New-Object System.Drawing.Size(($InfoGameIDButton.Right + 15), $InfoGameIDButton.Top)
    $InfoFreeButton.Text = "Info                Free"
    $InfoFreeButton.Add_Click({ $InfoFreeDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($InfoFreeButton)
    $ToolTip.SetToolTip($InfoFreeButton, "Open the list with information about the Free (N64) patching mode")

    # Create a button to show credits about the patches.
    $CreditsButton = New-Object System.Windows.Forms.Button
    $CreditsButton.Size = New-Object System.Drawing.Size(100, 35)
    $CreditsButton.Location = New-Object System.Drawing.Size(($InfoOcarinaOfTimeButton.Right + 15), $InfoGameIDButton.Top)
    $CreditsButton.Text = 'Credits'
    $CreditsButton.Add_Click({ $CreditsDialog.ShowDialog() | Out-Null })
    $MiscGroup.Controls.Add($CreditsButton)
    $ToolTip.SetToolTip($CreditsButton, "Open the list with credits of all of patches involved and those who helped with the " + $ScriptName + " tool")

    # Create a button to close the dialog.
    $global:ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Size = New-Object System.Drawing.Size(100, 35)
    $ExitButton.Location = New-Object System.Drawing.Size(($CreditsButton.Right + 15), $InfoGameIDButton.Top)
    $ExitButton.Text = 'Exit'
    $ExitButton.Add_Click({ $MainDialog.Close() })
    $MiscGroup.Controls.Add($ExitButton)
    $ToolTip.SetToolTip($ExitButton, "Close the " + $ScriptName + " tool")



    ##################
    # Current Status #
    ##################

    # Create a groupbox to show the current status.
    $global:StatusGroup = New-Object System.Windows.Forms.GroupBox
    $StatusGroup.Size = New-Object System.Drawing.Size(590, 30)
    $StatusGroup.Location = New-Object System.Drawing.Size(0, 175)
    $StatusGroup.Text = ''
    $MiscPanel.Controls.Add($StatusGroup)

    # Create a label to show the current status.
    $global:StatusLabel = New-Object System.Windows.Forms.Label
    $StatusLabel.Size = New-Object System.Drawing.Size(570, 15)
    $StatusLabel.Location = New-Object System.Drawing.Size(8, 10)
    $StatusGroup.Controls.Add($StatusLabel)

}



#==============================================================================================================================================================================================
function SetMainScreenSize() {
    
    if ($IsWiiVC) {

        $InputWADPanel.Location = New-Object System.Drawing.Size(10, 35)
        $InputROMPanel.Location = New-Object System.Drawing.Size(10, 90)
        $InputBPSPanel.Location = New-Object System.Drawing.Size(10, 145)
        $CustomGameIDPanel.Location = New-Object System.Drawing.Size(10, 200)

        $PatchOoTPanel.Location = New-Object System.Drawing.Size(10, ($CustomGameIDPanel.Bottom + 5))
        $PatchMMPanel.Location = New-Object System.Drawing.Size(10, ($CustomGameIDPanel.Bottom + 5))
        $PatchSM64Panel.Location = New-Object System.Drawing.Size(10, ($CustomGameIDPanel.Bottom + 5))
        $PatchPPPanel.Location = New-Object System.Drawing.Size(10, ($CustomGameIDPanel.Bottom + 5))

        if ($GameType -ne "Free") {
            $PatchVCPanel.Location = New-Object System.Drawing.Size(10, ($PatchOoTPanel.Bottom + 5))
        }
        else {
            $PatchVCPanel.Location = New-Object System.Drawing.Size(10, ($CustomGameIDPanel.Bottom + 5))
        }

        $MiscPanel.Location = New-Object System.Drawing.Size(10, ($PatchVCPanel.Bottom + 5))

    }

    else {
        
        $InputROMPanel.Location = New-Object System.Drawing.Size(10, 35)
        $InputBPSPanel.Location = New-Object System.Drawing.Size(10, 90)

        $PatchOoTPanel.Location = New-Object System.Drawing.Size(10, ($InputBPSPanel.Bottom + 5))
        $PatchMMPanel.Location = New-Object System.Drawing.Size(10, ($InputBPSPanel.Bottom + 5))
        $PatchSM64Panel.Location = New-Object System.Drawing.Size(10, ($InputBPSPanel.Bottom + 5))
        $PatchPPPanel.Location = New-Object System.Drawing.Size(10, ($InputBPSPanel.Bottom + 5))

        if ($GameType -ne "Free") {
            $MiscPanel.Location = New-Object System.Drawing.Size(10, ($PatchOoTPanel.Bottom + 5))
        }
        else {
            $MiscPanel.Location = New-Object System.Drawing.Size(10, ($InputBPSPanel.Bottom + 5))
        }

    }

    $MainDialog.Height = ($MiscPanel.Bottom + 50)

}


#==============================================================================================================================================================================================
function ChangeGameMode() {
    
    $PatchOoTPanel.Hide()
    $PatchMMPanel.Hide()
    $PatchSM64Panel.Hide()
    $PatchPPPanel.Hide()

    $InfoOcarinaOfTimeButton.Hide()
    $InfoMajorasMaskButton.Hide()
    $InfoSuperMario64Button.Hide()
    $InfoPaperMarioButton.Hide()
    $InfoFreeButton.Hide()

    $PatchVCExpandMemoryLabel.Hide()
    $PatchVCExpandMemory.Hide()
    $PatchVCRemapDPadLabel.Hide()
    $PatchVCRemapDPad.Hide()
    $PatchVCDowngradeLabel.Hide()
    $PatchVCDowngrade.Hide()

    $PatchVCMinimapLabel.Hide()
    $PatchVCRemapCDownLabel.Hide()
    $PatchVCRemapCDown.Hide()
    $PatchVCRemapZLabel.Hide()
    $PatchVCRemapZ.Hide()
    $PatchVCLeaveDPadUpLabel.Hide()
    $PatchVCLeaveDPadUp.Hide()

    SetModeLabel
    CheckForCheckboxes
    SetWiiVCMode -Bool $IsWiiVC

}


#==============================================================================================================================================================================================
function SetOcarinaOfTimeModeActive() {
    
    $global:GameType = "Ocarina of Time"
    $global:GameID = "NACE"
    $global:ChannelTitle = "Zelda: Ocarina"

    ChangeGameMode

    $PatchOoTPanel.Show()
    $InfoOcarinaOfTimeButton.Show()

    $InputCustomChannelTitleTextBox.Show()
    $InputCustomChannelTitleTextBoxLabel.Show()
    $InputCustomChannelTitleTextBox.Text = "Zelda: Ocarina"
    $InputCustomGameIDTextBox.Text = "NACE"

    $PatchVCExpandMemoryLabel.Show()
    $PatchVCExpandMemory.Show()
    $PatchVCRemapDPadLabel.Show()
    $PatchVCRemapDPad.Show()
    $PatchVCDowngradeLabel.Show()
    $PatchVCDowngrade.Show()

    $PatchVCMinimapLabel.Show()
    $PatchVCRemapCDownLabel.Show()
    $PatchVCRemapCDown.Show()
    $PatchVCRemapZLabel.Show()
    $PatchVCRemapZ.Show()
    $PatchVCLeaveDPadUpLabel.Show()
    $PatchVCLeaveDPadUp.Show()

}



#==============================================================================================================================================================================================
function SetMajorasMaskModeActive() {
    
    $global:GameType = "Majora's Mask"
    $global:GameID = "NARE"
    $global:ChannelTitle = "Zelda: Majora's"

    ChangeGameMode

    $PatchMMPanel.Show()
    $InfoMajorasMaskButton.Show()

    $InputCustomChannelTitleTextBox.Show()
    $InputCustomChannelTitleTextBoxLabel.Show()
    $InputCustomChannelTitleTextBox.Text = "Zelda: Majora"
    $InputCustomGameIDTextBox.Text = "NARE"

    $PatchVCExpandMemoryLabel.Show()
    $PatchVCExpandMemory.Show()
    $PatchVCRemapDPadLabel.Show()
    $PatchVCRemapDPad.Show()

    $PatchVCMinimapLabel.Show()
    $PatchVCRemapCDownLabel.Show()
    $PatchVCRemapCDown.Show()
    $PatchVCRemapZLabel.Show()
    $PatchVCRemapZ.Show()

}



#==============================================================================================================================================================================================
function SetSuperMario64ModeActive() {
    
    $global:GameType = "Super Mario 64"
    $global:GameID = "NAAE"
    $global:ChannelTitle = "Super Mario 64"

    ChangeGameMode

    $PatchSM64Panel.Show()
    $InfoSuperMario64Button.Show()

    $InputCustomChannelTitleTextBox.Show()
    $InputCustomChannelTitleTextBoxLabel.Show()
    $InputCustomChannelTitleTextBox.Text = "Super Mario 64"
    $InputCustomGameIDTextBox.Text = "NAAE"

}



#==============================================================================================================================================================================================
function SetPaperMarioModeActive() {
    
    $global:GameType = "Paper Mario"
    $global:GameID = "NAEE"
    $global:ChannelTitle = "Paper Mario"

    ChangeGameMode

    $PatchPPPanel.Show()
    $InfoPaperMarioButton.Show()

    $InputCustomChannelTitleTextBox.Show()
    $InputCustomChannelTitleTextBoxLabel.Show()
    $InputCustomChannelTitleTextBox.Text = "Paper Mario"
    $InputCustomGameIDTextBox.Text = "NAEE"

}



#==============================================================================================================================================================================================
function SetFreeModeActive() {

    $global:GameType = "Free"
    $global:GameID = "CUST"
    $global:ChannelTitle = "Custom Channel"

    ChangeGameMode

    $InfoFreeButton.Show()

    $InputCustomChannelTitleTextBox.Show()
    $InputCustomChannelTitleTextBoxLabel.Show()
    $InputCustomChannelTitleTextBox.Text = "Custom Channel"
    $InputCustomGameIDTextBox.Text = "CUST"

}



#==============================================================================================================================================================================================
function SetWiiVCMode([boolean]$Bool) {
    
    $InputWADPanel.Visible = $Bool
    $InjectROMButton.Visible = $Bool
    $CustomGameIDPanel.Visible = $Bool
    $PatchVCPanel.Visible = $Bool
    $global:IsWiiVC = $Bool
    if ($Bool) { EnablePatchButtons -Enable ($WADFilePath -ne $null) } else { EnablePatchButtons -Enable ($Z64FilePath -ne $null) }
    SetMainScreenSize
    SetModeLabel

}



#==============================================================================================================================================================================================
function SetModeLabel() {
	
    $CurrentModeLabel.Text = "Current  Mode  :  " + $GameType
    if ($IsWiiVC) { $CurrentModeLabel.Text += "  (Wii VC)" } else { $CurrentModeLabel.Text += "  (N64)" }
    $CurrentModeLabel.Location = New-Object System.Drawing.Size(([Math]::Floor($MainDialog.Width / 2) - [Math]::Floor($CurrentModeLabel.Width / 2)), 10)

}


function UpdateStatusLabelDuringPatching([String]$Text) {
    
    $MainDialog.Enabled = $true
    $StatusLabel.Text = $Text
    $MainDialog.Enabled = $false

}



#==============================================================================================================================================================================================
function CheckBootDolOptions() {
    
    if ($PatchVCExpandMemory.Checked -and $PatchVCExpandMemory.Visible) { return $true }
    elseif ($PatchVCRemapDPad.Checked -and $PatchVCRemapDPad.Visible) {  return $true }
    elseif ($PatchVCRemapCDown.Checked -and $PatchVCRemapCDown.Visible) { return $true }
    elseif ($PatchVCRemapZ.Checked -and $PatchVCRemapZ.Visible) { return $true }

    return false

}


#==============================================================================================================================================================================================
function CheckReduxOptions() {
    
    if ($GameType -eq "Ocarina of Time") {
        if ($1xDamageOoT.Checked -and !$NormalRecoveryOoT.Checked) { return $true }
        elseif ($2xDamageOoT.Checked) { return $true }
        elseif ($4xDamageOoT.Checked ) { return $true }
        elseif ($8xDamageOoT.Checked) { return $true }
        elseif (!$1xDamageOoT.Checked -and $NormalRecoveryOoT.Checked) { return $true }
        elseif ($HalfRecoveryOoT.Checked) { return $true }
        elseif ($QuarterRecoveryOoT.Checked ) { return $true }
        elseif ($NoRecoveryOoT.Checked) { return $true }
        elseif ($OHKOModeOoT.Checked) { return $true }
        elseif ($1xTextOoT.Checked) { return $true }
        elseif ($3xTextOoT.Checked) { return $true }
        elseif ($ExtendedDrawOoT.Checked) { return $true }
        elseif ($MedallionsOoT.Checked) { return $true }
        elseif ($ReturnChildOoT.Checked) { return $true }
        elseif ($HiresModelOoT.Checked) { return $true }
        elseif ($UnlockTunicsOoT.Checked) { return $true }
        elseif ($UnlockSwordOoT.Checked) { return $true }
        elseif ($UnlockBootsOoT.Checked) { return $true }
        elseif ($DisableLowHPSoundOoT.Checked) { return $true }
        elseif ($DisableNaviOoT.Checked) { return $true }
        elseif ($HideDPadOoT.Checked) { return $true }
    }
    elseif ($GameType -eq "Majora's Mask") {
        if ($1xDamageMM.Checked -and !$NormalRecoveryMM.Checked) { return $true }
        elseif ($2xDamageMM.Checked) { return $true }
        elseif ($4xDamageMM.Checked) { return $true }
        elseif ($8xDamageMM.Checked) { return $true }
        elseif (!$1xDamageMM.Checked -and $NormalRecoveryMM.Checked) { return $true }
        elseif ($HalfRecoveryMM.Checked) { return $true }
        elseif ($QuarterRecoveryMM.Checked) { return $true }
        elseif ($NoRecoveryMM.Checked) { return $true }
        elseif ($OHKOModeMM.Checked) { return $true }
        elseif ($LeftDPadMM.Checked) { return $true }
        elseif ($RightDPadMM.Checked) { return $true }
        elseif ($HideDPadMM.Checked) { return $true }
        elseif ($ExtendedDrawMM.Checked ) { return $true }
        elseif ($RazorSwordMM.Checked) { return $true }
        elseif ($DisableLowHPSoundMM.Checked) { return $true }
        elseif ($PieceOfHeartSoundMM.Checked) { return $true }
    }

    return $false

}



#==============================================================================================================================================================================================
function CheckForCheckboxes() {
    
    if ($PatchVCRemoveT64.Checked -and $PatchVCRemoveT64.Visible) {
        $PatchVCButton.Enabled = $true
    }
    elseif ($PatchVCExpandMemory.Checked -and $PatchVCExpandMemory.Visible) {
        $PatchVCButton.Enabled = $true
    }
    elseif ($PatchVCRemapDPad.Checked -and $PatchVCRemapDPad.Visible) {
        $PatchVCButton.Enabled = $true
    }
    elseif ($PatchVCDowngrade.Checked -and $PatchVCDowngrade.Visible) {
        $PatchVCButton.Enabled = $true
    }
    elseif ($PatchVCRemapCDown.Checked -and $PatchVCRemapCDown.Visible) {
         $PatchVCButton.Enabled = $true
    }
    elseif ($PatchVCRemapZ.Checked -and $PatchVCRemapZ.Visible) {
         $PatchVCButton.Enabled = $true
    }
    elseif ($PatchLeaveDPadUp.Checked -and $PatchLeaveDPadUp.Visible) {
         $PatchVCButton.Enabled = $true
    }
    else {
        $PatchVCButton.Enabled = $false
    }

}




#==============================================================================================================================================================================================
function CreateOcarinaOfTimeReduxOptionsDialog() {
    
    # Create the dialog that displays more info.
    $global:OoTReduxOptionsDialog = New-Object System.Windows.Forms.Form
    $OoTReduxOptionsDialog.Text = $ScriptName
    $OoTReduxOptionsDialog.Size = New-Object System.Drawing.Size(700, 400)
    $OoTReduxOptionsDialog.MaximumSize = $OoTReduxOptionsDialog.Size
    $OoTReduxOptionsDialog.MinimumSize = $OoTReduxOptionsDialog.Size
    $OoTReduxOptionsDialog.MaximizeBox = $false
    $OoTReduxOptionsDialog.MinimizeBox = $false
    $OoTReduxOptionsDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $OoTReduxOptionsDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $OoTReduxOptionsDialog.StartPosition = "CenterScreen"
    $OoTReduxOptionsDialog.Icon = $ZeldaIcon1

    # Options Label
    $TextLabel = New-Object System.Windows.Forms.Label
    $TextLabel.Size = New-Object System.Drawing.Size(300, 15)
    $TextLabel.Location = New-Object System.Drawing.Size(30, 20)
    $TextLabel.Font = $VCPatchFont
    $TextLabel.Text = "Ocarina of Time REDUX - Additional Options"
    $OoTReduxOptionsDialog.Controls.Add($TextLabel)

    # Create Tooltip
    $ToolTip = new-Object System.Windows.Forms.ToolTip
    $ToolTip.AutoPopDelay = 32767
    $ToolTip.InitialDelay = 500
    $ToolTip.ReshowDelay = 0
    $ToolTip.ShowAlways = $true



    ##############
    # Checkboxex #
    ##############

    $row = 0
    $column = 0
    $labelWidth = 135
    $labelHeight = 15
    $baseX = 30
    $rowHeight = 30
    $columnWidth = $labelWidth + 20



    # Create a groupbox for the Hero Mode buttons
    $HeroModeBox = New-Object System.Windows.Forms.GroupBox
    $HeroModeBox.Location = New-Object System.Drawing.Size(($baseX - 15), 50)
    $HeroModeBox.size = New-Object System.Drawing.Size(($OoTReduxOptionsDialog.Width - 50), ($rowHeight * 4))
    $HeroModeBox.Text = " Hero Mode "
    $OoTReduxOptionsDialog.Controls.Add($HeroModeBox)

    # Create a panel for the Recovery buttons
    $DamagePanel = New-Object System.Windows.Forms.Panel
    $DamagePanel.Location = New-Object System.Drawing.Size($HeroModeBox.Left, ($labelHeight + 10 + $row * $rowHeight))
    $DamagePanel.size = New-Object System.Drawing.Size(($HeroModeBox.Width - 20), 20)
    $HeroModeBox.Controls.Add($DamagePanel)

    # 1X Damage (Checkbox)
    $global:1xDamageOoT = New-Object System.Windows.Forms.RadioButton
    $1xDamageOoT.Size = New-Object System.Drawing.Size(20, 20)
    $1xDamageOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $1xDamageOoT.Checked = $true
    $ToolTip.SetToolTip($1xDamageOoT, "Enemies deal normal damage")

    # 1X Damage (Description)
    $1xDamageLabel = New-Object System.Windows.Forms.Label
    $1xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $1xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $1xDamageLabel.Text = "1x Damage"
    $ToolTip.SetToolTip($1xDamageLabel, "Enemies deal normal damage")

    $column = 1

    # 2X Damage (Checkbox)
    $global:2xDamageOoT = New-Object System.Windows.Forms.RadioButton
    $2xDamageOoT.Size = New-Object System.Drawing.Size(20, 20)
    $2xDamageOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($2xDamageOoT, "Enemies deal twice as much damage")

    # 2X Damage (Description)
    $2xDamageLabel = New-Object System.Windows.Forms.Label
    $2xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $2xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $2xDamageLabel.Text = "2x Damage"
    $ToolTip.SetToolTip($2xDamageLabel, "Enemies deal twice as much damage")

    $column = 2

    # 4X Damage (Checkbox)
    $global:4xDamageOoT = New-Object System.Windows.Forms.RadioButton
    $4xDamageOoT.Size = New-Object System.Drawing.Size(20, 20)
    $4xDamageOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($4xDamageOoT, "Enemies deal four times as much damage")

    # 4X Damage (Description)
    $4xDamageLabel = New-Object System.Windows.Forms.Label
    $4xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $4xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $4xDamageLabel.Text = "4x Damage"
    $ToolTip.SetToolTip($4xDamageLabel, "Enemies deal four times as much damage")

    $column = 3

    # 8X Damage (Checkbox)
    $global:8xDamageOoT = New-Object System.Windows.Forms.RadioButton
    $8xDamageOoT.Size = New-Object System.Drawing.Size(20, 20)
    $8xDamageOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($8xDamageOoT, "Enemies deal eight times as much damage")

    # 8X Damage (Description)
    $8xDamageLabel = New-Object System.Windows.Forms.Label
    $8xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $8xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $8xDamageLabel.Text = "8x Damage"
    $ToolTip.SetToolTip($8xDamageLabel, "Enemies deal eight times as much damage")

    $DamagePanel.Controls.AddRange(@($1xDamageOoT, $2xDamageOoT, $4xDamageOoT, $8xDamageOoT, $1xDamageLabel, $2xDamageLabel, $4xDamageLabel, $8xDamageLabel))

    $row = 1
    $column = 0

    # Create a panel for the Recovery buttons
    $RecoveryPanel = New-Object System.Windows.Forms.Panel
    $RecoveryPanel.Location = New-Object System.Drawing.Size($HeroModeBox.Left, ($labelHeight + 10 + $row * $rowHeight))
    $RecoveryPanel.size = New-Object System.Drawing.Size(($HeroModeBox.Width - 20), 20)
    $HeroModeBox.Controls.Add($RecoveryPanel)

    # Normal Recovery (Checkbox)
    $global:NormalRecoveryOoT = New-Object System.Windows.Forms.RadioButton
    $NormalRecoveryOoT.Size = New-Object System.Drawing.Size(20, 20)
    $NormalRecoveryOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $NormalRecoveryOoT.Checked = $true
    $ToolTip.SetToolTip($NormalRecoveryOoT, "Recovery Hearts restore Link's health for their full amount (1 Heart)")

    # 1X Recovery (Description)
    $NormalRecoveryLabel = New-Object System.Windows.Forms.Label
    $NormalRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $NormalRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $NormalRecoveryLabel.Text = "1x Recovery"
    $ToolTip.SetToolTip($NormalRecoveryLabel, "Recovery Hearts restore Link's health for their full amount (1 Heart)")

    $column = 1

    # Half Recovery (Checkbox)
    $global:HalfRecoveryOoT = New-Object System.Windows.Forms.RadioButton
    $HalfRecoveryOoT.Size = New-Object System.Drawing.Size(20, 20)
    $HalfRecoveryOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($HalfRecoveryOoT, "Recovery Hearts restore Link's health for half their amount (1/2 Heart)")

    # Half Recovery (Description)
    $HalfRecoveryLabel = New-Object System.Windows.Forms.Label
    $HalfRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $HalfRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $HalfRecoveryLabel.Text = "1/2x Recovery"
    $ToolTip.SetToolTip($HalfRecoveryLabel, "Recovery Hearts restore Link's health for half their amount (1/2 Heart)")

    $column = 2

    # Quarter Recovery (Checkbox)
    $global:QuarterRecoveryOoT = New-Object System.Windows.Forms.RadioButton
    $QuarterRecoveryOoT.Size = New-Object System.Drawing.Size(20, 20)
    $QuarterRecoveryOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($QuarterRecoveryOoT, "Recovery Hearts restore Link's for a quarter of their amount (1/4 Heart)")

    # Quarter Recovery (Description)
    $QuarterRecoveryLabel = New-Object System.Windows.Forms.Label
    $QuarterRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $QuarterRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $QuarterRecoveryLabel.Text = "1/4x Recovery"
    $ToolTip.SetToolTip($QuarterRecoveryLabel, "Recovery Hearts restore Link's health for a quarter of their amount (1/4 Heart)")

    $column = 3

    # No Recovery (Checkbox)
    $global:NoRecoveryOoT = New-Object System.Windows.Forms.RadioButton
    $NoRecoveryOoT.Size = New-Object System.Drawing.Size(20, 20)
    $NoRecoveryOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($NoRecoveryOoT, "Recovery Hearts will not restore Link's health anymore")

    # No Recovery (Description)
    $NoRecoveryLabel = New-Object System.Windows.Forms.Label
    $NoRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $NoRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $NoRecoveryLabel.Text = "0x Recovery"
    $ToolTip.SetToolTip($NoRecoveryLabel, "Recovery Hearts will not restore Link's health anymore")

    $RecoveryPanel.Controls.AddRange(@($NormalRecoveryOoT, $HalfRecoveryOoT, $QuarterRecoveryOoT, $NoRecoveryOoT, $NormalRecoveryLabel, $HalfRecoveryLabel, $QuarterRecoveryLabel, $NoRecoveryLabel))

    $row = 3
    $column = 0

    # OHKO MODE (Checkbox)
    $global:OHKOModeOoT = New-Object System.Windows.Forms.Checkbox
    $OHKOModeOoT.Size = New-Object System.Drawing.Size(20, 20)
    $OHKOModeOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column + 15), ($row * $rowHeight - 5))
    $ToolTip.SetToolTip($OHKOModeOoT, "Enemies kill Link with just a single hit\`nPrepare too die a lot")

    # OKHO Damage (Description)
    $OHKOModeLabel = New-Object System.Windows.Forms.Label
    $OHKOModeLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $OHKOModeLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20 + 15),  ($row * $rowHeight + 3 - 5))
    $OHKOModeLabel.Text = "OHKO Mode"
    $ToolTip.SetToolTip($OHKOModeLabel, "Enemies kill Link with just a single hit\`nPrepare too die a lot")

    $HeroModeBox.Controls.AddRange(@($OHKOModeOoT, $OHKOModeLabel))

    # EVERYTHING ELSE #

    # Create a panel to contain everything for other.
    $CheckboxesPanel = New-Object System.Windows.Forms.Panel
    $CheckboxesPanel.Size = New-Object System.Drawing.Size($OoTReduxOptionsDialog.Width, 110)
    $CheckboxesPanel.Location = New-Object System.Drawing.Size($baseX, ($HeroModeBox.Bottom + 15))
    $OoTReduxOptionsDialog.Controls.Add($CheckboxesPanel)

    $row = 0
    $column = 0

    # Create a panel for the Text Speed buttons
    $TextPanel = New-Object System.Windows.Forms.Panel
    $TextPanel.Location = New-Object System.Drawing.Size(0, ($row * $rowHeight))
    $TextPanel.size = New-Object System.Drawing.Size($OoTReduxOptionsDialog.Width, ($labelHeight + 3))
    $CheckboxesPanel.Controls.Add($TextPanel)

    # 1X Text Speed (Checkbox)
    $global:1xTextOoT = New-Object System.Windows.Forms.RadioButton
    $1xTextOoT.Size = New-Object System.Drawing.Size(20, 20)
    $1xTextOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($1xTextOoT, "Leave the dialogue text speed at normal")

    # 1X Text Speed (Description)
    $1xTextLabel = New-Object System.Windows.Forms.Label
    $1xTextLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $1xTextLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $1xTextLabel.Text = "1x Text Speed"
    $ToolTip.SetToolTip($1xTextLabel, "Leave the dialogue text speed at normal")

    $column = 1

    # 2X Text Speed (Checkbox)
    $global:2xTextOoT = New-Object System.Windows.Forms.RadioButton
    $2xTextOoT.Size = New-Object System.Drawing.Size(20, 20)
    $2xTextOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $2xTextOoT.Checked = $true
    $ToolTip.SetToolTip($2xTextOoT, "Set the dialogue text speed to be twice as fast")

    # 2X Text Speed (Description)
    $2xTextLabel = New-Object System.Windows.Forms.Label
    $2xTextLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $2xTextLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $2xTextLabel.Text = "2x Text Speed"
    $ToolTip.SetToolTip($2xTextLabel, "Set the dialogue text speed to be twice as fast")

    $column = 2

    # 3X Text Speed (Checkbox)
    $global:3xTextOoT = New-Object System.Windows.Forms.RadioButton
    $3xTextOoT.Size = New-Object System.Drawing.Size(20, 20)
    $3xTextOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($3xTextOoT, "Set the dialogue text speed to be three times as fast")

    # 3X Text Speed (Description)
    $3xTextLabel = New-Object System.Windows.Forms.Label
    $3xTextLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $3xTextLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $3xTextLabel.Text = "3x Text Speed"
    $ToolTip.SetToolTip($3xTextLabel, "Set the dialogue text speed to be three times as fast")

    $TextPanel.Controls.AddRange(@($1xTextOoT, $2xTextOoT, $3xTextOoT, $1xTextLabel, $2xTextLabel, $3xTextLabel))

    $row = 1
    $column = 0

    # Increase Extended Draw Distance (Checkbox)
    $global:ExtendedDrawOoT = New-Object System.Windows.Forms.Checkbox
    $ExtendedDrawOoT.Size = New-Object System.Drawing.Size(20, 20)
    $ExtendedDrawOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($ExtendedDrawOoT)
    $ToolTip.SetToolTip($ExtendedDrawOoT, "Increases the game's draw distance for objects`nDoes not work on all objects")
    
    # Increase Extended Draw Distance (Description)
    $ExtendedDrawLabel = New-Object System.Windows.Forms.Label
    $ExtendedDrawLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $ExtendedDrawLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $ExtendedDrawLabel.Text = "Extended Draw Distance"
    $CheckboxesPanel.Controls.Add($ExtendedDrawLabel)
    $ToolTip.SetToolTip($ExtendedDrawLabel, "Increases the game's draw distance for objects`nDoes not work on all objects")

    $column = 1

    # Force Hires Link Model (Checkbox)
    $global:HiresModelOoT = New-Object System.Windows.Forms.Checkbox
    $HiresModelOoT.Size = New-Object System.Drawing.Size(20, 20)
    $HiresModelOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($HiresModelOoT)
    $ToolTip.SetToolTip($HiresModelOoT, "Always use Link's High Resolution Model when Link is too far away")
    
    # Force Hires Link Model (Description)
    $HiresModelLabel = New-Object System.Windows.Forms.Label
    $HiresModelLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $HiresModelLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $HiresModelLabel.Text = "Force Hires Link Model"
    $CheckboxesPanel.Controls.Add($HiresModelLabel)
    $ToolTip.SetToolTip($HiresModelLabel, "Always use Link's High Resolution Model when Link is too far away")

    $column = 2
    
    # Require All Medallions for Ganon's Castle (Checkbox)
    $global:MedallionsOoT = New-Object System.Windows.Forms.Checkbox
    $MedallionsOoT.Size = New-Object System.Drawing.Size(20, 20)
    $MedallionsOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($MedallionsOoT)
    $ToolTip.SetToolTip($MedallionsOoT, "All six medallions are required for the Rainbow Bridge to appear before Ganon's Castle`The vanilla requirements were the Shadow and Spirit Medallions and the Light Arrows")

    # All Medallions - Ganon's Castle (Description)
    $MedallionsLabel = New-Object System.Windows.Forms.Label
    $MedallionsLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $MedallionsLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $MedallionsLabel.Text = "Require All Medallions"
    $CheckboxesPanel.Controls.Add($MedallionsLabel)
    $ToolTip.SetToolTip($MedallionsLabel, "All six medallions are required for the Rainbow Bridge to appear before Ganon's Castle`nThe vanilla requirements were the Shadow and Spirit Medallions and the Light Arrows")

    $column = 3

    # Can Return to Child Before Clearing Forest Temple (Checkbox)
    $global:ReturnChildOoT = New-Object System.Windows.Forms.Checkbox
    $ReturnChildOoT.Size = New-Object System.Drawing.Size(20, 20)
    $ReturnChildOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($ReturnChildOoT)
    $ToolTip.SetToolTip($ReturnChildOoT, "You can always go back to being a child again before clearing the boss of the Forest Temple`nOut of the way Sheik!")

    # Can Return to Child Before Clearing Forest Temple (Description)
    $ReturnChildLabel = New-Object System.Windows.Forms.Label
    $ReturnChildLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $ReturnChildLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $ReturnChildLabel.Text = "Can Always Return"
    $CheckboxesPanel.Controls.Add($ReturnChildLabel)
    $ToolTip.SetToolTip($ReturnChildLabel, "You can always go back to being a child again before clearing the boss of the Forest Temple`nOut of the way Sheik!")

    $row = 2
    $column = 0

    # Unlock Tunics Child Link (Checkbox)
    $global:UnlockTunicsOoT = New-Object System.Windows.Forms.Checkbox
    $UnlockTunicsOoT.Size = New-Object System.Drawing.Size(20, 20)
    $UnlockTunicsOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($UnlockTunicsOoT)
    $ToolTip.SetToolTip($UnlockTunicsOoT, "Child Link is able to use the Goron TUnic and Zora Tunic`nSince you might want to walk around in style as well when you are young")

    # Unlock Tunics Child Link (Description)
    $UnlockTunicsLabel = New-Object System.Windows.Forms.Label
    $UnlockTunicsLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $UnlockTunicsLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $UnlockTunicsLabel.Text = "Unlock Tunics"
    $CheckboxesPanel.Controls.Add($UnlockTunicsLabel)
    $ToolTip.SetToolTip($UnlockTunicsLabel, "Child Link is able to use the Goron TUnic and Zora Tunic`nSince you might want to walk around in style as well when you are young")

    $column = 1

    # Unlock Boots Child Link (Checkbox)
    $global:UnlockBootsOoT = New-Object System.Windows.Forms.Checkbox
    $UnlockBootsOoT.Size = New-Object System.Drawing.Size(20, 20)
    $UnlockBootsOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($UnlockBootsOoT)
    $ToolTip.SetToolTip($UnlockBootsOoT, "Child Link is able to use the Iron Boots and Hover Boots")

    # Unlock Boots Child Link (Description)
    $UnlockBootsLabel = New-Object System.Windows.Forms.Label
    $UnlockBootsLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $UnlockBootsLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $UnlockBootsLabel.Text = "Unlock Boots"
    $CheckboxesPanel.Controls.Add($UnlockBootsLabel)
    $ToolTip.SetToolTip($UnlockBootsLabel, "Child Link is able to use the Iron Boots and Hover Boots")

    $column = 2

    # Unlock Kokiri Sword Adult Link (Checkbox)
    $global:UnlockSwordOoT = New-Object System.Windows.Forms.Checkbox
    $UnlockSwordOoT.Size = New-Object System.Drawing.Size(20, 20)
    $UnlockSwordOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($UnlockSwordOoT)
    $ToolTip.SetToolTip($UnlockSwordOoT, "Adult Link is able to use the Kokiri Sword`nThe Kokiri Sword does half as much damage as the Master Sword")
    
    # Unlock Kokiri Sword Adult Link (Description)
    $UnlockSwordLabel = New-Object System.Windows.Forms.Label
    $UnlockSwordLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $UnlockSwordLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), (3 + $row * $rowHeight + 3))
    $UnlockSwordLabel.Text = "Unlock Kokiri Sword"
    $CheckboxesPanel.Controls.Add($UnlockSwordLabel)
    $ToolTip.SetToolTip($UnlockSwordLabel, "Adult Link is able to use the Kokiri Sword`nThe Kokiri Sword does half as much damage as the Master Sword")

    $column = 3

    # Disable Low HP Beep (Checkbox)
    $global:DisableLowHPSoundOoT = New-Object System.Windows.Forms.Checkbox
    $DisableLowHPSoundOoT.Size = New-Object System.Drawing.Size(20, 20)
    $DisableLowHPSoundOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($DisableLowHPSoundOoT)
    $ToolTip.SetToolTip($DisableLowHPSoundOoT, "There will be absolute silence when Link's HP is getting low")

    # Disable Low HP Beep (Description)
    $DisableLowHPSoundLabel = New-Object System.Windows.Forms.Label
    $DisableLowHPSoundLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $DisableLowHPSoundLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $DisableLowHPSoundLabel.Text = "Disable Low HP Beep"
    $CheckboxesPanel.Controls.Add($DisableLowHPSoundLabel)
    $ToolTip.SetToolTip($DisableLowHPSoundLabel, "There will be absolute silence when Link's HP is getting low")

    $row = 3
    $column = 0

    # Remove Navi Proximity Prompts (Checkbox)
    $global:DisableNaviOoT = New-Object System.Windows.Forms.Checkbox
    $DisableNaviOoT.Size = New-Object System.Drawing.Size(20, 20)
    $DisableNaviOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($DisableNaviOoT)
    $ToolTip.SetToolTip($DisableNaviOoT, "Navi will no longer interupt your during the first dungeon with mandatory textboxes")

    # Remove Navi Proximity Prompts (Description)
    $DisableNaviLabel = New-Object System.Windows.Forms.Label
    $DisableNaviLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $DisableNaviLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $DisableNaviLabel.Text = "Remove Navi Prompts"
    $CheckboxesPanel.Controls.Add($DisableNaviLabel)
    $ToolTip.SetToolTip($DisableNaviLabel, "Navi will no longer interupt your during the first dungeon with mandatory textboxes`nThis occurs for example when opening your first door or pushing your first block")

    $column = 1

    # Remove Navi Proximity Prompts (Checkbox)
    $global:HideDPadOoT = New-Object System.Windows.Forms.Checkbox
    $HideDPadOoT.Size = New-Object System.Drawing.Size(20, 20)
    $HideDPadOoT.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($HideDPadOoT)
    $ToolTip.SetToolTip($HideDPadOoT, "Hide the D-Pad icon, while it is still active")

    # Remove Navi Proximity Prompts (Description)
    $HideDPadLabel = New-Object System.Windows.Forms.Label
    $HideDPadLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $HideDPadLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $HideDPadLabel.Text = "Hide D-Pad Icon"
    $CheckboxesPanel.Controls.Add($HideDPadLabel)
    $ToolTip.SetToolTip($HideDPadLabel, "Hide the D-Pad icons, while they is still active")



    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $ButtonX = [Math]::Floor($OoTReduxOptionsDialog.Width / 2) - [Math]::Floor($InfoOKButton.Width / 2)
    $InfoOKButton.Location = New-Object System.Drawing.Size($ButtonX, ($OoTReduxOptionsDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$OoTReduxOptionsDialog.Hide()})
    $OoTReduxOptionsDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateMajorasMaskReduxOptionsDialog() {
    
    # Create the dialog that displays more info.
    $global:MMReduxOptionsDialog = New-Object System.Windows.Forms.Form
    $MMReduxOptionsDialog.Text = $ScriptName
    $MMReduxOptionsDialog.Size = New-Object System.Drawing.Size(700, 400)
    $MMReduxOptionsDialog.MaximumSize = $MMReduxOptionsDialog.Size
    $MMReduxOptionsDialog.MinimumSize = $MMReduxOptionsDialog.Size
    $MMReduxOptionsDialog.MaximizeBox = $false
    $MMReduxOptionsDialog.MinimizeBox = $false
    $MMReduxOptionsDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $MMReduxOptionsDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MMReduxOptionsDialog.StartPosition = "CenterScreen"
    $MMReduxOptionsDialog.Icon = $ZeldaIcon2

    # Options Label
    $TextLabel = New-Object System.Windows.Forms.Label
    $TextLabel.Size = New-Object System.Drawing.Size(300, 15)
    $TextLabel.Location = New-Object System.Drawing.Size(30, 20)
    $TextLabel.Font = $VCPatchFont
    $TextLabel.Text = "Majora's Mask REDUX - Additional Options"
    $MMReduxOptionsDialog.Controls.Add($TextLabel)

    # Create Tooltip
    $ToolTip = new-Object System.Windows.Forms.ToolTip
    $ToolTip.AutoPopDelay = 32767
    $ToolTip.InitialDelay = 500
    $ToolTip.ReshowDelay = 0
    $ToolTip.ShowAlways = $true



    ##############
    # Checkboxex #
    ##############

    $row = 0
    $column = 0
    $labelWidth = 135
    $labelHeight = 15
    $baseX = 30
    $rowHeight = 30
    $columnWidth = $labelWidth + 20



    # Create a groupbox for the Hero Mode buttons
    $HeroModeBox = New-Object System.Windows.Forms.GroupBox
    $HeroModeBox.Location = New-Object System.Drawing.Size(($baseX - 15), 50)
    $HeroModeBox.size = New-Object System.Drawing.Size(($MMReduxOptionsDialog.Width - 50), ($rowHeight * 4))
    $HeroModeBox.Text = " Hero Mode "
    $MMReduxOptionsDialog.Controls.Add($HeroModeBox)

    # Create a panel for the Recovery buttons
    $DamagePanel = New-Object System.Windows.Forms.Panel
    $DamagePanel.Location = New-Object System.Drawing.Size($HeroModeBox.Left, ($labelHeight + 10 + $row * $rowHeight))
    $DamagePanel.size = New-Object System.Drawing.Size(($HeroModeBox.Width - 20), 20)
    $HeroModeBox.Controls.Add($DamagePanel)

    # 1X Damage (Checkbox)
    $global:1xDamageMM = New-Object System.Windows.Forms.RadioButton
    $1xDamageMM.Size = New-Object System.Drawing.Size(20, 20)
    $1xDamageMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $1xDamageMM.Checked = $true
    $ToolTip.SetToolTip($1xDamageMM, "Enemies deal normal damage")

    # 1X Damage (Description)
    $1xDamageLabel = New-Object System.Windows.Forms.Label
    $1xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $1xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $1xDamageLabel.Text = "1x Damage"
    $ToolTip.SetToolTip($1xDamageLabel, "Enemies deal normal damage")

    $column = 1

    # 2X Damage (Checkbox)
    $global:2xDamageMM = New-Object System.Windows.Forms.RadioButton
    $2xDamageMM.Size = New-Object System.Drawing.Size(20, 20)
    $2xDamageMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($2xDamageMM, "Enemies deal twice as much damage")

    # 2X Damage (Description)
    $2xDamageLabel = New-Object System.Windows.Forms.Label
    $2xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $2xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $2xDamageLabel.Text = "2x Damage"
    $ToolTip.SetToolTip($2xDamageLabel, "Enemies deal twice as much damage")

    $column = 2

    # 4X Damage (Checkbox)
    $global:4xDamageMM = New-Object System.Windows.Forms.RadioButton
    $4xDamageMM.Size = New-Object System.Drawing.Size(20, 20)
    $4xDamageMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($4xDamageMM, "Enemies deal four times as much damage")

    # 4X Damage (Description)
    $4xDamageLabel = New-Object System.Windows.Forms.Label
    $4xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $4xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $4xDamageLabel.Text = "4x Damage"
    $ToolTip.SetToolTip($4xDamageLabel, "Enemies deal four times as much damage")

    $column = 3

    # 8X Damage (Checkbox)
    $global:8xDamageMM = New-Object System.Windows.Forms.RadioButton
    $8xDamageMM.Size = New-Object System.Drawing.Size(20, 20)
    $8xDamageMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($8xDamageMM, "Enemies deal eight times as much damage")

    # 8X Damage (Description)
    $8xDamageLabel = New-Object System.Windows.Forms.Label
    $8xDamageLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $8xDamageLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $8xDamageLabel.Text = "8x Damage"
    $ToolTip.SetToolTip($8xDamageLabel, "Enemies deal eight times as much damage")

    $DamagePanel.Controls.AddRange(@($1xDamageMM, $2xDamageMM, $4xDamageMM, $8xDamageMM, $1xDamageLabel, $2xDamageLabel, $4xDamageLabel, $8xDamageLabel))

    $row = 1
    $column = 0

    # Create a panel for the Recovery buttons
    $RecoveryPanel = New-Object System.Windows.Forms.Panel
    $RecoveryPanel.Location = New-Object System.Drawing.Size($HeroModeBox.Left, ($labelHeight + 10 + $row * $rowHeight))
    $RecoveryPanel.size = New-Object System.Drawing.Size(($HeroModeBox.Width - 20), 20)
    $HeroModeBox.Controls.Add($RecoveryPanel)

    # Normal Recovery (Checkbox)
    $global:NormalRecoveryMM = New-Object System.Windows.Forms.RadioButton
    $NormalRecoveryMM.Size = New-Object System.Drawing.Size(20, 20)
    $NormalRecoveryMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $NormalRecoveryMM.Checked = $true
    $ToolTip.SetToolTip($NormalRecoveryMM, "Recovery Hearts restore Link's health for their full amount (1 Heart)")

    # 1X Recovery (Description)
    $NormalRecoveryLabel = New-Object System.Windows.Forms.Label
    $NormalRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $NormalRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $NormalRecoveryLabel.Text = "1x Recovery"
    $ToolTip.SetToolTip($NormalRecoveryLabel, "Recovery Hearts restore Link's health for their full amount (1 Heart)")

    $column = 1

    # Half Recovery (Checkbox)
    $global:HalfRecoveryMM = New-Object System.Windows.Forms.RadioButton
    $HalfRecoveryMM.Size = New-Object System.Drawing.Size(20, 20)
    $HalfRecoveryMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($HalfRecoveryMM, "Recovery Hearts restore Link's health for half their amount (1/2 Heart)")

    # Half Recovery (Description)
    $HalfRecoveryLabel = New-Object System.Windows.Forms.Label
    $HalfRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $HalfRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $HalfRecoveryLabel.Text = "1/2x Recovery"
    $ToolTip.SetToolTip($HalfRecoveryLabel, "Recovery Hearts restore Link's health for half their amount (1/2 Heart)")

    $column = 2

    # Quarter Recovery (Checkbox)
    $global:QuarterRecoveryMM = New-Object System.Windows.Forms.RadioButton
    $QuarterRecoveryMM.Size = New-Object System.Drawing.Size(20, 20)
    $QuarterRecoveryMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($QuarterRecoveryMM, "Recovery Hearts restore Link's for a quarter of their amount (1/4 Heart)")

    # Quarter Recovery (Description)
    $QuarterRecoveryLabel = New-Object System.Windows.Forms.Label
    $QuarterRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $QuarterRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $QuarterRecoveryLabel.Text = "1/4x Recovery"
    $ToolTip.SetToolTip($QuarterRecoveryLabel, "Recovery Hearts restore Link's health for a quarter of their amount (1/4 Heart)")

    $column = 3

    # No Recovery (Checkbox)
    $global:NoRecoveryMM = New-Object System.Windows.Forms.RadioButton
    $NoRecoveryMM.Size = New-Object System.Drawing.Size(20, 20)
    $NoRecoveryMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($NoRecoveryMM, "Recovery Hearts will not restore Link's health anymore")

    # No Recovery (Description)
    $NoRecoveryLabel = New-Object System.Windows.Forms.Label
    $NoRecoveryLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $NoRecoveryLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $NoRecoveryLabel.Text = "0x Recovery"
    $ToolTip.SetToolTip($NoRecoveryLabel, "Recovery Hearts will not restore Link's health anymore")

    $RecoveryPanel.Controls.AddRange(@($NormalRecoveryMM, $HalfRecoveryMM, $QuarterRecoveryMM, $NoRecoveryMM, $NormalRecoveryLabel, $HalfRecoveryLabel, $QuarterRecoveryLabel, $NoRecoveryLabel))

    $row = 3
    $column = 0

    # OHKO MODE (Checkbox)
    $global:OHKOModeMM = New-Object System.Windows.Forms.Checkbox
    $OHKOModeMM.Size = New-Object System.Drawing.Size(20, 20)
    $OHKOModeMM.Location = New-Object System.Drawing.Size(($columnWidth * $column + 15), ($row * $rowHeight - 5))
    $ToolTip.SetToolTip($OHKOModeMM, "Enemies kill Link with just a single hit\`nPrepare too die a lot")

    # OKHO Damage (Description)
    $OHKOModeLabel = New-Object System.Windows.Forms.Label
    $OHKOModeLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $OHKOModeLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20 + 15),  ($row * $rowHeight + 3 - 5))
    $OHKOModeLabel.Text = "OHKO Mode"
    $ToolTip.SetToolTip($OHKOModeLabel, "Enemies kill Link with just a single hit\`nPrepare too die a lot")

    $HeroModeBox.Controls.AddRange(@($OHKOModeMM, $OHKOModeLabel))



    # EVERYTHING ELSE #

    # Create a panel to contain everything for other.
    $CheckboxesPanel = New-Object System.Windows.Forms.Panel
    $CheckboxesPanel.Size = New-Object System.Drawing.Size($MMReduxOptionsDialog.Width, 100)
    $CheckboxesPanel.Location = New-Object System.Drawing.Size($baseX, ($HeroModeBox.Bottom + 15))
    $MMReduxOptionsDialog.Controls.Add($CheckboxesPanel)

    $row = 0
    $column = 0

    # Create a panel for the D-Pad buttons
    $DPadPanel = New-Object System.Windows.Forms.Panel
    $DPadPanel.Location = New-Object System.Drawing.Size(0, ($row * $rowHeight))
    $DPadPanel.size = New-Object System.Drawing.Size($MMReduxOptionsDialog.Width, ($labelHeight + 3))
    $CheckboxesPanel.Controls.Add($DPadPanel)

    # Right D-Pad (Checkbox)
    $global:RightDPadMM = New-Object System.Windows.Forms.RadioButton
    $RightDPadMM.Size = New-Object System.Drawing.Size(20, 20)
    $RightDPadMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $RightDPadMM.Checked = $true
    $ToolTip.SetToolTip($RightDPadMM, "Show the D-Pad icons on the right side of the HUD")

    # Right D-Pad (Description)
    $RightDPadLabel = New-Object System.Windows.Forms.Label
    $RightDPadLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $RightDPadLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $RightDPadLabel.Text = "D-Pad Icon on Right Side"
    $ToolTip.SetToolTip($RightDPadLabel, "Show the D-Pad icons on the right side of the HUD")

    $column = 1

    # Left D-Pad (Checkbox)
    $global:LeftDPadMM = New-Object System.Windows.Forms.RadioButton
    $LeftDPadMM.Size = New-Object System.Drawing.Size(20, 20)
    $LeftDPadMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($LeftDPadMM, "Show the D-Pad icons on the left side of the HUD")

    # Left D-Pad (Description)
    $LeftDPadLabel = New-Object System.Windows.Forms.Label
    $LeftDPadLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $LeftDPadLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $LeftDPadLabel.Text = "D-Pad Icon on Left Side"
    $ToolTip.SetToolTip($LeftDPadLabel, "Show the D-Pad icons on the left side of the HUD")

    $column = 2

    # Hide D-Pad (Checkbox)
    $global:HideDPadMM = New-Object System.Windows.Forms.RadioButton
    $HideDPadMM.Size = New-Object System.Drawing.Size(20, 20)
    $HideDPadMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), 0)
    $ToolTip.SetToolTip($HideDPadMM, "Hide the D-Pad icons, while they are still active")

    # Hide D-Pad (Description)
    $HideDPadLabel = New-Object System.Windows.Forms.Label
    $HideDPadLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $HideDPadLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), 3)
    $HideDPadLabel.Text = "Hide D-Pad Icon"
    $ToolTip.SetToolTip($HideDPadLabel, "Hide the D-Pad icons, while they are still active")

    $DPadPanel.Controls.AddRange(@($RightDPadMM, $LeftDPadMM, $HideDPadMM, $RightDPadLabel, $LeftDPadLabel, $HideDPadLabel))

    $row = 1
    $column = 0

    # Increase Extended Draw Distance (Checkbox)
    $global:ExtendedDrawMM = New-Object System.Windows.Forms.Checkbox
    $ExtendedDrawMM.Size = New-Object System.Drawing.Size(20, 20)
    $ExtendedDrawMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($ExtendedDrawMM)
    $ToolTip.SetToolTip($ExtendedDrawMM, "Increases the game's draw distance for objects`nDoes not work on all objects")
    
    # Increase Extended Draw Distance (Description)
    $ExtendedDrawLabel = New-Object System.Windows.Forms.Label
    $ExtendedDrawLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $ExtendedDrawLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $ExtendedDrawLabel.Text = "Extended Draw Distance"
    $CheckboxesPanel.Controls.Add($ExtendedDrawLabel)
    $ToolTip.SetToolTip($ExtendedDrawLabel, "Increases the game's draw distance for objects`nDoes not work on all objects")

    $column = 1

    # Permanent Razor Sword (Checkbox)
    $global:RazorSwordMM = New-Object System.Windows.Forms.Checkbox
    $RazorSwordMM.Size = New-Object System.Drawing.Size(20, 20)
    $RazorSwordMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($RazorSwordMM)
    $ToolTip.SetToolTip($RazorSwordMM, "The Razor Sword won't get destroyed after 100 it`nYou can also keep the Razor Sword when traveling back in time")

    # Permanent Razor Sword (Description)
    $RazorSwordLabel = New-Object System.Windows.Forms.Label
    $RazorSwordLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $RazorSwordLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $RazorSwordLabel.Text = "Permanent Razor Sword"
    $CheckboxesPanel.Controls.Add($RazorSwordLabel)
    $ToolTip.SetToolTip($RazorSwordLabel, "The Razor Sword won't get destroyed after 100 it`nYou can also keep the Razor Sword when traveling back in time")

    $column = 2

    # Disable Low HP Beep (Checkbox)
    $global:DisableLowHPSoundMM = New-Object System.Windows.Forms.Checkbox
    $DisableLowHPSoundMM.Size = New-Object System.Drawing.Size(20, 20)
    $DisableLowHPSoundMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($DisableLowHPSoundMM)
    $ToolTip.SetToolTip($DisableLowHPSoundMM, "There will be absolute silence when Link's HP is getting low")

    # Disable Low HP Beep (Description)
    $DisableLowHPSoundLabel = New-Object System.Windows.Forms.Label
    $DisableLowHPSoundLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $DisableLowHPSoundLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $DisableLowHPSoundLabel.Text = "Disable Low HP Beep"
    $CheckboxesPanel.Controls.Add($DisableLowHPSoundLabel)
    $ToolTip.SetToolTip($DisableLowHPSoundLabel, "There will be absolute silence when Link's HP is getting low")

    $column = 3

    # Restore 4th Heart Piece Sound (Checkbox)
    $global:PieceOfHeartSoundMM = New-Object System.Windows.Forms.Checkbox
    $PieceOfHeartSoundMM.Size = New-Object System.Drawing.Size(20, 20)
    $PieceOfHeartSoundMM.Location = New-Object System.Drawing.Size(($columnWidth * $column), ($row * $rowHeight))
    $CheckboxesPanel.Controls.Add($PieceOfHeartSoundMM)
    $ToolTip.SetToolTip($PieceOfHeartSoundMM, "Restore the sound effect when collecting the fourth Piece of Heart that grants Link a new Heart Container")

    # Restore 4th Piece of Heart Sound (Description)
    $PieceOfHeartSoundLabel = New-Object System.Windows.Forms.Label
    $PieceOfHeartSoundLabel.Size = New-Object System.Drawing.Size($labelWidth, $labelHeight)
    $PieceOfHeartSoundLabel.Location = New-Object System.Drawing.Size(($columnWidth * $column + 20), ($row * $rowHeight + 3))
    $PieceOfHeartSoundLabel.Text = "4th Piece of Heart Sound"
    $CheckboxesPanel.Controls.Add($PieceOfHeartSoundLabel)
    $ToolTip.SetToolTip($PieceOfHeartSoundLabel, "Restore the sound effect when collecting the fourth Piece of Heart that grants Link a new Heart Container")



    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $ButtonX = [Math]::Floor($MMReduxOptionsDialog.Width / 2) - [Math]::Floor($InfoOKButton.Width / 2)
    $InfoOKButton.Location = New-Object System.Drawing.Size($ButtonX, ($MMReduxOptionsDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$MMReduxOptionsDialog.Hide()})
    $MMReduxOptionsDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateInfoGameIDDialog() {
    
    # Create the dialog that displays more info.
    $global:InfoGameIDDialog = New-Object System.Windows.Forms.Form
    $InfoGameIDDialog.Text = $ScriptName
    $InfoGameIDDialog.Size = New-Object System.Drawing.Size(400, 560)
    $InfoGameIDDialog.MaximumSize = $InfoGameIDDialog.Size
    $InfoGameIDDialog.MinimumSize = $InfoGameIDDialog.Size
    $InfoGameIDDialog.MaximizeBox = $false
    $InfoGameIDDialog.MinimizeBox = $false
    $InfoGameIDDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoGameIDDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoGameIDDialog.StartPosition = "CenterScreen"
    $InfoGameIDDialog.Icon = $MarioIcon2

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += '{0}'
    $InfoString += "--- OFFICIAL GAMEID'S ---{0}"
    $InfoString += '- NACE = Ocarina of Time{0}'
    $InfoString += "- NARE = Majora's Mask{0}"
    $InfoString += '- NAAE = Super Mario 64{0}'
    $InfoString += '- NAEE = Paper Mario{0}'
    
    $InfoString += '{0}'
    $InfoString += "--- UNOFFICIAL GAMEID'S (Rom Hacks) ---{0}"
    $InfoString += '- NAC0 = Ocarina of Time REDUX{0}'
    $InfoString += '- NAC1 = Ocarina of Time: Dawn & Dusk{0}'
    $InfoString += "- NAR0 = Majora's Mask REDUX{0}"
    $InfoString += "- NAR1 = Majora's Mask: Masked Quest{0}"
    $InfoString += "- NAAX = Super Mario 64: 60 FPS v2{0}"
    $InfoString += "- NAAY = Super Mario 64: Analog Camera{0}"
    $InfoString += "- NAAM = Super Mario 64: Multiplayer v1.4.2{0}"
    $InfoString += "- NAE0 = Paper Mario: Hard Mode{0}"
    $InfoString += "- NAE1 = Paper Mario: Hard Mode+{0}"
    $InfoString += "- NAE2 = Paper Mario: Insane Mode{0}"

    $InfoString += '{0}'
    $InfoString += "--- UNOFFICIAL GAMEID'S (Translations) ---{0}"
    $InfoString += '- NACS = Ocarina of Time (Spanish){0}'
    $InfoString += '- NACO = Ocarina of Time (Polish){0}'
    $InfoString += '- NACR = Ocarina of Time (Russian){0}'
    $InfoString += '- NACC = Ocarina of Time (Chinese){0}'
    $InfoString += "- NARO = Majora's Mask (Polish){0}"
    $InfoString += "- NARR = Majora's Mask (Russian){0}"

    $InfoString += '{0}'
    $InfoString += "--- RECOMMENDED GAMEID'S (Custom Injection) ---{0}"
    $InfoString += '- NAQE = Master Quest {0}'
    $InfoString += '- NAQS = Master Quest (Spanish){0}'

    $InfoString += '{0}'
    $InfoString += "--- Instructions (Custom GameID and Channel Title) ---{0}"
    $InfoString += '- Can be overwritten for any patch or ROM injection{0}'
    $InfoString += '- Check the checkbox to enable override{0}'
    $InfoString += '- Custom GameID requires 4 characters for acceptance{0}'
    $InfoString += '- Incorrect length uses default values instead {0}'

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(350, ($InfoGameIDDialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoGameIDDialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(150, ($InfoGameIDDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoGameIDDialog.Hide()})
    $InfoGameIDDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateInfoOcarinaOfTimeDialog() {
    
    # Create the dialog that displays more info.
    $global:InfoOcarinaOfTimeDialog = New-Object System.Windows.Forms.Form
    $InfoOcarinaOfTimeDialog.Text = $ScriptName
    $InfoOcarinaOfTimeDialog.Size = New-Object System.Drawing.Size(400, 510)
    $InfoOcarinaOfTimeDialog.MaximumSize = $InfoOcarinaOfTimeDialog.Size
    $InfoOcarinaOfTimeDialog.MinimumSize = $InfoOcarinaOfTimeDialog.Size
    $InfoOcarinaOfTimeDialog.MaximizeBox = $false
    $InfoOcarinaOfTimeDialog.MinimizeBox = $false
    $InfoOcarinaOfTimeDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoOcarinaOfTimeDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoOcarinaOfTimeDialog.StartPosition = "CenterScreen"
    $InfoOcarinaOfTimeDialog.Icon = $ZeldaIcon2

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += "{0}"
    $InfoString += "Patches The Legend of Zelda: Ocarina of Time game WAD:{0}"
    $InfoString += "1. ROM Injection (requires .Z64 ROM){0}"
    $InfoString += "2. Free BPS Patching (requires .IPS or .BPS File){0}"
    $InfoString += "3. Two ROM hacks (OoT Redux, Dawn and Dusk){0}"
    $InfoString += "4. Four fan translations (Spanish, Polish, Russian, Chinese){0}"

    $InfoString += "{0}"
    $InfoString += "Known Issues:{0}"
    $InfoString += "- Trees show transparent outlines through walls (Dawn and Dusk){0}"

    $InfoString += "{0}"
    $InfoString += "Requirements:{0}"
    $InfoString += "- The Legend of Zelda: Ocarina of Time USA VC WAD File{0}"

    $InfoString += "{0}"
    $InfoString += "Instructions:{0}"
    $InfoString += "- Select WAD File{0}"
    $InfoString += "- Press one of several patching buttons{0}"
    $InfoString += "- Enable optional Remap D-Pad{0}"

    $InfoString += "{0}"
    $InfoString += "Information:{0}"
    $InfoString += "- Original WAD is preserved{0}"
    $InfoString += "- Few patches are compatible with existing AR/Gecko Codes{0}"
    $InfoString += "- Redux forces Expand Memory, Remap D-Pad and Leave D-Pad Up{0}"
    $InfoString += "- Most patches forces Downgrade{0}"
    
    $InfoString += "{0}"
    $InfoString += "Programs:{0}"
    $InfoString += "- Wad Packer/Wad Unpacker{0}"
    $InfoString += "- Floating IPS{0}"
    $InfoString += "- Wiimm's 'wszst' Tool{0}"
    $InfoString += "- Compress Tool{0}"
    $InfoString += "- ndec Tool{0}"
    $InfoString += "- TabExt Tool"

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(360, ($InfoOcarinaOfTimeDialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoOcarinaOfTimeDialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(140, ($InfoOcarinaOfTimeDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoOcarinaOfTimeDialog.Hide()})
    $InfoOcarinaOfTimeDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateInfoMajorasMaskDialog() {
    
    # Create the dialog that displays more info.
    $global:InfoMajorasMaskDialog = New-Object System.Windows.Forms.Form
    $InfoMajorasMaskDialog.Text = $ScriptName
    $InfoMajorasMaskDialog.Size = New-Object System.Drawing.Size(400, 540)
    $InfoMajorasMaskDialog.MaximumSize = $InfoMajorasMaskDialog.Size
    $InfoMajorasMaskDialog.MinimumSize = $InfoMajorasMaskDialog.Size
    $InfoMajorasMaskDialog.MaximizeBox = $false
    $InfoMajorasMaskDialog.MinimizeBox = $false
    $InfoMajorasMaskDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoMajorasMaskDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoMajorasMaskDialog.StartPosition = "CenterScreen"
    $InfoMajorasMaskDialog.Icon = $ZeldaIcon2

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += "{0}"
    $InfoString += "Patches The Legend of Zelda: Majora's Mask game WAD:{0}"
    $InfoString += "1. ROM Injection (requires .Z64 ROM){0}"
    $InfoString += "2. Free BPS Patching (requires .IPS or .BPS File){0}"
    $InfoString += "3. Two ROM hack (MM Redux, Masked Quest){0}"
    $InfoString += "4. Two fan translations (Polish, Russian){0}"

    $InfoString += "{0}"
    $InfoString += "Known Issues:{0}"
    $InfoString += "- Unknown{0}"

    $InfoString += "{0}"
    $InfoString += "Requirements:{0}"
    $InfoString += "- The Legend of Zelda: Majora's Mask USA VC WAD File{0}"

    $InfoString += "{0}"
    $InfoString += "Instructions:{0}"
    $InfoString += "- Select WAD File{0}"
    $InfoString += "- Press one of several patching buttons{0}"
    $InfoString += "- Enable optional Remap D-Pad{0}"

    $InfoString += "{0}"
    $InfoString += "Information:{0}"
    $InfoString += "- Original WAD is preserved{0}"
    $InfoString += "- Patches are mostly compatible with existing AR/Gecko Codes{0}"
    $InfoString += "- Redux forces Remap D-Pad {0}"
    $InfoString += "- Expand Memory renders AR/Gecko Codes unsuable{0}"
    
    $InfoString += "{0}"
    $InfoString += "Programs:{0}"
    $InfoString += "- Wad Packer/Wad Unpacker{0}"
    $InfoString += "- Floating IPS{0}"
    $InfoString += "- Wiimm's 'wszst' Tool{0}"
    $InfoString += "- Romchu Tool{0}"
    $InfoString += "- LZSS Compression Tool{0}"
    $InfoString += "- Compress Tool{0}"
    $InfoString += "- ndec Tool{0}"
    $InfoString += "- TabExt Tool"

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(360, ($InfoMajorasMaskDialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoMajorasMaskDialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(100, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(140, ($InfoMajorasMaskDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoMajorasMaskDialog.Hide()})
    $InfoMajorasMaskDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateInfoSuperMario64Dialog() {
    
    # Create the dialog that displays more info.
    $global:InfoSuperMario64Dialog = New-Object System.Windows.Forms.Form
    $InfoSuperMario64Dialog.Text = $ScriptName
    $InfoSuperMario64Dialog.Size = New-Object System.Drawing.Size(400, 500)
    $InfoSuperMario64Dialog.MaximumSize = $InfoSuperMario64Dialog.Size
    $InfoSuperMario64Dialog.MinimumSize = $InfoSuperMario64Dialog.Size
    $InfoSuperMario64Dialog.MaximizeBox = $false
    $InfoSuperMario64Dialog.MinimizeBox = $false
    $InfoSuperMario64Dialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoSuperMario64Dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoSuperMario64Dialog.StartPosition = "CenterScreen"
    $InfoSuperMario64Dialog.Icon = $SM64Icon1

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += '{0}'
    $InfoString += 'Patches Super Mario 64 game WAD:{0}'
    $InfoString += '1. ROM Injection (requires .Z64 ROM){0}'
    $InfoString += "2. Free BPS Patching (requires .IPS or .BPS File){0}"
    $InfoString += '3. Super Mario 64: 60 FPS v2 (Native 60 FPS support){0}'
    $InfoString += '4. Super Mario 64: Free Cam (Analog Camera){0}'
    $InfoString += '5. SM64: Multiplayer (V1.4.2){0}'

    $InfoString += '{0}'
    $InfoString += 'Known Issues:{0}'
    $InfoString += '- Mario camera is inoperable (60 FPS){0}'
    $InfoString += '- Intro demo is broken (60 FPS){0}'

    $InfoString += '{0}'
    $InfoString += 'Requirements:{0}'
    $InfoString += '- Super Mario 64 VC USA WAD File{0}'

    $InfoString += '{0}'
    $InfoString += 'Instructions:{0}'
    $InfoString += '- Select Super Mario 64 VC USA WAD File{0}'
    $InfoString += '- Press one of several patching buttons{0}'
    $InfoString += '- Original WAD is preserved{0}'

    $InfoString += '{0}'
    $InfoString += 'Information:{0}'
    $InfoString += '- Existing AR/Gecko codes still work (60 FPS / Analog Camera){0}'
    $InfoString += '- Existing AR/Gecko codes do not work (Multiplayer){0}'
    $InfoString += '- Enable second emulated controller (Analog Camera / Multiplayer){0}'
    $InfoString += '- Bind second emulated Control Stick to primary physical controller{0}'
    
    $InfoString += '{0}'
    $InfoString += 'Programs:{0}'
    $InfoString += '- Wad Packer/Wad Unpacker{0}'
    $InfoString += '- Floating IPS{0}'
    $InfoString += "- Wiimm's 'wszst' Tool"

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(350, ($InfoSuperMario64Dialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoSuperMario64Dialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(150, ($InfoSuperMario64Dialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoSuperMario64Dialog.Hide()})
    $InfoSuperMario64Dialog.Controls.Add($InfoOKButton)

}


#==============================================================================================================================================================================================
function CreateInfoPaperMarioDialog() {
    
    # Create the dialog that displays more info.
    $global:InfoPaperMarioDialog = New-Object System.Windows.Forms.Form
    $InfoPaperMarioDialog.Text = $ScriptName
    $InfoPaperMarioDialog.Size = New-Object System.Drawing.Size(400, 460)
    $InfoPaperMarioDialog.MaximumSize = $InfoPaperMarioDialog.Size
    $InfoPaperMarioDialog.MinimumSize = $InfoPaperMarioDialog.Size
    $InfoPaperMarioDialog.MaximizeBox = $false
    $InfoPaperMarioDialog.MinimizeBox = $false
    $InfoPaperMarioDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoPaperMarioDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoPaperMarioDialog.StartPosition = "CenterScreen"
    $InfoPaperMarioDialog.Icon = $SM64Icon2

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += '{0}'
    $InfoString += 'Patches Paper Mario game WAD:{0}'
    $InfoString += '1. ROM Injection (requires .Z64 ROM){0}'
    $InfoString += "2. Free BPS Patching (requires .IPS or .BPS File){0}"
    $InfoString += '3. Paper Mario: Hard Mode (Extra damage){0}'
    $InfoString += '4. Paper Mario: Hard Mode+ (Extra damage and enemy HP) {0}'
    $InfoString += '5. Paper Mario: Insane Mode (Insane damage){0}'

    $InfoString += '{0}'
    $InfoString += 'Known Issues:{0}'
    $InfoString += '- Unknown{0}'

    $InfoString += '{0}'
    $InfoString += 'Requirements:{0}'
    $InfoString += '- Paper Mario VC USA WAD File{0}'

    $InfoString += '{0}'
    $InfoString += 'Instructions:{0}'
    $InfoString += '- Select Paper Mario VC USA WAD File{0}'
    $InfoString += '- Press one of several patching buttons{0}'
    $InfoString += '- Original WAD is preserved{0}'

    $InfoString += '{0}'
    $InfoString += 'Information:{0}'
    $InfoString += '- Existing AR/Gecko codes still work{0}'
    
    $InfoString += '{0}'
    $InfoString += 'Programs:{0}'
    $InfoString += '- Wad Packer/Wad Unpacker{0}'
    $InfoString += '- Floating IPS{0}'
    $InfoString += "- Wiimm's 'wszst' Tool{0}"
    $InfoString += "- Romc Tool"

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(350, ($InfoPaperMarioDialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoPaperMarioDialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(150, ($InfoPaperMarioDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoPaperMarioDialog.Hide()})
    $InfoPaperMarioDialog.Controls.Add($InfoOKButton)

}


#==============================================================================================================================================================================================
function CreateInfoFreeDialog() {
    
    # Create the dialog that displays more info.
    $global:InfoFreeDialog = New-Object System.Windows.Forms.Form
    $InfoFreeDialog.Text = $ScriptName
    $InfoFreeDialog.Size = New-Object System.Drawing.Size(400, 410)
    $InfoFreeDialog.MaximumSize = $InfoFreeDialog.Size
    $InfoFreeDialog.MinimumSize = $InfoFreeDialog.Size
    $InfoFreeDialog.MaximizeBox = $false
    $InfoFreeDialog.MinimizeBox = $false
    $InfoFreeDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $InfoFreeDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $InfoFreeDialog.StartPosition = "CenterScreen"
    $InfoFreeDialog.Icon = $VIcon

    # Create the string that will be displayed on the window.
    $InfoString = $ScriptName + " (" + $Version + ")" + '{0}'

    $InfoString += '{0}'
    $InfoString += 'Patches Custom game WAD:{0}'
    $InfoString += '1. ROM Injection (requires .Z64 ROM){0}'
    $InfoString += "2. Free BPS Patching (requires .IPS or .BPS File){0}"

    $InfoString += '{0}'
    $InfoString += 'Known Issues:{0}'
    $InfoString += '- Unknown{0}'

    $InfoString += '{0}'
    $InfoString += 'Requirements:{0}'
    $InfoString += '- Any VC WAD File{0}'

    $InfoString += '{0}'
    $InfoString += 'Instructions:{0}'
    $InfoString += '- Select VC WAD File{0}'
    $InfoString += '- Press Inject ROM or Patch BPS{0}'
    $InfoString += '- Original WAD is preserved{0}'

    $InfoString += '{0}'
    $InfoString += 'Information:{0}'
    $InfoString += '- Existing AR/Gecko codes likely will not work{0}'
    
    $InfoString += '{0}'
    $InfoString += 'Programs:{0}'
    $InfoString += '- Wad Packer/Wad Unpacker{0}'
    $InfoString += '- Floating IPS{0}'
    $InfoString += "- Wiimm's 'wszst' Tool"

    $InfoString = [String]::Format($InfoString, [Environment]::NewLine)

    # Create a label to house the string.
    $InfoLabel = New-Object System.Windows.Forms.Label
    $InfoLabel.Size = New-Object System.Drawing.Size(350, ($InfoFreeDialog.Height - 110))
    $InfoLabel.Location = New-Object System.Drawing.Size(10, 10)
    $InfoLabel.Text = $InfoString
    $InfoFreeDialog.Controls.Add($InfoLabel)

    # Create a button to hide the dialog.
    $InfoOKButton = New-Object System.Windows.Forms.Button
    $InfoOKButton.Size = New-Object System.Drawing.Size(80, 35)
    $InfoOKButton.Location = New-Object System.Drawing.Size(150, ($InfoFreeDialog.Height - 90))
    $InfoOKButton.Text = 'Close'
    $InfoOKButton.Add_Click({$InfoFreeDialog.Hide()})
    $InfoFreeDialog.Controls.Add($InfoOKButton)

}



#==============================================================================================================================================================================================
function CreateCreditsDialog() {
    
    # Create the dialog that displays more info.
    $global:CreditsDialog = New-Object System.Windows.Forms.Form
    $CreditsDialog.Text = $ScriptName
    $CreditsDialog.Size = New-Object System.Drawing.Size(400, 620)
    $CreditsDialog.MaximumSize = $creditsDialog.Size
    $CreditsDialog.MinimumSize = $creditsDialog.Size
    $CreditsDialog.MaximizeBox = $false
    $CreditsDialog.MinimizeBox = $false
    $CreditsDialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Inherit
    $CreditsDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $CreditsDialog.StartPosition = "CenterScreen"
    $CreditsDialog.Icon = $ZeldaIcon3

    # Create the string that will be displayed on the window.
    $CreditsString = $ScriptName + " (" + $Version + ")" + '{0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Dawn and Dusk ---{0}'
    $CreditsString += '- Lead Development and Music: Captain Seedy-Eye{0}'
    $CreditsString += '- 64DD Porting: LuigiBlood{0}'
    $CreditsString += '- Special Thanks: PK-LOVE, BWIX, Hylian Modding{0}'
    $CreditsString += '- Testers:  Captain Seedy, LuigiBlood, Hard4Games, ZFG, Dry4Haz, Fig{0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Ocarina of Time REDUX ---{0}'
    $CreditsString += '- Maroc, ShadowOne, MattKimura, Roman971, TestRunnerSRL, AmazingAmpharos, Krimtonz, Fig, rlbond86, KevinPal, junglechief{0}'

    $CreditsString += '{0}'
    $CreditsString += "--- Majora's Mask REDUX ---{0}"
    $CreditsString += '- Maroc, Saneki{0}'

    $CreditsString += '{0}'
    $CreditsString += "--- Majora's Mask: Masked Quest ---{0}"
    $CreditsString += '- Garo-Mastah, Aroenai, CloudMax, fkualol, VictorHale, Ideka, Saneki{0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Translations Ocarina of Time ---{0}'
    $CreditsString += '- Spanish: eduardo_a2j (v2.2){0}'
    $CreditsString += '- Polish: RPG (v1.3){0}'
    $CreditsString += '- Russian: Zelda64rus (v2.32){0}'
    $CreditsString += '- Chinese Simplified: madcell (2009){0}'

    $CreditsString += '{0}'
    $CreditsString += "--- Translations Majora's Mask ---{0}"
    $CreditsString += '- Polish: RPG (v1.1){0}'
    $CreditsString += '- Russian: Zelda64rus (v2.0 Beta){0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Super Mario 64: 60 FPS v2 / Analog Camera ---{0}'
    $CreditsString += '- Kaze Emanuar{0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Super Mario 64: Multiplayer v1.4.2 ---{0}'
    $CreditsString += '- Skelux{0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Paper Mario: Hard Mode / Insane Mode ---{0}'
    $CreditsString += '- Skelux (Extra Damage), Knux5577 (Enemy HP){0}'

    $CreditsString += '{0}'
    $CreditsString += '--- Dolphin ---{0}'
    $CreditsString += '- Admentus (Testing and PowerShell patcher){0}'
    $CreditsString += '- Bighead (Initial PowerShell patcher){0}'
    $CreditsString += '- GhostlyDark (Testing and Assistance)'
    
    $CreditsString = [String]::Format($CreditsString, [Environment]::NewLine)

    # Create a label to house the string.
    $CreditsLabel = New-Object System.Windows.Forms.Label
    $CreditsLabel.Size = New-Object System.Drawing.Size(380, ($CreditsDialog.Height - 110))
    $CreditsLabel.Location = New-Object System.Drawing.Size(10, 10)
    $CreditsLabel.Text = $CreditsString
    $CreditsDialog.Controls.Add($CreditsLabel)

    # Create a button to hide the dialog.
    $CreditsOKButton = New-Object System.Windows.Forms.Button
    $CreditsOKButton.Size = New-Object System.Drawing.Size(100, 35)
    $CreditsOKButton.Location = New-Object System.Drawing.Size(140, ($CreditsDialog.Height - 90))
    $CreditsOKButton.Text = 'Close'
    $CreditsOKButton.Add_Click({$CreditsDialog.Hide()})
    $CreditsDialog.Controls.Add($CreditsOKButton)

}



#==============================================================================================================================================================================================

# Hide the PowerShell console from the user.
ShowPowerShellConsole -ShowConsole $false

# Set paths to all the files stored in the script.
$global:Files = SetFileParameters

# Create images from Base64 strings.
CreateImages

# Create the dialogs to show to the user.
CreateMainDialog
SetOcarinaOfTimeModeActive

CreateOcarinaOfTimeReduxOptionsDialog
CreateMajorasMaskReduxOptionsDialog
CreateInfoGameIDDialog
CreateInfoOcarinaOfTimeDialog
CreateInfoMajorasMaskDialog
CreateInfoSuperMario64Dialog
CreateInfoPaperMarioDialog
CreateInfoFreeDialog
CreateCreditsDialog

# Disable patching buttons
EnablePatchButtons -Enable $false

# Show the dialog to the user.
$MainDialog.ShowDialog() | Out-Null

Exit