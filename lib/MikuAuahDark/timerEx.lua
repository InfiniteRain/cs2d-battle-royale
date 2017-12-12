-- timerEx by MikuAuahDark

local __timerArg={}
local function timerEx(ms,func,count,...)
	count=count or 1
	if count==0 then count=-1 end
	local tmpfunc,id="",0
	for i=1,8 do
		local rand=math.random(0,2)
		if rand==0 then
			tmpfunc=tmpfunc..string.char(math.random(65,90))
		elseif rand==1 then
			tmpfunc=tmpfunc..string.char(math.random(97,112))
		else
			tmpfunc=tmpfunc..math.random(0,9)
		end
	end
	table.insert(__timerArg,{type(func),tmpfunc,func,{...},count})
	for n,v in pairs(__timerArg) do
		if v[2]==tmpfunc then
			id=n
			break
		end
	end
	_G[tmpfunc]=function(id)
		id=tonumber(id)
		if __timerArg[id][1]=="function" then
			__timerArg[id].r=__timerArg[id][3](unpack(__timerArg[id][4]))
		elseif __timerArg[id][1]=="string" or __timerArg[id][1]=="number" then
			__timerArg[id].r=loadstring("return "..__timerArg[id][3].."(unpack(__timerArg["..id.."][4]))")()
		end
		__timerArg[id][5]=__timerArg[id][5]-1
		if __timerArg[id][5]==0 then
			_G[__timerArg[id][2]]=nil
			__timerArg[id]=nil
		end
	end
	timer(ms,tmpfunc,id,count)
	return id
end

local function freetimerEx(id)
	if __timerArg[id]~=nil then
		freetimer(__timerArg[id][2],id)
		_G[__timerArg[id][2]]=nil
		__timerArg[id]=nil
		return true
	end
	return false
end

return
{
    new = timerEx,
    free = freetimerEx,
}
