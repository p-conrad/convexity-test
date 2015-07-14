import property;
import expression;

// To check for convexity, certain rules are being applied. These are, by definition, functions
// taking an expression as argument and returning the property of that expression.
alias Rule = Property function(Expression);

// Aliases to simplify the unit tests
version (unittest) {
	alias E = Expression;
	alias P = Property;
	alias concave = Curvature.concave;
	alias convex = Curvature.convex;
	alias linear = Curvature.linear;
	alias unknown = Curvature.unspecified;
	alias increasing = Gradient.increasing;
	alias decreasing = Gradient.decreasing;
	alias constant = Gradient.constant;
	alias unspecified = Gradient.unspecified;
}

// Rules to apply when checking for convexity
enum Rule[][Identifier] applicableRules = [
	"+"		:	[&arithmeticRule],
	"-"		:	[&arithmeticRule],
	"*"		:	[&arithmeticRule],
	"/"		:	[&arithmeticRule],
	"ln"	:	[&compositionRule],
	"exp"	:	[&compositionRule]
];

// The algorithm checking for convexity
Property analyze(Expression e) {
	if (isNumber(e)) return Property(Curvature.linear, Gradient.constant);
	if (isIdentifier(e)) return Property(Curvature.linear, Gradient.increasing);

	assert (e.id in applicableRules);
	
	// simple version: take the first available rule and return its result
	// better: apply all available rules, then pick/combine their best result [TODO]
	return applicableRules[e.id][0](e);
}

unittest {
	assert (analyze(E("2")) == P(linear, constant));
	assert (analyze(E("x")) == P(linear, increasing));
	// should be (convex, decreasing) but turns out unknown because of insufficient ruleset for now
	assert (analyze(E("ln", [E("/", [E("1"), E("x")])])) == P(unknown, unspecified));
	// should be convex, however by now there is no rule to cover that case
	assert (analyze(E("*", [E("x"), E("ln", [E("x")])])) == P(unknown, unspecified));
}

// a rule dealing with simple arithmetic operations
Property arithmeticRule(Expression e) {
	// We are expecting the operators to be binary
	assert (e.childCount <= 2);

	// unary minus
	if (e.id == "-" && e.childCount == 1)
		return analyze(e.child).complement;

	// unary plus
	if (e.id == "+" && e.childCount == 1)
		return analyze(e.child);

	// If both children are numbers, the result is always linear
	if (isNumber(e.left) && isNumber(e.right))
		return Property(Curvature.linear, Gradient.constant);

	// TODO: deal with expressions whose children are both not numbers; say unspecified for now
	if (!(isNumber(e.left) || isNumber(e.right)))
		return Property(Curvature.unspecified, Gradient.unspecified);

	// Find the scalar and analyze the expression; save the result for later use
	double number = isNumber(e.left) ? getNumericValue(e.left) : getNumericValue(e.right);
	Property result = analyze(isNumber(e.left) ? e.right : e.left);

	assert (number != 0); // should be incorrect syntax

	// Addition with a scalar always preserves the properties of the function they are applied to
	if (e.id == "+") return result;

	// Subtraction with a scalar preserves the properties if the scalar is on the right side,
	// otherwise reverse them
	if (e.id == "-") {
		if (isNumber(e.right)) return result;
		return result.complement;
	}

	// Multiplication with a scalar preserves the properties if the scalar is larger than 0 and
	// reverse them if it is smaller
	if (e.id == "*") {
		if (number > 0) return result;
		return result.complement;
	}

	// Division with a scalar depends on both the side of the scalar and whether it is smaller or
	// larger than 0; also special rules apply if the function divided by has linear property
	if (e.id == "/") {
		if (isNumber(e.left)) {
			// First check whether the function divided is linear. The curvature and gradient need
			// to be adjusted accordingly
			if (number > 0 && result.isLinear) {
				if (result.isIncreasing) return Property(Curvature.convex, Gradient.decreasing);
				return Property(Curvature.concave, Gradient.increasing);
			}
			if (number < 0 && result.isLinear) {
				if (result.isIncreasing) return Property(Curvature.concave, Gradient.increasing);
				return Property(Curvature.convex, Gradient.decreasing);
			}
			// for non-linear functions the result only depends on whether the number is smaller or
			// larger than zero
			if (number > 0) return result.complement;
			if (number < 0) return result;
		}
		if (isNumber(e.right) && number > 0) return result;
		if (isNumber(e.right) && number < 0) return result.complement;
	}

	return Property(Curvature.unspecified, Gradient.unspecified);
}

unittest {
	// two numbers
	assert (arithmeticRule(E("+", [E("2.5"), E("-2")])) == P(linear, constant));

	// unary minus and plus
	assert (arithmeticRule(E("-", [E("ln", [E("x")])])) == P(convex, unspecified));
	assert (arithmeticRule(E("+", [E("ln", [E("x")])])) == P(concave, unspecified));

	// addition, subtraction, multiplication
	assert (arithmeticRule(E("+", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
	assert (arithmeticRule(E("-", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
	assert (arithmeticRule(E("-", [E("ln", [E("x")]), E("-2")])) == P(concave, unspecified));
	assert (arithmeticRule(E("-", [E("2"), E("ln", [E("x")])])) == P(convex, unspecified));
	assert (arithmeticRule(E("*", [E("ln", [E("x")]), E("2")])) == P(concave, unspecified));
	assert (arithmeticRule(E("*", [E("ln", [E("x")]), E("-2")])) == P(convex, unspecified));
	assert (arithmeticRule(E("/", [E("1"), E("ln", [E("x")])])) == P(convex, unspecified));
	assert (arithmeticRule(E("/", [E("1"), E("-", [E("ln", [E("x")])])])) == P(concave, unspecified));

	// division by linear functions, using some more complex examples
	assert (arithmeticRule(E("/", [E("1"), E("x")])) == P(convex, decreasing));
	assert (arithmeticRule(E("/", [E("1"), E("-", [E("x")])])) == P(concave, increasing));
	assert (arithmeticRule(E("/", [E("1"), E("+", [E("*", [E("-2"), E("x")]), E("5")])]))
			== P(concave, increasing));
	assert (arithmeticRule(E("/", [E("1"), E("-", [E("+", [E("*", [E("-2"), E("x")]), E("5")])])]))
			== P(convex, decreasing));
	assert (arithmeticRule(E("/", [E("-1"), E("+", [E("*", [E("-2"), E("x")]), E("5")])]))
			== P(convex, decreasing));
	assert (arithmeticRule(E("/", [E("-1"), E("-", [E("+", [E("*", [E("-2"), E("x")]), E("5")])])]))
			== P(concave, increasing));
}

// properties of already known functions, to be used with the composition rule
enum Property[string] functionProperties = [
	"ln"	:	Property(Curvature.concave, Gradient.increasing),
	"exp"	:	Property(Curvature.convex, Gradient.increasing)
];

// composition rules to be used for a function f(x) = g(h(x))
Property compositionRule(Expression e) {
	// expressions to be checked with this rule need to have exactly one child: h(x), while g is the
	// expression itself
	// TODO: A function may actually have more than one arguments
	assert (e.childCount == 1);

	auto parent = functionProperties[e.id];
	auto child = analyze(e.child);

	if (parent.isConvex && parent.isNonDecreasing && child.isConvex)
		return Property(Curvature.convex, Gradient.unspecified);
	if (parent.isConvex && parent.isNonIncreasing && child.isConcave)
		return Property(Curvature.convex, Gradient.unspecified);
	if (parent.isConcave && parent.isNonDecreasing && child.isConcave)
		return Property(Curvature.concave, Gradient.unspecified);
	if (parent.isConcave && parent.isNonIncreasing && child.isConvex)
		return Property(Curvature.concave, Gradient.unspecified);

	return Property(Curvature.unspecified, Gradient.unspecified);
}

unittest {
	assert (compositionRule(E("exp", [E("*", [E("2"), E("x")])])) == P(convex, unspecified));
	assert (compositionRule(E("exp", [E("-", [E("ln", [E("*", [E("2"), E("x")])])])])) == P(convex, unspecified));
}
