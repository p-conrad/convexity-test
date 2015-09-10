/// Data type used as an expression identifier.
alias Identifier = string;

/// An expression, consisting of an identifier and a number of sub-expressions.
struct Expression {
	Identifier id;
	Expression[] children;
	Classifier type;

	this (Identifier id, Expression[] children ...) {
		this.id = id;
		this.children = children;
		this.type = classify(id, children);
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

/**
 * Classification of an expression.
 * As long as no distinction is needed functions and operators will be grouped together in
 * functionSymbol for simplicity.
 */
enum Classifier { functionSymbol, functionArgument, positiveScalar, negativeScalar,
	constantVector, nonConstantVector }

bool isFunctionOrOperator(Classifier c) { return c == Classifier.functionSymbol; }
bool isFunctionOrOperator(Expression e) { return isFunctionOrOperator(e.type); }
bool isArgument(Classifier c) { return c == Classifier.functionArgument; }
bool isArgument(Expression e) { return isArgument(e.type); }
bool isScalar(Classifier c) { return  c == Classifier.positiveScalar || c == Classifier.negativeScalar; }
bool isScalar(Expression e) { return isScalar(e.type); }
bool isConstant(Classifier c) { return c.isScalar || c.isConstantVector; }
bool isConstant(Expression e) { return isConstant(e.type); }
bool isPositive(Classifier c) { return c == Classifier.positiveScalar; }
bool isPositive(Expression e) { return isPositive(e.type); }
bool isNegative(Classifier c) { return c == Classifier.negativeScalar; }
bool isNegative(Expression e) { return isNegative(e.type); }
bool isConstantVector(Classifier c) { return c == Classifier.constantVector; }
bool isConstantVector(Expression e) { return isConstantVector(e.type); }
bool isNonConstantVector(Classifier c) { return c == Classifier.nonConstantVector; }
bool isNonConstantVector(Expression e) { return isNonConstantVector(e.type); }
bool isVector(Classifier c) { return c.isConstantVector || c.isNonConstantVector; }
bool isVector(Expression e) { return isVector(e.type); }


/// Returns: the numeric value of an expression identifier if it is a number. Raises an exception otherwise.
double getNumericValue(Identifier i) {
	import std.conv : to;
	return to!double(i);
}
double getNumericValue(Expression e) { return getNumericValue(e.id); }

unittest {
	assert (getNumericValue("2") == 2);
	assert (getNumericValue("-2") == -2);
	assert (getNumericValue("2.5") == 2.5);
}

/// Returns: true if an expression identifier is a number
bool isNumber(Identifier i) {
	import std.conv : ConvException;
	try {
		getNumericValue(i);
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

/// Returns: true if an expression identifier is a function argument
bool isArgument(Identifier i) {
	import std.array : front;
	import std.uni : isAlpha;
	return (i.front.isAlpha() && !i.isFunctionOrOperator && !i.isVector);
}

// Outside because putting it inside will make the compiler cry about circular dependencies for some reason.
import ruleset : applicableRules;
/// Returns: true if an expression identifier is a function or operator
bool isFunctionOrOperator(Identifier i) {
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

/// Returns: true if an expression identifier is a vector of any size
bool isVector(Identifier i) { return i == "vector"; }

/// Returns: true if an expression is a vector consisting only of constants
bool isConstantVector(Identifier i, Expression[] children) {
	import std.algorithm : all;
	return (i.isVector && all!(a => isNumber(a.id))(children));
}

/// Returns: true if an expression is a non-constantVector
bool isNonConstantVector(Identifier i, Expression[] children) { return (i.isVector && !i.isConstantVector(children)); }

/// Returns: An array of expressions for a given vector. Useful for expanding a vector where
/// only one argument is given, otherwise simply the children of that expression will be returned.
Expression[] toVector(Expression e, size_t len) {
	assert (e.id == "vector");
	assert (e.childCount == 1 || e.childCount == len);

	if (e.childCount == len) return e.children;

	import std.array : uninitializedArray;
	return uninitializedArray!(Expression[])(len)[] = Expression(e.child.id);
}

/// Returns: The Classifier for a given expression
Classifier classify(Identifier i, Expression[] children) {
	if (i.isFunctionOrOperator) return Classifier.functionSymbol;
	if (i.isArgument) return Classifier.functionArgument;
	if (i.isNumber && i.getNumericValue > 0) return Classifier.positiveScalar;
	if (i.isNumber && i.getNumericValue < 0) return Classifier.negativeScalar;
	if (i.isConstantVector(children)) return Classifier.constantVector;
	if (i.isNonConstantVector(children)) return Classifier.nonConstantVector;

	import std.string : format;
	assert (0, format("Failed to classify expression: '%s'", i));
}
