// data type used as an expression identifier
alias Identifier = string;

// An expression, consisting of an identifier Identifier and a variable number
// of sub-expressions
struct Expression {
	Identifier id;
	Expression[] children;

	this (Identifier id) { this(id, []); }
	this (Identifier id, Expression[] children) {
		this.id = id;
		this.children = children;
	}
}

// Returns the number of cildren in an expression, namely the length of its children array
// This and the following functions is to avoid accessing the array directly, gaining some
// readability
size_t childCount(Expression e) { return e.children.length; }

// Returns whether an expression has any children
bool hasChildren(Expression e) { return (e.childCount > 0); }

// Returns the n-th child of a given expression, starting from 0
Expression nthChild(Expression e, size_t n) {
	assert (e.childCount > n);
	return e.children[n];
}

// Returns left/right child of an expression. Makes only sense if there are two children
// but could be used anyway
Expression left(Expression e) { return e.nthChild(0); }
Expression right(Expression e) { return e.nthChild(1); }

// Returns the first child of an expression, to be used in cases where there is only one
Expression child(Expression e) { return e.left; }
