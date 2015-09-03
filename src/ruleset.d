import property;
import expression;
import arithmetics;

/// To check for convexity, rules are being applied. These are, by definition, functions
/// taking an expression as argument and returning the property of that expression.
alias Rule = Property function(Expression);

/// Aliases to simplify the unit tests.
version (unittest) {
	alias E = Expression;
	alias P = Property;
	alias concave = Curvature.concave;
	alias convex = Curvature.convex;
	alias linear = Curvature.linear;
	alias unknown = Curvature.unspecified;
	alias nondecreasing = Gradient.nondecreasing;
	alias nonincreasing = Gradient.nonincreasing;
	alias constant = Gradient.constant;
	alias unspecified = Gradient.unspecified;

	enum x = E("x");
	enum sc1 = E("5");
	enum sc2 = E("-5");
	enum expX = E("exp", E("x"));
	enum lnX = E("ln", E("x"));
	enum linFun1 = E("+", E(".*", E("2"), E("x")), E("5"));
	enum linFun2 = E("+", E(".*", E("-2"), E("x")), E("-5"));
}

/// Rules to apply when checking for convexity.
enum Rule[][Identifier] applicableRules = [
	"+"		:	[&addition],
	"-"		:	[&subtraction],
	".*"	:	[&multiplication],
	"/"		:	[&division],
	"ln"	:	[&compositionRule],
	"exp"	:	[&compositionRule],
	"abs"	:	[&emptyRule]
];

/// The algorithm checking for convexity.
Property analyze(Expression e) {
	import classifier : isNumber, isArgument;
	if (isNumber(e)) return Property(Curvature.linear, Gradient.constant);
	if (isArgument(e)) return Property(Curvature.linear, Gradient.nondecreasing);

	assert (e.id in applicableRules);

	if (e.id == "-" && e.childCount == 1)
		return analyze(e.child).complement;

	if (e.id == "+" && e.childCount == 1)
		return analyze(e.child);

	// Iterate all available rules and use the "stronger" function to get their best possible result
	import std.algorithm : map, reduce;
	return reduce!((a, b) => stronger(a, b))(unknownResult, map!(a => a(e))(applicableRules[e.id]));
}

unittest {
	assert (analyze(E("2")) == P(linear, constant));
	assert (analyze(E("x")) == P(linear, nondecreasing));
	// should be (convex, nonincreasing) but turns out unknown because of insufficient ruleset for now
	assert (analyze(E("ln", [E("/", [E("1"), E("x")])])) == P(unknown, unspecified));
	// should be convex, however by now there is no rule to cover that case
	assert (analyze(E(".*", [E("x"), E("ln", [E("x")])])) == P(unknown, unspecified));

	// unary minus and plus
	assert (analyze(E("-", [E("ln", [E("x")])])) == P(convex, unspecified));
	assert (analyze(E("+", [E("ln", [E("x")])])) == P(concave, unspecified));
}

/// properties of already known functions, to be used with the composition rule.
enum Property[string] functionProperties = [
	"ln"	:	Property(Curvature.concave, Gradient.nondecreasing),
	"exp"	:	Property(Curvature.convex, Gradient.nondecreasing),
];

unittest {
	// Any function above should also be defined in applicableRules.
	import std.algorithm : all;
	static assert (all!((a) => a in applicableRules)(functionProperties.keys));
	static assert (all!((a) => applicableRules[a].length >= 1)(functionProperties.keys));
}

/// Composition rules to be used for a function f(x) = g(h(x)).
Property compositionRule(Expression e) {
	// We need to have exactly one child: h(x), while g is the expression itself.
	// TODO: A function may actually have more than one argument.
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

	return unknownResult;
}

unittest {
	assert (compositionRule(E("exp", [E(".*", [E("2"), E("x")])])) == P(convex, unspecified));
	assert (compositionRule(E("exp", [E("-", [E("ln", [E(".*", [E("2"), E("x")])])])])) == P(convex, unspecified));
}

/// An empty rule for expressions which should not occur due to transformations (e.g. abs).
Property emptyRule(Expression e) {
	assert (0, "emptyRule has been called");
}
