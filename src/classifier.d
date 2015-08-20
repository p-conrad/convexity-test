import expression;

// classification of an expression
// As long as no distinction is needed functions and operators will be grouped together in
// functionSymbol for simplicity
enum Classifier { functionSymbol, functionArgument, positiveScalar, negativeScalar }

// some functions to easily check for the value of a given classifier
bool isFunctionOrOperator(Classifier c) { return c == Classifier.functionSymbol; }
bool isArgument(Classifier c) { return c == Classifier.functionArgument; }
bool isScalar(Classifier c) { return  c == Classifier.positiveScalar || c == Classifier.negativeScalar; }
bool isConstantValue(Classifier c) { return c.isScalar; }
bool isPositive(Classifier c) { return c == Classifier.positiveScalar; }
bool isNegative(Classifier c) { return c == Classifier.negativeScalar; }


// Returns the numeric value of an expression identifier if it is a number or raises an exception
// otherwise
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

// Returns true if an expression identifier is a function argument
bool isArgument(Identifier i) {
	import std.array : front;
	import std.uni : isAlpha;
	return (i.front.isAlpha() && !isFunctionOrOperator(i));
}

// Returns true if an expression identifier is a function or operator
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
bool isArgument(Expression e) { return isArgument(e.id); }
bool isFunctionOrOperator(Expression e) { return isFunctionOrOperator(e.id); }

// classify an expression
Classifier classify(Expression e) {
	if (isFunctionOrOperator(e)) return Classifier.functionSymbol;
	if (isArgument(e)) return Classifier.functionArgument;
	if (isNumber(e) && getNumericValue(e) > 0) return Classifier.positiveScalar;
	if (isNumber(e) && getNumericValue(e) < 0) return Classifier.negativeScalar;
	
	import std.string : format;
	assert (0, format("Failed to classify expression: '%s'", e.id));
}
