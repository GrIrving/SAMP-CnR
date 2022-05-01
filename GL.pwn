#include <a_samp>
#undef MAX_PLAYERS
#define MAX_PLAYERS (30)
#define MAX_HOUSES (65)
#define MAX_HOUSE_MODELS (6)
#define AllowPicks(%0) SetTimerEx("AllowPick", 1000, false, "i", %0)
#define DisablePicks(%0) pInfo[%0][disablepick] = true
#include <core>
#include <float>
#include <YSI\y_iterate>
#include <a_zones>
#include "../include/gl_common.inc"
#include "../include/gl_spawns.inc"
//#include "../include/fixes.inc" //BUGS menus
#include <YSI\y_ini>  //If you have installed YSI, then you shouldn't have any problem
#include <zcmd>
#include <sscanf2>
#include <streamer>

native WP_Hash(buffer[],len,const str[]); // Whirlpool native, add it at the top of your script under includes
native IsValidVehicle(vehicleid);

#define UserPath "Users/%s.ini" //Will define user's account path. In this case, we will save it in Scriptfiles/Users. So create a file inside of your Scriptfiles folder called Users
#define HousePath "Houses/%d.ini"
#define BanPathL "Bans/%s.ini"
#define WhitePathL "Whitelist/%s.ini"
#define IPBanPathL "Bans/%s.ini"

#pragma tabsize 0

//----------------------------------------------------------

#define COLOR_WHITE 		0xFFFFFFFF
#define Col_Green 0x00FF00FF
#define Col_Red 0xFF0000FF
#define Col_LightOrange 0xffcb00ff
#define Col_Orange 0xffa200ff
#define Col_Gray 0xAAAAAAAA
#define Col_Blue 0x001effff
#define Col_LightBlue 0x518cffff
#define Col_Yellow 0xffff00ff
#define Col_Pink 0xffb6e6ff
#define COLOR_NORMAL_PLAYER 0xFFBB7777

#define CITY_LOS_SANTOS 	0
#define CITY_SAN_FIERRO 	1
#define CITY_LAS_VENTURAS 	2
#define PRESSEDKEY(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
	
new total_vehicles_from_files=0;

// Class selection globals
new gPlayerCitySelection[MAX_PLAYERS];
new gPlayerHasCitySelected[MAX_PLAYERS];
new gPlayerLastCitySelectionTick[MAX_PLAYERS];

new Text:txtClassSelHelper;
new Text:txtLosSantos;
new Text:txtSanFierro;
new Text:txtLasVenturas;

new thisanimid=0;
new lastanimid=0;

new VehicleNames[212][] = { //a catastroph :P
{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},{"Sentinel"},{"Dumper"},
{"Firetruck"},{"Trashmaster"},{"Stretch"},{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},
{"Cheetah"},{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},{"Washington"},
{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},{"Premier"},{"Enforcer"},{"Securicar"},
{"Banshee"},{"Predator"},{"Bus"},{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"},{"Previon"},
{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},{"Packer"},{"Monster"},
{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},{"Tram"},{"Trailer 2"},{"Turismo"},
{"Speeder"},{"Reefer"},{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},{"Glendale"},{"Oceanic"},
{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},
{"Rustler"},{"ZR-350"},{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},{"Marquis"},
{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},{"FBI Rancher"},{"Virgo"},{"Greenwood"},
{"Jetmax"},{"Hotring"},{"Sandking"},{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},
{"Mesa"},{"RC Goblin"},{"Hotring Racer A"},{"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
{"Super GT"},{"Elegant"},{"Journey"},{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropdust"},{"Stunt"},
{"Tanker"}, {"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},{"Shamal"},{"Hydra"},{"FCR-900"},
{"NRG-500"},{"HPV1000"},{"Cement Truck"},{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},
{"Willard"},{"Forklift"},{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},
{"Blade"},{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
{"Firetruck LA"},{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},{"Tampa"},{"Sunrise"},{"Merit"},
{"Utility"},{"Nevada"},{"Yosemite"},{"Windsor"},{"Monster A"},{"Monster B"},{"Uranus"},{"Jester"},
{"Sultan"},{"Stratum"},{"Elegy"},{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},
{"Bandito"},{"Freight Flat"},{"Streak Carriage"},{"Kart"},{"Mower"},{"Duneride"},{"Sweeper"},
{"Broadway"},{"Tornado"},{"AT-400"},{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},
{"Tug"},{"Trailer 3"},{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},{"Club"},{"Freight Carriage"},
{"Trailer 3"},{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},{"Police Car (SFPD)"},
{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},
{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},
{"Utility Trailer"}};

enum //Dialogs
{
	drules,
	dcolors,
	dcmds,
	dcmdslist,
	dclasses,
	dregister,
	ddrugs,
	dhospital,
	dbank,
	dATM,
	dATMwithdraw,
	dATMbalance,
	dTF7,
	dhouse,
	dbankwithdraw,
	dbankdeposit,
	dbankbalance,
	dgrottiwelcome,
	dgrottibuy,
	dgrottidelete,
	dgrottibring,
	dstats,
	dofferdrugs,
	dlogin,
	dchangepw
}

enum classes//classes
{
	cNone,
	cCop,
	cRobber,
	cCarJack,
	cWeaponDeal,
	cDrugDeal
}
enum PlayerInfo
{
    Pass[129], //User's password
	bool:Passflag, //Force change
    Adminlevel, //User's admin level
    VIPlevel, //User's vip level
    Money, //User's money
    Scores, //User's scores
	LastPM, //Last user id who PMed
	DailyLogin, //Login bonus
	/*Robs*/
	RobTime,//Time left to rob
	Timerid,//Timer for robbing, jail, etc.
	RobUsage,//Last rob
	Robbed,//Last time robbed
	WalletsLeft,//How many robs are left
	classes:Class,//Player class
	JailTime,//Jail time
	JailTimer,//Jail timer
	Spawnedv,//for vehicle spawned
	BCuffsTime, //Last cuff break try
	CuffTimer, //To avoid people left cuffed
	TazeTime, //To avoid taze spamming
	CurrentHouse, //Current house visiting
	SpawnHouse, //House to spawn
	HackCounter,//For many hacks
	/*Drugs*/
	Drugs, //Drug amount in pocket
	DrugTime, //Drugs active time
	DrugTimer, //TimerID for drugs
	DrugAmount, //Amount of drugs taken
	/*Weapon Dealer*/
	WeaponStacks,
	/*General Dealer*/
	DealingCD,
	DealerID,
	DealingPrice,
	/*Rape*/
	RapeTimer,//TimerID for rape
	RapeUsage, //Avoid spam
	LastRaped, //Last time raped
	BankMoney, //Money in bank
	/*Vehicles*/
	CurrentVeh,//Current user's veh (driver)
	vModel1, //For car #1 ownership
	vID1, //For car #1 ownership
	vModel2, //For car #2 ownership
	vID2, //For car #2 ownership
	vModel3, //For car #3 ownership
	vID3, //For car #3 ownership
	LastPoliceSteal, //Last time you stole a police vehicle
	LastWantedCarry,//Last time you carried a wanted person
	/*Stats*/
	sArrests,
	sRobs,
	sRapes,
	sWeaponDeals,
	sTimeSpent,
	sDrugDeals,
	LoginTime,
	/*Bools*/
	bool:tazed, //Is the player tazed?
	bool:drugbag, //Does the player own a drug bag?
	bool:raped,//Is the player raped?
	bool:alive,//Is player alive?
	bool:login, //Did the player login?
	bool:pmon, //Is player receiving messages?
	bool:adseepm, //Does the admin see PMs?
	bool:cuffed,//Is Player Cuffed?
	bool:triedescaping,//Did the player already try escaping?
	bool:disablepick, //Should the pickup be disabled? (avoid spam of type 1 pick)
	bool:needweapons,
	bool:needdrugs,
	bool:needjail,
	Float:LastX,//For exiting buildings and returns
	Float:LastY,//For exiting buildings and returns
	Float:LastZ,//For exiting buildings and returns
	LastInterior//For exiting buildings and returns
}
enum VehicleOwnGroups
{
	gNone,
	gPlayer,
	gAdmin,
}
enum VehicleInfo
{
	Driver,
	VehicleOwnGroups:OwnGroup //Who owns it (faction/player)
}
enum Stores
{
	Cluck,
	Saloon,
	Pizza,
	Burger,
	Tattoo,
	Hair,
	Gym,
	Binco,
	Pig,
	Bar,
	DS,
	Victim,
	Zip,
	Pro,
	InsideTrack,
	Donut
}
enum HouseInfo
{
	hID, //House ID
	hPickup, //pickupID
	/* House Pickups and Exits */
	Float:hPickX,
	Float:hPickY,
	Float:hPickZ,
	Float:hExitX,
	Float:hExitY,
	Float:hExitZ,
	hDesign, //house type/design
	hPrice,
	bool:owned //Is the house owned?
}
enum HouseModels
{
	Float:hEntryX,
	Float:hEntryY,
	Float:hEntryZ,
	hInterior
}
enum MovingObjects
{
	gAdminGarageID0,
	gAdminGarageID1,
	bool:gAdminGarageState,
	gAdminGaragePID0,
	gAdminGaragePID1,
	bool:gAdminGaragePState,
	gDuckzID,
	bool:gDuckzState //True for open, False for closed.
}
enum Menus
{
	Menu:mWeapons,
	Menu:mWeaponDeals
}
new pInfo[MAX_PLAYERS][PlayerInfo], StorePickups[Stores][2], DrugHouses[2], Hospitals[2], Ammunations[3], Banks[5], ATMs[10], TF7s[5], Grotti, 
	cColors[classes], MenuIDs[Menus], vInfo[MAX_VEHICLES][VehicleInfo], vOwnerName[MAX_VEHICLES][6], PickupModel[MAX_PICKUPS], hInfo[MAX_HOUSES][HouseInfo],
	hOwnerName[MAX_HOUSES][MAX_PLAYER_NAME], hModel[MAX_HOUSE_MODELS][HouseModels], DynamicPickupModel[MAX_PICKUPS], MovingObject[MovingObjects]; //6 = Packed Name. Saves an enourmous 160kb space on the buffer.
//----------------------------------------------------------
main()
{
	print("\n---------------------------------------");
	print("Running New Cops and Robbers - \n");
	print("---------------------------------------\n");
}

//----------------------------------------------------------

forward SetPlayerOCT(playerid); //Original Color and Team
forward unjailp(playerid);
forward jailupdate(playerid);
forward restoretaze(playerid);
forward cuffexpire(playerid);
forward RobbingStore(playerid, pickupid);
forward loadaccount_user(playerid, name[], value[]); //forwarding a new function to load user's data
forward loadhouses_house(houseid, name[], value[]); //load houses function
forward MoneyUpdate();
forward LoadAllVehicles();
forward DrugCheck(playerid);
forward RapeCheck(playerid);
forward SGPlayerPos(playerid, SetPosition);
forward ShowRules(playerid);
forward AllowPick(playerid);
forward KickF(playerid);
forward OnPlayerPickUpDynamicPickup(playerid, pickupid);
forward AddHackCounter(playerid, counter);
stock Path(playerid) //Will create a new stock so we can easily use it later to load/save user's data in user's path
{
    new str[128],name[MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,sizeof(name));
    format(str,sizeof(str),UserPath,name);
    return str;
}
stock hPath(houseid)
{
	new str[20];
	format(str, 20, HousePath, houseid);
	return str;
}
stock BanPath(playerid) //Will create a new stock so we can easily use it later to load/save user's data in user's path
{
    new str[128],name[MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,sizeof(name));
    format(str,sizeof(str),BanPathL,name);
    return str;
}
stock IPBanPath(IP[])
{
	new str[128];
	format(str, 128, IPBanPathL, IP);
	return str;
}
stock WhitePath(name[])
{
	new str[128];
	format(str, 128, WhitePathL, name);
	return str;
}
stock SMPlayerPos(playerid, Float:pX, Float:pY, Float:pZ)//Set Manual Player Position
{
	pInfo[playerid][LastX] = pX;
	pInfo[playerid][LastY] = pY;
	pInfo[playerid][LastZ] = pZ;
	pInfo[playerid][LastInterior] = GetPlayerInterior(playerid);
}
stock jailplayer(playerid, arresterid){
	new pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME], formatted[128], wantedl = GetPlayerWantedLevel(playerid);
	pInfo[playerid][JailTime] = (wantedl<10) ? (wantedl*10+50) : ((wantedl>22) ? (340) : (wantedl*10+120));
	SetPlayerOCT(playerid);
	ResetPlayerWeapons(playerid);
	SetPVarInt(playerid, "active punish", 1);
	pInfo[playerid][needjail] = true; //for anti-hack
	SetPlayerInterior(playerid, 6);
	SetPlayerPos(playerid,264.7426,77.7752,1001.0391);
	GetPlayerName(playerid,pname,MAX_PLAYER_NAME);
	GetPlayerName(arresterid,pname2,MAX_PLAYER_NAME);
	format(formatted, 128, "Wanted criminal %s(%d) has been jailed by %s(%d) for %d seconds.", pname, playerid, pname2, arresterid, pInfo[playerid][JailTime]);
	SendClientMessageToAll(Col_LightOrange, formatted);
	SendClientMessage(playerid, Col_LightOrange, "You may try to escape using /escape.");
	pInfo[playerid][JailTimer] = SetTimerEx("jailupdate", 1000, true, "i", playerid);
	return 1;
}
stock SendPMToAdmins(text[]){
	foreach (new i : Player){
	    if (pInfo[i][adseepm]){
	        SendClientMessage(i, Col_Gray, text);
     	}
    }
    return 1;
}
stock EnterHouse(playerid){
	SMPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX],hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
	SetPlayerInterior(playerid, hModel[hInfo[pInfo[playerid][CurrentHouse]][hDesign]][hInterior]);
	SetPlayerPos(playerid, hModel[hInfo[pInfo[playerid][CurrentHouse]][hDesign]][hEntryX], hModel[hInfo[pInfo[playerid][CurrentHouse]][hDesign]][hEntryY], hModel[hInfo[pInfo[playerid][CurrentHouse]][hDesign]][hEntryZ]);
	SendClientMessage(playerid, Col_LightOrange, "Use /exith to exit the house.");
	return 1;
}
stock BanPlayer(banning, target, reason[], btime = -1){
	new pip[16], formatted[128], pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME];
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	if (banning != -1) GetPlayerName(banning,pname2,MAX_PLAYER_NAME);
	else pname2 = "Autoban";
	GetPlayerIp(target, pip, 16);
	if(fexist(WhitePath(pname))){
		fremove(WhitePath(pname));
		if(banning != -1) SendClientMessage(banning, Col_Green, "Player was whitelisted. Whitelist removed.");
	}
	if(btime == -1) {
		format(formatted, 128, "%s has been permanently banned for %s.", pname, reason);
		SendClientMessageToAll(Col_Red, formatted);
	}
	else btime += gettime();
	format (formatted, 128, "%d\r\n%s\r\nTime: Permanent. By: %s. Reason: %s", btime, pip, pname2, reason);
	new File:BanFile = fopen(BanPath(target)), File:IPBanFile = fopen(IPBanPath(pip));
	fwrite(BanFile, formatted);
	format(formatted, 128, "Player: %s", pname);
	fwrite(IPBanFile, formatted);
	fclose(BanFile), fclose(IPBanFile);
	SendClientMessage(target, Col_Pink, "Think you were banned unfairly? Post an unban request at gcnr.tk");
	SetTimerEx("KickF", 1000, false, "i", target);
}
stock EEPicks(playerid, pickupid)
{
	if(pickupid == Banks[0]|| pickupid == Banks[3] || pickupid == Banks[4]){
		new hours, minutes;
		GetPlayerTime(playerid, hours, minutes);
		if (pickupid == Banks[0]) SMPlayerPos(playerid, 1498.5715,-1586.5768,13.5469);
		else if (pickupid == Banks[3]) SMPlayerPos(playerid, -1500.3237,920.1265,7.1875);
		else SMPlayerPos(playerid, 2597.4331,1891.0922,10.6025);
		if (hours >= 8 && hours < 23){
			SetPlayerPos(playerid, 2309.8052,-15.0160,26.7422);
			SetPlayerFacingAngle(playerid, 270);
			SetPlayerVirtualWorld(playerid, 1);
		}else {
			SendClientMessage(playerid, Col_Pink, "The bank is currently closed. Opening times are between 8:00 and 23:00.");
			SGPlayerPos(playerid, 0);
		}
	} else if(pickupid == Banks[2]){
		SGPlayerPos(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);
	}else if(pickupid == TF7s[0]){
		SMPlayerPos(playerid, 1930.4034,-1762.3552,13.5391);
		SetPlayerInterior(playerid, 17);
		SetPlayerPos(playerid, -24.9845, -184.2724, 1003.5469);
		SetPlayerFacingAngle(playerid, 0);
	}else if(pickupid == TF7s[2]){
		SGPlayerPos(playerid, 0);
	}
	return 1;
}
stock HousePicks(playerid, pickupid)
{
	new houseid, formatted[128], pname[MAX_PLAYER_NAME];
	for (new i; i != MAX_HOUSES ; i++){
		if (hInfo[i][hPickup] != pickupid) continue;
		houseid = i;
		break;
	}
	if (GetPVarInt(playerid, "Admin") >= 4) format(formatted, 128, "House ID: %d", houseid), SendClientMessage(playerid, Col_Pink, formatted);
	DisablePicks(playerid);
	pInfo[playerid][CurrentHouse] = houseid;
	if (DynamicPickupModel[pickupid] == 1272){ //Not owned
		format(formatted, 128, "This house is for sale. Price - %d", hInfo[houseid][hPrice]);
		ShowPlayerDialog(playerid, dhouse, DIALOG_STYLE_LIST, formatted, "Buy house\nVisit house", "Select", "Cancel");
		return 1;
	}
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (!strcmp(hOwnerName[houseid], pname, true)){
		ShowPlayerDialog(playerid, dhouse, DIALOG_STYLE_LIST, "This house belongs to you.", "Enter house\nSell house\nSpawn at this house\nStop spawning in houses", "Select", "Cancel");
	}else{
		pname = hOwnerName[houseid];
		format(formatted, 128, "This house belongs to %s.", pname);
		ShowPlayerDialog(playerid, dhouse, DIALOG_STYLE_LIST, formatted, "Enter house", "Select", "Cancel");
	}
	return 1;
}
stock InfoPicks(playerid, pickupid)
{
	if(pickupid == Grotti){
		ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
		DisablePicks(playerid);
	}else if(pickupid == Banks[1]){
		ShowPlayerDialog(playerid, dbank, DIALOG_STYLE_LIST, "Welcome to the bank", "Deposit Cash\nWithdraw Cash\nCheck Bank Balance", "Select", "Cancel");
	}else if(pickupid == ATMs[0] || pickupid == ATMs[1] || pickupid == ATMs[2] || pickupid == ATMs[3] || pickupid == ATMs[4] || pickupid == ATMs[5] || pickupid == ATMs[6] || pickupid == ATMs[7] || pickupid == ATMs[8] || pickupid == ATMs[9]){
		ShowPlayerDialog(playerid, dATM, DIALOG_STYLE_LIST, "ATM machine", "Withdraw Cash\nCheck Balance", "Select", "Cancel");
	}else if(pickupid == TF7s[1] || pickupid == TF7s[3] || pickupid == TF7s[4]){
		ShowPlayerDialog(playerid, dTF7, DIALOG_STYLE_LIST, "Welcome to the 24/7. What would you like to buy?", "Wallet\t\t$2500\nParachute\t$4000\nCamera\t\t$1500\nFlowers\t$250\nSpray Can(60)\t$450", "Select", "Cancel");
	}
	return 1;
}
stock StorePicks(playerid, pickupid)
{
	if(pickupid == StorePickups[Cluck][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Cluck][1] < gettime()){
			StorePickups[Cluck][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the cluckin' bell. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the cluckin' bell");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The cluckin' bell has been robbed recently.");
	}else if(pickupid == StorePickups[Saloon][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Saloon][1] < gettime()){
			StorePickups[Saloon][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the saloon. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the saloon");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The saloon has been robbed recently.");
	}else if(pickupid == StorePickups[Pro][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Pro][1] < gettime()){
			StorePickups[Pro][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing pro laps. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "pro laps");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Pro laps has been robbed recently.");
	}else if(pickupid == StorePickups[Pizza][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Pizza][1] < gettime()){
			StorePickups[Pizza][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing well stacked pizza. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "well stacked pizza");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Well stacked pizza has been robbed recently.");
	}else if(pickupid == StorePickups[Victim][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Victim][1] < gettime()){
			StorePickups[Victim][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing victim. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "victim");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Victim has been robbed recently.");
	}else if(pickupid == StorePickups[DS][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[DS][1] < gettime()){
			StorePickups[DS][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing DS. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "DS");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "DS has been robbed recently.");
	}else if(pickupid == StorePickups[Burger][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Burger][1] < gettime()){
			StorePickups[Burger][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing burgershot. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "burgershot");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Burgershot has been robbed recently.");
	}else if(pickupid == StorePickups[Tattoo][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Tattoo][1] < gettime()){
			StorePickups[Tattoo][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the tattoo shop. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the tatoo shop");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The tattoo shop has been robbed recently.");
	}else if(pickupid == StorePickups[Hair][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Hair][1] < gettime()){
			StorePickups[Hair][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the barber shop. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the barber shop");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The barber shop has been robbed recently.");
	}else if(pickupid == StorePickups[Gym][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Gym][1] < gettime()){
			StorePickups[Gym][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the gym. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the gym");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The gym has been robbed recently.");
	}else if(pickupid == StorePickups[Binco][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Binco][1] < gettime()){
			StorePickups[Binco][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing binco. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "binco");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Binco has been robbed recently.");
	}else if(pickupid == StorePickups[Zip][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Zip][1] < gettime()){
			StorePickups[Zip][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing zip. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "zip");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Zip has been robbed recently.");
	}else if(pickupid == StorePickups[Pig][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Pig][1] < gettime()){
			StorePickups[Pig][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the pig pen. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the pig pen");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The pig pen has been robbed recently.");
	}else if(pickupid == StorePickups[InsideTrack][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[InsideTrack][1] < gettime()){
			StorePickups[InsideTrack][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing inside track. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "inside track");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "Inside track has been robbed recently.");
	}else if(pickupid == StorePickups[Bar][0]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob stores.");
		if (StorePickups[Bar][1] < gettime()){
			StorePickups[Bar][1]= gettime() + 300;
			pInfo[playerid][RobTime] = 15;
			CommitedCrime(playerid, 2);
			SendClientMessage(playerid, Col_LightOrange, "You are robbing the bar. Please wait inside the building to complete the robbery.");
			PoliceRadioStore(playerid, "the bar");
			pInfo[playerid][Timerid] = SetTimerEx("RobbingStore", 1000, true, "dd", playerid, pickupid);
		}else return SendClientMessage(playerid, Col_LightOrange, "The bar has been robbed recently.");
	}
	return 1;
}
stock CommitedCrime(playerid, increaseby){
	new formatted[128], wantedl = GetPlayerWantedLevel(playerid) + increaseby;
	SetPlayerWantedLevel(playerid, (wantedl > 255) ? (255) : ((wantedl < 0) ? 0 : wantedl));
	SetPlayerTeam(playerid, NO_TEAM);
	wantedl = GetPlayerWantedLevel(playerid);
	if(wantedl==0){
		SetPlayerOCT(playerid);
	}else if(wantedl==1){
		SetPlayerColor(playerid, Col_Yellow);
	}else if(wantedl>=2 && wantedl < 10){
		SetPlayerColor(playerid, Col_Orange);
	}else if(wantedl>=10){
		SetPlayerColor(playerid, Col_Red);
	}
	format(formatted, 128, "**CRIME COMMITED** Wanted level: %d.", wantedl);
	SendClientMessage(playerid, GetPlayerColor(playerid), formatted);
	return 1;
}
stock IsPlayerInRangeOfPlayer(player1, player2, Float:distance){
	new Float:XX1, Float:YY1, Float:ZZ1;
	GetPlayerPos(player1, XX1, YY1, ZZ1);
	return IsPlayerInRangeOfPoint(player2, distance, XX1, YY1, ZZ1);
}
stock LoadHouses()
{
	for (new i; i != MAX_HOUSES ; i++){
		hOwnerName[i] = "NONE";
		if(fexist(hPath(i))){
			INI_ParseFile(hPath(i),"loadhouses_%s", .bExtra = true, .extra = i);
			hInfo[i][hPickup] = CreateDynamicPickup(hInfo[i][owned] ? 1273 : 1272, 1, hInfo[i][hPickX], hInfo[i][hPickY], hInfo[i][hPickZ]);
			DynamicPickupModel[hInfo[i][hPickup]] = hInfo[i][owned] ? 1273 : 1272;
		}
	}
	return 1;
}
stock LoadHouseModels()
{
	hModel[1][hEntryX] = 385.803986;
	hModel[1][hEntryY] = 1471.769897;
	hModel[1][hEntryZ] = 1080.209961;
	hModel[1][hInterior] = 15;
	hModel[2][hEntryX] = 295.138977;
	hModel[2][hEntryY] = 1474.469971;
	hModel[2][hEntryZ] = 1080.519897;
	hModel[2][hInterior] = 15;
	hModel[0][hEntryX] = 225.756989;
	hModel[0][hEntryY] = 1240.000000;
	hModel[0][hEntryZ] = 1082.149902;
	hModel[0][hInterior] = 2;
	hModel[3][hEntryX] = 235.508994;
	hModel[3][hEntryY] = 1189.169897;
	hModel[3][hEntryZ] = 1080.339966;
	hModel[3][hInterior] = 3;
	hModel[4][hEntryX] = 225.630997;
	hModel[4][hEntryY] = 1022.479980;
	hModel[4][hEntryZ] = 1084.069946;
	hModel[4][hInterior] = 7;
	hModel[5][hEntryX] = 1299.14;
	hModel[5][hEntryY] = -794.77;
	hModel[5][hEntryZ] = 1084.00;
	hModel[5][hInterior] = 5;
	return 1;
}
stock LoadClasses()
{
	// Player Class
	AddPlayerClass(280,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(281,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(282,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(283,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(284,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(286,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(71,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_DEAGLE,120,WEAPON_MP5,5000,WEAPON_M4,900); //Cop
	AddPlayerClass(268,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(269,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(270,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(1,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(2,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(3,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(4,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(5,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(6,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(8,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(42,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(65,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(74,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(86,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(119,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
 	AddPlayerClass(149,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(208,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(273,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(289,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(47,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(48,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(49,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(50,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(51,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(52,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(53,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(54,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(55,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(56,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(57,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(58,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
   	AddPlayerClass(68,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(69,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(230,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(70,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(72,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(73,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(75,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(76,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(78,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(79,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(80,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(81,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(82,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(83,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(84,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(85,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(87,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(88,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(89,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(91,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(92,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(93,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(95,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(96,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(97,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	AddPlayerClass(98,1759.0189,-1898.1260,13.5622,266.4503,WEAPON_COLT45,60,WEAPON_MP5,200,WEAPON_SHOTGSPA,14);
	return 1;
}
stock LoadPickups()
{
	StorePickups[Cluck][0] = CreatePickup(1274, 19, 371.1012,-7.0915,1001.8589, -1);
	PickupModel[StorePickups[Cluck][0]] = 1274;
	StorePickups[Saloon][0] = CreatePickup(1274, 19, 418.0066,-75.6407,1001.8047, -1);
	PickupModel[StorePickups[Saloon][0]] = 1274;
	StorePickups[Pizza][0] = CreatePickup(1274, 19, 376.5404,-116.1267,1001.4922, -1);
	PickupModel[StorePickups[Pizza][0]] = 1274;
	StorePickups[Burger][0] = CreatePickup(1274, 19, 372.9855,-65.6730,1001.5078, -1);
	PickupModel[StorePickups[Burger][0]] = 1274;
	StorePickups[Tattoo][0] = CreatePickup(1274, 19, -201.2714,-23.3582,1002.2734, -1);
	PickupModel[StorePickups[Tattoo][0]] = 1274;
	StorePickups[Hair][0] = CreatePickup(1274, 19, 414.4994,-11.2401,1001.8120, -1);
	PickupModel[StorePickups[Hair][0]] = 1274;
	StorePickups[Gym][0] = CreatePickup(1274, 19, 757.4478,5.6682,1000.7013, -1);
	PickupModel[StorePickups[Gym][0]] = 1274;
	StorePickups[Binco][0] = CreatePickup(1274, 19, 207.7114,-97.5476,1005.2578, -1);
	PickupModel[StorePickups[Binco][0]] = 1274;
	StorePickups[Pig][0] = CreatePickup(1274, 19, 1216.3262,-12.8319,1000.9219, -1);
	PickupModel[StorePickups[Pig][0]] = 1274;
	StorePickups[Bar][0] = CreatePickup(1274, 19, 501.6915,-78.4201,998.7578, -1);
	PickupModel[StorePickups[Bar][0]] = 1274;
	StorePickups[DS][0] = CreatePickup(1274, 19, 204.2953,-157.3629,1000.5234, -1);
	PickupModel[StorePickups[DS][0]] = 1274;
	StorePickups[Victim][0] = CreatePickup(1274, 19, 204.5596,-8.3968,1001.2109, -1);
	PickupModel[StorePickups[Victim][0]] = 1274;
	StorePickups[Zip][0] = CreatePickup(1274, 19, 161.4037,-79.8251,1001.8047, -1);
	PickupModel[StorePickups[Zip][0]] = 1274;
	StorePickups[Pro][0] = CreatePickup(1274, 19, 206.9348,-127.4049,1003.5078, -1);
	PickupModel[StorePickups[Pro][0]] = 1274;
	StorePickups[InsideTrack][0] = CreatePickup(1274, 19, 822.7689,2.7890,1004.1797, -1);
	PickupModel[StorePickups[InsideTrack][0]] = 1274;
	Hospitals[0] = CreatePickup(1240, 1, 2034.5853,-1404.4602,17.2588);
	PickupModel[Hospitals[0]] = 1240;
	Hospitals[1] = CreatePickup(1240, 1, 1173.2719,-1323.8844,15.3940);
	PickupModel[Hospitals[1]] = 1240;
	DrugHouses[0] = CreatePickup(1279, 19,320.0182,1120.4144,1083.8828, -1);
	PickupModel[DrugHouses[0]] = 1279;
	DrugHouses[1] = CreatePickup(1279, 19, 2344.7046,-1185.4514,1027.9766, -1);
	PickupModel[DrugHouses[1]] = 1279;
	Ammunations[0] = CreatePickup(353, 19, 296.1135,-38.2960,1001.5156, -1);
	PickupModel[Ammunations[0]] = 353;
	Ammunations[1] = CreatePickup(353, 19, 290.1722,-109.5499,1001.5156, -1);
	PickupModel[Ammunations[1]] = 353;
	Ammunations[2] = CreatePickup(353, 19, 296.9641,-79.6642,1001.5156, -1);
	PickupModel[Ammunations[2]] = 353;
	Banks[0] = CreatePickup(1318, 1, 1498.4279,-1583.0542,13.9184); //Bank Enterance
	PickupModel[Banks[0]] = 1318;
	Banks[1] = CreatePickup(1239, 19, 2315.9854,-7.6590,26.7422, -1); //Bank Checkpoint
	PickupModel[Banks[1]] = 1239;
	Banks[2] = CreatePickup(1318, 1, 2305.9180,-16.1663,27.0496, -1); //Bank Exit
	PickupModel[Banks[2]] = 1318;
	Banks[3] = CreatePickup(1318, 1, -1493.8386,920.0660,7.1875, -1); //Bank Entrance
	PickupModel[Banks[3]] = 1318;
	Banks[4] = CreatePickup(1318, 1, 2597.6011,1898.7023,10.6044, -1); //Bank Entrance
	PickupModel[Banks[4]] = 1318;
	TF7s[0] = CreatePickup(1318, 1, 1929.4576,-1776.2974,13.5469);//24/7 idle enterance
	PickupModel[TF7s[0]] = 1318;
	TF7s[1] = CreatePickup(1239, 19,-28.5483,-184.6961,1003.5469, -1);//24/7 Pickup
	PickupModel[TF7s[1]] = 1239;
	TF7s[2] = CreatePickup(1318, 1, -24.9845, -186.2724, 1003.5469, -1);//24/7 exit
	PickupModel[TF7s[2]] = 1318;
	TF7s[3] = CreatePickup(1239, 19,-30.4910,-55.1667,1003.5469, -1);//24/7 pershing
	PickupModel[TF7s[3]] = 1239;
	TF7s[4] = CreatePickup(1239, 19,-30.2960,-28.5857,1003.5573, -1);//24/7 rodeo
	PickupModel[TF7s[4]] = 1239;
	Grotti = CreatePickup(1239, 1,548.7548,-1291.1107,17.2482); //Grotti
	PickupModel[Grotti] = 1239;
	ATMs[0] = CreatePickup(1239, 2, 2127.22422, -1775.20740, 13.28500); //ATM Pizza (0)
	PickupModel[ATMs[0]] = 1239;
	ATMs[1] = CreatePickup(1239, 2, 1096.3354,-923.5619,43.0906); //ATM Sex Shop Temple (1)
	PickupModel[ATMs[1]] = 1239;
	ATMs[2] = CreatePickup(1239, 2, 2154.9319,-1086.6305,24.7440); //ATM Coutt (2)
	PickupModel[ATMs[2]] = 1239;
	ATMs[3] = CreatePickup(1239, 2, 2659.0652,-1633.8030,10.5412); //ATM Stadium (3)
	PickupModel[ATMs[3]] = 1239;
	ATMs[4] = CreatePickup(1239, 2, 1658.7560,-1657.3959,22.2156); //ATM Big VIP-type building behind LSPD (4)
	PickupModel[ATMs[4]] = 1239;
	ATMs[5] = CreatePickup(1239, 2, 809.7463,-1610.9984,13.2469); //ATM BurgetShot (5)
	PickupModel[ATMs[5]] = 1239;
	ATMs[6] = CreatePickup(1239, 2, 1153.9148,-1464.3831,15.5003); //ATM Shopping Centre (6)
	PickupModel[ATMs[6]] = 1239;
	ATMs[7] = CreatePickup(1239, 2, 1011.8904,-1370.3367,13.0553); //ATM Dounut (7)
	PickupModel[ATMs[7]] = 1239;
	ATMs[8] = CreatePickup(1239, 2, 519.5110,-1737.3870,11.6325); //ATM Santa Maria Beach (8)
	PickupModel[ATMs[8]] = 1239;
	ATMs[9] = CreatePickup(1239, 2, 589.0347,-1252.9973,17.8983); //ATM Grotti (9)
	PickupModel[ATMs[9]] = 1239;
	return 1;
}
stock LoadObjects()
{
	/*ATMS*/
	CreateDynamicObject(2942, 2128.32422, -1775.20740, 13.18500,   0.00000, 0.00000, 270.26300);//ATM Pizza (0)
	CreateDynamicObject(2942, 1011.88263, -1371.68579, 12.91730,   0.00000, 0.00000, 178.32001);//ATM Dounut (7)
	CreateDynamicObject(2942, 589.44122, -1254.04614, 17.86670,   0.00000, 0.00000, 201.67470);//ATM Grotti (9)
	CreateDynamicObject(2942, 1155.27881, -1463.86414, 15.44230,   0.00000, 0.00000, -68.47993);//ATM Shopping Centre (6)
	CreateDynamicObject(2942, 808.08569, -1611.07141, 13.16470,   0.00000, 0.00000, 91.68000);//ATM BurgetShot (5)
	CreateDynamicObject(2942, 1658.73181, -1656.08618, 22.17010,   0.00000, 0.00000, 0.00000);//ATM Big VIP-type building behind LSPD (4)
	CreateDynamicObject(2942, 2659.09131, -1632.50586, 10.46320,   0.00000, 0.00000, -1.68000);//ATM Stadium (3)
	CreateDynamicObject(2942, 2155.42163, -1085.33667, 24.64245,   0.00000, 0.00000, -19.08001);//ATM Coutt (2)
	CreateDynamicObject(2942, 519.27917, -1738.47156, 11.45810,   0.00000, 0.00000, -187.07993);//ATM Santa Maria Beach (8)
	CreateDynamicObject(2942, 1096.26587, -922.50250, 43.03320,   0.00000, 0.00000, 0.00000);//ATM Sex Shop Temple (1)
	/* Fix 24/7 */
	CreateDynamicObject(5020,-25.0000000,-186.7000000,1004.0000000,0.0000000,0.0000000,90.0000000, -1, 17, -1, 100.0);
	CreateDynamicObject(5020,-28.2000000,-189.7599900,1004.0000000,0.0000000,0.0000000,0.0000000, -1, 17, -1, 100.0);
	CreateDynamicObject(5020,-21.9000000,-189.7599900,1004.0000000,0.0000000,0.0000000,0.0000000, -1, 17, -1, 100.0);
	/*Admin Garage*/
	CreateDynamicObject(3095,2068.5996100,-1884.3994100,17.0000000,90.0000000,0.0000000,179.9950000); //object(a51_jetdoor) (1)
	CreateDynamicObject(3095,2068.5996100,-1863.1992200,17.0000000,90.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (2)
	CreateDynamicObject(3095,2059.6001000,-1863.1992200,17.0000000,90.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (3)
	CreateDynamicObject(3095,2059.5996100,-1884.3994100,17.0000000,90.0000000,0.0000000,179.9950000); //object(a51_jetdoor) (4)
	CreateDynamicObject(3095,2050.5996100,-1884.3994100,17.0000000,90.0000000,0.0000000,179.9950000); //object(a51_jetdoor) (5)
	CreateDynamicObject(3095,2050.6001000,-1863.1992200,17.0000000,90.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (6)
	CreateDynamicObject(3095,2041.5996100,-1884.3994100,17.0000000,90.0000000,0.0000000,179.9950000); //object(a51_jetdoor) (7)
	CreateDynamicObject(3095,2041.5999800,-1863.1992200,17.0000000,90.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (8)
	CreateDynamicObject(3095,2036.1191400,-1884.3994100,17.0000000,90.0000000,0.0000000,179.9950000); //object(a51_jetdoor) (9)
	CreateDynamicObject(3095,2036.1200000,-1863.1992200,17.0000000,90.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (10)
	CreateDynamicObject(3095,2031.5999800,-1867.6999500,17.0000000,90.0000000,0.0000000,90.0000000); //object(a51_jetdoor) (11)
	CreateDynamicObject(3095,2031.5999800,-1879.9000200,17.0000000,90.0000000,0.0000000,90.0000000); //object(a51_jetdoor) (12)
	CreateDynamicObject(3095,2036.1191400,-1867.6992200,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (13)
	CreateDynamicObject(3095,2068.5996100,-1867.6992200,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (14)
	CreateDynamicObject(3095,2059.5996100,-1867.6992200,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (15)
	CreateDynamicObject(3095,2050.5996100,-1867.6992200,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (16)
	CreateDynamicObject(3095,2041.5996100,-1867.6992200,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (17)
	CreateDynamicObject(3095,2068.5996100,-1879.8896500,21.5000000,0.0000000,180.0000000,180.0000000); //object(a51_jetdoor) (27)
	CreateDynamicObject(3095,2050.5996100,-1879.8896500,21.5000000,0.0000000,180.0000000,180.0000000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2059.5996100,-1879.8896500,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2041.5996100,-1879.8896500,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2036.1191400,-1879.8896500,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2036.1191400,-1874.0000000,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (13)
	CreateDynamicObject(3095,2041.5996100,-1874.0000000,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2068.5996100,-1874.0000000,21.5000000,0.0000000,179.9950000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,2059.5996100,-1874.0000000,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (15)
	CreateDynamicObject(3095,2050.5996100,-1874.0000000,21.5000000,179.9950000,0.0000000,0.0000000); //object(a51_jetdoor) (16)
	MovingObject[gAdminGarageID0] = CreateDynamicObject(2990,2073.0200200,-1878.7998000,16.4000000,0.0000000,0.0000000,90.0000000); //gate [0] - to open, z = 8
	MovingObject[gAdminGarageID1] = CreateDynamicObject(2990,2073.0300300,-1868.8000500,16.4000000,0.0000000,0.0000000,90.0000000); //gate [1] - to open, z = 8
	MovingObject[gAdminGaragePID0] = CreateDynamicObject(3437,2031.5996100,-1873.3994100,15.6400000,0.0000000,0.0000000,90.0000000); //backdoor [0] - to open, z = 5.6
	MovingObject[gAdminGaragePID1] = CreateDynamicObject(3437,2031.5996100,-1874.0996100,15.6400000,0.0000000,0.0000000,90.0000000); //backdoor [1] - to open, z = 5.6
	/* */
	/*Duckz garage*/
	CreateDynamicObject(17950, 1524.98596, -694.45953, 95.79932,   0.00000, 0.00000, 92.86292);
	MovingObject[gDuckzID] = CreateDynamicObject(17951, 1520.66174, -694.68091, 95.57840,   0.00000, 0.00000, 182.86290);
	/* */
	return 1;
}
stock RemoveBuildings(playerid)
{
	/*Duckz garage*/
	RemoveBuildingForPlayer(playerid, 3737, 1525.5000, -691.6953, 96.0781, 0.25); 
	RemoveBuildingForPlayer(playerid, 3604, 1525.5000, -691.6953, 96.0781, 0.25);
	/* */
	RemoveBuildingForPlayer(playerid, 759, 811.0781, -1609.8281, 12.5547, 0.25);//Bush blocking ATM near burgershot
	/*
	Removes vending machines
	RemoveBuildingForPlayer(playerid, 1302, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1209, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 955, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1775, 0.0, 0.0, 0.0, 6000.0);
	RemoveBuildingForPlayer(playerid, 1776, 0.0, 0.0, 0.0, 6000.0);
	*/
	return 1;
}
stock LoadOwnedVehicle(playerid, modelid, Float:ToX, Float:ToY, Float:ToZ){
	new pname[MAX_PLAYER_NAME], tempvID;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if(pInfo[playerid][vModel1] == modelid){
		tempvID = pInfo[playerid][vID1];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
			//foreach (new i : Player) if (GetPlayerVehicleID(i) == tempvID) RemovePlayerFromVehicle(i);
			SetVehiclePos(tempvID, ToX, ToY, ToZ);
			SetVehicleVirtualWorld(tempvID, 0);
			LinkVehicleToInterior(tempvID, 0);
		}else{
			tempvID = CreateVehicle(modelid, ToX, ToY, ToZ, 0, random(256), random(256), 99999);
			pInfo[playerid][vID1] = tempvID;
		}
	}else if (pInfo[playerid][vModel2] == modelid){
		tempvID = pInfo[playerid][vID2];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
		//foreach (new i : Player) if (GetPlayerVehicleID(i) == tempvID) RemovePlayerFromVehicle(i);
		SetVehiclePos(tempvID, ToX, ToY, ToZ);
		SetVehicleVirtualWorld(tempvID, 0);
		LinkVehicleToInterior(tempvID, 0);
		}else{
			tempvID = CreateVehicle(modelid, ToX, ToY, ToZ, 0, random(256), random(256), 99999);
			pInfo[playerid][vID2] = tempvID;
		}
	}else if (pInfo[playerid][vModel3] == modelid){
		tempvID = pInfo[playerid][vID3];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
		//foreach (new i : Player) if (GetPlayerVehicleID(i) == tempvID) RemovePlayerFromVehicle(i);
		SetVehiclePos(tempvID, ToX, ToY, ToZ);
		SetVehicleVirtualWorld(tempvID, 0);
		LinkVehicleToInterior(tempvID, 0);
		}else{
			tempvID = CreateVehicle(modelid, ToX, ToY, ToZ, 0, random(256), random(256), 99999);
			pInfo[playerid][vID3] = tempvID;
		}
	}
	RepairVehicle(tempvID);
	CallRemoteFunction("RestoreFuel", "i", tempvID);
	vInfo[tempvID][OwnGroup] = gPlayer;
	strpack(vOwnerName[tempvID], pname);
	PutPlayerInVehicle(playerid, tempvID, 0);
}
stock DeleteOwnedVehicle(playerid, modelid){
	new pname[MAX_PLAYER_NAME], tempvID;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if(pInfo[playerid][vModel1] == modelid){
		tempvID = pInfo[playerid][vID1];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
			vInfo[tempvID][OwnGroup] = gNone;
			DestroyVehicle(tempvID);
		}
		pInfo[playerid][vModel1] = 0;
	}else if (pInfo[playerid][vModel2] == modelid){
		tempvID = pInfo[playerid][vID2];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
			vInfo[tempvID][OwnGroup] = gNone;
			DestroyVehicle(tempvID);
		}
		pInfo[playerid][vModel2] = 0;
	}else if (pInfo[playerid][vModel3] == modelid){
		tempvID = pInfo[playerid][vID3];
		if (vInfo[tempvID][OwnGroup] == gPlayer && !strcmp(vOwnerName[tempvID], pname) && GetVehicleModel(tempvID) == modelid) {
			vInfo[tempvID][OwnGroup] = gNone;
			DestroyVehicle(tempvID);
		}
		pInfo[playerid][vModel3] = 0;
	}
}
stock BuyOwnedVehicle(playerid, modelid, Float:ToX, Float:ToY, Float:ToZ){
	new pname[MAX_PLAYER_NAME], tempvID;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (pInfo[playerid][vModel1] == 0){
		tempvID = CreateVehicle(modelid, ToX,ToY,ToZ, 0, random(256), random(256), 99999);
		pInfo[playerid][vID1] = tempvID;
		pInfo[playerid][vModel1] = modelid;
		PutPlayerInVehicle(playerid, tempvID, 0);
	}
	else if (pInfo[playerid][vModel2] == 0){
		tempvID	= CreateVehicle(modelid, ToX,ToY,ToZ, 0, random(256), random(256), 99999);
		pInfo[playerid][vID2] = tempvID;
		pInfo[playerid][vModel2] = modelid;
		PutPlayerInVehicle(playerid, tempvID, 0);
	}
	else if (pInfo[playerid][vModel3] == 0){
		tempvID = CreateVehicle(modelid, ToX,ToY,ToZ, 0, random(256), random(256), 99999);
		pInfo[playerid][vID3] = tempvID;
		pInfo[playerid][vModel3] = modelid;
		PutPlayerInVehicle(playerid, tempvID, 0);
	}
	vInfo[tempvID][OwnGroup] = gPlayer;
	strpack(vOwnerName[tempvID], pname);
	CallRemoteFunction("RestoreFuel", "i", tempvID);
}
stock SendToCops(msg[], color){
	foreach(new i : Player){
		if (pInfo[i][Class] == cCop) SendClientMessage(i, color, msg);
	}
}
stock PoliceRadioStore(playerid, storename[]){
	new pname[MAX_PLAYER_NAME], formatted[128];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "***Police Radio*** Please be advised, %s(%d) is robbing %s.", pname, playerid, storename);
	SendToCops(formatted, Col_LightBlue);
}
public OnPlayerConnect(playerid)
{
	GameTextForPlayer(playerid,"~w~Game's Cops and Robbers",3000,4);
  	SendClientMessage(playerid,COLOR_WHITE,"Welcome to {88AA88}G{FFFFFF}ame's {88AA88}C{FFFFFF}ops and {88AA88}R{FFFFFF}obbers");
	new formatted[128], pip[16], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, pip, 16);
	if (fexist(BanPath(playerid)) && !fexist(WhitePath(pname)) && strcmp("[GCnR]Duckz", pname) != 0){
		new File:BanFile = fopen(BanPath(playerid), io_read), bantime, tempS[40], tempIP[21], lasttemp[128];
		fread(BanFile, tempS);
		fread(BanFile, tempIP);
		fread(BanFile, lasttemp);
		fclose(BanFile);
		bantime = strval(tempS);
		if (strcmp(pip, tempIP, false, strlen(pip)) != 0){ //In case of ban evading, deletes the old IP file and replaces the IP line in the ban file.
			strdel(tempIP, strlen(tempIP)-2, strlen(tempIP));
			if(fexist(IPBanPath(tempIP))) fremove(IPBanPath(tempIP)); //Unbanning bug prevention
			fremove(BanPath(playerid));
			new File:newpath = fopen(BanPath(playerid));
			fwrite(newpath, tempS);
			format(formatted, 128, "%s\r\n", pip);
			fwrite(newpath, formatted);
			fwrite(newpath, lasttemp);
			fclose(newpath);
			newpath = fopen(IPBanPath(pip));
			format(formatted, 128, "Player: %s", pname);
			fwrite(newpath, formatted);
			fclose(newpath);
		}
		if(bantime > gettime()||bantime == -1){
			if(bantime != -1){
				new days = (bantime - gettime()-((bantime - gettime())%86400))/86400;
				new hours = ((bantime - gettime()-((bantime - gettime())%3600))/3600)-(days*24);
				if (days == 0 && hours == 0) formatted = "You are banned. Ban will expire in: Less then an hour.";
				else if (days == 0) format(formatted, 128, "You are banned. Ban will expire in: %d hours.", hours);
				else format(formatted, 128, "You are banned. Ban will expire in: %d days and %d hours.", days, hours);
				SendClientMessage(playerid, Col_Red, formatted);
			}else{
				format(formatted, 128, "You are permanently banned. Post a ban appeal at gcnr.tk");
				SendClientMessage(playerid, Col_Red, formatted);
			}
			SetTimerEx("KickF", 1000, false, "i", playerid);
			return 0;
		} else {
			fremove(BanPath(playerid));
			if(fexist(IPBanPath(pip))) fremove(IPBanPath(pip));
		}
	}else if (fexist(IPBanPath(pip)) && !fexist(WhitePath(pname)) && strcmp("[GCnR]Duckz", pname) != 0){
		SendClientMessage(playerid, Col_Red, "You are banned. Post a ban appeal at gcnr.tk");
		SetTimerEx("KickF", 1000, false, "i", playerid);
		return 0;
	}
	SetPlayerColor(playerid, Col_Gray);
    if(fexist(Path(playerid))) /* Check if the connected user is registered or not. fexist stands for file exist. So if file exist in the files(Path(playerid)),*/
    {// then
        INI_ParseFile(Path(playerid),"loadaccount_%s", .bExtra = true, .extra = playerid); //Will load user's data using INI_Parsefile.
        ShowPlayerDialog(playerid,dlogin,DIALOG_STYLE_PASSWORD,"Login","Welcome back. This account is registered. \nInsert your password to login to your account","Login","Quit");/*A dialog with input style will appear so you can insert your password to login.*/
    }
    else //If the connected user is not registered,
    {//then we will 'force' him to register :)
		if (!strcmp(pname, "[GCnR]", true, 6)  && strcmp("[GCnR]Duckz", pname) != 0){
			SendClientMessage(playerid, Col_Red, "You did not apply for a tag. Go to gcnr.net to apply for one.");
			SetTimerEx("KickF", 1000, false, "i", playerid);
			return 0;
		}
        ShowPlayerDialog(playerid,dregister,DIALOG_STYLE_INPUT,"Register","Welcome! This account is not registered.\nEnter your own password to create a new account.","Register","Quit");
    }
	

	  	// class selection init vars
  	gPlayerCitySelection[playerid] = -1;
	gPlayerHasCitySelected[playerid] = 0;
	gPlayerLastCitySelectionTick[playerid] = GetTickCount();
	
	RemoveBuildings(playerid);
 	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if (dialogid == dclasses)
	{
		switch (listitem){
			case 0: //Automatically robber on spawn, no need to set class
			{
				SendClientMessage(playerid, Col_Green, "You are now a normal robber. Your job is to rob places or people while evading the police.");
			}
			case 1:
			{
				pInfo[playerid][Class] = cWeaponDeal;
				SendClientMessage(playerid, Col_Green, "You are now a weapon dealer. Your job is to sell weapons to players using /offer.");
				SendClientMessage(playerid, Col_Green, "Do not tell people to /weapons so you'll give them money.");
			}
			case 2:
			{
				pInfo[playerid][Class] = cDrugDeal;
				SendClientMessage(playerid, Col_Green, "You are now a drug dealer. Your job is to sell drugs to players using /offer.");
				SendClientMessage(playerid, Col_Green, "Do not tell people to /drugs so you'll give them money.");
				SendClientMessage(playerid, Col_Green, "You start with 20 grams of drugs.");
				pInfo[playerid][Drugs] = 20;
			}
		}
		SendClientMessage(playerid, Col_Green, "See /cmds for a list of your commands.");
		return 1;
	}
    else if(dialogid == dregister) //If dialog id is a register dialog
    {//then
        if(!response) return Kick(playerid); //If they clicked the second button "Quit", we will kick them.
        if(response) //if they clicked the first button "Register"
        {//then
            if(!strlen(inputtext)) //If they didn't enter any password
            {// then we will tell to them to enter the password to register
                ShowPlayerDialog(playerid,dregister,DIALOG_STYLE_INPUT,"Register","Welcome! This account is not registered.\nEnter your own password to create a new account.\nPlease enter the password!","Register","Quit");
                return 1;
            }
            //If they have entered a correct password for his/her account...
            new hashpass[129]; //Now we will create a new variable to hash his/her password
            WP_Hash(hashpass,sizeof(hashpass),inputtext);//We will use whirlpool to hash their inputted text
			WP_Hash(hashpass,sizeof(hashpass),hashpass);//Double Hashing (against rainbow tables)
			new name[MAX_PLAYER_NAME], formatted[128]; //Making a new variable called 'name'. name[MAX_PLAYER_NAME] is created so we can use it to get player's name.
			GetPlayerName(playerid,name,sizeof(name)); //Get player's name
			if(!strcmp(name, "[GCnR]Duckz") && strcmp(hashpass, "885F9D67F1C48C1426246FBAA6AD2A3BFC21CF5AB839D66669E5CA7051D52C31DF2D64A50E4B81EC300FB95B96A6B1E8C8AAF97DDA4B630A8C26F5D752DEA90B") != 0) return Kick(playerid);
            new INI:file = INI_Open(Path(playerid)); // we will open a new file for them to save their account inside of Scriptfiles/Users folder
            INI_SetTag(file,"Player's Data");//We will set a tag inside of user's account called "Player's Data"
            INI_WriteString(file,"Password",hashpass);//This will write a hashed password into user's account
            INI_WriteInt(file,"AdminLevel",0); //Write an integer inside of user's account called "AdminLevel". We will set his level to 0 after he registered.
            INI_WriteInt(file,"VIPLevel",0);//As explained above
            INI_WriteInt(file,"Money",0);//Write an integer inside of user's account called "Money". We will set their money to 0 after he registered
			INI_WriteInt(file,"BankMoney",0);//Write an integer inside of user's account called "Money". We will set their money to 0 after he registered
            INI_WriteInt(file,"Scores",0);//Write an integer inside of user's account called "Scores". We will set their score to 0 after he registered
			INI_WriteInt(file, "JailTime",0); //To check for jail evade
			INI_WriteInt(file, "SpawnHouse",-1);
			INI_WriteInt(file, "WeaponStacks",0);
			INI_WriteInt(file, "vModel1",0);
			INI_WriteInt(file, "vID1",0);
			INI_WriteInt(file, "vModel2",0);
			INI_WriteInt(file, "vID2",0);
			INI_WriteInt(file, "vModel3",0);
			INI_WriteInt(file, "vID3",0);
			INI_WriteInt(file, "Arrests",0);
			INI_WriteInt(file, "Robs",0);
			INI_WriteInt(file, "Rapes",0);
			INI_WriteInt(file, "WeaponDeal",0);
			INI_WriteInt(file, "DrugDeal",0);
			INI_WriteInt(file, "TimeSpent",0);
            INI_Close(file);//Now after we've done saving their data, we now need to close the file
			pInfo[playerid][VIPlevel]= 0;
			pInfo[playerid][Money]= 10000;
			pInfo[playerid][BankMoney] = 0;
			pInfo[playerid][Scores]= 0;
			pInfo[playerid][Adminlevel]= 0;
            SendClientMessage(playerid,-1,"You have been successfully registered. Please read /rules.");//Tell to them that they have successfully registered a new account
			GameTextForPlayer(playerid, "$10,000 Registration Bonus!", 5000, 1);
			pInfo[playerid][login] = true;
			pInfo[playerid][vModel1] = 0;
			pInfo[playerid][vID1] = 0;
			pInfo[playerid][vModel2] = 0;
			pInfo[playerid][vID2] = 0;
			pInfo[playerid][vModel3] = 0;
			pInfo[playerid][vID3] = 0;
			pInfo[playerid][sArrests] = 0;
			pInfo[playerid][sRobs] = 0;
			pInfo[playerid][sRapes] = 0;
			pInfo[playerid][sWeaponDeals] = 0;
			pInfo[playerid][sDrugDeals] = 0;
			pInfo[playerid][SpawnHouse] = -1;
			pInfo[playerid][DailyLogin] = getdate();
			pInfo[playerid][sTimeSpent] = 0;
			pInfo[playerid][LoginTime] = gettime();
			format(formatted, 128, "%s (id: %d) has connected.", name, playerid);
			SendClientMessageToAll(Col_Gray, formatted);
        }
		return 1;
    }
    else if(dialogid == dlogin) //If dialog id is a login dialog
    {//then
        if(!response) return Kick(playerid); //If they clicked the second button "Quit", we will kick them.
        if(response) //if they clicked the first button "Login"
        {//then
            new hashpass[129]; //Will create a new variable to hash his/her password
            WP_Hash(hashpass,sizeof(hashpass),inputtext);//We will use whirlpool to hash their inputted text
			WP_Hash(hashpass,sizeof(hashpass),hashpass);//Double Hashing (against rainbow tables)
            if(!strcmp(hashpass,pInfo[playerid][Pass]) || strcmp(pInfo[playerid][Pass], "0", true) == 0) //If they have insert their correct password or password reset
            {//then
                INI_ParseFile(Path(playerid),"loadaccount_%s",.bExtra = true, .extra = playerid);//We will load his account's data from user's path
				new name[MAX_PLAYER_NAME], formatted[128]; //Making a new variable called 'name'. name[MAX_PLAYER_NAME] is created so we can use it to get player's name.
				GetPlayerName(playerid,name,sizeof(name)); //Get player's name
                SetPlayerScore(playerid,pInfo[playerid][Scores]);//We will get their score inside of his user's account and we will set it here
                SendClientMessage(playerid,-1,"Welcome back! You have successfully logged in");//Tell them that they've successfully logged in
				pInfo[playerid][login] = true;
				pInfo[playerid][LoginTime] = gettime();
				SetPVarInt(playerid, "Admin", pInfo[playerid][Adminlevel]);
				new date = getdate();
				if (pInfo[playerid][DailyLogin] != date) GameTextForPlayer(playerid, "$10,000 Daily Login Bonus!", 5000, 1), pInfo[playerid][Money] += 10000, pInfo[playerid][DailyLogin] = date;
				format(formatted, 128, "%s (id: %d) has connected.", name, playerid);
				SendClientMessageToAll(Col_Gray, formatted);
                if (pInfo[playerid][Passflag] || strcmp(pInfo[playerid][Pass], "0", true) == 0) ShowPlayerDialog(playerid,dchangepw,DIALOG_STYLE_INPUT,"Change Password","This account is flagged to change the password. \nInsert your new password below.","Change","Quit");
            }
            else //If they've entered an incorrect password
            {//then
                ShowPlayerDialog(playerid,dlogin,DIALOG_STYLE_INPUT,"Login","Welcome back. This account is registered. \nInsert your password to login to your account.\nIncorrect password!","Login","Quit");//We will tell to them that they've entered an incorrect password
            }
        }
		return 1;
    }
    else if(dialogid == dchangepw)
    {
        if(!response && (pInfo[playerid][Passflag] || strcmp(pInfo[playerid][Pass], "0", true) == 0)) return ShowPlayerDialog(playerid,dchangepw,DIALOG_STYLE_INPUT,"Change Password","You must change the password. \nInsert your new password below.","Change","Quit"), 1;
		if(!response) return 1;
        if(response)
        {
			if (!strlen(inputtext)) return ShowPlayerDialog(playerid,dchangepw,DIALOG_STYLE_INPUT,"Change Password","Please insert your new password below.\nPlease insert a password.","Change","Cancel");
            new hashpass[129];
            WP_Hash(hashpass,sizeof(hashpass),inputtext);//We will use whirlpool to hash their inputted text
			WP_Hash(hashpass,sizeof(hashpass),hashpass);//Double Hashing (against rainbow tables)
            new INI:file = INI_Open(Path(playerid)); //will open their file
	        INI_SetTag(file,"Player's Data");//We will set a tag inside of user's account called "Player's Data"
    		INI_WriteString(file,"Password",hashpass);//As explained above
			INI_WriteBool(file,"Passflag",false);
      		INI_Close(file);//Now after we've done saving their data, we now need to close the file
      		SendClientMessage(playerid,Col_Green,"Password changed.");
  		}
		return 1;
	}
	else if(dialogid == dcmds) // cmds
	{
		if(!response) return 1;
		else if(listitem == 0){
			new string[690] = "/animlist\tSee a list of animations\n/changepw\tChange your password\n/report\t\tReport a player\n/admins\t\tSee a list of online admins\n/w\t\tWhisper nearby players\n/cw\t\tWhisper players in vehicle\n/pm\t\tPrivate message a player\n/r\t\tRespond to the last PM\n/ask\t\tAsk admins a question\n/gc\t\tGive players money";
			strcat(string, "\n/(un)lock\tLock or unlock a vehicle\n/eject\t\tEject a player from your vehicle\n/color\t\tChange vehicle color\n/kill\t\tSuicide\n/loc\t\tGet a player's location\n/stats\t\tSee your stats\n/info\t\tSee your player info\n/city\t\tChange spawn city\n/exith\t\tExit the house\n/weapons\tCall for a weapon dealer");
			strcat(string, "\n/drugs\t\tCall for a drug dealer\n/me\t\tWrite an emotion.");
			ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "General commands", string, "OK", "");
		}
		else if(listitem == 1) ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "Robber commands", "/rob\t\tRob a player\n/rape\t\tRape a player\n/escape\t\tEscape from jail\n/bc\t\tBreak cuffs\n/td\t\tTake Drugs", "OK", "");
		else if(listitem == 2) switch (pInfo[playerid][Class]){
			case cCop:
				ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "Cop commands", "/taze\t\tTaze a player\n/cuff\t\tCuff a player\n/fine\t\tFine a low wanted player\n/ar\t\tArrest a player (must be cuffed)\n/search\t\tSearch a player for drugs (must be cuffed)\n/cm\t\tTalk in cop radio", "OK", "");
			case cWeaponDeal:
				ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "Weapon dealer commands", "/clients\t\tSee a list of clients.\n/offer\t\tOffer someone to buy weapons.", "OK", "");
			case cDrugDeal:
				ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "Drug dealer commands", "/clients\t\tSee a list of clients.\n/offer\t\tOffer someone to buy drugs.", "OK", "");
			default:
				ShowPlayerDialog(playerid, dcmdslist, DIALOG_STYLE_MSGBOX, "No class", "No special class commands. See robber commands.", "OK", "");
			}
		else if(listitem == 3) ShowRules(playerid);
		return 1;
	}
	else if(dialogid == drules) // rules
	{
		new stringy[760] = "{FFFFFF}White player\n\tInnocent Civilian. \n\tThey are allowed to shoot ONLY players that raped or robbed them, and ONLY if they do, you can shoot back.\n{FFFF00}Yellow player{FFFFFF}";
		strcat(stringy, "\n\tLow wanted criminal. They count as innocent civilians, same rules apply. Cops can fine them with /fine BUT NOT shoot them.\n\tKeep in mind that if they are in the car with wanteds, they CAN respond if they are being shot at.\n");
		strcat(stringy, "{FFA200}Orange player{FFFFFF}\n\tMedium wanted criminal. Cops can shoot and arrest them with /ar.\n{FF0000}Red player{FFFFFF}\n\tHighly wanted criminal. Cops can shoot and arrest them with /ar.\n{001EFF}Blue player{FFFFFF}\n\tLaw enforcement officer.");
		ShowPlayerDialog(playerid, dcolors, DIALOG_STYLE_MSGBOX, "Player colors:", stringy, "Done", "");
		return 1;
	}
	else if (dialogid == ddrugs) //drugs
	{
		new formatted[128];
		if(!response) return 1;
		if (listitem == 0){
			if (pInfo[playerid][Money] < 5000) SendClientMessage(playerid, Col_Red, "You do not have enough money!");
			else if (pInfo[playerid][Drugs]+10 > 100) SendClientMessage(playerid, Col_Red, "You may carry up to 100 grams of drugs.");
			else {
				pInfo[playerid][Money] -= 5000;
				pInfo[playerid][Drugs] += 10;
				format(formatted, 128, "You have bought 10 grams of drugs. You currently have %d grams. Use them with /td.", pInfo[playerid][Drugs]);
				SendClientMessage(playerid, Col_Pink, formatted);
			}
		}else if (listitem == 1){
			if (pInfo[playerid][Money] < 24000) SendClientMessage(playerid, Col_Red, "You do not have enough money!");
			else if (pInfo[playerid][Drugs]+50 > 100) SendClientMessage(playerid, Col_Red, "You may carry up to 100 grams of drugs.");
			else{
				pInfo[playerid][Money] -= 24000;
				pInfo[playerid][Drugs] += 50;
				format(formatted, 128, "You have bought 50 grams of drugs. You currently have %d grams. Use them with /td.", pInfo[playerid][Drugs]);
				SendClientMessage(playerid, Col_Pink, formatted);
			}
		}else if (listitem == 2){
			if (pInfo[playerid][Money] < 6000) SendClientMessage(playerid, Col_Red, "You do not have enough money!");
			else if (pInfo[playerid][drugbag] == true) SendClientMessage(playerid, Col_Red, "You already have a drug bag!");
			else {
				pInfo[playerid][Money] -= 6000;
				pInfo[playerid][drugbag] = true;
				format(formatted, 128, "You have bought a drug bag. You can hide up to 20 grams of drugs using it.");
				SendClientMessage(playerid, Col_Pink, formatted);
			}
		}
		ShowPlayerDialog(playerid, ddrugs, DIALOG_STYLE_LIST, "Welcome to the drug store", "Buy 10 grams\t\t5000$\nBuy 50 grams\t\t24000$\nBuy Drug Bag (protects up to 20 grams)\t6000$", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dhospital)
	{
		if (!response) return AllowPicks(playerid), 1;
		switch (listitem){
			case 0:
			{
				new Float:phealth;
				GetPlayerHealth(playerid, phealth);
				if (pInfo[playerid][Money] < 2000) SendClientMessage(playerid, Col_Red, "You do not have enough money.");
				else if (phealth == 100) SendClientMessage(playerid, Col_Red, "You already have full health");
				else {
					pInfo[playerid][Money] -= 2000;
					SetPlayerHealth(playerid, 100);
					SendClientMessage(playerid, Col_Pink, "You have healed yourself for $2000.");
				}
			}
			case 1:
			{
				if (pInfo[playerid][Money] < 4000) SendClientMessage(playerid, Col_Red, "You do not have enough money.");
				else if (!pInfo[playerid][raped]) SendClientMessage(playerid, Col_Red, "You do not need a cure.");
				else{
					KillTimer(pInfo[playerid][RapeTimer]);
					SendClientMessage(playerid, Col_Pink, "You have been cured for $4000.");
					pInfo[playerid][Money] -= 4000;
					pInfo[playerid][raped] = false;
				}
			}
			case 2:
			{
				if (pInfo[playerid][Money] < 5000) SendClientMessage(playerid, Col_Red, "You do not have enough money.");
				else if (!pInfo[playerid][raped]) SendClientMessage(playerid, Col_Red, "You do not need a cure.");
				else{
					KillTimer(pInfo[playerid][RapeTimer]);
					SendClientMessage(playerid, Col_Pink, "You have been cured and healed for $5000.");
					SetPlayerHealth(playerid, 100);
					pInfo[playerid][Money] -= 5000;
					pInfo[playerid][raped] = false;
				}
			}
		}
		ShowPlayerDialog(playerid, dhospital, DIALOG_STYLE_LIST, "Welcome to the hospital", "Heal\t\t$2000\nCure\t\t$4000\nCure and Heal\t$5000", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dATM){
		if (!response) return 1;
		switch(listitem){
			case 0: ShowPlayerDialog(playerid, dATMwithdraw, DIALOG_STYLE_INPUT, "Withdraw cash", "Please write below the amount you wish to withdraw", "OK", "Cancel");
			case 1:
			{
				new formatted[128];
				format(formatted, 128, "Your current balance is: $%d", pInfo[playerid][BankMoney]);
				ShowPlayerDialog(playerid, dATMbalance, DIALOG_STYLE_MSGBOX, "Withdraw cash", formatted, "Done","");
			}
		}
		return 1;
	}
	else if (dialogid == dbank){
		if (!response) return 1;
		switch(listitem){
			case 0: ShowPlayerDialog(playerid, dbankdeposit, DIALOG_STYLE_INPUT, "Deposit cash", "Please write below the amount you wish to deposit", "OK", "Cancel");
			case 1: ShowPlayerDialog(playerid, dbankwithdraw, DIALOG_STYLE_INPUT, "Withdraw cash", "Please write below the amount you wish to withdraw", "OK", "Cancel");
			case 2:
			{
				new formatted[128];
				format(formatted, 128, "Your current bank balance is: $%d", pInfo[playerid][BankMoney]);
				ShowPlayerDialog(playerid, dbankbalance, DIALOG_STYLE_MSGBOX, "Withdraw cash", formatted, "Done","");
			}
		}
		return 1;
	}
	else if (dialogid == dATMwithdraw){
		if (response){
			new amount = strval(inputtext);
			if(pInfo[playerid][BankMoney] < amount) SendClientMessage(playerid, Col_Red, "Not enough money in bank account.");
			else if(amount < 0) SendClientMessage(playerid, Col_Red, "You cannot withdraw a negative amount of money.");
			else{
				pInfo[playerid][BankMoney] -= amount;
				pInfo[playerid][Money] += amount;
				new formatted[128];
				format(formatted, 128, "You have successfully withdrawn $%d.", amount);
				SendClientMessage(playerid, Col_Green, formatted);
			}
		}
		ShowPlayerDialog(playerid, dATM, DIALOG_STYLE_LIST, "ATM machine", "Withdraw Cash\nCheck Balance", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dbankwithdraw){
		if (response){
			new amount = strval(inputtext);
			if(pInfo[playerid][BankMoney] < amount) SendClientMessage(playerid, Col_Red, "Not enough money in bank account.");
			else if(amount < 0) SendClientMessage(playerid, Col_Red, "You cannot withdraw a negative amount of money.");
			else{
				pInfo[playerid][BankMoney] -= amount;
				pInfo[playerid][Money] += amount;
				new formatted[128];
				format(formatted, 128, "You have successfully withdrawn $%d.", amount);
				SendClientMessage(playerid, Col_Green, formatted);
			}
		}
		ShowPlayerDialog(playerid, dbank, DIALOG_STYLE_LIST, "Welcome to the bank", "Deposit Cash\nWithdraw Cash\nCheck Bank Balance", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dbankdeposit){
		if (response){
			new amount = strval(inputtext);
			if(pInfo[playerid][Money] < amount) SendClientMessage(playerid, Col_Red, "You do not have that amount of money on you.");
			else if(amount < 0) SendClientMessage(playerid, Col_Red, "You cannot deposit a negative amount of money.");
			else{
				pInfo[playerid][BankMoney] += amount;
				pInfo[playerid][Money] -= amount;
				new formatted[128];
				format(formatted, 128, "You have successfully deposited $%d.", amount);
				SendClientMessage(playerid, Col_Green, formatted);
			}
		}
		ShowPlayerDialog(playerid, dbank, DIALOG_STYLE_LIST, "Welcome to the bank", "Deposit Cash\nWithdraw Cash\nCheck Bank Balance", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dbankbalance) return ShowPlayerDialog(playerid, dbank, DIALOG_STYLE_LIST, "Welcome to the bank", "Deposit Cash\nWithdraw Cash\nCheck Bank Balance", "Select", "Cancel");
	else if (dialogid == dATMbalance) return ShowPlayerDialog(playerid, dATM, DIALOG_STYLE_LIST, "ATM machine", "Withdraw Cash\nCheck Balance", "Select", "Cancel");
	else if (dialogid == dTF7){
		if (!response) return 1;
		switch (listitem){
			case 0:
			{
				if (pInfo[playerid][Money] < 2500) SendClientMessage(playerid, Col_Red, "You don't have enough money to purchase this item.");
				else if (pInfo[playerid][WalletsLeft] == 3) SendClientMessage(playerid, Col_Red, "You have already purchased a wallet.");
				else {
					pInfo[playerid][Money] -= 2500;
					pInfo[playerid][WalletsLeft] = 3;
					SendClientMessage(playerid, Col_Pink, "You have purchased a wallet for $2500. You will not be robbed the next 3 tries.");
				}
			}
			case 1:
			{
				if (pInfo[playerid][Money] < 4000) SendClientMessage(playerid, Col_Red, "You don't have enough money to purchase this item.");
				else{
					pInfo[playerid][Money] -= 4000;
					GivePlayerWeapon(playerid, 46, 1);
					SendClientMessage(playerid, Col_Pink, "You have purchased a parachute for $4000.");
				}
			}
			case 2:
			{
				if (pInfo[playerid][Money] < 1500) SendClientMessage(playerid, Col_Red, "You don't have enough money to purchase this item.");
				else{
					pInfo[playerid][Money] -= 1500;
					GivePlayerWeapon(playerid, 43, 1);
					SendClientMessage(playerid, Col_Pink, "You have purchased a camera for $1500.");
				}
			}
			case 3:
			{
				if (pInfo[playerid][Money] < 250) SendClientMessage(playerid, Col_Red, "You don't have enough money to purchase this item.");
				else{
					pInfo[playerid][Money] -= 250;
					GivePlayerWeapon(playerid, 14, 1);
					SendClientMessage(playerid, Col_Pink, "You have purchased some flowers for $250.");
				}
			}
			case 4:
			{
				if (pInfo[playerid][Money] < 450) SendClientMessage(playerid, Col_Red, "You don't have enough money to purchase this item.");
				else{
					pInfo[playerid][Money] -= 450;
					GivePlayerWeapon(playerid, 41, 60);
					SendClientMessage(playerid, Col_Pink, "You have purchased a spray can refill for $450.");
				}
			}
		}
		ShowPlayerDialog(playerid, dTF7, DIALOG_STYLE_LIST, "Welcome to the 24/7. What would you like to buy?", "Wallet\t\t$2500\nParachute\t$4000\nCamera\t\t$1500\nFlowers\t$250\nSpray Can(60)\t$450", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dgrottiwelcome){
		if (!response) return AllowPicks(playerid), 1;
		switch (listitem){
			case 0:
			{
				if (pInfo[playerid][vModel1] == 0 && pInfo[playerid][vModel2] == 0 && pInfo[playerid][vModel3] == 0){
					SendClientMessage(playerid, Col_Red, "You do not own any vehicle.");
					ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
					return 1;
				}
				new final[128] = "", formatted[40], ID;
				if (pInfo[playerid][vModel1] != 0){
					ID = pInfo[playerid][vModel1] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				if (pInfo[playerid][vModel2] != 0){
					ID = pInfo[playerid][vModel2] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				if (pInfo[playerid][vModel3] != 0){
					ID = pInfo[playerid][vModel3] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				ShowPlayerDialog(playerid, dgrottibring, DIALOG_STYLE_LIST, "Select a car to bring for $5,000.", final, "Select", "Cancel");
			}
			case 1:
			{
				if (pInfo[playerid][vModel1] == 0 || pInfo[playerid][vModel2] == 0 || pInfo[playerid][vModel3] == 0) ShowPlayerDialog(playerid, dgrottibuy, DIALOG_STYLE_LIST, "Which vehicle would you like to buy?", "NRG-500\t$100,000\nInfernus\t$120,000\nTurismo\t$90,000\nSultan\t\t$100,000\nCheetah\t$90,000\nRemington\t$100,000", "Select", "Cancel");
				else{
					SendClientMessage(playerid, Col_Red, "Vehicle slots full. Please delete a car or use one of them.");
					ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
				}
			}
			case 2:
			{
				if (pInfo[playerid][vModel1] == 0 && pInfo[playerid][vModel2] == 0 && pInfo[playerid][vModel3] == 0){
					SendClientMessage(playerid, Col_Red, "You do not own any vehicle.");
					ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
					return 1;
				}
				new final[128] = "", formatted[40], ID;
				if (pInfo[playerid][vModel1] != 0){
					ID = pInfo[playerid][vModel1] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				if (pInfo[playerid][vModel2] != 0){
					ID = pInfo[playerid][vModel2] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				if (pInfo[playerid][vModel3] != 0){
					ID = pInfo[playerid][vModel3] - 400;
					format(formatted, 40, "%s\n", VehicleNames[ID]);
					strcat(final, formatted);
				}
				ShowPlayerDialog(playerid, dgrottidelete, DIALOG_STYLE_LIST, "Select a car to delete. There are no returns for a mistake.", final, "Select", "Cancel");
				
			}
		}
		return 1;
	}
	else if (dialogid == dgrottibring){
		if(response){
			if(pInfo[playerid][Money] >= 5000){
				switch(listitem){
					case 0:
					{
						if(pInfo[playerid][vModel1] != 0) LoadOwnedVehicle(playerid, pInfo[playerid][vModel1], 560.5355,-1282.8049,18.1914);
						else if(pInfo[playerid][vModel2] != 0) LoadOwnedVehicle(playerid, pInfo[playerid][vModel2], 560.5355,-1282.8049,18.1914);
						else LoadOwnedVehicle(playerid, pInfo[playerid][vModel3], 560.5355,-1282.8049,18.1914);
					}
					case 1:
					{
						if(pInfo[playerid][vModel2] == 0) LoadOwnedVehicle(playerid, pInfo[playerid][vModel3], 560.5355,-1282.8049,18.1914); //if vmodel1 exists and 2 doesn't. it's option 3. if vmodel1 doesn't exist, and 2 doesn't, there is no 2nd option in list, therefore case doesn't exists.
						else LoadOwnedVehicle(playerid, pInfo[playerid][vModel2], 560.5355,-1282.8049,18.1914); //if model1 exists, and 2 isn't blank.
					}
					case 2: LoadOwnedVehicle(playerid, pInfo[playerid][vModel3], 560.5355,-1282.8049,18.1914);
				}
				pInfo[playerid][Money] -= 5000;
				return AllowPicks(playerid), 1;
			}else SendClientMessage(playerid, Col_Red, "You do not have enough money.");
		}
		ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dgrottidelete){
		if(response){
			switch(listitem){
				case 0:
				{
					if(pInfo[playerid][vModel1] != 0) DeleteOwnedVehicle(playerid, pInfo[playerid][vModel1]);
					else if(pInfo[playerid][vModel2] != 0) DeleteOwnedVehicle(playerid, pInfo[playerid][vModel2]);
					else DeleteOwnedVehicle(playerid, pInfo[playerid][vModel3]);
				}
				case 1:
				{
					if(pInfo[playerid][vModel2] == 0) DeleteOwnedVehicle(playerid, pInfo[playerid][vModel3]); //if vmodel1 exists and 2 doesn't. it's option 3. if vmodel1 doesn't exist, and 2 doesn't, there is no 2nd option in list, therefore case doesn't exists.
					else DeleteOwnedVehicle(playerid, pInfo[playerid][vModel2]); //if model1 exists, and 2 isn't blank.
				}
				case 2: DeleteOwnedVehicle(playerid, pInfo[playerid][vModel3]);
			}
			SendClientMessage(playerid, Col_Green, "Vehicle deleted.");
		}
		ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dgrottibuy){
		if(response){
			switch(listitem){
				case 0: //NRG
				{
					if(pInfo[playerid][Money] < 100000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 522, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 100000;
						return AllowPicks(playerid), 1;
					}
				}
				case 1: //Infernus
				{
					if(pInfo[playerid][Money] < 120000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 411, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 120000;
						return AllowPicks(playerid), 1;
					}
				}
				case 2: //Turismo
				{
					if(pInfo[playerid][Money] < 90000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 451, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 90000;
						return AllowPicks(playerid), 1;
					}
				}
				case 3: //Sultan
				{
					if(pInfo[playerid][Money] < 100000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 560, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 100000;
						return AllowPicks(playerid), 1;
					}
				}
				case 4: //Cheetah
				{
					if(pInfo[playerid][Money] < 90000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 415, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 90000;
						return AllowPicks(playerid), 1;
					}
				}
				case 5: //Remington
				{
					if(pInfo[playerid][Money] < 100000) SendClientMessage(playerid, Col_Red, "You don't have enough money to buy that vehicle.");
					else {
						BuyOwnedVehicle(playerid, 534, 560.5355,-1282.8049,18.1914);
						pInfo[playerid][Money] -= 100000;
						return AllowPicks(playerid), 1;
					}
				}
			}
		}
		ShowPlayerDialog(playerid, dgrottiwelcome, DIALOG_STYLE_LIST, "Welcome to grotti, please choose your action:", "Bring a car\nBuy a car\nDelete a car", "Select", "Cancel");
		return 1;
	}
	else if (dialogid == dhouse){
		if (!response) {
			SetPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX], hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
			pInfo[playerid][CurrentHouse] = -1;
			AllowPicks(playerid);
			return 1;
		}
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		if (!hInfo[pInfo[playerid][CurrentHouse]][owned]){
			switch (listitem){
				case 0:
				{
					if (pInfo[playerid][BankMoney] < hInfo[pInfo[playerid][CurrentHouse]][hPrice]) SendClientMessage(playerid, Col_Red, "You do not have enough money in your bank to buy this house.");
					else{
						hOwnerName[pInfo[playerid][CurrentHouse]] = pname;
						hInfo[pInfo[playerid][CurrentHouse]][owned] = true;
						DestroyDynamicPickup(hInfo[pInfo[playerid][CurrentHouse]][hPickup]);
						hInfo[pInfo[playerid][CurrentHouse]][hPickup] = CreateDynamicPickup(1273, 1, hInfo[pInfo[playerid][CurrentHouse]][hPickX], hInfo[pInfo[playerid][CurrentHouse]][hPickY], hInfo[pInfo[playerid][CurrentHouse]][hPickZ]);
						DynamicPickupModel[hInfo[pInfo[playerid][CurrentHouse]][hPickup]] = 1273;
						SendClientMessage(playerid, Col_Green, "You have succesfully bought that house.");
						pInfo[playerid][BankMoney] -= hInfo[pInfo[playerid][CurrentHouse]][hPrice];
						SetPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX], hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
						pInfo[playerid][CurrentHouse] = -1;
					}
				}
				case 1: EnterHouse(playerid);
			}
		}else if (!strcmp (hOwnerName[pInfo[playerid][CurrentHouse]], pname, true)){
			switch (listitem){
				case 0: EnterHouse(playerid);
				case 1:
				{
					hOwnerName[pInfo[playerid][CurrentHouse]] = "NONE";
					hInfo[pInfo[playerid][CurrentHouse]][owned] = false;
					DestroyDynamicPickup(hInfo[pInfo[playerid][CurrentHouse]][hPickup]);
					hInfo[pInfo[playerid][CurrentHouse]][hPickup] = CreateDynamicPickup(1272, 1, hInfo[pInfo[playerid][CurrentHouse]][hPickX], hInfo[pInfo[playerid][CurrentHouse]][hPickY], hInfo[pInfo[playerid][CurrentHouse]][hPickZ]);
					DynamicPickupModel[hInfo[pInfo[playerid][CurrentHouse]][hPickup]] = 1272;
					SendClientMessage(playerid, Col_Green, "You have succesfully sold that house. The money was transferred to your bank account.");
					pInfo[playerid][BankMoney] += hInfo[pInfo[playerid][CurrentHouse]][hPrice];
					SetPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX], hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
					if (pInfo[playerid][SpawnHouse] == pInfo[playerid][CurrentHouse]) pInfo[playerid][SpawnHouse] = -1;
					pInfo[playerid][CurrentHouse] = -1;
				}
				case 2:
				{
					pInfo[playerid][SpawnHouse] = pInfo[playerid][CurrentHouse];
					SendClientMessage(playerid, Col_Green, "From now on, you will spawn at this house.");
					SetPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX], hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
					pInfo[playerid][CurrentHouse] = -1;
				}
				case 3:
				{
					pInfo[playerid][SpawnHouse] = -1;
					SendClientMessage(playerid, Col_Green, "From now on, you will not spawn at houses.");
					SetPlayerPos(playerid, hInfo[pInfo[playerid][CurrentHouse]][hExitX], hInfo[pInfo[playerid][CurrentHouse]][hExitY], hInfo[pInfo[playerid][CurrentHouse]][hExitZ]);
					pInfo[playerid][CurrentHouse] = -1;
				}
			}
		}else{
			switch (listitem){
				case 0: EnterHouse(playerid);
			}
		}
		AllowPicks(playerid);
		return 1;
	}
	else if (dialogid == dofferdrugs){
		if(!response) return 1;
		new amount, pname[MAX_PLAYER_NAME], formatted[148], total;
		if (sscanf(inputtext, "i", amount)) SendClientMessage(playerid, Col_Red, "Please specify an amount.");
		else if (amount <= 0 ) SendClientMessage(playerid, Col_Red, "Amount can only be a positive number.");
		else if ((amount + pInfo[playerid][Drugs]) > 100) format(formatted, 148, "You can only buy up to %d drugs for a max of 100.", 100-pInfo[playerid][Drugs]), SendClientMessage(playerid, Col_Red, formatted);
		else if ((amount * pInfo[playerid][DealingPrice]) > pInfo[playerid][Money]) format(formatted, 148, "You do not have enough money to buy that amount of drugs. You can buy only %d drugs in that price.", floatround(pInfo[playerid][Money]/pInfo[playerid][DealingPrice], floatround_floor)), SendClientMessage(playerid, Col_Red, formatted);
		else if (amount > pInfo[pInfo[playerid][DealerID]][Drugs]) SendClientMessage(playerid, Col_Red, "You cannot buy that amount, dealer does not have enough drugs.");
		else {
			total = amount * pInfo[playerid][DealingPrice];
			pInfo[playerid][Money] -= total;
			pInfo[playerid][Drugs] += amount;
			pInfo[pInfo[playerid][DealerID]][Money] += total;
			pInfo[pInfo[playerid][DealerID]][Drugs] -= amount;
			GetPlayerName(pInfo[playerid][DealerID], pname, MAX_PLAYER_NAME);
			format(formatted, 148, "You have bought an amount of %d drugs from %s. Total price: $%d.", amount, pname, total);
			SendClientMessage(playerid, Col_Pink, formatted);
			GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
			format(formatted, 148, "%s has bought an amount of %d drugs. Total price: $%d. You received a bonus of 2 score points.", pname, amount, total);
			SendClientMessage(pInfo[playerid][DealerID], Col_Pink, formatted);
			SetPlayerScore(pInfo[playerid][DealerID], GetPlayerScore(pInfo[playerid][DealerID]) + 2);
			pInfo[pInfo[playerid][DealerID]][sDrugDeals]++;
			return 1;
		}
		GetPlayerName(pInfo[playerid][DealerID], pname, MAX_PLAYER_NAME);
		format(formatted, 148, "%s(%d) is selling you drugs for $%d per gram for a max of %d grams.\n Please type the amount of drugs below.", pname, pInfo[playerid][DealerID], pInfo[playerid][DealingPrice], pInfo[pInfo[playerid][DealerID]][Drugs]);
		ShowPlayerDialog(playerid, dofferdrugs, DIALOG_STYLE_INPUT, "Buy drugs", formatted, "Buy", "Cancel");
		return 1;
	}
    return 0;
}
//----------------------------------------------------------
public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;
	new randSpawn = 0;
	SetPlayerInterior(playerid,0);
	new pskin = GetPlayerSkin(playerid);
	if((pskin >= 280 && pskin <= 284) || pskin == 286 || pskin == 288 || pskin == 71){
		pInfo[playerid][Class] = cCop;
		SendClientMessage(playerid, Col_Blue, "You are now a cop. Your job is to arrest wanted criminals by cuffing them (/cuff) and arresting (/ar).");
		SendClientMessage(playerid, Col_Blue, "You start with 1 wallet.");
		pInfo[playerid][WalletsLeft] = 1;
		SetPlayerOCT(playerid);
	}else{
		pInfo[playerid][Class] = cRobber;
		ShowPlayerDialog(playerid, dclasses, DIALOG_STYLE_LIST, "Choose a class:", "Normal Robber\nWeapon Dealer\nDrug Dealer", "Select", "");
	}
	SetPlayerOCT(playerid);
	if(CITY_LOS_SANTOS == gPlayerCitySelection[playerid]) {
		if(pInfo[playerid][Class] == cCop) SetPlayerPos(playerid, 1568.9387,-1694.1570,5.8906);
		else if (pInfo[playerid][SpawnHouse] != -1 && (hInfo[pInfo[playerid][SpawnHouse]][hExitX] != 0 || hInfo[pInfo[playerid][SpawnHouse]][hExitY] !=0 || hInfo[pInfo[playerid][SpawnHouse]][hExitZ] !=0)) SetPlayerPos(playerid, hInfo[pInfo[playerid][SpawnHouse]][hExitX], hInfo[pInfo[playerid][SpawnHouse]][hExitY], hInfo[pInfo[playerid][SpawnHouse]][hExitZ]);
		else{
 	    randSpawn = random(sizeof(gRandomSpawns_LosSantos));
 	    SetPlayerPos(playerid,
		 gRandomSpawns_LosSantos[randSpawn][0],
		 gRandomSpawns_LosSantos[randSpawn][1],
		 gRandomSpawns_LosSantos[randSpawn][2]);
		SetPlayerFacingAngle(playerid,gRandomSpawns_LosSantos[randSpawn][3]);
		}
	}
	else if(CITY_SAN_FIERRO == gPlayerCitySelection[playerid]) {
		if(pInfo[playerid][Class] == cCop) SetPlayerPos(playerid, -1589.7664,716.9137,-5.2422);
		else if (pInfo[playerid][SpawnHouse] != -1 && (hInfo[pInfo[playerid][SpawnHouse]][hExitX] != 0 || hInfo[pInfo[playerid][SpawnHouse]][hExitY] !=0 || hInfo[pInfo[playerid][SpawnHouse]][hExitZ] !=0)) SetPlayerPos(playerid, hInfo[pInfo[playerid][SpawnHouse]][hExitX], hInfo[pInfo[playerid][SpawnHouse]][hExitY], hInfo[pInfo[playerid][SpawnHouse]][hExitZ]);
		else{
		randSpawn = random(sizeof(gRandomSpawns_SanFierro));
 	    SetPlayerPos(playerid,
		 gRandomSpawns_SanFierro[randSpawn][0],
		 gRandomSpawns_SanFierro[randSpawn][1],
		 gRandomSpawns_SanFierro[randSpawn][2]);
		SetPlayerFacingAngle(playerid,gRandomSpawns_SanFierro[randSpawn][3]);
		}
	}
	else if(CITY_LAS_VENTURAS == gPlayerCitySelection[playerid]) {
		if(pInfo[playerid][Class] == cCop) SetPlayerPos(playerid, 2293.2473,2451.7112,10.8203);
		else if (pInfo[playerid][SpawnHouse] != -1 && (hInfo[pInfo[playerid][SpawnHouse]][hExitX] != 0 || hInfo[pInfo[playerid][SpawnHouse]][hExitY] !=0 || hInfo[pInfo[playerid][SpawnHouse]][hExitZ] !=0)) SetPlayerPos(playerid, hInfo[pInfo[playerid][SpawnHouse]][hExitX], hInfo[pInfo[playerid][SpawnHouse]][hExitY], hInfo[pInfo[playerid][SpawnHouse]][hExitZ]);
		else{
		randSpawn = random(sizeof(gRandomSpawns_LasVenturas));
 	    SetPlayerPos(playerid,
		 gRandomSpawns_LasVenturas[randSpawn][0],
		 gRandomSpawns_LasVenturas[randSpawn][1],
		 gRandomSpawns_LasVenturas[randSpawn][2]);
		SetPlayerFacingAngle(playerid,gRandomSpawns_LasVenturas[randSpawn][3]);
		}
	}
	SetPlayerSkillLevel(playerid,WEAPONSKILL_PISTOL,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_PISTOL_SILENCED,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_DESERT_EAGLE,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_SHOTGUN,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_SAWNOFF_SHOTGUN,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_SPAS12_SHOTGUN,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_MICRO_UZI,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_MP5,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_AK47,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_M4,1000);
    SetPlayerSkillLevel(playerid,WEAPONSKILL_SNIPERRIFLE,1000);
	TogglePlayerClock(playerid, 0);
	pInfo[playerid][alive]=true;
	if (pInfo[playerid][JailTime]>1){//1 = adunjail
		new stringy[19] = "leaving in jail";
		CallRemoteFunction("adjailplayer", "iis[19]", playerid,  pInfo[playerid][JailTime], stringy); //To check for jail evade
		pInfo[playerid][JailTime] = 0;
	}
	SetCameraBehindPlayer(playerid);
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if (PRESSEDKEY(KEY_YES)){ //(Y)
		if (IsPlayerInRangeOfPoint(playerid, 15.0, 2073.0200200,-1878.7998000, 13.29795) && GetPVarInt(playerid, "Admin") > 0){
			if (!MovingObject[gAdminGarageState]){
				MoveDynamicObject(MovingObject[gAdminGarageID0] ,2073.0200200,-1878.7998000,8.0000000, 2.0,0.0000000,0.0000000,90.0000000); //gate [0] - to open, z = 8
				MoveDynamicObject(MovingObject[gAdminGarageID1] ,2073.0300300,-1868.8000500,8.0000000,2.0,0.0000000,0.0000000,90.0000000); //gate [1] - to open, z = 8
				MovingObject[gAdminGarageState] = true;
				SendClientMessage(playerid, Col_Green, "Garage Opening.");
			}else{
				MoveDynamicObject(MovingObject[gAdminGarageID0],2073.0200200,-1878.7998000,16.4000000,2.0, 0.0000000,0.0000000,90.0000000); //gate [0]
				MoveDynamicObject(MovingObject[gAdminGarageID1],2073.0300300,-1868.8000500,16.4000000,2.0, 0.0000000,0.0000000,90.0000000); //gate [1]
				MovingObject[gAdminGarageState] = false;
				SendClientMessage(playerid, Col_Green, "Garage Closing.");
			}
			return 1;
		}
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		if (IsPlayerInRangeOfPoint(playerid, 10.0, 1520.66174, -694.68091, 95.57840) && !strcmp(pname, "[GCnR]Duckz", true)){
			if (!MovingObject[gDuckzState]){
				MoveDynamicObject(MovingObject[gDuckzID], 1520.66174, -694.68091, 91.97930, 2.0);
				MovingObject[gDuckzState] = true;
				SendClientMessage(playerid, Col_Green, "Garage Opening.");
			}else{
				MoveDynamicObject(MovingObject[gDuckzID], 1520.66174, -694.68091, 95.57840, 2.0);
				MovingObject[gDuckzState] = false;
				SendClientMessage(playerid, Col_Green, "Garage Closing.");
			}
			return 1;
		}
	}
	return 1;
}
//----------------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{ 
	if(killerid == INVALID_PLAYER_ID && pInfo[playerid][raped]){
		new pname[MAX_PLAYER_NAME], formatted[128];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) has died from a sex disease.", pname, playerid);
		SendClientMessageToAll(Col_LightOrange, formatted);
	}
	SendDeathMessage(killerid, playerid, reason);
	SetPlayerColor(playerid, Col_Gray);
	SetPlayerWantedLevel(playerid, 0);
	pInfo[playerid][alive]=false;
	pInfo[playerid][JailTime]=0;
	pInfo[playerid][CurrentHouse] = -1;
	pInfo[playerid][Drugs]=0;
	pInfo[playerid][WalletsLeft]=0;
	pInfo[playerid][DrugTime] = 0;
	pInfo[playerid][drugbag]=false;
	pInfo[playerid][cuffed] = false;
	pInfo[playerid][needweapons] = false;
	pInfo[playerid][needdrugs] = false;
	pInfo[playerid][raped] = false;
	pInfo[playerid][Class] = cNone;
	KillTimer(pInfo[playerid][RapeTimer]);
	if(pInfo[killerid][Class] != cCop) CommitedCrime(killerid, 10);
	return 1;
}

//----------------------------------------------------------

ClassSel_SetupCharSelection(playerid)
{
   	if(gPlayerCitySelection[playerid] == CITY_LOS_SANTOS) {
		SetPlayerInterior(playerid,11);
		SetPlayerPos(playerid,508.7362,-87.4335,998.9609);
		SetPlayerFacingAngle(playerid,0.0);
    	SetPlayerCameraPos(playerid,508.7362,-83.4335,998.9609);
		SetPlayerCameraLookAt(playerid,508.7362,-87.4335,998.9609);
	}
	else if(gPlayerCitySelection[playerid] == CITY_SAN_FIERRO) {
		SetPlayerInterior(playerid,3);
		SetPlayerPos(playerid,-2673.8381,1399.7424,918.3516);
		SetPlayerFacingAngle(playerid,181.0);
    	SetPlayerCameraPos(playerid,-2673.2776,1394.3859,918.3516);
		SetPlayerCameraLookAt(playerid,-2673.8381,1399.7424,918.3516);
	}
	else if(gPlayerCitySelection[playerid] == CITY_LAS_VENTURAS) {
		SetPlayerInterior(playerid,3);
		SetPlayerPos(playerid,349.0453,193.2271,1014.1797);
		SetPlayerFacingAngle(playerid,286.25);
    	SetPlayerCameraPos(playerid,352.9164,194.5702,1014.1875);
		SetPlayerCameraLookAt(playerid,349.0453,193.2271,1014.1797);
	}
	
}

//----------------------------------------------------------
// Used to init textdraws of city names

ClassSel_InitCityNameText(Text:txtInit)
{
  	TextDrawUseBox(txtInit, 0);
	TextDrawLetterSize(txtInit,1.25,3.0);
	TextDrawFont(txtInit, 0);
	TextDrawSetShadow(txtInit,0);
    TextDrawSetOutline(txtInit,1);
    TextDrawColor(txtInit,0xEEEEEEFF);
    TextDrawBackgroundColor(txtClassSelHelper,0x000000FF);
}

//----------------------------------------------------------

ClassSel_InitTextDraws()
{
    // Init our observer helper text display
	txtLosSantos = TextDrawCreate(10.0, 380.0, "Los Santos");
	ClassSel_InitCityNameText(txtLosSantos);
	txtSanFierro = TextDrawCreate(10.0, 380.0, "San Fierro");
	ClassSel_InitCityNameText(txtSanFierro);
	txtLasVenturas = TextDrawCreate(10.0, 380.0, "Las Venturas");
	ClassSel_InitCityNameText(txtLasVenturas);

    // Init our observer helper text display
	txtClassSelHelper = TextDrawCreate(10.0, 415.0,
	   " Press ~b~~k~~GO_LEFT~ ~w~or ~b~~k~~GO_RIGHT~ ~w~to switch cities.~n~ Press ~r~~k~~PED_FIREWEAPON~ ~w~to select.");
	TextDrawUseBox(txtClassSelHelper, 1);
	TextDrawBoxColor(txtClassSelHelper,0x222222BB);
	TextDrawLetterSize(txtClassSelHelper,0.3,1.0);
	TextDrawTextSize(txtClassSelHelper,400.0,40.0);
	TextDrawFont(txtClassSelHelper, 2);
	TextDrawSetShadow(txtClassSelHelper,0);
    TextDrawSetOutline(txtClassSelHelper,1);
    TextDrawBackgroundColor(txtClassSelHelper,0x000000FF);
    TextDrawColor(txtClassSelHelper,0xFFFFFFFF);
}

//----------------------------------------------------------

ClassSel_SetupSelectedCity(playerid)
{
	if(gPlayerCitySelection[playerid] == -1) {
		gPlayerCitySelection[playerid] = CITY_LOS_SANTOS;
	}
	
	if(gPlayerCitySelection[playerid] == CITY_LOS_SANTOS) {
		SetPlayerInterior(playerid,0);
   		SetPlayerCameraPos(playerid,1630.6136,-2286.0298,110.0);
		SetPlayerCameraLookAt(playerid,1887.6034,-1682.1442,47.6167);
		
		TextDrawShowForPlayer(playerid,txtLosSantos);
		TextDrawHideForPlayer(playerid,txtSanFierro);
		TextDrawHideForPlayer(playerid,txtLasVenturas);
	}
	else if(gPlayerCitySelection[playerid] == CITY_SAN_FIERRO) {
		SetPlayerInterior(playerid,0);
   		SetPlayerCameraPos(playerid,-1300.8754,68.0546,129.4823);
		SetPlayerCameraLookAt(playerid,-1817.9412,769.3878,132.6589);
		
		TextDrawHideForPlayer(playerid,txtLosSantos);
		TextDrawShowForPlayer(playerid,txtSanFierro);
		TextDrawHideForPlayer(playerid,txtLasVenturas);
	}
	else if(gPlayerCitySelection[playerid] == CITY_LAS_VENTURAS) {
		SetPlayerInterior(playerid,0);
   		SetPlayerCameraPos(playerid,1310.6155,1675.9182,110.7390);
		SetPlayerCameraLookAt(playerid,2285.2944,1919.3756,68.2275);
		
		TextDrawHideForPlayer(playerid,txtLosSantos);
		TextDrawHideForPlayer(playerid,txtSanFierro);
		TextDrawShowForPlayer(playerid,txtLasVenturas);
	}
}

//----------------------------------------------------------

ClassSel_SwitchToNextCity(playerid)
{
    gPlayerCitySelection[playerid]++;
	if(gPlayerCitySelection[playerid] > CITY_LAS_VENTURAS) {
	    gPlayerCitySelection[playerid] = CITY_LOS_SANTOS;
	}
	PlayerPlaySound(playerid,1052,0.0,0.0,0.0);
	gPlayerLastCitySelectionTick[playerid] = GetTickCount();
	ClassSel_SetupSelectedCity(playerid);
}

//----------------------------------------------------------

ClassSel_SwitchToPreviousCity(playerid)
{
    gPlayerCitySelection[playerid]--;
	if(gPlayerCitySelection[playerid] < CITY_LOS_SANTOS) {
	    gPlayerCitySelection[playerid] = CITY_LAS_VENTURAS;
	}
	PlayerPlaySound(playerid,1053,0.0,0.0,0.0);
	gPlayerLastCitySelectionTick[playerid] = GetTickCount();
	ClassSel_SetupSelectedCity(playerid);
}

//----------------------------------------------------------

ClassSel_HandleCitySelection(playerid)
{
	new Keys,ud,lr;
    GetPlayerKeys(playerid,Keys,ud,lr);
    
    if(gPlayerCitySelection[playerid] == -1) {
		ClassSel_SwitchToNextCity(playerid);
		return;
	}

	// only allow new selection every ~500 ms
	if( (GetTickCount() - gPlayerLastCitySelectionTick[playerid]) < 500 ) return;
	
	if(Keys & KEY_FIRE) {
	    gPlayerHasCitySelected[playerid] = 1;
	    TextDrawHideForPlayer(playerid,txtClassSelHelper);
		TextDrawHideForPlayer(playerid,txtLosSantos);
		TextDrawHideForPlayer(playerid,txtSanFierro);
		TextDrawHideForPlayer(playerid,txtLasVenturas);
	    TogglePlayerSpectating(playerid,0);
	    return;
	}
	
	if(lr > 0) {
	   ClassSel_SwitchToNextCity(playerid);
	}
	else if(lr < 0) {
	   ClassSel_SwitchToPreviousCity(playerid);
	}
}

//----------------------------------------------------------
public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if(pInfo[playerid][login] == false){
		Kick(playerid);
		return 0;
	}
	return 1;
}
public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid)) return 1;
	if(gPlayerHasCitySelected[playerid]) {
		ClassSel_SetupCharSelection(playerid);
		if(pInfo[playerid][login] == false) Kick(playerid);
		if(classid >= 0 && classid <=6) GameTextForPlayer(playerid, "~b~Police Officer", 1500, 6);
		else GameTextForPlayer(playerid, "Civilian", 1500, 6);
		return 1;
	} else {
		if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING) {
			TogglePlayerSpectating(playerid,1);
    		TextDrawShowForPlayer(playerid, txtClassSelHelper);
    		gPlayerCitySelection[playerid] = -1;
		}
  	}
    
	return 0;
}

//----------------------------------------------------------

public OnGameModeInit()
{
	SetGameModeText("Game Cops and Robbers");
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
	ShowNameTags(1);
	SetNameTagDrawDistance(40.0);
	EnableStuntBonusForAll(0);
	SetWeather(2);
	SetWorldTime(11);
	UsePlayerPedAnims();
	//ManualVehicleEngineAndLights();
	//LimitGlobalChatRadius(300.0);
	ClassSel_InitTextDraws();
	LoadClasses();
	LoadAllVehicles();
	LoadObjects();
	LoadHouses();
	LoadHouseModels();
	/* In PAWN variables are automatically declared 0 (false). No need for redecleration */
	for (new i; i<MAX_PLAYERS; i++){ //initialize
		pInfo[i][pmon] = true;
		pInfo[i][CurrentHouse] = -1;
		pInfo[i][SpawnHouse] = -1;
	}
	SetTimer("MoneyUpdate", 2400, true);
	LoadPickups();
	//Weapons menu
	MenuIDs[mWeapons] = CreateMenu("mWeapons", 2, 150.0, 100.0, 180.0, 40.0);
	AddMenuItem(MenuIDs[mWeapons], 0, "Armor");
	AddMenuItem(MenuIDs[mWeapons], 1, "$500");
	AddMenuItem(MenuIDs[mWeapons], 0, "MP5 (500)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$2000");
	AddMenuItem(MenuIDs[mWeapons], 0, "M4 (150)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$3500");
	AddMenuItem(MenuIDs[mWeapons], 0, "Tec-9 (60)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$300");
	AddMenuItem(MenuIDs[mWeapons], 0, "Micro SMG/Uzi (120)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$500");
	AddMenuItem(MenuIDs[mWeapons], 0, "Sniper (10)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$5000");
	AddMenuItem(MenuIDs[mWeapons], 0, "Sawn-Off Shotgun (12)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$800");
	AddMenuItem(MenuIDs[mWeapons], 0, "Combat Shotgun (10)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$1000");
	AddMenuItem(MenuIDs[mWeapons], 0, "Desert Eagle (15)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$1200");
	AddMenuItem(MenuIDs[mWeapons], 0, "Weapon Stacks (10)");
	AddMenuItem(MenuIDs[mWeapons], 1, "$50,000");
	MenuIDs[mWeaponDeals] = CreateMenu("Weapon Dealer", 2, 150.0, 100.0, 180.0, 40.0);
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Armor");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$200");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "MP5 (500)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$500");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "M4 (150)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$1250");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Tec-9 (60)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$100");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Micro SMG/Uzi (120)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$170");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Sniper (10)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$1600");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Sawn-Off Shotgun (12)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$400");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Combat Shotgun (10)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$350");
	AddMenuItem(MenuIDs[mWeaponDeals], 0, "Desert Eagle (15)");
	AddMenuItem(MenuIDs[mWeaponDeals], 1, "$400");
	//Colors for SetPlayerOCT
	cColors[cCop] = Col_Blue;
	cColors[cRobber] = COLOR_WHITE;
	cColors[cCarJack] = COLOR_WHITE;
	cColors[cWeaponDeal] = COLOR_WHITE;
	cColors[cDrugDeal] = COLOR_WHITE;
	return 1;
}
public OnGameModeExit()
{
	for (new i; i != MAX_HOUSES; i++){
		if (!fexist(hPath(i))) continue;
		new INI:file = INI_Open(hPath(i)); //will open their file
		INI_SetTag(file,"House Data");
		// INI_WriteInt(file,"ID", hInfo[i][hID]); //House ID
		/* House Pickups and Exits */
		// INI_WriteFloat(file,"PickX", hInfo[i][hPickX]);
		// INI_WriteFloat(file,"PickY", hInfo[i][hPickY]);
		// INI_WriteFloat(file,"PickZ", hInfo[i][hPickZ]);
		// INI_WriteInt(file,"Design", hInfo[i][hDesign]);
		// INI_WriteInt(file,"Price", hInfo[i][hPrice]);
		INI_WriteBool(file,"Owned", hInfo[i][owned]);
		INI_WriteString(file,"Owner", hOwnerName[i]);
		// INI_WriteFloat(file,"ExitX", hInfo[i][hExitX]);
		// INI_WriteFloat(file,"ExitY", hInfo[i][hExitY]);
		// INI_WriteFloat(file,"ExitZ", hInfo[i][hExitZ]);
		INI_Close(file);
	}
    print("Gamemode ended.");
    return 1;
}
//----------------------------------------------------------
public OnPlayerUpdate(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;
	// changing cities by inputs
	if( !gPlayerHasCitySelected[playerid] &&
	    GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && !pInfo[playerid][alive]) {
	    ClassSel_HandleCitySelection(playerid);
	    return 1;
	}
	if (pInfo[playerid][needjail]) pInfo[playerid][needjail] = false; //for anti-hack
	return 1;
}
public OnPlayerSelectedMenuRow(playerid, row)
{
	new Menu:Current = GetPlayerMenu(playerid);
    if(Current == MenuIDs[mWeapons])
    {
        switch(row)
        {
            case 0:
			{
				if(pInfo[playerid][Money] < 500) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 500;
					SetPlayerArmour(playerid, 100);
				}
			}
            case 1:
			{
				if(pInfo[playerid][Money] < 2000) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 2000;
					GivePlayerWeapon(playerid, WEAPON_MP5, 500);
				}
			}
			case 2:
			{
				if(pInfo[playerid][Money] < 3500) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 3500;
					GivePlayerWeapon(playerid, WEAPON_M4, 150);
				}
			}
			case 3:
			{
				if(pInfo[playerid][Money] < 300) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 300;
					GivePlayerWeapon(playerid, WEAPON_TEC9, 60);
				}
			}
			case 4:
			{
				if(pInfo[playerid][Money] < 500) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 500;
					GivePlayerWeapon(playerid, WEAPON_UZI, 120);
				}
				
			}
			case 5:
			{
				if(pInfo[playerid][Money] < 5000) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 5000;
					GivePlayerWeapon(playerid, WEAPON_SNIPER, 10);
				}
				
			}
			case 6:
			{
				if(pInfo[playerid][Money] < 800) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 800;
					GivePlayerWeapon(playerid, WEAPON_SAWEDOFF, 12);
				}
				
			}
			case 7:
			{
				if(pInfo[playerid][Money] < 1000) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 1000;
					GivePlayerWeapon(playerid, WEAPON_SHOTGSPA, 10);
				}
				
			}
			case 8:
			{
				if(pInfo[playerid][Money] < 1200) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 1200;
					GivePlayerWeapon(playerid, WEAPON_DEAGLE, 15);
				}
				
			}
			case 9:
			{
				if (pInfo[playerid][Class] != cWeaponDeal) SendClientMessage(playerid, Col_Red, "This is only for weapon dealers.");
				else if (pInfo[playerid][Money] < 50000) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else if(pInfo[playerid][WeaponStacks] > 10) SendClientMessage(playerid, Col_Red, "You can't have more than 20 stacks.");
				else{
					pInfo[playerid][Money] -= 50000;
					pInfo[playerid][WeaponStacks] += 10;
				}
			}
        }
		ShowMenuForPlayer(MenuIDs[mWeapons], playerid);
		return 1;
    }
	else if(Current == MenuIDs[mWeaponDeals])
    {
        switch(row)
        {
            case 0:
			{
				if(pInfo[playerid][Money] < 200) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 200;
					SetPlayerArmour(playerid, 100);
				}
			}
            case 1:
			{
				if(pInfo[playerid][Money] < 500) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 500;
					GivePlayerWeapon(playerid, WEAPON_MP5, 500);
				}
			}
			case 2:
			{
				if(pInfo[playerid][Money] < 1250) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 1250;
					GivePlayerWeapon(playerid, WEAPON_M4, 150);
				}
			}
			case 3:
			{
				if(pInfo[playerid][Money] < 100) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 100;
					GivePlayerWeapon(playerid, WEAPON_TEC9, 60);
				}
			}
			case 4:
			{
				if(pInfo[playerid][Money] < 170) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 170;
					GivePlayerWeapon(playerid, WEAPON_UZI, 120);
				}
				
			}
			case 5:
			{
				if(pInfo[playerid][Money] < 1600) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 1600;
					GivePlayerWeapon(playerid, WEAPON_SNIPER, 10);
				}
				
			}
			case 6:
			{
				if(pInfo[playerid][Money] < 400) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 400;
					GivePlayerWeapon(playerid, WEAPON_SAWEDOFF, 12);
				}
				
			}
			case 7:
			{
				if(pInfo[playerid][Money] < 350) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 350;
					GivePlayerWeapon(playerid, WEAPON_SHOTGSPA, 10);
				}
				
			}
			case 8:
			{
				if(pInfo[playerid][Money] < 400) SendClientMessage(playerid, Col_Red, "Not enough money.");
				else{
					pInfo[playerid][Money] -= 400;
					GivePlayerWeapon(playerid, WEAPON_DEAGLE, 15);
				}
				
			}
        }
		ShowMenuForPlayer(MenuIDs[mWeaponDeals], playerid);
		return 1;
    }
	print("***MENU BUG*** Severity - 4 No option received");
	TogglePlayerControllable(playerid, 1); //Avoid players getting stuck in case of bug
	return 1;
}
public OnPlayerExitedMenu(playerid){
	TogglePlayerControllable(playerid, 1);
	return 1;
}
public OnVehicleDeath(vehicleid, killerid)
{
	if (vInfo[vehicleid][OwnGroup] == gPlayer || vInfo[vehicleid][OwnGroup] == gAdmin){
		DestroyVehicle(vehicleid);
		vInfo[vehicleid][OwnGroup] = gNone;
	}
	return 1;
}
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if (vInfo[vehicleid][OwnGroup] == gAdmin && ispassenger == 0 && GetPVarInt(playerid, "Admin") < 3){
		new Float:pX, Float:pY, Float:pZ;
		GetPlayerPos(playerid, pX, pY, pZ);
		SetPlayerPos(playerid, pX, pY, pZ);
		SendClientMessage(playerid, Col_Blue, "This is an admin's vehicle. You cannot enter or steal it.");
		return 0;
	}
	return 1;
}
public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if (oldstate == PLAYER_STATE_DRIVER) {
		new engine, lights, alarm, doors, bonnet, boot, objective;
		GetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, doors, bonnet, boot, objective);
		SetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, 0, bonnet, boot, objective);
		vInfo[pInfo[playerid][CurrentVeh]][Driver] = INVALID_PLAYER_ID;
	}
	pInfo[playerid][CurrentVeh] = GetPlayerVehicleID(playerid); // ORDER MATTERS!
	if (newstate == PLAYER_STATE_PASSENGER){
		if (vInfo[pInfo[playerid][CurrentVeh]][Driver] != INVALID_PLAYER_ID && GetPlayerWantedLevel(playerid) > 0 && pInfo[vInfo[pInfo[playerid][CurrentVeh]][Driver]][Class] != cCop && (GetPlayerWantedLevel(vInfo[pInfo[playerid][CurrentVeh]][Driver]) == 0 || pInfo[vInfo[pInfo[playerid][CurrentVeh]][Driver]][LastWantedCarry] < gettime())){
			CommitedCrime(vInfo[pInfo[playerid][CurrentVeh]][Driver], 1);
			pInfo[vInfo[pInfo[playerid][CurrentVeh]][Driver]][LastWantedCarry] = gettime()+120;
			SendClientMessage(vInfo[pInfo[playerid][CurrentVeh]][Driver], Col_Yellow, "You are carrying wanted players!");
		}
	}
	else if (newstate == PLAYER_STATE_DRIVER){
		vInfo[pInfo[playerid][CurrentVeh]][Driver] = playerid;
		if (vInfo[pInfo[playerid][CurrentVeh]][OwnGroup] == gAdmin) SendClientMessage(playerid, Col_Blue, "You are driving an admin vehicle. Please make sure not to abuse it. Use it only for admin work.");
		else if (vInfo[pInfo[playerid][CurrentVeh]][OwnGroup] == gPlayer){
			new pname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
			if (strcmp(vOwnerName[pInfo[playerid][CurrentVeh]], pname) == 0) SendClientMessage(playerid, Col_LightOrange, "This is your vehicle. Only you can drive it.");
			else {
				new formatted[128], Float:pX, Float:pY, Float:pZ;
				GetVehiclePos(pInfo[playerid][CurrentVeh], pX, pY, pZ);
				strunpack(formatted, vOwnerName[pInfo[playerid][CurrentVeh]]);
				format(formatted, 128, "This vehicle belongs to %s. You are not allowed to drive it.", formatted);
				SendClientMessage(playerid, Col_Red, formatted);
				RemovePlayerFromVehicle(playerid);
				SetVehiclePos(pInfo[playerid][CurrentVeh], pX, pY, pZ);
				return 0;
			}
		}else{
			switch (GetVehicleModel(pInfo[playerid][CurrentVeh])){
				case 596, 523, 427, 598, 597, 599, 528, 497, 490:
				{
					if(pInfo[playerid][Class] != cCop && (gettime() > pInfo[playerid][LastPoliceSteal] || GetPlayerWantedLevel(playerid) == 0)){
						CommitedCrime(playerid, 3);
						SendClientMessage(playerid, Col_Orange, "You stole a police vehicle!");
						pInfo[playerid][LastPoliceSteal] = gettime() + 180;
					}
					
				}
			}
		}
	}
	return 1;
}
public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	if (newinteriorid != 0) {
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), 1);
		SetPlayerVirtualWorld(playerid, 1);
	}
	else {
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), 0);
		SetPlayerVirtualWorld(playerid, 0);
		if (pInfo[playerid][CurrentHouse] != -1){
			SetTimerEx("SGPlayerPos", 1500, false, "ii", playerid, 0);
			SendClientMessage(playerid, Col_LightOrange, "You have left the house.");
			pInfo[playerid][CurrentHouse] = -1;
		}
	}
	return 1;
}
public OnPlayerPickUpDynamicPickup(playerid, pickupid){
	if (pInfo[playerid][disablepick]) return 1;
	if (DynamicPickupModel[pickupid] == 1272 || DynamicPickupModel[pickupid] == 1273) HousePicks(playerid, pickupid);
	return 1;
}
public OnPlayerPickUpPickup(playerid, pickupid)
{
	if (pInfo[playerid][disablepick]) return 1;
	if (PickupModel[pickupid] == 1318) EEPicks(playerid, pickupid);
	else if (PickupModel[pickupid] == 1239) InfoPicks(playerid, pickupid);
	else if (PickupModel[pickupid] == 1274) StorePicks(playerid, pickupid);
	else if(pickupid == Hospitals[0] || pickupid == Hospitals[1]){
		ShowPlayerDialog(playerid, dhospital, DIALOG_STYLE_LIST, "Welcome to the hospital", "Heal\t\t$2000\nCure\t\t$4000\nCure and Heal\t$5000", "Select", "Cancel");
		DisablePicks(playerid);
		return 1;
	}else if(pickupid == DrugHouses[0] || pickupid == DrugHouses[1]){
		if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot buy drugs.");
		ShowPlayerDialog(playerid, ddrugs, DIALOG_STYLE_LIST, "Welcome to the drug store", "Buy 10 grams\t\t5000$\nBuy 50 grams\t\t24000$\nBuy Drug Bag (protects up to 20 grams)\t6000$", "Select", "Cancel");
		return 1;
	}else if(pickupid == Ammunations[0] || pickupid == Ammunations[1] || pickupid == Ammunations[2]){
		ShowMenuForPlayer(MenuIDs[mWeapons], playerid);
		TogglePlayerControllable(playerid, 0);
		return 1;
	}
	return 1;
}
//----------------------------------------------------------

COMMAND:changepw(playerid)
{
	ShowPlayerDialog(playerid,dchangepw,DIALOG_STYLE_INPUT,"Change Password","Please insert your new password below.","Change","Cancel");
	return 1;
}
COMMAND:cmds(playerid)
{
	ShowPlayerDialog(playerid, dcmds, DIALOG_STYLE_LIST, "List of available commands", "General Commands\nRobber Commands\nClass Specific Commands\nServer Rules", "Select","Close");	
	return 1;
}
COMMAND:rules(playerid)
{
	ShowRules(playerid);
	return 1;
}
COMMAND:w(playerid, params[])
{
	new whisper[128], formatted[128], pname[MAX_PLAYER_NAME], Float:pX, Float:pY, Float:pZ;
	if (sscanf(params, "s[128]", whisper)) return SendClientMessage(playerid, Col_Red, "USAGE: /w [message]");
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && pInfo[playerid][Adminlevel] < 4) return SendClientMessage(playerid, Col_Red, "You cannot whisper.");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	GetPlayerPos(playerid, pX, pY, pZ);
	format(formatted, 128, "%s(%d) whispers: %s", pname, playerid, whisper);
	SetPlayerChatBubble(playerid, whisper, Col_Yellow, 10.0, 5000);
	foreach (new i : Player)
	{
		if (GetPlayerDistanceFromPoint(i, pX, pY, pZ) < 20) SendClientMessage(i, Col_Yellow, formatted);
	}
	return 1;
}
COMMAND:cw(playerid, params[])
{
	new whisper[128], formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "s[128]", whisper)) return SendClientMessage(playerid, Col_Red, "USAGE: /cw [message]");
	if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, Col_Red, "You are not inside a vehicle.");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) car whispers: %s", pname, playerid, whisper);
	foreach (new i : Player)
	{
		if (pInfo[playerid][CurrentVeh] == pInfo[i][CurrentVeh]) SendClientMessage(i, Col_Yellow, formatted);
	}
	return 1;
}
COMMAND:kill(playerid)
{
	if (GetPlayerWantedLevel(playerid) > 0) return SendClientMessage(playerid, Col_Red, "You can only use this command when you're innocent.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (GetPVarInt(playerid, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "You cannot use this command in jail");
	pInfo[playerid][raped] = false;
	new formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	SetPlayerHealth(playerid, 0);
	format(formatted, 128, "%s(%d) has commited suicide using /kill.", pname, playerid);
	SendClientMessageToAll(Col_Red, formatted);
	return 1;
}
COMMAND:cuff(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot cuff players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /cuff [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "Player is in a vehicle.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (pInfo[target][Class] == cCop) return SendClientMessage(playerid, Col_Red, "You cannot cuff law enforcement officers.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	if (pInfo[target][cuffed]) return SendClientMessage(playerid, Col_Red, "Player is already cuffed.");
	if (!pInfo[target][tazed]) return SendClientMessage(playerid, Col_Red, "You need to detain the suspect first! /taze him!");
	new pname[MAX_PLAYER_NAME], formatted[128];
	pInfo[target][cuffed] = true;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have been cuffed by %s. You may try to break them using /bc. Your cuffs will be automatically removed within 20 seconds.", pname);
	SendClientMessage(target, Col_Pink, formatted);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have cuffed %s. Please make sure you do not leave him cuffed.", pname);
	SendClientMessage(playerid, Col_Pink, formatted);
	SetPlayerAttachedObject(target, 8,19418,6,-0.031999,0.024000,-0.024000,-7.900000,-32.000011,-72.299987,1.115998,1.322000,1.406000);
	SetPlayerSpecialAction(target, SPECIAL_ACTION_CUFFED);
	TogglePlayerControllable(target, 0);
	SetTimerEx("restoretaze", 1000, false, "i", target);
	KillTimer(pInfo[target][CuffTimer]);
	pInfo[target][CuffTimer] = SetTimerEx("cuffexpire", 20000, false, "i", target);
	return 1;
}
COMMAND:clients(playerid)
{
	if (pInfo[playerid][Class] == cWeaponDeal){
		new formatted[128], pname[MAX_PLAYER_NAME];
		SendClientMessage(playerid, Col_LightOrange, "Client list:");
		foreach(new i : Player){
			if (pInfo[i][needweapons]){
				GetPlayerName(i, pname, MAX_PLAYER_NAME);
				format(formatted, 128, "%s(%d)", pname, i);
				SendClientMessage(playerid, Col_LightOrange, formatted);
			}
		}
		return 1;
	}else if (pInfo[playerid][Class] == cDrugDeal){
		new formatted[128], pname[MAX_PLAYER_NAME];
		SendClientMessage(playerid, Col_LightOrange, "Client list:");
		foreach(new i : Player){
			if (pInfo[i][needdrugs]){
				GetPlayerName(i, pname, MAX_PLAYER_NAME);
				format(formatted, 128, "%s(%d)", pname, i);
				SendClientMessage(playerid, Col_LightOrange, formatted);
			}
		}
		return 1;
	}
	return SendClientMessage(playerid, Col_Red, "You are not a dealer class.");
}
COMMAND:uncuff(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot uncuff players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /uncuff [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "Player is in a vehicle.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	if (!pInfo[target][cuffed]) return SendClientMessage(playerid, Col_Red, "Player is not cuffed.");
	new pname[MAX_PLAYER_NAME], formatted[128];
	pInfo[target][cuffed] = false;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have been uncuffed by %s.", pname);
	SendClientMessage(target, Col_Pink, formatted);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have uncuffed %s.", pname);
	SendClientMessage(playerid, Col_Pink, formatted);
	if(IsPlayerAttachedObjectSlotUsed(target, 8)) RemovePlayerAttachedObject(target, 8);
    SetPlayerSpecialAction(target, SPECIAL_ACTION_NONE);
	KillTimer(pInfo[target][CuffTimer]);
	return 1;
}
COMMAND:pm(playerid, params[])
{
	new pm[128], formatted[128], pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME], target;
	if (sscanf(params, "is[128]", target, pm)) return SendClientMessage(playerid, Col_Red, "USAGE: /pm [id] [message]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pInfo[target][pmon] == false) return SendClientMessage(playerid, Col_LightOrange, "Player does not accept private messages.");
	if (pInfo[playerid][pmon] == false) SendClientMessage(playerid, Col_LightOrange, "WARNING: You do not accept private messages.");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "PM from %s(%d): %s", pname, playerid, pm);
	SendClientMessage(target, Col_Yellow, formatted);
	GetPlayerName(target, pname2, MAX_PLAYER_NAME);
	format(formatted, 128, "PM to %s(%d): %s", pname2, target, pm);
	SendClientMessage(playerid, Col_Yellow, formatted);
	pInfo[target][LastPM] = playerid;
	format(formatted, 128, "%s(%d) -> %s(%d): %s", pname, playerid, pname2, target, pm);
	SendPMToAdmins(formatted);
	return 1;
}
COMMAND:offer(playerid, params[])
{
	if (pInfo[playerid][Class] == cWeaponDeal){
		if (pInfo[playerid][WeaponStacks] == 0) return SendClientMessage(playerid, Col_Red, "You don't have any weapons to sell. Buy some stacks in Ammunation.");
		if (pInfo[playerid][DealingCD] > gettime()) return SendClientMessage(playerid, Col_Red, "Please wait before selling more weapons.");
		new target, Float:pX, Float:pY, Float:pZ;
		if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /offer [id]");
		if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
		if (target == playerid) return SendClientMessage(playerid, Col_Red, "Unfortunately, your split personality has rejected the offer.");
		if (pInfo[target][Class] == cWeaponDeal) return SendClientMessage(playerid, Col_Red, "Weapon dealers cannot offer weapons to other dealers.");
		if (GetPVarInt(playerid, "active punish") == 1 || GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "You or Target player is in jail.");
		GetPlayerPos(playerid, pX, pY, pZ);
		if (GetPlayerDistanceFromPoint(target, pX, pY, pZ) > 15) return SendClientMessage(playerid, Col_Red, "You are too far away!");
		if (pInfo[target][needweapons]){
			SendClientMessage(playerid, Col_Pink, "You have sold weapons to the client and received $12,000 + 2 score.");
			pInfo[playerid][Money] += 12000;
			pInfo[playerid][sWeaponDeals]++;
			SetPlayerScore(playerid, GetPlayerScore(playerid) + 2);
			ShowMenuForPlayer(MenuIDs[mWeaponDeals], target);
			TogglePlayerControllable(target, 0);
			pInfo[playerid][DealingCD] = gettime() + 30;
			pInfo[playerid][WeaponStacks]--;
			pInfo[target][needweapons] = false;
		}else{
			SendClientMessage(playerid, Col_Pink, "You have offered the client to buy weapons.");
			new pname[MAX_PLAYER_NAME], formatted[128];
			GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
			format(formatted, 128, "%s has offered you to buy weapons. /weapons to agree.", pname);
			SendClientMessage(target, Col_Pink, formatted);
		}
		return 1;
	}else if (pInfo[playerid][Class] == cDrugDeal){
		if (pInfo[playerid][Drugs] == 0) return SendClientMessage(playerid, Col_Red, "You don't have any drugs to sell. Buy some in the drug house.");
		if (pInfo[playerid][DealingCD] > gettime()) return SendClientMessage(playerid, Col_Red, "Please wait before selling more drugs.");
		new target, price, Float:pX, Float:pY, Float:pZ, pname[MAX_PLAYER_NAME], formatted[148];
		if (sscanf(params, "ii", target, price)) return SendClientMessage(playerid, Col_Red, "USAGE: /offer [id] [price]");
		if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
		if (target == playerid) return SendClientMessage(playerid, Col_Red, "Unfortunately, your split personality has rejected the offer.");
		if (pInfo[target][Class] == cCop) return SendClientMessage(playerid, Col_Red, "You can't sell drugs to a police officer.");
		if (GetPVarInt(playerid, "active punish") == 1 || GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "You or Target player is in jail.");
		GetPlayerPos(playerid, pX, pY, pZ);
		if (GetPlayerDistanceFromPoint(target, pX, pY, pZ) > 15) return SendClientMessage(playerid, Col_Red, "You are too far away!");
		if (pInfo[target][Class] == cDrugDeal) return SendClientMessage(playerid, Col_Red, "Drug dealers cannot offer drugs to other dealers.");
		if (pInfo[target][needdrugs]){
			pInfo[playerid][DealingCD] = gettime() + 30;
			pInfo[target][needdrugs] = false;
			GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
			format(formatted, 148, "%s(%d) is selling you drugs for $%d per gram for a max of %d grams.\n Please type the amount of drugs below.", pname, playerid, price, pInfo[playerid][Drugs]);
			pInfo[target][DealingPrice] = price;
			pInfo[target][DealerID] = playerid;
			ShowPlayerDialog(target, dofferdrugs, DIALOG_STYLE_INPUT, "Buy drugs", formatted, "Buy", "Cancel");
		}else{
			SendClientMessage(playerid, Col_Pink, "You have offered the client to buy drugs.");
			GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
			format(formatted, 148, "%s has offered you to buy drugs for $%d per gram. /drugs to agree.", pname, price);
			SendClientMessage(target, Col_Pink, formatted);
		}
		return 1;
	}
	return SendClientMessage(playerid, Col_Red, "You are not playing a dealer class.");
}
COMMAND:weapons(playerid)
{
	if (pInfo[playerid][Class] == cWeaponDeal) return SendClientMessage(playerid, Col_Red, "Weapon dealers cannot buy weapons from other dealers.");
	pInfo[playerid][needweapons] = true;
	new dealers, formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) has called for a weapon dealer.", pname, playerid);
	foreach (new i : Player)
	{
		if (pInfo[i][Class] == cWeaponDeal) SendClientMessage(i, Col_LightOrange, formatted), dealers++;
	}
	if (dealers == 0) return SendClientMessage(playerid, Col_Red, "No weapon dealers online.");
	SendClientMessage(playerid, Col_LightOrange, "You have called for a weapon dealer.");
	return 1;
}
COMMAND:drugs(playerid)
{
	if (pInfo[playerid][Class] == cDrugDeal) return SendClientMessage(playerid, Col_Red, "Drug dealers cannot buy drugs from other dealers.");
	if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Police Officers cannot buy drugs.");
	pInfo[playerid][needdrugs] = true;
	new dealers, formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) has called for a drug dealer.", pname, playerid);
	foreach (new i : Player)
	{
		if (pInfo[i][Class] == cDrugDeal) SendClientMessage(i, Col_LightOrange, formatted), dealers++;
	}
	if (dealers == 0) return SendClientMessage(playerid, Col_Red, "No drug dealers online.");
	SendClientMessage(playerid, Col_LightOrange, "You have called for a drug dealer.");
	return 1;
}
COMMAND:city(playerid)
{
	gPlayerHasCitySelected[playerid] = 0;
	ForceClassSelection(playerid);
	SendClientMessage(playerid, Col_Green, "You will change city upon respawn.");
	return 1;
}
COMMAND:gc(playerid, params[])
{
	new target, amount, formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "ii", target, amount)) return SendClientMessage(playerid, Col_Red, "USAGE: /gc [id] [amount]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pInfo[playerid][Money] < amount) return SendClientMessage(playerid, Col_Red, "You do not own enough money.");
	if (amount <= 0) return SendClientMessage(playerid, Col_Red, "You cannot give players a negative amount of money.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have given %s %d$.", pname, amount);
	SendClientMessage(playerid, Col_Pink, formatted);
	pInfo[playerid][Money] -= amount;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s has given you %d$.", pname, amount);
	SendClientMessage(target, Col_Pink, formatted);
	pInfo[target][Money] += amount;
	return 1;
}
COMMAND:r(playerid, params[])
{
	new pm[128], formatted[128], pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME];
	if (sscanf(params, "s[128]", pm)) return SendClientMessage(playerid, Col_Red, "USAGE: /r [message]");
	if (!IsPlayerConnected(pInfo[playerid][LastPM])) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pInfo[pInfo[playerid][LastPM]][pmon] == false) return SendClientMessage(playerid, Col_LightOrange, "Player does not accept private messages.");
	if (pInfo[playerid][pmon] == false) SendClientMessage(playerid, Col_LightOrange, "WARNING: You do not accept private messages.");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "PM from %s(%d): %s", pname, playerid, pm);
	SendClientMessage(pInfo[playerid][LastPM], Col_Yellow, formatted);
	GetPlayerName(pInfo[playerid][LastPM], pname2, MAX_PLAYER_NAME);
	format(formatted, 128, "Reply to %s(%d): %s", pname2, pInfo[playerid][LastPM], pm);
	SendClientMessage(playerid, Col_Yellow, formatted);
	format(formatted, 128, "%s(%d) -> %s(%d): %s", pname, playerid, pname2, pInfo[playerid][LastPM], pm);
	SendPMToAdmins(formatted);
	pInfo[pInfo[playerid][LastPM]][LastPM] = playerid;
	return 1;
}
COMMAND:exith(playerid)
{
	if (pInfo[playerid][CurrentHouse] == -1) return SendClientMessage(playerid, Col_Red, "You are not inside a house.");
	SGPlayerPos(playerid, 0);
	SendClientMessage(playerid, Col_LightOrange, "You have left the house.");
	pInfo[playerid][CurrentHouse] = -1;
	return 1;
}
COMMAND:lock(playerid)
{
	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, Col_Red, "You are not a driver of a vehicle.");
	new engine, lights, alarm, doors, bonnet, boot, objective, pname[MAX_PLAYER_NAME];
	if (vInfo[pInfo[playerid][CurrentVeh]][OwnGroup] == gPlayer){
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		if (strcmp(pname, vOwnerName[pInfo[playerid][CurrentVeh]], true) != 0) return SendClientMessage(playerid, Col_Red, "You cannot lock a vehicle which isn't yours.");
	}
	GetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, 1, bonnet, boot, objective);
	SendClientMessage(playerid, Col_Yellow, "Vehicle locked!");
	PlayerPlaySound(playerid, 5201, 0, 0, 0);
	return 1;
}
COMMAND:eject(playerid, params[])
{
	if (GetPlayerVehicleSeat(playerid) != 0) return SendClientMessage(playerid, Col_Red, "You are not a driver of a vehicle.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /eject [playerid]");
	if (!IsPlayerInVehicle(target, GetPlayerVehicleID(playerid))) return SendClientMessage(playerid, Col_Red, "The player is not in your vehicle.");
	RemovePlayerFromVehicle(target);
	GameTextForPlayer(target, "Ejected", 1600, 6);
	SendClientMessage(playerid, Col_Pink, "Player ejected.");
	return 1;
}
COMMAND:unlock(playerid)
{
	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, Col_Red, "You are not a driver of a vehicle");
	new engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, 0, bonnet, boot, objective);
	SendClientMessage(playerid, Col_Yellow, "Vehicle unlocked!");
	PlayerPlaySound(playerid, 5201, 0, 0, 0);
	return 1;
}
COMMAND:escape(playerid)
{
	if(GetPVarInt(playerid, "active punish") == 1 && pInfo[playerid][JailTime] < 2) return SendClientMessage(playerid, Col_Red, "You cannot escape from admin jail.");
	if(pInfo[playerid][JailTime] <= 1) return SendClientMessage(playerid, Col_Red, "You are not in jail.");
	if(pInfo[playerid][triedescaping]) return SendClientMessage(playerid, Col_Red, "You have already tried escaping once.");
	if(pInfo[playerid][JailTime] > 60) return SendClientMessage(playerid, Col_Red, "Please wait a little before you try to escape (when 60 seconds are left).");
	if(random(10)<7) {
		pInfo[playerid][JailTime] = -2;
		CommitedCrime(playerid, 15);
	}
	else{
		new formatted[128], pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s has failed to escape from jail. Jail time extended.", pname);
		SendClientMessageToAll(Col_LightOrange, formatted);
		pInfo[playerid][JailTime] += 40;
		pInfo[playerid][triedescaping] = true;
	}
	return 1;
}
COMMAND:rape(playerid, params[])
{
	if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rape players.");
	if (pInfo[playerid][RapeUsage] > gettime()) return SendClientMessage(playerid, Col_Red, "Command used recently.");
	if (GetPVarInt(playerid, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "You are jailed or frozen.");
	new target, pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /rape [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (target == playerid) return SendClientMessage(playerid, Col_Red, "You cannot rape yourself.");
	if (pInfo[target][LastRaped] > gettime()) return SendClientMessage(playerid, Col_Red, "Player has been raped recently.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "Player is in a vehicle.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	if (pInfo[target][cuffed] || pInfo[playerid][cuffed]) return SendClientMessage(playerid, Col_Red, "You or target player is cuffed.");
	pInfo[playerid][RapeUsage] = gettime() + 10;
	if (!pInfo[target][alive]){
		GetPlayerName(target, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "You have raped %s's corpse.", pname, target);
		SendClientMessage(playerid, Col_Pink, formatted);
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) has raped your corpse. eeeew!", pname, playerid);
		SendClientMessage(target, Col_Pink, formatted);
		return 1;
	}
	if (!pInfo[target][raped]){
		pInfo[target][raped] = true;
		pInfo[target][RapeTimer] = SetTimerEx("RapeCheck", 2460, true, "i", target);
	}
	CommitedCrime(playerid, 3);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have raped %s(%d) and infected him with a sex disease.", pname, target);
	SendClientMessage(playerid, Col_Pink, formatted);
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have been raped by %s(%d) and infected with a sex disease. Run to the hospital to recover!", pname, playerid);
	pInfo[target][LastRaped] = gettime()+30;
	SendClientMessage(target, Col_Pink, formatted);
	pInfo[playerid][sRapes]++;
	SetPlayerScore(playerid, GetPlayerScore(playerid) + 1);
	return 1;
}
COMMAND:td(playerid, params[])
{
	if (pInfo[playerid][Drugs] == 0) return SendClientMessage(playerid, Col_Red, "You do not posses any drugs.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	new amount, formatted[128];
	if (sscanf(params, "i", amount)) return SendClientMessage(playerid, Col_Red, "USAGE: /td [amount]");
	if (amount > pInfo[playerid][Drugs]) return SendClientMessage(playerid, Col_Red, "You do not have enough drugs!");
	if (amount > 25) return SendClientMessage(playerid, Col_Red, "You may only take up to 25 grams of drugs.");
	if (pInfo[playerid][DrugTime] > 0) return SendClientMessage(playerid, Col_Red, "You are already on the effect of drugs.");
	if (amount <= 0) return SendClientMessage(playerid, Col_Red, "Haha, nice try...");
	pInfo[playerid][Drugs] -= amount;
	pInfo[playerid][DrugAmount] = amount;
	format(formatted, 128, "You have taken %d grams of drugs and be healed over time. You have %d grams left.", amount, pInfo[playerid][Drugs]);
	SendClientMessage(playerid, Col_Pink, formatted);
	pInfo[playerid][DrugTime] = 25;
	pInfo[playerid][DrugTimer] = SetTimerEx("DrugCheck", 1400, true, "i", playerid);
	return 1;
}
COMMAND:rob(playerid, params[])
{
	if (pInfo[playerid][Class] == cCop) return SendClientMessage(playerid, Col_Red, "Law enforcement officers cannot rob players.");
	if (pInfo[playerid][RobUsage] > gettime()) return SendClientMessage(playerid, Col_Red, "Command used recently.");
	if (GetPVarInt(playerid, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "You are jailed or frozen.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /rob [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (target == playerid) return SendClientMessage(playerid, Col_Red, "You cannot rob yourself.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "You or target player is in a vehicle.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (pInfo[target][Robbed] > gettime()) return SendClientMessage(playerid, Col_Red, "Player has been robbed recently.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	if (pInfo[target][cuffed] || pInfo[playerid][cuffed]) return SendClientMessage(playerid, Col_Red, "You or target player is cuffed.");
	if (pInfo[target][Money] < 2000) return SendClientMessage(playerid, Col_Red, "Player doesn't have much money.");
	pInfo[playerid][RobUsage] = gettime()+10;
	pInfo[target][Robbed] = gettime()+30;
	new formatted[128], pname[MAX_PLAYER_NAME], robamount = random(pInfo[target][Money]);
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (pInfo[target][WalletsLeft] > 0){
		pInfo[target][WalletsLeft]--;
		CommitedCrime(playerid, 1);
		SendClientMessage(playerid, Col_Pink, "You have tried robbing, but the player had a wallet. Better luck next time.");
		format(formatted, 128, "%s(%d) has tried robbing you, but you had a wallet. You now have %d wallets left.", pname, playerid, pInfo[target][WalletsLeft]);
		SendClientMessage(target, Col_Pink, formatted);
		return 1;
	}
	format(formatted, 128, "Robbed by %s(%d)~n~%d$", pname, playerid, robamount);
	GameTextForPlayer(target, formatted, 1500, 6);
	format(formatted, 128, "Robbed by %s(%d) for %d$.", pname, playerid, robamount);
	SendClientMessage(target, Col_Pink, formatted);
	pInfo[playerid][Money] += robamount;
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "Robbed %s(%d)~n~%d$", pname, target, robamount);
	GameTextForPlayer(playerid, formatted, 1500, 6);
	format(formatted, 128, "Robbed %s(%d) for %d$.", pname, target, robamount);
	SendClientMessage(playerid, Col_Pink, formatted);
	pInfo[target][Money] -= robamount;
	CommitedCrime(playerid, 3);
	SetPlayerScore(playerid, GetPlayerScore(playerid)+1);
	pInfo[playerid][sRobs]++;
	return 1;
}
COMMAND:cm(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "You are not a police officer.");
	new formatted[128], msg[101], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "s[128]", msg)) return SendClientMessage(playerid, Col_Red, "USAGE: /cm [message]");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "*CM* %s(%d): {FFFFFF}%s", pname, playerid, msg);
	SendToCops(formatted, 0x163fe1ff);
	return 1;
}
COMMAND:ar(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot arrest players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /ar [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (!pInfo[target][cuffed]) return SendClientMessage(playerid, Col_Red, "Player is not cuffed. You must cuff him before arresting.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "You or target player is in a vehicle.");
	if (GetPlayerWantedLevel(target)<2) return SendClientMessage(playerid, Col_Red, "Player is innocent!");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	new bonus;
	bonus = (GetPlayerWantedLevel(target)<10) ? 12000 : 21000;
	if (bonus == 12000) SendClientMessage(playerid, Col_Pink, "You have arrested a wanted criminal and recieved a 12000$ bonus + 2 score!");
	else SendClientMessage(playerid, Col_Pink, "You have arrested a most wanted criminal and recieved a 21000$ bonus + 2 score!");
	pInfo[playerid][Money] += bonus;
	SetPlayerScore(playerid, GetPlayerScore(playerid)+1);
	pInfo[target][cuffed] = false;
	KillTimer(pInfo[target][CuffTimer]);
	if(IsPlayerAttachedObjectSlotUsed(target, 8)) RemovePlayerAttachedObject(target, 8);
    SetPlayerSpecialAction(target, SPECIAL_ACTION_NONE);
	TogglePlayerControllable(target, 1);
	pInfo[playerid][sArrests]++;
	SetPlayerScore(playerid, GetPlayerScore(playerid) + 2);
	jailplayer(target, playerid);
	return 1;
}
COMMAND:adseepms(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	pInfo[playerid][adseepm] && (pInfo[playerid][adseepm] = false, SendClientMessage(playerid, Col_Red, "You can no longer see other PMs.")) || (pInfo[playerid][adseepm] = true, SendClientMessage(playerid, Col_Green, "You can now see other PMs."));
	return 1;
}
COMMAND:addeleteacc(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid)) return 0;
	SendClientMessage(playerid, Col_Green, "Account deleted. Note: Next command or chat will kick you out.");
	new pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	fremove(Path(playerid));
	pInfo[playerid][login] = false;
	return 1;
}
COMMAND:adinfo(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	new target, pIP[16], formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adinfo [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerIp(target, pIP, 16);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	SendClientMessage(playerid, Col_Pink, "Player Info:");
	format(formatted, 128, "Name: %s", pname);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "ID: %d", target);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "IP: %s", pIP);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "Money: %d", pInfo[target][Money]);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "Bank Money: %d", pInfo[target][BankMoney]);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "Drugs carrying: %d (%s)", pInfo[target][Drugs], (pInfo[target][DrugTime] > 0) ? ("Active") : ("Not active"));
	SendClientMessage(playerid, Col_Pink, formatted);
	CallRemoteFunction("PrintWarns", "ii", playerid, target);
	return 1;
}
COMMAND:adcash(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, amount, formatted[128];
	if(sscanf(params, "ii", target, amount)) return SendClientMessage(playerid, Col_Red, "USAGE: /adcash [ID] [Amount]");
	if (!IsPlayerConnected(target) && target != -1) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (amount > 9999999) return SendClientMessage(playerid, Col_Red, "What are you planning to do with all that amount?");
	if ((pInfo[target][Money] + amount) > 9999999 || (pInfo[target][Money] + amount) < -9999999) return SendClientMessage(playerid, Col_Red, "Are you trying to overflow the server?");
	if (target == -1) pInfo[playerid][Money] += amount;
	else {
		pInfo[target][Money] += amount;
		format(formatted, 128, "You have been given $%d by an admin.", amount);
		SendClientMessage(target, Col_Green, formatted);
	}
	format(formatted, 128, "Player has been given $%d.", amount);
	SendClientMessage(playerid, Col_Green, formatted);
	return 1;
}
COMMAND:bc(playerid)
{
	if (!pInfo[playerid][cuffed]) return SendClientMessage(playerid, Col_Red, "You are not cuffed.");
	if (pInfo[playerid][BCuffsTime] > gettime()) return SendClientMessage(playerid, Col_Red, "Please wait a little before you try to break them.");
	pInfo[playerid][BCuffsTime] = gettime() + 5;
	if (random(3) < 2){
		CommitedCrime(playerid, 1);
		return SendClientMessage(playerid, Col_Orange, "You have failed to break the cuffs.");
	}
	CommitedCrime(playerid, 2);
	SendClientMessage(playerid, Col_Pink, "You have broken the cuffs!");
	pInfo[playerid][cuffed] = false;
	if(IsPlayerAttachedObjectSlotUsed(playerid, 8)) RemovePlayerAttachedObject(playerid, 8);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}
COMMAND:loc(playerid, params[])
{
	new target, zone[MAX_ZONE_NAME], formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /loc [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (GetPlayerInterior(target) != 0 || GetPlayerState(target) == PLAYER_STATE_SPECTATING) {
		GetManualZone(pInfo[target][LastX], pInfo[target][LastY], zone, MAX_ZONE_NAME);
		format(formatted, 128, "Player is in an interior - %s", zone);
		
	}else{
		GetPlayer2DZone(target, zone, MAX_ZONE_NAME);
		format(formatted, 128, "Player is located in: %s.", zone);
	}
	SendClientMessage(playerid, Col_Pink, formatted);
	return 1;
}
COMMAND:taze(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot taze players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /taze [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (IsPlayerInAnyVehicle(playerid) || IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, Col_Red, "Player is in a vehicle.");
	if (pInfo[playerid][TazeTime] >= gettime()) return SendClientMessage(playerid, Col_Red, "Command used recently.");
	if (GetPlayerWantedLevel(target)<2) return SendClientMessage(playerid, Col_Red, "Player is innocent!");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 12.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	new pname[MAX_PLAYER_NAME], formatted[128];
	pInfo[target][tazed] = true;
	pInfo[playerid][TazeTime] = gettime()+3;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have been tazed by %s(%d).", pname, playerid);
	SendClientMessage(target, Col_LightOrange, formatted);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "You have tazed %s(%d).", pname, target);
	SendClientMessage(playerid, Col_LightOrange, formatted);
	TogglePlayerControllable(target, 0);
	SetTimerEx("restoretaze", 1000, false, "i", target);
	return 1;
}
COMMAND:fine(playerid, params[]){
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot fine players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /fine [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (GetPlayerWantedLevel(target)!=1) return SendClientMessage(playerid, Col_Red, "Player is not low-wanted. You can only fine low-wanted players.");
	if (!pInfo[playerid][alive]) return SendClientMessage(playerid, Col_Red, "You are dead.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 15.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (GetPVarInt(target, "active punish") == 1) return SendClientMessage(playerid, Col_Red, "Player is jailed or frozen.");
	SendClientMessage(playerid, Col_Pink, "You have fined a player and recieved a 5000$ bonus!");
	SetPlayerScore(playerid, GetPlayerScore(playerid)+1);
	pInfo[playerid][Money] += 5000;
	pInfo[target][Money] -= 5000;
	SendClientMessage(target, Col_Pink, "You have been fined for 5000$.");
	SetPlayerOCT(target);
	return 1;
}
COMMAND:pmon(playerid)
{
	pInfo[playerid][pmon] = true;
	SendClientMessage(playerid, Col_Green, "You are now accepting private messages.");
	return 1;
}
COMMAND:pmoff(playerid)
{
	pInfo[playerid][pmon] = false;
	SendClientMessage(playerid, Col_Red, "You are no longer accepting private messages.");
	return 1;
}
COMMAND:search(playerid, params[])
{
	if (pInfo[playerid][Class] != cCop) return SendClientMessage(playerid, Col_Red, "Robbers cannot search players.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /search [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pInfo[target][Class] == cCop) return SendClientMessage(playerid, Col_Red, "You cannot search law enforcement officers.");
	if (IsPlayerInRangeOfPlayer(playerid, target, 5.0) == 0) return SendClientMessage(playerid, Col_Red, "You are too far away.");
	if (pInfo[target][Drugs] == 0 || (pInfo[target][Drugs] <= 20 && pInfo[target][drugbag] == true)){
		SendClientMessage(playerid, Col_Pink, "You didn't manage to find any drugs.");
		if (pInfo[target][Drugs] == 0) SendClientMessage(target, Col_Pink, "You have been searched but you don't have any drugs.");
		else SendClientMessage(target, Col_Pink, "You have been searched but you have a drug bag. The drugs were not found.");
	}else{
		new formatted[128];
		format(formatted, 128, "You have found %d grams of drugs! Receive a $10,000 bonus!", pInfo[target][Drugs]);
		SendClientMessage(playerid, Col_Pink, formatted);
		CommitedCrime(target, 3);
		SendClientMessage(target, Col_Pink, "You have been searched and the officer has found your drugs!");
		pInfo[playerid][Money] += 10000;
		pInfo[target][Drugs] = 0;
	}
	return 1;
}
COMMAND:color(playerid, params[])
{
	if (!pInfo[playerid][CurrentVeh]) return SendClientMessage(playerid, Col_Red, "You are not inside a vehicle.");
	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, Col_Red, "You are not the driver of a vehicle.");
	new pname[MAX_PLAYER_NAME], color1, color2;
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (vInfo[pInfo[playerid][CurrentVeh]][OwnGroup] != gPlayer || strcmp(vOwnerName[pInfo[playerid][CurrentVeh]], pname, true)) return SendClientMessage(playerid, Col_Red, "This is not your private vehicle.");
	if (sscanf(params, "ii", color1, color2)) return SendClientMessage(playerid, Col_Red, "USAGE: /color [color 1] [color 2]");
	ChangeVehicleColor(pInfo[playerid][CurrentVeh], color1, color2);
	SendClientMessage(playerid, Col_Green, "You have sprayed your vehicle with a different color.");
	return 1;
}
COMMAND:adwanted(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, amount;
	if (sscanf(params, "I(-1)I(4)", target, amount)) return SendClientMessage(playerid, Col_Red, "USAGE: /adwanted [playerid - def self] [stars - def 4]");
	if (!IsPlayerConnected(target) && target != -1) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	CommitedCrime(target == -1 ? playerid : target, amount);
	SendClientMessage(playerid, Col_Green, "Wanted level added.");
	return 1;
}
COMMAND:adspawnv(playerid, params[]) //Vehicle Spawner
{
	if(GetPVarInt(playerid, "Admin") < 3) return 0;
	new Vehicle[32], VehicleID = 0, ColorOne, ColorTwo ,Float:pX, Float:pY, Float:pZ, Float:pAngle, pname[MAX_PLAYER_NAME];
	if(sscanf(params, "s[32]D(1)D(1)", Vehicle, ColorOne, ColorTwo)) return SendClientMessage(playerid, Col_Red, "USAGE: /adspawnv [Vehiclename/Vehicleid] [Color 1 (optional)] [Color 2 (optional)]");
	if(!isNumeric(Vehicle)){
		for(new i = 0; i < 211; i++)
        {
			if ( strfind(VehicleNames[i], Vehicle, true) != -1 ){
            VehicleID = i + 400;
			
			}
        }
		if (VehicleID == 0) return SendClientMessage(playerid, Col_Red, "You have entered an invalid vehicle name.");
	} else {
		VehicleID=strval(Vehicle);
		if(VehicleID <400 || VehicleID > 611) return SendClientMessage(playerid, Col_Red, "You have entered an invalid vehicle ID.");
	}
	GetPlayerPos(playerid, pX, pY, pZ);
	GetPlayerFacingAngle(playerid, pAngle);
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (vInfo[pInfo[playerid][Spawnedv]][OwnGroup] == gAdmin && !strcmp(pname, vOwnerName[pInfo[playerid][Spawnedv]])) DestroyVehicle(pInfo[playerid][Spawnedv]);
	pInfo[playerid][Spawnedv] = CreateVehicle(VehicleID, pX, pY, pZ+2.0, pAngle, ColorOne, ColorTwo, -1);
	SetVehicleVirtualWorld(pInfo[playerid][Spawnedv], GetPlayerVirtualWorld(playerid));
	LinkVehicleToInterior(pInfo[playerid][Spawnedv], GetPlayerInterior(playerid));
	PutPlayerInVehicle(playerid, pInfo[playerid][Spawnedv], 0);
	strpack(vOwnerName[pInfo[playerid][Spawnedv]], pname);
	vInfo[pInfo[playerid][Spawnedv]][OwnGroup] = gAdmin;
	SendClientMessage(playerid, Col_Green, "You have succesfully spawned this vehicle.");
	CallRemoteFunction("RestoreFuel", "i", pInfo[playerid][Spawnedv]);
	return 1;
}
COMMAND:info(playerid)
{
	new formatted[128];
	SendClientMessage(playerid, Col_Pink, "Player Info:");
	format(formatted, 128, "Wanted level: %d", GetPlayerWantedLevel(playerid));
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "Drugs amount: %d (%s)", pInfo[playerid][Drugs], (pInfo[playerid][drugbag]) ? ("You own a drug bag") : ("You don't have a drug bag"));
	SendClientMessage(playerid, Col_Pink, formatted);
	switch (pInfo[playerid][WalletsLeft]){
		case 0: SendClientMessage(playerid, Col_Pink, "You do not have a wallet.");
		case 1: SendClientMessage(playerid, Col_Pink, "You own a wallet. (1 rob left)");
		case 2: SendClientMessage(playerid, Col_Pink, "You own a wallet. (2 robs left)");
		case 3: SendClientMessage(playerid, Col_Pink, "You own a wallet. (3 robs left)");
	}
	if (pInfo[playerid][Class] == cWeaponDeal) {
		format(formatted, 128, "You have %d weapon stacks.", pInfo[playerid][WeaponStacks]);
		SendClientMessage(playerid, Col_Pink, formatted);
	}
	return 1;
}
COMMAND:adspawnperm(playerid, params[]) //Vehicle Spawner
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new Vehicle[32], VehicleID = 0, ColorOne, ColorTwo ,Float:pX, Float:pY, Float:pZ, Float:pAngle;
	if(sscanf(params, "s[32]D(1)D(1)", Vehicle, ColorOne, ColorTwo)) return SendClientMessage(playerid, Col_Red, "USAGE: /adspawnperm [Vehiclename/Vehicleid] [Color 1 (optional)] [Color 2 (optional)]");
	if(Vehicle[2] > '9' || Vehicle[2] < '0'){
		for(new i = 0; i < 211; i++)
        {
			if ( strfind(VehicleNames[i], Vehicle, true) != -1 ){
            VehicleID = i + 400;
			
			}
        }
		if (VehicleID == 0) return SendClientMessage(playerid, Col_Red, "You have entered an invalid vehicle name.");
	} else {
		VehicleID=strval(Vehicle);
		if(VehicleID <400 || VehicleID > 611) return SendClientMessage(playerid, Col_Red, "You have entered an invalid vehicle ID.");
	}
	GetPlayerPos(playerid, pX, pY, pZ);
	GetPlayerFacingAngle(playerid, pAngle);
	VehicleID = CreateVehicle(VehicleID, pX, pY, pZ+2.0, pAngle, ColorOne, ColorTwo, -1);
	SetVehicleVirtualWorld(VehicleID, GetPlayerVirtualWorld(playerid));
	LinkVehicleToInterior(VehicleID, GetPlayerInterior(playerid));
	PutPlayerInVehicle(playerid, VehicleID, 0);
	SendClientMessage(playerid, Col_Green, "You succesfully spawned this vehicle.");
	CallRemoteFunction("RestoreFuel", "i", VehicleID);
	return 1;
}
COMMAND:stats(playerid)
{
	new formatted[258], formatted1[40], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted1, 40, "%s's stats:", pname);
	pInfo[playerid][sTimeSpent] += gettime() - pInfo[playerid][LoginTime];
	pInfo[playerid][LoginTime] = gettime();
	format(formatted, 228, "Arrests:\t\t%d\nRobs:\t\t%d\nRapes:\t\t%d\nWeapon Deals:\t%d\nDrug Deals:\t%d\nTime Spent:\t%d Days %d Hours %d Minutes", pInfo[playerid][sArrests], pInfo[playerid][sRobs], pInfo[playerid][sRapes], pInfo[playerid][sWeaponDeals], pInfo[playerid][sDrugDeals], floatround((pInfo[playerid][sTimeSpent]/86400),floatround_floor), floatround((pInfo[playerid][sTimeSpent]%86400)/3600,floatround_floor), floatround((pInfo[playerid][sTimeSpent]%3600)/60,floatround_floor));
	ShowPlayerDialog(playerid, dstats, DIALOG_STYLE_MSGBOX, formatted1, formatted, "Done", "");
	return 1;
}
COMMAND:addestroy(playerid, params[]){
	if(GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if (sscanf(params, "I(-1)", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /addestroy [VehicleID - def self]. See with /dl for VehicleID.");
	if (target == -1){
		if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, Col_Red, "You're not driving a vehicle, nor typed vehicle ID.");
		vInfo[GetPlayerVehicleID(playerid)][OwnGroup] = gNone;
		DestroyVehicle(GetPlayerVehicleID(playerid));
	}else if(IsValidVehicle(target)){
		vInfo[target][OwnGroup] = gNone;
		DestroyVehicle(target);
	}else{
		SendClientMessage(playerid, Col_Red, "Vehicle does not exist.");
	}
	SendClientMessage(playerid, Col_Green, "Vehicle destroyed.");
	return 1;
}
COMMAND:createh(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new tempmodel, Float:tempx, Float:tempy, Float:tempz, tempprice, tempID = -1, formatted[100];
	if (sscanf(params, "ii", tempprice, tempmodel)) return SendClientMessage(playerid, Col_Red, "USAGE: /createh [Price] [Design]");
	else if (tempmodel < 0 || tempmodel > 5) return SendClientMessage(playerid, Col_Red, "Wrong Design (0-5).");
	for(new i; i != MAX_HOUSES; i++){
		if (!fexist(hPath(i))){
			tempID = i;
			break;
		}
	}
	if (tempID == -1) return SendClientMessage(playerid, Col_Red, "Max houses built.");
	GetPlayerPos(playerid, tempx, tempy, tempz);
	format (formatted, 100, "House ID is: %d. Make sure to /createx in the exit.", tempID);
	SendClientMessage(playerid, Col_Green, formatted);
	new INI:file = INI_Open(hPath(tempID)); //will open their file
	INI_SetTag(file,"House Data");
	INI_WriteInt(file,"ID", tempID); //House ID
	/* House Pickups and Exits */
	INI_WriteFloat(file,"PickX", tempx);
	INI_WriteFloat(file,"PickY", tempy);
	INI_WriteFloat(file,"PickZ", tempz);
	INI_WriteInt(file,"Design", tempmodel);
	INI_WriteInt(file,"Price", tempprice);
	INI_WriteBool(file,"Owned", false);
	INI_WriteString(file,"Owner", "None");
	INI_Close(file);
	return 1;
}
COMMAND:createx(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new tempID, Float:tempx, Float:tempy, Float:tempz;
	if (sscanf(params, "i", tempID)) return SendClientMessage(playerid, Col_Red, "USAGE: /createx [HouseID]");
	if (!fexist(hPath(tempID))) return SendClientMessage(playerid, Col_Red, "Incorrect house ID.");
	SendClientMessage(playerid, Col_Green, "Finished creating house.");
	GetPlayerPos(playerid, tempx, tempy, tempz);
	new INI:file = INI_Open(hPath(tempID)); //will open their file
	INI_SetTag(file,"House Data");
	/* House Pickups and Exits */
	INI_WriteFloat(file,"ExitX", tempx);
	INI_WriteFloat(file,"ExitY", tempy);
	INI_WriteFloat(file,"ExitZ", tempz);
	INI_Close(file);
	INI_ParseFile(hPath(tempID),"loadhouses_%s", .bExtra = true, .extra = tempID);
	if (!hInfo[tempID][hPickup]){
		hInfo[tempID][hPickup] = CreateDynamicPickup(hInfo[tempID][owned] ? 1273 : 1272, 1, hInfo[tempID][hPickX], hInfo[tempID][hPickY], hInfo[tempID][hPickZ]);
		DynamicPickupModel[hInfo[tempID][hPickup]] = hInfo[tempID][owned] ? 1273 : 1272;
	}
	return 1;
}
COMMAND:deleteh(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new tempID;
	if (sscanf(params, "i", tempID)) return SendClientMessage(playerid, Col_Red, "USAGE: /deleteh [HouseID]");
	if (!fexist(hPath(tempID))) return SendClientMessage(playerid, Col_Red, "House doesn't exist.");
	fremove(hPath(tempID));
	if (hInfo[tempID][owned]) SendClientMessage(playerid, Col_Orange, "Warning: House was owned.");
	if(IsValidDynamicPickup(hInfo[tempID][hPickup])) DestroyDynamicPickup(hInfo[tempID][hPickup]);
	SendClientMessage(playerid, Col_Green, "House Destroyed.");
	hInfo[tempID][hID] = -1; //House ID
	hInfo[tempID][hPickX] = -1;
	hInfo[tempID][hPickY] = -1;
	hInfo[tempID][hPickZ] = -1;
	hInfo[tempID][hDesign] = -1;
	hInfo[tempID][hPrice] = -1;
	hInfo[tempID][owned] = false;
	hOwnerName[tempID] = "None";
	hInfo[tempID][hExitX] = -1;
	hInfo[tempID][hExitY] = -1;
	hInfo[tempID][hExitZ] = -1;
	return 1;
}
COMMAND:setowner(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new tempID, tempOwner[MAX_PLAYER_NAME];
	if (sscanf(params, "is[24]", tempID, tempOwner)) return SendClientMessage(playerid, Col_Red, "USAGE: /setowner [HouseID] [OwnerName]");
	if (!fexist(hPath(tempID))) return SendClientMessage(playerid, Col_Red, "Incorrect house ID.");
	hOwnerName[tempID] = tempOwner;
	SendClientMessage(playerid, Col_Green, "Owner Changed.");
	return 1;
}
COMMAND:jack(playerid) //To be continued.
{
	if(pInfo[playerid][Class] == cCarJack) return SendClientMessage(playerid, Col_Red, "You must be a car jacker in order to use this command");
	if (!IsPlayerInAnyVehicle(playerid) || vInfo[pInfo[playerid][CurrentVeh]][OwnGroup] != gPlayer) return SendClientMessage(playerid, Col_Red, "You are not inside an owned vehicle");
	return 1;
}
public OnPlayerText(playerid, text[]){
    new formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
    format(formatted, 128, "%s(%d): {FFFFFF}%s", pname, playerid, text);
    SendClientMessageToAll(GetPlayerColor(playerid), formatted);
	SetPlayerChatBubble(playerid, text, COLOR_WHITE, 10.0, 5000);
    return 0; // return 0 to prevent text from being sent twice
}
public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if (!success) SendClientMessage(playerid, Col_Red, "Unknown command, see /cmds for a list of available commands.");
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	new pname[MAX_PLAYER_NAME], formatted[128];
	pInfo[playerid][sTimeSpent] += gettime() - pInfo[playerid][LoginTime];
	KillTimer(pInfo[playerid][Timerid]);
	if (pInfo[playerid][raped]) KillTimer(pInfo[playerid][RapeTimer]);
	if (pInfo[playerid][cuffed]) pInfo[playerid][JailTime] = 340;
	if (pInfo[playerid][login]){ //To avoid saving unlogged user's data
		//Same as OnDialogResponse, we will save their stats inside of their user's account
		new INI:file = INI_Open(Path(playerid)); //will open their file
		INI_SetTag(file,"Player's Data");//We will set a tag inside of user's account called "Player's Data"
		INI_WriteInt(file,"AdminLevel", pInfo[playerid][Adminlevel]); //If you've set his/her admin level, then his/her admin level will be saved inside of his/her account
		INI_WriteInt(file,"VIPLevel",pInfo[playerid][VIPlevel]);//As explained above
		INI_WriteInt(file,"Money",pInfo[playerid][Money]);//We will save his money inside of his account
		INI_WriteInt(file,"BankMoney",pInfo[playerid][BankMoney]);//We will save his money inside of his account
		INI_WriteInt(file,"Scores",GetPlayerScore(playerid));//We will save his score inside of his account
		INI_WriteInt(file, "JailTime",pInfo[playerid][JailTime]); //To check for jail evade
		INI_WriteInt(file, "SpawnHouse",pInfo[playerid][SpawnHouse]);
		INI_WriteInt(file, "WeaponStacks",pInfo[playerid][WeaponStacks]);
		INI_WriteInt(file, "DailyLogin",pInfo[playerid][DailyLogin]);
		/* Load Vehicles */
		INI_WriteInt(file, "vModel1",pInfo[playerid][vModel1]);
		INI_WriteInt(file, "vID1",pInfo[playerid][vID1]);
		INI_WriteInt(file, "vModel2",pInfo[playerid][vModel2]);
		INI_WriteInt(file, "vID2",pInfo[playerid][vID2]);
		INI_WriteInt(file, "vModel3",pInfo[playerid][vModel3]);
		INI_WriteInt(file, "vID3",pInfo[playerid][vID3]);
		/* Save Stats */
		INI_WriteInt(file, "Arrests",pInfo[playerid][sArrests]);
		INI_WriteInt(file, "Robs",pInfo[playerid][sRobs]);
		INI_WriteInt(file, "Rapes",pInfo[playerid][sRapes]);
		INI_WriteInt(file, "WeaponDeal",pInfo[playerid][sWeaponDeals]);
		INI_WriteInt(file, "DrugDeal",pInfo[playerid][sDrugDeals]);
		INI_WriteInt(file, "TimeSpent",pInfo[playerid][sTimeSpent]);
		INI_Close(file);//Now after we've done saving their data, we now need to close the file
		GetPlayerName(playerid, pname, sizeof(pname));
		switch(reason)
		{
			case 0: format(formatted, 128, "%s has left the server. (Lost Connection)", pname);
			case 1: format(formatted, 128, "%s has left the server. (Leaving)", pname);
			case 2: format(formatted, 128, "%s has left the server. (Kicked)", pname);
		} 
		SendClientMessageToAll(Col_Gray, formatted);
		if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER){ //Unlock Disconnected Car
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(pInfo[playerid][CurrentVeh], engine, lights, alarm, 0, bonnet, boot, objective);
		}
		pInfo[playerid][login] = false;
	}
	pInfo[playerid][CurrentVeh] = 0;
	pInfo[playerid][JailTime] = 0;
	pInfo[playerid][RobTime] = -1;
	if (vInfo[pInfo[playerid][Spawnedv]][OwnGroup] == gAdmin && !strcmp(pname, vOwnerName[pInfo[playerid][Spawnedv]])) DestroyVehicle(pInfo[playerid][Spawnedv]);
	pInfo[playerid][Spawnedv] = 0;
	pInfo[playerid][alive]=false;
	pInfo[playerid][pmon] = true;
	pInfo[playerid][cuffed] = false;
	pInfo[playerid][disablepick] = false;
	pInfo[playerid][needweapons] = false;
	pInfo[playerid][needdrugs] = false;
	pInfo[playerid][needjail] = false;
	pInfo[playerid][adseepm] = false;
	pInfo[playerid][WeaponStacks] = 0;
	pInfo[playerid][CurrentHouse] = -1;
	pInfo[playerid][SpawnHouse] = -1;
	pInfo[playerid][DailyLogin] = 0;
	pInfo[playerid][Class] = cNone;
	pInfo[playerid][sTimeSpent] = 0;
	pInfo[playerid][LoginTime] = 0;
	pInfo[playerid][WalletsLeft] = 0;
	pInfo[playerid][HackCounter] = 0;
    return 1;
}
public RobbingStore(playerid, pickupid){
	if (pInfo[playerid][RobTime] == -1){ //Attempts to solve that stupid bug
		print("Robbing store BUGGED. Try shutting down server.");
		KillTimer(pInfo[playerid][Timerid]);
		return 0;
	}
	pInfo[playerid][RobTime]--;
	new formatted[128];
	if (GetPlayerInterior(playerid) == 0){
		KillTimer(pInfo[playerid][Timerid]);
		SendClientMessage(playerid, Col_Red, "You have left the building. Robbery cancelled.");
		return 0;
	}
	if (pInfo[playerid][JailTime] > 1){
		KillTimer(pInfo[playerid][Timerid]);
		return 0;
	}
	if (pInfo[playerid][RobTime] > 0){
		format(formatted, 128, "Robbing time left~n~%d", pInfo[playerid][RobTime]);
		GameTextForPlayer(playerid, formatted, 1300, 6);
		return 1;
	}
	KillTimer(pInfo[playerid][Timerid]);
	new amount, pname[MAX_PLAYER_NAME], StoreName[64];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if(pickupid == StorePickups[Cluck][0]){
		amount = random(5001)+3000;
		StoreName = "the cluckin' bell";
	}else if(pickupid == StorePickups[Pro][0]){
		amount = random(5001)+3000;
		StoreName = "pro laps";
	}else if(pickupid == StorePickups[Victim][0]){
		amount = random(5001)+3000;
		StoreName = "victim";
	}else if(pickupid == StorePickups[DS][0]){
		amount = random(5001)+3000;
		StoreName = "DS";
	}else if(pickupid == StorePickups[Saloon][0]){
		amount = random(5001)+3000;
		StoreName = "the saloon";
	}else if(pickupid == StorePickups[Pizza][0]){
		amount = random(5001)+3000;
		StoreName = "well stacked pizza";
	}else if(pickupid == StorePickups[Burger][0]){
		amount = random(5001)+3000;
		StoreName = "burgershot";
	}else if(pickupid == StorePickups[Tattoo][0]){
		amount = random(5001)+3000;
		StoreName = "the tattoo shop";
	}else if(pickupid == StorePickups[Hair][0]){
		amount = random(5001)+3000;
		StoreName = "the barber shop";
	}else if(pickupid == StorePickups[Gym][0]){
		amount = random(5001)+3000;
		StoreName = "the gym";
	}else if(pickupid == StorePickups[Binco][0]){
		amount = random(5001)+3000;
		StoreName = "binco";
	}else if(pickupid == StorePickups[Pig][0]){
		amount = random(5001)+3000;
		StoreName = "the pig pen";
	}else if(pickupid == StorePickups[Bar][0]){
		amount = random(5001)+3000;
		StoreName = "the bar";
	}else if(pickupid == StorePickups[Zip][0]){
		amount = random(5001)+3000;
		StoreName = "zip";
	}else if(pickupid == StorePickups[InsideTrack][0]){
		amount = random(5001)+3000;
		StoreName = "inside track";
	}
	format(formatted, 128, "You have successfully robbed %s for $%d.", StoreName, amount);
	SendClientMessage(playerid, Col_Pink, formatted);
	format(formatted, 128, "%s has robbed %s for $%d.", pname, StoreName, amount);
	SendClientMessageToAll(Col_Pink, formatted);
	pInfo[playerid][Money] += amount;
	SetPlayerScore(playerid, GetPlayerScore(playerid)+1);
	pInfo[playerid][sRobs]++;
	return 1;
}
public jailupdate(playerid){
	new formatted[128];
	if (pInfo[playerid][JailTime]>1) {
		pInfo[playerid][JailTime]--;
		format(formatted, 128, "Jail time left~n~%d", pInfo[playerid][JailTime]);
		GameTextForPlayer(playerid, formatted, 1300, 6);
		if(!pInfo[playerid][needjail] && GetPlayerInterior(playerid) == 0 && GetPVarInt(playerid, "Admin") < 1 && pInfo[playerid][HackCounter] != -1){
			if (pInfo[playerid][HackCounter] > 2){
				BanPlayer(-1, playerid, "teleportation hacks");
				pInfo[playerid][JailTime] = 0;
				return 0;
			}
			SetPlayerInterior(playerid, 6);
			SetPlayerPos(playerid,264.7426,77.7752,1001.0391);
			pInfo[playerid][HackCounter]++;
		}
		return 1;
	}else if (pInfo[playerid][JailTime] == 1){
		pInfo[playerid][JailTime]=0;
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) has been released from jail.", pname, playerid);
		SendClientMessageToAll(Col_LightOrange, formatted);
		SetPlayerInterior(playerid, 6);
		SetPlayerPos(playerid, 264.0510,82.0633,1001.0391);
		return 1;
	}else if (pInfo[playerid][JailTime] == -2){
		pInfo[playerid][JailTime]=0;
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) has escaped from jail!", pname, playerid);
		SendClientMessageToAll(Col_LightOrange, formatted);
		SetPlayerPos(playerid, 264.0510,82.0633,1001.0391);
		GameTextForPlayer(playerid, "ESCAPED", 1300, 6);
	}
	SetPVarInt(playerid, "active punish", 0);
	pInfo[playerid][triedescaping] = false;
	KillTimer(pInfo[playerid][JailTimer]);
	pInfo[playerid][HackCounter] = 0;
	return 1;
}
public restoretaze(playerid){
	if(GetPVarInt(playerid, "active punish") == 0) TogglePlayerControllable(playerid, 1);
	pInfo[playerid][tazed] = false;
	return 1;
}
public unjailp(playerid){
	if(pInfo[playerid][JailTime] <= 1) return 0;
	pInfo[playerid][JailTime] = 1;
	return 1;
}
public loadaccount_user(playerid, name[], value[])
{
    INI_String("Password", pInfo[playerid][Pass],129); /*we will use INI_String to load user's password.
    ("Password",.. will load user's password inside of user's path. 'pInfo[playerid][Pass]',...We have defined our user's variable above called, pInfo. Now it's time to use it here to load user's password. '129',... 129 is a length of a hashed user's password. Whirlpool will hash 128 characters + NULL*/
	INI_Bool("Passflag", pInfo[playerid][Passflag]);
    INI_Int("AdminLevel",pInfo[playerid][Adminlevel]);/*We will use INI_Int to load user's admin level. INI_Int stands for INI_Integer. This load an admin level. */
    INI_Int("VIPLevel",pInfo[playerid][VIPlevel]);//As explained above
    INI_Int("Money",pInfo[playerid][Money]); //As explained above
	INI_Int("BankMoney",pInfo[playerid][BankMoney]); //As explained above
    INI_Int("Scores",pInfo[playerid][Scores]);//As explained above
	INI_Int("JailTime",pInfo[playerid][JailTime]); //To check for jail evade
	INI_Int("SpawnHouse",pInfo[playerid][SpawnHouse]);
	INI_Int("WeaponStacks",pInfo[playerid][WeaponStacks]);
	INI_Int("DailyLogin",pInfo[playerid][DailyLogin]);
	/* Load Vehicles */
	INI_Int("vModel1",pInfo[playerid][vModel1]);
	INI_Int("vID1",pInfo[playerid][vID1]);
	INI_Int("vModel2",pInfo[playerid][vModel2]);
	INI_Int("vID2",pInfo[playerid][vID2]);
	INI_Int("vModel3",pInfo[playerid][vModel3]);
	INI_Int("vID3",pInfo[playerid][vID3]);
	/* Load Stats */
	INI_Int("Arrests",pInfo[playerid][sArrests]);
	INI_Int("Rapes",pInfo[playerid][sRapes]);
	INI_Int("Robs",pInfo[playerid][sRobs]);
	INI_Int("WeaponDeal",pInfo[playerid][sWeaponDeals]);
	INI_Int("DrugDeal",pInfo[playerid][sDrugDeals]);
	INI_Int("TimeSpent",pInfo[playerid][sTimeSpent]);
    return 1;
}
public loadhouses_house(houseid, name[], value[]) //load houses function
{
	INI_Int("ID", hInfo[houseid][hID]); //House ID
	/* House Pickups and Exits */
	INI_Float("PickX", hInfo[houseid][hPickX]);
	INI_Float("PickY", hInfo[houseid][hPickY]);
	INI_Float("PickZ", hInfo[houseid][hPickZ]);
	INI_Int("Design", hInfo[houseid][hDesign]);
	INI_Int("Price", hInfo[houseid][hPrice]);
	INI_Bool("Owned", hInfo[houseid][owned]);
	INI_String("Owner", hOwnerName[houseid], MAX_PLAYER_NAME);
	INI_Float("ExitX", hInfo[houseid][hExitX]);
	INI_Float("ExitY", hInfo[houseid][hExitY]);
	INI_Float("ExitZ", hInfo[houseid][hExitZ]);
	return 1;
}
public SetPlayerOCT(playerid)
{
	SetPlayerWantedLevel(playerid, 0);
	//if(pInfo[playerid][Class] == cHitman) SetPlayerTeam(2);
	//else SetPlayerTeam(1);
	SetPlayerTeam(playerid, 1);
	SetPlayerColor(playerid, cColors[pInfo[playerid][Class]]);
	return 1;
}
public LoadAllVehicles(){
	// SPECIAL
	total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/trains.txt");
	total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/pilots.txt");

   	// LAS VENTURAS
     total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/lv_gen.txt");
    
    // SAN FIERRO
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/sf_gen.txt");
    
    // LOS SANTOS
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_law.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_airport.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_gen_inner.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/ls_gen_outer.txt");
    
    // OTHER AREAS
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/whetstone.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/bone.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/flint.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/tierra.txt");
    total_vehicles_from_files += LoadStaticVehiclesFromFile("vehicles/red_county.txt");
	printf("Total vehicles from files: %d",total_vehicles_from_files);
	total_vehicles_from_files = 0;
	for(new i; i < MAX_VEHICLES; i++) vInfo[i][OwnGroup] = gNone;
	return 1;
}
public cuffexpire(playerid){
	if(!pInfo[playerid][cuffed]) return 0;
	SendClientMessage(playerid, Col_Pink, "20 seconds have passed. Your cuffs has been removed.");
	pInfo[playerid][cuffed] = false;
	if(IsPlayerAttachedObjectSlotUsed(playerid, 8)) RemovePlayerAttachedObject(playerid, 8);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}
public MoneyUpdate(){
	foreach (new i : Player){
		if(pInfo[i][Money] != GetPlayerMoney(i)) GivePlayerMoney(i, pInfo[i][Money] - GetPlayerMoney(i));
	}
	return 1;
}
public DrugCheck(playerid){
	if (pInfo[playerid][DrugTime] > 1){
		new Float:phealth;
		GetPlayerHealth(playerid, phealth);
		pInfo[playerid][DrugTime]--;
		if (phealth + 3 + 0.15*pInfo[playerid][DrugAmount] < 100) SetPlayerHealth(playerid, phealth + 3 + 0.15*pInfo[playerid][DrugAmount]);
		else SetPlayerHealth(playerid, 100);
		return 1;
	}else if (pInfo[playerid][DrugTime] == 1){
		new Float:phealth;
		GetPlayerHealth(playerid, phealth);
		pInfo[playerid][DrugTime]--;
		if (phealth + 3 + 0.15*pInfo[playerid][DrugAmount] < 100) SetPlayerHealth(playerid, phealth + 3 + 0.15*pInfo[playerid][DrugAmount]);
		else SetPlayerHealth(playerid, 100);
		SendClientMessage(playerid, Col_Pink, "Drugs effect is over.");
		return 1;
	}
	KillTimer(pInfo[playerid][DrugTimer]);
	return 1;
}
public RapeCheck(playerid)
{
	new Float:phealth;
	GetPlayerHealth(playerid, phealth);
	SetPlayerHealth(playerid, phealth - 2);
	return 1;
}
public SGPlayerPos(playerid, SetPosition){ //Set/Get Player Position
	if (SetPosition == 1){
		GetPlayerPos(playerid, pInfo[playerid][LastX],pInfo[playerid][LastY],pInfo[playerid][LastZ]);
		pInfo[playerid][LastInterior] = GetPlayerInterior(playerid);
	}else{
		if(IsPlayerInAnyVehicle(playerid)) SetVehiclePos(GetPlayerVehicleID(playerid), pInfo[playerid][LastX],pInfo[playerid][LastY],pInfo[playerid][LastZ]);
		else SetPlayerPos(playerid, pInfo[playerid][LastX],pInfo[playerid][LastY],pInfo[playerid][LastZ]);
		SetPlayerInterior(playerid, pInfo[playerid][LastInterior]);
	}
	return 1;
}
public ShowRules(playerid)
{
	new rulesstring[1286] = "1. Respect all players, Admins and Normal players as one.\n2. This is not a deathmatch server! Please avoid killing random people that did nothing to you.\n3. No hacking or cheating. Doing so will result in a permanent ban!\n4. No abusing! (No ESC abusing either) Found a bug or glitch? Tell an admin!";
	strcat(rulesstring, "\n5. No spamming or advertising in main chat. Spamming means writing the same message OVER 3 times.\n6. English only in main chat. For other languages use PM or whisper.\n");
	strcat(rulesstring, "7. Remember, you are not allowed to take revenge after death.\n8. No cop hunting. Do not shoot a cop if he didn't chase you.\n9. Continuous ramming counts as shooting! Ramming an innocent player is DMing!\n10. Asking to be promoted to admin, VIP, army or anything else will get ");
	strcat(rulesstring, "you blacklisted or banned.\n11. /q jokes are not allowed.\n12. Bitching or harrassing is not allowed - This is subjective to admin's decision.\n13. You are NOT allowed to /q immidiatley after robbing/raping someone or while being chased by cops.\n14.Cops are not allowed to team with robbers.");
	ShowPlayerDialog(playerid, drules, DIALOG_STYLE_MSGBOX, "Server Rules", rulesstring, "Next", "");
}
public AllowPick(playerid)
{
	pInfo[playerid][disablepick] = false;
}
public KickF(playerid)
{
	Kick(playerid);
	return true;
}
public AddHackCounter(playerid, counter) //-1 is special priv
{
	pInfo[playerid][HackCounter] += counter;
	return 1;
}
forward GetPMoney(playerid);
public GetPMoney(playerid) return pInfo[playerid][Money];
forward AddPMoney(playerid, amount);
public AddPMoney(playerid, amount) pInfo[playerid][Money] += amount;
forward SetADLevel(playerid, level);
public SetADLevel(playerid, level) pInfo[playerid][Adminlevel] = level;
