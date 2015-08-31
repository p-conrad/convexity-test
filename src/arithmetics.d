import ruleset;
import expression;
import property;
import classifier;

// The calling function, doing some preparatory work common to all four functions so we don't need
// to do the same things in every function (DRY) but still have the advantage of giving each function
// in applicableRules their own name instead of calling the now removed arithmeticRule
Property caller(Expression e, Property function(Expression, Classifier, Classifier) rule) {
	if (e.childCount != 2) return unknownResult;

	auto left = classify(e.left);
	auto right = classify(e.right);

	if (left.isConstantValue && right.isConstantValue) return Property(Curvature.linear, Gradient.constant);

	return rule(e, left, right);
}

// The functions to be used in applicableRules
Property addition(Expression e) { return caller(e, &addition); }
Property subtraction(Expression e) { return caller(e, &subtraction); }
Property multiplication(Expression e) { return caller(e, &multiplication); }
Property division(Expression e) { return caller(e, &division); }

// The actual functions
Property addition(Expression e, Classifier left, Classifier right) {
	assert (e.id == "+");

	// Addition with a constant always preserves the properties of the function they are applied to
	if (left.isConstantValue || right.isConstantValue) return analyze(left.isConstantValue ? e.right: e.left);

	// Addition of two convex/concave functions preserves the properties
	return weaker(analyze(e.left), analyze(e.right));
}

unittest {
	assert (addition(E("+", [E("2.5"), E("-2")])) == P(linear, constant));
	assert (addition(E("+", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
}

Property subtraction(Expression e, Classifier left, Classifier right) {
	assert (e.id == "-");

	// Subtraction with a constant preserves the convex property if the constant is on the right side,
	// otherwise reverses it
	if (left.isConstantValue) return analyze(e.right).complement;
	if (right.isConstantValue) return analyze(e.left);
	
	// If a concave function is subtracted from a convex one then the result is convex, and vice versa
	return weaker(analyze(e.left), analyze(e.right).complement);
}

unittest {
	assert (subtraction(E("-", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
	assert (subtraction(E("-", [E("ln", [E("x")]), E("-2")])) == P(concave, unspecified));
	assert (subtraction(E("-", [E("2"), E("ln", [E("x")])])) == P(convex, unspecified));
}

Property multiplication(Expression e, Classifier left, Classifier right) {
	assert (e.id == ".*");

	// Return unknown if both children are functions or arguments
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

	// Multiplication with a scalar preserves the properties if the scalar is larger than 0 and
	// reverse them if it is smaller
	auto result = left.isConstantValue ? analyze(e.right) : analyze(e.left);
	bool positiveConstant = left.isConstantValue ? left.isPositive : right.isPositive;
	return positiveConstant ? result : result.complement;
}

unittest {
	assert (multiplication(E(".*", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
	assert (multiplication(E(".*", [E("ln", [E("x")]), E("-2")])) == P(convex, unspecified));
}

Property division(Expression e, Classifier left, Classifier right) {
	assert (e.id == "/");

	// Return unknown if both children are functions or arguments
	if (!left.isConstantValue && !right.isConstantValue) return unknownResult;

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

unittest {
	assert (division(E("/", [E("1"), E("ln", [E("x")])])) == P(convex, unspecified));
	assert (division(E("/", [E("1"), E("-", [E("ln", [E("x")])])])) == P(concave, unspecified));

	// division by linear functions, using some more complex examples
	assert (division(E("/", [E("1"), E("x")])) == P(convex, nonincreasing));
	assert (division(E("/", [E("1"), E("-", [E("x")])])) == P(concave, nondecreasing));
	assert (division(E("/", [E("1"), E("+", [E(".*", [E("-2"), E("x")]), E("5")])]))
			== P(concave, nondecreasing));
	assert (division(E("/", [E("1"), E("-", [E("+", [E(".*", [E("-2"), E("x")]), E("5")])])]))
			== P(convex, nonincreasing));
	assert (division(E("/", [E("-1"), E("+", [E(".*", [E("-2"), E("x")]), E("5")])]))
			== P(convex, nonincreasing));
	assert (division(E("/", [E("-1"), E("-", [E("+", [E(".*", [E("-2"), E("x")]), E("5")])])]))
			== P(concave, nondecreasing));
}
