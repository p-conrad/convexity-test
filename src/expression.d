// data type used as an expression identifier
alias Identifier = string;

// An expression, consisting of an identifier Identifier and a variable number
// of sub-expressions
struct Expression {
	Identifier id;
	Expression[] children;
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

// Returns the numeric value of an expression identifier if it is a number or raises an
// exception otherwise
double getNumericValue(Identifier e) {
	import std.conv : to;
	return to!double(e);
}

unittest {
	assert (getNumericValue("2") == 2);
	assert (getNumericValue("-2") == -2);
	assert (getNumericValue("2.5") == 2.5);
}

// Returns true if an expression identifier is a number
bool isNumber(Identifier e) {
	import std.conv : ConvException;
	try {
		getNumericValue(e);
		return true;
	}
	catch (ConvException) {
		return false;
	}
}

unittest {
	assert (isNumber("2.5"));
	assert (!isNumber("foo"));
	assert (isNumber("1e-4"));
}

bool isIdentifier(Identifier i) {
	import std.array : front;
	import std.uni : isAlpha;
	return (i.front.isAlpha() && !isFunctionOrOperator(i));
}

bool isFunctionOrOperator(Identifier i) {
	import ruleset : applicableRules;
	import std.algorithm : any;
	return any!(a => a == i)(applicableRules.keys);
}

unittest {
	assert ("+".isFunctionOrOperator);
	assert ("ln".isFunctionOrOperator);
	assert (!"ln ".isFunctionOrOperator);
	assert (!"2".isFunctionOrOperator);
	assert (!"".isFunctionOrOperator);
}

// wrapper functions
bool isNumber(Expression e) { return isNumber(e.id); }
double getNumericValue(Expression e) { return getNumericValue(e.id); }
bool isIdentifier(Expression e) { return isIdentifier(e.id); }
