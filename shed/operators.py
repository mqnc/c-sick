
print('''Expression <- List(AfterActionTerm, AfterActionOperator)

AfterActionOperator <- CustomOperator('after', 'action')
AfterActionTerm <- (ActionTerm _ '?' _ AfterActionTerm _ ':' _ AfterActionTerm) / ('throw' _ AfterActionTerm) / (CustomOperator('with', 'action') _ AfterActionTerm)
ActionTerm <- List(BeforeActionTerm, BeforeActionOperator)
BeforeActionOperator <- CustomOperator('before', 'action')''', end="")

def level(classname, operators, fix):

	print(" / CustomOperator('after', '" + classname.lower() + "')")
	print("Before" + classname + "Term <- InfixList(" + classname + "Term, " + classname + "Operator)")
	print("")
	print(classname + "Operator <- " + operators + " / CustomOperator('with', '" + classname.lower() + "')")
	print(classname + "Term <- " + fix + "List(Before" + classname + "Term, Before" + classname + "Operator)")
	print("Before" + classname + "Operator <- CustomOperator('before', '" + classname.lower() + "')", end="")

level("Or", "'or'", "Infix")
level("Xor", "'xor'", "Infix")
level("And", "'and'", "Infix")
level("Compare", "'==' / '!=' / '<' / '<=' / '>' / '>='", "Infix")
level("Bitor", "'bitor'", "Infix")
level("Bitxor", "'bitxor'", "Infix")
level("Bitand", "'bitand'", "Infix")
level("Shift", "'<<' / '>>'", "Infix")
level("Add", "'+' / '-'", "Infix")
level("Multiply", "'*' / '/' / 'div' / 'mod'", "Infix")
level("Power", "'^'", "Infix")
level("Pmember", "'.*' / '->*'", "Infix")
level("Prefix", "'++' / '--' / '+' / '-' / 'not' / 'bitnot' / '(' _ Identifier _ ')' / '^' / '@' / 'sizeof' / 'new' / 'new[]' / 'delete' / 'delete[]'", "Prefix")
level("Postfix", "'++' / '--' / '(' _ Placeholder _ ')' / '[' _ Placeholder _ ']' / '.' / '->'", "Postfix")
level("Scope", "'::'", "Infix")
print("")
print("")
print("BeforeScopeTerm <- Number / Identifier / '(' _ Expression _ ')'")
print("")
print('''PrefixList(Id, Op) <- (Op _)* Id
InfixList(Id, Op) <- Id (_ Op _ Id)*
PostfixList(Id, Op <- Id (_ Op)*''')


