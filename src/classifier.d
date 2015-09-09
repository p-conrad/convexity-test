import expression;

/// classification of an expression
/// As long as no distinction is needed functions and operators will be grouped together in
/// functionSymbol for simplicity
enum Classifier { functionSymbol, functionArgument, positiveScalar, negativeScalar,
	constantVector, nonConstantVector }

bool isFunctionOrOperator(Classifier c) { return c == Classifier.functionSymbol; }
bool isArgument(Classifier c) { return c == Classifier.functionArgument; }
bool isScalar(Classifier c) { return  c == Classifier.positiveScalar || c == Classifier.negativeScalar; }
bool isConstantValue(Classifier c) { return c.isScalar || c.isConstantVector; }
bool isPositive(Classifier c) { return c == Classifier.positiveScalar; }
bool isNegative(Classifier c) { return c == Classifier.negativeScalar; }
bool isConstantVector(Classifier c) { return c == Classifier.constantVector; }
bool isNonConstantVector(Classifier c) { return c == Classifier.nonConstantVector; }
bool isVector(Classifier c) { return c.isConstantVector || c.isNonConstantVector; }


/// Returns: the numeric value of an expression identifier if it is a number.
/// Raises an exception otherwise.
double getNumericValue(Identifier e) {
	import std.conv : to;
	return to!double(e);
}
double getNumericValue(Expression e) { return getNumericValue(e.id); }

unittest {
	assert (getNumericValue("2") == 2);
	assert (getNumericValue("-2") == -2);
	assert (getNumericValue("2.5") == 2.5);
}

/// Returns: true if an expression identifier is a number
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
bool isNumber(Expression e) { return isNumber(e.id); }

unittest {
	assert (isNumber("2.5"));
	assert (!isNumber("foo"));
	assert (isNumber("1e-4"));
}

/// Returns: true if an expression identifier is a function argument
bool isArgument(Identifier i) {
	import std.array : front;
	import std.uni : isAlpha;
	return (i.front.isAlpha() && !isFunctionOrOperator(i));
}
bool isArgument(Expression e) { return isArgument(e.id); }

/// Returns: true if an expression identifier is a function or operator
bool isFunctionOrOperator(Identifier i) {
	import ruleset : applicableRules;
	import std.algorithm : any;
	return any!(a => a == i)(applicableRules.keys);
}
bool isFunctionOrOperator(Expression e) { return isFunctionOrOperator(e.id); }

unittest {
	assert ("+".isFunctionOrOperator);
	assert ("ln".isFunctionOrOperator);
	assert (!"ln ".isFunctionOrOperator);
	assert (!"2".isFunctionOrOperator);
	assert (!"".isFunctionOrOperator);
}

/// Returns: true if an expression identifier is a vector of any size
bool isVector(Identifier i) { return i == "vector"; }
bool isVector(Expression e) { return isVector(e.id); }

/// Returns: true if an expression is a vector consisting only of constants
bool isConstantVector(Expression e) {
	import std.algorithm : all;
	return (e.isVector && all!(a => isNumber(a))(e.children));
}

/// Returns: true if an expression is a non-constantVector
bool isNonConstantVector(Expression e) {
	return (e.isVector && !e.isConstantVector);
}


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
Classifier classify(Expression e) {
	if (e.isFunctionOrOperator) return Classifier.functionSymbol;
	if (e.isArgument) return Classifier.functionArgument;
	if (e.isNumber && e.getNumericValue > 0) return Classifier.positiveScalar;
	if (e.isNumber && e.getNumericValue < 0) return Classifier.negativeScalar;
	if (e.isConstantVector) return Classifier.constantVector;
	if (e.isNonConstantVector) return Classifier.nonConstantVector;
	
	import std.string : format;
	assert (0, format("Failed to classify expression: '%s'", e.id));
}
