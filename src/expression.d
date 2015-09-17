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
	this (Identifier id, Classifier type) {
		this.id = id;
		this.type = type;
		this.children = [];
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
 * functionSymbol for simplicity. positiveVector and negativeVector means that its length is smaller
 * or larger than zero. A vector of arguments shall be classified functionArgument. psdMatrix and
 * nsdMatrix are positive/negative semidefinite matrices, matrix describes a matrix with no further
 * known properties.
 */
enum Classifier { functionSymbol, functionArgument, positiveScalar, negativeScalar, positiveVector,
	negativeVector, psdMatrix, nsdMatrix, matrix }

bool isFunctionOrOperator(Classifier c) { return c == Classifier.functionSymbol; }
bool isFunctionOrOperator(Expression e) { return isFunctionOrOperator(e.type); }
bool isArgument(Classifier c) { return c == Classifier.functionArgument; }
bool isArgument(Expression e) { return isArgument(e.type); }
bool isScalar(Classifier c) { return  c == Classifier.positiveScalar || c == Classifier.negativeScalar; }
bool isScalar(Expression e) { return isScalar(e.type); }
bool isVector(Classifier c) { return c == Classifier.positiveVector || c == Classifier.negativeVector; }
bool isVector(Expression e) { return isVector(e.type); }
bool isMatrix(Classifier c) { return c == Classifier.psdMatrix || c == Classifier.nsdMatrix
									|| c == Classifier.matrix; }
bool isMatrix(Expression e) { return isMatrix(e.type); }
// Vectors either consist of constants or arguments - the latter shall be classified functionArgument.
bool isConstant(Classifier c) { return c.isScalar || c.isVector || c.isMatrix; }
bool isConstant(Expression e) { return isConstant(e.type); }
bool isPositive(Classifier c) { return c == Classifier.positiveScalar || c == Classifier.positiveVector
									|| c == Classifier.psdMatrix; }
bool isPositive(Expression e) { return isPositive(e.type); }
bool isNegative(Classifier c) { return c == Classifier.negativeScalar || c == Classifier.negativeVector
									|| c == Classifier.nsdMatrix; }
bool isNegative(Expression e) { return isNegative(e.type); }

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

/// Some keywords which do not have a rule associated with but shall not be classified as arguments
enum reservedWords = [ "vector", "matrix", "det", "diag", "tr" ];

/// Returns: true if an expression identifier is a function argument
bool isArgument(Identifier i) {
	import std.array : front;
	import std.uni : isAlpha;
	import std.algorithm : any;
	return (i.front.isAlpha() && !any!(a => a == i)(reservedWords));
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

/// Returns: true if an expression identifier is a vector of any type
bool isVector(Identifier i) { return i == "vector"; }

/// Returns: true if an expression identifier is a matrix of any type
bool isMatrix(Identifier i) { return i == "matrix"; }

/// Returns: The Classifier for a given expression
Classifier classify(Identifier i, Expression[] children) {
	if (i.isFunctionOrOperator) return Classifier.functionSymbol;
	if (i.isArgument) return Classifier.functionArgument;
	if (i.isVector && children[0].isArgument) return Classifier.functionArgument;
	if (i.isNumber && i.getNumericValue > 0) return Classifier.positiveScalar;
	if (i.isNumber && i.getNumericValue < 0) return Classifier.negativeScalar;
	import std.algorithm : sum, map;
	if (i.isVector && sum(children.map!(a => a.getNumericValue)) > 0) return Classifier.positiveVector;
	if (i.isVector && sum(children.map!(a => a.getNumericValue)) < 0) return Classifier.negativeVector;
	if (i.isMatrix) return Classifier.matrix;
	// positive/negative definite matrix -> diag positive/negative too
	if (i == "diag") return children[0].isPositive ? Classifier.positiveVector : Classifier.negativeVector;
	// same for det and tr
	if (i == "det" || i == "tr") return children[0].isPositive ? Classifier.positiveScalar : Classifier.negativeScalar;
	// transposed vector
	if (i == "'") return children[0].type;

	import std.string : format;
	assert (0, format("Failed to classify expression: '%s'", i));
}

unittest {
	import ruleset : E;
	assert (E("ln").isFunctionOrOperator);
	assert (E("+").isFunctionOrOperator);
	assert (E("vector", E("x")).isArgument);
	assert (E("2").type == Classifier.positiveScalar);
	assert (E("-2").type == Classifier.negativeScalar);
	assert (E("vector", E("1"), E("2")).type == Classifier.positiveVector);
	assert (E("vector", E("-1"), E("-2")).type == Classifier.negativeVector);
	assert (E("vector", E("-1"), E("-2")).type == Classifier.negativeVector);
	assert (E("vector", E("-1"), E("2")).type == Classifier.positiveVector);
	assert (E("vector", E("1"), E("-2")).type == Classifier.negativeVector);
	assert (E("diag", E("matrix", Classifier.psdMatrix)).type == Classifier.positiveVector);
	assert (E("det", E("matrix", Classifier.psdMatrix)).type == Classifier.positiveScalar);
	assert (E("'", E("vector", E("1"), E("-2"))).type == Classifier.negativeVector);
}
