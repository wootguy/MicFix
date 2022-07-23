// fixes choppy microphone audio caused by cutscenes and cameras
// by automatically executing the "stopsound" command for clients.
// This is done at the beginning and end of camera sequences.

void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

class Camera {
	EHandle h_ent;
	EHandle h_tracker; // entity that tracks who activated the camera
	float lastThinkTime;
	
	Camera() {}
	
	Camera(CBaseEntity@ ent) {
		h_ent = EHandle(ent);
		lastThinkTime = ent.pev.nextthink;
		
		dictionary keys;
		keys["targetname"] = string(ent.pev.targetname);
		keys["target"] = "!activator";
		keys["m_iszValueName"] = "$i_cameraUser";
		keys["m_iszNewValue"] = "1";
		CBaseEntity@ tracker = g_EntityFuncs.CreateEntity("trigger_changevalue", keys, true);	
		h_tracker = tracker;
	}
}

array<Camera> g_cameras;

void PluginInit() {
	g_Module.ScriptInfo.SetAuthor( "w00tguy" );
	g_Module.ScriptInfo.SetContactInfo( "github" );
	
	findCameraEnts();
	
	g_Scheduler.SetInterval("pollCameras", 1.0f, -1);
}

void PluginExit() {
	for (uint i = 0; i < g_cameras.size(); i++) {
		g_EntityFuncs.Remove(g_cameras[i].h_tracker);
	}
}

void MapInit() {
	g_cameras.resize(0);
}

void MapActivate() {
	findCameraEnts();
}

void pollCameras() {
	for (uint i = 0; i < g_cameras.size(); i++) {
		CBaseEntity@ cam = g_cameras[i].h_ent;
		
		if (cam is null) {
			continue;
		}
		
		bool isAllPlayers = cam.pev.spawnflags & 8 != 0;
		bool wasActive = g_cameras[i].lastThinkTime != 0;
		bool isActive = cam.pev.nextthink != 0;
		
		if (wasActive != isActive) {
			if (!isAllPlayers) {
				CBasePlayer@ activator = findActivator();
				if (activator !is null) {
					clientCommand(activator, "stopsound");
					g_PlayerFuncs.ClientPrint(activator, HUD_PRINTCONSOLE, "[MicFix] Microphone audio was reset to prevent stuttering.\n");
				}
			} else {
				globalClientCommand("stopsound");
				g_PlayerFuncs.ClientPrintAll(HUD_PRINTCONSOLE, "[MicFix] Microphone audio was reset to prevent stuttering.\n");
			}
		}
		
		g_cameras[i].lastThinkTime = cam.pev.nextthink;
		
		//println("" + cam.pev.nextthink + " " + cam.pev.targetname);
	}
}

CBasePlayer@ findActivator() {
	for ( int i = 1; i <= g_Engine.maxClients; i++ ) {
		CBasePlayer@ plr = g_PlayerFuncs.FindPlayerByIndex(i);
		
		if (plr is null or !plr.IsConnected())
			continue;
		
		CustomKeyvalues@ pCustom = plr.GetCustomKeyvalues();
		CustomKeyvalue pValue( pCustom.GetKeyvalue( "$i_cameraUser" ) );
		if (pValue.GetInteger() == 1) {			
			pCustom.SetKeyvalue("$i_cameraUser", 0);
			return plr;
		}
	}
	
	return null;
}

void findCameraEnts() {
	float delay = 0.1f;
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "trigger_camera"); 

		if (ent !is null) {
			g_cameras.insertLast(ent);
		}
	} while (ent !is null);
	
	println("[MicFix] Monitoring " + g_cameras.size() + " cameras.");
}

void clientCommand(CBaseEntity@ plr, string cmd) {
	NetworkMessage m(MSG_ONE, NetworkMessages::NetworkMessageType(9), plr.edict());
		m.WriteString(";" + cmd + ";");
	m.End();
}

void globalClientCommand(string cmd) {
	NetworkMessage m(MSG_ALL, NetworkMessages::NetworkMessageType(9), null);
		m.WriteString(";" + cmd + ";");
	m.End();
}