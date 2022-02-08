#include <amxmodx>
#include <ChatAdditions>

public stock const PluginName[] = "CA: Logger";
public stock const PluginVersion[] = "1.0";
public stock const PluginAuthor[] = "Karaulov";
//public stock const PluginURL[] = "https://github.com/ChatAdditions";
public stock const PluginDescription[] = "Chat logger for CA!";

public plugin_init() {
	register_plugin(PluginName, PluginVersion, PluginAuthor);
}

public client_command(id){
	new cmdMsg[256], cmdMsgTemp[256], username[64], steamid[64], ipaddress[64];
	new argsCount = read_argc();
	if (!argsCount)
		return;
	for(new i = 0; i < argsCount; i++)
	{
		read_argv(i,cmdMsgTemp,charsmax(cmdMsgTemp));
		if (cmdMsgTemp[0] != EOS)
		{
			add(cmdMsg,charsmax(cmdMsg),cmdMsgTemp);
			add(cmdMsg,charsmax(cmdMsg)," ");
		}
	}
	get_user_name(id,username,charsmax(username));
	get_user_authid(id,steamid,charsmax(steamid));
	get_user_ip(id,ipaddress,charsmax(ipaddress))
	
	CA_Log(logLevel_Info, "[%s] [%s] %s : %s",ipaddress,steamid,username,cmdMsg);
}