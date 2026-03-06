#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#include <PTaH>

#include "itemdef.sp"

#define BASE_STR_LEN 128

ConVar cvarShowHintByDefault;

Cookie cookieNoHintWhenEnter;

// deagle/r8
Cookie cookiePowerfulPistol;
// usp-s/p2000
Cookie cookieCTStartPistol;
// cz/tec9
Cookie cookieAutoPistolT;
// cz/five-seven
Cookie cookieAutoPistolCT;
// mp7/mp5sd
Cookie cookieMP;
// m4a1/m4a4
Cookie cookieAR15;

enum GiveWeaponAction {
    GiveWeapon_Block,
    GiveWeapon_Handled,
    GiveWeapon_Continue
}

#define DEAGLE_NAME "deagle"
#define R8_NAME "r8"
#define USP_NAME "usp"
#define P2000_NAME "p2000"
#define CZ_T_NAME "cz_t"
#define CZ_CT_NAME "cz_ct"
#define TEC9_NAME "tec9_t"
#define FIVE_SEVEN_NAME "fiveseven_ct"
#define MP7_NAME "mp7"
#define MP5SD_NAME "mp5sd"
#define M4A1_NAME "m4a1"
#define M4A4_NAME "m4a4"

#define DEAGLE_CLASSNAME "deagle"
#define R8_CLASSNAME "revolver"
#define USP_CLASSNAME "usp_silencer"
#define P2000_CLASSNAME "hkp2000"
#define CZ_CLASSNAME "cz75a"
#define TEC9_CLASSNAME "tec9"
#define FIVE_SEVEN_CLASSNAME "fiveseven"
#define MP7_CLASSNAME "mp7"
#define MP5SD_CLASSNAME "mp5sd"
#define M4A1_CLASSNAME "m4a1_silencer"
#define M4A4_CLASSNAME "m4a1"

#define DEAGLE_PRICE 700
#define R8_PRICE 600

// usp and p2000 have the same price
#define USP_PRICE 200
// cz tec9 fiveseven all have the same price
#define CZ_PRICE 500
// mp7 and mp5sd have the same price
#define MP7_PRICE 1500

#define M4A1_PRICE 2900
#define M4A4_PRICE 3100

public Plugin myinfo = {
    name = "CSGO Weapon Selector",
    author = "Eric Zhang",
    description = "Select CSGO weapon",
    version = "1.1",
    url = "https://ericaftereric.top"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    char game[PLATFORM_MAX_PATH];
    GetGameFolderName(game, sizeof(game));
    if (!StrEqual(game, "csgo")) {
        strcopy(error, err_max, "This plugin only works on Counter-Strike: Global Offensive");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart() {
    LoadTranslations("csgo-weapon-selector.phrases");

    cvarShowHintByDefault = CreateConVar("sm_weapon_select_hint_default", "1", "Tell clients they can select weapons by default.");

    cookieNoHintWhenEnter = new Cookie("Show weapon select hint", "Toggle the weapon select hint when you enter the server.", CookieAccess_Public);
    cookiePowerfulPistol = new Cookie("Powerful pistol", "Power pistol pref", CookieAccess_Private);
    cookieCTStartPistol = new Cookie("CT start pistol", "CT start pistol pref", CookieAccess_Private);
    cookieAutoPistolT = new Cookie("Auto pistol T", "Auto pistol T pref", CookieAccess_Private);
    cookieAutoPistolCT = new Cookie("Auto pistol CT", "Auto pistol CT pref", CookieAccess_Private);
    cookieMP = new Cookie("MP 57", "MP pref", CookieAccess_Private);
    cookieAR15 = new Cookie("AR15", "AR15 pref", CookieAccess_Private);

    cookieNoHintWhenEnter.SetPrefabMenu(CookieMenu_OnOff_Int, "Show weapon select hint", OnHintCookieMenu);

    HookEvent("player_team", Event_PlayerTeam);
    PTaH(PTaH_GiveNamedItemPre, Hook, OnGiveNamedItemPre);

    RegConsoleCmd("sm_selectweapon", Cmd_SelectWeapon);
#if defined DEBUG
    RegConsoleCmd("sm_check_selectweapon", Cmd_OnWeaponCheck);
#endif

    AutoExecConfig();
}

public void OnHintCookieMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
    if (action == CookieMenuAction_DisplayOption) {
        Format(buffer, maxlen, "%t", "CSGO_WEAPONSELECT_PREF_MENU", client);
    }
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client)) {
        return;
    }
    if (cookieNoHintWhenEnter.GetInt(client, cvarShowHintByDefault.BoolValue ? 1 : 0)) {
        PrintToChat(client, "%t", "CSGO_WEAPONSELECT_HINT");
    }
}

public Action Cmd_SelectWeapon(int client, int args) {
    if (!IsValidClient(client)) {
        return Plugin_Continue;
    }
    ShowFirstMenu(client);
    return Plugin_Handled;
}

#if defined DEBUG
public Action Cmd_OnWeaponCheck(int client, int args) {
    if (!IsValidClient(client)) {
        return Plugin_Continue;
    }

    char powerfulPistol[BASE_STR_LEN], ctStartPistol[BASE_STR_LEN], autoPistolT[BASE_STR_LEN],
        autoPistolCT[BASE_STR_LEN], mp57[BASE_STR_LEN], ar15[BASE_STR_LEN];

    cookiePowerfulPistol.Get(client, powerfulPistol, sizeof(powerfulPistol));
    cookieCTStartPistol.Get(client, ctStartPistol, sizeof(ctStartPistol));
    cookieAutoPistolT.Get(client, autoPistolT, sizeof(autoPistolT));
    cookieAutoPistolCT.Get(client, autoPistolCT, sizeof(autoPistolCT));
    cookieMP.Get(client, mp57, sizeof(mp57));
    cookieAR15.Get(client, ar15, sizeof(ar15));

    ReplyToCommand(client, "cookiePowerfulPistol: %s", powerfulPistol);
    ReplyToCommand(client, "cookieCTStartPistol: %s", ctStartPistol);
    ReplyToCommand(client, "cookieAutoPistolT: %s", autoPistolT);
    ReplyToCommand(client, "cookieAutoPistolCT: %s", autoPistolCT);
    ReplyToCommand(client, "cookieMP: %s", mp57);
    ReplyToCommand(client, "cookieAR15: %s", ar15);

    return Plugin_Handled;
}
#endif

public Action CS_OnBuyCommand(int client, const char[] weapon) {
#if defined DEBUG
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    LogMessage("CS_OnBuyCommand: %s (client id %d) wants to buy %s", name, client, weapon);
#endif
    if (!IsValidClient(client) || GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0) {
        return Plugin_Continue
    }

    GiveWeaponAction action = OnClientWeaponGive(client, weapon);
    if (action == GiveWeapon_Handled) {
        return Plugin_Changed;
    }
    if (action == GiveWeapon_Block) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action CS_OnGetWeaponPrice(int client, const char[] weapon, int &price) {
#if defined DEBUG
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    LogMessage("CS_OnGetWeaponPrice: %s (client id %d) gets price %d for weapon %s", name, client, price, weapon);
#endif
    char clientPref[BASE_STR_LEN];
    if (StrEqual(weapon, DEAGLE_CLASSNAME) || StrEqual(weapon, R8_CLASSNAME)) {
        cookiePowerfulPistol.Get(client, clientPref, sizeof(clientPref));
        if (StrEqual(clientPref, DEAGLE_NAME)) {
            price = DEAGLE_PRICE;
        } else if (StrEqual(clientPref, R8_NAME)) {
            price = R8_PRICE;
        }
        return Plugin_Changed;
    } else if (StrEqual(weapon, M4A4_CLASSNAME) || StrEqual(weapon, M4A1_CLASSNAME)) {
        cookieAR15.Get(client, clientPref, sizeof(clientPref));
        if (StrEqual(clientPref, M4A4_NAME)) {
            price = M4A4_PRICE;
        } else if (StrEqual(clientPref, M4A1_NAME)) {
            price = M4A1_PRICE;
        }
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action OnGiveNamedItemPre(int iClient, char sClassname[64], CEconItemView &pItemView, bool &bIgnoredView, bool &bOriginNULL, float vecOrigin[3]) {
    // hack to grant usp-s/p2000 on spawn
    if (GetClientTeam(iClient) == CS_TEAM_CT) {
        if (StrEqual(sClassname, ("weapon_" ... P2000_CLASSNAME)) || StrEqual(sClassname, ("weapon_" ... USP_CLASSNAME))) {
            char targetWeapon[BASE_STR_LEN], userPref[BASE_STR_LEN];
            cookieCTStartPistol.Get(iClient, userPref, sizeof(userPref));
            if (StrEqual(userPref, USP_NAME)) {
                strcopy(targetWeapon, sizeof(targetWeapon), ("weapon_" ... USP_CLASSNAME));
            } else if (StrEqual(userPref, P2000_NAME)) {
                strcopy(targetWeapon, sizeof(targetWeapon), ("weapon_" ... P2000_CLASSNAME));
            } else {
                return Plugin_Continue;
            }
            if (StrEqual(targetWeapon, sClassname)) {
                return Plugin_Continue;
            }
            strcopy(sClassname, sizeof(sClassname), targetWeapon);
#if defined DEBUG
            char clientName[MAX_NAME_LENGTH];
            GetClientName(iClient, clientName, sizeof(clientName));
            LogMessage("OnGiveNamedItemPre: Replacing staing pistol with %s on client %s (client id %d)",
                sClassname, targetWeapon, clientName, iClient);
#endif
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

void ShowFirstMenu(int client) {
    char title[BASE_STR_LEN], powerfulPistol[BASE_STR_LEN], ctStartPistol[BASE_STR_LEN],
        autoPistolT[BASE_STR_LEN], autoPistolCT[BASE_STR_LEN], mp57[BASE_STR_LEN], ar15[BASE_STR_LEN];

    Format(title, sizeof(title), "%T", "CSGO_WEAPONSELECT_MENU", client);
    Format(powerfulPistol, sizeof(powerfulPistol), "%T", "CSGO_WEAPONSELECT_POWERFUL_PISTOL", client);
    Format(ctStartPistol, sizeof(ctStartPistol), "%T", "CSGO_WEAPONSELECT_CT_START_PISTOL", client);
    Format(autoPistolT, sizeof(autoPistolT), "%T", "CSGO_WEAPONSELECT_AUTO_PISTOL_T", client);
    Format(autoPistolCT, sizeof(autoPistolCT), "%T", "CSGO_WEAPONSELECT_AUTO_PISTOL_CT", client);
    Format(mp57, sizeof(mp57), "%T", "CSGO_WEAPONSELECT_MP", client);
    Format(ar15, sizeof(ar15), "%T", "CSGO_WEAPONSELECT_AR15", client);

    Menu menu = new Menu(Menu_FirstMenuHandler);
    menu.SetTitle(title);
    menu.AddItem("powerfulPistol", powerfulPistol);
    menu.AddItem("ctStartPistol", ctStartPistol);
    menu.AddItem("autoPistolT", autoPistolT);
    menu.AddItem("autoPistolCT", autoPistolCT);
    menu.AddItem("mp", mp57);
    menu.AddItem("ar15", ar15);
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowSecondMenu(int client, const char[] type) {
    Menu menu = new Menu(Menu_SecondMenuHandler);
    char title[BASE_STR_LEN];
    Format(title, sizeof(title), "%T", "CSGO_WEAPONSELECT_MENU", client);
    menu.SetTitle(title);
    char userPref[BASE_STR_LEN];
    // this sucks, please help
    if (StrEqual(type, "powerfulPistol")) {
        cookiePowerfulPistol.Get(client, userPref, sizeof(userPref));
        char deagle[BASE_STR_LEN], r8[BASE_STR_LEN];
        Format(deagle, sizeof(deagle), "%T", "CSGO_WEAPONSELECT_DEAGLE", client);
        Format(r8, sizeof(r8), "%T", "CSGO_WEAPONSELECT_R8", client);
        if (StrEqual(userPref, DEAGLE_NAME)) {
            char deagleDisplay[BASE_STR_LEN];
            Format(deagleDisplay, sizeof(deagleDisplay), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, deagle);
            menu.AddItem(DEAGLE_NAME, deagleDisplay, ITEMDRAW_DISABLED);
            menu.AddItem(R8_NAME, r8);
        } else if (StrEqual(userPref, R8_NAME)) {
            char r8Display[BASE_STR_LEN];
            Format(r8Display, sizeof(r8Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, r8);
            menu.AddItem(DEAGLE_NAME, deagle);
            menu.AddItem(R8_NAME, r8Display, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(DEAGLE_NAME, deagle);
            menu.AddItem(R8_NAME, r8);
        }
    } else if (StrEqual(type, "ctStartPistol")) {
        cookieCTStartPistol.Get(client, userPref, sizeof(userPref));
        char p2000[BASE_STR_LEN], usps[BASE_STR_LEN];
        Format(p2000, sizeof(p2000), "%T", "CSGO_WEAPONSELECT_P2000", client);
        Format(usps, sizeof(usps), "%T", "CSGO_WEAPONSELECT_USPS", client);
        if (StrEqual(userPref, P2000_NAME)) {
            char p2000Display[BASE_STR_LEN];
            Format(p2000Display, sizeof(p2000Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, p2000);
            menu.AddItem(P2000_NAME, p2000Display, ITEMDRAW_DISABLED);
            menu.AddItem(USP_NAME, usps);
        } else if (StrEqual(userPref, USP_NAME)) {
            char uspsDisplay[BASE_STR_LEN];
            Format(uspsDisplay, sizeof(uspsDisplay), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, usps);
            menu.AddItem(P2000_NAME, p2000);
            menu.AddItem(USP_NAME, uspsDisplay, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(P2000_NAME, p2000);
            menu.AddItem(USP_NAME, usps)
        }
    } else if (StrEqual(type, "autoPistolT")) {
        cookieAutoPistolT.Get(client, userPref, sizeof(userPref));
        char cz75[BASE_STR_LEN], tec9[BASE_STR_LEN];
        Format(cz75, sizeof(cz75), "%T", "CSGO_WEAPONSELECT_CZ75", client);
        Format(tec9, sizeof(tec9), "%T", "CSGO_WEAPONSELECT_TEC9", client);
        if (StrEqual(userPref, CZ_T_NAME)) {
            char cz75Display[BASE_STR_LEN];
            Format(cz75Display, sizeof(cz75Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, cz75);
            menu.AddItem(CZ_T_NAME, cz75Display, ITEMDRAW_DISABLED);
            menu.AddItem(TEC9_NAME, tec9);
        } else if (StrEqual(userPref, TEC9_NAME)) {
            char tec9Display[BASE_STR_LEN];
            Format(tec9Display, sizeof(tec9Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, tec9);
            menu.AddItem(CZ_T_NAME, cz75);
            menu.AddItem(TEC9_NAME, tec9, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(CZ_T_NAME, cz75);
            menu.AddItem(TEC9_NAME, tec9);
        }
    } else if (StrEqual(type, "autoPistolCT")) {
        cookieAutoPistolCT.Get(client, userPref, sizeof(userPref));
        char cz75[BASE_STR_LEN], fiveseven[BASE_STR_LEN];
        Format(cz75, sizeof(cz75), "%T", "CSGO_WEAPONSELECT_CZ75", client);
        Format(fiveseven, sizeof(fiveseven), "%T", "CSGO_WEAPONSELECT_FIVESEVEN", client);
        if (StrEqual(userPref, CZ_CT_NAME)) {
            char cz75Display[BASE_STR_LEN];
            Format(cz75Display, sizeof(cz75Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, cz75);
            menu.AddItem(CZ_CT_NAME, cz75Display, ITEMDRAW_DISABLED);
            menu.AddItem(FIVE_SEVEN_NAME, fiveseven);
        } else if (StrEqual(userPref, FIVE_SEVEN_NAME)) {
            char fivesevenDisplay[BASE_STR_LEN];
            Format(fivesevenDisplay, sizeof(fivesevenDisplay), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, fiveseven);
            menu.AddItem(CZ_CT_NAME, cz75);
            menu.AddItem(FIVE_SEVEN_NAME, fivesevenDisplay, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(CZ_CT_NAME, cz75);
            menu.AddItem(FIVE_SEVEN_NAME, fiveseven);
        }
    } else if (StrEqual(type, "mp")) {
        cookieMP.Get(client, userPref, sizeof(userPref));
        char mp7[BASE_STR_LEN], mp5sd[BASE_STR_LEN];
        Format(mp7, sizeof(mp7), "%T", "CSGO_WEAPONSELECT_MP7", client);
        Format(mp5sd, sizeof(mp5sd), "%T", "CSGO_WEAPONSELECT_MP5SD", client);
        if (StrEqual(userPref, MP7_NAME)) {
            char mp7Display[BASE_STR_LEN];
            Format(mp7Display, sizeof(mp7Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, mp7);
            menu.AddItem(MP7_NAME, mp7Display, ITEMDRAW_DISABLED);
            menu.AddItem(MP5SD_NAME, mp5sd);
        } else if (StrEqual(userPref, MP5SD_NAME)) {
            char mp5sdDisplay[BASE_STR_LEN];
            Format(mp5sdDisplay, sizeof(mp5sdDisplay), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, mp5sd);
            menu.AddItem(MP7_NAME, mp7);
            menu.AddItem(MP5SD_NAME, mp5sdDisplay, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(MP7_NAME, mp7);
            menu.AddItem(MP5SD_NAME, mp5sd);
        }
    } else if (StrEqual(type, "ar15")) {
        cookieAR15.Get(client, userPref, sizeof(userPref));
        char m4a4[BASE_STR_LEN], m4a1s[BASE_STR_LEN];
        Format(m4a4, sizeof(m4a4), "%T", "CSGO_WEAPONSELECT_M4A4", client);
        Format(m4a1s, sizeof(m4a1s), "%T", "CSGO_WEAPONSELECT_M4A1S", client);
        if (StrEqual(userPref, M4A4_NAME)) {
            char m4a4Display[BASE_STR_LEN];
            Format(m4a4Display, sizeof(m4a4Display), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, m4a4);
            menu.AddItem(M4A4_NAME, m4a4Display, ITEMDRAW_DISABLED);
            menu.AddItem(M4A1_NAME, m4a1s);
        } else if (StrEqual(userPref, M4A1_NAME)) {
            char m4a1sDisplay[BASE_STR_LEN];
            Format(m4a1sDisplay, sizeof(m4a1sDisplay), "%T", "CSGO_WEAPONSELECT_MENU_SELECTED", client, m4a1s);
            menu.AddItem(M4A4_NAME, m4a4);
            menu.AddItem(M4A1_NAME, m4a1sDisplay, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(M4A4_NAME, m4a4);
            menu.AddItem(M4A1_NAME, m4a1s);
        }
    } else {
        delete menu;
        SetFailState("Invalid type %s passed to ShowSecondMenu, something has gone horribly wrong", type);
        return;
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void Menu_FirstMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[BASE_STR_LEN];
            menu.GetItem(param2, info, sizeof(info));
            ShowSecondMenu(param1, info);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public void Menu_SecondMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[BASE_STR_LEN];
            menu.GetItem(param2, info, sizeof(info));
            ApplyWeaponPref(param1, info);
        }
        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                ShowFirstMenu(param1);
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

void ApplyWeaponPref(int client, const char[] weapon) {
    if (StrEqual(weapon, DEAGLE_NAME) || StrEqual(weapon, R8_NAME)) {
        cookiePowerfulPistol.Set(client, weapon);
    } else if (StrEqual(weapon, P2000_NAME) || StrEqual(weapon, USP_NAME)) {
        cookieCTStartPistol.Set(client, weapon);
    } else if (StrEqual(weapon, CZ_T_NAME) || StrEqual(weapon, TEC9_NAME)) {
        cookieAutoPistolT.Set(client, weapon);
    } else if (StrEqual(weapon, CZ_CT_NAME) || StrEqual(weapon, FIVE_SEVEN_NAME)) {
        cookieAutoPistolCT.Set(client, weapon);
    } else if (StrEqual(weapon, MP7_NAME) || StrEqual(weapon, MP5SD_NAME)) {
        cookieMP.Set(client, weapon);
    } else if (StrEqual(weapon, M4A4_NAME) || StrEqual(weapon, M4A1_NAME)) {
        cookieAR15.Set(client, weapon);
    }
}

GiveWeaponAction OnClientWeaponGive(int client, const char[] weapon) {
    int price = 0;
    char userPref[BASE_STR_LEN], targetWeapon[BASE_STR_LEN];
    if (StrEqual(weapon, DEAGLE_CLASSNAME) || StrEqual(weapon, R8_CLASSNAME)) {
        cookiePowerfulPistol.Get(client, userPref, sizeof(userPref));
        if (StrEqual(userPref, DEAGLE_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), DEAGLE_CLASSNAME);
            price = DEAGLE_PRICE;
        } else if (StrEqual(userPref, R8_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), R8_CLASSNAME);
            price = R8_PRICE;
        }
    } else if (StrEqual(weapon, P2000_CLASSNAME) || StrEqual(weapon, USP_CLASSNAME)) {
        price = USP_PRICE;
        cookieCTStartPistol.Get(client, userPref, sizeof(userPref));
        if (StrEqual(userPref, P2000_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), P2000_CLASSNAME);
        } else if (StrEqual(userPref, USP_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), USP_CLASSNAME);
        } else {
            price = 0;
        }
    } else if (StrEqual(weapon, TEC9_CLASSNAME) || StrEqual(weapon, FIVE_SEVEN_CLASSNAME) || StrEqual(weapon, CZ_CLASSNAME)) {
        price = CZ_PRICE;
        if (GetClientTeam(client) == CS_TEAM_T) {
            cookieAutoPistolT.Get(client, userPref, sizeof(userPref));
        } else {
            cookieAutoPistolCT.Get(client, userPref, sizeof(userPref));
        }
        if (StrEqual(userPref, CZ_T_NAME) || StrEqual(userPref, CZ_CT_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), CZ_CLASSNAME);
        } else if (StrEqual(userPref, FIVE_SEVEN_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), FIVE_SEVEN_CLASSNAME);
        } else if (StrEqual(userPref, TEC9_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), TEC9_CLASSNAME);
        } else {
            price = 0;
        }
    } else if (StrEqual(weapon, MP7_CLASSNAME) || StrEqual(weapon, MP5SD_CLASSNAME)) {
        price = MP7_PRICE;
        cookieMP.Get(client, userPref, sizeof(userPref));
        if (StrEqual(userPref, MP7_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), MP7_CLASSNAME);
        } else if (StrEqual(userPref, MP5SD_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), MP5SD_CLASSNAME);
        } else {
            price = 0;
        }
    } else if (StrEqual(weapon, M4A4_CLASSNAME) || StrEqual(weapon, M4A1_CLASSNAME)) {
        cookieAR15.Get(client, userPref, sizeof(userPref));
        if (StrEqual(userPref, M4A4_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), M4A4_CLASSNAME);
            price = M4A4_PRICE;
        } else if (StrEqual(userPref, M4A1_NAME)) {
            strcopy(targetWeapon, sizeof(targetWeapon), M4A1_CLASSNAME);
            price = M4A1_PRICE;
        }
    }

    if (!strlen(targetWeapon) || price == 0) {
        return GiveWeapon_Continue;
    }

    int money = GetClientMoney(client);
    if (money < price) {
        return GiveWeapon_Block;
    }

    SetClientMoney(client, money - price);
    char weaponClassName[BASE_STR_LEN] = "weapon_";
    StrCat(weaponClassName, sizeof(weaponClassName), targetWeapon);
    if (PlayerHasWeapon(client, weaponClassName)) {
        return GiveWeapon_Block;
    }
    int dropSlot = 1;
    if (StrEqual(targetWeapon, MP7_CLASSNAME) || StrEqual(targetWeapon, MP5SD_CLASSNAME) ||
        StrEqual(targetWeapon, M4A1_CLASSNAME) || StrEqual(targetWeapon, M4A4_CLASSNAME)) {
        dropSlot = 0;
    }
    PlayerDropWeapon(client, dropSlot);
    GivePlayerItem(client, weaponClassName);
#if defined DEBUG
    char clientName[MAX_NAME_LENGTH];
    GetClientName(client, clientName, sizeof(clientName));
    LogMessage("OnClientWeaponGive: Giving %s (client id: %d) weapon %s instead of %s based on preference %s with a price of %d",
        clientName, client, targetWeapon, weapon, userPref, price);
#endif

    return GiveWeapon_Handled;
}

int GetClientMoney(int client) {
    return GetEntProp(client, Prop_Send, "m_iAccount");
}

void SetClientMoney(int client, int money) {
    SetEntProp(client, Prop_Send, "m_iAccount", money);
}

bool PlayerHasWeapon(int client, const char[] weapon) {
    int myWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    if (myWeapons == -1) {
        return false;
    }
    for (int offset = 0; offset < 128; offset += 4) {
        int weap = GetEntDataEnt2(client, myWeapons + offset);
        if (IsValidEdict(weap)) {
            char classname[BASE_STR_LEN];
            GetWeaponClassname(weap, classname, sizeof(classname));
            LogMessage("classname: %s", classname);
            LogMessage("weapon: %s", weapon);
            if (StrEqual(classname, weapon)) {
                return true;
            }
        }
    }
    return false;
}

void PlayerDropWeapon(int client, int slot) {
    int wepSlot = GetPlayerWeaponSlot(client, slot);
    if (wepSlot != -1) {
        CS_DropWeapon(client, wepSlot, false);
    }
}

public bool IsValidClient(int client) {
    return IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client);
}

void GetWeaponClassname(int weapon, char[] classname, int maxLen) {
    int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    ItemDefinitionIndex indexDef = view_as<ItemDefinitionIndex>(index);

    switch (indexDef) {
        case WEAPON_DEAGLE: {
            strcopy(classname, maxLen, ("weapon_" ... DEAGLE_CLASSNAME));
        }
        case WEAPON_REVOLVER: {
            strcopy(classname, maxLen, ("weapon_" ... R8_CLASSNAME));
        }
        case WEAPON_CZ75A: {
            strcopy(classname, maxLen, ("weapon_" ... CZ_CLASSNAME));
        }
        case WEAPON_TEC9: {
            strcopy(classname, maxLen, ("weapon_" ... TEC9_CLASSNAME));
        }
        case WEAPON_FIVESEVEN: {
            strcopy(classname, maxLen, ("weapon_" ... FIVE_SEVEN_CLASSNAME));
        }
        case WEAPON_MP7: {
            strcopy(classname, maxLen, ("weapon_" ... MP7_CLASSNAME));
        }
        case WEAPON_MP5: {
            strcopy(classname, maxLen, ("weapon_" ... MP5SD_CLASSNAME));
        }
        case WEAPON_M4A1_SILENCER: {
            strcopy(classname, maxLen, ("weapon_" ... M4A1_CLASSNAME));
        }
        // m4a4
        case WEAPON_M4A1: {
            strcopy(classname, maxLen, ("weapon_" ... M4A4_CLASSNAME));
        }
        case WEAPON_USP_SILENCER: {
            strcopy(classname, maxLen, ("weapon_" ... USP_CLASSNAME));
        }
        case WEAPON_HKP2000: {
            strcopy(classname, maxLen, ("weapon_" ... P2000_CLASSNAME));
        }
    }
}
