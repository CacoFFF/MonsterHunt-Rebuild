//**********************************************
// MonsterHUD
class MonsterHUD expands MHCR_HUD
	config(User);
	
#exec TEXTURE IMPORT NAME=HUDIcon FILE=pcx\HUDIcon.pcx Mips=Off GROUP="HUD"

//MH-Andromeda requires this for some reason
simulated function DrawStatus(Canvas Canvas)
{
	Super.DrawStatus( Canvas);
}

//UTJMH requires this function
simulated event PostRender( Canvas Canvas)
{
	Super.PostRender( Canvas);
}
