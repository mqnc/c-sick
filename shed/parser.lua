
grammar = [[
# Grammar for Calculator...
Additive    <- Multitive '+' Additive / Multitive
Multitive   <- Primary '*' Multitive / Primary
Primary     <- '(' Additive ')' / Number
Number      <- < [0-9]+ >
%whitespace <- [ \t]*
]]

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function generate(mtc, lin, col, chc, tok)
	print("match: ", mtc)
	print("line: ", lin)
	print("column: ", col)
	print("choice: ", chc)
	print(dump(tok))
	return "haha"
end