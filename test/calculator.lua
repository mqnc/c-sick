
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

function ProcessOpSequence(sequence)
	local res = sequence[1]
	for i = 3, #sequence, 2 do
		res = sequence[i - 1](res, sequence[i])
	end
	return res
end

function Add(params)
	return ProcessOpSequence(params.subnodes)
end

function DoAdd(lhs, rhs)
	return lhs + rhs
end

function DoSub(lhs, rhs)
	return lhs - rhs
end

function AddOp(params)
	if 0 == params.choice then
		return DoAdd
	else
		return DoSub
	end
end

function Mul(params)
	return ProcessOpSequence(params.subnodes)
end

function DoMul(lhs, rhs)
	return lhs * rhs
end

function DoDiv(lhs, rhs)
	return lhs / rhs
end

function MulOp(params)
	if 0 == params.choice then
		return DoMul
	else
		return DoDiv
	end
end

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

