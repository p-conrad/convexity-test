/**
 * The main module, containing the algorithm checking for convexity, basic definitions, rules, and
 * definitions of which rules to apply to a certain type of expression.
 */
module ruleset;

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
	enum vecX = E("vector", E("x"));
	enum ones = E("vector", E("1"));
	enum nVec = E("vector", E("-1"));
	enum pMatrix = E("matrix", Classifier.psdMatrix);
	enum nMatrix = E("matrix", Classifier.nsdMatrix);
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
	"s*"	:	[&multiplication],
	"m*"	:	[&matrixMultiplication],
	"/"		:	[&division],
	"^"		:	[&power],
	"ln"	:	[&compositionRule],
	"exp"	:	[&compositionRule],
	"max"	:	[&compositionRule],
	"min"	:	[&compositionRule],
	"sqrt"	:	[&compositionRule],
	"square":	[&compositionRule],
	"abs"	:	[&emptyRule],
	"norm"	:	[&emptyRule],
];

/// The algorithm checking for convexity.
Result analyze(Expression e) {
	if (e.isConstant) return Result(Curvature.linear, Monotonicity.constant);
	if (e.isArgument) return Result(Curvature.linear, Monotonicity.nondecreasing);

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
	// should be (convex, nonincreasing) but turns out unknown because of insufficient ruleset for now
	assert (analyze(E("ln", [E("/", [E("1"), E("x")])])) == R(unknown, unspecified));
	// should be convex, however by now there is no rule to cover that case
	assert (analyze(E(".*", [E("x"), E("ln", [E("x")])])) == R(unknown, unspecified));

	// unary minus and plus
	assert (analyze(E("-", lnX)) == R(convex, unspecified));
	assert (analyze(E("+", lnX)) == R(concave, unspecified));
}

/// attributes of already known functions, to be used with the composition rule.
enum Result[string] functionAttributes = [
	"ln"	:	Result(Curvature.concave, Monotonicity.nondecreasing),
	"exp"	:	Result(Curvature.convex, Monotonicity.nondecreasing),
	"max"	:	Result(Curvature.convex, Monotonicity.nondecreasing),
	"min"	:	Result(Curvature.concave, Monotonicity.nondecreasing),
	"sqrt"	:	Result(Curvature.concave, Monotonicity.nondecreasing),
	"square":	Result(Curvature.convex, Monotonicity.unspecified),
];

unittest {
	// Any function above should also be defined in applicableRules.
	import std.algorithm : all;
	static assert (all!((a) => a in applicableRules)(functionAttributes.keys));
	static assert (all!((a) => applicableRules[a].length >= 1)(functionAttributes.keys));
}

/// Composition rules to be used for a function f(x) = g(h(x)).
Result compositionRule(Expression e) {
	assert (e.id in functionAttributes);

	auto parent = functionAttributes[e.id];

	import std.algorithm : all;
	if (parent.isConvex && parent.isNonDecreasing && all!(a => analyze(a).isConvex)(e.children))
		return Result(Curvature.convex, Monotonicity.unspecified);
	if (parent.isConvex && parent.isNonIncreasing && all!(a => analyze(a).isConcave)(e.children))
		return Result(Curvature.convex, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonMonotonic && all!(a => analyze(a).isLinear)(e.children))
		return Result(Curvature.convex, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonDecreasing && all!(a => analyze(a).isConcave)(e.children))
		return Result(Curvature.concave, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonIncreasing && all!(a => analyze(a).isConvex)(e.children))
		return Result(Curvature.concave, Monotonicity.unspecified);
	if (parent.isConcave && parent.isNonMonotonic && all!(a => analyze(a).isLinear)(e.children))
		return Result(Curvature.concave, Monotonicity.unspecified);

	return unknownResult;
}

unittest {
	assert (compositionRule(E("exp", linFun1)) == R(convex, unspecified));
	assert (compositionRule(E("exp", E("-", E("ln", linFun1)))) == R(convex, unspecified));
	assert (compositionRule(E("exp", expX)) == R(convex, unspecified));
}

/// The power function, checking for convexity of expressions in the form x^p.
/// Simply: x^p, p in (0..1) -> concave, x^p, p in {2, 4, 6, ...} -> convex, else unknown.
Result power(Expression e) {
	assert (e.id == "^");
	assert (e.childCount == 2);

	if (!e.left.isArgument || !e.right.isScalar) return unknownResult;

	auto number = getNumericValue(e.right);
	if (number < 0) return unknownResult;
	if (number == 0) return Result(Curvature.linear, Monotonicity.constant);
	if (number > 0 && number < 1) return Result(Curvature.concave, Monotonicity.nondecreasing);
	if (number == 1) return analyze(e.left);
	if (number % 1 != 0 || number % 2 == 1) return unknownResult;
	return Result(Curvature.convex, Monotonicity.unspecified);
}

unittest {
	assert (power(E("^", x, sc1)) == unknownResult);
	assert (power(E("^", x, sc2)) == unknownResult);
	assert (power(E("^", lnX, sc1)) == unknownResult);
	assert (power(E("^", sc1, lnX)) == unknownResult);
	assert (power(E("^", x, E("6.5"))) == unknownResult);
	assert (power(E("^", x, E("6"))) == R(convex, unspecified));
	assert (power(E("^", x, E("0.5"))) == R(concave, nondecreasing));
}

/// An empty rule for expressions which should not occur due to transformations (e.g. abs).
Result emptyRule(Expression e) {
	import std.string : format;
	assert (0, format("emptyRule has been called for: '%s'", e.id));
}
