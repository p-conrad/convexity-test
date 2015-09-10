/**
 * Rules checking for the convexity of arithmetic expressions. Although not checked for explicitly,
 * passing two constant values will yield the correct result (linear, constant) implicitly, except
 * for division.
 */
module arithmetics;

import ruleset;
import expression;
import attributes;

Result addition(Expression e) {
	assert (e.id == "+");
	assert (e.childCount == 2);

	if (e.left.isConstant || e.right.isConstant) return analyze(e.left.isConstant ? e.right: e.left);

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

Result subtraction(Expression e) {
	assert (e.id == "-");
	assert (e.childCount == 2);

	// Subtraction with a constant depends on the side of the constant
	if (e.left.isConstant) return analyze(e.right).complement;
	if (e.right.isConstant) return analyze(e.left);
	
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

Result multiplication(Expression e) {
	assert (e.id == ".*");
	assert (e.childCount == 2);

	if (!e.left.isConstant && !e.right.isConstant) return unknownResult;

	// Multiplication with a scalar depends on whether that scalar is smaller or larger than zero
	auto result = e.left.isConstant ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = e.left.isConstant ? e.left.isPositive : e.right.isPositive;
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (multiplication(E(".*", lnX, sc1)) == R(concave, unspecified));
	assert (multiplication(E(".*", lnX, sc2)) == R(convex, unspecified));
}

Result division(Expression e) {
	assert (e.id == "/");
	assert (e.childCount == 2);

	if (e.left.isConstant && e.right.isConstant) return Result(Curvature.linear, Monotonicity.constant);
	if (!e.left.isConstant && !e.right.isConstant) return unknownResult;

	// dividing functions: discontinuities -> not convex in general
	if (e.left.isConstant) return unknownResult;
	return e.right.isPositive ? analyze(e.left) : analyze(e.left).complement;
}

unittest {
	assert (division(E("/", expX, sc1)) == Result(Curvature.convex, Monotonicity.unspecified));
	assert (division(E("/", expX, sc2)) == Result(Curvature.concave, Monotonicity.unspecified));
}
