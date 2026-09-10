//====================================================================================================
//
// Name: ForceInput
// Author: zaCade + BotoX (Modified by PSE Shufen and Koen to fix crash issues)
// Description: Allows admins to force inputs on entities. (ent_fire)
//
//====================================================================================================
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name 			= "ForceInput",
	author 			= "zaCade + BotoX + PSE Shufen + koen",
	description 	= "Allows admins to force inputs on entities. (ent_fire)",
	version 		= "2.2.0",
	url 			= ""
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_forceinput", Command_ForceInput, ADMFLAG_ROOT, "Force an input on entities by classname/targetname/HammerID (supports !self, !target, #<HammerID> and * wildcards)");
	RegAdminCmd("sm_forceinputplayer", Command_ForceInputPlayer, ADMFLAG_ROOT, "Force an input on one or more players");
}

//----------------------------------------------------------------------------------------------------
// Purpose: Applies the optional parameter and fires the input, returning whether it succeeded.
//----------------------------------------------------------------------------------------------------
bool FireInput(int entity, const char[] input, const char[] parameter, int activator, int caller)
{
	if(parameter[0])
		SetVariantString(parameter);

	return AcceptEntityInput(entity, input, activator, caller);
}

//----------------------------------------------------------------------------------------------------
// Purpose: Logs a forced input against an entity.
//----------------------------------------------------------------------------------------------------
void LogInput(int client, int entity, const char[] input, const char[] parameter)
{
	char sClassname[64];
	char sTargetname[64];
	GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

	LogAction(client, -1, "\"%L\" used ForceInput on Entity \"%d\" - \"%s\" - \"%s\": \"%s %s\"", client, entity, sClassname, sTargetname, input, parameter);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_ForceInputPlayer(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forceinputplayer <target> <input> [parameter]");
		return Plugin_Handled;
	}

	char sArguments[3][256];
	GetCmdArg(1, sArguments[0], sizeof(sArguments[]));
	GetCmdArg(2, sArguments[1], sizeof(sArguments[]));
	GetCmdArg(3, sArguments[2], sizeof(sArguments[]));

	char sTargetName[MAX_TARGET_LENGTH];
	int aTargetList[MAXPLAYERS + 1];
	int TargetCount;
	bool TnIsMl;

	if((TargetCount = ProcessTargetString(
			sArguments[0],
			client,
			aTargetList,
			sizeof(aTargetList),
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY,
			sTargetName,
			sizeof(sTargetName),
			TnIsMl)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}

	int iSuccess;
	int iFailed;

	for(int i = 0; i < TargetCount; i++)
	{
		if(!IsClientInGame(aTargetList[i]))
			continue;

		if(FireInput(aTargetList[i], sArguments[1], sArguments[2], aTargetList[i], aTargetList[i]))
		{
			iSuccess++;
			LogAction(client, aTargetList[i], "\"%L\" used ForceInputPlayer on \"%L\": \"%s %s\"", client, aTargetList[i], sArguments[1], sArguments[2]);
		}
		else
		{
			iFailed++;
		}
	}

	if(!iSuccess && !iFailed)
		ReplyToCommand(client, "[SM] Input \"%s\" was not applied to any player.", sArguments[1]);
	else if(iFailed)
		ReplyToCommand(client, "[SM] Input \"%s\" applied to %d of %d player(s), %d failed.", sArguments[1], iSuccess, iSuccess + iFailed, iFailed);
	else
		ReplyToCommand(client, "[SM] Input \"%s\" applied to %d player(s).", sArguments[1], iSuccess);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_ForceInput(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forceinput <classname/targetname> <input> [parameter]");
		return Plugin_Handled;
	}

	char sArguments[3][256];
	GetCmdArg(1, sArguments[0], sizeof(sArguments[]));
	GetCmdArg(2, sArguments[1], sizeof(sArguments[]));
	GetCmdArg(3, sArguments[2], sizeof(sArguments[]));

	if(StrEqual(sArguments[0], "!self"))
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] You can't use `!self` args from the server console.");
			return Plugin_Handled;
		}

		if(FireInput(client, sArguments[1], sArguments[2], client, client))
		{
			ReplyToCommand(client, "[SM] Input successful.");
			LogAction(client, client, "\"%L\" used ForceInput on himself: \"%s %s\"", client, sArguments[1], sArguments[2]);
		}
		else
		{
			ReplyToCommand(client, "[SM] Input \"%s\" failed.", sArguments[1]);
		}

		return Plugin_Handled;
	}

	if(StrEqual(sArguments[0], "!target"))
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] You can't use `!target` args from the server console.");
			return Plugin_Handled;
		}

		float fPosition[3];
		float fAngles[3];
		GetClientEyePosition(client, fPosition);
		GetClientEyeAngles(client, fAngles);

		Handle hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

		int entity = TR_DidHit(hTrace) ? TR_GetEntityIndex(hTrace) : -1;
		CloseHandle(hTrace);

		if(entity < 1 || !IsValidEntity(entity))
		{
			ReplyToCommand(client, "[SM] No valid entity found under your crosshair.");
			return Plugin_Handled;
		}

		if(FireInput(entity, sArguments[1], sArguments[2], client, client))
		{
			ReplyToCommand(client, "[SM] Input successful.");
			LogInput(client, entity, sArguments[1], sArguments[2]);
		}
		else
		{
			ReplyToCommand(client, "[SM] Input \"%s\" failed.", sArguments[1]);
		}

		return Plugin_Handled;
	}

	// Collect a snapshot of every matching entity first, then fire the input on it.
	// Firing inputs while iterating FindEntityByClassname() is unsafe: an input can
	// create or remove entities mid-iteration, which previously caused crashes.
	ArrayList hEntities = new ArrayList();

	if(sArguments[0][0] == '#') // HammerID
	{
		int iHammerID = StringToInt(sArguments[0][1]);

		int entity = INVALID_ENT_REFERENCE;
		while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntProp(entity, Prop_Data, "m_iHammerID") == iHammerID)
				hEntities.Push(EntIndexToEntRef(entity));
		}
	}
	else
	{
		int iWildcard = FindCharInString(sArguments[0], '*');

		int entity = INVALID_ENT_REFERENCE;
		while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			char sClassname[64];
			char sTargetname[64];
			GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
			GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

			if((iWildcard > 0 && (strncmp(sClassname, sArguments[0], iWildcard, false) == 0 || strncmp(sTargetname, sArguments[0], iWildcard, false) == 0)) ||
				(iWildcard <= 0 && (StrEqual(sClassname, sArguments[0], false) || StrEqual(sTargetname, sArguments[0], false))))
			{
				hEntities.Push(EntIndexToEntRef(entity));
			}
		}
	}

	int iSuccess;
	int iFailed;

	for(int i = 0; i < hEntities.Length; i++)
	{
		int entity = EntRefToEntIndex(hEntities.Get(i));

		if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
			continue;

		if(FireInput(entity, sArguments[1], sArguments[2], client, client))
		{
			iSuccess++;
			LogInput(client, entity, sArguments[1], sArguments[2]);
		}
		else
		{
			iFailed++;
		}
	}

	delete hEntities;

	if(!iSuccess && !iFailed)
		ReplyToCommand(client, "[SM] No entities matched \"%s\".", sArguments[0]);
	else if(iFailed)
		ReplyToCommand(client, "[SM] Input \"%s\" applied to %d of %d entities, %d failed.", sArguments[1], iSuccess, iSuccess + iFailed, iFailed);
	else
		ReplyToCommand(client, "[SM] Input \"%s\" applied to %d entities.", sArguments[1], iSuccess);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public bool TraceRayFilter(int entity, int mask, any client)
{
	if(entity == client)
		return false;

	return true;
}
