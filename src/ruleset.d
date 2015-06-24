import property;
import expression;

// To check for convexity, certain rules are being applied. These are,
// by definition, functions taking an expression as argument and
// returning the property of that expression.
alias Rule = Property function(Expression);

// Apply a certain rule to a given expression
Property applyRule(Rule rule, Expression e) {
	return rule(e);
}

// a sample rule, traversing the expression tree und simply saying
// unspecified
Property sampleRule(Expression e) {
	if (!e.hasChildren())
		return Property(Curvature.unspecified, Gradient.unspecified);

	// post-order traverse the expression, determining theature of
	// all children
	auto subProp = new Property[e.children.length];
	foreach (i, ref c; subProp)
		c = sampleRule(e.children[i]);

	/* [some magic involving the results obtained from the previous step] */

	return Property(Curvature.unspecified, Gradient.unspecified);
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
	Property result;
	import std.exception;
	assertNotThrown( result = applyRule(&sampleRule, simpleExpression) );
	assert (result == Property(Curvature.unspecified, Gradient.unspecified));
}
