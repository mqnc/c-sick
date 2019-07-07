
rule([[ Tuple <- TupleOpen _ ExpressionList _ TupleClose ]], basic.concat )
rule([[ TupleOpen <- '{' ]], 'std::make_tuple(')
rule([[ TupleClose <- '}' ]], ')')
