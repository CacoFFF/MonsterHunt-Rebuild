//================================================================================
// MonsterComment.
//================================================================================
class MonsterComment extends Info;

#exec TEXTURE IMPORT NAME=MHComment FILE=pcx\MHComment.pcx

var() string Comment1;
var() string Comment2;
var() string Comment3;
var() string Comment4;
var() string Comment5;

defaultproperties
{
	Texture=Texture'MHComment'
	DrawScale=2.00
}
