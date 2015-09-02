/// Data type used as an expression identifier.
alias Identifier = string;

/// An expression, consisting of an identifier and a number of sub-expressions.
struct Expression {
	Identifier id;
	Expression[] children;

	this (Identifier id) { this(id, []); }
	this (Identifier id, Expression[] children) {
		this.id = id;
		this.children = children;
	}
}

/// Returns: the number of cildren in an expression, namely the length of its children array.
size_t childCount(Expression e) { return e.children.length; }

/// Returns: true if an expression has any children
bool hasChildren(Expression e) { return (e.childCount > 0); }

/// Returns: the n-th child of a given expression, starting from 0.
Expression nthChild(Expression e, size_t n) {
	assert (e.childCount > n);
	return e.children[n];
}

/// Returns: the left/right child of an expression, namely the child at index 0/1.
Expression left(Expression e) { return e.nthChild(0); }
Expression right(Expression e) { return e.nthChild(1); }

/// Returns the first child of an expression, namely the child at index 0
Expression child(Expression e) { return e.left; }
