import attributes;
import expression;
import arithmetics;

/// To check for convexity, rules are being applied. These are, by definition, functions
/// taking an expression as argument and returning the attributes (Result) of that expression.
alias Rule = Result function(Expression);

/// Aliases to simplify the unit tests.
version (unittest) {
	alias E = Expression;
	alias R = Result;
	alias concave = Curvature.concave;
	alias convex = Curvature.convex;
	alias linear = Curvature.linear;
	alias unknown = Curvature.unspecified;
	alias nondecreasing = Monotonicity.nondecreasing;
	alias nonincreasing = Monotonicity.nonincreasing;
	alias constant = Monotonicity.constant;
	alias unspecified = Monotonicity.unspecified;

	enum x = E("x");
	enum sc1 = E("5");
	enum sc2 = E("-5");
	enum expX = E("exp", E("x"));
	enum lnX = E("ln", E("x"));
	enum linFun1 = E("+", E(".*", E("2"), E("x")), E("5"));
	enum linFun2 = E("+", E(".*", E("-2"), E("x")), E("-5"));
}

unittest {
	assert (analyze(x) == R(linear, nondecreasing));
	assert (analyze(sc1) == R(linear, constant));
	assert (analyze(expX) == R(convex, unspecified));
	assert (analyze(lnX) == R(concave, unspecified));
	assert (analyze(linFun1) == R(linear, nondecreasing));
	assert (analyze(linFun2) == R(linear, nonincreasing));
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
Result analyze(Expression e) {
	import classifier : isNumber, isArgument;
	if (isNumber(e)) return Result(Curvature.linear, Monotonicity.constant);
	if (isArgument(e)) return Result(Curvature.linear, Monotonicity.nondecreasing);

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
	assert (analyze(E("2")) == R(linear, constant));
	assert (analyze(E("x")) == R(linear, nondecreasing));
	// should be (convex, nonincreasing) but turns out unknown because of insufficient ruleset for now
	assert (analyze(E("ln", [E("/", [E("1"), E("x")])])) == R(unknown, unspecified));
	// should be convex, however by now there is no rule to cover that case
	assert (analyze(E(".*", [E("x"), E("ln", [E("x")])])) == R(unknown, unspecified));

	// unary minus and plus
	assert (analyze(E("-", [E("ln", [E("x")])])) == R(convex, unspecified));
	assert (analyze(E("+", [E("ln", [E("x")])])) == R(concave, unspecified));
}

/// attributes of already known functions, to be used with the composition rule.
enum Result[string] functionAttributes = [
	"ln"	:	Result(Curvature.concave, Monotonicity.nondecreasing),
	"exp"	:	Result(Curvature.convex, Monotonicity.nondecreasing),
];

unittest {
	// Any function above should also be defined in applicableRules.
	import std.algorithm : all;
	static assert (all!((a) => a in applicableRules)(functionAttributes.keys));
	static assert (all!((a) => applicableRules[a].length >= 1)(functionAttributes.keys));
}

/// Composition rules to be used for a function f(x) = g(h(x)).
Result compositionRule(Expression e) {
	// We need to have exactly one child: h(x), while g is the expression itself.
	// TODO: A function may actually have more than one argument.
	assert (e.childCount == 1);

	auto parent = functionAttributes[e.id];
	auto child = analyze(e.child);

	if (parent.isConvex && parent.isNonDecreasing && child.isConvex)
		return Result(Curvature.convex, Monotonicity.unspecified);
	if (parent.isConvex && parent.isNonIncreasing && child.isConcave)
		return Result(Curvature.convex, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonDecreasing && child.isConcave)
		return Result(Curvature.concave, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonIncreasing && child.isConvex)
		return Result(Curvature.concave, Monotonicity.unspecified);

	return unknownResult;
}

unittest {
	assert (compositionRule(E("exp", linFun1)) == R(convex, unspecified));
	assert (compositionRule(E("exp", E("-", E("ln", linFun1)))) == R(convex, unspecified));
}

/// An empty rule for expressions which should not occur due to transformations (e.g. abs).
Result emptyRule(Expression e) {
	assert (0, "emptyRule has been called");
}
