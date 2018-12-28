
--[[
t0 = os.clock()
asen = table.concat(a)
bsen = table.concat(b)

test1 = asen..bsen
print(os.clock() - t0)


t0 = os.clock()
test2 = ""
for _,v in ipairs(a) do
	test2 = test2 .. v
end
for _,v in ipairs(b) do
	test2 = test2 .. v
end
print(os.clock() - t0)


t0 = os.clock()
for _,v in ipairs(a) do
	table.insert(b, v)
end

test3 = table.concat(b)
print(os.clock() - t0)
]]


f = function(...)

	t0 = os.clock()
	for trial = 1,1000000 do
		for n=1,select('#',...) do
		  local e = select(n,...)
		end
	end
	print(os.clock() - t0)


	t0 = os.clock()
	for trial = 1,1000000 do
		for _, e in ipairs({...}) do
		   local e2 = e
		end
	end
	print(os.clock() - t0)


end

f(1,2,3,4,5,6,345,23,45,324,534,52,345,234,523,45)
