import property;
import expression;
import classifier;

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
	"exp"	:	[&compositionRule],
	"abs"	:	[&emptyRule]
];

// The algorithm checking for convexity
Property analyze(Expression e) {
	if (isNumber(e)) return Property(Curvature.linear, Gradient.constant);
	if (isArgument(e)) return Property(Curvature.linear, Gradient.increasing);

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
Property arithmeticRule(Expression e)
in {
	import std.algorithm : any;
	assert (any!(a => a == e.id)(["+", "-", "*", "/"]));
}
body {
	// We are expecting the operators to be binary for now (?)
	assert (e.childCount <= 2 && e.childCount > 0);

	// unary minus
	if (e.id == "-" && e.childCount == 1)
		return analyze(e.child).complement;

	// unary plus
	if (e.id == "+" && e.childCount == 1)
		return analyze(e.child);

	// If both children are numbers, the result is always linear
	if (isNumber(e.left) && isNumber(e.right))
		return Property(Curvature.linear, Gradient.constant);

	auto left = classify(e.left);
	auto right = classify(e.right);

	import arithmetics;
	if (e.id == "+") return addition(e, left, right);
	if (e.id == "-") return subtraction(e, left, right);

	// The result of multiplying / dividing two functions cannot (yet?) be determined by arithmeticRule
	if (!(left.isConstantValue || right.isConstantValue))
		return Property(Curvature.unspecified, Gradient.unspecified);

	if (e.id == "*") return multiplication(e, left, right);
	if (e.id == "/") return division(e, left, right);

	assert (0);
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
	"exp"	:	Property(Curvature.convex, Gradient.increasing),
];

unittest {
	// make sure that for every function in functionProperties there is a rule defined in
	// applicableRules
	import std.algorithm : all;
	static assert (all!((a) => a in applicableRules)(functionProperties.keys));
	static assert (all!((a) => applicableRules[a].length >= 1)(functionProperties.keys));
}

// composition rules to be used for a function f(x) = g(h(x))
Property compositionRule(Expression e) {
	// expressions to be checked with this rule need to have exactly one child: h(x), while g is the
	// expression itself
	// TODO: A function may actually have more than one argument
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

// an empty rule for expressions which should not occur due to transformations (e.g. abs)
Property emptyRule(Expression e) {
	assert (0, "emptyRule has been called");
}
