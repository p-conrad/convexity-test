// data type used as an expression identifier
alias id_t = string;

// An expression, consisting of an identifier id_t and a variable number
// of sub-expressions
struct Expression {
	id_t identifier;
	Expression[] children;
}

bool hasChildren(Expression e) { return (e.children.length > 0); }
