#include <amxmodx>

#define DEFAULT_CHAT_ACCESS_LEVEL ADMIN_KICK

// Natives
native aes_get_player_level(player);
native aes_get_level_name(level,level_name[],len,idLang = LANG_SERVER);
native ar_get_user_level(const player, rankName[] = "", len = 0);
native cmsranks_get_user_level(id, szLevel[] = "", len = 0);
native Array:cmsapi_get_user_services(const index, const szAuth[] = "", const szService[] = "", serviceID = 0, bool:part = false);
native csstats_get_user_stats(const player, const stats[22]);
native statsx_get_skill(stats[22], string[] = "", len = 0);

new g_sGameCmsPrefix[MAX_PLAYERS + 1][128];
new g_sGameCmsAdminPrefix[MAX_PLAYERS + 1][128];
new g_sChatRbsPrefix[MAX_PLAYERS + 1][128];

new g_sUnrealPrefix[MAX_PLAYERS + 1][64];
new g_sUnrealSkillPrefix[MAX_PLAYERS + 1][16];

new bool:UNREAL_RANK_PREFIX_ENABLED = false;
new bool:AES_PREFIX_ENABLED = true;
new bool:AR_PREFIX_ENABLED = true;
new bool:CMS_PREFIX_ENABLED = true;
new bool:GAMECMS_PREFIX_ENABLED = true;
new bool:CHATRBS_PREFIX_ENABLED = true;

new bool:STATSRBS_PREFIX_ENABLED[2] = {true,true};

new bool:g_bPlayerConnected[MAX_PLAYERS + 1] = {false, ...};

new g_hServerLanguage = LANG_SERVER;

public stock const PluginName[] = "Unreal Prefix";
public stock const PluginVersion[] = "1.0.1";
public stock const PluginAuthor[] = "Karaulov";
public stock const PluginDescription[] = "Combine of all prefixes";

public plugin_init() 
{
	register_plugin(PluginName, PluginVersion, PluginAuthor);
	
	register_clcmd("say",       "ClCmd_Say",      ADMIN_ALL)
	register_clcmd("say_team",  "ClCmd_SayTeam",  ADMIN_ALL)
	
	register_dictionary("unreal_prefix.txt")
}

public plugin_natives() 
{
	set_native_filter("native_filter")
}

public client_disconnected(id)
{
	g_sUnrealPrefix[id][0] = EOS;
	g_sUnrealSkillPrefix[id][0] = EOS;
	g_sGameCmsPrefix[id][0] = EOS;
	g_sChatRbsPrefix[id][0] = EOS;
	g_bPlayerConnected[id] = false;
}

public client_connect(id)
{
	g_sUnrealPrefix[id][0] = EOS;
	g_sUnrealSkillPrefix[id][0] = EOS;
	g_bPlayerConnected[id] = false;
}

public native_filter(const name[], index, trap) 
{
	if (trap)
		return PLUGIN_CONTINUE;
		
	if(equal(name, "aes_get_player_level") || equal(name, "aes_get_level_name"))
	{
		AES_PREFIX_ENABLED = false;
		return PLUGIN_HANDLED;
	}

	if(equal(name, "ar_get_user_level"))
	{
		AR_PREFIX_ENABLED = false;
		return PLUGIN_HANDLED;
	}

	if(equal(name, "cmsranks_get_user_level"))
	{
		CMS_PREFIX_ENABLED = false;
		return PLUGIN_HANDLED;
	}

	if(equal(name, "cmsapi_get_user_services"))
	{
		GAMECMS_PREFIX_ENABLED = false;
		return PLUGIN_HANDLED;
	}

	if(equal(name, "csstats_get_user_stats"))
	{
		STATSRBS_PREFIX_ENABLED[0] = false;
		return PLUGIN_HANDLED;
	}

	if(equal(name, "statsx_get_skill"))
	{
		STATSRBS_PREFIX_ENABLED[1] = false;
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE
}


public ClCmd_Say(id) {
	static message[191];
	read_args(message, charsmax(message));
	remove_quotes(message);
	if (strlen(message) > 0 )
		return CheckMessage(id, message, false);
	return PLUGIN_HANDLED;
}

public ClCmd_SayTeam(id) {
	static message[191];
	read_args(message, charsmax(message));
	remove_quotes(message);
	if (strlen(message) > 0 )
		return CheckMessage(id, message, true);
	return PLUGIN_HANDLED;
}

CheckMessage(id, const message[], const bool:team) {
	if(id == 0 || id > 33 || message[0] == '/' || !is_user_connected(id)) {
		return PLUGIN_HANDLED;
	}
	
	new outMessage[256];
	if (!LookupLangKey(outMessage,charsmax(outMessage),"UNREAL_PrefixFORMAT",g_hServerLanguage))
	{
		copy(outMessage,charsmax(outMessage),"%status%%team%%admin%%gamecms%%rank%%skill%%addons%!t%name%!n : !g%message%");
	}
	
	new teamName[64];
	new iTeam = get_user_team(id);
	new flags = get_user_flags(id);
	
	if (!is_user_alive(id) && (iTeam == 2 || iTeam == 1))
	{
		new deadName[64];
		if (!LookupLangKey(deadName,charsmax(deadName),"UNREAL_PrefixDead",g_hServerLanguage) || deadName[0] == EOS)
		{
			copy(deadName,charsmax(deadName),"*DEAD*");
		}
		
		replace_string(outMessage,charsmax(outMessage), "%status%", "%status% ", false);
		replace_string(outMessage,charsmax(outMessage), "%status%", deadName);
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%status%", "", false);
	}
	
	if (team || (iTeam != 2 && iTeam != 1) )
	{
		if (iTeam == 1)
		{
			if (!LookupLangKey(teamName,charsmax(teamName),"UNREAL_PrefixTEAM_T",g_hServerLanguage) || teamName[0] == EOS)
			{
				copy(teamName,charsmax(teamName),"( TERRORIST )");
			}
		}
		else if (iTeam == 2)
		{
			if (!LookupLangKey(teamName,charsmax(teamName),"UNREAL_Prefix2",g_hServerLanguage) || teamName[0] == EOS)
			{
				copy(teamName,charsmax(teamName),"( COUNTER-TERRORIST )");
			}
		}
		else 
		{
			if (!LookupLangKey(teamName,charsmax(teamName),"UNREAL_PrefixTEAM_SPEC",g_hServerLanguage) || teamName[0] == EOS)
			{
				copy(teamName,charsmax(teamName),"( SPECTATOR )");
			}
		}
		replace_string(outMessage,charsmax(outMessage), "%team%", "%team% ", false);
		replace_string(outMessage,charsmax(outMessage), "%team%", teamName);
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%team%", "", false);
	}
	
	new bool:adminAdded = false;
	
	if (GAMECMS_PREFIX_ENABLED)
	{
		if (g_sGameCmsPrefix[id][0] != EOS)
		{
			replace_string(outMessage,charsmax(outMessage), "%gamecms%", "%gamecms% ", false);
			replace_string(outMessage,charsmax(outMessage), "%gamecms%", g_sGameCmsPrefix[id]);
		}
		else 
			replace_string(outMessage,charsmax(outMessage), "%gamecms%", "", false);
			
		if (g_sGameCmsAdminPrefix[id][0] != EOS)
		{
			replace_string(outMessage,charsmax(outMessage), "%admin%", "[^4%admin%^1] ", false);
			replace_string(outMessage,charsmax(outMessage), "%admin%", g_sGameCmsAdminPrefix[id]);
			adminAdded = true;
		}
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%gamecms%", "", false);
	}
	
	if (!adminAdded)
	{
		new adminName[64];
		
		if (flags & ADMIN_RCON)
		{
			if (!LookupLangKey(adminName,charsmax(adminName),"UNREAL_PrefixADMIN_RCON",g_hServerLanguage) || adminName[0] == EOS)
			{
				copy(adminName,charsmax(adminName),"[^4Root Admin^1]");
			}
		}
		else if (flags & ADMIN_BAN)
		{
			if (!LookupLangKey(adminName,charsmax(adminName),"UNREAL_PrefixADMIN_BAN",g_hServerLanguage) || adminName[0] == EOS)
			{
				copy(adminName,charsmax(adminName),"[^4Admin^1]");
			}
		}
		else if (flags & ADMIN_KICK)
		{
			if (!LookupLangKey(adminName,charsmax(adminName),"UNREAL_PrefixADMIN_KICK",g_hServerLanguage) || adminName[0] == EOS)
			{
				copy(adminName,charsmax(adminName),"[^4Admin^1]");
			}
		}
		else if (flags & ADMIN_RESERVATION)
		{
			if (!LookupLangKey(adminName,charsmax(adminName),"UNREAL_PrefixADMIN_RESERV",g_hServerLanguage) || adminName[0] == EOS)
			{
				copy(adminName,charsmax(adminName),"[^4VIP^1]");
			}
		}
		
		if (adminName[0] == EOS)
		{
			replace_string(outMessage,charsmax(outMessage), "%admin%", "", false);
		}
		else 
		{
			replace_string(outMessage,charsmax(outMessage), "%admin%", "%admin% ", false);
			replace_string(outMessage,charsmax(outMessage), "%admin%", adminName);
		}
	}
	
	new bool:rankAdded = false;
	new rankName[64];
	
	if (UNREAL_RANK_PREFIX_ENABLED && !rankAdded)
	{
		if (g_sUnrealPrefix[id][0] != EOS)
		{
			copy(rankName,charsmax(rankName),g_sUnrealPrefix[id]);
			rankAdded = true;
		}
	}
	
	if (AES_PREFIX_ENABLED && !rankAdded)
	{
		new iPlayerLvl = aes_get_player_level(id);
		if (iPlayerLvl >= 0 && rankName[0] != EOS)
		{
			aes_get_level_name(iPlayerLvl,rankName,charsmax(rankName),id);
			rankAdded = true;
		}
	}
	
	if (AR_PREFIX_ENABLED && !rankAdded)
	{
		new iPlayerLvl = ar_get_user_level(id,rankName,charsmax(rankName));
		if (iPlayerLvl >= 0 && rankName[0] != EOS)
		{
			rankAdded = true;
		}
	}
	
	if (CMS_PREFIX_ENABLED && !rankAdded)
	{
		new iPlayerLvl = cmsranks_get_user_level(id,rankName,charsmax(rankName));
		if (iPlayerLvl >= 0 && rankName[0] != EOS)
		{
			rankAdded = true;
		}
	}
	
	if (!rankAdded || rankName[0] == EOS)
	{
		replace_string(outMessage,charsmax(outMessage), "%rank%", "", false);
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%rank%", "[^4%rank%^1] ", false);
		replace_string(outMessage,charsmax(outMessage), "%rank%", rankName);
	}
	
	new bool:skillAdded = false;
	new skillName[64];
	
	if (UNREAL_RANK_PREFIX_ENABLED && !skillAdded)
	{
		if (g_sUnrealSkillPrefix[id][0] != EOS)
		{
			copy(skillName,charsmax(skillName),g_sUnrealSkillPrefix[id]);
			skillAdded = true;
		}
	}
	
	if (STATSRBS_PREFIX_ENABLED[0] && STATSRBS_PREFIX_ENABLED[1] && skillAdded)
	{
		new statsRbs[22];
		new iPlayerLvl = csstats_get_user_stats(id,statsRbs);
		if (iPlayerLvl >= 0)
		{
			statsx_get_skill(statsRbs,skillName,charsmax(skillName));
			skillAdded = true;
		}
	}
	
	if (!skillAdded || skillName[0] == EOS)
	{
		replace_string(outMessage,charsmax(outMessage), "%skill%", "", false);
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%skill%", "[^4%skill%^1] ", false);
		replace_string(outMessage,charsmax(outMessage), "%skill%", skillName);
	}
	
	if (CHATRBS_PREFIX_ENABLED && g_sChatRbsPrefix[id][0] != EOS)
	{
		replace_string(outMessage,charsmax(outMessage), "%addons%", "%addons% ", false);
		replace_string(outMessage,charsmax(outMessage), "%addons%", g_sChatRbsPrefix[id]);
	}
	else 
	{
		replace_string(outMessage,charsmax(outMessage), "%addons%", "", false);
	}
	
	new playerName[64];
	get_user_name(id,playerName,charsmax(playerName));
	replace_string(outMessage,charsmax(outMessage), "%name%", playerName, false);
	
	replace_string(outMessage,charsmax(outMessage), "%message%", message, false);
	
	
	
	replace_string( outMessage, charsmax( outMessage ), "!g", "^4" ); // Green Color
	replace_string( outMessage, charsmax( outMessage ), "!n", "^1" ); // Default Color
	replace_string( outMessage, charsmax( outMessage ), "!t", "^3" ); // Team Color
    
	
	print_color(id,id,"^1%s",outMessage);
	
	for (new pid = 0; pid <= get_maxplayers(); pid++)
	{
		if (pid == id || !is_user_connected(pid))
		{
			continue;
		}
		new iPidTeam = get_user_team(pid);
		
		if (team)
		{
			if (iTeam == iPidTeam)
			{
				print_color(pid,id,"^1%s",outMessage);
			}
			else if (iTeam != 2 && iTeam != 1 && flags & DEFAULT_CHAT_ACCESS_LEVEL)
			{
				print_color(pid,id,"^1%s",outMessage);
			}
		}
		else 
		{
			if (iTeam != 2 && iTeam != 1)
			{
				if (iTeam == iPidTeam || flags & DEFAULT_CHAT_ACCESS_LEVEL)
					print_color(pid,id,"^1%s",outMessage);
			}
			else 
			{
				print_color(pid,id,"^1%s",outMessage);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}


public OnAPISendChatPrefix(id, prefix[], type)
{
	if( prefix[0] != EOS )
	{
		GAMECMS_PREFIX_ENABLED = true;
		if (type == 1 && cmsapi_get_user_services(id, "", "_nick_prefix", 0))
		{
			if (g_sGameCmsPrefix[id][0] == EOS || strfind(g_sGameCmsPrefix[id],prefix) == -1)
			{
				add(g_sGameCmsPrefix[id],charsmax(g_sGameCmsPrefix[]),"[^4");
				add(g_sGameCmsPrefix[id],charsmax(g_sGameCmsPrefix[]), prefix);
				add(g_sGameCmsPrefix[id],charsmax(g_sGameCmsPrefix[]),"^1] ");
			}
			if (!g_bPlayerConnected[id])
			{
				g_bPlayerConnected[id] = true;
				set_task(1.5,"print_joined_user_prefix",id);
			}
		}
		if (type == 2 && (get_user_flags(id) & (ADMIN_BAN | ADMIN_RESERVATION | ADMIN_IMMUNITY)) > 0)
		{
			copy(g_sGameCmsAdminPrefix[id], charsmax(g_sGameCmsAdminPrefix[]), prefix);
			if (!g_bPlayerConnected[id] || task_exists(id))
			{
				if (task_exists(id))
				{
					remove_task(id);
				}
				g_bPlayerConnected[id] = true;
				set_task(1.5,"print_joined_admin_prefix",id);
			}
		}
	}
}

public print_joined_user_prefix(id)
{
	g_bPlayerConnected[id] = true;
	if (is_user_connected(id))
	{
		new username[33];
		get_user_name(id,username,charsmax(username));
		
		
		new outMessage[256];
		if (!LookupLangKey(outMessage,charsmax(outMessage),"UNREAL_PrefixJOIN_USER",g_hServerLanguage))
		{
			copy(outMessage,charsmax(outMessage),"!nИгрок %s !g%s!n присоединился к игре!");
		}
		
		
		replace_string( outMessage, charsmax( outMessage ), "!g", "^4" ); // Green Color
		replace_string( outMessage, charsmax( outMessage ), "!n", "^1" ); // Default Color
		replace_string( outMessage, charsmax( outMessage ), "!t", "^3" ); // Team Color

		
		print_color(0,print_team_red,outMessage, g_sGameCmsPrefix[id], username );
	}
}


public print_joined_admin_prefix(id)
{
	g_bPlayerConnected[id] = true;
	if (is_user_connected(id))
	{
		new username[33];
		get_user_name(id,username,charsmax(username));
		
		
		new outMessage[256];
		if (!LookupLangKey(outMessage,charsmax(outMessage),"UNREAL_PrefixJOIN_ADMIN",g_hServerLanguage))
		{
			copy(outMessage,charsmax(outMessage),"!nВнимание! [!g%s!n] !t%s!n присоединился к игре!");
		}
		
		
		replace_string( outMessage, charsmax( outMessage ), "!g", "^4" ); // Green Color
		replace_string( outMessage, charsmax( outMessage ), "!n", "^1" ); // Default Color
		replace_string( outMessage, charsmax( outMessage ), "!t", "^3" ); // Team Color

		
		print_color(0,print_team_red,outMessage, g_sGameCmsPrefix[id], username );
	}
}

// CHAT RBS PREFIX SUPPORT
public chat_addons_prefix(id, prefix[])
{
	if ( prefix[0] != EOS )
	{
		if( g_sChatRbsPrefix[id][0] != EOS )
		{
			if (strfind(g_sChatRbsPrefix[id],prefix) == -1)
			{
				CHATRBS_PREFIX_ENABLED = true;
				add(g_sChatRbsPrefix[id],charsmax(g_sChatRbsPrefix[]),"[^4");
				add(g_sChatRbsPrefix[id],charsmax(g_sChatRbsPrefix[]),prefix);
				add(g_sChatRbsPrefix[id],charsmax(g_sChatRbsPrefix[]),"^1] ");
			}
		}
	}
}

public unrealranks_user_level_updated(const id,const level,const levelstr[],const rankstr[])
{
	UNREAL_RANK_PREFIX_ENABLED = true;
	
	if ( levelstr[0] != EOS )
	{
		copy(g_sUnrealPrefix[id],charsmax(g_sUnrealPrefix[]),levelstr);
	}
	
	if ( rankstr[0] != EOS )
	{
		copy(g_sUnrealSkillPrefix[id],charsmax(g_sUnrealSkillPrefix[]),rankstr);
	}
}

stock print_color( const id, const sender, const input[], any:... )
{
	static msg[ 191 ];
	new players[ 32 ], num, i = 0;
	
	if (numargs() == 3)
	{
		copy(msg,charsmax(msg),input);
	}
	else 
	{
		vformat(msg,charsmax(msg),input,4);
	}
	
	static msgId_SayText;
	if(!msgId_SayText) {
		msgId_SayText = get_user_msgid("SayText");
	}
	
	if (id != 0)
	{
		message_begin( MSG_ONE_UNRELIABLE, msgId_SayText, _, id );
		write_byte( sender );
		write_string( msg );
		message_end();
	}
	else 
	{
		get_players( players, num, "c" );
		for( i = 0; i < num; i ++ )
		{
			message_begin( MSG_ONE_UNRELIABLE, msgId_SayText, _, players[ i ] )
			write_byte( sender )
			write_string( msg )
			message_end()
		}
	}
	return 0
}