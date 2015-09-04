import ruleset;
import expression;
import attributes;
import classifier;

/// The calling function, doing some preparatory work common to all four functions so we don't need
/// to do the same things in every function (DRY) but still have the advantage of giving each function
/// in applicableRules their own name instead of calling the now removed arithmeticRule
Result caller(Expression e, Result function(Expression, Classifier, Classifier) rule) {
	if (e.childCount != 2) return unknownResult;

	auto left = classify(e.left);
	auto right = classify(e.right);

	if (left.isConstantValue && right.isConstantValue) return Result(Curvature.linear, Monotonicity.constant);

	return rule(e, left, right);
}

Result addition(Expression e) { return caller(e, &addition); }
Result subtraction(Expression e) { return caller(e, &subtraction); }
Result multiplication(Expression e) { return caller(e, &multiplication); }
Result division(Expression e) { return caller(e, &division); }

Result addition(Expression e, Classifier left, Classifier right) {
	assert (e.id == "+");

	if (left.isConstantValue || right.isConstantValue) return analyze(left.isConstantValue ? e.right: e.left);

	// Convex functions are closed under addition
	return weaker(analyze(e.left), analyze(e.right));
}

unittest {
	assert (addition(E("+", sc1, sc2)) == R(linear, constant));
	assert (addition(E("+", lnX, sc1)) == R(concave, unspecified));
	assert (addition(E("+", lnX, linFun1)) == R(concave, unspecified));
	assert (addition(E("+", lnX, E("-", linFun1))) == R(concave, unspecified));
	assert (addition(E("+", expX, linFun1)) == R(convex, unspecified));
	assert (addition(E("+", linFun1, linFun2)) == R(linear, unspecified));
	// exp(-2x+(-5)) + (-ln(x))
	assert (addition(E("+", E("exp", linFun2), E("-", lnX))) == R(convex, unspecified));
	// multiple addition
	assert (addition(E("+", sc1, E("+", sc2, linFun1))) == R(linear, nondecreasing));
	assert (addition(E("+", expX, lnX)) == unknownResult);
}

Result subtraction(Expression e, Classifier left, Classifier right) {
	assert (e.id == "-");

	// Subtraction with a constant depends on the side of the constant
	if (left.isConstantValue) return analyze(e.right).complement;
	if (right.isConstantValue) return analyze(e.left);
	
	// Like addition: f + (-g)
	return weaker(analyze(e.left), analyze(e.right).complement);
}

unittest {
	assert (subtraction(E("-", linFun1, linFun2)) == R(linear, nondecreasing));
	assert (subtraction(E("-", lnX, sc1)) == R(concave, unspecified));
	assert (subtraction(E("-", lnX, sc2)) == R(concave, unspecified));
	assert (subtraction(E("-", sc1, lnX)) == R(convex, unspecified));
	assert (subtraction(E("-", E("exp", linFun2), lnX)) == R(convex, unspecified));
	assert (subtraction(E("-", E("exp", linFun2), expX)) == unknownResult);
}

Result multiplication(Expression e, Classifier left, Classifier right) {
	assert (e.id == ".*");

	// We must have at least one constant value here
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

	// Multiplication with a scalar depends on whether that scalar is smaller or larger than zero
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (multiplication(E(".*", lnX, sc1)) == R(concave, unspecified));
	assert (multiplication(E(".*", lnX, sc2)) == R(convex, unspecified));
}

Result division(Expression e, Classifier left, Classifier right) {
	assert (e.id == "/");

	// We must have at least one constant value here
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

	// dividing functions: discontinuities -> not convex in general
	if (left.isConstantValue) return unknownResult;
	return right.isPositive ? analyze(e.left) : analyze(e.left).complement;
}

unittest {
	assert (division(E("/", expX, sc1)) == Result(Curvature.convex, Monotonicity.unspecified));
	assert (division(E("/", expX, sc2)) == Result(Curvature.concave, Monotonicity.unspecified));
}
