' Dick Tracy 2024 by TheRocketeer84
' Mod of Vortex - Taito 1981
' IPD No. 4576 / 1981 / 4 Players
' VPX - version by JPSalas 2020, version 4.0.1

Option Explicit
Randomize

Const BallSize = 50
Const BallMass = 1

On Error Resume Next
ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the controller.vbs in order to run this table, available in the vp10 package"
On Error Goto 0

LoadVPM "01550000", "Taito.vbs", 3.26

Dim bsTrough, dtbank1, dtbank2, dtbank3, bsRightSaucer, x

Const cGameName = "Vortex"
Const UseFlexDMD = 1    ' 1 is on
Const UseSolenoids = 2
Const UseLamps = 0
Const UseGI = 0
Const UseSync = 0 'set it to 1 if the table runs too fast
Const HandleMech = 0
Const vpmhidden = 1 'hide the vpinmame window

If Table1.ShowDT = true then
    For each x in aReels
        x.Visible = 1
    Next
else
    For each x in aReels
        x.Visible = 0
    Next
end if

' Standard Sounds
Const SSolenoidOn = "fx_Solenoid"
Const SSolenoidOff = ""
Const SCoin = "fx_Coin"

'************
' Table init.
'************

Sub table1_Init
    NVramPatchLoad
    vpmInit me
    With Controller
        .GameName = cGameName
		.Games(cGameName).Settings.Value("sound") = 0 'enable the rom sound
        If Err Then MsgBox "Can't start Game" & cGameName & vbNewLine & Err.Description:Exit Sub
        .SplashInfoLine = "Vortex - Taito 1981" & vbNewLine & "VPX table by JPSalas v4.0.1"
        .HandleKeyboard = 0
        .ShowTitle = 0
        .ShowDMDOnly = 1
        .ShowFrame = 0
        .HandleMechanics = 0
        .Hidden = vpmhidden
        .Games(cGameName).Settings.Value("rol") = 0 '1= rotated display, 0= normal
        '.SetDisplayPosition 0,0, GetPlayerHWnd 'restore dmd window position
        On Error Resume Next
        Controller.SolMask(0) = 0
        vpmTimer.AddTimer 2000, "Controller.SolMask(0)=&Hffffffff'" 'ignore all solenoids - then add the Timer to renable all the solenoids after 2 seconds
        Controller.Run GetPlayerHWnd
        On Error Goto 0
    End With

    ' Nudging
    vpmNudge.TiltSwitch = 30
    vpmNudge.Sensitivity = 3
    vpmNudge.TiltObj = Array(Bumper1, Bumper2, Bumper3, LeftSlingshot, RightSlingshot)

    ' Trough
    Set bsTrough = New cvpmBallStack
    With bsTrough
        .InitSw 0, 1, 0, 0, 0, 0, 0, 0
        .InitKick BallRelease, 90, 4
        .InitExitSnd SoundFX("fx_ballrel", DOFContactors), SoundFX("fx_Solenoid", DOFContactors)
        .Balls = 1
    End With

    ' Saucers
    Set bsRightSaucer = New cvpmBallStack
    bsRightSaucer.InitSaucer sw2, 2, 220, 15
    bsRightSaucer.InitExitSnd SoundFX("fx_kicker", DOFContactors), SoundFX("fx_Solenoid", DOFContactors)
    bsRightSaucer.KickForceVar = 6

    ' Drop targets
    set dtbank1 = new cvpmdroptarget
    dtbank1.InitDrop Array(sw35, sw45, sw55, sw65, sw75), Array(35, 45, 55, 65, 75)
    dtbank1.initsnd SoundFX("fx_droptarget", DOFDropTargets), SoundFX("fx_resetdrop", DOFContactors)
    dtbank1.CreateEvents "dtBank1"

    set dtbank2 = new cvpmdroptarget
    dtbank2.InitDrop Array(sw41, sw51, sw61), Array(41, 51, 61)
    dtbank2.initsnd SoundFX("fx_droptarget", DOFDropTargets), SoundFX("fx_resetdrop", DOFContactors)
    dtbank2.CreateEvents "dtBank2"

    set dtbank3 = new cvpmdroptarget
    dtbank3.InitDrop Array(sw11, sw21, sw31), Array(11, 21, 31)
    dtbank3.initsnd SoundFX("fx_droptarget", DOFDropTargets), SoundFX("fx_resetdrop", DOFContactors)
    dtbank3.CreateEvents "dtBank3"

    ' Main Timer init
    PinMAMETimer.Interval = PinMAMEInterval
    PinMAMETimer.Enabled = 1
    RealTime.Enabled = 1

    ' Turn on Gi
    vpmtimer.addtimer 1500, "GiOn '"

    LoadLUT
	' initalise the FlexDMD display
    If UseFlexDMD Then FlexDMD_Init
End Sub

Sub table1_Paused:Controller.Pause = 1:End Sub
Sub table1_unPaused:Controller.Pause = 0:End Sub
Sub table1_exit:NVramPatchExit:Controller.stop
  If B2SOn Then 
    Controller.Pause = False
    Controller.Stop
  End If
  If UseFlexDMD then
		If Not FlexDMD is Nothing Then 
			FlexDMD.Show = False
			FlexDMD.Run = False
			FlexDMD = NULL
		End if
	End if
End Sub

PlaySound "Music",-1
PlaySound "Intro 2",-0
PlaySound "Intro",-0

'******************
' Realtime Updates
'******************

Sub RealTime_Timer
    GIUpdate
    RollingUpdate
    LeftFlipperTop.RotZ = LeftFlipper.CurrentAngle
    RightFlipperTop.RotZ = RightFlipper.CurrentAngle
End Sub

'**********
' Keys
'**********

Sub table1_KeyDown(ByVal Keycode)
    If keycode = LeftTiltKey Then Nudge 90, 5:PlaySound SoundFX("fx_nudge", 0), 0, 1, -0.1, 0.25
    If keycode = RightTiltKey Then Nudge 270, 5:PlaySound SoundFX("fx_nudge", 0), 0, 1, 0.1, 0.25
    If keycode = CenterTiltKey Then Nudge 0, 6:PlaySound SoundFX("fx_nudge", 0), 0, 1, 0, 0.25
    if keycode = rightflipperkey then controller.switch(74) = 1
    If keycode = LeftMagnaSave Then bLutActive = True: Lutbox.text = "level of darkness " & LUTImage + 1
    If keycode = RightMagnaSave Then
        If bLutActive Then NextLUT:End If
    End If
    If vpmKeyDown(keycode)Then Exit Sub
    If keycode = PlungerKey Then PlaySoundat "fx_PlungerPull", Plunger:Plunger.Pullback
End Sub

Sub table1_KeyUp(ByVal Keycode)
    If keycode = LeftMagnaSave Then bLutActive = False: LutBox.text = ""
    if keycode = rightflipperkey then controller.switch(74) = 0
    If vpmKeyUp(keycode)Then Exit Sub
    If keycode = PlungerKey Then PlaySoundAt "fx_plunger", Plunger:Plunger.Fire
End Sub

'***************************
'   LUT - Darkness control 
'***************************

Dim bLutActive, LUTImage

Sub LoadLUT
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 15:UpdateLUT:SaveLUT:Lutbox.text = "level of darkness " & LUTImage + 1:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0":GiIntensity = 1:ChangeGIIntensity 1
        Case 1:table1.ColorGradeImage = "LUT1":GiIntensity = 1.05:ChangeGIIntensity 1
        Case 2:table1.ColorGradeImage = "LUT2":GiIntensity = 1.1:ChangeGIIntensity 1
        Case 3:table1.ColorGradeImage = "LUT3":GiIntensity = 1.15:ChangeGIIntensity 1
        Case 4:table1.ColorGradeImage = "LUT4":GiIntensity = 1.2:ChangeGIIntensity 1
        Case 5:table1.ColorGradeImage = "LUT5":GiIntensity = 1.25:ChangeGIIntensity 1
        Case 6:table1.ColorGradeImage = "LUT6":GiIntensity = 1.3:ChangeGIIntensity 1
        Case 7:table1.ColorGradeImage = "LUT7":GiIntensity = 1.35:ChangeGIIntensity 1
        Case 8:table1.ColorGradeImage = "LUT8":GiIntensity = 1.4:ChangeGIIntensity 1
        Case 9:table1.ColorGradeImage = "LUT9":GiIntensity = 1.45:ChangeGIIntensity 1
        Case 10:table1.ColorGradeImage = "LUT10":GiIntensity = 1.5:ChangeGIIntensity 1
        Case 11:table1.ColorGradeImage = "LUT11":GiIntensity = 1.55:ChangeGIIntensity 1
        Case 12:table1.ColorGradeImage = "LUT12":GiIntensity = 1.6:ChangeGIIntensity 1
        Case 13:table1.ColorGradeImage = "LUT13":GiIntensity = 1.65:ChangeGIIntensity 1
        Case 14:table1.ColorGradeImage = "LUT14":GiIntensity = 1.7:ChangeGIIntensity 1
    End Select
End Sub

Dim GiIntensity
GiIntensity = 1   'used for the LUT changing to increase the GI lights when the table is darker

Sub ChangeGiIntensity(factor) 'changes the intensity scale
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = GiIntensity * factor
    Next
End Sub

'*********
' Switches
'*********

' Slings
Dim LStep, RStep

Sub LeftSlingShot_Slingshot
    PlaySoundAt SoundFX("fx_slingshot", DOFContactors), Lemk
    DOF 101, DOFPulse
    LeftSling4.Visible = 1
    Lemk.RotX = 26
    LStep = 0
    vpmTimer.PulseSw 71
    LeftSlingShot.TimerEnabled = 1
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 1:LeftSLing4.Visible = 0:LeftSLing3.Visible = 1:Lemk.RotX = 14
        Case 2:LeftSLing3.Visible = 0:LeftSLing2.Visible = 1:Lemk.RotX = 2
        Case 3:LeftSLing2.Visible = 0:Lemk.RotX = -10:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub

Sub RightSlingShot_Slingshot
    PlaySoundAt SoundFX("fx_slingshot", DOFContactors), Remk
    DOF 102, DOFPulse
    RightSling4.Visible = 1
    Remk.RotX = 26
    RStep = 0
    vpmTimer.PulseSw 64
    RightSlingShot.TimerEnabled = 1
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing4.Visible = 0:RightSLing3.Visible = 1:Remk.RotX = 14
        Case 2:RightSLing3.Visible = 0:RightSLing2.Visible = 1:Remk.RotX = 2
        Case 3:RightSLing2.Visible = 0:Remk.RotX = -10:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

' Scoring rubbers
Sub sw44_Hit:vpmTimer.PulseSw 44:PlaySoundAtBall SoundFX("fx_rubber_band", DOFDropTargets):End Sub

Sub sw54_Hit:vpmTimer.PulseSw 54:PlaySoundAtBall SoundFX("fx_rubber_band", DOFDropTargets):End Sub

' Rubber animations
Dim Rub1, Rub2

Sub rlband003_Hit:Rub1 = 1:rlband003_Timer:End Sub

Sub rlband003_Timer
    Select Case Rub1
        Case 1:r2.Visible = 0:r7.Visible = 1:rlband003.TimerEnabled = 1
        Case 2:r7.Visible = 0:r8.Visible = 1
        Case 3:r8.Visible = 0:r2.Visible = 1:rlband003.TimerEnabled = 0
    End Select
    Rub1 = Rub1 + 1
End Sub

Sub rlband008_Hit:Rub2 = 1:rlband008_Timer:End Sub
Sub rlband008_Timer
    Select Case Rub2
        Case 1:r6.Visible = 0:r9.Visible = 1:rlband008.TimerEnabled = 1
        Case 2:r9.Visible = 0:r10.Visible = 1
        Case 3:r10.Visible = 0:r6.Visible = 1:rlband008.TimerEnabled = 0
    End Select
    Rub2 = Rub2 + 1
End Sub

' Bumpers
Sub Bumper1_Hit:vpmTimer.PulseSw 3:PlaySoundAt SoundFX("fx_bumper1", DOFContactors), Bumper1:End Sub
Sub Bumper2_Hit:vpmTimer.PulseSw 13:PlaySoundAt SoundFX("fx_bumper2", DOFContactors), Bumper2:End Sub
Sub Bumper3_Hit:vpmTimer.PulseSw 23:PlaySoundAt SoundFX("fx_bumper3", DOFContactors), Bumper3:End Sub

' Drain & Saucers
Sub Drain_Hit:PlaysoundAt "fx_drain", Drain:bsTrough.AddBall Me:End Sub
Sub sw2_Hit::PlaysoundAt "BigBoyArrest", sw2:bsRightSaucer.AddBall 0:End Sub

' Rollovers
Sub sw4_Hit:Controller.Switch(4) = 1:PlaySoundAt "BlankCar", sw4:End Sub
Sub sw4_UnHit:Controller.Switch(4) = 0:End Sub

Sub sw14_Hit:Controller.Switch(14) = 1:PlaySoundAt "DickDead", sw14:End Sub
Sub sw14_UnHit:Controller.Switch(14) = 0:End Sub

Sub sw24_Hit:Controller.Switch(24) = 1:PlaySoundAt "GetBigBoy", sw24:End Sub
Sub sw24_UnHit:Controller.Switch(24) = 0:End Sub

Sub sw34_Hit:Controller.Switch(34) = 1:PlaySoundAt "Goodbye to Oxygen", sw34:End Sub
Sub sw34_UnHit:Controller.Switch(34) = 0:End Sub

Sub sw42_Hit:Controller.Switch(42) = 1:PlaySoundAt "HeyTough", sw42:End Sub
Sub sw42_UnHit:Controller.Switch(42) = 0:End Sub

Sub sw52_Hit:Controller.Switch(52) = 1:PlaySoundAt "suck_egg", sw52:End Sub
Sub sw52_UnHit:Controller.Switch(52) = 0:End Sub

Sub sw62_Hit:Controller.Switch(62) = 1:PlaySoundAt "Hi Little Fella", sw62:End Sub
Sub sw62_UnHit:Controller.Switch(62) = 0:End Sub

' Spinners
Sub Spinner1_Spin:vpmTimer.PulseSw 22:PlaySoundAt "fx_spinner", Spinner1:End Sub
Sub Spinner2_Spin:vpmTimer.PulseSw 12:PlaySoundAt "fx_spinner", Spinner2:End Sub
Sub Spinner3_Spin:vpmTimer.PulseSw 32:PlaySoundAt "fx_spinner", Spinner3:End Sub

'Targets
Sub sw33_Hit:vpmTimer.PulseSw 33:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub
Sub sw43_Hit:vpmTimer.PulseSw 43:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub
Sub sw53_Hit:vpmTimer.PulseSw 53:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub
Sub sw63_Hit:vpmTimer.PulseSw 63:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub
Sub sw73_Hit:vpmTimer.PulseSw 73:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub
Sub sw72_Hit:vpmTimer.PulseSw 72:PlaySoundAtBall SoundFX("fx_target", DOFDropTargets):End Sub

'*********
'Solenoids
'*********

SolCallback(1) = "bsTrough.SolOut"
SolCallback(2) = "bsRightSaucer.SolOut"
SolCallback(3) = "dtbank2.SolDropUp"
SolCallback(4) = "dtbank3.SolDropUp"
SolCallback(5) = "dtbank1.SolDropUp"
'SolCallback(6) = ""
SolCallback(7) = "dtbank1.SolHit 1,"
SolCallback(8) = "dtbank1.SolHit 2,"
SolCallback(9) = "dtbank1.SolHit 3,"
SolCallback(10) = "dtbank1.SolHit 4,"
SolCallback(11) = "dtbank1.SolHit 5,"

SolCallback(12) = "SolLeftGi"  'left flash effect
SolCallback(13) = "SolRightGi" 'right flash effect

SolCallback(17) = "SolGi"      '17=relay
SolCallback(18) = "vpmNudge.SolGameOn"

Sub SolGi(enabled)
    If enabled Then
        GiOff
    Else
        GiOn
    End If
End Sub

Sub SolLeftGi(enabled)
    If enabled Then
        For each x in aGiLeftLights
            x.State = 0
        Next
    Else
        For each x in aGiLeftLights
            x.State = 1
        Next
    End If
End Sub

Sub SolRightGi(enabled)
    If enabled Then
        For each x in aGiRightLights
            x.State = 0
        Next
    Else
        For each x in aGiRightLights
            x.State = 1
        Next
    End If
End Sub

'*******************
' Flipper Subs Rev3
'*******************

SolCallback(sLRFlipper) = "SolRFlipper"
SolCallback(sLLFlipper) = "SolLFlipper"

Sub SolLFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFX("fx_flipperup", DOFFlippers), LeftFlipper
        LeftFlipper.RotateToEnd
        LeftFlipperOn = 1
    Else
        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), LeftFlipper
        LeftFlipper.RotateToStart
        LeftFlipperOn = 0
    End If
End Sub

Sub SolRFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFX("fx_flipperup", DOFFlippers), RightFlipper
        RightFlipper.RotateToEnd
        RightFlipperOn = 1
    Else
        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), RightFlipper
        RightFlipper.RotateToStart
        RightFlipperOn = 0
    End If
End Sub

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.1, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.1, 0, 0, 0, AudioFade(ActiveBall)
End Sub

'*********************************************************
' Real Time Flipper adjustments - by JLouLouLou & JPSalas
'        (to enable flipper tricks) 
'*********************************************************

Dim FlipperPower
Dim FlipperElasticity
Dim SOSTorque, SOSAngle
Dim FullStrokeEOS_Torque, LiveStrokeEOS_Torque
Dim LeftFlipperOn
Dim RightFlipperOn

Dim LLiveCatchTimer
Dim RLiveCatchTimer
Dim LiveCatchSensivity

FlipperPower = 5000
FlipperElasticity = 0.8
FullStrokeEOS_Torque = 0.3 	' EOS Torque when flipper hold up ( EOS Coil is fully charged. Ampere increase due to flipper can't move or when it pushed back when "On". EOS Coil have more power )
LiveStrokeEOS_Torque = 0.2	' EOS Torque when flipper rotate to end ( When flipper move, EOS coil have less Ampere due to flipper can freely move. EOS Coil have less power )

LeftFlipper.EOSTorqueAngle = 10
RightFlipper.EOSTorqueAngle = 10

SOSTorque = 0.1
SOSAngle = 6

LiveCatchSensivity = 10

LLiveCatchTimer = 0
RLiveCatchTimer = 0

LeftFlipper.TimerInterval = 1
LeftFlipper.TimerEnabled = 1

Sub LeftFlipper_Timer 'flipper's tricks timer
'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If LeftFlipper.CurrentAngle >= LeftFlipper.StartAngle - SOSAngle Then LeftFlipper.Strength = FlipperPower * SOSTorque else LeftFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
	If LeftFlipperOn = 1 Then
		If LeftFlipper.CurrentAngle = LeftFlipper.EndAngle then
			LeftFlipper.EOSTorque = FullStrokeEOS_Torque
			LLiveCatchTimer = LLiveCatchTimer + 1
			If LLiveCatchTimer < LiveCatchSensivity Then
				LeftFlipper.Elasticity = 0
			Else
				LeftFlipper.Elasticity = FlipperElasticity
				LLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		LeftFlipper.Elasticity = FlipperElasticity
		LeftFlipper.EOSTorque = LiveStrokeEOS_Torque
		LLiveCatchTimer = 0
	End If
	

'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If RightFlipper.CurrentAngle <= RightFlipper.StartAngle + SOSAngle Then RightFlipper.Strength = FlipperPower * SOSTorque else RightFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
 	If RightFlipperOn = 1 Then
		If RightFlipper.CurrentAngle = RightFlipper.EndAngle Then
			RightFlipper.EOSTorque = FullStrokeEOS_Torque
			RLiveCatchTimer = RLiveCatchTimer + 1
			If RLiveCatchTimer < LiveCatchSensivity Then
				RightFlipper.Elasticity = 0
			Else
				RightFlipper.Elasticity = FlipperElasticity
				RLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		RightFlipper.Elasticity = FlipperElasticity
		RightFlipper.EOSTorque = LiveStrokeEOS_Torque
		RLiveCatchTimer = 0
	End If
End Sub

'*****************
'   Gi Effects
'*****************

Dim OldGiState
OldGiState = -1 'start witht he Gi off

Sub GiON
    For each x in aGiLights
        x.State = 1
    Next
End Sub

Sub GiOFF
    For each x in aGiLights
        x.State = 0
    Next
End Sub

Sub GiEffect(enabled)
    If enabled Then
        For each x in aGiLights
            x.Duration 2, 1000, 1
        Next
    End If
End Sub

Sub GIUpdate
    Dim tmp, obj
    tmp = Getballs
    If UBound(tmp) <> OldGiState Then
        OldGiState = Ubound(tmp)
        If UBound(tmp) = -1 Then
            GiOff
        Else
            GiOn
        End If
    End If
End Sub

'**********************************************************
'     JP's Flasher Fading for VPX and Vpinmame v3.0
'       (Based on Pacdude's Fading Light System)
' This is a fast fading for the Flashers in vpinmame tables
'  just 4 steps, like in Pacdude's original script.
' Included the new Modulated flashers & Lights for WPC
'**********************************************************

Dim LampState(200), FadingState(200), FlashLevel(200)

InitLamps() ' turn off the lights and flashers and reset them to the default parameters

' vpinmame Lamp & Flasher Timers

Sub LampTimer_Timer()
    Dim chgLamp, num, chg, ii
    chgLamp = Controller.ChangedLamps
    If Not IsEmpty(chgLamp)Then
        For ii = 0 To UBound(chgLamp)
            LampState(chgLamp(ii, 0)) = chgLamp(ii, 1)       'keep the real state in an array
            FadingState(chgLamp(ii, 0)) = chgLamp(ii, 1) + 3 'fading step
        Next
    End If
    UpdateLeds
    UpdateLamps
    NVramPatchKeyCheck
End Sub

Sub UpdateLamps()
    Lamp 0, li0
    Lamp 1, li1
    Lamp 10, li10
    Lampm 100, li100
    Flash 100, li100a
    Lampm 101, li101
    Flash 101, li101a
    Lamp 102, li102
    Lamp 103, li103
    Lamp 109, li109
    Lamp 11, li11
    Lamp 110, LightBumper1
    Lamp 111, LightBumper2
    Lamp 112, LightBumper3
    Lamp 113, li113
    Lamp 12, li12
    Lamp 123, li123
    Lamp 133, li133
    Lamp 143, li143
    Lamp 153, li153
    Lamp 2, li2
    Lamp 20, li20
    Lamp 21, li21
    Lamp 22, li22
    Lamp 30, li30
    Lamp 31, li31
    Lamp 32, li32
    Lamp 40, li40
    Lamp 41, li41
    Lamp 42, li42
    Lamp 50, li50
    Lamp 51, li51
    Lamp 52, li52
    Lamp 60, li60
    Lampm 61, li61
    Lampm 61, li61a
    Flashm 61, li61b
    Flash 61, li61c
    Lamp 62, li62
    Lampm 70, li70
    Flash 70, li70a
    Lampm 71, li71
    Flash 71, li71a
    Lampm 72, li72
    Flash 72, li72a
    Lamp 79, li79
    Lamp 80, li80
    Lamp 81, li81
    Lampm 82, li82
    Flash 82, li82a
    Lamp 83, li83
    Lamp 89, li89
    Lamp 90, li90
    Lamp 91, li91
    Lampm 92, li92
    Flash 92, li92a
    Lamp 93, li93
    Lampm 99, li99
    Flash 99, li99a
    'backdrop lights
    Lamp 139, li139
    Lamp 140, li140
    Lamp 141, li141
    Lamp 142, li142
    Lamp 149, li149
    Lamp 150, li150
    Lamp 151, li151
    Lamp 152, li152
End Sub

' div lamp subs

' Normal Lamp & Flasher subs

Sub InitLamps()
    Dim x
    LampTimer.Interval = 25 ' flasher fading speed
    LampTimer.Enabled = 1
    For x = 0 to 200
        LampState(x) = 0
        FadingState(x) = 3 ' used to track the fading state
        FlashLevel(x) = 0
    Next
End Sub

Sub SetLamp(nr, value) ' 0 is off, 1 is on
    FadingState(nr) = abs(value) + 3
End Sub

' Lights: used for VPX standard lights, the fading is handled by VPX itself, they are here to be able to make them work together with the flashers

Sub Lamp(nr, object)
    Select Case FadingState(nr)
        Case 4:object.state = 1:FadingState(nr) = 0
        Case 3:object.state = 0:FadingState(nr) = 0
    End Select
End Sub

Sub Lampm(nr, object) ' used for multiple lights, it doesn't change the fading state
    Select Case FadingState(nr)
        Case 4:object.state = 1
        Case 3:object.state = 0
    End Select
End Sub

' Flashers: 4 is on,3,2,1 fade steps. 0 is off

Sub Flash(nr, object)
    Select Case FadingState(nr)
        Case 4:Object.IntensityScale = 1:FadingState(nr) = 0
        Case 3:Object.IntensityScale = 0.66:FadingState(nr) = 2
        Case 2:Object.IntensityScale = 0.33:FadingState(nr) = 1
        Case 1:Object.IntensityScale = 0:FadingState(nr) = 0
    End Select
End Sub

Sub Flashm(nr, object) 'multiple flashers, it doesn't change the fading state
    Select Case FadingState(nr)
        Case 4:Object.IntensityScale = 1
        Case 3:Object.IntensityScale = 0.66
        Case 2:Object.IntensityScale = 0.33
        Case 1:Object.IntensityScale = 0
    End Select
End Sub

' Desktop Objects: Reels & texts (you may also use lights on the desktop)

' Reels

Sub Reel(nr, object)
    Select Case FadingState(nr)
        Case 4:object.SetValue 1:FadingState(nr) = 0
        Case 3:object.SetValue 2:FadingState(nr) = 2
        Case 2:object.SetValue 3:FadingState(nr) = 1
        Case 1:object.SetValue 0:FadingState(nr) = 0
    End Select
End Sub

Sub Reelm(nr, object)
    Select Case FadingState(nr)
        Case 4:object.SetValue 1
        Case 3:object.SetValue 2
        Case 2:object.SetValue 3
        Case 1:object.SetValue 0
    End Select
End Sub

'Texts

Sub Text(nr, object, message)
    Select Case FadingState(nr)
        Case 4:object.Text = message:FadingState(nr) = 0
        Case 3:object.Text = "":FadingState(nr) = 0
    End Select
End Sub

Sub Textm(nr, object, message)
    Select Case FadingState(nr)
        Case 4:object.Text = message
        Case 3:object.Text = ""
    End Select
End Sub

' Modulated Subs for the WPC tables

Sub SetModLamp(nr, level)
    FlashLevel(nr) = level / 150 'lights & flashers
End Sub

Sub LampMod(nr, object)          ' modulated lights used as flashers
    Object.IntensityScale = FlashLevel(nr)
    Object.State = 1             'in case it was off
End Sub

Sub FlashMod(nr, object)         'sets the flashlevel from the SolModCallback
    Object.IntensityScale = FlashLevel(nr)
End Sub

'Walls and mostly Primitives used as 4 step fading lights
'a,b,c,d are the images used from on to off

Sub FadeObj(nr, object, a, b, c, d)
    Select Case FadingState(nr)
        Case 4:object.image = a:FadingState(nr) = 0 'fading to off...
        Case 3:object.image = b:FadingState(nr) = 2
        Case 2:object.image = c:FadingState(nr) = 1
        Case 1:object.image = d:FadingState(nr) = 0
    End Select
End Sub

Sub FadeObjm(nr, object, a, b, c, d)
    Select Case FadingState(nr)
        Case 4:object.image = a
        Case 3:object.image = b
        Case 2:object.image = c
        Case 1:object.image = d
    End Select
End Sub

Sub NFadeObj(nr, object, a, b)
    Select Case FadingState(nr)
        Case 4:object.image = a:FadingState(nr) = 0 'off
        Case 3:object.image = b:FadingState(nr) = 0 'on
    End Select
End Sub

Sub NFadeObjm(nr, object, a, b)
    Select Case FadingState(nr)
        Case 4:object.image = a
        Case 3:object.image = b
    End Select
End Sub

'************************************
'          LEDs Display
'     Based on Scapino's LEDs
'************************************

Dim Digits(32)
Dim Patterns(11)
Dim Patterns2(11)

Patterns(0) = 0     'empty
Patterns(1) = 63    '0
Patterns(2) = 6     '1
Patterns(3) = 91    '2
Patterns(4) = 79    '3
Patterns(5) = 102   '4
Patterns(6) = 109   '5
Patterns(7) = 125   '6
Patterns(8) = 7     '7
Patterns(9) = 127   '8
Patterns(10) = 111  '9

Patterns2(0) = 128  'empty
Patterns2(1) = 191  '0
Patterns2(2) = 134  '1
Patterns2(3) = 219  '2
Patterns2(4) = 207  '3
Patterns2(5) = 230  '4
Patterns2(6) = 237  '5
Patterns2(7) = 253  '6
Patterns2(8) = 135  '7
Patterns2(9) = 255  '8
Patterns2(10) = 239 '9

'Assign 6-digit output to reels
Set Digits(0) = a0
Set Digits(1) = a1
Set Digits(2) = a2
Set Digits(3) = a3
Set Digits(4) = a4
Set Digits(5) = a5

Set Digits(6) = b0
Set Digits(7) = b1
Set Digits(8) = b2
Set Digits(9) = b3
Set Digits(10) = b4
Set Digits(11) = b5

Set Digits(12) = c0
Set Digits(13) = c1
Set Digits(14) = c2
Set Digits(15) = c3
Set Digits(16) = c4
Set Digits(17) = c5

Set Digits(18) = d0
Set Digits(19) = d1
Set Digits(20) = d2
Set Digits(21) = d3
Set Digits(22) = d4
Set Digits(23) = d5

Set Digits(24) = e0
Set Digits(25) = e1

Sub UpdateLeds
    On Error Resume Next
	Dim ChgLED,ii,num,chg,stat,obj
	ChgLED=Controller.ChangedLEDs  (&Hffffffff, &Hffffffff)
	If Not IsEmpty(ChgLED) Then
		For ii=0 To UBound(chgLED)
			num=chgLED(ii,0):chg=chgLED(ii,1):stat=chgLED(ii,2)
			If UseFlexDMD then UpdateFlexChar num, stat
			For Each obj In Digits(num)
				If chg And 1 Then obj.State=stat And 1
				chg=chg\2:stat=stat\2
			Next
		Next
		If UseFlexDMD then FlexDMDUpdate
	End If
End Sub

'************************************
' Diverse Collection Hit Sounds v3.0
'************************************

Sub aMetals_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub aMetalWires_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub aRubber_Bands_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_LongBands_Hit(idx):PlaySoundAtBall "fx_rubber_longband":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub aRubber_Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub aRubber_Pegs_Hit(idx):PlaySoundAtBall "fx_rubber_peg":End Sub
Sub aPlastics_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub aGates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v4.0
'  includes random pitch in PlaySoundAt and PlaySoundAtBall
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp > 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.2, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.2, Pitch(ActiveBall) * 10, 0, 0, AudioFade(ActiveBall)
End Sub

Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v4.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls
Const lob = 0     'number of locked balls
Const maxvel = 30 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate()
    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
        aBallShadow(b).Y = 3000
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' play the rolling sound for each ball and draw the shadow
    For b = lob to UBound(BOT)
        aBallShadow(b).X = BOT(b).X
        aBallShadow(b).Y = BOT(b).Y
        aBallShadow(b).Height = BOT(b).Z -Ballsize/2

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 50000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 10
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ <-1 and BOT(b).z <55 and BOT(b).z> 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed control
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
    Next
End Sub

'***********************
' Ball Collision Sound
'***********************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

' =============================================================================================================
'                 NVram patch for Taito do Brasil tables by Pmax65
'
' NVramPatchExit	' Must be placed before the Controler.Stop statement into the Table1_Exit Sub
' NVramPatchLoad	' Must be placed before the VPinMAME controller initialization
' NVramPatchKeyCheck' Must be placed in the lamptimer timer
' =============================================================================================================

Const GameOverLampID = 149 ' set this constant to the ID number of the game-over lamp

Dim NVramPatchCoinCnt

Function GetNVramPath()
    Dim WshShell
    Set WshShell = CreateObject("WScript.Shell")
    'GetNVramPath = WshShell.RegRead("HKCU\Software\Freeware\Visual PinMame\globals\nvram_directory")
	GetNVramPath = ".\pinmame\nvram"
End function

Function FileExists(FileName)
    DIM FSO
    FileExists = False
    Set FSO = CreateObject("Scripting.FileSystemObject")
    FileExists = FSO.FileExists(FileName)
    Set FSO = Nothing
End Function

Sub Kill(FileName)
    Dim ObjFile, FSO
    On Error Resume Next
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Set ObjFile = FSO.GetFile(FileName)
    ObjFile.Delete
    On Error Goto 0
    Set FSO = Nothing
End Sub

Sub Copy(SourceFileName, DestFileName)
    Dim FSO
    On Error Resume Next
    Set FSO = CreateObject("Scripting.FileSystemObject")
    FSO.CopyFile SourceFileName, DestFileName, True
    On Error Goto 0
    Set FSO = Nothing
End Sub

Sub NVramPatchLoad
    NVramPatchCoinCnt = 0
    If FileExists(GetNVramPath + "\" + cGameName + ".nvb")Then
        Copy GetNVramPath + "\" + cGameName + ".nvb", GetNVramPath + "\" + cGameName + ".nv"
    Else
        Copy GetNVramPath + "\" + cGameName + ".nv", GetNVramPath + "\" + cGameName + ".nvb"
    End If
End Sub

Sub NVramPatchExit
    If LampState(GameOverLampID)Then
        Kill GetNVramPath + "\" + cGameName + ".nvb"
        Do
            LampTimer_Timer          ' This loop is needed to avoid the NVram reset (losing the hi-score and credits)
        Loop Until LampState(20) = 1 ' when the game is over but the match procedure isn't still ended
    End If
End Sub

' =============================================================================================================
' To completely erase the NVram file keep the Start Game button pushed while inserting
' two coins into the first coin slit (this resets the high scores too)
' =============================================================================================================

Sub NVramPatchKeyCheck
    If Controller.Switch(swStartButton)then
        If Controller.Switch(swCoin1)then
            If NVramPatchCoinCnt = 2 Then
                Controller.Stop
                Kill GetNVramPath + "\" + cGameName + ".nv"
                Kill GetNVramPath + "\" + cGameName + ".nvb"
                QuitPlayer 2
            Else
                NVramPatchCoinCnt = 1
            End If
        Else
            If NVramPatchCoinCnt = 1 Then
                NVramPatchCoinCnt = 2
            End If
        End If
    Else
        NVramPatchCoinCnt = 0
    End If
End Sub


'********************************************************************************
' Flex DMD routines made possible by scutters' tutorials and scripts.
'********************************************************************************
DIm FlexDMDFont
Dim FlexDMDFontActiveScore
Dim FlexDMDScene
Dim ExternalEnabled

Dim LastScoreUpdated
Dim FlexDMD		' the flex dmd display
DIm FlexDMDDict		' a dictionary / lookup to convert segment display hex/int codes to characters
Dim L1Chars, L2Chars, L3Chars, L4Chars
Dim Line1Change, Line2Change, Line3Change, Line4Change, Flexpath

Sub FlexDMD_Init() 'default/startup values

	

'	GameOver = 1

	'arrays to hold characters to display converted from segment codes
	L1Chars = Array("0","0","0","0","0","0")
	L2Chars = Array("0","0","0","0","0","0")
	L3Chars = Array("0","0","0","0","0","0")
	L4Chars = Array("0","0","0","0","0","0")
	LastScoreUpdated = 0
	FlexDictionary_Init
	Dim fso,curdir
	Set fso = CreateObject("Scripting.FileSystemObject")
	curDir = fso.GetAbsolutePathName(".")
	FlexPath = curDir & "\DickTracy.FlexDMD\"

	Set FlexDMD = CreateObject("FlexDMD.FlexDMD")
	If Not FlexDMD is Nothing Then
	
		FlexDMD.GameName = cGameName
'		FlexDMD.TableFile = cGameName.Filename & ".vpx"
		FlexDMD.RenderMode = 2
		FlexDMD.Width = 128
		FlexDMD.Height = 32
		FlexDMD.Clear = True
		FlexDMD.Run = True

		Set FlexDMDScene = FlexDMD.NewGroup("Scene")

			FlexDMDFont = FlexDMD.NewFont(FlexPath & "dicktracy.fnt", vbWhite, vbBlue, 0)

		With FlexDMDScene

	
			.AddActor FlexDMD.NewImage("Back",FlexPath & "background.png")



			.AddActor(FlexDMD.NewLabel("ActivePlayerLine", FlexDMDFont, "123456"))
			.GetLabel("ActivePlayerLine").SetAlignedPosition  1,0,0
			.GetLabel("ActivePlayerLine").Visible = False
			.AddActor FlexDMD.NewImage("Title",FlexPath & "Title.png")
			.GetImage("Title").SetAlignedPosition  0,0,0
			.GetImage("Title").Visible = True

		End With

		FlexDMD.LockRenderThread
		
		FlexDMD.Stage.AddActor FlexDMDScene
		
		FlexDMD.Show = True
		FlexDMD.UnlockRenderThread
		
		Line1Change = False
		Line2Change = False 
		Line3Change = False
		Line4Change = False
	End If

End Sub



Sub FlexDictionary_Init

	'add conversion of segment charcters codes to lookup table
	Set FlexDMDDict = CreateObject("Scripting.Dictionary")

	FlexDMDDict.Add 0, " "
	FlexDMDDict.Add 63, "0"
	FlexDMDDict.Add 6, "1"
	FlexDMDDict.Add 91, "2"
	FlexDMDDict.Add 79, "3"
	FlexDMDDict.Add 102, "4"
	FlexDMDDict.Add 109, "5"
	FlexDMDDict.Add 125, "6"
	FlexDMDDict.Add 7, "7"
	FlexDMDDict.Add 127, "8"
	FlexDMDDict.Add 111, "9"
	
	FlexDMDDict.Add 191, "0"
	FlexDMDDict.Add 134, "1"
	FlexDMDDict.Add 219, "2"
	FlexDMDDict.Add 207, "3"
	FlexDMDDict.Add 230, "4"
	FlexDMDDict.Add 237, "5"
	FlexDMDDict.Add 253, "6"
	FlexDMDDict.Add 135, "7"
	FlexDMDDict.Add 255, "8"
	FlexDMDDict.Add 239, "9"
	 
End Sub

'**************
' Update FlexDMD
'**************
	Dim scoreholder
Sub FlexDMDUpdate()

	Dim FlexLabel
	dim LineText
	
	If Not FlexDMD is Nothing Then FlexDMD.LockRenderThread
	If FlexDMD.Run = False Then FlexDMD.Run = True

	With FlexDMD.Stage




		If Line1Change Then
			If Join(L1Chars,"") <> "      " Then scoreholder = Join(L1Chars,"")
			If scoreholder = "000000" Then
			.GetImage("Title").Visible = True
			.GetLabel("ActivePlayerLine").Visible = False
			Else
		
			If L1Chars(0)="0" Then scoreholder = ","& L1Chars(1)& L1Chars(2)& L1Chars(3)& L1Chars(4)& L1Chars(5)& ","
			If L1Chars(1)="0" And L1Chars(0)="0" Then scoreholder = ",," & L1Chars(2) & L1Chars(3) & L1Chars(4) & L1Chars(5)
			.GetLabel("ActivePlayerLine").Text = scoreholder
			.GetImage("Title").Visible = False
			.GetLabel("ActivePlayerLine").Visible = True
			End If
		ElseIf Line2Change Then
			If Join(L2Chars,"") <> "      " Then scoreholder = Join(L2Chars,"")
			If scoreholder = "000000" Then
			.GetImage("Title").Visible = True
			.GetLabel("ActivePlayerLine").Visible = False
			Else
			If L2Chars(0)="0" Then scoreholder = ","& L2Chars(1)& L2Chars(2)& L2Chars(3)& L2Chars(4)& L2Chars(5)& ","
			If L2Chars(1)="0" And L2Chars(0)="0" Then scoreholder = ",,"& L2Chars(2)& L2Chars(3)& L2Chars(4)& L2Chars(5)& " "
			.GetLabel("ActivePlayerLine").Text = scoreholder
			.GetImage("Title").Visible = False
			.GetLabel("ActivePlayerLine").Visible = True
			End If
		ElseIf Line3Change Then
			If Join(L3Chars,"") <> "      " Then scoreholder = Join(L3Chars,"")
			If scoreholder = "000000" Then
			.GetImage("Title").Visible = True
			.GetLabel("ActivePlayerLine").Visible = False
			Else
			If L3Chars(0)="0" Then scoreholder = ","& L3Chars(1)& L3Chars(2)& L3Chars(3)& L3Chars(4)& L3Chars(5)& ","
			If L3Chars(1)="0" And L3Chars(0)="0" Then scoreholder = ",,"& L3Chars(2)& L3Chars(3)& L3Chars(4)& L3Chars(5)& " "
			.GetLabel("ActivePlayerLine").Text = scoreholder
			.GetImage("Title").Visible = False
			.GetLabel("ActivePlayerLine").Visible = True
			End If
		ElseIf Line4Change Then
			If Join(L4Chars,"") <> "      " Then scoreholder = Join(L4Chars,"")
			If scoreholder = "000000" Then
			.GetImage("Title").Visible = True
			.GetLabel("ActivePlayerLine").Visible = False
			Else
			If L4Chars(0)="0" Then scoreholder = ","& L4Chars(1)& L4Chars(2)& L4Chars(3)& L4Chars(4)& L4Chars(5)& ","
			If L4Chars(1)="0" And L4Chars(0)="0" Then scoreholder = ",,"& L4Chars(2)& L4Chars(3)& L4Chars(4)& L4Chars(5)& " "
			.GetLabel("ActivePlayerLine").Text = scoreholder
			.GetImage("Title").Visible = False
			.GetLabel("ActivePlayerLine").Visible = True
			End If
		End If

	End With

	If Not FlexDMD is Nothing Then FlexDMD.UnlockRenderThread
	
	Line1Change = False
	Line2Change = False 
	Line3Change = False
	Line4Change = False
		
End Sub


Sub UpdateFlexChar(id, value)
	'map segment code to character in LnChars arrays
	Dim chr
	if id < 24 and FlexDMDDict.Exists (value) then
	
		chr = FlexDMDDict.Item (value)
		
		'if value = 0 then ' 0 is a space, everything else is numbers for scores 1-4
		'	select case id
		'	case 0,3,7,10,14,17,21,24
			'	chr = chr & "." 'pad for alignment  
			'end select
		'end if

		if id < 6 then
			L1Chars(id) = chr
			Line1Change = True
		elseif id < 12 then
			L2Chars(id - 6) = chr
			Line2Change = True
		elseif id < 18 then
			L3Chars(id - 12) = chr
			Line3Change = True
		elseif id < 24 then
			L4Chars(id - 18) = chr
			Line4Change = True
		end if

	end if 
		
End Sub
