// An expression, consisting of an identifier string and a variable number
// of sub-expressions
struct Expression {
	string identifier;
	Expression[] children;
}

bool hasChildren(Expression e) { return (e.children.length > 0); }
