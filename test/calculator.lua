
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

function default(params)
	print(stringify(params))
	return params.matched
end
