function Warp(W,R,D,M,B,E) --Warp into the appropriate World, Room, Door, Map, Btl, Evt
WriteByte(Now+0x00,W)
WriteByte(Now+0x01,R)
WriteShort(Now+0x02,D)
WriteShort(Now+0x04,M)
WriteShort(Now+0x06,B)
WriteShort(Now+0x08,E)
--Record Location in Save File
WriteByte(Save+0x000C,W)
WriteByte(Save+0x000D,R)
WriteShort(Save+0x000E,D)
end

function BAR(File,Subfile,Offset) --Get address within a BAR file
local Subpoint = File + 0x08 + 0x10*Subfile
local Address
--Detect errors
if ReadInt(File,OnPC) ~= 0x01524142 then --Header mismatch
	return
elseif Subfile > ReadInt(File+4,OnPC) then --Subfile over count
	return
elseif Offset >= ReadInt(Subpoint+4,OnPC) then --Offset exceed subfile length
	return
end
--Get address
Address = File + (ReadInt(Subpoint,OnPC) - ReadInt(File+8,OnPC)) + Offset
return Address
end

function _OnInit()
GameVersion = 0
CupFlags = {0x02,0x200,0x08,0x10,0x100}
FromPooh = false
end

function GetVersion() --Define anchor addresses
if (GAME_ID == 0xF266B00B or GAME_ID == 0xFAF99301) and ENGINE_TYPE == "ENGINE" then --PCSX2
	OnPC = false
	GameVersion = 1
	Now = 0x032BAE0 --Current Location
	Save = 0x032BB30 --Save File
	ARDPointer  = 0x034ECF4 --ARD Pointer Address
elseif GAME_ID == 0x431219CC and ENGINE_TYPE == 'BACKEND' then --PC
	OnPC = true
	if ReadString(0x9A9330,4) == 'KH2J' then --EGS
		GameVersion = 2
		Now = 0x0716DF8
		Save = 0x09A9330
		ARDPointer = 0x2A0F2A8
	elseif ReadString(0x9A98B0,4) == 'KH2J' then --Steam Global
		GameVersion = 3
		Now = 0x0717008
		Save = 0x09A98B0
		ARDPointer = 0x2A0F828
	elseif ReadString(0x9A98B0,4) == 'KH2J' then --Steam JP (same as Global for now)
		GameVersion = 4
		Now = 0x0717008
		Save = 0x09A98B0
		ARDPointer = 0x2A0F828
	elseif ReadString(0x9A7070,4) == "KH2J" or ReadString(0x9A70B0,4) == "KH2J" or ReadString(0x9A92F0,4) == "KH2J" then
		GameVersion = -1
		print("Epic Version is outdated. Please update the game.")
	elseif ReadString(0x9A9830,4) == "KH2J" then
		GameVersion = -1
		print("Steam Global Version is outdated. Please update the game.")
	elseif ReadString(0x9A8830,4) == "KH2J" then
		GameVersion = -1
		print("Steam JP Version is outdated. Please update the game.")
	end
end
end

function _OnFrame()
if GameVersion == 0 then --Get anchor addresses
	GetVersion()
	return
elseif GameVersion < 0 then --Incompatible version
	return
end

local Place = ReadShort(Now)
if Place == 0x0906 and ReadShort(Now+0x30) == 0x0009 then --Record if going to cups from 100AW
	FromPooh = true
elseif FromPooh and (Place == 0x0306 or Place == 0x0606) then --Warp back to 100AW from cups
	Warp(0x09,0x00,0x63,ReadShort(Save+0x0D90),ReadShort(Save+0x0D92),ReadShort(Save+0x0D94))
	FromPooh = false
elseif Place == 0x0009 then --Remove event triggers for locked cups
	if not OnPC then
		ARD = ReadInt(ARDPointer)
	else
		ARD = ReadLong(ARDPointer)
	end
	for i = 1,5 do
		CupFlag = CupFlags[i]
		if ReadShort(Save+0x239C) & CupFlag ~= CupFlag then
			WriteShort(BAR(ARD,0x1E,0x8+0x20*(i-1)),0xA5+i,OnPC)
		end
	end
end
end
