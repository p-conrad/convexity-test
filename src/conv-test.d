module convtest;

// Curvature types of an expression
enum Curvature { CONCAVE, CONVEX, INCREASING, DECREASING, LINEAR, UNKNOWN }

// An expression, consisting of an identifier string and a variable number
// of sub-expressions
struct Expression {
	string identifier;
	Expression[] children;
}

// To check for convexity, certain rules are being applied. These are,
// by definition, functions taking an expression as argument and
// returning the curvature of that expression.
alias Rule = Curvature function(Expression);

// Apply a certain rule to a given expression
Curvature applyRule(Rule rule, Expression e) {
	return rule(e);
}

// a sample rule, traversing the expression tree und simply saying UNKNOWN
Curvature sampleRule(Expression exp) {
	if (exp.children.length == 0)
		return Curvature.UNKNOWN;

	// post-order traverse the expression, determining the curvature of
	// all children
	auto subCurv = new Curvature[exp.children.length];
	foreach (i, ref c; subCurv)
		c = sampleRule(exp.children[i]);

	/* [some magic involving the results obtained from the previous step] */

	return Curvature.UNKNOWN;
}

unittest {
	// 2*x^3+5
	auto simpleExpression =
		Expression("+",
		[
			Expression("*",
			[
				Expression("2", []),
				Expression("^",
				[
					Expression("x", []),
					Expression("3", [])
				])
			]),
			Expression("5", [])
		]);

	// Basic test: Walking the tree works without raising exceptions
	// and sampleRule yields the expected results
	Curvature result;
	import std.exception;
	assertNotThrown( result = applyRule(&sampleRule, simpleExpression) );
	assert (result == Curvature.UNKNOWN);
}
