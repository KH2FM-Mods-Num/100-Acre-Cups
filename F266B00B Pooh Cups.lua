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

function Spawn(Type,Subfile,Offset,Value)
local Subpoint = ARD + 0x08 + 0x10*Subfile
local Address
--Detect errors
if ReadInt(ARD,OnPC) ~= 0x01524142 then --Header mismatch
	return
elseif Subfile > ReadInt(ARD+4,OnPC) then --Subfile over count
	return
elseif Offset >= ReadInt(Subpoint+4,OnPC) then --Offset exceed subfile length
	return
end
--Get address
if not OnPC then
	Address = ReadInt(Subpoint) + Offset
else
	local x = ARD&0xFFFFFF000000 --Calculations are wrong if done in one step for some reason
	local y = ReadInt(Subpoint,true)&0xFFFFFF
	Address = x + y + Offset
end
--Change value
if Type == 'Short' then
	WriteShort(Address,Value,OnPC)
elseif Type == 'Float' then
	WriteFloat(Address,Value,OnPC)
elseif Type == 'Int' then
	WriteInt(Address,Value,OnPC)
elseif Type == 'String' then
	WriteString(Address,Value,OnPC)
end
end

function _OnInit()
local VersionNum = 'GoA Version 1.53.2'
if (GAME_ID == 0xF266B00B or GAME_ID == 0xFAF99301) and ENGINE_TYPE == "ENGINE" then --PCSX2
	OnPC = false
	Now = 0x032BAE0 --Current Location
	Save = 0x032BB30 --Save File
	ARDLoad  = 0x034ECF4 --ARD Pointer Address
elseif GAME_ID == 0x431219CC and ENGINE_TYPE == 'BACKEND' then --PC
	OnPC = true
	Now = 0x0714DB8 - 0x56454E
	Save = 0x09A7070 - 0x56450E
	ARDLoad  = 0x2A0CEE8 - 0x56450E
end
CupFlags = {0x02,0x200,0x08,0x10,0x100}
FromPooh = false
end

function _OnFrame()
if ReadShort(Now) == 0x0906 and ReadShort(Now+0x30) == 0x0009 then --Warp back to 100AW from cups
	FromPooh = true
elseif FromPooh and (ReadShort(Now) == 0x0306 or ReadShort(Now) == 0x0606) then
	Warp(0x09,0x00,0x63,ReadShort(Save+0x0D90),ReadShort(Save+0x0D92),ReadShort(Save+0x0D94))
	FromPooh = false
elseif ReadShort(Now) == 0x0009 then --Remove triggers for locked cups
	if not OnPC then
		ARD = ReadInt(ARDLoad) --Base ARD Address
	else
		ARD = ReadLong(ARDLoad) --Base ARD Address
	end
	for i = 1,5 do
		CupFlag = CupFlags[i]
		if ReadShort(Save+0x239C) & CupFlag ~= CupFlag then
			Spawn('Short',0x1E,0x8+0x20*(i-1),0xA5+i)
		end
	end
end
end
