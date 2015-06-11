module convtest;

// Function properties
enum Curvature { concave, convex, linear, unspecified }
enum Gradient { increasing, decreasing, constant, unspecified }

// A tuple, describing both properties of a given expression
import std.typecons : Tuple;
alias Property = Tuple!(Curvature, "curv", Gradient, "grad");

// checking for some basic properties
@property
bool isNondecreasing(Gradient g) {
	return ((g == Gradient.increasing) || (g == Gradient.constant));
}

@property
bool isNonIncreasing(Gradient g) {
	return ((g == Gradient.decreasing) || (g == Gradient.constant));
}

@property
bool isConvex(Curvature c) {
	return ((c == Curvature.convex) || (c == Curvature.linear));
}

@property
bool isConcave(Curvature c) {
	return ((c == Curvature.concave) || (c == Curvature.linear));
}

// An expression, consisting of an identifier string and a variable number
// of sub-expressions
struct Expression {
	string identifier;
	Expression[] children;

	bool hasChildren() { return (children.length > 0); }
}

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
Property sampleRule(Expression exp) {
	if (!exp.hasChildren())
		return Property(Curvature.unspecified, Gradient.unspecified);

	// post-order traverse the expression, determining the curvature of
	// all children
	auto subProp = new Property[exp.children.length];
	foreach (i, ref c; subProp)
		c = sampleRule(exp.children[i]);

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
	assert (result.curv == Curvature.unspecified);
	assert (result.grad == Gradient.unspecified);
}
