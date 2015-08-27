// functions checking for convexity of arithmetic operations, to be called by arithmeticRule in ruleset

import ruleset;
import expression;
import property;
import classifier;

Property addition(Expression e, Classifier left, Classifier right) {
	assert (e.id == "+");
	assert (!(left.isConstantValue && right.isConstantValue));

	// Addition with a scalar always preserves the properties of the function they are applied to
	if (left.isConstantValue || right.isConstantValue) return analyze(left.isConstantValue ? e.right: e.left);

	// Addition of two convex/concave functions preserves the properties
	return weaker(analyze(e.left), analyze(e.right));
}

Property subtraction(Expression e, Classifier left, Classifier right) {
	assert (e.id == "-");
	assert (!(left.isConstantValue && right.isConstantValue));

	// Subtraction with a scalar preserves the convex property if the scalar is on the right side,
	// otherwise reverses it
	if (left.isConstantValue) return analyze(e.right).complement;
	if (right.isConstantValue) return analyze(e.left);
	
	// If a concave function is subtracted from a convex one then the result is convex, and vice versa
	return weaker(analyze(e.left), analyze(e.right).complement);
}

Property multiplication(Expression e, Classifier left, Classifier right) {
	assert (e.id == ".*");
	assert (!(left.isConstantValue && right.isConstantValue));

	// Multiplication with a scalar preserves the properties if the scalar is larger than 0 and
	// reverse them if it is smaller
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;
	return positiveConstant ? result : result.complement;
}

Property division(Expression e, Classifier left, Classifier right) {
	assert (e.id == "/");
	assert (!(left.isConstantValue && right.isConstantValue));

	// Division with a constant value depends on both the side of the scalar and whether it is smaller or
	// larger than 0; also special rules apply if the function divided by has linear property
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;

	if (left.isConstantValue) {
		// First check whether the function divided is linear. The curvature and gradient need
		// to be adjusted accordingly
		if (left.isPositive && result.isLinear) {
			return result.isNonDecreasing
				? Property(Curvature.convex, Gradient.nonincreasing)
				: Property(Curvature.concave, Gradient.nondecreasing);
		}
		if (left.isNegative && result.isLinear) {
			return result.isNonDecreasing
				? Property(Curvature.concave, Gradient.nondecreasing)
				: Property(Curvature.convex, Gradient.nonincreasing);
		}
		// for non-linear functions the result only depends on whether the number is smaller or larger than zero
		return positiveConstant ? result.complement : result;
	}
	// When a function is divided by a constant value, the result only depends on whether that value is positive or
	// negative
	return positiveConstant ? result : result.complement;
}
