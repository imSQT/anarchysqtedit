#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, Mouse, Relative
CoordMode, Pixel, Relative
DetectHiddenWindows, On
DetectHiddenText, On
SetBatchLines, -1

#Include, Modules\chatmodule.ahk
#Include, Modules\humanclick.ahk
#Include, Modules\randomizer.ahk
#Include, Modules\Teemo.ahk
#Include, Modules\Yuumi.ahk
#Include, Modules\Taric.ahk
#Include, Modules\Sona.ahk
#Include, Modules\Soraka.ahk



StdOutToVar(cmd) 
{
	DllCall("CreatePipe", "PtrP", hReadPipe, "PtrP", hWritePipe, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hWritePipe, "UInt", 1, "UInt", 1)

	VarSetCapacity(PROCESS_INFORMATION, (A_PtrSize == 4 ? 16 : 24), 0)    ; http://goo.gl/dymEhJ
	cbSize := VarSetCapacity(STARTUPINFO, (A_PtrSize == 4 ? 68 : 104), 0) ; http://goo.gl/QiHqq9
	NumPut(cbSize, STARTUPINFO, 0, "UInt")                                ; cbSize
	NumPut(0x100, STARTUPINFO, (A_PtrSize == 4 ? 44 : 60), "UInt")        ; dwFlags
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 60 : 88), "Ptr")    ; hStdOutput
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 64 : 96), "Ptr")    ; hStdError
	
	if !DllCall(
	(Join Q C
		"CreateProcess",             ; http://goo.gl/9y0gw
		"Ptr",  0,                   ; lpApplicationName
		"Ptr",  &cmd,                ; lpCommandLine
		"Ptr",  0,                   ; lpProcessAttributes
		"Ptr",  0,                   ; lpThreadAttributes
		"UInt", true,                ; bInheritHandles
		"UInt", 0x08000000,          ; dwCreationFlags
		"Ptr",  0,                   ; lpEnvironment
		"Ptr",  0,                   ; lpCurrentDirectory
		"Ptr",  &STARTUPINFO,        ; lpStartupInfo
		"Ptr",  &PROCESS_INFORMATION ; lpProcessInformation
	)) {
		DllCall("CloseHandle", "Ptr", hWritePipe)
		DllCall("CloseHandle", "Ptr", hReadPipe)
		return ""
	}

	DllCall("CloseHandle", "Ptr", hWritePipe)
	VarSetCapacity(buffer, 4096, 0)
	while DllCall("ReadFile", "Ptr", hReadPipe, "Ptr", &buffer, "UInt", 4096, "UIntP", dwRead, "Ptr", 0)
		sOutput .= StrGet(&buffer, dwRead, "CP0")

	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, 0))         ; hProcess
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize)) ; hThread
	DllCall("CloseHandle", "Ptr", hReadPipe)
	return sOutput
}


TeamCheck()
{
    strStdOut:=StdOutToVar("curl --insecure https://127.0.0.1:2999/liveclientdata/activeplayer")
	namePos := InStr(strStdOut, "summonerName" , CaseSensitive := true, StartingPos := 1, Occurrence := 1)
    offset=0
    while (char!="""")
    {
        offset:=offset+1
        char:=SubStr(strStdOut, namePos+15+offset, 1)
    }
    nameEndPos:=namePos+offset-1
	lenght:=(nameEndPos-namepos)
	activeplayer := SubStr(strStdOut, namePos+16, lenght)

    strStdOut:=StdOutToVar("curl --insecure https://127.0.0.1:2999/liveclientdata/playerlist")
	activeplayerPos := InStr(strStdOut, activeplayer , CaseSensitive := true, StartingPos := 1, Occurrence := 1)
	teamPos := InStr(strStdOut, "team" , CaseSensitive := true, StartingPos := activeplayerPos, Occurrence := 1)
	team := SubStr(strStdOut, teamPos+8, 5)
	if team=ORDER
	{
		return 1
	}
	if team=CHAOS
	{
		return 2
	}
}

BotRecall()
{
	send b ;begin channeling recall
	loop, 32
	{
		PixelSearch, ax, bx, 65, 87, 70, 87, 0x010d07, 10, Fast RGB ;check if very low / dead
		if ErrorLevel=0
		{
			return 0 ;cancel recall
		}
		Else
		{
			sleep 260 ;continue channeling recall
		}
	}
	SleepRandom(1000)
	return 1 ;return success value
}


TimeDisplay(timemessage)
{
    if not (timemessage=0)
    {
        gametime:=timemessage
    }
    GuiControl, Panel:Text, gametime, %gametime%
    return
}


ChampionDisplay(championmessage)
{
    if not (championmessage=0)
    {
        championdisplay:=championmessage
    }
    GuiControl, Panel:Text, championdisplay, %championdisplay%
    return
}


GamestepDisplay(gamestepmessage)
{
    if not gamestepmessage=0
    {
        gamestep:=gamestepmessage
    }
    GuiControl, Panel:Text, gamestep, %gamestep%
    return
}


ChatDisplay(chatmessage)
{
    if not (chatmessage=0)
    {
        chatmessagedisplay:=chatmessage
    }
    GuiControl, Panel:Text, chatmessagedisplay, %chatmessagedisplay%
    return
}


InitGUI()
{
	Gui, Panel:Destroy
	Gui, Panel:Color,Black,000000
	Gui, Panel:Show, x-3 y-27 h1180 w1920, Console
	Gui, Panel:Font,Arial s12
	Gui, Panel:Add, Text, cWhite vgamestep w2000,Current Action: ?
	Gui, Panel:Add, Text, cWhite vstopmessagedisplay w2000, Bot stops playing after this game: No
	Gui, Panel:Add, Text, cWhite vchampiondisplay w2000,Picked Champion: ?
	Gui, Panel:Add, Text, cWhite vchatmessagedisplay w2000, Recent message sent in chat: ?
	Gui, Panel:Add, Text, cWhite vgametime w2000, Game Duration: ? Minutes
	return
}

;---------------------------------------------------------------------------------------------------------------------------------------------------------------

if not FileExist("config.ini")
{
	msgbox,16,,No config.ini file found, is it named "config.ini"? If it is missing, please reinstall the bot!
	ExitApp
}


start:
IniRead, LeagueConfigFolder, config.ini, section5, LeagueConfigFolder
IniRead, azerty, config.ini, section1, azerty
Champ=0
global championdisplay=0
global chatmessagedisplay=0
global gamestep=0
global gametime=0
Gui, Destroy
Gui, Add, Picture, w325 h102, Images\Logo.png
Gui, Add, Text,, Select AI - Apply settings before the game window opens!
Gui, Add, Radio, vChampion, Sona
Gui, Add, Radio,, Teemo
Gui, Add, Radio,, Taric
Gui, Add, Radio,, Yuumi
Gui, Add, Radio,, Soraka

Gui, Add, Text, y+20 xm+5, League of Legends config folder: `nPlease make a backup of your old config folder before proceeding!
Gui, Add, Text,, %LeagueConfigFolder%
Gui, Add, Button, yp-5 x+5 default, Change Folder

Gui, Add, CheckBox, y+12 xm vazerty, AZERTY Keyboard
GuiControl,, azerty, %azerty%

Gui, Add, Button, default xm y+20, Start playing
Gui, Add, Button, default yp x+5, Apply Bot Settings

Gui, Show
return

ButtonChangeFolder:
FileSelectFolder, OutputVar, , 3
if OutputVar =
    MsgBox, 64,, Not a valid folder!
else
    IniWrite, %OutputVar%, config.ini, section5, LeagueConfigFolder
Gui, Submit
Reload
return

ButtonApplyBotSettings:
Gui, Submit
IniWrite, %azerty%, config.ini, section1, azerty
IniRead, LeagueConfigFolder, config.ini, section5, LeagueConfigFolder
IniRead, azertymode, config.ini, section1, azerty
if azertymode=0
{
	FileCopyDir, Config, %LeagueConfigFolder%, 1
	if ErrorLevel=1
	{
		msgbox, Error while copying config folder, make sure you select the path where your League of Legends is installed!
	}
	Else
	{
		msgbox, League Settings applied
	}
}
if azertymode=1
{
	FileCopyDir, ConfigAZERTY, %LeagueConfigFolder%, 1
	if ErrorLevel=1
	{
		msgbox, Error while copying config folder, make sure you select the path where your League of Legends is installed!
	}
	Else
	{
		msgbox, League Settings applied
	}
}
Gui, Show
return

ButtonStartplaying:
IniRead, LeagueConfigFolder, config.ini, section5, LeagueConfigFolder
IniRead, randomchat, config.ini, section4, randomchat
Settingspath:=LeagueConfigFolder "\" "Riot Games disgusting company.txt"
if not FileExist(Settingspath)
{
	msgbox, Please apply the settings first, make sure you select the correct Config folder where your League of Legends is installed!
	goto, start
}
Gui, Submit
Gui, Destroy
if Champion=0
{
	msgbox, Please select a champion to play.
	goto, start
}
if Champion=1
{
	PickedChampion=Sona
}
if Champion=2
{
	PickedChampion=Teemo
}
if Champion=3
{
	PickedChampion=Taric
}
if Champion=4
{
	PickedChampion=Yuumi
}
if Champion=5
{
	PickedChampion=Soraka
}
goto, ingame
return

GuiClose:
GuiEscape:
{
    ExitApp
}


;----------------------------------------------------------------------------------------------------------------------------------;

ingame:
global gamestep="Next action: Bot start"
global stopmessagedisplay="Bot stops playing after this game: No"
global championdisplay="Picked Champion: ?"
global chatmessagedisplay="Recent message sent in chat: ?"
global gametime="Game Duration: ? Minutes"
InitGUI()
loop
{
	WinActivate, League of Legends (TM) Client ahk_exe League of Legends.exe
	SleepRandom(250)
	CoordMode, Mouse, Screen
	mousemove, A_ScreenWidth/2, A_ScreenHeight/2
	click, Left
	CoordMode, Mouse, Relative
	PixelSearch, ci, di, 137, 0, 137, 0, 0xceae63,, Fast RGB
	if ErrorLevel=0
	{
		WinActivate, League of Legends (TM) Client ahk_exe League of Legends.exe
		break
	}
	if ErrorLevel=1
	{
		SleepRandom(5000)
	}
}
gamestart:=A_TickCount
GameStepDisplay("Ingame, playing...")
WinActivate, League of Legends (TM) Client ahk_exe League of Legends.exe
CoordMode, Pixel, Relative
CoordMode, Mouse, Relative
SleepRandom(1000)
team:=TeamCheck()
Global RecallChannel=0
ChampIndex=0
if randomchat=1
{
	SleepRandom(1500)
	ingamerandommessage()
	SleepRandom(2500)
}

InitialSpellLevel%PickedChampion%()

loop
{
	WinActivate, League of Legends (TM) Client ahk_exe League of Legends.exe
	if not WinExist("League of Legends (TM)")
	{
		goto, aftergame
	}
	TimeDisplay("Game Duration: " ingametime_m " Minutes")
	Random, Chance, 1, 2
	if (Chance=2 && ingametime_m<=20)
	{
		PixelSearch, ax, bx, 0, 0, 133, 78, 0xf2d65d,, Fast, RGB
		if ErrorLevel=0
		{
			%PickedChampion%Explore(team, ChampIndex)
		}
	}
	
	LoopCount:=LoopRandom(30)
	loop, %LoopCount%
	{
		ingametime_m:=Floor((A_TickCount-gamestart)/60000)+1
		if not WinExist("League of Legends (TM)")
		{
			goto, aftergame
		}

		if ingametime_m>=20
		{
			ChampIndex=1
		}
		PixelSearch, xx, xy, 154-ChampIndex*6, 58, 154-ChampIndex*6, 58, 0x8b8c8b, 20, Fast RGB ;check if allyX is dead
		if ErrorLevel=0
		{
			RecallChannel:=%PickedChampion%Retreat(team, RecallChannel) ;increase recall score every time the bot clicks to base to recall
			if RecallChannel>=25
			{
				RecallChannel=0
				if BotRecall()=1 ;recall after 50 clicks ~ 10 seconds of walking to base
				{
					AttemptShopping%PickedChampion%()
				}
			}
			PixelSearch, ax, bx, 65, 87, 65, 87, 0x010d07, 10, Fast RGB ;check if dead
			if ErrorLevel=0
			{
				AttemptShopping%PickedChampion%()
				SleepRandom(1200)
				if randomchat=1
				{
					SleepRandom(1500)
					ingamerandommessage()
					SleepRandom(2500)
				}
			}
			SleepRandom(100)
		}
		Else
		{
			%PickedChampion%Logic(team, ChampIndex, ingametime_m)
		}
	}
	PixelSearch, ax, bx, 0, 0, 133, 78, 0x3E0700, 5, Fast, RGB ;check for enemies on screen
	if ErrorLevel=0
	{
		%PickedChampion%Attack()
	}
}


;-------------------------------------------------------------------------------------------------------------;

aftergame:
GameStepDisplay("Finished game, waiting for user input...")
msgbox, I finished the game! Click OK if the next game loads!
sleep 500
Goto, start
return


!o::
msgbox, stopped.
ExitApp

#k::
GameStepDisplay("Paused...")
msgbox, This message appears because you paused the bot! To resume, simply close this window! I am currently in the %gamestep% section of the code.
GameStepDisplay(gamestep)
WinActivate, League of Legends ahk_exe LeagueClientUx.exe
SleepRandom(100)
WinActivate, League of Legends (TM) Client ahk_exe League of Legends.exe
SleepRandom(100)
return