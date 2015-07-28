;===============================================
/*

Quick Access Popup
Written using AutoHotkey_L v1.1.09.03+ (http://ahkscript.org/)
By Jean Lalonde (JnLlnd on AHKScript.org forum)
	
Based on FoldersPopup from the same author
https://github.com/JnLlnd/FoldersPopup
initialy inspired by Robert Ryan's script DirMenu v2 (rbrtryn on AutoHotkey.com forum)
http://www.autohotkey.com/board/topic/91109-favorite-folders-popup-menu-with-gui/
who was maybe inspired by Savage's script FavoriteFolders
http://www.autohotkey.com/docs/scripts/FavoriteFolders.htm
or Rexx version Folder Menu
http://www.autohotkey.com/board/topic/13392-folder-menu-a-popup-menu-to-quickly-change-your-folders/


BUGS

TO-DO
- build menu and POC actions
- add default hotkey to QAP Feature Object and show select default button in gui
- prevent 2 favorites to use the same .FavoriteHotkey
- check exclusion as "class contain the exclusion string"
- exclusion list in options
- adjust static control occurences showing cursor in WM_MOUSEMOVE
- review help text
- build menu "QAP Essentials" like My Special Folders
- add Support freeware to main menu if user did not donate

LATER
-----
* decode arguments placeholders {LOC}, ect.

HELP
* Update links to QAP website in Help
* Update links to QAP reviews in Donate
* fix hotkey names in help text

LANGUAGE

QAP FEATURES MENUS
* Does not support Folders in Explorer and Group menus for TC and FPc users


Version 6.0.2 alpha (2015-05-??)


Version: 6.0.1 alpha (2015-05-11)
* Replace "FoldersPopup" with "QuickAccessPopup"
* Update @Ahk2Exe-SetVersion with "6.0.1 alpha"
* Update strCurrentVersion with "6.0.1 alpha"
* Update @Ahk2Exe-SetDescription with "Most handy Windows launcher. Freeware!"
* Distinct variables strAppNameFile for "QuickAccessPopup" and strAppNameText for "Quick Access Popup"
* Update strCurrentBranch with "alpha"
* Adapt for alpha version without version checking for alpha branch
* Replace "FoldersPopup" with "QuickAccessPopup" in InitFileInstall, and language variable names
* Replace "strTempDir" with "g_strTempDir"

SEE PREVIOUS HISTORY on FoldersPopup's GitHub or in FoldersPopup.ahk file


VARIABLES NAMING CONVENTION
---------------------------

typNameOfVariable
^^^^^^^^^^^^^^^^^ description of the variable content, with name sections from general to specific

typeNameOfVariable
^^^^ type of variable, str for strings, int for integers (any size), dbl for reals (not used in this app),
     arr for arrays, obj for objects, menu for menus, etc.
  
g_typNameOfVariable
^ g_ for global, nothing for local

f_typNameOfVariable
^ f_ for form (Gui) variables

*/ 
;========================================================================================================================
!_010_COMPILER_DIRECTIVES:
;========================================================================================================================

; Doc: http://fincs.ahk4.net/Ahk2ExeDirectives.htm
; Note: prefix comma with `

;@Ahk2Exe-SetName Quick Access Popup
;@Ahk2Exe-SetDescription Quick Access Popup - Freeware launcher for Windows.
;@Ahk2Exe-SetVersion 6.0.1 alpha
;@Ahk2Exe-SetOrigFilename QuickAccessPopup.exe


;========================================================================================================================
!_011_INITIALIZATION:
;========================================================================================================================

#NoEnv
#SingleInstance force
#KeyHistory 0
ListLines, Off
DetectHiddenWindows, On
ComObjError(False) ; we will do our own error handling

; avoid error message when shortcut destination is missing
; see http://ahkscript.org/boards/viewtopic.php?f=5&t=4477&p=25239#p25236
DllCall("SetErrorMode", "uint", SEM_FAILCRITICALERRORS := 1)

; By default, the A_WorkingDir is A_ScriptDir.
; When the shortcut is created by Inno Setup, the working is set to the folder under {userappdata}.
; In portable mode, the user can set the working directory in his own Windows shortcut.
; If user enable "Run at startup", the "Start in:" shortcut option is set to the current A_WorkingDir.

; If A_WorkingDir equals A_ScriptDir and the file _do_not_remove_or_rename.txt is found in A_WorkingDir
; it means that QAP has been installed with the setup program but that it was launched directly in the
; Program Files directory instead of using the Start menu or Startup shortcuts. In this situation, we
; know that the working directory has not been set properly. The following lines will fix it.
if (A_WorkingDir = A_ScriptDir) and FileExist(A_WorkingDir . "\_do_not_remove_or_rename.txt")
	SetWorkingDir, %A_AppData%\QuickAccessPopup

; Force A_WorkingDir to A_ScriptDir if uncomplied (development environment)
;@Ahk2Exe-IgnoreBegin
; Start of code for development environment only - won't be compiled
; see http://fincs.ahk4.net/Ahk2ExeDirectives.htm
SetWorkingDir, %A_ScriptDir%
; to test user data directory: SetWorkingDir, %A_AppData%\QuickAccessPopup

ListLines, On
; / End of code for developement enviuronment only - won't be compiled
;@Ahk2Exe-IgnoreEnd

OnExit, CleanUpBeforeExit ; must be positioned before InitFileInstall to ensure deletion of temporary files

Gosub, InitFileInstall

Gosub, InitLanguageVariables

; --- Global variables

g_strAppNameFile := "QuickAccessPopup"
g_strAppNameText := "Quick Access Popup"
g_strCurrentVersion := "6.0.1" ; "major.minor.bugs" or "major.minor.beta.release"
g_strCurrentBranch := "alpha" ; "prod", "beta" or "alpha", always lowercase for filename
g_strAppVersion := "v" . g_strCurrentVersion . (g_strCurrentBranch <> "prod" ? " " . g_strCurrentBranch : "")

g_blnDiagMode := False
g_strDiagFile := A_WorkingDir . "\" . g_strAppNameFile . "-DIAG.txt"
g_strIniFile := A_WorkingDir . "\" . g_strAppNameFile . ".ini"

g_blnMenuReady := false

/* not needed here because initialized in LoadIniFile
g_objMenuInGui := Object() ; object of menu currently in Gui
g_objMenusIndex := Object() ; index of menus path used in Gui menu dropdown list and to access the menu object for a given menu path
g_objMainMenu := Object() ; object of menu structure entry point
*/
g_objMenuColumnBreaks := Object()

g_arrSubmenuStack := Object()
g_arrSubmenuStackPosition := Object()

g_objIconsFile := Object()
g_objIconsIndex := Object()

g_strMenuPathSeparator := ">" ; spaces before/after are added only when submenus are added
g_strGroupPathSeparator := "[]"
g_strGuiMenuSeparator := "----------------"
g_strGuiMenuColumnBreak := "==="

g_intListW := "" ; Gui width captured by GuiSize
g_strEscapePipe := "С��" ; used to escape pipe in ini file

g_objGuiControls := Object()

g_strMouseButtons := ""
g_arrMouseButtons := ""
g_arrMouseButtonsText := ""

g_strExclusionClassList := "|" ; must end with |

g_objClassIdOrPathByDefaultName := Object() ; used by InitSpecialFolders and CollectExplorers
g_objSpecialFolders := Object()
g_strSpecialFoldersList := ""

g_objQAPFeaturesCodeByDefaultName := Object()
g_objQAPFeatures := Object()
g_strQAPFeaturesList := ""

g_blnUseDirectoryOpus := ""
g_blnUseTotalCommander := ""
g_blnUseFPconnect := ""
g_strDirectoryOpusRtPath := ""
g_strFPconnectPath := ""
g_strFPconnectAppFilename := ""
g_strFPconnectTargetFilename := ""


; if the app runs from a zip file, the script directory is created under the system Temp folder
if InStr(A_ScriptDir, A_Temp) ; must be positioned after g_strAppNameFile is created
{
	Oops(lOopsZipFileError, g_strAppNameFile)
	ExitApp
}

;@Ahk2Exe-IgnoreBegin
; Start of code for developement environment only - won't be compiled
if (A_ComputerName = "JEAN-PC") ; for my home PC
	g_strIniFile := A_WorkingDir . "\" . g_strAppNameFile . "-HOME.ini"
else if InStr(A_ComputerName, "STIC") ; for my work hotkeys
	g_strIniFile := A_WorkingDir . "\" . g_strAppNameFile . "-WORK.ini"
; / End of code for developement environment only - won't be compiled
;@Ahk2Exe-IgnoreEnd

; Keep gosubs in this order
Gosub, InitSystemArrays
Gosub, InitLanguages
Gosub, InitLanguageArrays
Gosub, InitSpecialFolders
Gosub, InitQAPFeatures
Gosub, InitGuiControls

Gosub, LoadIniFile
; must be after LoadIniFile
IniWrite, %g_strCurrentVersion%, %g_strIniFile%, Global, % "LastVersionUsed" .  (g_strCurrentBranch = "alpha" ? "Alpha" : (g_strCurrentBranch = "beta" ? "Beta" : "Prod"))

if (g_blnDiagMode)
	Gosub, InitDiagMode
if (g_blnUseColors)
	Gosub, LoadThemeGlobal

; build even if blnDisplayFoldersInExplorerMenu (etc.) are false because they could become true
; no need to build Recent folders menu at startup since this menu is refreshed/recreated on demand
Gosub, BuildFoldersInExplorerMenuInit ; need to be initialized here - will be updated at each call to popup menu
; Gosub, BuildGroupMenuInit not needed with new Grup favorite type
Gosub, BuildClipboardMenuInit

Gosub, BuildMainMenu
Gosub, BuildGui
Gosub, BuildTrayMenu

; Gosub, GuiShow

if (g_blnCheck4Update)
	Gosub, Check4Update

IfExist, %A_Startup%\%g_strAppNameFile%.lnk ; update the shortcut in case the exe filename changed
{
	FileDelete, %A_Startup%\%g_strAppNameFile%.lnk
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%g_strAppNameFile%.lnk, %A_WorkingDir%
	Menu, Tray, Check, %lMenuRunAtStartup%
}

if (g_blnDisplayTrayTip)
	TrayTip, % L(lTrayTipInstalledTitle, g_strAppNameText, g_strAppVersion)
		, % L(lTrayTipInstalledDetail, g_strAppNameText
			, Hotkey2Text(strModifiers1, strMouseButton1, strOptionsKey1)
			, Hotkey2Text(strModifiers3, strMouseButton3, strOptionsKey3)
			, Hotkey2Text(strModifiers2, strMouseButton2, strOptionsKey2)
			, Hotkey2Text(strModifiers4, strMouseButton4, strOptionsKey4))
		, , 17 ; 1 info icon + 16 no sound)

g_blnMenuReady := true

; Load the cursor and start the "hook" - See WM_MOUSEMOVE function below
objCursor := DllCall("LoadCursor", "UInt", NULL, "Int", 32649, "UInt") ; IDC_HAND
OnMessage(0x200, "WM_MOUSEMOVE")

; To prevent double-click on image static controls to copy their path to the clipboard - See WM_LBUTTONDBLCLK function below
; see http://www.autohotkey.com/board/topic/94962-doubleclick-on-gui-pictures-puts-their-path-in-your-clipboard/#entry682595
OnMessage(0x203, "WM_LBUTTONDBLCLK")

; To popup menu when left click on the tray icon - See AHK_NOTIFYICON function below
OnMessage(0x404, "AHK_NOTIFYICON")

; Create a mutex to allow Inno Setup to detect if FP is running before uninstall or update
DllCall("CreateMutex", "uint", 0, "int", false, "str", g_strAppNameFile . "Mutex")

; DEBUG

; Gosub, BuildClipboardMenu
; Menu, g_menuClipboard, Show


return


;------------------------------------------------------------
;------------------------------------------------------------
#If, CanNavigate(A_ThisHotkey)
; empty - act as a handle for the "Hotkey, If" confition
#If
;------------------------------------------------------------
;------------------------------------------------------------


;------------------------------------------------------------
;------------------------------------------------------------
#If, CanLaunch(A_ThisHotkey)
; empty - act as a handle for the "Hotkey, If" confition
#If
;------------------------------------------------------------
;------------------------------------------------------------


;========================================================================================================================
!_012_HOTKEYS:
;========================================================================================================================

; Gui Hotkeys
#If WinActive(L(lGuiTitle, g_strAppNameText, g_strAppVersion)) ; main Gui title

^Up::
if (LV_GetCount("Selected") > 1)
	Gosub, GuiMoveMultipleFavoritesUp
else
	Gosub, GuiMoveFavoriteUp
return

^Down::
if (LV_GetCount("Selected") > 1)
	Gosub, GuiMoveMultipleFavoritesDown
else
	Gosub, GuiMoveFavoriteDown
return

^Right::
Gosub, HotkeyChangeMenu
return

^Left::
GuiControlGet, blnUpMenuVisible, Visible, f_picUpMenu
if (blnUpMenuVisible)
	Gosub, GuiGotoPreviousMenu
return

^A::
LV_Modify(0, "Select")
return

^N::
Gosub, GuiAddFavoriteSelectType
return

Enter::
if (LV_GetCount("Selected") > 1)
	Gosub, GuiMoveMultipleFavoritesToMenu
else
	Gosub, GuiEditFavorite
return

Del::
if (LV_GetCount("Selected") > 1)
	Gosub, GuiRemoveMultipleFavorites
else
	Gosub, GuiRemoveFavorite
return

#If
; End of Gui Hotkeys


;========================================================================================================================
; END OF HOTKEYS
;========================================================================================================================



;========================================================================================================================
!_015_INITIALIZATION_SUBROUTINES:
;========================================================================================================================

;-----------------------------------------------------------
InitFileInstall:
;-----------------------------------------------------------

g_strTempDir := A_WorkingDir . "\_temp"
FileCreateDir, %g_strTempDir%

FileInstall, FileInstall\QuickAccessPopup_LANG_DE.txt, %g_strTempDir%\QuickAccessPopup_LANG_DE.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_FR.txt, %g_strTempDir%\QuickAccessPopup_LANG_FR.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_NL.txt, %g_strTempDir%\QuickAccessPopup_LANG_NL.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_KO.txt, %g_strTempDir%\QuickAccessPopup_LANG_KO.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_SV.txt, %g_strTempDir%\QuickAccessPopup_LANG_SV.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_IT.txt, %g_strTempDir%\QuickAccessPopup_LANG_IT.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_ES.txt, %g_strTempDir%\QuickAccessPopup_LANG_ES.txt, 1
FileInstall, FileInstall\QuickAccessPopup_LANG_PT-BR.txt, %g_strTempDir%\QuickAccessPopup_LANG_PT-BR.txt, 1

FileInstall, FileInstall\default_browser_icon.html, %g_strTempDir%\default_browser_icon.html, 1

FileInstall, FileInstall\about-32.png, %g_strTempDir%\about-32.png
FileInstall, FileInstall\add_property-48.png, %g_strTempDir%\add_property-48.png
FileInstall, FileInstall\delete_property-48.png, %g_strTempDir%\delete_property-48.png
FileInstall, FileInstall\channel_mosaic-48.png, %g_strTempDir%\channel_mosaic-48.png
FileInstall, FileInstall\separator-26.png, %g_strTempDir%\separator-26.png
FileInstall, FileInstall\column-26.png, %g_strTempDir%\column-26.png
FileInstall, FileInstall\down_circular-26.png, %g_strTempDir%\down_circular-26.png
FileInstall, FileInstall\edit_property-48.png, %g_strTempDir%\edit_property-48.png
FileInstall, FileInstall\generic_sorting2-26-grey.png, %g_strTempDir%\generic_sorting2-26-grey.png
FileInstall, FileInstall\help-32.png, %g_strTempDir%\help-32.png
FileInstall, FileInstall\left-12.png, %g_strTempDir%\left-12.png
FileInstall, FileInstall\settings-32.png, %g_strTempDir%\settings-32.png
FileInstall, FileInstall\up-12.png, %g_strTempDir%\up-12.png
FileInstall, FileInstall\up_circular-26.png, %g_strTempDir%\up_circular-26.png

FileInstall, FileInstall\thumbs_up-32.png, %g_strTempDir%\thumbs_up-32.png
FileInstall, FileInstall\solutions-32.png, %g_strTempDir%\solutions-32.png
FileInstall, FileInstall\handshake-32.png, %g_strTempDir%\handshake-32.png
FileInstall, FileInstall\conference-32.png, %g_strTempDir%\conference-32.png
FileInstall, FileInstall\gift-32.png, %g_strTempDir%\gift-32.png

return
;-----------------------------------------------------------


;-----------------------------------------------------------
InitLanguageVariables:
;-----------------------------------------------------------

#Include %A_ScriptDir%\QuickAccessPopup_LANG.ahk

return
;-----------------------------------------------------------


;-----------------------------------------------------------
InitSystemArrays:
;-----------------------------------------------------------

; Hotkeys: ini names, hotkey variables name, default values, gosub label and Gui hotkey titles
strHotkeyNames := "NavigateOrLaunchHotkeyMouse|NavigateOrLaunchHotkeyKeyboard|PowerHotkeyMouse|PowerHotkeyKeyboard"
StringSplit, g_arrHotkeyNames, strHotkeyNames, |
strHotkeyDefaults := "MButton|#a|!MButton|!#a"
StringSplit, g_arrHotkeyDefaults, strHotkeyDefaults, |
g_arrHotkeys := Array ; initialized by LoadIniHotkeys
g_arrHotkeysPrevious := Array ; initialized by GuiOptions and checked in LoadIniHotkeys

g_strMouseButtons := "None|LButton|MButton|RButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight|"
; leave last | to enable default value on the last item
StringSplit, g_arrMouseButtons, g_strMouseButtons, |

; Icon files and index tested on Win 7 and Win 8.1. Not tested on Win 10.
strIconsMenus := "iconDesktop|iconDocuments|iconPictures|iconMyComputer|iconNetworkNeighborhood|iconControlPanel|iconRecycleBin"
	. "|iconRecentFolders|iconSpecialFolders|iconGroup|iconCurrentFolders"
	. "|iconRecentFolders|iconSettings|iconAddThisFolder|iconDonate|iconSubmenu|iconNetwork|iconUnknown|iconFolder"
	. "|iconGroupSave|iconGroupLoad|iconDownloads|iconTemplates|iconMyMusic|iconMyVideo|iconHistory|iconFavorites|iconTemporary|iconWinver"
	. "|iconFonts|iconApplication|iconClipboard|iconAbout|iconHelp|iconOptions|iconFTP"
strIconsFile := "imageres|imageres|imageres|imageres|imageres|imageres|imageres"
			. "|imageres|imageres|shell32|imageres"
			. "|imageres|imageres|imageres|imageres|shell32|imageres|shell32|shell32"
			. "|shell32|shell32|imageres|shell32|imageres|imageres|shell32|shell32|shell32|winver"
			. "|shell32|shell32|shell32|shell32|shell32|imageres|shell32"
strIconsIndex := "106|189|68|105|115|23|50"
			. "|113|203|99|96"
			. "|113|110|217|208|298|29|176|4"
			. "|297|46|176|55|104|179|240|87|153|1"
			. "|39|304|261|222|24|166|104"

StringSplit, arrIconsFile, strIconsFile, |
StringSplit, arrIconsIndex, strIconsIndex, |

Loop, Parse, strIconsMenus, |
{
	g_objIconsFile[A_LoopField] := A_WinDir . "\System32\" . arrIconsFile%A_Index% . (arrIconsFile%A_Index% = "winver" ? ".exe" : ".dll")
	g_objIconsIndex[A_LoopField] := arrIconsIndex%A_Index%
}
; example: g_objIconsFile["iconPictures"] and g_objIconsIndex["iconPictures"]

strFavoriteTypes := "Folder|Document|Application|Special|URL|FTP|QAP|Menu|Group"
StringSplit, g_arrFavoriteTypes, strFavoriteTypes, |
StringSplit, arrFavoriteTypesLabels, lDialogFavoriteTypesLabels, |
g_objFavoriteTypesLabels := Object()
StringSplit, arrFavoriteTypesLocationLabels, lDialogFavoriteTypesLocationLabels, |
g_objFavoriteTypesLocationLabels := Object()
; StringSplit, arrFavoriteTypesHelp, lDialogFavoriteTypesHelp, |
Loop, 9
	arrFavoriteTypesHelp%A_Index% := lDialogFavoriteTypesHelp%A_Index%
g_objFavoriteTypesHelp := Object()
StringSplit, arrFavoriteTypesShortNames, lDialogFavoriteTypesShortNames, |
g_objFavoriteTypesShortNames := Object()
Loop, %g_arrFavoriteTypes0%
{
	; example to display favorite type label: g_objFavoriteTypesLabels["Folder"], g_objFavoriteTypesLabels["Document"]
	g_objFavoriteTypesLabels.Insert(g_arrFavoriteTypes%A_Index%, arrFavoriteTypesLabels%A_Index%)
	g_objFavoriteTypesLocationLabels.Insert(g_arrFavoriteTypes%A_Index%, arrFavoriteTypesLocationLabels%A_Index%)
	g_objFavoriteTypesHelp.Insert(g_arrFavoriteTypes%A_Index%, arrFavoriteTypesHelp%A_Index%)
	g_objFavoriteTypesShortNames.Insert(g_arrFavoriteTypes%A_Index%, arrFavoriteTypesShortNames%A_Index%)
}

; 1 Basic Settings, 2 Menu Options, 3 Window Options, 4 Advanced Settings
StringSplit, g_arrFavoriteGuiTabs, lDialogAddFavoriteTabs, |

strHotkeyNames := ""
strHotkeyDefaults := ""
strIconsMenus := ""
strIconsFile := ""
strIconsIndex := ""
arrIconsFile := ""
arrIconsIndex := ""
strFavoriteTypes := ""
arrFavoriteTypesLabels := ""
arrFavoriteTypesLocationLabels := ""
arrFavoriteTypesHelp := ""
arrFavoriteTypesShortNames := ""

return
;-----------------------------------------------------------


;------------------------------------------------------------
InitLanguages:
;------------------------------------------------------------

IfNotExist, %g_strIniFile%
	; read language code from ini file created by the Inno Setup script in the user data folder
	IniRead, g_strLanguageCode, % A_WorkingDir . "\" . g_strAppNameFile . "-setup.ini", Global , LanguageCode, EN
else
	IniRead, g_strLanguageCode, %g_strIniFile%, Global, LanguageCode, EN

strLanguageFile := g_strTempDir . "\" . g_strAppNameFile . "_LANG_" . g_strLanguageCode . ".txt"
strReplacementForSemicolon := "!r4nd0mt3xt!" ; for non-comment semi-colons ";" escaped as ";;"

if FileExist(strLanguageFile)
{
	FileRead, strLanguageStrings, %strLanguageFile%
	Loop, Parse, strLanguageStrings, `n, `r
	{
		if (SubStr(A_LoopField, 1, 1) <> ";") ; skip comment lines
		{
			StringSplit, arrLanguageBit, A_LoopField, `t
			if SubStr(arrLanguageBit1, 1, 1) = "l"
				%arrLanguageBit1% := arrLanguageBit2
			StringReplace, %arrLanguageBit1%, %arrLanguageBit1%, ``n, `n, All
			
			if InStr(%arrLanguageBit1%, ";;") ; preserve escaped ; in string
				StringReplace, %arrLanguageBit1%, %arrLanguageBit1%, % ";;", %strReplacementForSemicolon%, A
			if InStr(%arrLanguageBit1%, ";")
				%arrLanguageBit1% := Trim(SubStr(%arrLanguageBit1%, 1, InStr(%arrLanguageBit1%, ";") - 1)) ; trim comment from ; and trim spaces and tabs
			if InStr(%arrLanguageBit1%, strReplacementForSemicolon) ; restore escaped ; in string
				StringReplace, %arrLanguageBit1%, %arrLanguageBit1%, %strReplacementForSemicolon%, % ";", A
		}
	}
}
else
	g_strLanguageCode := "EN"

strLanguageFile := ""
strReplacementForSemicolon := ""
strLanguageStrings := ""
arrLanguageBit := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
InitLanguageArrays:
;------------------------------------------------------------
StringSplit, g_arrOptionsTitles, lOptionsTitles, |
strOptionsLanguageCodes := "EN|FR|DE|NL|KO|SV|IT|ES|PT-BR"
StringSplit, g_arrOptionsLanguageCodes, strOptionsLanguageCodes, |
StringSplit, g_arrOptionsLanguageLabels, lOptionsLanguageLabels, |

loop, %g_arrOptionsLanguageCodes0%
	if (g_arrOptionsLanguageCodes%A_Index% = g_strLanguageCode)
		{
			g_strLanguageLabel := g_arrOptionsLanguageLabels%A_Index%
			break
		}

lDialogMouseButtonsText := lDialogMouseNone . "|" . lDialogMouseButtonsText ; use lDialogMouseNone because this is displayed
StringSplit, g_arrMouseButtonsText, lDialogMouseButtonsText, |

strOptionsLanguageCodes := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
InitSpecialFolders:
;------------------------------------------------------------

; Shell numeric Constants
; http://msdn.microsoft.com/en-us/library/windows/desktop/bb774096%28v=vs.85%29.aspx

; Shell Commands:
; http://www.sevenforums.com/tutorials/4941-shell-command.html
; http://www.eightforums.com/tutorials/6050-shell-commands-windows-8-a.html

; Environment system variables
; http://en.wikipedia.org/wiki/Environment_variable#Windows

; InitSpecialFolderObject(strClassIdOrPath, strShellConstant, intShellConstant, strAHKConstant, strDOpusAlias, strTCCommand
;	, strDefaultName, strDefaultIcon
;	, strUse4NavigateExplorer, strUse4NewExplorer, strUse4Dialog, strUse4Console, strUse4DOpus, strUse4TC, strUse4FPc)

; 		CLS: Class ID
;		SCT: Shell Constant Text
;		SCN: Shell Constant Numeric
;		DOA: Directory Opus Alias
;		TCC: Total Commander Commands
;		NEW: Open in new Explorer anyway
/*
NOTES
- Total Commander commands: cm_OpenDesktop (2121), cm_OpenDrives (2122), cm_OpenControls (2123), cm_OpenFonts (2124), cm_OpenNetwork (2125), cm_OpenPrinters (2126), cm_OpenRecycled (2127)
- DOpus see http://resource.dopus.com/viewtopic.php?f=3&t=23691
*/

;---------------------
; CLSID giving localized name and icon, with valid Shell Command

InitSpecialFolderObject("{D20EA4E1-3957-11d2-A40B-0C5020524153}", "Common Administrative Tools", -1, "", "commonadmintools", ""
	, "Administrative Tools", "" ; Outils d�administration
	, "CLS", "CLS", "NEW", "NEW", "DOA", "NEW", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "MyComputerFolder", 17, "", "mycomputer", 2122
	, "Computer", "" ; Ordinateur
	, "SCT", "SCT", "SCT", "NEW", "DOA", "TCC", "NEW") ; for 1,2,3 CLS works, 7 OK for FPc but CLS does not work with DoubleCommander
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{21EC2020-3AEA-1069-A2DD-08002B30309D}", "ControlPanelFolder", 3, "", "controls", 2123
	, "Control Panel (Icons view)", "" ; Tous les Panneaux de configuration
	, "SCT", "SCT", "NEW", "NEW", "DOA", "CLS", "NEW")
	; OK     OK      OK     OK    OK  NO-use NEW
InitSpecialFolderObject("{450D8FBA-AD25-11D0-98A8-0800361B1103}", "Personal", 5, "A_MyDocuments", "mydocuments", ""
	, "Documents", "" ; Mes documents
	, "SCT", "SCT", "AHK", "AHK", "DOA", "AHK", "AHK")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{ED228FDF-9EA8-4870-83b1-96b02CFE0D52}", "Games", -1, "", "", ""
	, "Games Explorer", "" ; Jeux
	, "SCT", "SCT", "NEW", "NEW", "NEW", "CLS", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}", "HomeGroupFolder", -1, "", "", ""
	, "HomeGroup", "" ; Groupe r�sidentiel
	, "SCT", "SCT", "SCT", "NEW", "NEW", "CLS", "NEW")
	; OK     OK      OK     OK    OK     OK
InitSpecialFolderObject("{031E4825-7B94-4dc3-B131-E946B44C8DD5}", "Libraries", -1, "", "libraries", ""
	, "Libraries", "" ; Biblioth�que
	, "SCT", "SCT", "SCT", "NEW", "DOA", "CLS", "NEW")
	; OK     OK      OK     OK     OK      OK
InitSpecialFolderObject("{7007ACC7-3202-11D1-AAD2-00805FC1270E}", "ConnectionsFolder", -1, "", "", ""
	, "Network Connections", "" ; Connexions r�seau
	, "SCT", "SCT", "NEW", "NEW", "NEW", "CLS", "NEW")
	; OK     OK      OK     OK     OK      OK
InitSpecialFolderObject("{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}", "NetworkPlacesFolder", 18, "", "network", 2125
	, "Network", "" ; R�seau
	, "SCT", "SCT", "SCT", "NEW", "DOA", "TCC", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{2227A280-3AEA-1069-A2DE-08002B30309D}", "PrintersFolder", -1, "", "printers", 2126
	, "Printers and Faxes", "" ; Imprimantes
	, "SCT", "SCT", "NEW", "NEW", "DOA", "TCC", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{645FF040-5081-101B-9F08-00AA002F954E}", "RecycleBinFolder", 0, "", "trash", 2127
	, "Recycle Bin", "" ; Corbeille
	, "SCT", "SCT", "NEW", "NEW", "DOA", "TCC", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{59031a47-3f72-44a7-89c5-5595fe6b30ee}", "Profile", -1, "", "profile", ""
	, lMenuUserFolder, "" ; Dossier de l'utilisateur
	, "SCT", "SCT", "SCT", "NEW", "DOA", "CLS", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{1f3427c8-5c10-4210-aa03-2ee45287d668}", "User Pinned", -1, "", "", ""
	, lMenuUserPinned, "" ; Epingl� par l'utilisateur
	, "SCT", "SCT", "SCT", "NEW", "NEW", "NEW", "NEW")
	; OK     OK      OK     OK    OK      OK
InitSpecialFolderObject("{BD84B380-8CA2-1069-AB1D-08000948534}", "Fonts", -1, "", "fonts", 2124
	, lMenuFonts, "iconFonts"
	, "SCT", "SCT", "NEW", "NEW", "DOA", "TCC", "NEW")
	; OK     OK      OK     OK    OK      OK

;---------------------
; CLSID giving localized name and icon, no valid Shell Command, must be open in a new Explorer using CLSID - to be tested with DOpus, TC and FPc

InitSpecialFolderObject("{B98A2BEA-7D42-4558-8BD1-832F41BAC6FD}", "", -1, "", "", ""
	, "Backup and Restore", "" ; Sauvegarder et restaurer
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{ED7BA470-8E54-465E-825C-99712043E01C}", "", -1, "", "", ""
	, "Control Panel (All Tasks)", "" ; Toutes les t�ches
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{323CA680-C24D-4099-B94D-446DD2D7249E}", "", -1, "", "favorites", ""
	, "Favorites", "" ; Favoris (<> Favorites (Internet))
	, "CLS", "CLS", "CLS", "NEW", "DOA", "NEW", "NEW")
InitSpecialFolderObject("{3080F90E-D7AD-11D9-BD98-0000947B0257}", "", -1, "", "", ""
	, "Flip 3D", "" ; Pas de traduction
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{6DFD7C5C-2451-11d3-A299-00C04F8EF6AF}", "", -1, "", "", ""
	, "Folder Options", "" ; Options des dossiers
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
if (A_OSVersion = "WIN_7") ; Performance Information and Tool not available on Win8+
	InitSpecialFolderObject("{78F3955E-3B90-4184-BD14-5397C15F1EFC}", "", -1, "", "", ""
		, "Performance Information and Tools", "" ; Informations et outils de performance
		, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{35786D3C-B075-49b9-88DD-029876E11C01}", "", -1, "", "", ""
	, "Portable Devices", "" ; Appareils mobiles
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{7be9d83c-a729-4d97-b5a7-1b7313c39e0a}", "", -1, "A_Programs", "programs", ""
	, lMenuProgramsFolderStartMenu, "" ; Menu D�marrer / Programmes (Menu Start/Programs)
	, "CLS", "CLS", "NEW", "AHK", "DOA", "AHK", "AHK")
InitSpecialFolderObject("{22877a6d-37a1-461a-91b0-dbda5aaebc99}", "", -1, "", "", ""
	, "Recent Places", "" ; Emplacements r�cents
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{3080F90D-D7AD-11D9-BD98-0000947B0257}", "", -1, "", "", ""
	, "Show Desktop", "" ; Afficher le Bureau
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")
InitSpecialFolderObject("{BB06C0E4-D293-4f75-8A90-CB05B6477EEE}", "", -1, "", "", ""
	, "System", "" ; Syst�me
	, "CLS", "CLS", "NEW", "NEW", "NEW", "NEW", "NEW")

;---------------------
; Path from registry (no CLSID), localized name and icon provided, no Shell Command - to be tested with DOpus, TC and FPc

RegRead, g_strDownloadPath, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, {374DE290-123F-4565-9164-39C4925E467B}
InitSpecialFolderObject(g_strDownloadPath, "", -1, "", "downloads", ""
	, lMenuDownloads, "iconDownloads"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
RegRead, strException, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, My Music
InitSpecialFolderObject(strException, "", -1, "", "mymusic", ""
	, lMenuMyMusic, "iconMyMusic"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
RegRead, strException, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, My Video
InitSpecialFolderObject(strException, "", -1, "", "myvideos", ""
	, lMenuMyVideo, "iconMyVideo"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
RegRead, strException, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Templates
InitSpecialFolderObject(strException, "", -1, "", "templates", ""
	, lMenuTemplates, "iconTemplates"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
RegRead, g_strMyPicturesPath, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, My Pictures
InitSpecialFolderObject(g_strMyPicturesPath, "", 39, "", "mypictures", ""
	, lMenuPictures, "iconPictures"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
RegRead, strException, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Favorites
InitSpecialFolderObject(strException, "", -1, "", "", ""
	, lMenuFavoritesInternet, "iconFavorites"
	, "CLS", "CLS", "CLS", "CLS", "CLS", "CLS", "CLS")

;---------------------
; Path under %APPDATA% (no CLSID), localized name and icon provided, no Shell Command - to be tested with DOpus, TC and FPc

InitSpecialFolderObject("%APPDATA%\Microsoft\Windows\Start Menu", "", -1, "A_StartMenu", "start", ""
	, lMenuStartMenu, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup", "", -1, "A_Startup", "startup", ""
	, lMenuStartup, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%", "", -1, "A_AppData", "appdata", ""
	, lMenuAppData, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%\Microsoft\Windows\Recent", "", -1, "", "recent", ""
	, lMenuRecentItems, "iconRecentFolders"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%\Microsoft\Windows\Cookies", "", -1, "", "cookies", ""
	, lMenuCookies, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%\Microsoft\Internet Explorer\Quick Launch", "", -1, "", "", ""
	, lMenuQuickLaunch, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "CLS", "CLS", "CLS")
InitSpecialFolderObject("%APPDATA%\Microsoft\SystemCertificates", "", -1, "", "", ""
	, lMenuSystemCertificates, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "CLS", "CLS", "CLS")

;---------------------
; Path under other environment variables (no CLSID), localized name and icon provided, no Shell Command - to be tested with DOpus, TC and FPc

InitSpecialFolderObject("%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu", "", -1, "A_StartMenuCommon", "commonstartmenu", ""
	, lMenuCommonStartMenu, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Startup", "", -1, "A_StartupCommon", "commonstartup", ""
	, lMenuCommonStartupMenu, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%ALLUSERSPROFILE%", "", -1, "A_AppDataCommon", "commonappdata", ""
	, lMenuCommonAppData, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%LOCALAPPDATA%\Microsoft\Windows\Temporary Internet Files", "", -1, "", "", ""
	, lMenuCache, "iconTemporary"
	, "CLS", "CLS", "CLS", "CLS", "CLS", "CLS", "CLS")
InitSpecialFolderObject("%LOCALAPPDATA%\Microsoft\Windows\History", "", -1, "", "history", ""
	, lMenuHistory, "iconHistory"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%ProgramFiles%", "", -1, "A_ProgramFiles", "programfiles", ""
	, lMenuProgramFiles, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
if (A_Is64bitOS)
	InitSpecialFolderObject("%ProgramFiles(x86)%", "", -1, "", "programfilesx86", ""
		, lMenuProgramFiles . " (x86)", "iconFolder"
		, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject("%PUBLIC%\Libraries", "", -1, "", "", ""
	, lMenuPublicLibraries, "iconFolder"
	, "CLS", "CLS", "CLS", "CLS", "CLS", "CLS", "CLS")

;---------------------
; Path under the Users folder (no CLSID, localized name and icon provided), no Shell Command

StringReplace, strPathUsername, A_AppData, \AppData\Roaming
StringReplace, strPathUsers, strPathUsername, \%A_UserName%

InitSpecialFolderObject(strPathUsers . "\Public", "Public", -1, "", "common", ""
	, "Public Folder", "" ; Public
	, "SCT", "SCT", "SCT", "CLS", "DOA", "CLS", "CLS")
	; OK     OK      OK     OK    OK      OK

;---------------------
; Path using AHK constants (no CLSID), localized name and icon provided, no Shell Command - to be tested with DOpus, TC and FPc

InitSpecialFolderObject(A_Desktop, "", 0, "A_Desktop", "desktop", 2121
	, lMenuDesktop, "iconDesktop"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "TCC", "CLS")
InitSpecialFolderObject(A_DesktopCommon, "", -1, "A_DesktopCommon", "commondesktopdir", ""
	, lMenuCommonDesktop, "iconDesktop"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject(A_Temp, "", -1, "A_Temp", "temp", ""
	, lMenuTemporaryFiles, "iconTemporary"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")
InitSpecialFolderObject(A_WinDir, "", -1, "A_WinDir", "windows", ""
	, "Windows", "iconWinver"
	, "CLS", "CLS", "CLS", "CLS", "DOA", "CLS", "CLS")

;------------------------------------------------------------
; Build folders list for dropdown

g_strSpecialFoldersList := ""
for strSpecialFolderName in g_objClassIdOrPathByDefaultName
	g_strSpecialFoldersList .= strSpecialFolderName . "|"
StringTrimRight, g_strSpecialFoldersList, g_strSpecialFoldersList, 1

strException := ""
strPathUsername := ""
strPathUsers := ""
strSpecialFolderName := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
InitSpecialFolderObject(strClassIdOrPath, strShellConstantText, intShellConstantNumeric, strAHKConstant, strDOpusAlias, strTCCommand
	, strDefaultName, strDefaultIcon
	, strUse4NavigateExplorer, strUse4NewExplorer, strUse4Dialog, strUse4Console, strUse4DOpus, strUse4TC, strUse4FPc)

; strClassIdOrPath: CLSID or Path, used as key to access objSpecialFolder objects
;		CLSID Win_7: http://www.sevenforums.com/tutorials/110919-clsid-key-list-windows-7-a.html
;		CLSID Win_8: http://www.eightforums.com/tutorials/13591-clsid-key-guid-shortcuts-list-windows-8-a.html
; 		Environment system variables: http://en.wikipedia.org/wiki/Environment_variable#Windows
;		HKEY_CLASSES_ROOT Key: http://msdn.microsoft.com/en-us/library/windows/desktop/ms724475(v=vs.85).aspx
; 		NOTES How to call in Explorer...
;		... CLSID: shell:::{{20D04FE0-3AEA-1069-A2D8-08002B30309D}}
;		... ShellConstant: shell:MyComputerFolder

; strShellConstantText: text constant used to navigate using Explorer or Dialog box? What with DOpus and TC?
;		http://www.sevenforums.com/tutorials/4941-shell-command.html
;		http://www.eightforums.com/tutorials/6050-shell-commands-windows-8-a.html

; intShellConstantNumeric: numeric ShellSpecialFolderConstants constant 
;		http://msdn.microsoft.com/en-us/library/windows/desktop/bb774096%28v=vs.85%29.aspx

; CLSID, strShellConstantText (by version XP!, Vista, 7) and intShellConstantNumeric: http://docs.rainmeter.net/tips/launching-windows-special-folders

; strAHKConstant: AutoHotkey constant

; strDOpusAlias: Directory Opus constant

; strTCCommand: Total Commander constant

; strDefaultName: name for menu if path is used, fallback name if CLSID is used to access localized name

; strDefaultIcon: icon in strIconsMenus if path is used, fallback icon (?) if CLSID returns no icon resource

; Constants for "use" flags:
; 		CLS: Class ID
;		SCT: Shell Constant Text
;		SCN: Shell Constant Numeric
;		DOA: Directory Opus Alias
;		TCC: Total Commander Commands

; Usage flags:
; 		strUse4NavigateExplorer
; 		strUse4NewExplorer
; 		strUse4Dialog
; 		strUse4Console
; 		strUse4DOpus
; 		strUse4TC
;		strUse4FPc

; Special Folder Object (objOneSpecialFolder) definition:
;		strClassIdOrPath: key to access one Special Folder object (example: g_objSpecialFolders[strClassIdOrPath], saved to ini file
;		objSpecialFolder.ShellConstantText: text constant used to navigate using Explorer or Dialog box? What with DOpus and TC?
;		objSpecialFolder.ShellConstantNumeric: numeric ShellSpecialFolderConstants constant 
;		objSpecialFolder.AHKConstant: AutoHotkey constant
;		objSpecialFolder.DOpusAlias: Directory Opus constant
;		objSpecialFolder.TCCommand: Total Commander constant
;		objSpecialFolder.DefaultName:
;		objSpecialFolder.DefaultIcon: icon resource name in the format "file,index"
;		objSpecialFolder.Use4NavigateExplorer:
;		objSpecialFolder.Use4NewExplorer:
;		objSpecialFolder.Use4Dialog:
;		objSpecialFolder.Use4Console:
;		objSpecialFolder.Use4DOpus:
;		objSpecialFolder.Use4TC:
;		objSpecialFolder.Use4FPc:

;------------------------------------------------------------
{
	global g_objIconsFile
	global g_objIconsIndex
	global g_objClassIdOrPathByDefaultName
	global g_objSpecialFolders
	
	objOneSpecialFolder := Object()
	
	blnIsClsId := (SubStr(strClassIdOrPath, 1, 1) = "{")

	if (blnIsClsId)
		strThisDefaultName := GetLocalizedNameForClassId(strClassIdOrPath)
	If !StrLen(strThisDefaultName)
		strThisDefaultName := strDefaultName
    g_objClassIdOrPathByDefaultName.Insert(strThisDefaultName, strClassIdOrPath)
	objOneSpecialFolder.DefaultName := strThisDefaultName
	
	if (blnIsClsId)
		strThisDefaultIcon := GetIconForClassId(strClassIdOrPath)
	if !StrLen(strThisDefaultIcon) and StrLen(g_objIconsFile[strDefaultIcon]) and StrLen(g_objIconsIndex[strDefaultIcon])
		strThisDefaultIcon := g_objIconsFile[strDefaultIcon] . "," . g_objIconsIndex[strDefaultIcon]
	if !StrLen(strThisDefaultIcon)
		strThisDefaultIcon := "%SystemRoot%\System32\shell32.dll,4"
	objOneSpecialFolder.DefaultIcon := strThisDefaultIcon

	objOneSpecialFolder.ShellConstantText := strShellConstantText
	objOneSpecialFolder.ShellConstantNumeric := intShellConstantNumeric
	objOneSpecialFolder.AHKConstant := strAHKConstant
	objOneSpecialFolder.DOpusAlias := strDOpusAlias
	objOneSpecialFolder.TCCommand := strTCCommand
	
	objOneSpecialFolder.Use4NavigateExplorer := strUse4NavigateExplorer
	objOneSpecialFolder.Use4NewExplorer := strUse4NewExplorer
	objOneSpecialFolder.Use4Dialog := strUse4Dialog
	objOneSpecialFolder.Use4Console := strUse4Console
	objOneSpecialFolder.Use4DOpus := strUse4DOpus
	objOneSpecialFolder.Use4TC := strUse4TC
	objOneSpecialFolder.Use4FPc := strUse4FPc
	
	g_objSpecialFolders.Insert(strClassIdOrPath, objOneSpecialFolder)
}
;------------------------------------------------------------


;------------------------------------------------------------
GetLocalizedNameForClassId(strClassId)
;------------------------------------------------------------
{
    /*
        Question: What's the best Registry key should I use for this to work on Win 7, 8+ ?
		
        HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}
        HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}
        HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}
        HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Wow6432Node\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}
        HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}
		
		Seems to be HKEY_CLASSES_ROOT for XP compatibility accorging to
		http://msdn.microsoft.com/en-us/library/windows/desktop/ms724475(v=vs.85).aspx
		But what if XP support is not needed in QAP?
		
		See: http://superuser.com/questions/916401/registry-keys-for-clsid-info
    */
    RegRead, strLocalizedString, HKEY_CLASSES_ROOT, CLSID\%strClassId%, LocalizedString
    ; strLocalizedString example: "@%SystemRoot%\system32\shell32.dll,-9216"

    StringSplit, arrLocalizedString, strLocalizedString, `,
    intDllNameStart := InStr(arrLocalizedString1, "\", , 0)
    StringRight, strDllFile, arrLocalizedString1, % StrLen(arrLocalizedString1) - intDllNameStart
    strDllIndex := arrLocalizedString2
    strTranslatedName := TranslateMUI(strDllFile, Abs(strDllIndex))
    
	/*
    MsgBox, % ""
        . "strClassId: " . strClassId . "`n"
        . "strLocalizedString: " . strLocalizedString . "`n"
        . "strDllFile: " . strDllFile . "`n"
        . "strDllIndex: " . strDllIndex . "`n"
        . "strTranslatedName: " . strTranslatedName . "`n"
    */
	
    return strTranslatedName
}
;------------------------------------------------------------


;------------------------------------------------------------
GetIconForClassId(strClassId)
;------------------------------------------------------------
{
	RegRead, strDefaultIcon, HKEY_CLASSES_ROOT, CLSID\%strClassId%\DefaultIcon
    return strDefaultIcon
}
;------------------------------------------------------------


;------------------------------------------------------------
TranslateMUI(resDll, resID)
; source: 7plus (https://github.com/7plus/7plus/blob/master/MiscFunctions.ahk)
;------------------------------------------------------------
{
	VarSetCapacity(buf, 256) 
	hDll := DllCall("LoadLibrary", "str", resDll, "Ptr") 
	Result := DllCall("LoadString", "Ptr", hDll, "uint", resID, "str", buf, "int", 128)
	return buf
}
;------------------------------------------------------------


;------------------------------------------------------------
InitQAPFeatures:
;------------------------------------------------------------

; InitQAPFeatureObject(strQAPFeatureCode, strThisDefaultName, strQAPFeatureMenu, strQAPFeatureCommand, strThisDefaultIcon
;	, strUse4NavigateExplorer, strUse4NewExplorer, strUse4Dialog, strUse4Console, strUse4DOpus, strUse4TC, strUse4FPc)

; Constants for "use" flags:
; 		NAV: Navigate
;		NEW: New Explorer
;		NOT: Not supported

; Usage flags:
; 		strUse4NavigateExplorer
; 		strUse4NewExplorer
; 		strUse4Dialog
; 		strUse4Console
; 		strUse4DOpus
; 		strUse4TC
;		strUse4FPc

InitQAPFeatureObject("Current Folders", lMenuCurrentFolders, ":g_menuFoldersInExplorer", "FoldersInExplorerMenuShortcut:", "iconCurrentFolders"
	, "NAV", "NEW", "NAV", "NAV", "NAV", "NOT", "NOT")
; removed InitQAPFeatureObject("Manage Groups", lMenuGroupManage . "...", "", "GuiGroupsManage:", "iconGroup"
;	, "NAV", "NEW", "NAV", "NAV", "NAV", "NAV", "NAV")
InitQAPFeatureObject("Recent Folders", lMenuRecentFolders, "", "RefreshRecentFolders:", "iconRecentFolders"
	, "NAV", "NEW", "NAV", "NAV", "NAV", "NAV", "NAV")
InitQAPFeatureObject("Clipboard", lMenuClipboard, ":g_menuClipboard", "ClipboardMenuShortcut:", "iconClipboard"
	, "NAV", "NEW", "NAV", "NAV", "NAV", "NAV", "NAV")

InitQAPFeatureObject("About", lGuiAbout . "...", "", "GuiAbout:", "iconAbout")
InitQAPFeatureObject("Support", lGuiDonate . "...", "", "GuiDonate:", "iconDonate"
	, "NOT", "NOT", "NOT", "NOT", "NOT", "NOT", "NOT")
InitQAPFeatureObject("Help", lGuiHelp . "...", "", "GuiHelp:", "iconHelp")
InitQAPFeatureObject("Options", lGuiOptions . "...", "", "GuiOptions:", "iconOptions")
InitQAPFeatureObject("Add This Folder", lMenuAddThisFolder . "...", "", "AddThisFolder:", "iconAddThisFolder")
InitQAPFeatureObject("Copy a Favorite's Path or URL", lMenuCopyLocation, "", "PopupMenuCopyLocation:", "iconClipboard")
; removed InitQAPFeatureObject("Groups of Favorites", lMenuGroup, ":g_menuGroups", "GroupsMenuShortcut:", "iconGroup")
InitQAPFeatureObject("Settings", L(lMenuSettings, g_strAppNameText) . "...", "", "SettingsHotkey:", "iconSettings")

;------------------------------------------------------------
; Build folders list for dropdown

g_strQAPFeaturesList := ""
for strQAPFeatureName in g_objQAPFeaturesCodeByDefaultName
	g_strQAPFeaturesList .= strQAPFeatureName . "|"
StringTrimRight, g_strQAPFeaturesList, g_strQAPFeaturesList, 1

strQAPFeatureName := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
InitQAPFeatureObject(strQAPFeatureCode, strThisDefaultName, strQAPFeatureMenu, strQAPFeatureCommand, strThisDefaultIcon
	, strUse4NavigateExplorer := "NOT", strUse4NewExplorer := "NOT", strUse4Dialog := "NOT", strUse4Console := "NOT", strUse4DOpus := "NOT", strUse4TC := "NOT", strUse4FPc := "NOT")

; QAP Feature Objects (g_objQAPFeatures) definition:
;		Key: strQAPFeatureInternalName
;		Value: objOneQAPFeature

; QAP Features Object (objOneQAPFeature) definition:
;		objOneQAPFeature.DefaultName: QAP Feature localized label, key to access one QAP Feature object (example: g_objQAPFeatures[strThisDefaultName]
;		strQAPFeatureMenu: menu to be added to the menu (including the starting ":"), empty if no submenu associated to this QAP feature
;		strQAPFeatureCommand: command to be executed when this favorite is selected (including the ending ":"), empty if no command associated to this QAP feature
;		objOneQAPFeature.DefaultIcon: default icon (in the "file,index" format)
;		objOneQAPFeature.Use4NavigateExplorer:
;		objOneQAPFeature.Use4NewExplorer:
;		objOneQAPFeature.Use4Dialog:
;		objOneQAPFeature.Use4Console:
;		objOneQAPFeature.Use4DOpus:
;		objOneQAPFeature.Use4TC:
;		objOneQAPFeature.Use4FPc:

;------------------------------------------------------------
{
	global g_objIconsFile
	global g_objIconsIndex
	global g_objQAPFeatures
	global g_objQAPFeaturesCodeByDefaultName
	
	objOneQAPFeature := Object()
	
	objOneQAPFeature.DefaultName := strThisDefaultName
	objOneQAPFeature.DefaultIcon := g_objIconsFile[strThisDefaultIcon] . "," . g_objIconsIndex[strThisDefaultIcon]
	objOneQAPFeature.Use4NavigateExplorer := strUse4NavigateExplorer
	objOneQAPFeature.Use4NewExplorer := strUse4NewExplorer
	objOneQAPFeature.Use4Dialog := strUse4Dialog
	objOneQAPFeature.Use4Console := strUse4Console
	objOneQAPFeature.Use4DOpus := strUse4DOpus
	objOneQAPFeature.Use4TC := strUse4TC
	objOneQAPFeature.Use4FPc := strUse4FPc
	
	g_objQAPFeatures.Insert("{" . strQAPFeatureCode . "}", objOneQAPFeature)
	g_objQAPFeaturesCodeByDefaultName.Insert(strThisDefaultName, "{" . strQAPFeatureCode . "}")
}
;------------------------------------------------------------


;------------------------------------------------------------
InitGuiControls:
;------------------------------------------------------------

; Order of controls important to avoid drawgins gliches when resizing

InsertGuiControlPos("f_lnkGuiDropHelpClicked",	 -88, -130)
InsertGuiControlPos("f_lnkGuiHotkeysHelpClicked",	  40, -130)

InsertGuiControlPos("f_picGuiOptions",			 -44,   10, true) ; true = center
InsertGuiControlPos("f_picGuiAddFavorite",		 -44,  122, true)
InsertGuiControlPos("f_picGuiEditFavorite",		 -44,  199, true)
InsertGuiControlPos("f_picGuiRemoveFavorite",		 -44,  274, true)
InsertGuiControlPos("f_picGuiGroupsManage",		 -44, -150, true, true) ; true = center, true = draw
InsertGuiControlPos("f_picGuiDonate",				  50,  -62, true, true)
InsertGuiControlPos("f_picGuiHelp",				 -44,  -62, true, true)
InsertGuiControlPos("f_picGuiAbout",				-104,  -62, true, true)

InsertGuiControlPos("f_picAddColumnBreak",		  10,  230)
InsertGuiControlPos("f_picAddSeparator",			  10,  200)
InsertGuiControlPos("f_picMoveFavoriteDown",		  10,  170)
InsertGuiControlPos("f_picMoveFavoriteUp",		  10,  140)
InsertGuiControlPos("f_picPreviousMenu",			  10,   84)
; InsertGuiControlPos("picSortFavorites",			  10, -165) ; REMOVED
InsertGuiControlPos("f_picUpMenu",				  25,   84)

InsertGuiControlPos("f_btnGuiSave",				   0,  -90, , true)				
InsertGuiControlPos("f_btnGuiCancel",				   0,  -90, , true)

InsertGuiControlPos("f_drpMenusList",				  40,   84)

InsertGuiControlPos("f_lblGuiDonate",				  50,  -20, true)
InsertGuiControlPos("f_lblGuiAbout",				-104,  -20, true)
InsertGuiControlPos("f_lblGuiHelp",				 -44,  -20, true)
InsertGuiControlPos("f_lblAppName",				  10,   10)
InsertGuiControlPos("f_lblAppTagLine",			  10,   42)
InsertGuiControlPos("f_lblGuiAddFavorite",		 -44,  172, true)
InsertGuiControlPos("f_lblGuiEditFavorite",		 -44,  249, true)
InsertGuiControlPos("f_lblGuiOptions",			 -44,   45, true)
InsertGuiControlPos("f_lblGuiRemoveFavorite",		 -44,  324, true)
InsertGuiControlPos("f_lblSubmenuDropdownLabel",	  40,   66)
InsertGuiControlPos("f_lblGuiGroupsManage",		 -44,  -95, true)

InsertGuiControlPos("f_lvFavoritesList",			  40,  115)

return
;------------------------------------------------------------


;------------------------------------------------------------
InsertGuiControlPos(strControlName, intX, intY, blnCenter := false, blnDraw := false)
;------------------------------------------------------------
{
	global g_objGuiControls
	
	objGuiControl := Object()
	objGuiControl.Name := strControlName
	objGuiControl.X := intX
	objGuiControl.Y := intY
	objGuiControl.Center := blnCenter
	objGuiControl.Draw := blnDraw
	
	g_objGuiControls.Insert(objGuiControl)
	
	objGuiControl := ""
}
;------------------------------------------------------------


;-----------------------------------------------------------
LoadIniFile:
;-----------------------------------------------------------

; create a backup of the ini file before loading
StringReplace, strIniBackupFile, g_strIniFile, .ini, -backup.ini
FileCopy, %g_strIniFile%, %strIniBackupFile%, 1

; reinit after Settings save if already exist
g_objMenuInGui := Object() ; object of menu currently in Gui
g_objMenusIndex := Object() ; index of menus path used in Gui menu dropdown list and to access the menu object for a given menu path
g_objMainMenu := Object() ; object of menu structure entry point
g_objMainMenu.MenuPath := lMainMenuName ; localized name of the main menu
g_objMainMenu.MenuType := "Menu" ; main menu is not a group

IfNotExist, %g_strIniFile%
{
	strNavigateOrLaunchHotkeyMouseDefault := g_arrHotkeyDefaults1 ; "MButton"
	strNavigateOrLaunchHotkeyKeyboard := g_arrHotkeyDefaults2 ; "#a"
	strPowerHotkeyMouseDefault := g_arrHotkeyDefaults3 ; "!MButton"
	strPowerHotkeyKeyboardDefault := g_arrHotkeyDefaults4 ; "!#a"
	
	g_intIconSize := 24
	
	FileAppend,
		(LTrim Join`r`n
			[Global]
			NavigateOrLaunchHotkeyMouse=%strNavigateOrLaunchHotkeyMouseDefault%
			NavigateOrLaunchHotkeyKeyboard=%strNavigateOrLaunchHotkeyKeyboardDefault%
			PowerHotkeyMouseDefault=%strPowerHotkeyMouseDefault%
			PowerHotkeyKeyboardDefault=%strPowerHotkeyKeyboardDefault%
			DisplayTrayTip=1
			DisplayIcons=1
			RecentFolders=10
			DisplayMenuShortcuts=0
			PopupMenuPosition=1
			PopupFixPosition=20,20
			DiagMode=0
			Startups=1
			LanguageCode=%g_strLanguageCode%
			DirectoryOpusPath=
			IconSize=%g_intIconSize%
			OpenMenuOnTaskbar=1
			[Favorites]
			Favorite1=F|C:\|C:\
			Favorite2=F|Windows|%A_WinDir%
			Favorite3=F|Program Files|%A_ProgramFiles%
			Favorite4=F|User Profile|`%USERPROFILE`%
			Favorite5=A|Notepad|%A_WinDir%\system32\notepad.exe
			Favorite6=U|%g_strAppNameText% web site|http://www.QuickAccessPopup.com


)
		, %g_strIniFile%
}

Gosub, LoadIniHotkeys

IniRead, g_blnDisplayTrayTip, %g_strIniFile%, Global, DisplayTrayTip, 1
IniRead, g_blnDisplayIcons, %g_strIniFile%, Global, DisplayIcons, 1
g_blnDisplayIcons := (g_blnDisplayIcons and OSVersionIsWorkstation())
; IniRead, g_blnDisplaySpecialMenusShortcuts, %g_strIniFile%, Global, DisplaySpecialMenusShortcuts, 1
; IniRead, blnDisplayRecentFolders, %g_strIniFile%, Global, DisplayRecentFolders, 1
; IniRead, blnDisplayFoldersInExplorerMenu, %g_strIniFile%, Global, DisplayFoldersInExplorerMenu, 1
; IniRead, blnDisplayGroupMenu, %g_strIniFile%, Global, DisplayGroupMenu, 1
; IniRead, blnDisplayClipboardMenu, %g_strIniFile%, Global, DisplayClipboardMenu, 1
; IniRead, blnDisplayCopyLocationMenu, %g_strIniFile%, Global, DisplayCopyLocationMenu, 1
IniRead, g_intPopupMenuPosition, %g_strIniFile%, Global, PopupMenuPosition, 1
IniRead, strPopupFixPosition, %g_strIniFile%, Global, PopupFixPosition, 20,20
StringSplit, g_arrPopupFixPosition, strPopupFixPosition, `,
IniRead, g_blnDisplayMenuShortcuts, %g_strIniFile%, Global, DisplayMenuShortcuts, 0
IniRead, g_blnDisplayFavoritesHotkeysInMenus, %g_strIniFile%, Global, blnDisplayFavoritesHotkeysInMenus, 0
IniRead, g_blnDiagMode, %g_strIniFile%, Global, DiagMode, 0
IniRead, g_intRecentFoldersMax, %g_strIniFile%, Global, RecentFoldersMax, 10
IniRead, g_intIconSize, %g_strIniFile%, Global, IconSize, 24
; IniRead, g_strGroups, %g_strIniFile%, Global, Groups, %A_Space% ; empty string if not found
IniRead, g_blnCheck4Update, %g_strIniFile%, Global, Check4Update, 1
IniRead, g_blnOpenMenuOnTaskbar, %g_strIniFile%, Global, OpenMenuOnTaskbar, 1
IniRead, g_blnRememberSettingsPosition, %g_strIniFile%, Global, RememberSettingsPosition, 1

IniRead, g_blnDonor, %g_strIniFile%, Global, Donor, 0 ; Please, be fair. Don't cheat with this.

IniRead, g_strDirectoryOpusPath, %g_strIniFile%, Global, DirectoryOpusPath, %A_Space% ; empty string if not found
IniRead, g_blnDirectoryOpusUseTabs, %g_strIniFile%, Global, DirectoryOpusUseTabs, 1 ; use tabs by default
if StrLen(g_strDirectoryOpusPath)
{
	g_blnUseDirectoryOpus := FileExist(g_strDirectoryOpusPath)
	if (g_blnUseDirectoryOpus)
		Gosub, SetDOpusRt
	else
		if (g_strDirectoryOpusPath <> "NO")
			Oops(lOopsWrongThirdPartyPath, "Directory Opus", g_strDirectoryOpusPath, lOptionsThirdParty)
}
else
	if (g_strDirectoryOpusPath <> "NO")
		Gosub, CheckDirectoryOpus

IniRead, g_strTotalCommanderPath, %g_strIniFile%, Global, TotalCommanderPath, %A_Space% ; empty string if not found
IniRead, g_blnTotalCommanderUseTabs, %g_strIniFile%, Global, TotalCommanderUseTabs, 1 ; use tabs by default
if StrLen(g_strTotalCommanderPath)
{
	g_blnUseTotalCommander := FileExist(g_strTotalCommanderPath)
	if (g_blnUseTotalCommander)
		Gosub, SetTCCommand
	else
		if (g_strTotalCommanderPath <> "NO")
			Oops(lOopsWrongThirdPartyPath, "Total Commander", g_strTotalCommanderPath, lOptionsThirdParty)
}
else
	if (g_strTotalCommanderPath <> "NO")
		Gosub, CheckTotalCommander

IniRead, g_strFPconnectPath, %g_strIniFile%, Global, FPconnectPath, %A_Space% ; empty string if not found
if StrLen(g_strFPconnectPath)
{
	g_blnUseFPconnect := FileExist(g_strFPconnectPath)
	if (g_blnUseFPconnect)
		Gosub, SetFPconnect
	else
		if (g_strFPconnectPath <> "NO")
			Oops(lOopsWrongThirdPartyPath, "FPconnect", g_strFPconnectPath, lOptionsThirdParty)
}
else
	if (g_strFPconnectPath <> "NO")
		Gosub, CheckFPconnect

IniRead, g_strTheme, %g_strIniFile%, Global, Theme
if (g_strTheme = "ERROR") ; if Theme not found, we have a new ini file - add the themes to the ini file
{
	g_strTheme := "Windows"
	g_strAvailableThemes := "Windows|Grey|Light Blue|Light Green|Light Red|Yellow"
	IniWrite, %g_strTheme%, %g_strIniFile%, Global, Theme
	IniWrite, %g_strAvailableThemes%, %g_strIniFile%, Global, AvailableThemes
	FileAppend,
		(LTrim Join`r`n
			[Gui-Grey]
			WindowColor=E0E0E0
			TextColor=000000
			ListviewBackground=FFFFFF
			ListviewText=000000
			MenuBackgroundColor=FFFFFF
			[Gui-Yellow]
			WindowColor=f9ffc6
			TextColor=000000
			ListviewBackground=fcffe0
			ListviewText=000000
			MenuBackgroundColor=fcffe0
			[Gui-Light Blue]
			WindowColor=e8e7fa
			TextColor=000000
			ListviewBackground=e7f0fa
			ListviewText=000000
			MenuBackgroundColor=e7f0fa
			[Gui-Light Red]
			WindowColor=fddcd7
			TextColor=000000
			ListviewBackground=fef1ef
			ListviewText=000000
			MenuBackgroundColor=fef1ef
			[Gui-Light Green]
			WindowColor=d6fbde
			TextColor=000000
			ListviewBackground=edfdf1
			ListviewText=000000
			MenuBackgroundColor=edfdf1

)
		, %g_strIniFile%
}
else
{
	IniRead, g_strAvailableThemes, %g_strIniFile%, Global, AvailableThemes
	if !InStr(g_strAvailableThemes, "Windows|")
	{
		g_strAvailableThemes := "Windows|" . g_strAvailableThemes
		IniWrite, %g_strAvailableThemes%, %g_strIniFile%, Global, AvailableThemes
	}
}
g_blnUseColors := (g_strTheme <> "Windows")
	
IniRead, blnMySystemFoldersBuilt, %g_strIniFile%, Global, MySystemFoldersBuilt, 0 ; default false
if !(blnMySystemFoldersBuilt)
 	Gosub, AddToIniMySystemFoldersMenu ; modify the ini file Folders section before reading it

IniRead, blnMyQAPFeaturesBuilt, %g_strIniFile%, Global, MyQAPFeaturesBuilt, 0 ; default false
if !(blnMyQAPFeaturesBuilt)
 	Gosub, AddToIniMyQAPFeaturesMenu ; modify the ini file Folders section before reading it

; ### load exclusion list todo
g_strExclusionClassList := "SciTEWindow|Chrome_WidgetWin_1|" ; must end with |

IfNotExist, %g_strIniFile%
{
	Oops(lOopsWriteProtectedError, g_strAppNameText)
	ExitApp
}
else
{
	g_intIniLine := 1
	
	if (RecursiveLoadMenuFromIni(g_objMainMenu) <> "EOM") ; build menu tree
		Oops("An error occurred while reading the favorites in the ini file.")
}

strIniBackupFile := ""
arrMainMenu := ""
strNavigateOrLaunchHotkeyMouseDefault := ""
strNavigateOrLaunchHotkeyKeyboard := ""
strPowerHotkeyMouseDefault := ""
strPowerHotkeyKeyboardDefault := ""
strPopupFixPosition := ""
blnMySystemFoldersBuilt := ""
blnMyQAPFeaturesBuilt := ""
strLoadIniLine := ""
arrThisFavorite := ""
objLoadIniFavorite := ""
arrSubMenu := ""
g_intIniLine := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
RecursiveLoadMenuFromIni(objCurrentMenu)
;------------------------------------------------------------
{
	global g_objMenusIndex
	global g_strIniFile
	global g_intIniLine
	global g_strMenuPathSeparator
	global g_strGroupPathSeparator
	global g_strEscapePipe
	
	g_objMenusIndex.Insert(objCurrentMenu.MenuPath, objCurrentMenu) ; update the menu index

	Loop
	{
		IniRead, strLoadIniLine, %g_strIniFile%, Favorites, Favorite%g_intIniLine%
		g_intIniLine++

		if (strLoadIniLine = "ERROR")
			Return, "EOF" ; end of file - should not happen if main menu ends with a "Z" type favorite as expected
		
		strLoadIniLine := strLoadIniLine . "||||||||" ; additional "|" to make sure we have all empty items
		; 1 FavoriteType, 2 FavoriteName, 3 FavoriteLocation, 4 FavoriteIconResource, 5 FavoriteArguments, 6 FavoriteAppWorkingDir,
		; 7 FavoriteWindowPosition, 8 FavoriteHotkey, 9 FavoriteLaunchWith, 10 FavoriteFTPLoginName, 11 FavoriteFTPPassword, 12 FavoriteGroupSettings
		StringSplit, arrThisFavorite, strLoadIniLine, |

		if (arrThisFavorite1 = "Z")
			return, "EOM" ; end of menu
		
		objLoadIniFavorite := Object() ; new favorite item
		
		if InStr("Menu|Group", arrThisFavorite1) ; begin a submenu
		{
			objNewMenu := Object() ; create the submenu object
			objNewMenu.MenuPath := objCurrentMenu.MenuPath . " " . (arrThisFavorite1 = "Menu" ? g_strMenuPathSeparator : g_strGroupPathSeparator) . " " . arrThisFavorite2
			objNewMenu.MenuType := arrThisFavorite1
			
			; create a navigation entry to navigate to the parent menu
			objNewMenuBack := Object()
			objNewMenuBack.FavoriteType := "B" ; for Back link to parent menu
			objNewMenuBack.FavoriteName := "(" . GetDeepestMenuPath(objCurrentMenu.MenuPath) . ")"
			objNewMenuBack.SubMenu := objCurrentMenu ; this is the link to the parent menu
			objNewMenu.Insert(objNewMenuBack)
			
			; build the submenu
			strResult := RecursiveLoadMenuFromIni(objNewMenu) ; RECURSIVE
			
			if (strResult = "EOF") ; end of file was encountered while building this submenu, exit recursive function
				Return, %strResult%
		}
		
		; this is a regular favorite, add it to the current menu
		objLoadIniFavorite.FavoriteType := arrThisFavorite1 ; see Favorite Types
		objLoadIniFavorite.FavoriteName := ReplaceAllInString(arrThisFavorite2, g_strEscapePipe, "|") ; display name of this menu item
		objLoadIniFavorite.FavoriteLocation := ReplaceAllInString(arrThisFavorite3, g_strEscapePipe, "|") ; path, URL or menu path (without "Main") for this menu item
		objLoadIniFavorite.FavoriteIconResource := ReplaceAllInString(arrThisFavorite4, g_strEscapePipe, "|") ; icon resource in format "iconfile,iconindex"
		objLoadIniFavorite.FavoriteArguments := ReplaceAllInString(arrThisFavorite5, g_strEscapePipe, "|") ; application arguments
		objLoadIniFavorite.FavoriteAppWorkingDir := ReplaceAllInString(arrThisFavorite6, g_strEscapePipe, "|") ; application working directory
		objLoadIniFavorite.FavoriteWindowPosition := arrThisFavorite7 ; Boolean,Left,Top,Width,Height (comma delimited)
		objLoadIniFavorite.FavoriteHotkey := arrThisFavorite8 ; hotkey to launch this favorite
		objLoadIniFavorite.FavoriteLaunchWith := ReplaceAllInString(arrThisFavorite9, g_strEscapePipe, "|") ; launch favorite with this executable
		objLoadIniFavorite.FavoriteLoginName := ReplaceAllInString(arrThisFavorite10, g_strEscapePipe, "|") ; login name for FTP favorite
		objLoadIniFavorite.FavoritePassword := ReplaceAllInString(arrThisFavorite11, g_strEscapePipe, "|") ; password for FTP favorite
		objLoadIniFavorite.FavoriteGroupSettings := arrThisFavorite12 ; coma separated values for group restore settings
		
		; this is a submenu favorite, link to the submenu object
		if InStr("Menu|Group", arrThisFavorite1)
			objLoadIniFavorite.SubMenu := objNewMenu

		; update the current menu object
		objCurrentMenu.Insert(objLoadIniFavorite)
	}
}
;-----------------------------------------------------------


;------------------------------------------------------------
AddToIniMySystemFoldersMenu:
;------------------------------------------------------------

strInstance := ""
Loop
{
	IniRead, strIniLine, %g_strIniFile%, Favorites, Favorite%A_Index%
	if InStr(strIniLine, lMenuMySystemMenu . strInstance)
		strInstance := strInstance . "+"
	if (strIniLine = "ERROR")
	{
		intNextFolderNumber := A_Index - 1 ; overwrite end of main menu marker
		Break
	}
}
strMySystemMenu := lMenuMySystemMenu . strInstance

AddToIniOneSystemFolderMenu("", "", "X")
AddToIniOneSystemFolderMenu(g_strMenuPathSeparator . " " . strMySystemMenu, strMySystemMenu, "Menu")
AddToIniOneSystemFolderMenu(A_Desktop, lMenuDesktop) ; Desktop
AddToIniOneSystemFolderMenu("{450D8FBA-AD25-11D0-98A8-0800361B1103}") ; Documents
AddToIniOneSystemFolderMenu(g_strMyPicturesPath) ; Pictures
AddToIniOneSystemFolderMenu(g_strDownloadPath) ; Downloads
AddToIniOneSystemFolderMenu("", "", "X")
AddToIniOneSystemFolderMenu("{20D04FE0-3AEA-1069-A2D8-08002B30309D}") ; Computer
AddToIniOneSystemFolderMenu("{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}") ; Network
AddToIniOneSystemFolderMenu("", "", "X")
AddToIniOneSystemFolderMenu("{21EC2020-3AEA-1069-A2DD-08002B30309D}") ; Control Panel
AddToIniOneSystemFolderMenu("{645FF040-5081-101B-9F08-00AA002F954E}") ; Recycle Bin
AddToIniOneSystemFolderMenu("", "", "Z") ; close special menu
AddToIniOneSystemFolderMenu("", "", "Z") ; restore end of main menu marker

IniWrite, 1, %g_strIniFile%, Global, MySystemFoldersBuilt

intNextFolderNumber := ""
strMySystemMenu := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
AddToIniMyQAPFeaturesMenu:
;------------------------------------------------------------

; base on AddToIniMySystemFoldersMenu: and re-use AddToIniOneSystemFolderMenu

return
;------------------------------------------------------------


;------------------------------------------------------------
AddToIniOneSystemFolderMenu(strSpecialFolderLocation, strSpecialFolderName := "", strFavoriteType := "Special")
;------------------------------------------------------------
{
	global g_strIniFile
	global g_objIconsFile
	global g_objIconsIndex
	global g_objSpecialFolders
	global intNextFolderNumber
	
	if (strFavoriteType = "Z")
		strNewIniLine := strFavoriteType
	else
	{
		if (strFavoriteType = "Menu")
			strIconResource := g_objIconsFile["iconSpecialFolders"] . "," . g_objIconsIndex["iconSpecialFolders"]
		else
			strIconResource := g_objSpecialFolders[strSpecialFolderLocation].DefaultIcon
		if !StrLen(strSpecialFolderName)
			strSpecialFolderName := g_objSpecialFolders[strSpecialFolderLocation].DefaultName
		
		strNewIniLine := strFavoriteType . "|" . strSpecialFolderName . "|" . strSpecialFolderLocation . "|" . strIconResource . "|||"
	}
	
	IniWrite, %strNewIniLine%, %g_strIniFile%, Favorites, Favorite%intNextFolderNumber%
	intNextFolderNumber++
}
;------------------------------------------------------------


;-----------------------------------------------------------
LoadIniHotkeys:
;-----------------------------------------------------------

; Read the values and set hotkey shortcuts
; NavigateOrLaunchHotkeyMouse|NavigateOrLaunchHotkeyKeyboard|PowerHotkeyMouse|PowerHotkeyKeyboard
loop, % g_arrHotkeyNames%0%
{
	; Prepare global arrays used by SplitHotkey function
	IniRead, g_arrHotkeys%A_Index%, %g_strIniFile%, Global, % g_arrHotkeyNames%A_Index%, % g_arrHotkeyDefaults%A_Index%
	SplitHotkey(g_arrHotkeys%A_Index%, strModifiers%A_Index%, strOptionsKey%A_Index%, strMouseButton%A_Index%, strMouseButtonsWithDefault%A_Index%)
}
; ###_V("Navigate or Launch`n`n", g_arrHotkeyNames1, g_arrHotkeysPrevious1, g_arrHotkeys1, g_arrHotkeyNames2, g_arrHotkeysPrevious2, g_arrHotkeys2)

; First, if we can, navigate with Launch hotkeys (1 NavigateOrLaunchHotkeyMouse and 2 NavigateOrLaunchHotkeyKeyboard) 
Hotkey, If, CanNavigate(A_ThisHotkey)
	if (g_arrHotkeysPrevious1 <> "") and (g_arrHotkeysPrevious1 <> "None")
		Hotkey, % g_arrHotkeysPrevious1, , Off
	if (g_arrHotkeys1 <> "None")
		Hotkey, % g_arrHotkeys1, NavigateHotkeyMouse, On UseErrorLevel
	if (ErrorLevel)
		Oops(lDialogInvalidHotkey, g_arrHotkeys1, g_strAppNameText, g_arrOptionsTitles1)
	if (g_arrHotkeysPrevious2 <> "") and (g_arrHotkeysPrevious2 <> "None")
		Hotkey, % g_arrHotkeysPrevious2, , Off
	if (g_arrHotkeys2 <> "None")
		Hotkey, % g_arrHotkeys2, NavigateHotkeyKeyboard, On UseErrorLevel
	if (ErrorLevel)
		Oops(lDialogInvalidHotkey, g_arrHotkeys2, g_strAppNameText, g_arrOptionsTitles2)
Hotkey, If

; Second, if we can't navigate but can launch, launch with Launch hotkeys (1 NavigateOrLaunchHotkeyMouse and 2 NavigateOrLaunchHotkeyKeyboard) 
Hotkey, If, CanLaunch(A_ThisHotkey)
	if (g_arrHotkeysPrevious1 <> "") and (g_arrHotkeysPrevious1 <> "None") ; ### continuer pour les autres
		Hotkey, % g_arrHotkeysPrevious1, , Off
	if (g_arrHotkeys1 <> "None")
		Hotkey, % g_arrHotkeys1, LaunchHotkeyMouse, On UseErrorLevel
	if (ErrorLevel)
		Oops(lDialogInvalidHotkey, g_arrHotkeys1, g_strAppNameText, g_arrOptionsTitles1)
	if (g_arrHotkeysPrevious2 <> "") and (g_arrHotkeysPrevious2 <> "None")
		Hotkey, % g_arrHotkeysPrevious2, , Off
	if (g_arrHotkeys2 <> "None")
		Hotkey, % g_arrHotkeys2, LaunchHotkeyKeyboard, On UseErrorLevel
	if (ErrorLevel)
		Oops(lDialogInvalidHotkey, g_arrHotkeys2, g_strAppNameText, g_arrOptionsTitles2)
Hotkey, If

; ###_V("Power`n`n", g_arrHotkeyNames3, g_arrHotkeysPrevious3, g_arrHotkeys3, g_arrHotkeyNames4, g_arrHotkeysPrevious4, g_arrHotkeys4)

; Then, in any case, open the Power menu with the alternate hotkeys (3 PowerHotkeyMouse and 4 PowerHotkeyKeyboard)
if (g_arrHotkeysPrevious3 <> "") and (g_arrHotkeysPrevious3 <> "None")
	Hotkey, % g_arrHotkeysPrevious3, , Off
if (g_arrHotkeys3 <> "None") ; do not compare with lOptionsMouseNone because it is translated
	Hotkey, % g_arrHotkeys3, PowerHotkeyMouse, On UseErrorLevel
if (ErrorLevel)
	Oops(lDialogInvalidHotkey, g_arrHotkeys3, g_strAppNameText, g_arrOptionsTitles3)
if (g_arrHotkeysPrevious4 <> "") and (g_arrHotkeysPrevious4 <> "None")
	Hotkey, % g_arrHotkeysPrevious4, , Off
if (g_arrHotkeys4 <> "None") ; do not compare with lOptionsMouseNone because it is translated
	Hotkey, % g_arrHotkeys4, PowerHotkeyKeyboard, On UseErrorLevel
if (ErrorLevel)
	Oops(lDialogInvalidHotkey, g_arrHotkeys4, g_strAppNameText, g_arrOptionsTitles4)

return
;------------------------------------------------------------


;------------------------------------------------------------
InitDiagMode:
;------------------------------------------------------------

MsgBox, 52, %g_strAppNameText%, % L(lDiagModeCaution, g_strAppNameText, g_strDiagFile)
IfMsgBox, No
{
	g_blnDiagMode := False
	IniWrite, 0, %g_strIniFile%, Global, DiagMode
	return
}
	
if !FileExist(g_strDiagFile)
{
	FileAppend, DateTime`tType`tData`n, %g_strDiagFile%
	Diag("DIAGNOSTIC FILE", lDiagModeIntro)
	Diag("AppNameFile", g_strAppNameFile)
	Diag("AppNameText", g_strAppNameText)
	Diag("AppVersion", g_strAppVersion)
	Diag("A_ScriptFullPath", A_ScriptFullPath)
	Diag("A_WorkingDir", A_WorkingDir)
	Diag("A_AhkVersion", A_AhkVersion)
	Diag("A_OSVersion", A_OSVersion)
	Diag("A_Is64bitOS", A_Is64bitOS)
	Diag("A_Language", A_Language)
	Diag("A_IsAdmin", A_IsAdmin)
}

FileRead, strIniFileContent, %g_strIniFile%
StringReplace, strIniFileContent, strIniFileContent, `", `"`"
Diag("IniFile", """" . strIniFileContent . """")
FileAppend, `n, %g_strDiagFile% ; required when the last line of the existing file ends with "

strIniFileContent := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
LoadThemeGlobal:
;------------------------------------------------------------

IniRead, g_strGuiWindowColor, %g_strIniFile%, Gui-%g_strTheme%, WindowColor, E0E0E0
IniRead, g_strMenuBackgroundColor, %g_strIniFile%, Gui-%g_strTheme%, MenuBackgroundColor, FFFFFF

return
;------------------------------------------------------------



;========================================================================================================================
; END OF INITIALIZATION
;========================================================================================================================


;========================================================================================================================
!_017_EXIT:
;========================================================================================================================

;-----------------------------------------------------------
TrayMenuExitApp:
;-----------------------------------------------------------

ExitApp
;-----------------------------------------------------------


;-----------------------------------------------------------
CleanUpBeforeExit:
;-----------------------------------------------------------

strSettingsPosition := "-1" ; center at minimal size
if (g_blnRememberSettingsPosition)
{
	WinGet, intMinMax, MinMax, ahk_id %g_strAppHwnd%
	if (intMinMax <> 1) ; if window is maximized, we keep the default positionand size (center at minimal size)
	{
		WinGetPos, intX, intY, intW, intH, ahk_id %g_strAppHwnd%
		strSettingsPosition := intX . "|" . intY . "|" . intW . "|" . intH
	}
}
IniWrite, %strSettingsPosition%, %g_strIniFile%, Global, SettingsPosition

FileRemoveDir, %g_strTempDir%, 1 ; Remove all files and subdirectories

if (g_blnDiagMode)
{
	MsgBox, 52, %g_strAppNameText%, % L(lDiagModeExit, g_strAppNameText, g_strDiagFile) . "`n`n" . lDiagModeIntro . "`n`n" . lDiagModeSee
	IfMsgBox, Yes
		Run, %g_strDiagFile%
}

strSettingsPosition := ""
intMinMax := ""
intX := ""
intY := ""
intW := ""
intH := ""

ExitApp
;-----------------------------------------------------------


;========================================================================================================================
; END OF EXIT
;========================================================================================================================



;========================================================================================================================
!_020_BUILD:
;========================================================================================================================

;------------------------------------------------------------
BuildTrayMenu:
;------------------------------------------------------------

Menu, Tray, Icon, , , 1 ; last 1 to freeze icon during pause or suspend
Menu, Tray, NoStandard
;@Ahk2Exe-IgnoreBegin
; Start of code for developement phase only - won't be compiled
Menu, Tray, Icon, %A_ScriptDir%\qap-red-512.ico, 1, 1 ; last 1 to freeze icon during pause or suspend
Menu, Tray, Standard
Menu, Tray, Add
; / End of code for developement phase only - won't be compiled
;@Ahk2Exe-IgnoreEnd
; Menu, Tray, Add, % L(lMenuFPMenu, g_strAppNameText, lMenuMenu), :%lMainMenuName% ; REMOVED seems to cause a BUG in submenu display (first display only) - unexplained...
Menu, Tray, Add, % L(lMenuSettings, g_strAppNameText) . "...", GuiShow
Menu, Tray, Add, % g_strAppNameFile . ".ini", ShowIniFile
Menu, Tray, Add
Menu, Tray, Add, %lMenuRunAtStartup%, RunAtStartup
Menu, Tray, Add, %lMenuSuspendHotkeys%, SuspendHotkeys
Menu, Tray, Add
Menu, Tray, Add, %lMenuUpdate%, Check4Update
Menu, Tray, Add, %lMenuHelp%, GuiHelp
Menu, Tray, Add, %lMenuAbout%, GuiAbout
Menu, Tray, Add, %lDonateMenu%, GuiDonate
Menu, Tray, Add
Menu, Tray, Add, % L(lMenuExitApp, g_strAppNameText), TrayMenuExitApp
Menu, Tray, Default, % L(lMenuSettings, g_strAppNameText) . "..."
if (g_blnUseColors)
	Menu, Tray, Color, %g_strMenuBackgroundColor%
Menu, Tray, Tip, % g_strAppNameText . " " . g_strAppVersion . " (" . (A_PtrSize * 8) . "-bit)`n" . (g_blnDonor ? lDonateThankyou : lDonateButton) ; A_PtrSize * 8 = 32 or 64

return
;------------------------------------------------------------


;------------------------------------------------------------
FoldersInExplorerMenuShortcut:
;------------------------------------------------------------

; ### COMPLETE blnNewWindow := !CanOpenFavorite("", strTargetWinId, strTargetClass, strTargetControl)
Gosub, SetMenuPosition ; sets strTargetWinId or activate the window strTargetWinId set by CanOpenFavorite

Gosub, BuildFoldersInExplorerMenu
if (g_intExplorersIndex) ; there are Folders in Explorer menu
{
	CoordMode, Menu, % (g_intPopupMenuPosition = 2 ? "Window" : "Screen")
	Menu, g_menuFoldersInExplorer, Show, %g_intMenuPosX%, %g_intMenuPosy%
}
else
	TrayTip, % L(lTrayTipNoFoldersInExplorerMenuTitle, g_strAppNameText), %lTrayTipNoFoldersInExplorerMenuDetail%, , 2

return
;------------------------------------------------------------


;------------------------------------------------------------
BuildFoldersInExplorerMenuInit:
BuildFoldersInExplorerMenu:
;------------------------------------------------------------

Menu, g_menuFoldersInExplorer, Add ; create the menu

if (A_ThisLabel = "BuildFoldersInExplorerMenuInit")
	return

if (g_blnUseDirectoryOpus)
{
	FileDelete, %g_strDOpusTempFilePath%
	RunDOpusRt("/info", g_strDOpusTempFilePath, ",paths") ; list opened listers in a text file
	; Run, "%strDirectoryOpusRtPath%" /info "%g_strDOpusTempFilePath%"`,paths
	loop, 10
		if FileExist(g_strDOpusTempFilePath)
			Break
		else
			Sleep, 50 ; was 10 and had some gliches with FP - is 50 enough?
	FileRead, strDOpusListText, %g_strDOpusTempFilePath%

	objDOpusListers := Object()
	CollectDOpusListersList(objDOpusListers, strDOpusListText) ; list all listers, excluding special folders like Recycle Bin
}

objExplorersWindows := Object()
CollectExplorers(objExplorersWindows, ComObjCreate("Shell.Application").Windows)

objFoldersInExplorers := Object()

g_intExplorersIndex := 0 ; used in PopupMenu and SaveGroup to check if we disable menu or button when empty

if (g_blnUseDirectoryOpus)
	for intIndex, objLister in objDOpusListers
	{
		; if we have no path or or DOpus collection, skip it
		if !StrLen(objLister.LocationURL) or InStr(objLister.LocationURL, "coll://")
			continue
		
		if NameIsInObject(objLister.LocationURL, objFoldersInExplorers)
			continue
		
		g_intExplorersIndex++
			
		objFolderInExplorer := Object()
		objFolderInExplorer.LocationURL := objLister.LocationURL
		objFolderInExplorer.Name := objLister.LocationURL
		
		; used for DOpus windows to discriminatre different listers
		objFolderInExplorer.WindowId := objLister.Lister
		
		; info used to create groups
		objFolderInExplorer.TabId := objLister.Tab
		objFolderInExplorer.Position := objLister.Position
		objFolderInExplorer.MinMax := objLister.MinMax
		objFolderInExplorer.Pane := (objLister.Pane = 0 ? 1 : objLister.Pane) ; consider pane 0 as pane 1
		objFolderInExplorer.WindowType := "DO"
		
		objFoldersInExplorers.Insert(g_intExplorersIndex, objFolderInExplorer)
	}

for intIndex, objFolder in objExplorersWindows
{
	; if we have no path, skip it
	if !StrLen(objFolder.LocationURL)
		continue
		
	if NameIsInObject(objFolder.LocationName, objFoldersInExplorers)
		continue
	
	g_intExplorersIndex++
	
	objFolderInExplorer := Object()
	objFolderInExplorer.LocationURL := objFolder.LocationURL
	objFolderInExplorer.Name := objFolder.LocationName
	objFolderInExplorer.IsSpecialFolder := objFolder.IsSpecialFolder
	
	; not used for Explorer windows, but keep it
	objFolderInExplorer.WindowId := objFolder.WindowId

	; info used to create groups
	objFolderInExplorer.Position := objFolder.Position
	objFolderInExplorer.MinMax := objFolder.MinMax
	objFolderInExplorer.WindowType := "EX"

	objFoldersInExplorers.Insert(g_intExplorersIndex, objFolderInExplorer)
}

Menu, g_menuFoldersInExplorer, DeleteAll
if (g_blnUseColors)
	Menu, g_menuFoldersInExplorer, Color, %g_strMenuBackgroundColor%

intShortcutFoldersInExplorer := 0
g_objFoldersInExplorerLocationUrlByName := Object()

for intIndex, objFolderInExplorer in objFoldersInExplorers
{
	strMenuName := (g_blnDisplayMenuShortcuts and (intShortcutFoldersInExplorer <= 35) ? "&" . NextMenuShortcut(intShortcutFoldersInExplorer) . " " : "") . objFolderInExplorer.Name
	g_objFoldersInExplorerLocationUrlByName.Insert(strMenuName, objFolderInExplorer.LocationURL) ; can include the numeric shortcut
	AddMenuIcon("g_menuFoldersInExplorer", strMenuName, "OpenFolderInExplorer", "Folder")
}

objDOpusListers := ""
objExplorersWindows := ""
objFolderInExplorer := ""
strDOpusListText := ""
intIndex := ""
objLister := ""
objFolder := ""
intShortcutFoldersInExplorer := ""
strMenuName := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
CollectDOpusListersList(objListers, strList)
; list all DirectoryOpus listers, excluding special folders like Recycle Bin, Network because they are not included in dopus-list.txt
;------------------------------------------------------------
{
	strList := SubStr(strList, InStr(strList, "<path"))
	Loop
	{
		objLister := Object()
		
		strList := SubStr(strList, InStr(strList, "<path"))
		strSubStr := SubStr(strList, InStr(strList, "<path"))
		strSubStr := SubStr(strSubStr, 1, InStr(strSubStr, "</path>") - 1)
		
		if (StrLen(strSubStr))
		{
			objLister.Active_lister := ParseDOpusListerProperty(strSubStr, "active_lister")
			objLister.Active_tab := ParseDOpusListerProperty(strSubStr, "active_tab")
			objLister.Lister := ParseDOpusListerProperty(strSubStr, "lister")
			objLister.Side := ParseDOpusListerProperty(strSubStr, "side")
			objLister.Tab := ParseDOpusListerProperty(strSubStr, "tab")
			objLister.Tab_state := ParseDOpusListerProperty(strSubStr, "tab_state")
			objLister.LocationURL := SubStr(strSubStr, InStr(strSubStr, ">") + 1)

			WinGetPos, intX, intY, intW, intH, % "ahk_id " . objLister.lister
			objLister.Position := intX . "|" . intY . "|" . intW . "|" . intH
			WinGet, intMinMax, MinMax, % "ahk_id " . objLister.lister
			objLister.MinMax := intMinMax
			objLister.Pane := objLister.Side
			
			if !InStr(objLister.LocationURL, "ftp://")
				; Swith Explorer to DOpus FTP folder not supported (see https://github.com/JnLlnd/FoldersPopup/issues/84)
				objListers.Insert(A_Index, objLister)
				
			strList := SubStr(strList, StrLen(strSubStr))
		}
	} until	(!StrLen(strSubStr))
}
;------------------------------------------------------------


;------------------------------------------------------------
ParseDOpusListerProperty(strSource, strProperty)
;------------------------------------------------------------
{
	intStartPos := InStr(strSource, " " . strProperty . "=")
	if !(intStartPos)
		return ""
	strSource := SubStr(strSource, intStartPos + StrLen(strProperty) + 3)
	intEndPos := InStr(strSource, """")
	return SubStr(strSource, 1, intEndPos - 1)
}
;------------------------------------------------------------


;------------------------------------------------------------
CollectExplorers(objExplorers, pExplorers)
;------------------------------------------------------------
{
	intExplorers := 0
	
	For pExplorer in pExplorers
	; see http://msdn.microsoft.com/en-us/library/windows/desktop/aa752084(v=vs.85).aspx
	{
		/* in v.3.9.8: stop interupting Explorer collection if an error occurs - just check for content and continue
		if (A_LastError)
			; an error occurred during ComObjCreate (A_LastError probably is E_UNEXPECTED = -2147418113 #0x8000FFFFL)
			break
		*/

		strType := ""
		try strType := pExplorer.Type ; Gets the type name of the contained document object. "Document HTML" for IE windows. Should be empty for file Explorer windows.
		strWindowID := ""
		try strWindowID := pExplorer.HWND ; Try to get the handle of the window. Some ghost Explorer in the ComObjCreate may return an empty handle
		
		if !StrLen(strType) ; must be empty
			and StrLen(strWindowID) ; must not be empty
		{
			intExplorers++
			objExplorer := Object()
			objExplorer.Position := pExplorer.Left . "|" . pExplorer.Top . "|" . pExplorer.Width . "|" . pExplorer.Height

			objExplorer.IsSpecialFolder := !StrLen(pExplorer.LocationURL) ; empty for special folders like Recycle bin
			
			if (objExplorer.IsSpecialFolder)
			{
				objExplorer.LocationURL := pExplorer.Document.Folder.Self.Path
				objExplorer.LocationName := pExplorer.LocationName ; see http://msdn.microsoft.com/en-us/library/aa752084#properties
			}
			else
			{
				objExplorer.LocationURL := pExplorer.LocationURL
				strLocationName :=  UriDecode(pExplorer.LocationURL)
				StringReplace, strLocationName, strLocationName, file:///
				StringReplace, strLocationName, strLocationName, /, \, A
				objExplorer.LocationName := strLocationName
			}
			
			objExplorer.WindowId := pExplorer.HWND ; not used for Explorer windows, but keep it
			WinGet, intMinMax, MinMax, % "ahk_id " . pExplorer.HWND
			objExplorer.MinMax := intMinMax
			
			objExplorers.Insert(intExplorers, objExplorer) ; I was checking if StrLen(pExplorer.HWND) - any reason?
		}
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
RefreshRecentFolders:
RecentFoldersShortcut:
;------------------------------------------------------------

blnCopyLocation := false

; ### COMPLETE blnNewWindow := !CanOpenFavorite("", g_strTargetWinId, g_strTargetClass, g_strTargetControl)
Gosub, SetMenuPosition ; sets g_strTargetWinId or activate the window g_strTargetWinId set by CanOpenFavorite

ToolTip, %lMenuRefreshRecent%...
Gosub, BuildRecentFoldersMenu
ToolTip

CoordMode, Menu, % (g_intPopupMenuPosition = 2 ? "Window" : "Screen")
Menu, menuRecentFolders, Show, %g_intMenuPosX%, %g_intMenuPosY%

return
;------------------------------------------------------------


;------------------------------------------------------------
BuildRecentFoldersMenu:
;------------------------------------------------------------

Menu, menuRecentFolders, Add
Menu, menuRecentFolders, DeleteAll ; had problem with DeleteAll making the Special menu to disappear 1/2 times - now OK
if (g_blnUseColors)
	Menu, menuRecentFolders, Color, %g_strMenuBackgroundColor%

g_objRecentFolders := Object()
g_intRecentFoldersIndex := 0 ; used in PopupMenu... to check if we disable the menu when empty

RegRead, strRecentsFolder, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Recent

/*
; Alternative to collect recent files *** NOT WORKING with XP and SLOWER because all shortcuts are resolved before getting the list
; See: post from Skan http://ahkscript.org/boards/viewtopic.php?f=5&t=4477#p25261
; Implement for Win7+ if FileGetShortcut still produce Windows errors when external drive is not available (despite DllCall in initialization)

strWinPathRecent := RegExReplace(SubStr(strRecentsFolder, 3) . "\", "\\", "\\")
strDirList := ""
for ObjItem in ComObjGet("winmgmts:")
	.ExecQuery("Select * from Win32_ShortcutFile where path = '" . strWinPathRecent . "'")
	strDirList .= ObjItem.LastModified . A_Tab . ObjItem.Extension . A_Tab . ObjItem.Target . "`n"
*/

Loop, %strRecentsFolder%\*.* ; tried to limit to number of recent but they are not sorted chronologically
	strDirList .= A_LoopFileTimeModified . "`t`" . A_LoopFileFullPath . "`n"

Sort, strDirList, R

intShortcut := 0

Loop, parse, strDirList, `n
{
	if !StrLen(A_LoopField) ; last line is empty
		continue

	arrShortcutFullPath := StrSplit(A_LoopField, A_Tab)
	strShortcutFullPath := arrShortcutFullPath[2]
	
	FileGetShortcut, %strShortcutFullPath%, strTargetPath
	
	if (errorlevel) ; hidden or system files (like desktop.ini) returns an error
		continue
	if !FileExist(strTargetPath) ; if folder/document was delete or on a removable drive
		continue
	if LocationIsDocument(strTargetPath) ; not a folder
		continue

	g_intRecentFoldersIndex++
	g_objRecentFolders.Insert(g_intRecentFoldersIndex, strTargetPath)
	
	strMenuName := (g_blnDisplayMenuShortcuts and (intShortcut <= 35) ? "&" . NextMenuShortcut(intShortcut) . " " : "") . strTargetPath
	AddMenuIcon("menuRecentFolders", strMenuName, "OpenRecentFolder", "Folder")

	if (g_intRecentFoldersIndex >= g_intRecentFoldersMax)
		break
}

strRecentsFolder := ""
strDirList := ""
intShortcut := ""
arrShortcutFullPath := ""
strShortcutFullPath := ""
strTargetPath := ""
strMenuName := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
ClipboardMenuShortcut:
;------------------------------------------------------------

; ### COMPLETE blnNewWindow := !CanOpenFavorite("", strTargetWinId, strTargetClass, strTargetControl)
Gosub, SetMenuPosition ; sets strTargetWinId or activate the window strTargetWinId set by CanOpenFavorite

Gosub, RefreshClipboardMenu
if (g_blnClipboardMenuEnable)
{
    CoordMode, Menu, % (g_intPopupMenuPosition = 2 ? "Window" : "Screen")
    Menu, g_menuClipboard, Show, %g_intMenuPosX%, %g_intMenuPosy%
}
else
    TrayTip, % L(lTrayTipNoClipboardMenuTitle, g_strAppNameText), %lTrayTipNoClipboardMenuDetail%, , 2

return
;------------------------------------------------------------


;------------------------------------------------------------
BuildClipboardMenuInit:
BuildClipboardMenu:
;------------------------------------------------------------

Menu, g_menuClipboard, Add ; create the menu

if (A_ThisLabel = "BuildClipboardMenuInit")
	return

Menu, g_menuClipboard, DeleteAll
if (g_blnUseColors)
	Menu, g_menuClipboard, Color, %g_strMenuBackgroundColor%

g_blnClipboardMenuEnable := 0

Gosub, RefreshClipboardMenu

return
;------------------------------------------------------------


;------------------------------------------------------------
RefreshClipboardMenu:
;------------------------------------------------------------

blnPreviousClipboardMenuDeleted := 0
intShortcutClipboardMenu := 0
strURLsInClipboard := ""

; Parse Clipboard for folder, document or application filenames (filenames alone on one line)
Loop, parse, Clipboard, `n, `r%A_Space%%A_Tab%/?:*`"><|
{
    strClipboardLine = %A_LoopField%
	strClipboardLineExpanded := EnvVars(strClipboardLine) ; only to test if file exist - will not be displayed in menu

	if StrLen(FileExist(strClipboardLineExpanded))
	{
		if !(blnPreviousClipboardMenuDeleted)
		{
			Menu, g_menuClipboard, Add
			Menu, g_menuClipboard, DeleteAll
			blnPreviousClipboardMenuDeleted := 1
		}
		g_blnClipboardMenuEnable := 1

		strMenuName := (g_blnDisplayMenuShortcuts and (intShortcutFoldersInExplorer <= 35) ? "&" . NextMenuShortcut(intShortcutClipboardMenu) . " " : "") . strClipboardLine
		if (g_blnDisplayIcons)
			if LocationIsDocument(strClipboardLineExpanded)
			{
				GetIcon4Location(strClipboardLineExpanded, strThisIconFile, intThisIconIndex)
				strIconValue := strThisIconFile . "," . intThisIconIndex
			}
			else
				strIconValue := "Folder"
		AddMenuIcon("g_menuClipboard", strMenuName, "OpenClipboard", strIconValue)
	}

	; Parse Clipboard line for URLs (anywhere on the line)
	strURLSearchString := strClipboardLine
	Gosub, GetURLsInClipboardLine
}

Sort, strURLsInClipboard

Loop, parse, strURLsInClipboard, `n
{
	if !StrLen(A_LoopField)
		break
	
	; if we get here, we have at least one URL, check if we need to delete previous menu
	if !(blnPreviousClipboardMenuDeleted)
	{
		Menu, g_menuClipboard, Add
		Menu, g_menuClipboard, DeleteAll
		blnPreviousClipboardMenuDeleted := 1
	}
	g_blnClipboardMenuEnable := 1

	strMenuName := (g_blnDisplayMenuShortcuts and (intShortcutFoldersInExplorer <= 35) ? "&" . NextMenuShortcut(intShortcutClipboardMenu) . " " : "") . A_LoopField
	if StrLen(strMenuName) < 260 ; skip too long URLs
	{
		Menu, g_menuClipboard, Add, %strMenuName%, OpenClipboard
		if (blnDisplayIcon)
			Menu, g_menuClipboard, Icon, %strMenuName%, %strThisIconFile%, %intThisIconIndex%, %g_intIconSize%
	}
}

blnPreviousClipboardMenuDeleted := ""
intShortcutClipboardMenu := ""
strURLsInClipboard := ""
strClipboardLine := ""
strClipboardLineExpanded := ""
strURLSearchString := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GetURLsInClipboardLine:
;------------------------------------------------------------
; Adapted from AHK help file: http://ahkscript.org/docs/commands/LoopReadFile.htm
; It's done this particular way because some URLs have other URLs embedded inside them:
StringGetPos, intURLStart1, strURLSearchString, http://
StringGetPos, intURLStart2, strURLSearchString, https://
StringGetPos, intURLStart3, strURLSearchString, www.

; Find the left-most starting position:
intURLStart := intURLStart1 ; Set starting default.
Loop
{
	; It helps performance (at least in a script with many variables) to resolve
	; "intURLStart%A_Index%" only once:
	intArrayElement := intURLStart%A_Index%
	if (intArrayElement = "") ; End of the array has been reached.
		break
	if (intArrayElement = -1) ; This element is disqualified.
		continue
	if (intURLStart = -1)
		intURLStart := intArrayElement
	else ; intURLStart has a valid position in it, so compare it with intArrayElement.
	{
		if (intArrayElement <> -1)
			if (intArrayElement < intURLStart)
				intURLStart := intArrayElement
	}
}

if (intURLStart = -1) ; No URLs exist in strURLSearchString.
	return ; (exit loop)

; Otherwise, extract this strURL:
StringTrimLeft, strURL, strURLSearchString, %intURLStart% ; Omit the beginning/irrelevant part.
Loop, parse, strURL, %A_Tab%%A_Space%<> ; Find the first space, tab, or angle (if any).
{
	strURL := A_LoopField
	break ; i.e. perform only one loop iteration to fetch the first "field".
}
; If the above loop had zero iterations because there were no ending characters found,
; leave the contents of the strURL var untouched.

; If the strURL ends in a double quote, remove it.  For now, StringReplace is used, but
; note that it seems that double quotes can legitimately exist inside URLs, so this
; might damage them:
StringReplace, strURLCleansed, strURL, ",, All


; See if there are any other URLs in this line:
StringLen, intCharactersToOmit, strURL
intCharactersToOmit += intURLStart
StringTrimLeft, strURLSearchString, strURLSearchString, %intCharactersToOmit%

Gosub, GetURLsInClipboardLine ; Recursive call to self (end of loop)

strURLsInClipboard .= strURLCleansed . "`n"

intURLStart1 := ""
intURLStart2 := ""
intURLStart3 := ""
intURLStart := ""
intArrayElement := ""
strURL := ""
strURLCleansed := ""
intCharactersToOmit := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
BuildMainMenu:
BuildMainMenuWithStatus:
;------------------------------------------------------------

if (A_ThisLabel = "BuildMainMenuWithStatus")
	TrayTip, % L(lTrayTipWorkingTitle, g_strAppNameText, g_strAppVersion)
		, %lTrayTipWorkingDetail%, , 1

Menu, %lMainMenuName%, Add
Menu, %lMainMenuName%, DeleteAll
if (g_blnUseColors)
	Menu, %lMainMenuName%, Color, %g_strMenuBackgroundColor%

RecursiveBuildOneMenu(g_objMainMenu) ; recurse for submenus

if (g_arrMenus[lMainMenuName][g_arrMenus[lMainMenuName].MaxIndex()].FavoriteType <> "K")
; column break not allowed if first item is a separator
	Menu, %lMainMenuName%, Add

/* ### later
if (blnDisplayFoldersInExplorerMenu)
{
	AddMenuIcon(lMainMenuName, BuildSpecialMenuItemName(6, lMenuCurrentFolders), ":g_menuFoldersInExplorer", "iconCurrentFolders")
	if (g_blnUseColors)
		Menu, g_menuFoldersInExplorer, Color, %g_strMenuBackgroundColor%
}

if (blnDisplayGroupMenu)
{
	AddMenuIcon(lMainMenuName, BuildSpecialMenuItemName(7, lMenuGroup), ":g_menuGroups", "iconGroup")
	if (g_blnUseColors)
		Menu, g_menuGroups, Color, %g_strMenuBackgroundColor%
}

if (blnDisplayRecentFolders)
	AddMenuIcon(lMainMenuName, BuildSpecialMenuItemName(8, lMenuRecentFolders), "RefreshRecentFolders", "iconRecentFolders")

if (blnDisplayClipboardMenu)
	AddMenuIcon(lMainMenuName, BuildSpecialMenuItemName(9, lMenuClipboard), ":g_menuClipboard", "iconClipboard")

if (blnDisplayRecentFolders or blnDisplayFoldersInExplorerMenu or blnDisplayGroupMenu or blnDisplayClipboardMenu)
	Menu, %lMainMenuName%, Add

AddMenuIcon(lMainMenuName, BuildSpecialMenuItemName(5, L(lMenuSettings, g_strAppNameText) . "..."), "GuiShow", "iconSettings")
Menu, %lMainMenuName%, Default, %  BuildSpecialMenuItemName(5, L(lMenuSettings, g_strAppNameText) . "...")
AddMenuIcon(lMainMenuName, lMenuAddThisFolder . "...", "AddThisFolder", "iconAddThisFolder")

if (blnDisplayCopyLocationMenu)
	AddMenuIcon(lMainMenuName, lMenuCopyLocation . "...", "PopupMenuCopyLocation", "iconClipboard")
*/

if !(g_blnDonor)
{
	Menu, %lMainMenuName%, Add
	AddMenuIcon(lMainMenuName, lDonateMenu . "...", "GuiDonate", "iconDonate")
}

if (A_ThisLabel = "BuildMainMenuWithStatus")
	TrayTip, % L(lTrayTipInstalledTitle, g_strAppNameText, g_strAppVersion)
		, %lTrayTipWorkingDetailFinished%, , 1

return
;------------------------------------------------------------


;------------------------------------------------------------
RecursiveBuildOneMenu(objCurrentMenu)
;------------------------------------------------------------
{
	global g_blnDisplayMenuShortcuts
	global g_blnDisplayFavoritesHotkeysInMenus ; ### todo
	global g_blnDisplayIcons
	global g_intIconSize
	global g_strMenuBackgroundColor
	global g_objIconsFile
	global g_objIconsIndex
	global g_blnUseColors
	
	intShortcut := 0
	
	; try because at first execution the strMenu menu does not exist and produces an error,
	; but DeleteAll is required later for menu updates
	try Menu, %strMenu%, DeleteAll
	
	intMenuItemsCount := 0
	intMenuArrayItemsCount := 0
	
	Loop, % objCurrentMenu.MaxIndex()
	{	
		intMenuItemsCount++ ; for objMenuColumnBreak
		intMenuArrayItemsCount++ ; for objMenuColumnBreak
		
		if (objCurrentMenu[A_Index].FavoriteType = "B")
			continue
		
		if (objCurrentMenu[A_Index].FavoriteType = "Menu")
		{
			RecursiveBuildOneMenu(objCurrentMenu[A_Index].SubMenu) ; RECURSIVE
			
			if (g_blnUseColors)
				Try Menu, % objCurrentMenu[A_Index].SubMenu.MenuPath, Color, %g_strMenuBackgroundColor% ; Try because this can fail if submenu is empty
			
			strMenuName := (g_blnDisplayMenuShortcuts and (intShortcut <= 35) ? "&" . NextMenuShortcut(intShortcut) . " " : "") . objCurrentMenu[A_Index].FavoriteName
			Try Menu, % objCurrentMenu.MenuPath, Add, % objCurrentMenu[A_Index].FavoriteName, % ":" . objCurrentMenu[A_Index].SubMenu.MenuPath
			catch e ; when menu objCurrentMenu[A_Index].SubMenu.MenuPath is empty
				Menu, % objCurrentMenu.MenuPath, Add, % objCurrentMenu[A_Index].FavoriteName, OpenFavorite ; will never be called because disabled
			Menu, % objCurrentMenu.MenuPath, % (objCurrentMenu[A_Index].SubMenu.MaxIndex() > 1 ? "Enable" : "Disable"), % objCurrentMenu[A_Index].FavoriteName ; disable menu if contains only the back .. item
			if (g_blnDisplayIcons)
			{
				ParseIconResource(objCurrentMenu[A_Index].FavoriteIconResource, strThisIconFile, intThisIconIndex, "iconSubmenu")
				
				Menu, % objCurrentMenu.MenuPath, UseErrorLevel, on
				Menu, % objCurrentMenu.MenuPath, Icon, % objCurrentMenu[A_Index].FavoriteName
					, %strThisIconFile%, %intThisIconIndex% , %g_intIconSize%
				if (ErrorLevel)
					Menu, % objCurrentMenu.MenuPath, Icon, % objCurrentMenu[A_Index].FavoriteName
						, % g_objIconsFile["iconUnknown"], % g_objIconsIndex["iconUnknown"], %g_intIconSize%
				Menu, % objCurrentMenu.MenuPath, UseErrorLevel, off
			}
		}
		
		else if (objCurrentMenu[A_Index].FavoriteType = "X") ; this is a separator
			
			if (objCurrentMenu[A_Index - 1].FavoriteType = "K")
				intMenuItemsCount -= 1 ; separator not allowed as first item is a column, skip it
			else
				Menu, % objCurrentMenu.MenuPath, Add
			
		else if (objCurrentMenu[A_Index].FavoriteType = "K")
		{
			intMenuItemsCount -= 1
			objMenuColumnBreak := Object()
			objMenuColumnBreak.MenuPath := objCurrentMenu.MenuPath
			objMenuColumnBreak.MenuPosition := intMenuItemsCount
			objMenuColumnBreak.MenuArrayPosition := intMenuArrayItemsCount
			g_objMenuColumnBreaks.Insert(objMenuColumnBreak)
		}
		else ; this is a favorite (folder, document, application or link)
		{
			strSubMenuDisplayName := objCurrentMenu[A_Index].FavoriteName
			strMenuName := (g_blnDisplayMenuShortcuts and (intShortcut <= 35) ? "&" . NextMenuShortcut(intShortcut) . " " : "")
				. strSubMenuDisplayName
			Menu, % objCurrentMenu.MenuPath, Add, %strMenuName%, OpenFavorite

			if (g_blnDisplayIcons)
			{
				Menu, % objCurrentMenu.MenuPath, UseErrorLevel, on
				if (objCurrentMenu[A_Index].FavoriteType = "Folder") ; this is a folder
					ParseIconResource(objCurrentMenu[A_Index].FavoriteIconResource, strThisIconFile, intThisIconIndex, "iconFolder")
				else if (objCurrentMenu[A_Index].FavoriteType = "Url") ; this is an URL
					if StrLen(objCurrentMenu[A_Index].FavoriteIconResource)
						ParseIconResource(objCurrentMenu[A_Index].FavoriteIconResource, strThisIconFile, intThisIconIndex)
					else
						GetIcon4Location(g_strTempDir . "\default_browser_icon.html", strThisIconFile, intThisIconIndex)
						; not sure it is required to have a physical file with .html extension - but keep it as is by safety
				else ; this is a document
					if StrLen(objCurrentMenu[A_Index].FavoriteIconResource)
						ParseIconResource(objCurrentMenu[A_Index].FavoriteIconResource, strThisIconFile, intThisIconIndex)
					else
						GetIcon4Location(objCurrentMenu[A_Index].FavoriteLocation, strThisIconFile, intThisIconIndex)
					
				ErrorLevel := 0 ; for safety clear in case Menu is not called in next if
				if StrLen(strThisIconFile)
					Menu, % objCurrentMenu.MenuPath, Icon, %strMenuName%, %strThisIconFile%, %intThisIconIndex%, %g_intIconSize%
				if (!StrLen(strThisIconFile) or ErrorLevel)
					Menu, % objCurrentMenu.MenuPath, Icon, %strMenuName%
						, % g_objIconsFile["iconUnknown"], % g_objIconsIndex["iconUnknown"], %g_intIconSize%
						
				Menu, % objCurrentMenu.MenuPath, UseErrorLevel, off
			}
		}
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
NextMenuShortcut(ByRef intShortcut)
;------------------------------------------------------------
{
	if (intShortcut < 10)
		strShortcut := intShortcut ; 0 .. 9
	else
		strShortcut := Chr(intShortcut + 55) ; Chr(10 + 55) = "A" .. Chr(35 + 55) = "Z"
	
	intShortcut := intShortcut + 1
	return strShortcut
}
;------------------------------------------------------------


;------------------------------------------------------------
AddMenuIcon(strMenuName, ByRef strMenuItemName, strLabel, strIconValue)
; strIconValue can be an item from strIconsMenus (eg: "iconFolder") or a "file,index" combo (eg: "imageres.dll,33")
;------------------------------------------------------------
{
	global g_intIconSize
	global g_blnDisplayIcons
	global g_objIconsFile ; ok
	global g_objIconsIndex ; ok
	global g_blnMainIsFirstColumn

	if !StrLen(strMenuItemName)
		return
	
	; The names of menus and menu items can be up to 260 characters long.
	if StrLen(strMenuItemName) > 260
		strMenuItemName := SubStr(strMenuItemName, 1, 256) . "..." ; minus one for the luck ;-)
	
	Menu, %strMenuName%, Add, %strMenuItemName%, %strLabel%
	if (g_blnDisplayIcons) and ((A_OSVersion <> "WIN_XP") or g_blnMainIsFirstColumn or (strMenuName <> lMainMenuName))
		; under Win_XP, display icons in main menu only when in first column (for other menus, this fuction is not called)
	{
		Menu, %strMenuName%, UseErrorLevel, on
		if InStr(strIconValue, ",")
			ParseIconResource(strIconValue, strIconFile, intIconIndex)
		else
		{
			strIconFile := g_objIconsFile[strIconValue]
			intIconIndex := g_objIconsIndex[strIconValue]
		}
		
		Menu, %strMenuName%, Icon, %strMenuItemName%, %strIconFile%, %intIconIndex%, %g_intIconSize%
		if (ErrorLevel)
			Menu, %strMenuName%, Icon, %strMenuItemName%
				, % g_objIconsFile["iconUnknown"], % g_objIconsIndex["iconUnknown"], %g_intIconSize%
		Menu, %strMenuName%, UseErrorLevel, off
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
InsertColumnBreaks:
; Based on Lexikos
; http://www.autohotkey.com/board/topic/69553-menu-with-columns-problem-with-adding-column-separator/#entry440866
;------------------------------------------------------------

VarSetCapacity(mii, cb:=16+8*A_PtrSize, 0) ; A_PtrSize is used for 64-bit compatibility.
NumPut(cb, mii, "uint")
NumPut(0x100, mii, 4, "uint") ; fMask = MIIM_FTYPE
NumPut(0x20, mii, 8, "uint") ; fType = MFT_MENUBARBREAK

for intIndex, objMenuColumnBreak in g_objMenuColumnBreaks
{
	pMenuHandle := GetMenuHandle(objMenuColumnBreak.MenuName) 
	DllCall("SetMenuItemInfo", "ptr", pMenuHandle, "uint", objMenuColumnBreak.MenuPosition, "int", 1, "ptr", &mii)
}

return
;------------------------------------------------------------


;------------------------------------------------------------
GetMenuHandle(strMenuName)
; from MenuIcons v2 by Lexikos
; http://www.autohotkey.com/board/topic/20253-menu-icons-v2/
;------------------------------------------------------------
{
	static pMenuDummy
	
	; v2.2: Check for !pMenuDummy instead of pMenuDummy="" in case init failed last time.
	If !pMenuDummy
	{
		Menu, menuDummy, Add
		Menu, menuDummy, DeleteAll
		
		Gui, 99:Menu, menuDummy
		; v2.2: Use LastFound method instead of window title. [Thanks animeaime.]
		Gui, 99:+LastFound
		
		pMenuDummy := DllCall("GetMenu", "uint", WinExist())
		
		Gui, 99:Menu
		Gui, 99:Destroy
		
		; v2.2: Return only after cleaning up. [Thanks animeaime.]
		if !pMenuDummy
			return 0
	}

	Menu, menuDummy, Add, :%strMenuName%
	pMenu := DllCall( "GetSubMenu", "uint", pMenuDummy, "int", 0 )
	DllCall( "RemoveMenu", "uint", pMenuDummy, "uint", 0, "uint", 0x400 )
	Menu, menuDummy, Delete, :%strMenuName%

	return pMenu
}
;------------------------------------------------------------



;========================================================================================================================
; END OF BUILD
;========================================================================================================================



;========================================================================================================================
!_025_OPTIONS:
;========================================================================================================================

;------------------------------------------------------------
GuiOptions:
;------------------------------------------------------------

g_intGui1WinID := WinExist("A")
loop, 4
	g_arrHotkeysPrevious%A_Index% := g_arrHotkeys%A_Index% ; allow to turn off replaced hotkeys

StringSplit, g_arrOptionsTitlesSub, lOptionsTitlesSub, |

;---------------------------------------
; Build Gui header
Gui, 1:Submit, NoHide
Gui, 2:New, , % L(lOptionsGuiTitle, g_strAppNameText, g_strAppVersion)
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%
Gui, 2:+Owner1
Gui, 2:Font, s10 w700, Verdana
Gui, 2:Add, Text, x10 y10 w595 center, % L(lOptionsGuiTitle, g_strAppNameText)

Gui, 2:Font, s8 w600, Verdana
Gui, 2:Add, Tab2, vf_intOptionsTab w620 h400 AltSubmit, %A_Space%%lOptionsOtherOptions% | %lOptionsMouseAndKeyboard% | %lOptionsHotkeys% | %lOptionsThirdParty%%A_Space%

;---------------------------------------
; Tab 1: General options

Gui, 2:Tab, 1

Gui, 2:Font
Gui, 2:Add, Text, x10 y+10 w595 center, % L(lOptionsTabOtherOptionsIntro, g_strAppNameText)

; column 1
Gui, 2:Add, Text, y+10 x15 Section, %lOptionsLanguage%
Gui, 2:Add, DropDownList, ys x+10 w120 vf_drpLanguage Sort, %lOptionsLanguageLabels%
GuiControl, ChooseString, f_drpLanguage, %g_strLanguageLabel%

Gui, 2:Add, CheckBox, y+10 xs w220 vf_blnOptionsRunAtStartup, %lOptionsRunAtStartup%
GuiControl, , f_blnOptionsRunAtStartup, % FileExist(A_Startup . "\" . g_strAppNameFile . ".lnk") ? 1 : 0

Gui, 2:Add, CheckBox, y+10 xs w220 vf_blnDisplayMenuShortcuts, %lOptionsDisplayMenuShortcuts%
GuiControl, , f_blnDisplayMenuShortcuts, %g_blnDisplayMenuShortcuts%

Gui, 2:Add, CheckBox, y+10 xs w220 vf_blnDisplayTrayTip, %lOptionsTrayTip%
GuiControl, , f_blnDisplayTrayTip, %g_blnDisplayTrayTip%

Gui, 2:Add, CheckBox, y+10 xs w220 vf_blnCheck4Update, %lOptionsCheck4Update%
GuiControl, , f_blnCheck4Update, %g_blnCheck4Update%

Gui, 2:Add, CheckBox, y+10 xs w220 vf_blnOpenMenuOnTaskbar, %lOptionsOpenMenuOnTaskbar%
GuiControl, , f_blnOpenMenuOnTaskbar, %g_blnOpenMenuOnTaskbar%

Gui, 2:Add, Edit, y+20 xs w36 h17 vf_intRecentFoldersMax center, %g_intRecentFoldersMax%
Gui, 2:Add, Text, yp x+10 w180, %lOptionsRecentFolders%

if !OSVersionIsWorkstation()
{
	g_blnDisplayIcons := 0
	GuiControl, Disable, f_blnDisplayIcons
}
Gui, 2:Add, CheckBox, y+20 xs w220 vf_blnDisplayIcons gDisplayIconsClicked, %lOptionsDisplayIcons%
GuiControl, , f_blnDisplayIcons, %g_blnDisplayIcons%

Gui, 2:Add, Text, % "y+10 xs vf_drpIconSizeLabel " . (g_blnDisplayIcons ? "" : "hidden"), %lOptionsIconSize%
Gui, 2:Add, DropDownList, % "yp x+10 w40 vf_drpIconSize Sort " . (g_blnDisplayIcons ? "" : "hidden"), 16|24|32|48|64
GuiControl, ChooseString, f_drpIconSize, %g_intIconSize%

; column 2

Gui, 2:Add, Text, ys x300 Section, %lOptionsTheme%
Gui, 2:Add, DropDownList, ys x+10 w120 vf_drpTheme, %g_strAvailableThemes%
GuiControl, ChooseString, f_drpTheme, %g_strTheme%

Gui, 2:Add, CheckBox, y+10 xs w190 vf_blnRememberSettingsPosition, %lOptionsRememberSettingsPosition%
GuiControl, , f_blnRememberSettingsPosition, %g_blnRememberSettingsPosition%

Gui, 2:Add, Text, y+12 xs w190 Section, %lOptionsMenuPositionPrompt%

Gui, 2:Add, Radio, % "y+5 xs w190 vf_radPopupMenuPosition1 gPopupMenuPositionClicked Group " . (g_intPopupMenuPosition = 1 ? "Checked" : ""), %lOptionsMenuNearMouse%
Gui, 2:Add, Radio, % "y+5 xs w190 vf_radPopupMenuPosition2 gPopupMenuPositionClicked " . (g_intPopupMenuPosition = 2 ? "Checked" : ""), %lOptionsMenuActiveWindow%
Gui, 2:Add, Radio, % "y+5 xs w190 vf_radPopupMenuPosition3 gPopupMenuPositionClicked " . (g_intPopupMenuPosition = 3 ? "Checked" : ""), %lOptionsMenuFixPosition%

Gui, 2:Add, Text, % "y+5 xs+18 vf_lblPopupFixPositionX " . (g_intPopupMenuPosition = 3 ? "" : "hidden"), %lOptionsPopupFixPositionX%
Gui, 2:Add, Edit, % "yp x+5 w36 h17 vf_strPopupFixPositionX center " . (g_intPopupMenuPosition = 3 ? "" : "hidden"), %g_arrPopupFixPosition1%
Gui, 2:Add, Text, % "yp x+5 vf_lblPopupFixPositionY " . (g_intPopupMenuPosition = 3 ? "" : "hidden"), %lOptionsPopupFixPositionY%
Gui, 2:Add, Edit, % "yp x+5 w36 h17 vf_strPopupFixPositionY center " . (g_intPopupMenuPosition = 3 ? "" : "hidden"), %g_arrPopupFixPosition2%

;---------------------------------------
; Tab 2: Popup menu hotkeys

Gui, 2:Tab, 2

Gui, 2:Font
Gui, 2:Add, Text, x10 y+10 w595 center, % L(lOptionsTabMouseAndKeyboardIntro, g_strAppNameText)

loop, % g_arrHotkeyNames%0%
{
	Gui, 2:Font, s8 w700
	Gui, 2:Add, Text, x15 y+20 w610, % g_arrOptionsTitles%A_Index%
	Gui, 2:Font, s9 w500, Courier New
	Gui, 2:Add, Text, Section x260 y+5 w280 h23 center 0x1000 vf_lblHotkeyText%A_Index% gButtonOptionsChangeHotkey%A_Index%, % Hotkey2Text(strModifiers%A_Index%, strMouseButton%A_Index%, strOptionsKey%A_Index%)
	Gui, 2:Font
	Gui, 2:Add, Button, yp x555 vf_btnChangeHotkey%A_Index% gButtonOptionsChangeHotkey%A_Index%, %lOptionsChangeHotkey%
	Gui, 2:Font, s8 w500
	Gui, 2:Add, Link, x15 ys w240 gOptionsTitlesSubClicked, % g_arrOptionsTitlesSub%A_Index%
}

;---------------------------------------
; Tab 3: Exclusion list

; ### to-do

;---------------------------------------
; Tab 4: File Managers

Gui, 2:Tab, 4

Gui, 2:Add, Text, x10 y+10 w595 center, %lOptionsTabFileManagersIntro%

Gui, 2:Font, s8 w700
Gui, 2:Add, Link, y+15 x15, % L(lOptionsThirdPartyTitle, "Directory Opus") . " (<a href=""http://code.jeanlalonde.ca/using-folderspopup-with-directory-opus/"">" . lGuiHelp . "</a>)"
Gui, 2:Font
Gui, 2:Add, Text, y+5 x15, % L(lOptionsThirdPartyDetail, "Directory Opus")
Gui, 2:Add, Text, y+10 x15, %lOptionsThirdPartyPrompt%
Gui, 2:Add, Edit, x+10 yp w300 h20 vf_strDirectoryOpusPath, %g_strDirectoryOpusPath%
Gui, 2:Add, Button, x+10 yp vf_btnSelectDOpusPath gButtonSelectDOpusPath, %lDialogBrowseButton%
Gui, 2:Add, Checkbox, x+10 yp vf_blnDirectoryOpusUseTabs, %lOptionsDirectoryOpusUseTabs%
GuiControl, , f_blnDirectoryOpusUseTabs, %g_blnDirectoryOpusUseTabs%

Gui, 2:Font, s8 w700
Gui, 2:Add, Link, y+25 x15, % L(lOptionsThirdPartyTitle, "Total Commander") . " (<a href=""http://code.jeanlalonde.ca/using-folderspopup-with-total-commander/"">" . lGuiHelp . "</a>)"
Gui, 2:Font
Gui, 2:Add, Text, y+5 x15, % L(lOptionsThirdPartyDetail, "Total Commander")
Gui, 2:Add, Text, y+10 x15, %lOptionsThirdPartyPrompt%
Gui, 2:Add, Edit, x+10 yp w300 h20 vf_strTotalCommanderPath, %g_strTotalCommanderPath%
Gui, 2:Add, Button, x+10 yp vf_btnSelectTCPath gButtonSelectTCPath, %lDialogBrowseButton%
Gui, 2:Add, Checkbox, x+10 yp vf_blnTotalCommanderUseTabs, %lOptionsTotalCommanderUseTabs%
GuiControl, , f_blnTotalCommanderUseTabs, %g_blnTotalCommanderUseTabs%

Gui, 2:Font, s8 w700
Gui, 2:Add, Link, y+25 x15, %lOptionsThirdPartyTitleFPconnect% (<a href="https://github.com/rolandtoth/FPconnect">%lGuiHelp%</a>)
Gui, 2:Font
Gui, 2:Add, Text, y+5 x15, %lOptionsThirdPartyDetailFPconnect%
Gui, 2:Add, Text, y+10 x15, %lOptionsThirdPartyPrompt%
Gui, 2:Add, Edit, x+10 yp w300 h20 vf_strFPconnectPath, %g_strFPconnectPath%
Gui, 2:Add, Button, x+10 yp vf_btnSelectFPcPath gButtonSelectFPcPath, %lDialogBrowseButton%

;---------------------------------------
; Build Gui footer

Gui, 2:Tab

GuiControlGet, arrTabPos, Pos, f_intOptionsTab

Gui, 2:Add, Button, % "y" . arrTabPosY + arrTabPosH + 10 . " x10 vf_btnOptionsSave gButtonOptionsSave Default", %lGuiSave%
Gui, 2:Add, Button, yp vf_btnOptionsCancel gButtonOptionsCancel, %lGuiCancel%
Gui, 2:Add, Button, yp vf_btnOptionsDonate gGuiDonate, %lDonateButton%
GuiCenterButtons(L(lOptionsGuiTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnOptionsSave", "f_btnOptionsCancel", "f_btnOptionsDonate")

Gui, 2:Add, Text
GuiControl, Focus, f_btnOptionsSave

Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
DisplayIconsClicked:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, % (f_blnDisplayIcons ? "Show" : "Hide"), f_drpIconSizeLabel
GuiControl, % (f_blnDisplayIcons ? "Show" : "Hide"), f_drpIconSize

return
;------------------------------------------------------------


;------------------------------------------------------------
PopupMenuPositionClicked:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, % (f_radPopupMenuPosition3 ? "Show" : "Hide"), f_lblPopupFixPositionX
GuiControl, % (f_radPopupMenuPosition3 ? "Show" : "Hide"), f_strPopupFixPositionX
GuiControl, % (f_radPopupMenuPosition3 ? "Show" : "Hide"), f_lblPopupFixPositionY
GuiControl, % (f_radPopupMenuPosition3 ? "Show" : "Hide"), f_strPopupFixPositionY

return
;------------------------------------------------------------


;------------------------------------------------------------
OptionsTitlesSubClicked:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, Choose, f_intOptionsTab, 3

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonOptionsChangeHotkey1:
ButtonOptionsChangeHotkey2:
ButtonOptionsChangeHotkey3:
ButtonOptionsChangeHotkey4:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

StringReplace, intHotkeyIndex, A_ThisLabel, ButtonOptionsChangeHotkey

if InStr(g_arrHotkeyNames%intHotkeyIndex%, "Mouse")
	intHotkeyType := 1 ; Mouse
else
	intHotkeyType := 2 ; Keyboard

g_arrHotkeys%intHotkeyIndex% := SelectHotkey(g_arrHotkeys%intHotkeyIndex%, g_arrOptionsTitles%intHotkeyIndex%, "", "", intHotkeyType, g_arrHotkeyDefaults%intHotkeyIndex%, g_arrOptionsTitlesSub%intHotkeyIndex%)

SplitHotkey(g_arrHotkeys%intHotkeyIndex%, strNewModifiers, strNewKey, strNewMouse, strNewMouseButtonsWithDefault)
GuiControl, 2:, f_lblHotkeyText%intHotkeyIndex%, % Hotkey2Text(strNewModifiers, strNewMouse, strNewKey)

strNewModifiers := ""
strNewMouse := ""
strNewOptionsKey := ""
strNewMouseButtonsWithDefault := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonSelectDOpusPath:
;------------------------------------------------------------
Gui, 2:+OwnDialogs

if StrLen(g_strDirectoryOpusPath) and (g_strDirectoryOpusPath <> "NO")
	strCurrentDOpusLocation := g_strDirectoryOpusPath
else
	strCurrentDOpusLocation := A_ProgramFiles . "\GPSoftware\Directory Opus\dopus.exe"

FileSelectFile, strNewDOpusLocation, 3, %strCurrentDOpusLocation%, %lDialogAddFolderSelect%

if !(StrLen(strNewDOpusLocation))
	return

GuiControl, 2:, f_strDirectoryOpusPath, %strNewDOpusLocation%

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonSelectTCPath:
;------------------------------------------------------------
Gui, 2:+OwnDialogs

if StrLen(g_strTotalCommanderPath) and (g_strTotalCommanderPath <> "NO")
	strCurrentTCLocation := g_strTotalCommanderPath
else
	strCurrentTCLocation := GetTotalCommanderPath()

FileSelectFile, strNewTCLocation, 3, %strCurrentTCLocation%, %lDialogAddFolderSelect%

if !(StrLen(strNewTCLocation))
	return

GuiControl, 2:, f_strTotalCommanderPath, %strNewTCLocation%

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonSelectFPcPath:
;------------------------------------------------------------
Gui, 2:+OwnDialogs

if StrLen(g_strFPconnectPath) and (g_strFPconnectPath <> "NO")
	strCurrentFPcLocation := g_strFPconnectPath
else
	strCurrentFPcLocation := A_ScriptDir . "\FPconnect\FPconnect.exe"

FileSelectFile, strNewFPcLocation, 3, %strCurrentFPcLocation%, %lDialogAddFolderSelect%

if !(StrLen(strNewFPcLocation))
	return

GuiControl, 2:, f_strFPconnectPath, %strNewFPcLocation%

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonOptionsSave:
;------------------------------------------------------------
Gui, 2:Submit

g_blnMenuReady := false

;---------------------------------------
; Tab 1: General options

IfExist, %A_Startup%\%g_strAppNameFile%.lnk
	FileDelete, %A_Startup%\%g_strAppNameFile%.lnk
if (f_blnOptionsRunAtStartup)
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%g_strAppNameFile%.lnk, %A_WorkingDir%
Menu, Tray, % f_blnOptionsRunAtStartup ? "Check" : "Uncheck", %lMenuRunAtStartup%

g_blnDisplayTrayTip := f_blnDisplayTrayTip
IniWrite, %g_blnDisplayTrayTip%, %g_strIniFile%, Global, DisplayTrayTip
g_blnDisplayIcons := f_blnDisplayIcons
IniWrite, %g_blnDisplayIcons%, %g_strIniFile%, Global, DisplayIcons
g_intRecentFoldersMax := f_intRecentFoldersMax
IniWrite, %g_intRecentFoldersMax%, %g_strIniFile%, Global, RecentFoldersMax
g_blnDisplayMenuShortcuts := f_blnDisplayMenuShortcuts
IniWrite, %g_blnDisplayMenuShortcuts%, %g_strIniFile%, Global, DisplayMenuShortcuts
g_blnDisplayFavoritesHotkeysInMenus := f_blnDisplayFavoritesHotkeysInMenus
IniWrite, %g_blnDisplayFavoritesHotkeysInMenus%, %g_strIniFile%, Global, DisplayFavoritesHotkeysInMenus
g_blnCheck4Update := f_blnCheck4Update
IniWrite, %g_blnCheck4Update%, %g_strIniFile%, Global, Check4Update
g_blnOpenMenuOnTaskbar := f_blnOpenMenuOnTaskbar
IniWrite, %g_blnOpenMenuOnTaskbar%, %g_strIniFile%, Global, OpenMenuOnTaskbar
g_blnRememberSettingsPosition := f_blnRememberSettingsPosition
IniWrite, %g_blnRememberSettingsPosition%, %g_strIniFile%, Global, RememberSettingsPosition

if (f_radPopupMenuPosition1)
	g_intPopupMenuPosition := 1
else if (f_radPopupMenuPosition2)
	g_intPopupMenuPosition := 2
else
	g_intPopupMenuPosition := 3
IniWrite, %g_intPopupMenuPosition%, %g_strIniFile%, Global, PopupMenuPosition

g_arrPopupFixPosition1 := f_strPopupFixPositionX
g_arrPopupFixPosition2 := f_strPopupFixPositionY
IniWrite, %g_arrPopupFixPosition1%`,%g_arrPopupFixPosition2%, %g_strIniFile%, Global, PopupFixPosition

strLanguageCodePrev := g_strLanguageCode
g_strLanguageLabel := f_drpLanguage
loop, %g_arrOptionsLanguageLabels0%
	if (g_arrOptionsLanguageLabels%A_Index% = g_strLanguageLabel)
		{
			g_strLanguageCode := g_arrOptionsLanguageCodes%A_Index%
			break
		}
IniWrite, %g_strLanguageCode%, %g_strIniFile%, Global, LanguageCode

strThemePrev := g_strTheme
g_strTheme := f_drpTheme
IniWrite, %g_strTheme%, %g_strIniFile%, Global, Theme

g_intIconSize := f_drpIconSize
IniWrite, %g_intIconSize%, %g_strIniFile%, Global, IconSize

;---------------------------------------
; Tab 2: Popup menu hotkeys

loop, % g_arrHotkeyNames%0%
	if (g_arrHotkeys%A_Index% = "None") ; do not compare with lOptionsMouseNone because it is translated
		IniWrite, None, %g_strIniFile%, Global, % g_arrHotkeyNames%A_Index% ; do not write lOptionsMouseNone because it is translated
	else
		IniWrite, % g_arrHotkeys%A_Index%, %g_strIniFile%, Global, % g_arrHotkeyNames%A_Index%

Gosub, LoadIniHotkeys ; reload ini variables and reset hotkeys

;---------------------------------------
; Tab 3: Exclusion list

; ### to-do

g_strExclusionClassList := "SciTEWindow|Chrome_WidgetWin_1|" ; must end with |

;---------------------------------------
; Tab 4: File Managers

g_strDirectoryOpusPath := f_strDirectoryOpusPath
IniWrite, %g_strDirectoryOpusPath%, %g_strIniFile%, Global, DirectoryOpusPath
g_blnDirectoryOpusUseTabs := f_blnDirectoryOpusUseTabs
IniWrite, %g_blnDirectoryOpusUseTabs%, %g_strIniFile%, Global, DirectoryOpusUseTabs
g_blnUseDirectoryOpus := StrLen(g_strDirectoryOpusPath)
if (g_blnUseDirectoryOpus)
{
	g_blnUseDirectoryOpus := FileExist(g_strDirectoryOpusPath)
	if (g_blnUseDirectoryOpus)
		Gosub, SetDOpusRt
}
if (g_blnDirectoryOpusUseTabs)
	g_strDirectoryOpusNewTabOrWindow := "NEWTAB" ; open new folder in a new lister tab
else
	g_strDirectoryOpusNewTabOrWindow := "NEW" ; open new folder in a new DOpus lister (instance)

g_strTotalCommanderPath := f_strTotalCommanderPath
IniWrite, %g_strTotalCommanderPath%, %g_strIniFile%, Global, TotalCommanderPath
g_blnTotalCommanderUseTabs := f_blnTotalCommanderUseTabs
IniWrite, %g_blnTotalCommanderUseTabs%, %g_strIniFile%, Global, TotalCommanderUseTabs
g_blnUseTotalCommander := StrLen(g_strTotalCommanderPath)
if (g_blnUseTotalCommander)
{
	g_blnUseTotalCommander := FileExist(g_strTotalCommanderPath)
	if (g_blnUseTotalCommander)
		Gosub, SetTCCommand
}
if (g_blnTotalCommanderUseTabs)
	g_strTotalCommanderNewTabOrWindow := "/O /T" ; open new folder in a new tab
else
	g_strTotalCommanderNewTabOrWindow := "/N" ; open new folder in a new window (TC instance)

g_strFPconnectPath := f_strFPconnectPath
IniWrite, %g_strFPconnectPath%, %g_strIniFile%, Global, FPconnectPath
g_blnUseFPconnect := StrLen(g_strFPconnectPath)
if (g_blnUseFPconnect)
{
	g_blnUseFPconnect := FileExist(g_strFPconnectPath)
	if (g_blnUseFPconnect)
		Gosub, SetFPconnect
}

; if language or theme changed, offer to restart the app
if (strLanguageCodePrev <> g_strLanguageCode) or (strThemePrev <> g_strTheme)
{
	MsgBox, 52, %g_strAppNameText%, % L(lReloadPrompt, (strLanguageCodePrev <> g_strLanguageCode ? lOptionsLanguage : lOptionsTheme), (strLanguageCodePrev <> g_strLanguageCode ? g_strLanguageLabel : g_strTheme), g_strAppNameText)
	IfMsgBox, Yes
		Reload
}	

; else rebuild Explorers folder
Gosub, BuildFoldersInExplorerMenu

; and rebuild Folders menus w/ or w/o optional folders and shortcuts
for strMenuName, arrMenu in g_arrMenus
{
	Menu, %strMenuName%, Add
	Menu, %strMenuName%, DeleteAll
	arrMenu := "" ; free object's memory
}
Gosub, BuildMainMenuWithStatus

Gosub, 2GuiClose

g_blnMenuReady := true

strLanguageCodePrev := ""
strThemePrev := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonOptionsCancel:
;------------------------------------------------------------
Gosub, 2GuiClose

return
;------------------------------------------------------------



;========================================================================================================================
; END OF OPTIONS
;========================================================================================================================


;========================================================================================================================
!_030_FAVORITES_LIST:
;========================================================================================================================

;------------------------------------------------------------
BuildGui:
;------------------------------------------------------------

IniRead, strTextColor, %g_strIniFile%, Gui-%g_strTheme%, TextColor, 000000
IniRead, strGuiListviewBackgroundColor, %g_strIniFile%, Gui-%g_strTheme%, ListviewBackground, FFFFFF
IniRead, strGuiListviewTextColor, %g_strIniFile%, Gui-%g_strTheme%, ListviewText, 000000

lGuiFullTitle := L(lGuiTitle, g_strAppNameText, g_strAppVersion)
Gui, 1:New, +Resize -MinimizeBox +MinSize636x538, %lGuiFullTitle%

Gui, +LastFound
g_strAppHwnd := WinExist()

if (g_blnUseColors)
	Gui, 1:Color, %g_strGuiWindowColor%

; Order of controls important to avoid drawgins gliches when resizing

Gui, 1:Font, % "s12 w700 " . (g_blnUseColors ? "c" . strTextColor : ""), Verdana
Gui, 1:Add, Text, vf_lblAppName x0 y0, %g_strAppNameText% %g_strAppVersion%
Gui, 1:Font, s9 w400, Verdana
Gui, 1:Add, Text, vf_lblAppTagLine, %lAppTagline%

Gui, 1:Add, Picture, vf_picGuiAddFavorite gGuiAddFavoriteSelectType, %g_strTempDir%\add_property-48.png ; Static3
Gui, 1:Add, Picture, vf_picGuiEditFavorite gGuiEditFavorite x+1 yp, %g_strTempDir%\edit_property-48.png ; Static4
Gui, 1:Add, Picture, vf_picGuiRemoveFavorite gGuiRemoveFavorite x+1 yp, %g_strTempDir%\delete_property-48.png ; Static5
; Gui, 1:Add, Picture, vf_picGuiGroupsManage gGuiGroupsManage x+1 yp, %g_strTempDir%\channel_mosaic-48.png ; Static6
Gui, 1:Add, Picture, vf_picGuiOptions gGuiOptions x+1 yp, %g_strTempDir%\settings-32.png ; Static7
Gui, 1:Add, Picture, vf_picPreviousMenu gGuiGotoPreviousMenu hidden x+1 yp, %g_strTempDir%\left-12.png ; Static8
Gui, 1:Add, Picture, vf_picUpMenu gGuiGotoUpMenu hidden x+1 yp, %g_strTempDir%\up-12.png ; Static9
Gui, 1:Add, Picture, vf_picMoveFavoriteUp gGuiMoveFavoriteUp x+1 yp, %g_strTempDir%\up_circular-26.png ; Static10
Gui, 1:Add, Picture, vf_picMoveFavoriteDown gGuiMoveFavoriteDown x+1 yp, %g_strTempDir%\down_circular-26.png ; Static11
Gui, 1:Add, Picture, vf_picAddSeparator gGuiAddSeparator x+1 yp, %g_strTempDir%\separator-26.png ; Static12
Gui, 1:Add, Picture, vf_picAddColumnBreak gGuiAddColumnBreak x+1 yp, %g_strTempDir%\column-26.png ; Static13
; OUT Gui, 1:Add, Picture, vpicSortFavorites gGuiSortFavorites x+1 yp, %g_strTempDir%\generic_sorting2-26-grey.png ; Static14
Gui, 1:Add, Picture, vf_picGuiAbout gGuiAbout x+1 yp, %g_strTempDir%\about-32.png ; Static15
Gui, 1:Add, Picture, vf_picGuiHelp gGuiHelp x+1 yp, %g_strTempDir%\help-32.png ; Static16

Gui, 1:Font, s8 w400, Arial ; button legend
Gui, 1:Add, Text, vf_lblGuiOptions gGuiOptions x0 y+20, %lGuiOptions% ; Static17
Gui, 1:Add, Text, vf_lblGuiAddFavorite center gGuiAddFavoriteSelectType x+1 yp, %lGuiAddFavorite% ; Static18
Gui, 1:Add, Text, vf_lblGuiEditFavorite center gGuiEditFavorite x+1 yp w88, %lGuiEditFavorite% ; Static19, w88 to make room fot when multiple favorites are selected
Gui, 1:Add, Text, vf_lblGuiRemoveFavorite center gGuiRemoveFavorite x+1 yp, %lGuiRemoveFavorite% ; Static20
; Gui, 1:Add, Text, vf_lblGuiGroupsManage center gGuiGroupsManage x+1 yp, %lDialogGroups% ; Static21
Gui, 1:Add, Text, vf_lblGuiAbout center gGuiAbout x+1 yp, %lGuiAbout% ; Static22
Gui, 1:Add, Text, vf_lblGuiHelp center gGuiHelp x+1 yp, %lGuiHelp% ; Static23

Gui, 1:Font, s8 w400 italic, Verdana
Gui, 1:Add, Link, vf_lnkGuiHotkeysHelpClicked gGuiHotkeysHelpClicked x0 y+1, <a>%lGuiHotkeysHelp%</a> ; center option not working SysLink1
Gui, 1:Add, Link, vf_lnkGuiDropHelpClicked gGuiDropFilesHelpClicked right x+1 yp, <a>%lGuiDropFilesHelp%</a> ; SysLink2

Gui, 1:Font, s8 w400 normal, Verdana
Gui, 1:Add, Text, vf_lblSubmenuDropdownLabel x+1 yp, %lGuiSubmenuDropdownLabel%
Gui, 1:Add, DropDownList, vf_drpMenusList gGuiMenusListChanged x0 y+1

Gui, 1:Add, ListView
	, % "vf_lvFavoritesList Count32 AltSubmit NoSortHdr LV0x10 " . (g_blnUseColors ? "c" . strGuiListviewTextColor . " Background" . strGuiListviewBackgroundColor : "") . " gGuiFavoritesListEvents x+1 yp"
	, %lGuiLvFavoritesHeader%

Gui, 1:Font, s9 w600, Verdana
Gui, 1:Add, Button, vf_btnGuiSave Disabled Default gGuiSave x200 y400 w100 h50, %lGuiSave% ; Button1
Gui, 1:Add, Button, vf_btnGuiCancel gGuiCancel x350 yp w100 h50, %lGuiClose% ; Close until changes occur - Button2

if !(g_blnDonor)
{
	strDonateButtons := "thumbs_up|solutions|handshake|conference|gift"
	StringSplit, arrDonateButtons, strDonateButtons, |
	Random, intDonateButton, 1, 5

	Gui, 1:Add, Picture, vf_picGuiDonate gGuiDonate x0 y+1, % g_strTempDir . "\" . arrDonateButtons%intDonateButton% . "-32.png" ; Static25
	Gui, 1:Font, s8 w400, Arial ; button legend
	Gui, 1:Add, Text, vf_lblGuiDonate center gGuiDonate x0 y+1, %lGuiDonate% ; Static26
}

IniRead, strSettingsPosition, %g_strIniFile%, Global, SettingsPosition, -1 ; center at minimal size
StringSplit, arrSettingsPosition, strSettingsPosition, |

Gui, 1:Show, % "Hide "
	. (arrSettingsPosition1 = -1 or arrSettingsPosition1 = "" or arrSettingsPosition2 = ""
	? "center w636 h538"
	: "x" . arrSettingsPosition1 . " y" . arrSettingsPosition2)
sleep, 100
if (arrSettingsPosition1 <> -1)
	WinMove, ahk_id %g_strAppHwnd%, , , , %arrSettingsPosition3%, %arrSettingsPosition4%

strSettingsPosition := ""
arrSettingsPosition := ""
strTextColor := ""
strGuiListviewBackgroundColor := ""
strGuiListviewTextColor := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
LoadMenuInGui:
;------------------------------------------------------------

Gui, 1:ListView, f_lvFavoritesList
LV_Delete()

Loop, % g_objMenuInGui.MaxIndex()
	
	if InStr("Menu|Group", g_objMenuInGui[A_Index].FavoriteType) ; this is a menu or a group
		LV_Add(, g_objMenuInGui[A_Index].FavoriteName, g_objFavoriteTypesShortNames[g_objMenuInGui[A_Index].FavoriteType]
			, (g_objMenuInGui[A_Index].FavoriteType = "Menu" ? g_strMenuPathSeparator : g_strGroupPathSeparator))
	
	else if (g_objMenuInGui[A_Index].FavoriteType = "X") ; this is a separator
		LV_Add(, g_strGuiMenuSeparator, "---", g_strGuiMenuSeparator . g_strGuiMenuSeparator)
	
	else if (g_objMenuInGui[A_Index].FavoriteType = "K") ; this is a column break
		LV_Add(, g_strGuiMenuColumnBreak . " " . lMenuColumnBreak . " " . g_strGuiMenuColumnBreak
		, "===", g_strGuiMenuColumnBreak . " " . lMenuColumnBreak . " " . g_strGuiMenuColumnBreak)
		
	else if (g_objMenuInGui[A_Index].FavoriteType = "B") ; this is a back link
		LV_Add(, g_objMenuInGui[A_Index].FavoriteName, "   ..   " , "")
		
	else ; this is a folder, document, URL or application
		LV_Add(, g_objMenuInGui[A_Index].FavoriteName, g_objFavoriteTypesShortNames[g_objMenuInGui[A_Index].FavoriteType], g_objMenuInGui[A_Index].FavoriteLocation)

LV_Modify(1 + (g_objMenuInGui[1].FavoriteType = "B" ? 1 : 0), "Select Focus") 

Gosub, AjustColumnWidth

GuiControl, , f_drpMenusList, % "|" . RecursiveBuildMenuTreeDropDown(g_objMainMenu, g_objMenuInGui.MenuPath) . "|"

GuiControl, Focus, f_lvFavoritesList

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiSize:
;------------------------------------------------------------

if (A_EventInfo = 1)  ; The window has been minimized.  No action needed.
    return

g_intListW := A_GuiWidth - 40 - 88
intListH := A_GuiHeight - 115 - 132

intButtonSpacing := (g_intListW - (100 * 2)) // 3

for intIndex, objGuiControl in g_objGuiControls
{
	intX := objGuiControl.X
	intY := objGuiControl.Y

	if (intX < 0)
		intX:= A_GuiWidth + intX
	if (intY < 0)
		intY := A_GuiHeight + intY

	if (objGuiControl.Center)
	{
		GuiControlGet, arrPos, Pos, % objGuiControl.Name
		intX := intX - (arrPosW // 2) ; Floor divide
	}

	if (objGuiControl.Name = "f_lnkGuiDropHelpClicked")
	{
		GuiControlGet, arrPos, Pos, f_lnkGuiDropHelpClicked
		intX := intX - arrPosW
	}
	else if (objGuiControl.Name = "f_btnGuiSave")
		intX := 40 + intButtonSpacing
	else if (objGuiControl.Name = "f_btnGuiCancel")
		intX := 40 + (2 * intButtonSpacing) + 100
		
	GuiControl, % "1:Move" . (objGuiControl.Draw ? "Draw" : ""), % objGuiControl.Name, % "x" . intX	.  " y" . intY
		
}

GuiControl, 1:Move, f_drpMenusList, w%g_intListW%
GuiControl, 1:Move, f_lvFavoritesList, w%g_intListW% h%intListH%

Gosub, AjustColumnWidth

intListH := ""
intButtonSpacing := ""
intIndex := ""
objGuiControl := ""
intX := ""
intY := ""
arrPos := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
AjustColumnWidth:
;------------------------------------------------------------

LV_ModifyCol(1, "Auto") ; adjust column width
LV_ModifyCol(2, "Auto") ; adjust column width

; See http://www.autohotkey.com/board/topic/6073-get-listview-column-width-with-sendmessage/
intCol1 := 0 ; column index, zero-based
SendMessage, 0x1000+29, %intCol1%, 0, SysListView321, ahk_id %g_strAppHwnd%
intCol1 := ErrorLevel ; column width

intCol2 := 0 ; column index, zero-based
SendMessage, 0x1000+29, %intCol2%, 0, SysListView321, ahk_id %g_strAppHwnd%
intCol2 := ErrorLevel ; column width

LV_ModifyCol(3, g_intListW - intCol1 - intCol2 - 21) ; adjust column width (-21 is for vertical scroll bar width)

intCol1 := ""
intCol2 := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiHotkeysHelpClicked:
;------------------------------------------------------------
Gui, 1:+OwnDialogs

MsgBox, 0, %g_strAppNameText% - %lGuiHotkeysHelp%
	, %lGuiHotkeysHelpText%

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiDropFilesHelpClicked:
;------------------------------------------------------------
Gui, 1:+OwnDialogs

MsgBox, 0, %g_strAppNameText% - %lGuiDropFilesHelp%
	, % L(lGuiDropFilesIncentive, g_strAppNameText, lDialogFolderLabel, lDialogFileLabel, lDialogApplicationLabel)

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiFavoritesListEvents:
;------------------------------------------------------------

Gui, 1:ListView, f_lvFavoritesList

if (A_GuiEvent = "DoubleClick")
{
	g_intOriginalMenuPosition := LV_GetNext()
	if InStr("Menu|Group", g_objMenuInGui[g_intOriginalMenuPosition].FavoriteType)
		Gosub, OpenMenuFromGuiHotkey
	else if (g_objMenuInGui[g_intOriginalMenuPosition].FavoriteType = "B")
		Gosub, GuiGotoUpMenu
	else
		gosub, GuiEditFavorite
}
else if (A_GuiEvent = "I") ; Item changed, change Edit button label
{
	g_intFavoriteSelected := LV_GetCount("Selected")
	if (g_intFavoriteSelected > 1)
	{
		GuiControl, , f_lblGuiEditFavorite, % lGuiMove . " (" . g_intFavoriteSelected . ")"
		GuiControl, +gGuiMoveMultipleFavoritesToMenu, f_lblGuiEditFavorite
		GuiControl, +gGuiMoveMultipleFavoritesToMenu, f_picGuiEditFavorite
		GuiControl, , f_lblGuiRemoveFavorite, % lGuiRemoveFavorite . " (" . g_intFavoriteSelected . ")"
		GuiControl, +gGuiRemoveMultipleFavorites, f_lblGuiRemoveFavorite
		GuiControl, +gGuiRemoveMultipleFavorites, f_picGuiRemoveFavorite
		GuiControl, +gGuiMoveMultipleFavoritesUp, f_picMoveFavoriteUp
		GuiControl, +gGuiMoveMultipleFavoritesDown, f_picMoveFavoriteDown
	}
	else
	{
		GuiControl, , f_lblGuiEditFavorite, %lGuiEditFavorite%
		GuiControl, +gGuiEditFavorite, f_lblGuiEditFavorite
		GuiControl, +gGuiEditFavorite, f_picGuiEditFavorite
		GuiControl, , f_lblGuiRemoveFavorite, %lGuiRemoveFavorite%
		GuiControl, +gGuiRemoveFavorite, f_lblGuiRemoveFavorite
		GuiControl, +gGuiRemoveFavorite, f_picGuiRemoveFavorite
		GuiControl, +gGuiMoveFavoriteUp, f_picMoveFavoriteUp
		GuiControl, +gGuiMoveFavoriteDown, f_picMoveFavoriteDown
	}
}

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavoriteSelectType:
;------------------------------------------------------------

g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide
g_intOriginalMenuPosition := (LV_GetCount() ? (LV_GetNext() ? LV_GetNext() : 0xFFFF) : 1)

Gui, 2:New, , % L(lDialogAddFavoriteSelectTitle, g_strAppNameText, g_strAppVersion)
Gui, 2:+Owner1
Gui, 2:+OwnDialogs
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%

Gui, 2:Add, Text, x10 y+20, %lDialogAdd%:
Gui, 2:Add, Text, x+10 yp section

loop, %g_arrFavoriteTypes0%
	Gui, 2:Add, Radio, % (A_Index = 1 ? " vf_intRadioFavoriteType yp " : (A_Index = 7 or A_Index = 8? "y+15 " : "")) . "xs gFavoriteSelectTypeRadioButtonsChanged", % g_objFavoriteTypesLabels[g_arrFavoriteTypes%A_Index%]

Gui, 2:Add, Button, x+20 y+20 vf_btnAddFavoriteSelectTypeContinue gGuiAddFavoriteSelectTypeContinue default, %lDialogContinue%
Gui, 2:Add, Button, yp vf_btnAddFavoriteSelectTypeCancel gGuiEditFavoriteCancel, %lGuiCancel%
Gui, Add, Text
Gui, 2:Add, Text, % "xs+120 ys vf_lblAddFavoriteTypeHelp w250 h" . g_arrFavoriteTypes0 * 20, % L(lDialogFavoriteSelectType, lDialogContinue)

GuiCenterButtons(L(lDialogAddFavoriteSelectTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnAddFavoriteSelectTypeContinue", "f_btnAddFavoriteSelectTypeCancel")
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
FavoriteSelectTypeRadioButtonsChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

if (g_arrFavoriteTypes%f_intRadioFavoriteType% = "QAP")
	GuiControl, , f_lblAddFavoriteTypeHelp, % L(g_objFavoriteTypesHelp["QAP"], lMenuRecentFolders, lMenuCurrentFolders, lMenuAddThisFolder, L(lMenuSettings, g_strAppNameText), lGuiOptions)
else
	GuiControl, , f_lblAddFavoriteTypeHelp, % g_objFavoriteTypesHelp[g_arrFavoriteTypes%f_intRadioFavoriteType%]

if (A_GuiEvent = "DoubleClick")
	Gosub, GuiAddFavoriteSelectTypeContinue

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavoriteSelectTypeContinue:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

; GuiControl, , f_lblAddFavoriteTypeHelp, % g_objFavoriteTypesHelp[] ; OUT OK?

g_strAddFavoriteType := g_arrFavoriteTypes%f_intRadioFavoriteType%

Gosub, GuiAddFavorite

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiDropFiles:
;------------------------------------------------------------

Loop, parse, A_GuiEvent, `n
{
    g_strNewLocation = %A_LoopField%
    Break
}

g_intOriginalMenuPosition := (LV_GetCount() ? (LV_GetNext() ? LV_GetNext() : 0xFFFF) : 1)
Gosub, GuiAddFromDropFiles

return
;------------------------------------------------------------


;------------------------------------------------------------
AddThisFolder:
;------------------------------------------------------------

; ### TO BE TESTED WHEN MENU IS DEVELOPED

/*
if WindowIsDirectoryOpus(strTargetClass)
{
	objDOpusListers := Object()
	CollectDOpusListersList(objDOpusListers, strListText) ; list all listers, excluding special folders like Recycle Bin
	; ### QAP NOTE: NOT SURE strListText IS CORRECTLY INITAILIZED IN FP? BUT IT WORKS...
	
	; From leo @ GPSoftware (http://resource.dopus.com/viewtopic.php?f=3&t=23013):
	; Lines will have active_lister="1" if they represent tabs from the active lister.
	; To get the active tab you want the line with active_lister="1" and tab_state="1".
	; tab_state="1" means it's the selected tab, on the active side of the lister.
	; tab_state="2" means it's the selected tab, on the inactive side of a dual-display lister.
	; Tabs which are not visible (because another tab is selected on top of them) don't get a tab_state attribute at all.

	for intIndex, objLister in objDOpusListers
		if (objLister.active_lister = "1" and objLister.tab_state = "1") ; this is the active tab
		{
			g_strNewLocation := objLister.LocationURL
			break
		}
}
else
{
	objPrevClipboard := ClipboardAll ; Save the entire clipboard
	ClipBoard := ""

	; Add This folder menu is active only if we are in Explorer or in a Dialog box.
	; In all these OS, with Explorer, the key sequence {F4}{Esc} selects the current location of the window.
	; With dialog boxes, the key sequence {F4}{Esc} generally selects the current location of the window. But, in some
	; dialog boxes, the {Esc} key closes the dialog box. We will check window title to detect this behavior.

	if (strTargetClass = "#32770")
		intWaitTimeIncrement := 300 ; time allowed for dialog boxes
	else
		intWaitTimeIncrement := 150 ; time allowed for Explorer

	if (g_blnDiagMode)
		intTries := 8
	else
		intTries := 3

	strWindowTitle := ""
	Loop, %intTries%
	{
		Sleep, intWaitTimeIncrement * A_Index
		WinGetTitle, strWindowTitle, A ; to check later if this window is closed unexpectedly
	} Until (StrLen(strWindowTitle))

	if WindowIsTotalCommander(strTargetClass)
	{
		cm_CopySrcPathToClip := 2029
		SendMessage, 0x433, %cm_CopySrcPathToClip%, , , ahk_class TTOTAL_CMD ; 
		WinGetTitle, strWindowThisTitle, A ; to check if the window was closed unexpectedly
	}
	else ; Explorer
		Loop, %intTries%
		{
			Sleep, intWaitTimeIncrement * A_Index
			SendInput, {F4}{Esc} ; F4 move the caret the "Go To A Different Folder box" and {Esc} select it content ({Esc} could be replaced by ^a to Select All)
			Sleep, intWaitTimeIncrement * A_Index
			SendInput, ^c ; Copy
			Sleep, intWaitTimeIncrement * A_Index
			intTries := A_Index
			WinGetTitle, strWindowThisTitle, A ; to check if the window was closed unexpectedly
		} Until (StrLen(ClipBoard) or (strWindowTitle <> strWindowThisTitle))

	g_strNewLocation := ClipBoard
	Clipboard := objPrevClipboard ; Restore the original clipboard
	objPrevClipboard := "" ; Free the memory in case the clipboard was very large

	if (g_blnDiagMode)
	{
		Diag("Menu", A_ThisLabel)
		Diag("Class", strTargetClass)
		Diag("Tries", intTries)
		Diag("AddedFolder", g_strNewLocation)
	}
}

If !StrLen(g_strNewLocation) or !(InStr(g_strNewLocation, ":") or InStr(g_strNewLocation, "\\")) or (strWindowTitle <> strWindowThisTitle)
{
	Gui, 1:+OwnDialogs 
	MsgBox, 52, % L(lDialogAddFolderManuallyTitle, g_strAppNameText, g_strAppVersion), %lDialogAddFolderManuallyPrompt%
	IfMsgBox, Yes
	{
		Gosub, GuiShow
		Gosub, GuiAddFavorite
	}
}
else
{
	Gosub, GuiShow
	Gosub, GuiAddThisFolder
}

objDOpusListers :=

RELEASE ALL LOCAL VARIABLES

*/

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavorite:
GuiAddThisFolder:
GuiAddFromDropFiles:
GuiEditFavorite:
;------------------------------------------------------------

; Icon resource in the format "iconfile,index", examnple "shell32.dll,2"
; g_strDefaultIconResource -> default icon for the current type of favorite
; g_strNewFavoriteIconResource -> icon currently displayed in the Add/Edit dialog box

; g_strNewFavoriteHotkey -> actual hotkey in internal format displayed as text in the Add/Edit dialog box

; when edit favorite, keep original values in g_objEditedFavorite
; when add favorite, put initial or default values in g_objEditedFavorite and update them when gui save

g_objEditedFavorite := Object()
g_strDefaultIconResource := ""
g_strNewFavoriteIconResource := ""

if (A_ThisLabel = "GuiEditFavorite")
{
	Gui, 1:ListView, f_lvFavoritesList
	g_intOriginalMenuPosition := LV_GetNext()
	
	if (g_intOriginalMenuPosition = "")
	{
		Oops(lDialogSelectItemToEdit)
		return
	}
	
	g_objEditedFavorite := g_objMenuInGui[g_intOriginalMenuPosition]
	
	if (g_objEditedFavorite.FavoriteType = "B")
		return
	
	if InStr("XK", g_objEditedFavorite.FavoriteType) ; favorite is menu separator or column break
		return

	g_strNewFavoriteIconResource := g_objEditedFavorite.FavoriteIconResource
	g_strNewFavoriteWindowPosition := g_objEditedFavorite.FavoriteWindowPosition

	if (g_objEditedFavorite.FavoriteType = "Group")
	{
	   ; 1 boolean value (replace existing Explorer windows if true, add to existing Explorer Windows if false)
	   ; 2 delay in milliseconds to insert between each favorite to restore
	   ; 3 delay in milliseconds to insert between each retries of Explorer launch
		strGroupSettings := g_objEditedFavorite.FavoriteGroupSettings . ",,," ; ,,, to make sure all fields are re-init
		StringSplit, arrGroupSettings, strGroupSettings, `,
	}
}
else
{
	if (A_ThisLabel <> "GuiAddThisFolder") ; else position is set in AddThisFolder
		g_strNewFavoriteWindowPosition := ""

	if InStr("GuiAddThisFolder|GuiAddFromDropFiles", A_ThisLabel)
	{
		; g_strNewLocation is received from AddThisFolder or GuiDropFiles
		g_objEditedFavorite.FavoriteLocation := g_strNewLocation
		g_objEditedFavorite.FavoriteName := GetDeepestFolderName(g_strNewLocation)
	}
	g_objEditedFavorite.FavoriteHotkey := "None" ; internal name

	if (A_ThisLabel = "GuiAddFavorite")
		g_objEditedFavorite.FavoriteType := g_strAddFavoriteType
	else if (A_ThisLabel = "GuiAddThisFolder")
		g_objEditedFavorite.FavoriteType := "Folder"
	else if (A_ThisLabel = "GuiAddFromDropFiles")
	{
		SplitPath, g_strNewLocation, , , strExtension
		if StrLen(strExtension) and InStr("exe|com|bat", strExtension)
			g_objEditedFavorite.FavoriteType := "Application"
		else if LocationIsDocument(g_strNewLocation)
			g_objEditedFavorite.FavoriteType := "Document"
		else
			g_objEditedFavorite.FavoriteType := "Folder"
	}
}
g_strNewFavoriteWindowPosition .= ",,,,,,," ; extra coma to avoid having phantom values if in case string is empty
 
g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide
if (A_ThisLabel = "GuiAddFavorite")
	Gosub, 2GuiClose ; to avoid flashing Gui 1:

Gui, 2:New, , % L(lDialogAddEditFavoriteTitle, (A_ThisLabel = "GuiEditFavorite" ? lDialogEdit : lDialogAdd), g_strAppNameText, g_strAppVersion, g_objEditedFavorite.FavoriteType)
Gui, 2:+Owner1
Gui, 2:+OwnDialogs
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%

Gui, 2:Add, Tab2, vf_intAddFavoriteTab w420 h380 gGuiAddFavoriteTabChanged AltSubmit, % " " . BuildTabsList(g_objEditedFavorite.FavoriteType) . " "
intTabNumber := 0

; ------ TAB Basic Settings ------

Gui, 2:Tab, % ++intTabNumber

Gui, 2:Font, w700
Gui, 2:Add, Text, x20 y40 w400, % lDialogFavoriteType . ": " . g_objFavoriteTypesLabels[g_objEditedFavorite.FavoriteType]
Gui, 2:Font

if (g_objEditedFavorite.FavoriteType = "QAP")
	Gui, 2:Add, Text, x20 y+10 w400, % ReplaceAllInString(L(g_objFavoriteTypesHelp["QAP"], lMenuRecentFolders, lMenuCurrentFolders, lMenuAddThisFolder, L(lMenuSettings, g_strAppNameText), lGuiOptions), "`n`n", "`n")
else
	Gui, 2:Add, Text, x20 y+10 w400, % "> " . ReplaceAllInString(g_objFavoriteTypesHelp[g_objEditedFavorite.FavoriteType], "`n`n", "`n> ")

if (g_objEditedFavorite.FavoriteType = "QAP")
	Gui, 2:Add, Edit, x20 y+0 vf_strFavoriteShortName hidden, % g_objEditedFavorite.FavoriteName ; not allow to change favorite short name for QAP feature favorites
else
{
	Gui, 2:Add, Text, x20 y+20, % L(lDialogFavoriteShortNameLabel, g_objFavoriteTypesLabels[g_objEditedFavorite.FavoriteType]) . " *"

	Gui, 2:Add, Edit
		, % "x20 y+10 Limit250 vf_strFavoriteShortName w" . 300 - (g_objEditedFavorite.FavoriteType = "Menu" ? 50 : 0)
		, % g_objEditedFavorite.FavoriteName
}

if (g_objEditedFavorite.FavoriteType = "Menu" and A_ThisLabel = "GuiEditFavorite")
	Gui, 2:Add, Button, x+10 yp gGuiOpenThisMenu, %lDialogOpenThisMenu%

if !InStr("Special|QAP", g_objEditedFavorite.FavoriteType)
{
	if !InStr("Menu|Group", g_objEditedFavorite.FavoriteType)
	{
		Gui, 2:Add, Text, x20 y+20, % g_objFavoriteTypesLocationLabels[g_objEditedFavorite.FavoriteType] . " *"
		Gui, 2:Add, Edit, x20 y+10 w300 h20 vf_strFavoriteLocation gEditFavoriteLocationChanged, % g_objEditedFavorite.FavoriteLocation
		if InStr("Folder|Document|Application", g_objEditedFavorite.FavoriteType)
			Gui, 2:Add, Button, x+10 yp gButtonSelectFavoriteLocation vf_btnSelectFolderLocation, %lDialogBrowseButton%
	}
	
	if (g_objEditedFavorite.FavoriteType = "Application")
	{
		Gui, 2:Add, Text, x20 y+20 vf_lblSelectRunningApplication, %lDialogBrowseOrSelectApplication%
		Gui, 2:Add, DropDownList, x20 y+5 w400 vf_drpRunningApplication gDropdownRunningApplicationChanged
			, % CollectRunningApplications(g_objEditedFavorite.FavoriteLocation)
	}
}
else ; "Special" or "QAP"
{
	Gui, 2:Add, Edit, x20 y+20 hidden section vf_strFavoriteLocation, % g_objEditedFavorite.FavoriteLocation ; hidden because set by DropdownSpecialChanged or DropdownQAPChanged
	Gui, 2:Add, Text, xs ys, % g_objFavoriteTypesLabels[g_objEditedFavorite.FavoriteType] . " *"

	Gui, 2:Add, DropDownList
		, % "x20 y+10 w300 vf_drp" . g_objEditedFavorite.FavoriteType . " gDropdown" . g_objEditedFavorite.FavoriteType . "Changed"
		, % lDialogSelectItemToAdd . "...||" . (g_objEditedFavorite.FavoriteType = "Special" ? g_strSpecialFoldersList : g_strQAPFeaturesList)
	if (A_ThisLabel = "GuiEditFavorite")
		if (g_objEditedFavorite.FavoriteType = "Special")
			GuiControl, ChooseString, f_drpSpecial, % g_objSpecialFolders[g_objEditedFavorite.FavoriteLocation].DefaultName
		else ; QAP
			GuiControl, ChooseString, f_drpQAP, % g_objQAPFeatures[g_objEditedFavorite.FavoriteLocation].DefaultName
}

if (g_objEditedFavorite.FavoriteType = "FTP")
{
	Gui, 2:Add, Text, x20 y+10, %lGuiLoginName%
	Gui, 2:Add, Edit, x20 y+10 w300 h20 vf_strFavoriteLoginName, % g_objEditedFavorite.FavoriteLoginName

	Gui, 2:Add, Text, x20 y+10, %lGuiPassword%
	Gui, 2:Add, Edit, x20 y+10 w300 h20 vf_strFavoritePassword, % g_objEditedFavorite.FavoritePassword
}

if (g_objEditedFavorite.FavoriteType = "Group")
{
	Gui, 2:Add, Text, x20 y+20, %lGuiGroupSaveRestoreOption%
	Gui, 2:Add, Radio, % "x20 y+10 vf_blnRadioGroupAdd " . (arrGroupSettings1 ? "" : "checked"), %lGuiGroupSaveAddWindowsLabel%
	Gui, 2:Add, Radio, % "x20 y+5 vf_blnRadioGroupReplace " . (arrGroupSettings1 ? "checked" : ""), %lGuiGroupSaveReplaceWindowsLabel%
}

; ------ TAB Menu Options ------

Gui, 2:Tab, % ++intTabNumber

Gui, 2:Add, Text, x20 y40 vf_lblFavoriteParentMenu
	, % (g_objEditedFavorite.FavoriteType = "Menu" ? lDialogSubmenuParentMenu : lDialogFavoriteParentMenu)
Gui, 2:Add, DropDownList, x20 y+5 w300 vf_drpParentMenu gDropdownParentMenuChanged
	, % RecursiveBuildMenuTreeDropDown(g_objMainMenu, g_objMenuInGui.MenuPath, (g_objEditedFavorite.FavoriteType = "Menu" ? lMainMenuName . " " . g_objEditedFavorite.FavoriteLocation : "")) . "|"

Gui, 2:Add, Text, x20 y+10 vf_lblFavoriteParentMenuPosition, %lDialogFavoriteMenuPosition%
Gui, 2:Add, DropDownList, x20 y+5 w290 vf_drpParentMenuItems AltSubmit

Gui, 2:Add, Text, x20 y+20 gGuiPickIconDialog section, %lDialogIcon%
Gui, 2:Add, Picture, x20 y+5 w32 h32 vf_picIcon gGuiPickIconDialog
Gui, 2:Add, Text, x+5 yp vf_lblRemoveIcon gGuiRemoveIcon, X
Gui, 2:Add, Link, x20 ys+57 gGuiPickIconDialog, <a>%lDialogSelectIcon%</a>

g_strNewFavoriteHotkey := g_objEditedFavorite.FavoriteHotkey
SplitHotkey(g_strNewFavoriteHotkey, strHotkeyModifiers, strHotkeyKey, strHotkeyMouse, strMouseButtonsWithDefault)
Gui, 2:Add, Text, x20 y+20, %lDialogShortcut%
Gui, 2:Add, Text, x20 y+5 w280 h23 0x1000 vf_strHotkeyText gButtonChangeFavoriteHotkey, % Hotkey2Text(strHotkeyModifiers, strHotkeyMouse, strHotkeyKey)
Gui, 2:Add, Button, yp x+10 gButtonChangeFavoriteHotkey, %lOptionsChangeHotkey%

; ------ TAB Window Options ------

if InStr("Folder|Special", g_objEditedFavorite.FavoriteType)
{
	Gui, 2:Tab, % ++intTabNumber

	;  0 for use default / 1 for remember, -1 Minimized / 0 Normal / 1 Maximized, Left (X), Top (Y), Width, Height; for example: "1,0,100,50,640,480"
	StringSplit, arrNewFavoriteWindowPosition, g_strNewFavoriteWindowPosition, `,

	Gui, 2:Add, Checkbox, % "x20 y40 section vf_chkRememberWindowPosition gCheckboxWindowPositionClicked " . (arrNewFavoriteWindowPosition1 ? "checked" : ""), %lDialogRememberWindowPosition%
	
	Gui, 2:Add, Text, % "y+20 x20 section vf_lblWindowPositionState " . (arrNewFavoriteWindowPosition1 ? "" : "hidden"), %lDialogState%
	
	Gui, 2:Add, Radio, % "y+10 x20 vf_lblWindowPositionMinMax1 gRadioButtonWindowPositionMinMaxClicked" 
		. (arrNewFavoriteWindowPosition1 ? "" : " hidden") . (!arrNewFavoriteWindowPosition2 ? " checked" : ""), %lDialogNormal%
	Gui, 2:Add, Radio, % "y+10 x20 vf_lblWindowPositionMinMax2 gRadioButtonWindowPositionMinMaxClicked"
		. (arrNewFavoriteWindowPosition1 ? "" : " hidden") . (arrNewFavoriteWindowPosition2 = 1 ? " checked" : ""), %lDialogMaximized%
	Gui, 2:Add, Radio, % "y+10 x20 vf_lblWindowPositionMinMax3 gRadioButtonWindowPositionMinMaxClicked"
		. (arrNewFavoriteWindowPosition1 ? "" : " hidden") . (arrNewFavoriteWindowPosition2 = -1 ? " checked" : ""), %lDialogMinimized%

	Gui, 2:Add, Text, % "ys x200 section vf_lblWindowPosition " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %lDialogWindowPosition%

	Gui, 2:Add, Text, % "ys+20 xs vf_lblWindowPositionX " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %lDialogWindowPositionX%
	Gui, 2:Add, Text, % "ys+40 xs vf_lblWindowPositionY " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %lDialogWindowPositionY%
	Gui, 2:Add, Text, % "ys+60 xs vf_lblWindowPositionW " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %lDialogWindowPositionW%
	Gui, 2:Add, Text, % "ys+80 xs vf_lblWindowPositionH " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %lDialogWindowPositionH%
	
	Gui, 2:Add, Edit, % "ys+20 xs+72 w36 h17 vf_intWindowPositionX center number limit5 " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %arrNewFavoriteWindowPosition3%
	Gui, 2:Add, Edit, % "ys+40 xs+72 w36 h17 vf_intWindowPositionY center number limit5 " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %arrNewFavoriteWindowPosition4%
	Gui, 2:Add, Edit, % "ys+60 xs+72 w36 h17 vf_intWindowPositionW center number limit5 " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %arrNewFavoriteWindowPosition5%
	Gui, 2:Add, Edit, % "ys+80 xs+72 w36 h17 vf_intWindowPositionH center number limit5 " . (arrNewFavoriteWindowPosition1 and arrNewFavoriteWindowPosition2 = 0 ? "" : "hidden"), %arrNewFavoriteWindowPosition6%
}

; ------ TAB Advanced Settings ------

if InStr("Folder|Document|Application|Special|URL|FTP|Group", g_objEditedFavorite.FavoriteType)
{
	Gui, 2:Tab, % ++intTabNumber

	Gui, 2:Add, Checkbox, x20 y40 vf_blnUseDefaultSettings gCheckboxUseDefaultSettingsClicked, %lDialogUseDefaultSettings%

	blnShowAdvancedSettings := StrLen(g_objEditedFavorite.FavoriteAppWorkingDir . arrGroupSettings2 . arrGroupSettings3 . g_objEditedFavorite.FavoriteLaunchWith . g_objEditedFavorite.FavoriteArguments)
	GuiControl, , f_blnUseDefaultSettings, % !blnShowAdvancedSettings

	if (g_objEditedFavorite.FavoriteType = "Application")
	{
		Gui, 2:Add, Text, x20 y+20 w300 vf_AdvancedSettingsLabel1, %lDialogWorkingDirLabel%
		Gui, 2:Add, Edit, x20 y+5 w300 Limit250 vf_strFavoriteAppWorkingDir, % g_objEditedFavorite.FavoriteAppWorkingDir
		Gui, 2:Add, Button, x+10 yp vf_AdvancedSettingsButton1 gButtonSelectWorkingDir, %lDialogBrowseButton%
	}
	else if (g_objEditedFavorite.FavoriteType = "Group")
	{
		Gui, 2:Add, Text, x20 y+20 vf_AdvancedSettingsLabel2, %lGuiGroupRestoreDelay%
		Gui, 2:Add, Edit, x20 y+5 w50 center number Limit4 vf_intGroupRestoreDelay, %arrGroupSettings2%
		Gui, 2:Add, Text, x+10 yp vf_AdvancedSettingsLabel3, %lGuiGroupRestoreDelayMilliseconds%

		Gui, 2:Add, Text, x20 y+20 vf_AdvancedSettingsLabel4, %lGuiGroupExplorerDelay%
		Gui, 2:Add, Edit, x20 y+5 w50 center number Limit4 vf_intGroupExplorerDelay, %arrGroupSettings3%
		Gui, 2:Add, Text, x+10 yp vf_AdvancedSettingsLabel5, %lGuiGroupRestoreDelayMilliseconds%
	}
	else
	{
		Gui, 2:Add, Text, x20 y+20 w300 vf_AdvancedSettingsLabel6, %lDialogLaunchWith%
		Gui, 2:Add, Edit, x20 y+5 w300 Limit250 vf_strFavoriteLaunchWith, % g_objEditedFavorite.FavoriteLaunchWith
		Gui, 2:Add, Button, x+10 yp vf_AdvancedSettingsButton2 gButtonSelectLaunchWith, %lDialogBrowseButton%
	}

	if (g_objEditedFavorite.FavoriteType <> "Group")
	{
		Gui, 2:Add, Text, y+20 x20 w300 vf_AdvancedSettingsLabel7, %lDialogArgumentsLabel%
		Gui, 2:Add, Edit, x20 y+5 w300 Limit250 vf_strFavoriteArguments, % g_objEditedFavorite.FavoriteArguments
		Gui, 2:Add, Text, x20 y+5 w300 vf_AdvancedSettingsLabel8, %lDialogArgumentsPlaceholder%
	}

	Gosub, CheckboxUseDefaultSettingsClicked ; init controls hidden
}

; ------ TAB End ------

Gui, 2:Tab

; ------ TAB End ------

if (A_ThisLabel = "GuiEditFavorite")
{
	Gui, 2:Add, Button, y420 vf_btnEditFavoriteSave gGuiEditFavoriteSave default, %lDialogSave%
	Gui, 2:Add, Button, yp vf_btnEditFavoriteCancel gGuiEditFavoriteCancel, %lGuiCancel%
	
	GuiCenterButtons(L(lDialogAddEditFavoriteTitle, lDialogEdit, g_strAppNameText, g_strAppVersion, g_objEditedFavorite.FavoriteType), 10, 5, 20, "f_btnEditFavoriteSave", "f_btnEditFavoriteCancel")
}
else
{
	Gui, 2:Add, Button, y400 vf_btnAddFavoriteAdd gGuiAddFavoriteSave default, %lDialogAdd%
	Gui, 2:Add, Button, yp vf_btnAddFavoriteCancel gGuiAddFavoriteCancel, %lGuiCancel%
	
	GuiCenterButtons(L(lDialogAddEditFavoriteTitle, lDialogAdd, g_strAppNameText, g_strAppVersion, g_objEditedFavorite.FavoriteType), 10, 5, 20, "f_btnAddFavoriteAdd", "f_btnAddFavoriteCancel")
}

if InStr("Folder|Document|Application", g_objEditedFavorite.FavoriteType)
	GuiControl, 2:+Default, f_btnSelectFolderLocation
else
	GuiControl, 2:+Default, f_btnAddFavoriteAdd

if InStr("Special|QAP", g_objEditedFavorite.FavoriteType)
	GuiControl, 2:Focus, % "f_drp" . g_objEditedFavorite.FavoriteType
else
{
	GuiControl, 2:Focus, f_strFavoriteShortName
	if (A_ThisLabel = "GuiEditFavorite") 
		SendInput, ^a
}

Gosub, DropdownParentMenuChanged ; to init the content of menu items

Gui, 2:Add, Text
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

g_strNewLocation := ""
arrTop := ""
strHotkeyModifiers := ""
strHotkeyMouse := ""
strHotkeyKey := ""
arrNewFavoriteWindowPosition := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
BuildTabsList(strFavoriteType)
;------------------------------------------------------------
{
	global

	; 1 Basic Settings, 2 Menu Options, 3 Window Options, 4 Advanced Settings
	strTabsList := g_arrFavoriteGuiTabs1 . " | " . g_arrFavoriteGuiTabs2
	
	if InStr("Folder|Special", strFavoriteType)
		strTabsList .= " | " . g_arrFavoriteGuiTabs3
	if InStr("Folder|Document|Application|Special|URL|FTP|Group", strFavoriteType)
		strTabsList .= " | " . g_arrFavoriteGuiTabs4
	
	strTabsList .= " "
	
	return strTabsList
}
;------------------------------------------------------------


;------------------------------------------------------------
GuiMoveMultipleFavoritesToMenu:
;------------------------------------------------------------

Gui, 2:New, , % L(lDialogMoveFavoritesTitle, g_strAppNameText, g_strAppVersion)
Gui, 2:Add, Text, % x10 y10 vf_lblFavoriteParentMenu, % L(lDialogFavoritesParentMenuMove, g_intFavoriteSelected)
Gui, 2:Add, DropDownList, x10 w300 vf_drpParentMenu gDropdownParentMenuChanged, % RecursiveBuildMenuTreeDropDown(g_objMainMenu, g_objMenuInGui.MenuPath)

Gui, 2:Add, Text, x20 y+10 vf_lblFavoriteParentMenuPosition, %lDialogFavoriteMenuPosition%
Gui, 2:Add, DropDownList, x20 y+5 w290 vf_drpParentMenuItems AltSubmit

Gui, 2:Add, Button, y+20 vf_btnMoveFavoritesSave gGuiMoveMultipleFavoritesSave, %lGuiMove%
Gui, 2:Add, Button, yp vf_btnMoveFavoritesCancel gGuiEditFavoriteCancel, %lGuiCancel%
GuiCenterButtons(L(lDialogMoveFavoritesTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnMoveFavoritesSave", "f_btnMoveFavoritesCancel")

Gosub, DropdownParentMenuChanged ; to init the content of menu items

GuiControl, 2:Focus, f_drpParentMenu
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonChangeFavoriteHotkey:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

g_strNewFavoriteHotkey := SelectHotkey(g_strNewFavoriteHotkey, f_strFavoriteShortName, g_objEditedFavorite.FavoriteType, f_strFavoriteLocation, 3)

SplitHotkey(g_strNewFavoriteHotkey, strNewModifiers, strNewKey, strNewMouse, strNewMouseButtonsWithDefault)
GuiControl, 2:, f_strHotkeyText, % Hotkey2Text(strNewModifiers, strNewMouse, strNewKey)

strNewModifiers := ""
strNewMouse := ""
strNewOptionsKey := ""
strNewMouseButtonsWithDefault := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
CheckboxUseDefaultSettingsClicked:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

strAdvancedSettingsControls := "f_strFavoriteAppWorkingDir|f_AdvancedSettingsButton1|f_intGroupRestoreDelay|f_intGroupExplorerDelay|f_strFavoriteLaunchWith|f_AdvancedSettingsButton2|f_strFavoriteArguments"

Loop, Parse, strAdvancedSettingsControls, |
	GuiControl, % (f_blnUseDefaultSettings ? "Hide" : "Show"), %A_LoopField%

Loop, 8
	GuiControl, % (f_blnUseDefaultSettings ? "Hide" : "Show"), f_AdvancedSettingsLabel%A_Index%

strAdvancedSettingsControls := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavoriteTabChanged:
;------------------------------------------------------------

if (f_intAddFavoriteTab = 1) ; if last tab was 1 we need to update the icon
{
	Gui, 2:Submit, NoHide

	Gosub, GuiFavoriteIconDefault
	Gosub, GuiFavoriteIconDisplay
}

return
;------------------------------------------------------------


;------------------------------------------------------------
DropdownParentMenuChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

strDropdownParentMenuItems := ""

Loop, % g_objMenusIndex[f_drpParentMenu].MaxIndex()
{
	if (g_objMenusIndex[f_drpParentMenu][A_Index].FavoriteType = "B") ; skip ".." back link to parent menu
		or (g_objEditedFavorite.FavoriteName = g_objMenusIndex[f_drpParentMenu][A_Index].FavoriteName)
			and (g_objMenuInGui.MenuPath = g_objMenusIndex[f_drpParentMenu].MenuPath) ; skip edited item itself
		Continue
	else if (g_objMenusIndex[f_drpParentMenu][A_Index].FavoriteType = "X")
		strDropdownParentMenuItems .= g_strGuiMenuSeparator . g_strGuiMenuSeparator . "|"
	else if (g_objMenusIndex[f_drpParentMenu][A_Index].FavoriteType = "K")
		strDropdownParentMenuItems .= g_strGuiMenuColumnBreak . " " . lMenuColumnBreak . " " . g_strGuiMenuColumnBreak . "|"
	else
		strDropdownParentMenuItems .= g_objMenusIndex[f_drpParentMenu][A_Index].FavoriteName . "|"
}

GuiControl, , f_drpParentMenuItems, % "|" . strDropdownParentMenuItems . g_strGuiMenuColumnBreak . " " . lDialogEndOfMenu . " " . g_strGuiMenuColumnBreak
if (f_drpParentMenu = g_objMenuInGui.MenuPath) and (g_intOriginalMenuPosition <> 0xFFFF)
	GuiControl, Choose, f_drpParentMenuItems, % g_intOriginalMenuPosition - (g_objMenusIndex[f_drpParentMenu][1].FavoriteType = "B" ? 1 : 0)
else
	GuiControl, ChooseString, f_drpParentMenuItems, % g_strGuiMenuColumnBreak . " " . lDialogEndOfMenu . " " . g_strGuiMenuColumnBreak

return
;------------------------------------------------------------


;------------------------------------------------------------
DropdownRunningApplicationChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, , f_strFavoriteLocation, %f_drpRunningApplication%

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiOpenThisMenu:
;------------------------------------------------------------
Gosub, 2GuiClose

Gui, 1:Default
GuiControl, 1:Focus, f_lvFavoritesList
Gui, 1:ListView, f_lvFavoritesList

Gosub, OpenMenuFromEditForm

return
;------------------------------------------------------------


;------------------------------------------------------------
DropdownSpecialChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, , f_strFavoriteShortName, %f_drpSpecial%
GuiControl, , f_strFavoriteLocation, % g_objClassIdOrPathByDefaultName[f_drpSpecial]

g_strNewFavoriteIconResource := g_objSpecialFolders[g_objClassIdOrPathByDefaultName[f_drpSpecial]].DefaultIcon
g_strDefaultIconResource := g_strNewFavoriteIconResource 

return
;------------------------------------------------------------


;------------------------------------------------------------
DropdownQAPChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, , f_strFavoriteShortName, %f_drpQAP%
GuiControl, , f_strFavoriteLocation, % g_objQAPFeaturesCodeByDefaultName[f_drpQAP]

g_strNewFavoriteIconResource := g_objQAPFeatures[g_objQAPFeaturesCodeByDefaultName[f_drpQAP]].DefaultIcon
g_strDefaultIconResource := g_strNewFavoriteIconResource 

return
;------------------------------------------------------------


;------------------------------------------------------------
EditFavoriteLocationChanged:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

if InStr("Document|Application", g_objEditedFavorite.FavoriteType)
	g_strNewFavoriteIconResource := ""

if !StrLen(f_strFavoriteShortName)
	GuiControl, 2:, f_strFavoriteShortName, % GetDeepestFolderName(f_strFavoriteLocation)

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonSelectFavoriteLocation:
ButtonSelectWorkingDir:
ButtonSelectLaunchWith:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

if (A_ThisLabel = "ButtonSelectFavoriteLocation")
{
	strDefault := f_strFavoriteLocation
	strType := (g_objEditedFavorite.FavoriteType = "Folder" ? "Folder" : "File")
}
else if (A_ThisLabel = "ButtonSelectWorkingDir")
{
	strDefault := f_strFavoriteAppWorkingDir
	strType := "Folder"
}
else ; ButtonSelectLaunchWith
{
	strDefault := f_strFavoriteLaunchWith
	strType := "File"
}

if (strType = "Folder")
	FileSelectFolder, strNewLocation, *%strDefault%, 3, %lDialogAddFolderSelect%
else ; File
	FileSelectFile, strNewLocation, S3, %strDefault%, %lDialogAddFileSelect%

if !(StrLen(strNewLocation))
	return

if (A_ThisLabel = "ButtonSelectWorkingDir")
	GuiControl, 2:, f_strFavoriteAppWorkingDir, %strNewLocation%
else if (A_ThisLabel = "ButtonSelectLaunchWith")
	GuiControl, 2:, f_strFavoriteLaunchWith, %strNewLocation%
else
{
	GuiControl, 2:, f_strFavoriteLocation, %strNewLocation%
	if !StrLen(f_strFavoriteShortName)
		GuiControl, 2:, f_strFavoriteShortName, % GetDeepestFolderName(strNewLocation)
}

strNewLocation := ""
strDefault := ""
strType := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiPickIconDialog:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

if InStr("Document|Application", g_objEditedFavorite.FavoriteType) and !StrLen(f_strFavoriteLocation)
{
	Oops(lPickIconNoLocation)
	return
}

; Source: http://ahkscript.org/boards/viewtopic.php?f=5&t=5108#p29970
VarSetCapacity(strThisIconFile, 1024) ; must be placed before strNewIconFile is initialized because VarSetCapacity erase its content
ParseIconResource(g_strNewFavoriteIconResource, strThisIconFile, intThisIconIndex)

WinGet, hWnd, ID, A
if (intThisIconIndex >= 0) ; adjust index for positive index only (not for negative index)
	intThisIconIndex := intThisIconIndex - 1
DllCall("shell32\PickIconDlg", "Uint", hWnd, "str", strThisIconFile, "Uint", 260, "intP", intThisIconIndex)
if (intThisIconIndex >= 0) ; adjust index for positive index only (not for negative index)
	intThisIconIndex := intThisIconIndex + 1

if StrLen(strThisIconFile)
	g_strNewFavoriteIconResource := strThisIconFile . "," . intThisIconIndex

Gosub, GuiFavoriteIconDisplay

strThisIconFile := ""
intThisIconIndex := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiRemoveIcon:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

g_strNewFavoriteIconResource := ""
Gosub, GuiFavoriteIconDefault

Gosub, GuiFavoriteIconDisplay

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiFavoriteIconDefault:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

if (g_objEditedFavorite.FavoriteType = "Menu")
	; default submenu icon
	g_strDefaultIconResource := g_objIconsFile["iconSubmenu"] . "," . g_objIconsIndex["iconSubmenu"]
else if (g_objEditedFavorite.FavoriteType = "Group")
	; default group icon
	g_strDefaultIconResource := g_objIconsFile["iconGroup"] . "," . g_objIconsIndex["iconGroup"]
else if (g_objEditedFavorite.FavoriteType = "Folder")
	; default folder icon
	g_strDefaultIconResource := g_objIconsFile["iconFolder"] . "," . g_objIconsIndex["iconFolder"]
else if (g_objEditedFavorite.FavoriteType = "URL")
{
	; default browser icon
	GetIcon4Location(g_strTempDir . "\default_browser_icon.html", strThisIconFile, intThisIconIndex)
	g_strDefaultIconResource := strThisIconFile . "," . intThisIconIndex
}
else if (g_objEditedFavorite.FavoriteType = "FTP")
{
	; default FTP icon
	g_strDefaultIconResource := g_objIconsFile["iconFTP"] . "," . g_objIconsIndex["iconFTP"]
}
else if InStr("Document|Application", g_objEditedFavorite.FavoriteType) and StrLen(f_strFavoriteLocation)
{
	; default icon for the selected file in add/edit favorite
	GetIcon4Location(f_strFavoriteLocation, strThisIconFile, intThisIconIndex, blnRadioApplication)
	g_strDefaultIconResource := strThisIconFile . "," . intThisIconIndex
}
else if (g_objEditedFavorite.FavoriteType = "Special")
	g_strDefaultIconResource := g_objSpecialFolders[g_objEditedFavorite.FavoriteLocation].DefaultIcon
else if (g_objEditedFavorite.FavoriteType = "QAP")
	g_strDefaultIconResource := g_objQAPFeatures[g_objEditedFavorite.FavoriteLocation].DefaultIcon
else ; should not
	g_strDefaultIconResource := g_objIconsFile["iconUnknown"] . "," . g_objIconsIndex["iconUnknown"]

if !StrLen(g_strNewFavoriteIconResource) or (g_strNewFavoriteIconResource = g_objIconsFile["iconUnknown"] . "," . g_objIconsIndex["iconUnknown"])
	g_strNewFavoriteIconResource := g_strDefaultIconResource

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiFavoriteIconDisplay:
;------------------------------------------------------------

strExpandedRessourceIcon := EnvVars(g_strNewFavoriteIconResource)
ParseIconResource(strExpandedRessourceIcon, strThisIconFile, intThisIconIndex)
GuiControl, , f_picIcon, *icon%intThisIconIndex% %strThisIconFile%
GuiControl, % (strExpandedRessourceIcon <> EnvVars(g_strDefaultIconResource) ? "Show" : "Hide"), f_lblRemoveIcon

strExpandedRessourceIcon := ""
strThisIconFile := ""
intThisIconIndex := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
CheckboxWindowPositionClicked:
RadioButtonWindowPositionMinMaxClicked:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

GuiControl, % (f_chkRememberWindowPosition ? "Show" : "Hide"), f_lblWindowPositionState
GuiControl, % (f_chkRememberWindowPosition ? "Show" : "Hide"), f_lblWindowPositionMinMax1
GuiControl, % (f_chkRememberWindowPosition ? "Show" : "Hide"), f_lblWindowPositionMinMax2
GuiControl, % (f_chkRememberWindowPosition ? "Show" : "Hide"), f_lblWindowPositionMinMax3

GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_lblWindowPosition
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_lblWindowPositionX
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_intWindowPositionX
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_lblWindowPositionY
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_intWindowPositionY
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_lblWindowPositionW
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_intWindowPositionW
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_lblWindowPositionH
GuiControl, % (f_chkRememberWindowPosition and f_lblWindowPositionMinMax1 ? "Show" : "Hide"), f_intWindowPositionH

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiMoveMultipleFavoritesSave:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

if (f_drpParentMenu = g_objMenuInGui.MenuPath)
	return

Gui, 1:Default
Gui, ListView, f_lvFavoritesList
g_intOriginalMenuPosition := 0

Loop
{
	g_intOriginalMenuPosition := LV_GetNext(g_intOriginalMenuPosition)
	if (!g_intOriginalMenuPosition)
        break
	if (g_objMenuInGui[g_intOriginalMenuPosition].FavoriteType = "B") ; skip back menu
		continue
	g_objEditedFavorite := g_objMenuInGui[g_intOriginalMenuPosition]
	
	Gosub, GuiMoveOneFavoriteSave
	g_intOriginalMenuPosition -=  1 ; because GuiMoveOneFavoriteSave deleted the previous item
}

g_intNewItemPos := "" ; make it fresh for next use (multiple move or not)

Gosub, BuildMainMenuWithStatus ; update menus
Gosub, GuiEditFavoriteCancel

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavoriteSave:
GuiEditFavoriteSave:
GuiMoveOneFavoriteSave:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

; original and destination menus values

if (A_ThisLabel = "GuiAddFavoriteSave")
{
	strOriginalMenu := ""
	g_intOriginalMenuPosition := 0
}
else ; GuiEditFavoriteSave or GuiMoveOneFavoriteSave
	strOriginalMenu := g_objMenuInGui.MenuPath

; f_drpParentMenu and f_drpParentMenuItems have same field name in 2 gui: GuiAddFavorite and GuiMoveMultipleFavoritesToMenu
strDestinationMenu := f_drpParentMenu
if (!f_drpParentMenuItems) ; ### because once I got a menu item inserted before the back link - unable to reproduce - remove after debugging
	###_D("f_drpParentMenuItems = 0. Not supposed...")
if (!g_intNewItemPos) ; if in GuiMoveOneFavoriteSave g_intNewItemPos may be already set
	g_intNewItemPos := f_drpParentMenuItems + (g_objMenusIndex[strDestinationMenu][1].FavoriteType = "B" ? 1 : 0)

; validation to avoid unauthorized favorite types in groups
if (g_objMenusIndex[strDestinationMenu].MenuType = "Group" and InStr("QAP|Menu|Group", g_objEditedFavorite.FavoriteType))
{
	Oops(lDialogFavoriteNameNotAllowed, ReplaceAllInString(g_objFavoriteTypesLabels[g_objEditedFavorite.FavoriteType], "&", ""), lDialogFavoriteParentMenu)
	if (A_ThisLabel = "GuiMoveOneFavoriteSave")
		g_intOriginalMenuPosition++
	return
}
/*
###_D("g_objEditedFavorite.FavoriteType: " . g_objEditedFavorite.FavoriteType 
	. "`ng_objMenusIndex[strDestinationMenu].MenuPath: " . g_objMenusIndex[strDestinationMenu].MenuPath 
	. "`ng_objMenusIndex[strDestinationMenu].MenuType: " . g_objMenusIndex[strDestinationMenu].MenuType)
*/

; validation (not required for GuiMoveOneFavoriteSave because info in g_objEditedFavorite is not changed)

if (A_ThisLabel <> "GuiMoveOneFavoriteSave")
{
	if !StrLen(f_strFavoriteShortName)
	{
		Oops(g_objEditedFavorite.FavoriteType = "Menu" ? lDialogSubmenuNameEmpty : lDialogFavoriteNameEmpty)
		return
	}

	if IsColumnBreak(f_strFavoriteShortName)
	{
		Oops(L(lDialogFavoriteNameNoColumnBreak, g_strGuiMenuColumnBreak))
		return
	}

	if  InStr("Folder|Document|Application|URL|FTP", g_objEditedFavorite.FavoriteType) and !StrLen(f_strFavoriteLocation)
	{
		Oops(lDialogFavoriteLocationEmpty)
		return
	}

	if  InStr("Special|QAP", g_objEditedFavorite.FavoriteType) and !StrLen(f_strFavoriteLocation)
	{
		Oops(lDialogFavoriteDropdownEmpty, ReplaceAllInString(g_objFavoriteTypesLabels[g_objEditedFavorite.FavoriteType], "&", ""))
		return
	}

	if InStr("Menu|Group", g_objEditedFavorite.FavoriteType)
		and InStr(f_strFavoriteShortName, g_strMenuPathSeparator) or InStr(f_strFavoriteShortName, g_strGroupPathSeparator)
	{
		Oops(L(lDialogFavoriteNameNoSeparator, g_strMenuPathSeparator, g_strGroupPathSeparator))
		return
	}

	strNewFavoriteWindowPosition := f_chkRememberWindowPosition
	if (f_chkRememberWindowPosition)
		strNewFavoriteWindowPosition .= "," . (f_lblWindowPositionMinMax1 ? 0 : (f_lblWindowPositionMinMax2 ? 1 : -1))
			. "," . f_intWindowPositionX . "," . f_intWindowPositionY . "," . f_intWindowPositionW . "," . f_intWindowPositionH
	if !ValidateWindowPosition(strNewFavoriteWindowPosition)
	{
		Oops(lOopsInvalidWindowPosition)
		return
	}
}

if !FolderNameIsNew((A_ThisLabel = "GuiMoveOneFavoriteSave" ? g_objEditedFavorite.FavoriteName : f_strFavoriteShortName), g_objMenusIndex[strDestinationMenu])
	and !InStr("X|K", g_objEditedFavorite.FavoriteType) ; same name OK for separators
	; we have the same name in the destination menu
	; if this is the same menu and the same name, this is OK
	if (strDestinationMenu <> strOriginalMenu) or (f_strFavoriteShortName <> g_objEditedFavorite.FavoriteName)
	{
		Oops(lDialogFavoriteNameNotNew, f_strFavoriteShortName)
		if (A_ThisLabel = "GuiMoveOneFavoriteSave")
			g_intOriginalMenuPosition++
		return
	}

if (InStr(strDestinationMenu, strOriginalMenu . " " . g_strMenuPathSeparator " " . g_objEditedFavorite.FavoriteName) = 1) ; = 1 to check if equal from start only
	and !InStr("K|X", g_objEditedFavorite.FavoriteType) ; no risk with separators
{
	Oops(lDialogMenuNotMoveUnderItself, g_objEditedFavorite.FavoriteName)
	g_intOriginalMenuPosition++ ; will be reduced by GuiMoveMultipleFavoritesSave
	return
}

; if adding menu or group, create submenu object

if (InStr("Menu|Group", g_objEditedFavorite.FavoriteType) and (A_ThisLabel = "GuiAddFavoriteSave"))
{
	objNewMenu := Object() ; object for the new menu or group
	objNewMenu.MenuPath := strDestinationMenu . " " . (g_objEditedFavorite.FavoriteType = "Menu" ? g_strMenuPathSeparator : g_strGroupPathSeparator) . " " . f_strFavoriteShortName
	objNewMenu.MenuType := g_objEditedFavorite.FavoriteType

	; create a navigation entry to navigate to the parent menu
	objNewMenuBack := Object()
	objNewMenuBack.FavoriteType := "B" ; for Back link to parent menu
	objNewMenuBack.FavoriteName := "(" . GetDeepestMenuPath(strDestinationMenu) . ")"
	objNewMenuBack.SubMenu := g_objMenusIndex[strDestinationMenu] ; this is the link to the parent menu
	objNewMenu.Insert(objNewMenuBack)
	
	g_objMenusIndex.Insert(objNewMenu.MenuPath, objNewMenu)
	g_objEditedFavorite.Submenu := objNewMenu
}

; update menu object except if we move favorites

if (A_ThisLabel <> "GuiMoveOneFavoriteSave")
{
	g_objEditedFavorite.FavoriteName := f_strFavoriteShortName
	if InStr("Menu|Group", g_objEditedFavorite.FavoriteType)
	{
		strMenuLocation := strDestinationMenu . " " . (g_objEditedFavorite.FavoriteType = "Menu" ? g_strMenuPathSeparator : g_strGroupPathSeparator) . " " . f_strFavoriteShortName
		RecursiveUpdateMenuPath(g_objEditedFavorite.Submenu, strMenuLocation)
		
		StringReplace, strMenuLocation, strMenuLocation, %lMainMenuName%%A_Space% ; menu path without main menu localized name
		g_objEditedFavorite.FavoriteLocation := strMenuLocation
	}
	else
		g_objEditedFavorite.FavoriteLocation := f_strFavoriteLocation
	
	g_objEditedFavorite.FavoriteIconResource := g_strNewFavoriteIconResource
	g_objEditedFavorite.FavoriteHotkey := g_strNewFavoriteHotkey
	g_objEditedFavorite.FavoriteWindowPosition := strNewFavoriteWindowPosition
	
	g_objEditedFavorite.FavoriteGroupSettings := f_blnRadioGroupReplace
	g_objEditedFavorite.FavoriteGroupSettings .= (f_blnUseDefaultSettings ? "" : "," . f_intGroupRestoreDelay . "," . f_intGroupExplorerDelay)
	
	g_objEditedFavorite.FavoriteLoginName := f_strFavoriteLoginName
	g_objEditedFavorite.FavoritePassword := f_strFavoritePassword
	
	g_objEditedFavorite.FavoriteArguments := (f_blnUseDefaultSettings ? "" : f_strFavoriteArguments)
	g_objEditedFavorite.FavoriteAppWorkingDir := (f_blnUseDefaultSettings ? "" : f_strFavoriteAppWorkingDir)
	g_objEditedFavorite.FavoriteLaunchWith := (f_blnUseDefaultSettings ? "" : f_strFavoriteLaunchWith)
}

; updating original and destination menu objects (these can be the same)

if (strOriginalMenu <> "") ; we are moving a favorite
	g_objMenusIndex[strOriginalMenu].Remove(g_intOriginalMenuPosition)
if (g_intNewItemPos)
	g_objMenusIndex[strDestinationMenu].Insert(g_intNewItemPos, g_objEditedFavorite)
else
	g_objMenusIndex[strDestinationMenu].Insert(g_objEditedFavorite) ; if no item is selected, add to the end of menu

/*
###_D(""
	. "g_intNewItemPos: " . g_intNewItemPos . "`n"
	. "g_objEditedFavorite.FavoriteType : " . g_objEditedFavorite.FavoriteType . "`n"
	. "g_objEditedFavorite.FavoriteName : " . g_objEditedFavorite.FavoriteName . "`n"
	. "g_objEditedFavorite.FavoriteLocation: " . g_objEditedFavorite.FavoriteLocation . "`n"
	. "g_objEditedFavorite.Submenu.MenuPath: " . g_objEditedFavorite.Submenu.MenuPath . "`n"
	. "g_objEditedFavorite.Submenu.MenuType: " . g_objEditedFavorite.Submenu.MenuType . "`n"
	. "`n"
	. "g_objEditedFavorite.Submenu[1].FavoriteName: " . g_objEditedFavorite.Submenu[1].FavoriteName . "`n"
	. "g_objEditedFavorite.Submenu[1].Submenu.MenuPath: " . g_objEditedFavorite.Submenu[1].Submenu.MenuPath . "`n"
	. "")
*/

; updating listview

Gosub, 2GuiClose

Gui, 1:Default
GuiControl, 1:Focus, lvFavoritesList
Gui, 1:ListView, lvFavoritesList

if (strOriginalMenu = g_objMenuInGui.MenuPath) ; remove original from Listview if original in Gui (can be replaced with modified)
	LV_Delete(g_intOriginalMenuPosition)

if (strDestinationMenu = g_objMenuInGui.MenuPath) ; add modified to Listview if destination in Gui (can replace original deleted)
{
	LV_Modify(0, "-Select")
	if (g_objEditedFavorite.FavoriteType = "Menu")
		strThisLocation := g_strMenuPathSeparator
	else if (g_objEditedFavorite.FavoriteType = "Group")
		strThisLocation := g_strGroupPathSeparator
	else
		strThisLocation := g_objEditedFavorite.FavoriteLocation
	
	if (g_intNewItemPos)
		LV_Insert(g_intNewItemPos, "Select Focus", g_objEditedFavorite.FavoriteName, g_objFavoriteTypesShortNames[g_objEditedFavorite.FavoriteType], strThisLocation)
	else
		LV_Add("Select Focus", g_objEditedFavorite.FavoriteName, g_objFavoriteTypesShortNames[g_objEditedFavorite.FavoriteName], strThisLocation)

	LV_Modify(LV_GetNext(), "Vis")
}

GuiControl, 1:, f_drpMenusList, % "|" . RecursiveBuildMenuTreeDropDown(g_objMainMenu, g_objMenuInGui.MenuPath) . "|" ; required if submenu was added
Gosub, AjustColumnWidth

if (A_ThisLabel <> "GuiMoveOneFavoriteSave")
	Gosub, BuildMainMenuWithStatus ; update menus

GuiControl, Enable, f_btnGuiSave
GuiControl, , f_btnGuiCancel, %lDialogCancelButton%

g_blnMenuReady := true

if (A_ThisLabel = "GuiMoveOneFavoriteSave")
	g_intNewItemPos++ ; move next favorite after this one in the destination menu (or will be deleted in GuiMoveOneFavoriteSave after the loop)
else
	g_intNewItemPos := "" ; delete it for next use

strOriginalMenu := ""
strDestinationMenu := ""
strMenuLocation := ""
strThisLocation := ""
strNewFavoriteWindowPosition := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
RecursiveUpdateMenuPath(objEditedMenu, strMenuPath)
;------------------------------------------------------------
{
	global g_strMenuPathSeparator
	global g_strGroupPathSeparator
	
	Loop, % objEditedMenu.MaxIndex()
	{
		objEditedMenu.MenuPath := strMenuPath ; update only path regardless .MenuType "Menu" or "Group"
		
		; skip ".." back link to parent menu
		if (objEditedMenu[A_Index].FavoriteType = "B")
			continue
		
		if InStr("Menu|Group", objEditedMenu[A_Index].FavoriteType)
			RecursiveUpdateMenuPath(objEditedMenu[A_Index].SubMenu
				, objEditedMenu.MenuPath . " " . (objEditedMenu[A_Index].FavoriteType = "Menu" ? g_strMenuPathSeparator : g_strGroupPathSeparator) . " " . objEditedMenu[A_Index].FavoriteName) ; RECURSIVE
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
ValidateWindowPosition(strPosition)
;------------------------------------------------------------
{
	StringSplit, arrPosition, strPosition, `,
	if !(arrPosition1) or (arrPosition2 <> 0) ; no position to validate
		return true
	
	if arrPosition3 is not integer
		blnOK := false
	else if arrPosition4 is not integer
		blnOK := false
	else if arrPosition5 is not integer
		blnOK := false
	else if arrPosition6 is not integer
		blnOK := false
	else
		blnOK := true

	if (blnOK)
		blnOK := (arrPosition3 > 0) and (arrPosition4 > 0) and (arrPosition5 > 0) and (arrPosition6 > 0)
	
	return blnOK
}
;------------------------------------------------------------


;------------------------------------------------------------
FolderNameIsNew(strCandidateName, objMenu)
;------------------------------------------------------------
{
	Loop, % objMenu.MaxIndex()
		if (strCandidateName = objMenu[A_Index].FavoriteName)
			return False

	return True
}
;------------------------------------------------------------


;------------------------------------------------------------
GuiRemoveMultipleFavorites:
;------------------------------------------------------------

GuiControl, Focus, f_lvFavoritesList
Gui, 1:ListView, f_lvFavoritesList

if (LV_GetNext() = 1 and g_objMenuInGui[1].FavoriteType = "B")
	LV_Modify(1, "-Select") ; deselect back link entry

if LV_GetCount("Selected") > 1
{
	MsgBox, 52, %g_strAppNameText%, % L(lDialogRemoveMultipleFavorites, LV_GetCount("Selected"))
	IfMsgBox, No
		return
}

Loop
	Gosub, GuiRemoveOneFavorite
until !LV_GetNext()

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiRemoveFavorite:
GuiRemoveOneFavorite:
;------------------------------------------------------------

GuiControl, Focus, f_lvFavoritesList
Gui, 1:ListView, f_lvFavoritesList
intItemToRemove := LV_GetNext()
if !(intItemToRemove)
{
	Oops(lDialogSelectItemToRemove)
	return
}
if (g_objMenuInGui[intItemToRemove].FavoriteType = "B")
	return

; remove favorite in object model (if menu, leaving submenu objects unlinked without releasing them)

blnItemIsMenu := (g_objMenuInGui[intItemToRemove].FavoriteType = "Menu")

if (blnItemIsMenu)
{
	MsgBox, 52, % L(lDialogFavoriteRemoveTitle, g_strAppNameText), % L(lDialogFavoriteRemovePrompt, g_objMenuInGui[intItemToRemove].Submenu.MenuPath)
	IfMsgBox, No
		return
	g_objMenusIndex.Remove(g_objMenuInGui[intItemToRemove].Submenu.MenuPath)
}
g_objMenuInGui.Remove(intItemToRemove)

; refresh menu dropdpown in gui

if (blnItemIsMenu)
	GuiControl, 1:, f_drpMenusList, % "|" . RecursiveBuildMenuTreeDropDown(g_objMainMenu, g_objMenuInGui.MenuPath) . "|"

; remove favorite in gui

LV_Delete(intItemToRemove)
if (A_ThisLabel = "GuiRemoveFavorite")
{
	LV_Modify(intItemToRemove, "Select Focus")
	if !LV_GetNext() ; if last item was deleted, select the new last item
		LV_Modify(LV_GetCount(), "Select Focus")
}
Gosub, AjustColumnWidth

GuiControl, Enable, f_btnGuiSave
GuiControl, , f_btnGuiCancel, %lGuiCancel%

intItemToRemove := ""
blnItemIsMenu := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddFavoriteCancel:
GuiEditFavoriteCancel:
;------------------------------------------------------------

Gosub, 2GuiClose

return
;------------------------------------------------------------


;------------------------------------------------------------
HotkeyChangeMenu:
;------------------------------------------------------------

Gui, 1:ListView, f_lvFavoritesList

g_intOriginalMenuPosition := LV_GetNext()

if (g_objMenuInGui[g_intOriginalMenuPosition].FavoriteType = "Menu")
	Gosub, OpenMenuFromGuiHotkey

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiMenusListChanged:
GuiGotoUpMenu:
GuiGotoPreviousMenu:
OpenMenuFromEditForm:
OpenMenuFromGuiHotkey:
;------------------------------------------------------------
intCurrentLastPosition := 0

if (A_ThisLabel = "GuiMenusListChanged")
{
	GuiControlGet, strNewDropdownMenu, , f_drpMenusList
	; ###_D("GuiMenusListChanged: " . strNewDropdownMenu . "`ng_objMenuInGui.MenuPath: " . g_objMenuInGui.MenuPath) 

	if (strNewDropdownMenu = g_objMenuInGui.MenuPath) ; user selected the current menu in the dropdown
		return
}

; ### not required if object updated Gosub, SaveCurrentListviewToMenuObject ; save current LV

/*
###_D(A_ThisLabel . "`n"
	. "intCurrentLastPosition: " . intCurrentLastPosition . "`n"
	. "g_intOriginalMenuPosition: " . g_intOriginalMenuPosition . "`n"
	. "strNewDropdownMenu: " . strNewDropdownMenu . "`n"
	. "g_objMenuInGui.MenuPath: " . g_objMenuInGui.MenuPath . "`n"
	. "g_objMenusIndex[strNewDropdownMenu].MenuPath: " . g_objMenusIndex[strNewDropdownMenu].MenuPath . "`n"
	. "g_objMenuInGui[1].SubMenu.MenuPath: " . g_objMenuInGui[1].SubMenu.MenuPath . "`n"
	. "g_objMenuInGui[g_intOriginalMenuPosition].SubMenu.MenuPath: " . g_objMenuInGui[g_intOriginalMenuPosition].SubMenu.MenuPath . "`n"
	. ": " . "`n"
	. "")
*/

if (A_ThisLabel = "GuiGotoPreviousMenu")
{
	g_objMenuInGui := g_objMenusIndex[g_arrSubmenuStack[1]] ; pull the top menu from the left arrow stack
	g_arrSubmenuStack.Remove(1) ; remove the top menu from the left arrow stack

	intCurrentLastPosition := g_arrSubmenuStackPosition[1] ; pull the focus position in top menu from the left arrow stack
	g_arrSubmenuStackPosition.Remove(1) ; remove the top position from the left arrow stack
}
else
{
	g_arrSubmenuStack.Insert(1, g_objMenuInGui.MenuPath) ; push the current menu to the left arrow stack
	
	if (A_ThisLabel = "GuiMenusListChanged")
		g_objMenuInGui := g_objMenusIndex[strNewDropdownMenu]
	else if (A_ThisLabel = "GuiGotoUpMenu")
		g_objMenuInGui := g_objMenuInGui[1].SubMenu
	else if (A_ThisLabel = "OpenMenuFromEditForm") or (A_ThisLabel = "OpenMenuFromGuiHotkey")
		g_objMenuInGui := g_objMenuInGui[g_intOriginalMenuPosition].SubMenu

	g_arrSubmenuStackPosition.Insert(1, LV_GetNext("Focused")) ; ### ???
}

GuiControl, % (g_arrSubmenuStack.MaxIndex() ? "Show" : "Hide"), f_picPreviousMenu
GuiControl, % (g_objMenuInGui.MenuPath <> lMainMenuName ? "Show" : "Hide"), f_picUpMenu

; ### if blnSaveEnabled load will abort - need to save before (where in FP?)
Gosub, LoadMenuInGui

if (intCurrentLastPosition) ; we went to a previous menu
{
	LV_Modify(0, "-Select")
	LV_Modify(intCurrentLastPosition, "Select Focus Vis")
}

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiMoveMultipleFavoritesUp:
GuiMoveMultipleFavoritesDown:
;------------------------------------------------------------

GuiControl, Focus, f_lvFavoritesList
Gui, 1:ListView, f_lvFavoritesList

g_blnAbortMultipleMove := false
strSelectedRows := ""
g_intRowToProcess := 0
loop
{
	g_intRowToProcess := LV_GetNext(g_intRowToProcess)
	strSelectedRows .= g_intRowToProcess . "|"
}
until !LV_GetNext(g_intRowToProcess)
StringTrimRight, strSelectedRows, strSelectedRows, 1

Loop
{
	Gosub, % (A_ThisLabel = "GuiMoveMultipleFavoritesUp" ? "GetFirstSelected" : "GetLastSelected") ; will re-init g_intRowToProcess
	if (!g_intRowToProcess) or (g_blnAbortMultipleMove)
		break
	
	g_intSelectedRow := g_intRowToProcess
	Gosub, % (A_ThisLabel = "GuiMoveMultipleFavoritesUp" ? "GuiMoveOneFavoriteUp" : "GuiMoveOneFavoriteDown")
}

if (!g_blnAbortMultipleMove)
	Loop, Parse, strSelectedRows, |
		LV_Modify(A_LoopField  + (A_ThisLabel = "GuiMoveMultipleFavoritesUp" ? -1 : 1), "Select")

LV_Modify(LV_GetNext(0), "Focus") ; give focus to the first selected row

g_blnAbortMultipleMove := ""
strSelectedRows := ""
g_intRowToProcess := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GetFirstSelected:
GetLastSelected:
;------------------------------------------------------------

g_intRowToProcess := 0

if (A_ThisLabel = "GetFirstSelected")
	g_intRowToProcess := LV_GetNext(g_intRowToProcess) ; start from first selected
else
	loop
		g_intRowToProcess := LV_GetNext(g_intRowToProcess) ; start with last selected
	until !LV_GetNext(g_intRowToProcess)

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiMoveFavoriteUp:
GuiMoveFavoriteDown:
GuiMoveOneFavoriteUp:
GuiMoveOneFavoriteDown:
;------------------------------------------------------------

if !InStr(A_ThisLabel, "One")
{
	GuiControl, Focus, f_lvFavoritesList
	Gui, 1:ListView, f_lvFavoritesList
	g_intSelectedRow := LV_GetNext()
}
if (g_intSelectedRow = 0)
{
	Oops(lDialogSelectItemToMove)
	return
}
if (g_intSelectedRow = (InStr(A_ThisLabel, "Up") ? (g_objMenuInGui[1].FavoriteType = "B" ? 2 : 1) ; if Up not higher that first non-back link favorite
	: LV_GetCount())) ; if Down not lower that last
	or (g_objMenuInGui[g_intSelectedRow].FavoriteType = "B") ; cannot move back link
{
	if InStr(A_ThisLabel, "One")
		g_blnAbortMultipleMove := true
	return
}

; --- move in menu object ---

; ###_D(list(g_objMenuInGui, g_intSelectedRow))
MoveFavoriteInMenuObject(g_objMenuInGui, g_intSelectedRow, (InStr(A_ThisLabel, "Up") ? -1 : 1))
; ###_D(list(g_objMenuInGui, g_intSelectedRow))

; --- move in Gui ---

Loop, 3
	LV_GetText(arrThis%A_Index%, g_intSelectedRow, A_Index)

Loop, 3
	LV_GetText(arrOther%A_Index%, g_intSelectedRow + (InStr(A_ThisLabel, "Up") ? -1 : 1), A_Index)

LV_Modify(g_intSelectedRow, "-Select")
LV_Modify(g_intSelectedRow, "", arrOther1, arrOther2, arrOther3)
LV_Modify(g_intSelectedRow + (InStr(A_ThisLabel, "Up") ? -1 : 1), , arrThis1, arrThis2, arrThis3)

if !InStr(A_ThisLabel, "One")
	LV_Modify(g_intSelectedRow + (InStr(A_ThisLabel, "Up") ? -1 : 1), "Select Focus Vis")

GuiControl, Enable, f_btnGuiSave
GuiControl, , f_btnGuiCancel, %lGuiCancel%

return

/*
list(objMenu, intPos)
{
	s := ""
	for key, val in objMenu
		s .= key . " " . val.FavoriteName . (key = intPos ? "!" : "") . "`n"
	return s
}
*/

;------------------------------------------------------------


;------------------------------------------------------------
MoveFavoriteInMenuObject(objMenu, intItem, intDirection)
; intDirection = +1 to to down or -1 to go up
;------------------------------------------------------------
{
	if (intItem + intDirection > objMenu.MaxIndex())
		or (intItem + intDirection < o.MinIndex())
		return

	objMenu.Insert(intItem + intDirection + (intDirection > 0 ? 1 : 0), objMenu[intItem])
	objMenu.Remove(intItem + (intDirection > 0 ? 0 : 1))
}	
;------------------------------------------------------------


;------------------------------------------------------------
GuiAddSeparator:
GuiAddColumnBreak:
;------------------------------------------------------------

GuiControl, Focus, f_lvFavoritesList
Gui, 1:ListView, f_lvFavoritesList

if (LV_GetCount("Selected") > 1)
	return

intInsertPosition := LV_GetCount() ? (LV_GetNext() ? LV_GetNext() : 0xFFFF) : 1

; --- ### add in menu object ---

; ###_D(list(g_objMenuInGui, g_intSelectedRow))
objNewFavorite := Object()
if (A_ThisLabel = "GuiAddSeparator")
{
	objNewFavorite.FavoriteType := "X"
	objNewFavorite.FavoriteName := ""
	objNewFavorite.FavoriteLocation := ""
}
else ; GuiAddColumnBreak
{
	objNewFavorite.FavoriteType := "K"
	objNewFavorite.FavoriteName := ""
	objNewFavorite.FavoriteLocation := ""
}
g_objMenuInGui.Insert(intInsertPosition, objNewFavorite)
; ###_D(list(g_objMenuInGui, g_intSelectedRow))

; --- add in Gui ---

LV_Modify(0, "-Select")

if (A_ThisLabel = "GuiAddSeparator")
	LV_Insert(intInsertPosition, "Select Focus", "---", g_strGuiMenuSeparator, g_strGuiMenuSeparator . g_strGuiMenuSeparator)
else ; GuiAddColumnBreak
	LV_Insert(intInsertPosition, "Select Focus", "===", g_strGuiMenuColumnBreak . " " . lMenuColumnBreak . " " . g_strGuiMenuColumnBreak
		, g_strGuiMenuColumnBreak . " " . lMenuColumnBreak . " " . g_strGuiMenuColumnBreak)

LV_Modify(LV_GetNext(), "Vis")
Gosub, AjustColumnWidth

GuiControl, Enable, f_btnGuiSave
GuiControl, , f_btnGuiCancel, %lGuiCancel%

intInsertPosition := ""
objNewFavorite := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiSave:
;------------------------------------------------------------

g_blnMenuReady := false

IniDelete, %g_strIniFile%, Favorites

g_intIniLine := 1 ; reset counter before saving to another ini file
RecursiveSaveFavoritesToIniFile(g_objMainMenu)

Gosub, LoadIniFile
Gosub, BuildMainMenuWithStatus
GuiControl, Disable, %lGuiSave%
GuiControl, , %lGuiCancel%, %lGuiClose%

Gosub, GuiCancel
g_blnMenuReady := true

g_intIniLine := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
RecursiveSaveFavoritesToIniFile(objCurrentMenu)
;------------------------------------------------------------
{
	global g_strIniFile
	global g_intIniLine
	global g_strEscapePipe
	
	Loop, % objCurrentMenu.MaxIndex()
	{
		; skip ".." back link to parent menu
		blnIsBackMenu := (objCurrentMenu[A_Index].FavoriteType = "B")
		if !(blnIsBackMenu)
		{
			strIniLine := objCurrentMenu[A_Index].FavoriteType . "|" ; 1
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteName, "|", g_strEscapePipe) . "|" ; 2
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteLocation, "|", g_strEscapePipe) . "|" ; 3
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteIconResource, "|", g_strEscapePipe) . "|" ; 4
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteArguments, "|", g_strEscapePipe) . "|" ; 5
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteAppWorkingDir, "|", g_strEscapePipe) . "|" ; 6
			strIniLine .= objCurrentMenu[A_Index].FavoriteWindowPosition . "|" ; 7
			strIniLine .= objCurrentMenu[A_Index].FavoriteHotkey . "|" ; 8
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteLaunchWith, "|", g_strEscapePipe) . "|" ; 9
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoriteLoginName, "|", g_strEscapePipe) . "|" ; 10
			strIniLine .= ReplaceAllInString(objCurrentMenu[A_Index].FavoritePassword, "|", g_strEscapePipe) . "|" ; 11
			strIniLine .= objCurrentMenu[A_Index].FavoriteGroupSettings . "|" ; 12

			IniWrite, %strIniLine%, %g_strIniFile%, Favorites, Favorite%g_intIniLine%
			g_intIniLine++
		}
		
		if InStr("Menu|Group", objCurrentMenu[A_Index].FavoriteType) and !(blnIsBackMenu)
		{
			; ###_D("Going down in: " . objCurrentMenu[A_Index].SubMenu.MenuPath)
			RecursiveSaveFavoritesToIniFile(objCurrentMenu[A_Index].SubMenu) ; RECURSIVE
			; ###_D("Going up back in: " . objCurrentMenu.MenuPath)
		}
	}
		
	IniWrite, Z, %g_strIniFile%, Favorites, Favorite%g_intIniLine% ; end of menu marker
	g_intIniLine++
	
	return
}
;------------------------------------------------------------


;------------------------------------------------------------
GuiShow:
;------------------------------------------------------------

; should not be required but safer
GuiControlGet, blnSaveEnabled, Enabled, %lGuiSave%
if (blnSaveEnabled)
	return

g_objMenuInGui := g_objMainMenu ; was g_strCurrentMenu := lMainMenuName
Gosub, BackupMenusObjects

; ### test Gosub, RestoreBackupMenusObjects
Gosub, LoadMenuInGui
Gui, 1:Show

return
;------------------------------------------------------------

;========================================================================================================================
; END OF FAVORITES LIST
;========================================================================================================================


;========================================================================================================================
!_035_GUI_CHANGE_HOTKEY:
return
;========================================================================================================================

; Gui in function, see from daniel2 http://www.autohotkey.com/board/topic/19880-help-making-gui-work-inside-a-function/#entry130557

;------------------------------------------------------------
SelectHotkey(strActualHotkey, strFavoriteName, strFavoriteType, strFavoriteLocation, intHotkeyType, strDefaultHotkey := "", strDescription := "")
; intHotkeyType: 1 Mouse, 2 Keyboard, 3 Mouse or Keyboard
; returns the new hotkey or empty string if cancel
;------------------------------------------------------------
{
	; safer that declaring individual variables (see "Common source of confusion" in https://www.autohotkey.com/docs/Functions.htm#Locals)
	global
	
	SplitHotkey(strActualHotkey, strActualModifiers, strActualKey, strActualMouseButton, strActualMouseButtonsWithDefault)

	intGui2WinID := WinExist("A")

	Gui, 3:New, , % L(lDialogChangeHotkeyTitle, g_strAppNameText, g_strAppVersion)
	Gui, 3:Default
	Gui, +Owner2
	Gui, +OwnDialogs
	
	if (g_blnUseColors)
		Gui, Color, %g_strGuiWindowColor%
	Gui, Font, s10 w700, Verdana
	Gui, Add, Text, x10 y10 w300 center, % L(lDialogChangeHotkeyTitle, g_strAppNameText)
	Gui, Font

	Gui, Add, Text, y+15 x10, %lDialogTriggerFor%
	Gui, Font, s8 w700
	Gui, Add, Text, x+5 yp w300 section, % strFavoriteName . (StrLen(strFavoriteType) ? " (" . strFavoriteType . ")" : "")
	Gui, Font
	if StrLen(strFavoriteLocation)
		Gui, Add, Text, xs y+5 w300, %strFavoriteLocation%
	if StrLen(strDescription)
		Gui, Add, Text, xs y+5 w300, %strDescription%

	Gui, Add, CheckBox, y+20 x50 vf_blnShift, %lDialogShift%
	GuiControlGet, arrTop, Pos, f_blnShift
	Gui, Add, CheckBox, y+10 x50 vf_blnCtrl, %lDialogCtrl%
	Gui, Add, CheckBox, y+10 x50 vf_blnAlt, %lDialogAlt%
	Gui, Add, CheckBox, y+10 x50 vf_blnWin, %lDialogWin%
	Gosub, SetModifiersCheckBox

	if (intHotkeyType = 1)
		Gui, Add, DropDownList, % "y" . arrTopY . " x150 w200 vf_drpHotkeyMouse gMouseChanged", %strActualMouseButtonsWithDefault%
	if (intHotkeyType = 3)
	{
		Gui, Add, Text, % "y" . arrTopY . " x150 w60", %lDialogMouse%
		Gui, Add, DropDownList, yp x+10 w200 vf_drpHotkeyMouse gMouseChanged, %strActualMouseButtonsWithDefault%
		Gui, Add, Text, % "y" . arrTopY + 20 . " x150", %lDialogOr%
	}
	if (intHotkeyType <> 1)
	{
		Gui, Add, Text, % "y" . arrTopY + (intHotkeyType = 2 ? 0 : 40) . " x150 w60", %lDialogKeyboard%
		Gui, Add, Hotkey, yp x+10 w130 vf_strHotkeyKey gHotkeyChanged section
		GuiControl, , f_strHotkeyKey, %strActualKey%
	}
	if (intHotkeyType <> 1)
		Gui, Add, Link, y+5 xs w130 gHotkeySpaceTabClicked, %lDialogSpacebarTab% ; space or tab

	Gui, Add, Button, % "x10 y" . arrTopY + 100 . " vf_btnNoneHotkey gSelectNoneHotkeyClicked", %lDialogMouseNone%
	if StrLen(strDefaultHotkey)
	{
		Gui, Add, Button, % "x10 y" . arrTopY + 100 . " vf_btnResetHotkey gButtonResetHotkey", %lGuiResetDefault%
		GuiCenterButtons(L(lDialogChangeHotkeyTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnNoneHotkey", "f_btnResetHotkey")
	}
	else
	{
		Gui, Add, Text, % "x10 y" . arrTopY + 100
		GuiCenterButtons(L(lDialogChangeHotkeyTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnNoneHotkey")
	}
	Gui, Add, Button, y+30 x10 vf_btnChangeHotkeySave gButtonChangeHotkeySave, %lGuiSave%
	Gui, Add, Button, yp x+20 vf_btnChangeHotkeyCancel gButtonChangeHotkeyCancel, %lGuiCancel%
	
	GuiCenterButtons(L(lDialogChangeHotkeyTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnChangeHotkeySave", "f_btnChangeHotkeyCancel")

	Gui, Add, Text
	GuiControl, Focus, f_btnChangeHotkeySave
	Gui, Show, AutoSize Center

	Gui, 2:+Disabled
	WinWaitClose,  % L(lDialogChangeHotkeyTitle, g_strAppNameText, g_strAppVersion) ; waiting for Gui to close

	return strNewHotkey ; returning value


	;------------------------------------------------------------
	MouseChanged:
	;------------------------------------------------------------

	strMouseControl := A_GuiControl ; hotkey var name
	GuiControlGet, strMouseValue, , %strMouseControl%

	if (strMouseValue = lDialogMouseNone) ; this is the translated "None"
	{
		GuiControl, , f_blnShift, 0
		GuiControl, , f_blnCtrl, 0
		GuiControl, , f_blnAlt, 0
		GuiControl, , f_blnWin, 0
	}

	if (intHotkeyType = 3) ; both keyboard and mouse options are available
	{
		; get the hotkey var
		StringReplace, strHotkeyControl, strMouseControl, Mouse, Key
		StringReplace, strHotkeyControl, strHotkeyControl, drp, str

		; we have a mouse button, empty the hotkey control
		GuiControl, , %strHotkeyControl%, None
	}

	return
	;------------------------------------------------------------
	
	;------------------------------------------------------------
	HotkeyChanged:
	;------------------------------------------------------------
	strHotkeyControl := A_GuiControl ; hotkey var name
	strHotkeyChanged := %strHotkeyControl% ; hotkey content

	if !StrLen(strHotkeyChanged)
		return

	SplitModifiersFromKey(strHotkeyChanged, strHotkeyChangedModifiers, strHotkeyChangedKey)

	if StrLen(strHotkeyChangedModifiers) ; we have a modifier and we don't want it, reset keyboard to none and return
		GuiControl, , %A_GuiControl%, None
	else ; we have a valid key, empty the mouse dropdown and return
	{
		StringReplace, strMouseControl, strHotkeyControl, Key, Mouse ; get the matching mouse dropdown var
		GuiControl, Choose, %f_strHotkeyMouse%, 0
	}

	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	SelectNoneHotkeyClicked:
	;------------------------------------------------------------

	GuiControl, , f_strHotkeyKey, %lDialogMouseNone%
	GuiControl, Choose, f_drpHotkeyMouse, %lDialogMouseNone%
	SplitHotkey("None", strActualModifiers, strActualKey, strActualMouseButton, strActualMouseButtonsWithDefault)
	Gosub, SetModifiersCheckBox

	strModifiers := ""

	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	HotkeySpaceTabClicked:
	;------------------------------------------------------------
	
	if (ErrorLevel = "Space")
		GuiControl, , f_strHotkeyKey, %A_Space%
	else
		GuiControl, , f_strHotkeyKey, %A_Tab%
	GuiControl, Choose, f_drpHotkeyMouse, 0

	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	ButtonResetHotkey:
	;------------------------------------------------------------

	SplitHotkey(strDefaultHotkey, strActualModifiers, strActualKey, strActualMouseButton, strActualMouseButtonsWithDefault)
	GuiControl, , f_strHotkeyKey, %strActualKey%
	GuiControl, Choose, f_drpHotkeyMouse, % GetText4MouseButton(strActualMouseButton)
	Gosub, SetModifiersCheckBox
	
	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	SetModifiersCheckBox:
	;------------------------------------------------------------
	GuiControl, , f_blnShift, % InStr(strActualModifiers, "+") ? 1 : 0
	GuiControl, , f_blnCtrl, % InStr(strActualModifiers, "^") ? 1 : 0
	GuiControl, , f_blnAlt, % InStr(strActualModifiers, "!") ? 1 : 0
	GuiControl, , f_blnWin, % InStr(strActualModifiers, "#") ? 1 : 0
	
	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	ButtonChangeHotkeySave:
	;------------------------------------------------------------
	
	GuiControlGet, strMouse, , f_drpHotkeyMouse
	GuiControlGet, strKey, , f_strHotkeyKey
	GuiControlGet, blnWin , ,f_blnWin
	GuiControlGet, blnAlt, , f_blnAlt
	GuiControlGet, blnCtrl, , f_blnCtrl
	GuiControlGet, blnShift, , f_blnShift
	
	if StrLen(strMouse)
		strMouse := GetMouseButton4Text(strMouse) ; get mouse button system name from dropdown localized text
	; else ???
	;	strMouseButton%intIndex% := "" ;  empty mouse button text
	
	strNewHotkey := Trim(strKey . (strMouse = "None" ? "" : strMouse))
	if !StrLen(strNewHotkey)
		strNewHotkey := "None"

	if (strNewHotkey <> "None") ; do not compare with lDialogMouseNone because it is translated
	{
		; Order of modifiers important to keep modifiers labels in correct order
		if (blnWin)
			strNewHotkey := "#" . strNewHotkey
		if (blnAlt)
			strNewHotkey := "!" . strNewHotkey
		if (blnCtrl)
			strNewHotkey := "^" . strNewHotkey
		if (blnShift)
			strNewHotkey := "+" . strNewHotkey

		if (strNewHotkey = "LButton")
		{
			Oops(lDialogMouseCheckLButton, lDialogShift, lDialogCtrl, lDialogAlt, lDialogWin)
			strNewHotkey := ""
			return
		}
	}

	Gosub, 3GuiClose
	
	return
	;------------------------------------------------------------

	;------------------------------------------------------------
	ButtonChangeHotkeyCancel:
	;------------------------------------------------------------
	
	strHotkey := ""

	Gosub, 3GuiClose
  
	return
	;------------------------------------------------------------

}
;------------------------------------------------------------

;========================================================================================================================
; END OF !_035_GUI_CHANGE_HOTKEY:
;========================================================================================================================


;========================================================================================================================
!_040_GROUPS:
;========================================================================================================================

/*
;------------------------------------------------------------
GuiGroupsManage:
;------------------------------------------------------------

; ### not reviewed, not tested

intWidth := 350

Gosub, BuildFoldersInExplorerMenu ; refresh explorers object and intExplorersIndex counter

g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide

Gui, 2:New, , % L(lDialogGroupManageGroupsTitle, g_strAppNameText, g_strAppVersion)
Gui, 2:+Owner1
Gui, 2:+OwnDialogs
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%

Gui, 2:Font, w600 
Gui, 2:Add, Text, x10 y10, %lDialogGroupManageAbout%
Gui, 2:Font

Gui, 2:Add, Text, x10 y+10 w%intWidth%, %lDialogGroupManageIntro%

Gui, 2:Font, w600 
Gui, 2:Add, Text, x10 y+20, %lDialogGroupManageCreatingTitle%
Gui, 2:Font 

strUseMenuSave := lMenuGroup . " > " . lMenuGroupSave
Gui, 2:Add, Text, x10 y+10 w%intWidth%, % L(lDialogGroupManageCreatingPrompt, lDialogGroupNew, strUseMenuSave)
Gui, 2:Add, Button, x10 y+10 vf_btnGroupManageNew gGuiGroupManageNew, %lDialogGroupNew%
GuiControl, % (!intExplorersIndex ? "Disable" : "Enable") ; disable Save group menu if no Explorer
	, f_btnGroupManageNew
GuiCenterButtons(L(lDialogGroupManageGroupsTitle, g_strAppNameText, g_strAppVersion), , , , "f_btnGroupManageNew")
if !(intExplorersIndex)
	Gui, 2:Add, Text, x10 y+10 w%intWidth%, %lDialogGroupManageCannotSave%

Gui, 2:Font, w600 
Gui, 2:Add, Text, x10 y+20, %lDialogGroupManageManagingTitle%
Gui, 2:Font

Gui, 2:Add, DropDownList, x10 y+10 w%intWidth% vf_drpGroupsList, %lDialogGroupSelect%||%g_strGroups%

Gui, 2:Add, Button, x10 y+10 vf_btnGroupManageLoad gGuiGroupManageLoad, %lDialogGroupLoad%
Gui, 2:Add, Button, x10 yp vf_btnGroupManageEdit gGuiGroupManageEdit, %lDialogGroupEdit%
Gui, 2:Add, Button, x10 yp vf_btnGroupManageDelete gGuiGroupManageDelete, %lDialogGroupDelete%
GuiCenterButtons(L(lDialogGroupManageGroupsTitle, g_strAppNameText, g_strAppVersion), , , , "f_btnGroupManageLoad", "f_btnGroupManageEdit", "f_btnGroupManageDelete")

Gui, 2:Add, Button, x+10 y+30 vf_btnGroupManageClose g2GuiClose h33, %lGui2Close%
GuiCenterButtons(L(lDialogGroupManageGroupsTitle, g_strAppNameText, g_strAppVersion), , , , "f_btnGroupManageClose")
Gui, 2:Add, Text, x10, %A_Space%

Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiGroupManageEdit:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

if !StrLen(f_drpGroupsList) or (f_drpGroupsList = lDialogGroupSelect)
{
	Oops(lDialogGroupSelectError, lDialogGroupEditError)
	return
}

strGroupToEdit := f_drpGroupsList
Gosub, GuiGroupEditFromManage
GuiControl, 2:, f_drpGroupsList, |%lDialogGroupSelect%||%g_strGroups%

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiGroupManageDelete:
;------------------------------------------------------------
Gui, 2:Submit, NoHide
Gui, 2:+OwnDialogs

if !StrLen(f_drpGroupsList) or (f_drpGroupsList = lDialogGroupSelect)
{
	Oops(lDialogGroupSelectError, lDialogGroupDeleteError)
	return
}

MsgBox, 52, % L(lDialogGroupDeleteTitle, g_strAppNameText), % L(lDialogGroupDeletePrompt, f_drpGroupsList)
IfMsgBox, No
	return

g_strGroups := g_strGroups . "|"
StringReplace, g_strGroups, g_strGroups, %f_drpGroupsList%|
StringTrimRight, g_strGroups, g_strGroups, 1
GuiControl, 2:, f_drpGroupsList, |%lDialogGroupSelect%||%g_strGroups%

IniDelete, %g_strIniFile%, Group-%f_drpGroupsList%
IniWrite, %g_strGroups%, %g_strIniFile%, Global, Groups

Gosub, BuildGroupMenu

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiGroupManageLoad:
;------------------------------------------------------------
Gui, 2:Submit, NoHide

if !StrLen(f_drpGroupsList) or (f_drpGroupsList = lDialogGroupSelect)
{
	Oops(lDialogGroupSelectError, lDialogGroupLoadError)
	return
}

strSelectedGroup := f_drpGroupsList

Gosub, 2GuiClose
Gosub, GuiClose
Gosub, GroupLoadFromManage

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiGroupManageNew:
;------------------------------------------------------------

Gosub, GuiGroupSaveFromManage
GuiControl, 2:, f_drpGroupsList, |%lDialogGroupSelect%||%g_strGroups%

return
;------------------------------------------------------------
*/

;========================================================================================================================
; END OF GROUPS
;========================================================================================================================



;========================================================================================================================
!_050_GUI_CLOSE-CANCEL-BK_OBJECTS:
;========================================================================================================================


;------------------------------------------------------------
GuiClose:
GuiEscape:
;------------------------------------------------------------

GoSub, GuiCancel

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiCancel:
;------------------------------------------------------------

GuiControlGet, blnSaveEnabled, Enabled, f_btnGuiSave
if (blnSaveEnabled)
{
	Gui, 1:+OwnDialogs
	MsgBox, 36, % L(lDialogCancelTitle, g_strAppNameText, g_strAppVersion), %lDialogCancelPrompt%
	IfMsgBox, Yes
	{
		g_blnMenuReady := false
		Gosub, RestoreBackupMenusObjects
		
		; restore popup menu
		Gosub, BuildFoldersInExplorerMenu
		Gosub, BuildMainMenu ; need to be initialized here - will be updated at each call to popup menu
		
		GuiControl, Disable, f_btnGuiSave
		GuiControl, , f_btnGuiCancel, %lGuiClose%
		g_blnMenuReady := true
	}
	IfMsgBox, No
		return
}
Gui, 1:Cancel

blnSaveEnabled := ""

; ### TEMP
; Gosub, CleanUpBeforeExit ; ExitApp

return
;------------------------------------------------------------


;------------------------------------------------------------
2GuiClose:
2GuiEscape:
;------------------------------------------------------------

Gui, 1:-Disabled
Gui, 2:Destroy
WinActivate, ahk_id %g_intGui1WinID%

return
;------------------------------------------------------------


;------------------------------------------------------------
3GuiClose:
3GuiEscape:
;------------------------------------------------------------

Gui, 2:-Disabled
Gui, 3:Destroy
WinActivate, ahk_id %intGui2WinID%

return
;------------------------------------------------------------


;------------------------------------------------------------
BackupMenusObjects:
RestoreBackupMenusObjects:
; in case of Gui Cancel to restore objects to original state
;------------------------------------------------------------

if (A_ThisLabel = "BackupMenusObjects")
	objMenusSource := g_objMenusIndex
else ; RestoreBackupMenusObjects
	objMenusSource := g_objMenusBK


objMenusDest := Object() ; reset object

for strMenuPath, objMenuSource in objMenusSource
{
	objMenuDest := Object()
	objMenuDest.MenuPath := objMenu.MenuPath
	
	loop, % objMenuSource.MaxIndex()
	{
		objFavorite := Object()
		objFavorite.FavoriteType := objMenuSource[A_Index].FavoriteType
		objFavorite.FavoriteName := objMenuSource[A_Index].FavoriteName
		objFavorite.FavoriteLocation := objMenuSource[A_Index].FavoriteLocation
		objFavorite.FavoriteIconResource := objMenuSource[A_Index].FavoriteIconResource
		objFavorite.FavoriteArguments := objMenuSource[A_Index].FavoriteArguments
		objFavorite.FavoriteAppWorkingDir := objMenuSource[A_Index].FavoriteAppWorkingDir
		objFavorite.FavoriteWindowPosition := objMenuSource[A_Index].FavoriteWindowPosition
		objFavorite.FavoriteHotkey := objMenuSource[A_Index].FavoriteHotkey
		objFavorite.FavoriteLaunchWith := objMenuSource[A_Index].FavoriteLaunchWith
		objFavorite.SubMenu := objMenuSource[A_Index].SubMenu
		
		objMenuDest.Insert(A_Index, objFavorite)
	}
	
	objMenusDest.Insert(strMenuPath, objMenuDest)
}

if (A_ThisLabel = "BackupMenusObjects")
	g_objMenusBK := objMenusDest
else ; RestoreBackupMenusObjects
	g_objMenusIndex := objMenusDest

objMenusSource := ""
objMenusDest := ""
strMenuPath := ""
objMenuSource := ""
objMenuDest := ""
objFavorite := ""

return
;------------------------------------------------------------



;========================================================================================================================
; END OF GUI CLOSE-CANCEL-BK_OBJECTS
;========================================================================================================================


;========================================================================================================================
!_060_POPUP_MENU:
;========================================================================================================================

;------------------------------------------------------------
NavigateHotkeyMouse:
NavigateHotkeyKeyboard:
;------------------------------------------------------------

###_D(A_ThisLabel)

if !(g_blnMenuReady)
	return

blnMouse := InStr(A_ThisLabel, "Mouse")

Gosub, SetMenuPosition ; sets strTargetWinId or activate the window strTargetWinId set by CanOpenFavorite
WinGetClass g_strTargetClass, % "ahk_id " . g_strTargetWinId ; ### already set by CanNavigate?

if (blnMouse) and (WindowIsDirectoryOpus(g_strTargetClass) or WindowIsTotalCommander(g_strTargetClass))
{
	Click ; to make sure the DOpus lister or TC pane under the mouse become active
	Sleep, 20
}

if (g_blnDisplayFoldersInExplorerMenu) ; ### check or track that we have a FoldersInExplorerMenu
{
	Gosub, BuildFoldersInExplorerMenu
	Menu, %lMainMenuName% ; ### find in what menu we have the FoldersInExplorerMenu
		, % (!intExplorersIndex ? "Disable" : "Enable") ; disable Folders in Explorer menu if no Explorer
		, %lMenuCurrentFolders%
}

if (g_blnDisplayClipboardMenu) ; ### check or track that we have a ClipboardMenu
{
	Gosub, RefreshClipboardMenu
	Menu, %lMainMenuName% ; ### find in what menu we have the ClipboardMenu
		, % (g_blnClipboardMenuEnable ? "Enable" : "Disable")
		, %lMenuClipboard%
}

; Enable "Add This Folder" only if the target window is an Explorer, TotalCommander,
; Directory Opus or a dialog box under WIN_7 (does not work under WIN_XP). Tested on WIN_XP and WIN_7.

/*
Menu, %lMainMenuName% ; ### find in what menu we have the lMenuAddThisFolder
	, % WindowIsAnExplorer(g_strTargetClass) ; removed for FPconnect: or WindowIsFreeCommander(strTargetClass)
	or WindowIsTotalCommander(g_strTargetClass) or WindowIsDirectoryOpus(g_strTargetClass)
	or (WindowIsDialog(g_strTargetClass, g_strTargetWinId)) ? "Enable" : "Disable"
	, %lMenuAddThisFolder%...
*/

Gosub, InsertColumnBreaks

Menu, %lMainMenuName%, Show, %g_intMenuPosX%, %g_intMenuPosy% ; at mouse pointer if option 1, 20x20 offset of active window if option 2 and fix location if option 3


blnMouse := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
LaunchHotkeyMouse:
LaunchHotkeyKeyboard:
;------------------------------------------------------------

###_D(A_ThisLabel)

if !(g_blnMenuReady)
	return

blnMouse := InStr(A_ThisLabel, "Mouse")


return
;------------------------------------------------------------


;------------------------------------------------------------
PowerHotkeyMouse:
PowerHotkeyKeyboard:
;------------------------------------------------------------

###_D(A_ThisLabel)

return
;------------------------------------------------------------


;------------------------------------------------------------
SetMenuPosition:
;------------------------------------------------------------

; relative to active window if option g_intPopupMenuPosition = 2
CoordMode, Mouse, % (g_intPopupMenuPosition = 2 ? "Window" : "Screen")
CoordMode, Menu, % (g_intPopupMenuPosition = 2 ? "Window" : "Screen")

if (g_intPopupMenuPosition = 1) ; display menu near mouse pointer location
	MouseGetPos, g_intMenuPosX, g_intMenuPosY
else if (g_intPopupMenuPosition = 2) ; display menu at an offset of 20x20 pixel from top-left of active window area
{
	g_intMenuPosX := 20
	g_intMenuPosY := 20
}
else ; (g_intPopupMenuPosition =  3) - fix position - use the g_intMenuPosX and g_intMenuPosY values from the ini file
{
	g_intMenuPosX := g_arrPopupFixPosition1
	g_intMenuPosY := g_arrPopupFixPosition2
}

; not related to set position but this is a good place to execute it ;-)
if (blnMouse)
	if (blnNewWindow)
		MouseGetPos, , , g_strTargetWinId ; sets strTargetWinId for PopupMenuNewWindowMouse
	else
		WinActivate, % "ahk_id " . g_strTargetWinId ; activate for PopupMenuMouse
else ; (keyboard)
	if (blnNewWindow)
		g_strTargetWinId := WinExist("A") ; sets strTargetWinId for PopupMenuNewWindowKeyboard

return
;------------------------------------------------------------


;------------------------------------------------------------
CanNavigate(strMouseOrKeyboard) ; SEE HotkeyIfWin.ahk to use Hotkey, If, Expression
; "CabinetWClass" and "ExploreWClass" -> Explorer
; "ProgMan" -> Desktop
; "WorkerW" -> Desktop
; "ConsoleWindowClass" -> Console (CMD)
; "#32770" -> Dialog
; "bosa_sdm_" (...) -> Dialog MS Office under WinXP
;------------------------------------------------------------
{
	global
	
	g_intCounterNavigate++
	
	if (strMouseOrKeyboard = g_arrHotkeys1) ; Mouse hotkey
	{
		MouseGetPos, , , g_strTargetWinId, g_strTargetControl
		WinGetClass g_strTargetClass, % "ahk_id " . g_strTargetWinId
		; TrayTip, Navigate Mouse, %strMouseOrKeyboard% = %g_strMouseNavigateHotkey% (%g_intCounter%)`n%g_strTargetWinId%`n%g_strTargetClass%`n%g_strTargetControl%
	}
	else ; Keyboard
	{
		g_strTargetWinId := WinExist("A")
		g_strTargetControl := ""
		WinGetClass g_strTargetClass, % "ahk_id " . g_strTargetWinId
		; TrayTip, Navigate Keyboard, %strMouseOrKeyboard% = %g_strKeyboardNavigateHotkey% (%g_intCounter%)`n%g_strTargetWinId%`n%g_strTargetClass%
	}

	blnCanNavigate := WindowIsAnExplorer(g_strTargetClass) or WindowIsDesktop(g_strTargetClass) or WindowIsConsole(g_strTargetClass)
		or WindowIsDialog(g_strTargetClass, g_strTargetWinId)
		or (g_blnUseDirectoryOpus and WindowIsDirectoryOpus(g_strTargetClass))
		or (g_blnUseTotalCommander and WindowIsTotalCommander(g_strTargetClass))
		or (g_blnUseFPconnect and WindowIsFPconnect(g_strTargetWinId))
		or WindowIsQuickAccessPopup(g_strTargetClass)

	return blnCanNavigate
}
;------------------------------------------------------------


;------------------------------------------------------------
CanLaunch(strMouseOrKeyboard) ; SEE HotkeyIfWin.ahk to use Hotkey, If, Expression
;------------------------------------------------------------
{
	global

	g_intCounterLaunch++

	if (strMouseOrKeyboard = g_arrHotkeys1) ; Mouse hotkey
	{
		MouseGetPos, , , g_strTargetWinId, g_strTargetControl
		WinGetClass g_strTargetClass, % "ahk_id " . g_strTargetWinId
		TrayTip, CanLaunch Mouse, %strMouseOrKeyboard% = %g_strMouseHotkey%`n%g_strTargetControl%`nList: %g_strExclusionClassList%`nClass: %g_strTargetClass%
	}
	else ; Keyboard
	{
		g_strTargetWinId := WinExist("A")
		g_strTargetControl := ""
		WinGetClass g_strTargetClass, % "ahk_id " . g_strTargetWinId
		TrayTip, CanLaunch Keyboard, %strMouseOrKeyboard% = %g_strKeyboardHotkey%`nList: %g_strExclusionClassList%`nClass: %g_strTargetClass%
	}
	; ###_V("CanLaunch`n`n", g_strExclusionClassList, g_strTargetClass . "|")

	; ### to-do exclusion as "class contain the exclusion string" (looping in exclusion strings)
	return !InStr(g_strExclusionClassList, g_strTargetClass . "|")
}
;------------------------------------------------------------



;========================================================================================================================
; END OF POPUP MENU
;========================================================================================================================



;========================================================================================================================
!_070_CLASS:
return
;========================================================================================================================

;------------------------------------------------------------
WindowIsAnExplorer(strClass)
;------------------------------------------------------------
{
	return (strClass = "CabinetWClass") or (strClass = "ExploreWClass")
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsDesktop(strClass)
;------------------------------------------------------------
{
	global g_blnOpenMenuOnTaskbar
	global blnClickOnTrayIcon
	
	blnWindowIsDesktop := (strClass = "ProgMan")
		or (strClass = "WorkerW")
		or (strClass = "Shell_TrayWnd" and (g_blnOpenMenuOnTaskbar or blnClickOnTrayIcon))
		or (strClass = "NotifyIconOverflowWindow")

	blnClickOnTrayIcon := 0
	; blnClickOnTrayIcon was turned on by AHK_NOTIFYICON
	; turn it off to avoid further clicks on taskbar to be accepted if g_blnOpenMenuOnTaskbar is off

	return blnWindowIsDesktop
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsTray(strClass)
;------------------------------------------------------------
{
	return (strClass = "Shell_TrayWnd") or (strClass = "NotifyIconOverflowWindow")
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsConsole(strClass)
;------------------------------------------------------------
{
	return (strClass = "ConsoleWindowClass")
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsDialog(strClass, strWinId)
;------------------------------------------------------------
{
	return (strClass = "#32770") and !WindowIsTreeview(strWinId)
	
	; or InStr(strClass, "bosa_sdm_")
	; Removed 2014-09-27  (see http://code.jeanlalonde.ca/folderspopupv3archives/#comment-7912)
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsTreeview(strWinId)
; Disable popup menu in folder select dialog boxes (like those displayed by FileSelectFolder)
; because their Edit1 control does not react as expected in NavigateDialog.
; Signature: contains both SysTreeView321 and SHBrowseForFolder controls (tested on Win7 only)
; but NOT 100% sure this is a unique signature...
;------------------------------------------------------------
{
	global g_strAppNameText
	
	WinGet, strControlsList, ControlList, ahk_id %strWinId%
	blnIsTreeView := InStr(strControlsList, "SysTreeView321") and InStr(strControlsList, "SHBrowseForFolder")
	if (blnIsTreeView)
		TrayTip, %lWindowIsTreeviewTitle%, % L(lWindowIsTreeviewText, g_strAppNameText), , 2
	
	return blnIsTreeView
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsDirectoryOpus(strClass)
;------------------------------------------------------------
{
	return InStr(strClass, "dopus")
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsTotalCommander(strClass)
;------------------------------------------------------------
{
	return InStr(strClass, "TTOTAL_CMD")
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsFPconnect(strWinId)
;------------------------------------------------------------
{
	global g_strFPconnectAppFilename
	global g_strFPconnectTargetFilename

	if (strTargetWinId = 0)
		return false

	; get path and filename of the app controling window strWinId
	; first get process ID
    intPID := 0
    DllCall("GetWindowThreadProcessId", "UInt", strWinId, "UInt *", intPID)
	; get filename of process
    hProcess := DllCall("OpenProcess", "UInt", 0x400 | 0x10, "Int", False, "UInt", intPID)
    intPathLength = 260*2
    VarSetCapacity(strFCAppFile, intPathLength, 0)
    DllCall("Psapi.dll\GetModuleFileNameExW", "UInt", hProcess, "Int", 0, "Str", strFCAppFile, "UInt", intPathLength)
    DllCall("CloseHandle", "UInt", hProcess)
	
	; get filename only and compare with FPconnect filename or FPconnect target filename (see FPconnect doc)
	SplitPath, strFCAppFile, strFCAppFile
	return (strFCAppFile = g_strFPconnectAppFilename) or (strFCAppFile = g_strFPconnectTargetFilename)
}
;------------------------------------------------------------


;------------------------------------------------------------
WindowIsQuickAccessPopup(strClass)
; enabled only when compiled
;------------------------------------------------------------
{
	return (strClass = "JeanLalonde.ca")
}
;------------------------------------------------------------



;========================================================================================================================
; END OF CLASS
;========================================================================================================================



;========================================================================================================================
!_080_MENU_ACTIONS:
;========================================================================================================================


;------------------------------------------------------------
OpenFavorite:
OpenRecentFolder:
OpenFolderInExplorer:
OpenClipboard:
;------------------------------------------------------------

; is this navigate or launch?

if (g_blnDisplayMenuShortcuts)
	StringTrimLeft, strThisMenu, A_ThisMenuItem, 3 ; remove "&1 " from menu item
else
	strThisMenu := A_ThisMenuItem
GetFavoriteProperties(A_ThisMenu, strThisMenu, strLocation, strFavoriteType, strAppArguments, strAppWorkingDir)

###_V("Menu Action`n`n", A_ThisLabel, A_ThisMenu, strThisMenu, strLocation, strFavoriteType, strAppArguments, strAppWorkingDir)

return
;------------------------------------------------------------


;------------------------------------------------------------
GetFavoriteProperties(strMenu, strName, ByRef strLocation, ByRef strFavoriteType, ByRef strAppArguments, ByRef strAppWorkingDir)
;------------------------------------------------------------
{
	global g_arrMenus
	
	Loop, % g_arrMenus[strMenu].MaxIndex()
		if (strName = g_arrMenus[strMenu][A_Index].FavoriteName)
		{
			strLocation := g_arrMenus[strMenu][A_Index].FavoriteLocation
			strFavoriteType := g_arrMenus[strMenu][A_Index].FavoriteType
			strAppArguments := g_arrMenus[strMenu][A_Index].AppArguments
			strAppWorkingDir := g_arrMenus[strMenu][A_Index].AppWorkingDir
			break
		}
}
;------------------------------------------------------------


;========================================================================================================================
; END OF MENU ACTIONS
;========================================================================================================================



;========================================================================================================================
!_072_TRAY_MENU_ACTIONS:
;========================================================================================================================

;------------------------------------------------------------
ShowIniFile:
;------------------------------------------------------------

Run, %g_strIniFile%

return
;------------------------------------------------------------


;------------------------------------------------------------
RunAtStartup:
;------------------------------------------------------------
; Startup code adapted from Avi Aryan Ryan in Clipjump

Menu, Tray, Togglecheck, %lMenuRunAtStartup%
IfExist, %A_Startup%\%g_strAppNameFile%.lnk
	FileDelete, %A_Startup%\%g_strAppNameFile%.lnk
else
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%g_strAppNameFile%.lnk, %A_WorkingDir%

return
;------------------------------------------------------------


;------------------------------------------------------------
SuspendHotkeys:
;------------------------------------------------------------

if (A_IsSuspended)
	Suspend, Off
else
	Suspend, On

Menu, Tray, % (A_IsSuspended ? "check" : "uncheck"), %lMenuSuspendHotkeys%

return
;------------------------------------------------------------


;------------------------------------------------------------
Check4Update:
;------------------------------------------------------------

strUrlCheck4Update := "http://quickaccesspopup.com/latest/version.php"
strAppLandingPage := "http://quickaccesspopup.com"
strBetaLandingPage := "http://quickaccesspopup.com/latest/check4update-beta-redirect.html"

IniRead, strLatestSkippedProd, %g_strIniFile%, Global, LatestVersionSkippedProd, 0.0
IniRead, strLatestSkippedBeta, %g_strIniFile%, Global, LatestVersionSkippedBeta, 0.0
IniRead, strLatestUsedProd, %g_strIniFile%, Global, LastVersionUsedProd, 0.0
IniRead, strLatestUsedBeta, %g_strIniFile%, Global, LastVersionUsedBeta, 0.0

IniRead, intStartups, %g_strIniFile%, Global, Startups, 1

if (g_blnDiagMode)
{
	Diag("Check4Update strAppLandingPage", strAppLandingPage)
	Diag("Check4Update strBetaLandingPage", strBetaLandingPage)
}

Gui, 1:+OwnDialogs

if (A_ThisMenuItem <> lMenuUpdate)
{
	if Time2Donate(intStartups, g_blnDonor)
	{
		MsgBox, 36, % l(lDonateCheckTitle, intStartups, g_strAppNameText), % l(lDonateCheckPrompt, g_strAppNameText, intStartups)
		IfMsgBox, Yes
			Gosub, GuiDonate
	}
	IniWrite, % (intStartups + 1), %g_strIniFile%, Global, Startups
}

blnSetup := (FileExist(A_ScriptDir . "\_do_not_remove_or_rename.txt") = "" ? 0 : 1)

strLatestVersions := Url2Var(strUrlCheck4Update
	. "?v=" . g_strCurrentVersion
	. "&os=" . A_OSVersion
	. "&is64=" . A_Is64bitOS
    . "&setup=" . (blnSetup)
				+ (2 * (g_blnDonor ? 1 : 0))
				+ (4 * (g_blnUseDirectoryOpus ? 1 : 0))
				+ (8 * (g_blnUseTotalCommander ? 1 : 0))
				+ (16 * (g_blnUseFPconnect ? 1 : 0))
    . "&lsys=" . A_Language
    . "&lfp=" . g_strLanguageCode)
if !StrLen(strLatestVersions)
	if (A_ThisMenuItem = lMenuUpdate)
	{
		Oops(lUpdateError)
		return ; an error occured during ComObjCreate
	}

strLatestVersions := SubStr(strLatestVersions, InStr(strLatestVersions, "[[") + 2) 
strLatestVersions := SubStr(strLatestVersions, 1, InStr(strLatestVersions, "]]") - 1) 
strLatestVersions := Trim(strLatestVersions, "`n`l") ; remove en-of-line if present
Loop, Parse, strLatestVersions, , 0123456789.| ; strLatestVersions should only contain digits, dots and one pipe (|) between prod and beta versions
	; if we get here, the content returned by the URL above is wrong
	if (A_ThisMenuItem <> lMenuUpdate)
		return ; return silently
	else
	{
		Oops(lUpdateError) ; return with an error message
		return
	}

StringSplit, arrLatestVersions, strLatestVersions, |
strLatestVersionProd := arrLatestVersions1
strLatestVersionBeta := arrLatestVersions2

if (g_blnDiagMode)
{
	Diag("Check4Update g_strCurrentVersion", g_strCurrentVersion)
	Diag("Check4Update strLatestVersionProd", strLatestVersionProd)
	Diag("Check4Update strLatestVersionBeta", strLatestVersionBeta)
	Diag("Check4Update strLatestSkippedProd", strLatestSkippedProd)
	Diag("Check4Update strLatestSkippedBeta", strLatestSkippedBeta)
	Diag("Check4Update strLatestUsedProd", strLatestUsedProd)
	Diag("Check4Update strLatestUsedBeta", strLatestUsedBeta)
}

Gui, 1:+OwnDialogs

if (strLatestUsedBeta <> "0.0")
{
	if FirstVsSecondIs(strLatestVersionBeta, g_strCurrentVersion) = 1
	{
		SetTimer, Check4UpdateChangeButtonNames, 50

		MsgBox, 3, % l(lUpdateTitle, g_strAppNameText) ; do not add BETA to keep buttons rename working
			, % l(lUpdatePromptBeta, g_strAppNameText, g_strCurrentVersion, strLatestVersionBeta)
		IfMsgBox, Yes
			Run, %strBetaLandingPage%
		IfMsgBox, Cancel ; Remind me
			IniWrite, 0.0, %g_strIniFile%, Global, LatestVersionSkippedBeta
		IfMsgBox, No
		{
			IniWrite, %strLatestVersionBeta%, %g_strIniFile%, Global, LatestVersionSkippedBeta
			MsgBox, 4, % l(lUpdateTitle, g_strAppNameText . " BETA"), %lUpdatePromptBetaContinue%
			IfMsgBox, No
				IniWrite, 0.0, %g_strIniFile%, Global, LastVersionUsedBeta
		}
	}
}

if (FirstVsSecondIs(strLatestSkippedProd, strLatestVersionProd) >= 0 and (A_ThisMenuItem <> lMenuUpdate))
	return

if FirstVsSecondIs(strLatestVersionProd, g_strCurrentVersion) = 1
{
	SetTimer, Check4UpdateChangeButtonNames, 50

	MsgBox, 3, % l(lUpdateTitle, g_strAppNameText)
		, % l(lUpdatePrompt, g_strAppNameText, g_strCurrentVersion, strLatestVersionProd)
	IfMsgBox, Yes
		Run, %strAppLandingPage%
	IfMsgBox, No
		IniWrite, %strLatestVersionProd%, %g_strIniFile%, Global, LatestVersionSkipped ; do not add "Prod" to ini variable for backward compatibility
	IfMsgBox, Cancel ; Remind me
		IniWrite, 0.0, %g_strIniFile%, Global, LatestVersionSkipped ; do not add "Prod" to ini variable for backward compatibility
}
else if (A_ThisMenuItem = lMenuUpdate)
{
	MsgBox, 4, % l(lUpdateTitle, g_strAppNameText), % l(lUpdateYouHaveLatest, g_strAppVersion, g_strAppNameText)
	IfMsgBox, Yes
	{
		if (g_blnDiagMode)
		{
			Diag("Check4Update lMenuUpdate g_strCurrentBranch", g_strCurrentBranch)
			Diag("Check4Update lMenuUpdate strAppLandingPage", strAppLandingPage)
			Diag("Check4Update lMenuUpdate strBetaLandingPage", strBetaLandingPage)
		}
		Run, %strAppLandingPage%
	}
}

strLatestSkippedProd := ""
strLatestSkippedBeta := ""
strLatestUsedProd := ""
strLatestUsedBeta := ""
intStartups := ""

return 
;------------------------------------------------------------


;------------------------------------------------------------
FirstVsSecondIs(strFirstVersion, strSecondVersion)
;------------------------------------------------------------
{
	StringSplit, arrFirstVersion, strFirstVersion, `.
	StringSplit, arrSecondVersion, strSecondVersion, `.
	if (arrFirstVersion0 > arrSecondVersion0)
		intLoop := arrFirstVersion0
	else
		intLoop := arrSecondVersion0

	Loop %intLoop%
		if (arrFirstVersion%A_index% > arrSecondVersion%A_index%)
			return 1 ; greater
		else if (arrFirstVersion%A_index% < arrSecondVersion%A_index%)
			return -1 ; smaller
		
	return 0 ; equal
}
;------------------------------------------------------------


;------------------------------------------------------------
Check4UpdateChangeButtonNames:
;------------------------------------------------------------

IfWinNotExist, % l(lUpdateTitle, g_strAppNameText)
    return  ; Keep waiting.
SetTimer, Check4UpdateChangeButtonNames, Off
WinActivate 
ControlSetText, Button3, %lUpdateButtonRemind%

return
;------------------------------------------------------------


;------------------------------------------------------------
Time2Donate(intStartups, g_blnDonor)
;------------------------------------------------------------
{
	return !Mod(intStartups, 20) and (intStartups > 40) and !(g_blnDonor)
}
;------------------------------------------------------------



;========================================================================================================================
; END OF TRAY MENU ACTIONS
;========================================================================================================================



;========================================================================================================================
!_075_NAVIGATE:
;========================================================================================================================


;========================================================================================================================
; END OF NAVIGATE
;========================================================================================================================




;========================================================================================================================
!_078_ABOUT-DONATE-HELP:
;========================================================================================================================

;------------------------------------------------------------
GuiAbout:
;------------------------------------------------------------

g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide

Gui, 2:New, , % L(lAboutTitle, g_strAppNameText, g_strAppVersion)
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%
Gui, 2:+Owner1
Gui, 2:Font, s12 w700, Verdana
Gui, 2:Add, Link, y10 w350, % L(lAboutText1, g_strAppNameText, g_strAppVersion, A_PtrSize * 8) ;  ; A_PtrSize * 8 = 32 or 64
Gui, 2:Font, s8 w400, Verdana
Gui, 2:Add, Link, , % L(lAboutText2, g_strAppNameText)
Gui, 2:Add, Link, , % L(lAboutText3, chr(169))
Gui, 2:Font, s10 w400, Verdana
Gui, 2:Add, Link, , % L(lAboutText4)
Gui, 2:Font, s8 w400, Verdana

Gui, 2:Add, Button, y+20 vf_btnAboutDonate gGuiDonate, %lDonateButton%
Gui, 2:Add, Button, yp vf_btnAboutClose g2GuiClose, %lGui2Close%
GuiCenterButtons(L(lAboutTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnAboutDonate", "f_btnAboutClose")

GuiControl, Focus, f_btnAboutClose
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiDonate:
;------------------------------------------------------------

g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide

Gui, 2:New, , % L(lDonateTitle, g_strAppNameText, g_strAppVersion)
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%
Gui, 2:+Owner1
Gui, 2:Font, s12 w700, Verdana
Gui, 2:Add, Link, y10 w420, % L(lDonateText1, g_strAppNameText)
Gui, 2:Font, s8 w400, Verdana
Gui, 2:Add, Link, x175 w185 y+10, % L(lDonateText2, "http://code.jeanlalonde.ca/support-freeware/")
loop, 2
{
	Gui, 2:Add, Button, % (A_Index = 1 ? "y+10 Default vbtnDonateDefault " : "") . " xm w150 gButtonDonate" . A_Index, % lDonatePlatformName%A_Index%
	Gui, 2:Add, Link, x+10 w235 yp, % lDonatePlatformComment%A_Index%
}

Gui, 2:Font, s10 w700, Verdana
Gui, 2:Add, Link, xm y+20 w420, %lDonateText3%
Gui, 2:Font, s8 w400, Verdana
Gui, 2:Add, Link, xm y+10 w420 Section, % L(lDonateText4, g_strAppNameText)

strDonateReviewUrlLeft1 := "http://download.cnet.com/FoldersPopup/3000-2344_4-76062382.html"
strDonateReviewUrlLeft2 := "http://www.portablefreeware.com/index.php?id=2557"
strDonateReviewUrlLeft3 := "http://www.softpedia.com/get/System/OS-Enhancements/FoldersPopup.shtml"
strDonateReviewUrlRight1 := "http://fileforum.betanews.com/detail/Folders-Popup/1385175626/1"
strDonateReviewUrlRight2 := "http://www.filecluster.com/System-Utilities/Other-Utilities/Download-FoldersPopup.html"
strDonateReviewUrlRight3 := "http://freewares-tutos.blogspot.fr/2013/12/folders-popup-un-logiciel-portable-pour.html"

loop, 3
	Gui, 2:Add, Link, % (A_Index = 1 ? "ys+20" : "y+5") . " x25 w150", % "<a href=""" . strDonateReviewUrlLeft%A_Index% . """>" . lDonateReviewNameLeft%A_Index% . "</a>"

loop, 3
	Gui, 2:Add, Link, % (A_Index = 1 ? "ys+20" : "y+5") . " x175 w150", % "<a href=""" . strDonateReviewUrlRight%A_Index% . """>" . lDonateReviewNameRight%A_Index% . "</a>"

Gui, 2:Add, Link, y+10 x130, <a href="http://code.jeanlalonde.ca/support-freeware/">%lDonateText5%</a>

Gui, 2:Font, s8 w400, Verdana
Gui, 2:Add, Button, x175 y+20 g2GuiClose vf_btnDonateClose, %lGui2Close%
GuiCenterButtons(L(lDonateTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnDonateClose")

GuiControl, Focus, btnDonateDefault
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

strDonateReviewUrlLeft1 := ""
strDonateReviewUrlLeft2 := ""
strDonateReviewUrlLeft3 := ""
strDonateReviewUrlRight1 := ""
strDonateReviewUrlRight2 := ""
strDonateReviewUrlRight3 := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
ButtonDonate1:
ButtonDonate2:
ButtonDonate3:
;------------------------------------------------------------

strDonatePlatformUrl1 := "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=AJNCXKWKYAXLCV"
strDonatePlatformUrl2 := "http://www.shareit.com/product.html?productid=300628012"
strDonatePlatformUrl3 := "http://code.jeanlalonde.ca/?flattrss_redirect&id=19&md5=e1767c143c9bde02b4e7f8d9eb362b71"

StringReplace, strButton, A_ThisLabel, ButtonDonate
Run, % strDonatePlatformUrl%strButton%

return
;------------------------------------------------------------


;------------------------------------------------------------
GuiHelp:
;------------------------------------------------------------

g_intGui1WinID := WinExist("A")
Gui, 1:Submit, NoHide

Gui, 2:New, , % L(lHelpTitle, g_strAppNameText, g_strAppVersion)
if (g_blnUseColors)
	Gui, 2:Color, %g_strGuiWindowColor%
Gui, 2:+Owner1
intWidth := 600
Gui, 2:Font, s12 w700, Verdana
Gui, 2:Add, Text, x10 y10, %g_strAppNameText%
Gui, 2:Font, s10 w400, Verdana
Gui, 2:Add, Link, x10 w%intWidth%, %lHelpTextLead%

Gui, 2:Font, s8 w600, Verdana
Gui, 2:Add, Tab2, vf_intHelpTab w640 h350 AltSubmit, %A_Space%%lHelpTabGettingStarted% | %lHelpTabAddingFavorite% | %lHelpTabTitlesTipsAndTricks%%A_Space%

; ### REVIEW Hotkeys: 1) PopupHotkeyMouse 2) PopupHotkeyNewMouse 3) PopupHotkeyKeyboard 4) PopupHotkeyNewKeyboard
; 5) SettingsHotkey 6) FoldersInExplorerHotkey 7) GroupsHotkey 8) RecentsHotkey 9) ClipboardHotkey 10) CopyLocationHotkey
Gui, 2:Font, s8 w400, Verdana
Gui, 2:Tab, 1
Gui, 2:Add, Link, w%intWidth%, % L(lHelpText1, Hotkey2Text(strModifiers1, strMouseButton1, strOptionsKey1), Hotkey2Text(strModifiers3, strMouseButton3, strOptionsKey3))
Gui, 2:Add, Link, w%intWidth%, % lHelpText2
Gui, 2:Add, Button, vf_btnNext1 gNextHelpButtonClicked, %lDialogTabNext%
GuiCenterButtons(L(lHelpTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnNext1")

Gui, 2:Tab, 2
Gui, 2:Add, Link, w%intWidth%, % L(lHelpText3, Hotkey2Text(strModifiers1, strMouseButton1, strOptionsKey1), Hotkey2Text(strModifiers3, strMouseButton3, strOptionsKey3))
Gui, 2:Add, Link, w%intWidth%, % L(lHelpText4, Hotkey2Text(strModifiers5, strMouseButton5, strOptionsKey5))
Gui, 2:Add, Button, vf_btnNext2 gNextHelpButtonClicked, %lDialogTabNext%
GuiCenterButtons(L(lHelpTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnNext2")

Gui, 2:Tab, 3
Gui, 2:Add, Link, w%intWidth%, % L(lHelpText5
	, Hotkey2Text(strModifiers2, strMouseButton2, strOptionsKey2)
	, Hotkey2Text(strModifiers4, strMouseButton4, strOptionsKey4)
	, Hotkey2Text(strModifiers8, strMouseButton8, strOptionsKey8)
	, Hotkey2Text(strModifiers6, strMouseButton6, strOptionsKey6)
	, Hotkey2Text(strModifiers7, strMouseButton7, strOptionsKey7)
	, Hotkey2Text(strModifiers9, strMouseButton9, strOptionsKey9)
	, Hotkey2Text(strModifiers10, strMouseButton10, strOptionsKey10))
Gui, 2:Add, Link, w%intWidth%, % lHelpText6

Gui, 2:Tab

GuiControlGet, arrTabPos, Pos, f_intHelpTab
Gui, 2:Add, Button, % "x180 y" . arrTabPosY + arrTabPosH + 10. " vf_btnHelpDonate gGuiDonate", %lDonateButton%
Gui, 2:Add, Button, x+80 yp g2GuiClose vf_btnHelpClose, %lGui2Close%
GuiCenterButtons(L(lHelpTitle, g_strAppNameText, g_strAppVersion), 10, 5, 20, "f_btnHelpDonate", "f_btnHelpClose")

GuiControl, Focus, btnHelpClose
Gui, 2:Show, AutoSize Center
Gui, 1:+Disabled

return
;------------------------------------------------------------


;------------------------------------------------------------
NextHelpButtonClicked:
;------------------------------------------------------------

Gui, 2:Submit, NoHide

GuiControl, Choose, f_intHelpTab, % f_intHelpTab + 1 ; f_intHelpTab is number of current tab

return
;------------------------------------------------------------



;========================================================================================================================
; END OF ABOUT-DONATE-HELP
;========================================================================================================================



;========================================================================================================================
!_080_THIRD-PARTY:
return
;========================================================================================================================


;------------------------------------------------------------
RunDOpusRt(strCommand, strLocation := "", strParam := "")
; put A_Space at the beginning of strParam if required - some param (like ",paths") must have no space 
;------------------------------------------------------------
{
	global g_strDirectoryOpusRtPath
	
	if FileExist(g_strDirectoryOpusRtPath)
		Run, % """" . g_strDirectoryOpusRtPath . """ " . strCommand . " """ . strLocation . """" . strParam
}
;------------------------------------------------------------


;------------------------------------------------------------
CheckDirectoryOpus:
;------------------------------------------------------------

g_strCheckDirectoryOpusPath := A_ProgramFiles . "\GPSoftware\Directory Opus\dopus.exe"

if FileExist(g_strCheckDirectoryOpusPath)
{
	MsgBox, 52, %g_strAppNameText%, % L(lDialogThirdPartyDetected, g_strAppNameText, "Directory Opus")
	IfMsgBox, No
		g_strDirectoryOpusPath := "NO"
	else
	{
		g_strDirectoryOpusPath := g_strCheckDirectoryOpusPath
		Gosub, SetDOpusRt
	}
	g_blnUseDirectoryOpus := (g_strDirectoryOpusPath <> "NO")
	IniWrite, %g_strDirectoryOpusPath%, %g_strIniFile%, Global, DirectoryOpusPath
	g_blnDirectoryOpusUseTabs := 1
	IniWrite, %g_blnDirectoryOpusUseTabs%, %g_strIniFile%, Global, DirectoryOpusUseTabs
	; g_strDirectoryOpusNewTabOrWindow will contain "NEWTAB" to open in a new tab if DirectoryOpusUseTabs is 1 (default) or "NEW" to open in a new lister
	g_strDirectoryOpusNewTabOrWindow := "NEWTAB"
}

return
;------------------------------------------------------------


;------------------------------------------------------------
SetDOpusRt:
;------------------------------------------------------------

IniRead, g_blnDirectoryOpusUseTabs, %g_strIniFile%, Global, DirectoryOpusUseTabs, 1 ; should be intialized here but true by default for safety
if (g_blnDirectoryOpusUseTabs)
	g_strDirectoryOpusNewTabOrWindow := "NEWTAB" ; open new folder in a new tab
else
	g_strDirectoryOpusNewTabOrWindow := "NEW" ; open new folder in a new lister

g_strDOpusTempFilePath := g_strTempDir . "\dopus-list.txt"
StringReplace, g_strDirectoryOpusRtPath, g_strDirectoryOpusPath, \dopus.exe, \dopusrt.exe

; additional icon for Directory Opus
g_objIconsFile["DirectoryOpus"] := g_strDirectoryOpusPath
g_objIconsIndex["DirectoryOpus"] := 1

return
;------------------------------------------------------------


;------------------------------------------------------------
CheckTotalCommander:
;------------------------------------------------------------

strCheckTotalCommanderPath := GetTotalCommanderPath()

if FileExist(strCheckTotalCommanderPath)
{
	MsgBox, 52, %g_strAppNameText%, % L(lDialogThirdPartyDetected, g_strAppNameText, "Total Commander")
	IfMsgBox, No
		g_strTotalCommanderPath := "NO"
	else
	{
		g_strTotalCommanderPath := strCheckTotalCommanderPath
		Gosub, SetTCCommand
	}
	g_blnUseTotalCommander := (g_strTotalCommanderPath <> "NO")
	IniWrite, %g_strTotalCommanderPath%, %g_strIniFile%, Global, TotalCommanderPath
	g_blnTotalCommanderUseTabs := 1
	IniWrite, %g_blnTotalCommanderUseTabs%, %g_strIniFile%, Global, TotalCommanderUseTabs
	; g_strTotalCommanderNewTabOrWindow will contain "/O /T" to open in a new tab if TotalCommanderUseTabs is 1 (default) or "/N" to open in a new file list
	g_strTotalCommanderNewTabOrWindow := "/O /T"
}

strCheckTotalCommanderPath := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
GetTotalCommanderPath()
;------------------------------------------------------------
{
	RegRead, strPath, HKEY_CURRENT_USER, Software\Ghisler\Total Commander\, InstallDir
	If !StrLen(strPath)
		RegRead, strPath, HKEY_LOCAL_MACHINE, Software\Ghisler\Total Commander\, InstallDir

	if FileExist(strPath . "\TOTALCMD64.EXE")
		strPath := strPath . "\TOTALCMD64.EXE"
	else
		strPath := strPath . "\TOTALCMD.EXE"
	return strPath
}
;------------------------------------------------------------


;------------------------------------------------------------
SetTCCommand:
;------------------------------------------------------------

IniRead, g_blnTotalCommanderUseTabs, %g_strIniFile%, Global, TotalCommanderUseTabs, 1 ; should be intialized here but true by default for safety
if (g_blnTotalCommanderUseTabs)
	g_strTotalCommanderNewTabOrWindow := "/O /T" ; open new folder in a new tab
else
	g_strTotalCommanderNewTabOrWindow := "/N" ; open new folder in a new window (TC instance)

; additional icon for TotalCommander
g_objIconsFile["TotalCommander"] := g_strTotalCommanderPath
g_objIconsIndex["TotalCommander"] := 1

return
;------------------------------------------------------------


;------------------------------------------------------------
CheckFPconnect:
;------------------------------------------------------------

strCheckFPconnectPath := A_ScriptDir . "\FPconnect\FPconnect.exe"

if FileExist(strCheckFPconnectPath)
{
	MsgBox, 52, %g_strAppNameText%, % L(lDialogThirdPartyDetected, g_strAppNameText, "FPconnect")
	IfMsgBox, No
		g_strFPconnectPath := "NO"
	else
	{
		g_strFPconnectPath := strCheckFPconnectPath
		Gosub, SetFPconnect
	}
	g_blnUseFPconnect := (g_strFPconnectPath <> "NO")
	IniWrite, %g_strFPconnectPath%, %g_strIniFile%, Global, FPconnectPath
}

strCheckFPconnectPath := ""

return
;------------------------------------------------------------


;------------------------------------------------------------
SetFPconnect:
;------------------------------------------------------------

StringTrimRight, strFPconnectIniPath, g_strFPconnectPath, 4
strFPconnectIniPath := strFPconnectIniPath . ".ini"

IniRead, strFPconnectAppPathFilename, %strFPconnectIniPath%, Options, AppPath, %A_Space% ; empty by default
g_blnUseFPconnect := FileExist(EnvVars(strFPconnectAppPathFilename))

IniRead, strFPconnectTargetPathFilename, %strFPconnectIniPath%, Options, TargetPath, %A_Space% ; empty by default

if (g_blnUseFPconnect)
{
	strFPconnectAppPathFilename := EnvVars(strFPconnectAppPathFilename)
	SplitPath, strFPconnectAppPathFilename, g_strFPconnectAppFilename
	strFPconnectTargetPathFilename := EnvVars(strFPconnectTargetPathFilename)
	SplitPath, strFPconnectTargetPathFilename, g_strFPconnectTargetFilename
}
else
	Oops(lOopsWrongFPconnectAppPathFilename, g_strFPconnectPath, strFPconnectIniPath)

strFPconnectAppPathFilename := ""
strFPconnectTargetPathFilename := ""

return
;------------------------------------------------------------


;========================================================================================================================
; END OF THIRD-PARTY
;========================================================================================================================



;========================================================================================================================
!_090_VARIOUS_FUNCTIONS:
return
;========================================================================================================================

;------------------------------------------------
L(strMessage, objVariables*)
;------------------------------------------------
{
	Loop
	{
		if InStr(strMessage, "~" . A_Index . "~")
			StringReplace, strMessage, strMessage, ~%A_Index%~, % objVariables[A_Index], A
 		else
			break
	}
	
	return strMessage
}
;------------------------------------------------


;------------------------------------------------
Oops(strMessage, objVariables*)
;------------------------------------------------
{
	global g_strAppNameText
	global g_strAppVersion
	
	Gui, 1:+OwnDialogs
	MsgBox, 48, % L(lOopsTitle, g_strAppNameText, g_strAppVersion), % L(strMessage, objVariables*)
}
; ------------------------------------------------


;------------------------------------------------------------
OSVersionIsWorkstation()
;------------------------------------------------------------
{
	return (GetOSVersionInfo() and (GetOSVersionInfo().ProductType = 1))
}
;------------------------------------------------------------


;------------------------------------------------------------
GetOSVersionInfo()
; by shajul (http://www.autohotkey.com/board/topic/54639-getosversion/?p=414249)
; reference: http://msdn.microsoft.com/en-ca/library/windows/desktop/ms724833(v=vs.85).aspx
;------------------------------------------------------------
{
	static Ver

	If !Ver
	{
		VarSetCapacity(OSVer, 284, 0)
		NumPut(284, OSVer, 0, "UInt")
		If !DllCall("GetVersionExW", "Ptr", &OSVer)
		   return 0 ; GetSysErrorText(A_LastError)
		Ver := Object()
		Ver.MajorVersion      := NumGet(OSVer, 4, "UInt")
		Ver.MinorVersion      := NumGet(OSVer, 8, "UInt")
		Ver.BuildNumber       := NumGet(OSVer, 12, "UInt")
		Ver.PlatformId        := NumGet(OSVer, 16, "UInt")
		Ver.ServicePackString := StrGet(&OSVer+20, 128, "UTF-16")
		Ver.ServicePackMajor  := NumGet(OSVer, 276, "UShort")
		Ver.ServicePackMinor  := NumGet(OSVer, 278, "UShort")
		Ver.SuiteMask         := NumGet(OSVer, 280, "UShort")
		Ver.ProductType       := NumGet(OSVer, 282, "UChar") ; 1 = VER_NT_WORKSTATION, 2 = VER_NT_DOMAIN_CONTROLLER, 3 = VER_NT_SERVER
		Ver.EasyVersion       := Ver.MajorVersion . "." . Ver.MinorVersion . "." . Ver.BuildNumber
	}
	return Ver
}
;------------------------------------------------------------


;------------------------------------------------------------
SplitHotkey(strHotkey, ByRef strModifiers, ByRef strKey, ByRef strMouseButton, ByRef strMouseButtonsWithDefault)
;------------------------------------------------------------
{
	; safer that declaring individual variables (see "Common source of confusion" in https://www.autohotkey.com/docs/Functions.htm#Locals)
	global

	if (strHotkey = "None") ; do not compare with lDialogMouseNone because it is translated
	{
		strModifiers := ""
		strKey := ""
		strMouseButton := "None" ; do not use lDialogMouseNone because it is translated
		StringReplace, strMouseButtonsWithDefault, lDialogMouseButtonsText, % lDialogMouseNone . "|", % lDialogMouseNone . "||" ; use lDialogMouseNone because this is displayed
	}
	else 
	{
		SplitModifiersFromKey(strHotkey, strModifiers, strKey)

		if InStr(g_strMouseButtons, "|" . strKey . "|") ;  we have a mouse button
		{
			strMouseButton := strKey
			strKey := ""
			StringReplace, strMouseButtonsWithDefault, lDialogMouseButtonsText, % GetText4MouseButton(strMouseButton) . "|", % GetText4MouseButton(strMouseButton) . "||" ; with default value
		}
		else ; we have a key
			strMouseButtonsWithDefault := lDialogMouseButtonsText ; no default value
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
Hotkey2Text(strModifiers, strMouseButton, strKey, blnShort := false)
;------------------------------------------------------------
{
	if (strMouseButton = "None") ; do not compare with lDialogNone because it is translated
		or !StrLen(strModifiers . strMouseButton . strKey) ; if all parameters are empty
		str := lDialogMouseNone ; use lDialogMouseNone because this is displayed
	else
	{
		str := ""
		loop, parse, strModifiers
		{
			if (A_LoopField = "!")
				str := str . lDialogAlt . "+"
			if (A_LoopField = "^")
				str := str . (blnShort ? lDialogCtrlShort : lDialogCtrl) . "+"
			if (A_LoopField = "+")
				str := str . lDialogShift . "+"
			if (A_LoopField = "#")
				str := str . (blnShort ? lDialogWinShort : lDialogWin) . "+"
		}
		if StrLen(strMouseButton)
			str := str . GetText4MouseButton(strMouseButton)
		if StrLen(strKey)
		{
			StringUpper, strKey, strKey
			str := str . strKey
		}
	}

	return str
}
;------------------------------------------------------------


;------------------------------------------------------------
GetText4MouseButton(strSource)
; Returns the string in g_arrMouseButtonsText at the same position of strSource in g_arrMouseButtons
;------------------------------------------------------------
{
	; safer that declaring individual variables (see "Common source of confusion" in https://www.autohotkey.com/docs/Functions.htm#Locals)
	global

	loop, %g_arrMouseButtons0%
	{
		if (strSource = g_arrMouseButtons%A_Index%)
			return g_arrMouseButtonsText%A_Index%
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
GetMouseButton4Text(strSource)
; Returns the string in g_arrMouseButtons at the same position of strSource in g_arrMouseButtonsText
;------------------------------------------------------------
{
	global

	loop, %g_arrMouseButtonsText0%
		if (strSource = g_arrMouseButtonsText%A_Index%)
			return g_arrMouseButtons%A_Index%
}
;------------------------------------------------------------


;------------------------------------------------------------
SplitModifiersFromKey(strHotkey, ByRef strModifiers, ByRef strKey)
;------------------------------------------------------------
{
	intModifiersEnd := GetFirstNotModifier(strHotkey)
	StringLeft, strModifiers, strHotkey, %intModifiersEnd%
	StringMid, strKey, strHotkey, % (intModifiersEnd + 1)
}
;------------------------------------------------------------


;------------------------------------------------------------
GetFirstNotModifier(strHotkey)
;------------------------------------------------------------
{
	intPos := 0
	loop, Parse, strHotkey
		if (A_LoopField = "^") or (A_LoopField = "!") or (A_LoopField = "+") or (A_LoopField = "#")
			intPos := intPos + 1
		else
			return intPos
	return intPos
}
;------------------------------------------------------------


;------------------------------------------------------------
EnvVars(str)
; from Lexikos http://www.autohotkey.com/board/topic/40115-func-envvars-replace-environment-variables-in-text/#entry310601
;------------------------------------------------------------
{
    if sz:=DllCall("ExpandEnvironmentStrings", "uint", &str
                    , "uint", 0, "uint", 0)
    {
        VarSetCapacity(dst, A_IsUnicode ? sz*2:sz)
        if DllCall("ExpandEnvironmentStrings", "uint", &str
                    , "str", dst, "uint", sz)
            return dst
    }
    return src
}
;------------------------------------------------------------


;------------------------------------------------
Diag(strName, strData)
;------------------------------------------------
{
	global g_strDiagFile
	
	FormatTime, strNow, %A_Now%, yyyyMMdd@HH:mm:ss
	loop
	{
		FileAppend, %strNow%.%A_MSec%`t%strName%`t%strData%`n, %g_strDiagFile%
		if ErrorLevel
			Sleep, 20
	}
	until !ErrorLevel or (A_Index > 50) ; after 1 second (20ms x 50), we have a problem
}
;------------------------------------------------


;------------------------------------------------------------
ParseIconResource(strIconResource, ByRef strIconFile, ByRef intIconIndex, strDefaultType := "")
;------------------------------------------------------------
{
	global g_objIconsFile ; ok
	global g_objIconsIndex ; ok
	
	if !StrLen(strDefaultType)
		strDefaultType := "iconUnknown"
	
	if StrLen(strIconResource)
		If InStr(strIconResource, ",") ; this is icongroup files
		{
			intIconResourceCommaPosition := InStr(strIconResource, ",", , 0) ; search reverse
			StringLeft, strIconFile, strIconResource, % intIconResourceCommaPosition - 1
			StringRight, intIconIndex, strIconResource, % StrLen(strIconResource) - intIconResourceCommaPosition
		}
		else
		{
			strIconFile := strIconResource
			intIconIndex := 1
		}
	else
	{
		strIconFile := g_objIconsFile[strDefaultType]
		intIconIndex := g_objIconsIndex[strDefaultType]
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
GetIcon4Location(strLocation, ByRef strDefaultIcon, ByRef intDefaultIcon, blnRadioApplication := false)
; get icon, extract from kiu http://www.autohotkey.com/board/topic/8616-kiu-icons-manager-quickly-change-icon-files/
;------------------------------------------------------------
{
	global g_blnDiagMode
	global g_objIconsFile
	global g_objIconsIndex
	
	if !StrLen(strLocation)
	{
		if (blnRadioApplication)
		{
			strDefaultIcon := g_objIconsFile["iconApplication"]
			intDefaultIcon := g_objIconsIndex["iconApplication"]
		}
		else
		{
			strDefaultIcon := g_objIconsFile["iconUnknown"]
			intDefaultIcon := g_objIconsIndex["iconUnknown"]
		}
		return
	}
	
	SplitPath, strLocation, , , strExtension
	RegRead, strHKeyClassRoot, HKEY_CLASSES_ROOT, .%strExtension%
	RegRead, strRegistryIconResource, HKEY_CLASSES_ROOT, %strHKeyClassRoot%\DefaultIcon
	
	if (g_blnDiagMode)
	{
		Diag("BuildOneMenuIcon", strLocation)
		Diag("strHKeyClassRoot", strHKeyClassRoot)
		Diag("strRegistryIconResource", strRegistryIconResource)
	}
	
	if (strRegistryIconResource = "%1") ; use the file itself (for executable)
	{
		strDefaultIcon := strLocation
		intDefaultIcon := 1
		return
	}
	
	if !StrLen(strHKeyClassRoot)
	{
		strDefaultIcon := g_objIconsFile["iconUnknown"]
		intDefaultIcon := g_objIconsIndex["iconUnknown"]
	}
	else
		ParseIconResource(strRegistryIconResource, strDefaultIcon, intDefaultIcon)

	if (g_blnDiagMode)
	{
		Diag("strDefaultIcon", strDefaultIcon)
		Diag("intDefaultIcon", intDefaultIcon)
	}
}
;------------------------------------------------------------


;------------------------------------------------------------
GuiCenterButtons(strWindow, intInsideHorizontalMargin := 10, intInsideVerticalMargin := 0, intDistanceBetweenButtons := 20, arrControls*)
; This is a variadic function. See: http://ahkscript.org/docs/Functions.htm#Variadic
;------------------------------------------------------------
{
	Gui, Show, Hide ; why?
	WinGetPos, , , intWidth, , %strWindow%

	intMaxControlWidth := 0
	intMaxControlHeight := 0
	for intIndex, strControl in arrControls
	{
		GuiControlGet, arrControlPos, Pos, %strControl%
		if (arrControlPosW > intMaxControlWidth)
			intMaxControlWidth := arrControlPosW
		if (arrControlPosH > intMaxControlHeight)
			intMaxControlHeight := arrControlPosH
	}
	
	intMaxControlWidth := intMaxControlWidth + intInsideHorizontalMargin
	intButtonsWidth := (arrControls.MaxIndex() * intMaxControlWidth) + ((arrControls.MaxIndex()  - 1) * intDistanceBetweenButtons)
	intLeftMargin := (intWidth - intButtonsWidth) // 2

	for intIndex, strControl in arrControls
		GuiControl, Move, %strControl%
			, % "x" . intLeftMargin + ((intIndex - 1) * intMaxControlWidth) + ((intIndex - 1) * intDistanceBetweenButtons)
			. " w" . intMaxControlWidth
			. " h" . intMaxControlHeight + intInsideVerticalMargin
}
;------------------------------------------------------------


;------------------------------------------------------------
RecursiveBuildMenuTreeDropDown(objMenu, strDefaultMenuName, strSkipMenuName := "")
; recursive function
;------------------------------------------------------------
{
	strList := objMenu.MenuPath
	if (objMenu.MenuPath = strDefaultMenuName)
		strList .= "|" ; default value

	Loop, % objMenu.MaxIndex()
		if InStr("Menu|Group", objMenu[A_Index].FavoriteType) ; this is a menu or a group
			if (objMenu[A_Index].Submenu.MenuPath <> strSkipMenuName) ; skip to avoid moving a submenu under itself (in GuiEditFavorite)
				strList .= "|" . RecursiveBuildMenuTreeDropDown(objMenu[A_Index].Submenu, strDefaultMenuName, strSkipMenuName) ; recursive call
	return strList
}
;------------------------------------------------------------


;------------------------------------------------------------
LocationIsDocument(strLocation)
;------------------------------------------------------------
{
    FileGetAttrib, strAttributes, %strLocation%
    return !InStr(strAttributes, "D") ; not a folder
}
;------------------------------------------------------------


;------------------------------------------------------------
GetDeepestFolderName(strLocation)
;------------------------------------------------------------
{
	SplitPath, strLocation, , , , strDeepestName, strDrive
	if !StrLen(strDeepestName) ; we are probably at the root of a drive
		return strDrive
	else
		return strDeepestName
}
;------------------------------------------------------------


;------------------------------------------------------------
GetDeepestMenuPath(strPath)
;------------------------------------------------------------
{
	global g_strMenuPathSeparator ; only used for menu, not for group
	
	return Trim(SubStr(strPath, InStr(strPath, g_strMenuPathSeparator, , 0) + 1, 9999))
}
;------------------------------------------------------------


;------------------------------------------------------------
CollectRunningApplications(strDefaultPath)
;------------------------------------------------------------
{
	objApps := Object()

	Winget, strIDs, list
	
	Loop, %strIDs%
	{
		WinGet, strPath, ProcessPath, % "ahk_id " . strIDs%A_index%
		if !objApps.HasKey(strPath)
			objApps.Insert(strPath, "")
	}
	for strPath in objApps
	{
		strPaths .= strPath . "|"
		if (strPath = strDefaultPath)
			strPaths .= "|"
	}

	return strPaths
}
;------------------------------------------------------------


;------------------------------------------------------------
IsColumnBreak(strMenuName)
;------------------------------------------------------------
{
	global g_strGuiMenuColumnBreak

	return (SubStr(Trim(strMenuName), 1, StrLen(g_strGuiMenuColumnBreak)) = g_strGuiMenuColumnBreak)
}
;------------------------------------------------------------


;------------------------------------------------------------
ReplaceAllInString(strThis, strFrom, strTo)
;------------------------------------------------------------
{
	StringReplace, strThis, strThis, %strFrom%, %strTo%, A
	return strThis
}
;------------------------------------------------------------


;------------------------------------------------------------
Url2Var(strUrl)
;------------------------------------------------------------
{
	objWebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	/*
	if (A_LastError)
		; an error occurred during ComObjCreate (A_LastError probably is E_UNEXPECTED = -2147418113 #0x8000FFFFL)
		BUT DO NOT ABORT because the following commands will be executed even if an error occurred in ComObjCreate (!)
	*/
	objWebRequest.Open("GET", strUrl)
	objWebRequest.Send()

	Return objWebRequest.ResponseText()
}
;------------------------------------------------------------


;------------------------------------------------------------
NameIsInObject(strName, obj)
;------------------------------------------------------------
{
	loop, % obj.MaxIndex()
		if (strName = obj[A_Index].Name)
			return true
		
	return false
}
;------------------------------------------------------------


;------------------------------------------------
UriDecode(str)
; by polyethene
; http://www.autohotkey.com/board/topic/17367-url-encoding-and-decoding-of-special-characters/?p=112822
;------------------------------------------------
{
	Loop
		If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
			StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
		Else
			Break
	return str
}
;------------------------------------------------



;========================================================================================================================
; END OF VARIOUS_FUNCTIONS
;========================================================================================================================

;========================================================================================================================
!_095_ONMESSAGE_FUNCTIONS:
return
;========================================================================================================================


;------------------------------------------------
WM_MOUSEMOVE(wParam, lParam)
; "hook" for image buttons cursor
; see http://www.autohotkey.com/board/topic/70261-gui-buttons-hover-cant-change-cursor-to-hand/
;------------------------------------------------
{
	Global objCursor
	Global lGuiFullTitle

	WinGetTitle, strCurrentWindow, A
	if (strCurrentWindow <> lGuiFullTitle)
		return

	MouseGetPos, , , , strControl ; Static1, StaticN, Button1, ButtonN
	if InStr(strControl, "Static")
	{
		StringReplace, intControl, strControl, Static
		; 3-23, 25-26
		if (intControl < 3) or (intControl = 24) or (intControl > 26)
			return
	}
	else if !InStr(strControl, "Button")
		return

	DllCall("SetCursor", "UInt", objCursor)

	return
}
;------------------------------------------------


;------------------------------------------------------------
WM_LBUTTONDBLCLK(wParam, lParam, msg, hwnd)
; To prevent double-click on image static controls to copy their path to the clipboard
; see http://www.autohotkey.com/board/topic/94962-doubleclick-on-gui-pictures-puts-their-path-in-your-clipboard/#entry682595
;------------------------------------------------------------
{
    WinGetClass class, ahk_id %hwnd%
    if (class = "Static") {
        if !A_Gui
            return 0  ; Just prevent Clipboard change.
        ; Send a WM_COMMAND message to the Gui to trigger the control's g-label.
        Gui +LastFound
        id := DllCall("GetDlgCtrlID", "ptr", hwnd) ; Requires AutoHotkey v1.1.
        static STN_DBLCLK := 1
        PostMessage 0x111, id | (STN_DBLCLK << 16), hwnd
        ; Return a value to prevent the default handling of this message.
        return 0
    }
}
;------------------------------------------------------------


;------------------------------------------------------------
AHK_NOTIFYICON(wParam, lParam) 
; Adapted from Lexikos http://www.autohotkey.com/board/topic/11250-mouseover-trayicon-triggering-an-event/#entry153388
; To popup menu when left click on the tray icon - See the OnMessage command in the init section
;------------------------------------------------------------
{
	global blnClickOnTrayIcon
	
	if (lParam = 0x202) ; WM_LBUTTONUP
	{
		blnClickOnTrayIcon := 1
		SetTimer, LaunchHotkeyMouse, -1
		return 0
	}
} 
;------------------------------------------------------------


