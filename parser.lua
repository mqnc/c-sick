
grammar = [==[

	Add <- (Mul AddOp)* Mul
	AddOp <- '+' / '-'
	Mul <- (Prim MulOp)* Prim
	MulOp <- '*' / '/'
	Prim <- '(' Add ')'
		 / Num
	Num <- < [0-9]+ >
	%whitespace <- [ \t]*

]==]

function Num(params)
	print("                          ", dump(params))
	return params.matched
end

function default(params)
	print("                          ", dump(params))
	return params.matched
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = ''..k..'' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

