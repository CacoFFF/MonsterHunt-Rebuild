//================================================================================
// MonsterHuntRules.
//================================================================================
class MonsterHuntRules extends UTRulesCWindow;

#exec OBJ LOAD FILE=..\System\UTMenu.u PACKAGE=UTMenu
#exec Texture Import File=pcx\MHRulesBG.pcx Name=MHRulesBG Mips=Off Group=Rules

var bool bMHInit;

// Damage to score
var UWindowEditControl DamageToScoreEdit;
var localized string DamageToScoreText;
var localized string DamageToScoreHelp;

// Monster Strength
var UWindowHSliderControl MSSlider;
var localized string MSText;
var localized string MSHelp;


function Created()
{
	local int FFS;
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	bMHInit = False;

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;
	
	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	Initialized = False;
	Super.Created();
	if ( ForceRespawnCheck != None )
		ForceRespawnCheck.HideWindow();
	Initialized = False;
	
	DamageToScoreEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
	DamageToScoreEdit.SetText(DamageToScoreText);
	DamageToScoreEdit.SetHelpText(DamageToScoreHelp);
	DamageToScoreEdit.SetFont(F_Normal);
	DamageToScoreEdit.SetNumericOnly(True);
	DamageToScoreEdit.SetMaxLength(3);
	DamageToScoreEdit.Align = TA_Right;
	DamageToScoreEdit.SetDelayedNotify(True);
	DamageToScoreEdit.SetValue(string(class<MonsterHunt>(BotmatchParent.GameClass).Default.DamageToScore));
	ControlOffset += 25;


	DesiredWidth = 220;
	DesiredHeight = 165;

	// Friendly Fire Scale
	MSSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', CenterPos, ControlOffset, CenterWidth, 1));
	MSSlider.SetRange(0, 20, 1);
	FFS = Class<MonsterHunt>(BotmatchParent.GameClass).Default.MonsterSkill;
	MSSlider.SetValue(FFS);
	MSSlider.SetText(MSText$" ["$FFS$"]:");
	MSSlider.SetHelpText(MSHelp);
	MSSlider.SetFont(F_Normal);

	Initialized = True;
	bMHInit = true;
}




function LoadCurrentValues()
{
//	Super.LoadCurrentValues();
	TimeEdit.SetValue(string(Class<MonsterHunt>(BotmatchParent.GameClass).Default.TimeLimit));
	if ( MaxPlayersEdit != None )
		MaxPlayersEdit.SetValue(string(Class<MonsterHunt>(BotmatchParent.GameClass).Default.MaxPlayers));
	if ( MaxSpectatorsEdit != None )
		MaxSpectatorsEdit.SetValue(string(Class<MonsterHunt>(BotmatchParent.GameClass).Default.MaxSpectators));
	if ( BotmatchParent.bNetworkGame )
		WeaponsCheck.bChecked = Class<MonsterHunt>(BotmatchParent.GameClass).Default.bMultiWeaponStay;
	else
		WeaponsCheck.bChecked = Class<MonsterHunt>(BotmatchParent.GameClass).Default.bCoopWeaponMode;
	FragEdit.SetValue(string(Class<MonsterHunt>(BotmatchParent.GameClass).Default.Lives));
	TourneyCheck.bChecked = Class<MonsterHunt>(BotmatchParent.GameClass).Default.bUseTeamSkins;
}

function Paint( Canvas C, float X, float Y)
{
	Super.Paint(C,X,Y);
	DrawStretchedTexture(C,0.0,0.0,WinWidth,WinHeight,Texture'MHRulesBG');
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, ButtonWidth, ButtonLeft;

	Super.BeforePaint(C, X, Y);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	DamageToScoreEdit.SetSize(ControlWidth, 1);
	DamageToScoreEdit.WinLeft = ControlLeft;
	DamageToScoreEdit.EditBoxWidth = 20;

	MSSlider.SetSize(CenterWidth, 1);
	MSSlider.SliderWidth = 90;
	MSSlider.WinLeft = CenterPos;
}

function Notify(UWindowDialogControl C, byte E)
{
	if (!Initialized)
		return;
	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch (C)
		{
			case DamageToScoreEdit:
				DamageToScoreChanged();
				break;
			case MSSlider:
				MSChanged();
				break;
		}
	}
}

function DamageToScoreChanged()
{
	Class<MonsterHunt>(BotmatchParent.GameClass).Default.DamageToScore = int(DamageToScoreEdit.GetValue());
}

function MSChanged()
{
	Class<MonsterHunt>(BotmatchParent.GameClass).Default.MonsterSkill = MSSlider.GetValue();
	MSSlider.SetText(MSText$" ["$int(MSSlider.GetValue())$"]:");
}


function FragChanged()
{
	if ( bMHInit )
		Class<MonsterHunt>(BotmatchParent.GameClass).Default.Lives = int(FragEdit.GetValue());
}

function TourneyChanged()
{
	if ( bMHInit )
		Class<MonsterHunt>(BotmatchParent.GameClass).Default.bUseTeamSkins = TourneyCheck.bChecked;
}

function TimeChanged()
{
	Class<MonsterHunt>(BotmatchParent.GameClass).Default.TimeLimit = int(TimeEdit.GetValue());
}


function WeaponsChecked()
{
	if ( BotmatchParent.bNetworkGame )
		Class<MonsterHunt>(BotmatchParent.GameClass).Default.bMultiWeaponStay = WeaponsCheck.bChecked;
	else
		Class<MonsterHunt>(BotmatchParent.GameClass).Default.bCoopWeaponMode = WeaponsCheck.bChecked;
}



defaultproperties
{
    TourneyText="Force team colours"
    TourneyHelp="If enabled, players will use red team skins and HUD, otherwise they will use their own skin and HUD settings."
    FragText="Lives"
    FragHelp="Set the number of lives each hunter starts with for each round. Set it to 0 for no limit."
	MSText="Monster Skill"
	MSHelp="Increases monster skill and strength. Default=3"
	DamageToScoreText="Damage to score"
	DamageToScoreHelp="Gain 1 point after dealing this amount of damage"
}