#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "X-AROK"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <clientprefs>
#include <knife_choice_core>
#include <csgo_colors>
#include <playersmanager>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Players Knives",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

static const char menuTriggers[][] = {"!лтшау", "/лтшау", "/нож", "knife" , "!knife", "!нож", "!knifes", "!knfie", "!knifw", "!knifew", "!kinfe", "!kinfes", "/knif", "/knifes", "/knfie", "/knifw", "/knives", "/kinfe", "/kinfes" , "/knife"};

Handle g_hCookie;
int kife_n[MAXPLAYERS+1];
int g_iRankToKnife[20] = {
	-1, //0 not exist
	0, // CT
	0, //T
	0, //Golden
	6, //Flip
	1, //Gut
	5, //Bayonet
	6, //M9 Bayonet
	8, //Karambit
	5, //Huntsman
	7, //Butterfly
	1, //Falchion
	2, //Shadow Daggers
	4, //Bowie
	3, //Ursus
	3, //Navaja
	2, //Stiletto
	4, //Talon
	9, //Spectral Shiv
	10, //Classic
};
ConVar p_World, p_NoKnife;
bool b_World, b_NoKnife;

public void OnPluginStart(){
	g_hCookie = RegClientCookie("ExcetraKnives", "ExcetraKnives", CookieAccess_Protected);
	p_NoKnife = CreateConVar("sm_knife_choice_im_no_knife", "1", "Блокировать выдачу ножа если у игрока нету ножа(не выдан самой картой).", FCVAR_NONE, true, 0.0, true, 1.0);
	p_World = CreateConVar("sm_knife_choice_im_world", "0", "Заменять поднятый с карты нож на выбранный игроком.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(p_World, ConVarChanges);
	HookConVarChange(p_NoKnife, ConVarChanges);
	AutoExecConfig(true, "knife_choice_im");
}

public void OnConfigsExecuted() 
{
	b_World = p_World.BoolValue;
	b_NoKnife = p_NoKnife.BoolValue;
}

public void ConVarChanges(ConVar convar, const char[] oldVal, const char[] newVal) 
{
	if(convar == p_World) b_World = p_World.BoolValue;
	else if(convar == p_NoKnife) b_NoKnife = p_NoKnife.BoolValue;
}

public void OnClientSayCommand_Post(int iClient, const char[] command, const char[] sArgs)
{
	for(int i; i < sizeof(menuTriggers); i++)
	{
		if (StrEqual(sArgs, menuTriggers[i], false)){
			DisplayKnifeMenu(iClient);
		}
	}
}

public void DisplayKnifeMenu(int iClient){
	int iClientRank = PM_getClientRank(iClient);
	char buf[64];
	Menu mKkife = new Menu(m_mKkife);
	mKkife.SetTitle("--------------------------------------------\nВыберете себе нож\n--------------------------------------------");
	mKkife.AddItem("", "Не изменять нож");
	int Mid = KCC_GetKnifeMaxId();
	for (int i = 1; i <= Mid; i++)
	{
		if(iClientRank >= g_iRankToKnife[i]){
			KCC_GetKnifeNameFromIndex(KCC_GetKnifeTypeInId(i), buf, 64);
			mKkife.AddItem("", buf);
		}
		else{
			KCC_GetKnifeNameFromIndex(KCC_GetKnifeTypeInId(i), buf, 64);
			FormatEx(buf, sizeof(buf), "%s [Ранг %i]", buf, g_iRankToKnife[i]);
			mKkife.AddItem("", buf, ITEMDRAW_DISABLED);
		}
	}
	mKkife.Display(iClient, 0);
}

public int m_mKkife(Menu hMenu, MenuAction action, int iClient, int Item)
{
	if(action == MenuAction_Select)
	{
		kife_n[iClient] = Item;
		if(kife_n[iClient] && IsPlayerAlive(iClient)) KCC_SetKnife(iClient, KCC_GetKnifeTypeInId(kife_n[iClient]));
		static char sCookieValue[10];
		IntToString(kife_n[iClient], sCookieValue, 10);
		SetClientCookie(iClient, g_hCookie, sCookieValue);
		CGOPrintToChat(iClient, "{PURPLE}Вы успешно сменили свой нож");
		hMenu.DisplayAt(iClient, GetMenuSelectionPosition(), 0);
	}
}


public void OnClientCookiesCached(int iClient)
{
	static char sCookieValue[10];
	GetClientCookie(iClient, g_hCookie, sCookieValue, sizeof(sCookieValue));
	kife_n[iClient] = StringToInt(sCookieValue);
}

public Action KCC_OnReceivesKnifePre(int iClient, knifes &kKnife, bool bHasKnife, bool bKnifeClient, bool bSetKnife)
{
	if(kife_n[iClient])
	{
		if(!bHasKnife && b_NoKnife && bSetKnife) return Plugin_Handled;
		else if(!bKnifeClient && !b_World) return Plugin_Continue;
		else if(KCC_GetKnifeIdInType(kKnife) != kife_n[iClient])
		{
			kKnife = KCC_GetKnifeTypeInId(kife_n[iClient]);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}