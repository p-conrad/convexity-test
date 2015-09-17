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
	// currently works for both types of multiplication
	assert (e.id == ".*" || e.id == "s*");
	assert (e.childCount == 2);

	if (!e.left.isConstant && !e.right.isConstant) return unknownResult;

	// Multiplication with a constant depends on whether that constant is positive or negative
	auto result = e.left.isConstant ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = e.left.isConstant ? e.left.isPositive : e.right.isPositive;
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (multiplication(E(".*", lnX, sc1)) == R(concave, unspecified));
	assert (multiplication(E(".*", lnX, sc2)) == R(convex, unspecified));
	// (weighted) sums expressed as a scalar product
	assert (multiplication(E(".*", E("exp", vecX), ones)) == R(convex, unspecified));
	assert (multiplication(E(".*", E("exp", vecX), E("vector", E("1"), E("-2")))) == R(concave, unspecified));
	assert (multiplication(E(".*", E("ln", vecX), nVec)) == R(convex, unspecified));
	assert (multiplication(E(".*", E("ln", vecX), ones)) == R(concave, unspecified));
	// linear functions
	assert (multiplication(E(".*", E("s*", E("2"), vecX), ones)) == R(linear, nondecreasing));
	assert (multiplication(E(".*", E("s*", E("-2"), vecX), ones)) == R(linear, nonincreasing));
	assert (multiplication(E(".*", E("vector", E("1"), E("-2")), vecX)) == R(linear, nonincreasing));
	assert (multiplication(E(".*", E("vector", E("-1"), E("2")), vecX)) == R(linear, nondecreasing));
}

/// Returns: the Result for a matrix multiplication in the form x'Ax. Only two children are given,
/// the vector does not need to be transposed explicitly.
Result matrixMultiplication(Expression e) {
	assert (e.id == "m*");
	assert (e.childCount == 2);
	assert (e.right.isMatrix);

	if (e.left.isConstant) return Result(Curvature.linear, Monotonicity.constant);

	// matrix type not specified
	if (!e.right.isPositive && !e.right.isNegative) return unknownResult;
	// squares of non-linear functions -> unknown
	if (!analyze(e.left).isLinear) return unknownResult;
	return Result(e.right.isPositive ? Curvature.convex : Curvature.concave, Monotonicity.unspecified);
}

unittest {
	assert (matrixMultiplication(E("m*", vecX, pMatrix)) == R(convex, unspecified));
	assert (matrixMultiplication(E("m*", E(".*", E("2"), vecX), pMatrix)) == R(convex, unspecified));
	assert (matrixMultiplication(E("m*", vecX, nMatrix)) == R(concave, unspecified));
	assert (matrixMultiplication(E("m*", E(".*", E("2"), vecX), nMatrix)) == R(concave, unspecified));
	assert (matrixMultiplication(E("m*", E("exp", vecX), nMatrix)) == unknownResult);
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
