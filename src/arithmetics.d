import ruleset;
import expression;
import property;
import classifier;

/// The calling function, doing some preparatory work common to all four functions so we don't need
/// to do the same things in every function (DRY) but still have the advantage of giving each function
/// in applicableRules their own name instead of calling the now removed arithmeticRule
Property caller(Expression e, Property function(Expression, Classifier, Classifier) rule) {
	if (e.childCount != 2) return unknownResult;

	auto left = classify(e.left);
	auto right = classify(e.right);

	if (left.isConstantValue && right.isConstantValue) return Property(Curvature.linear, Gradient.constant);

	return rule(e, left, right);
}

Property addition(Expression e) { return caller(e, &addition); }
Property subtraction(Expression e) { return caller(e, &subtraction); }
Property multiplication(Expression e) { return caller(e, &multiplication); }
Property division(Expression e) { return caller(e, &division); }

Property addition(Expression e, Classifier left, Classifier right) {
	assert (e.id == "+");

	if (left.isConstantValue || right.isConstantValue) return analyze(left.isConstantValue ? e.right: e.left);

	// Convex functions are closed under addition
	return weaker(analyze(e.left), analyze(e.right));
}

unittest {
	assert (addition(E("+", sc1, sc2)) == P(linear, constant));
	assert (addition(E("+", lnX, sc1)) == P(concave, unspecified));
	assert (addition(E("+", lnX, linFun1)) == P(concave, unspecified));
	assert (addition(E("+", lnX, E("-", linFun1))) == P(concave, unspecified));
	assert (addition(E("+", expX, linFun1)) == P(convex, unspecified));
	assert (addition(E("+", linFun1, linFun2)) == P(linear, unspecified));
}

Property subtraction(Expression e, Classifier left, Classifier right) {
	assert (e.id == "-");

	// Subtraction with a constant depends on the side of the constant
	if (left.isConstantValue) return analyze(e.right).complement;
	if (right.isConstantValue) return analyze(e.left);
	
	// Like addition: f + (-g)
	return weaker(analyze(e.left), analyze(e.right).complement);
}

unittest {
	assert (subtraction(E("-", lnX, sc1)) == P(concave, unspecified));
	assert (subtraction(E("-", lnX, sc2)) == P(concave, unspecified));
	assert (subtraction(E("-", sc1, lnX)) == P(convex, unspecified));
}

Property multiplication(Expression e, Classifier left, Classifier right) {
	assert (e.id == ".*");

	// We must have at least one constant value here
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

	// Multiplication with a scalar depends on whether that scalar is smaller or larger than zero
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (multiplication(E(".*", lnX, sc1)) == P(concave, unspecified));
	assert (multiplication(E(".*", lnX, sc2)) == P(convex, unspecified));
}

Property division(Expression e, Classifier left, Classifier right) {
	assert (e.id == "/");

	// We must have at least one constant value here
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

	// Division with a constant value depends on both the side of the scalar and whether it is smaller or
	// larger than zero; also special rules apply if the function divided by has linear property
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;

	if (left.isConstantValue) {
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
		return positiveConstant ? result.complement : result;
	}
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (division(E("/", sc1, lnX)) == P(convex, unspecified));
	assert (division(E("/", sc1, E("-", lnX))) == P(concave, unspecified));

	// division by linear functions, using some more complex examples
	assert (division(E("/", sc1, E("x"))) == P(convex, nonincreasing));
	assert (division(E("/", sc1, E("-", x))) == P(concave, nondecreasing));
	assert (division(E("/", sc1, linFun2)) == P(concave, nondecreasing));
	assert (division(E("/", sc1, E("-", linFun2))) == P(convex, nonincreasing));
	assert (division(E("/", sc2, linFun2)) == P(convex, nonincreasing));
	assert (division(E("/", sc2, E("-", linFun2))) == P(concave, nondecreasing));
}
