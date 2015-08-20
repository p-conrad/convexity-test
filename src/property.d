// Function properties
enum Curvature { unspecified, concave, convex, linear }
enum Gradient { unspecified, increasing, decreasing, constant }

// A tuple, describing both properties of a given expression
import std.typecons : Tuple;
alias Property = Tuple!(Curvature, "curv", Gradient, "grad");

// Check for some properties of the Gradient or Curvature
bool isIncreasing(Gradient g) { return g == Gradient.increasing; }
bool isDecreasing(Gradient g) { return g == Gradient.decreasing; }

bool isNonDecreasing(Gradient g) {
	return (g == Gradient.increasing || g == Gradient.constant);
}

bool isNonIncreasing(Gradient g) {
	return (g == Gradient.decreasing || g == Gradient.constant);
}

bool isConvex(Curvature c) {
	return (c == Curvature.convex || c == Curvature.linear);
}

bool isConcave(Curvature c) {
	return (c == Curvature.concave || c == Curvature.linear);
}

bool isLinear(Curvature c) { return c == Curvature.linear; }

// wrapper functions
bool isIncreasing(Property p) { return isIncreasing(p.grad); }
bool isDecreasing(Property p) { return isDecreasing(p.grad); }
bool isNonDecreasing(Property p) { return isNonDecreasing(p.grad); }
bool isNonIncreasing(Property p) { return isNonIncreasing(p.grad); }
bool isConvex(Property p) { return isConvex(p.curv); }
bool isConcave(Property p) { return isConcave(p.curv); }
bool isLinear(Property p) { return isLinear(p.curv); }

// Property complements, for easy lookup
enum Curvature[Curvature] cComplement = [
	Curvature.concave		:	Curvature.convex,
	Curvature.convex		:	Curvature.concave,
	Curvature.linear		:	Curvature.linear,
	Curvature.unspecified	:	Curvature.unspecified
];

enum Gradient[Gradient] gComplement = [
	Gradient.increasing		:	Gradient.decreasing,
	Gradient.decreasing		:	Gradient.increasing,
	Gradient.constant		:	Gradient.constant,
	Gradient.unspecified	:	Gradient.unspecified
];

// Returns the complement of a Property according to the rules specified above
Property complement(Property p) {
	return Property(cComplement[p.curv], gComplement[p.grad]);
}

// Returns the single complement of either a Curvature or a Gradient
Curvature complement(Curvature c) { return cComplement[c]; }
Gradient complement(Gradient g) { return gComplement[g]; }

// Returns true if two curvatures equal each other
bool curvatureEquals(Curvature a, Curvature b) {
	return (a.isConvex && b.isConvex || a.isConcave && b.isConcave);
}

// Returns true if two gradients equal each other
bool gradientEquals(Gradient a, Gradient b) {
	return (a.isNonIncreasing && b.isNonIncreasing || a.isNonDecreasing && b.isNonDecreasing);
}

bool curvatureEquals(Property a, Property b) { return curvatureEquals(a.curv, b.curv); }
bool gradientEquals(Property a, Property b) { return gradientEquals(a.grad, b.grad); }

// Returns true if two properties equal each other
bool propertyEquals(Property a, Property b) {
	return (a.curvatureEquals(b) && a.gradientEquals(b));
}

// Returns the stronger (i.e. the one having more information) curvature out of two equal ones
Curvature stronger(Curvature a, Curvature b)
in {
	assert (a.curvatureEquals(b));
}
body {
	return (a >= b) ? a : b;
}

// Returns the weaker curvature out of two equal ones
Curvature weaker(Curvature a, Curvature b)
in {
	assert (a.curvatureEquals(b));
}
body {
	return (a <= b) ? a : b;
}

// Returns the stronger gradient out of two equal ones
Gradient stronger(Gradient a, Gradient b)
in {
	assert (a.gradientEquals(b));
}
body {
	return (a >= b) ? a : b;
}

// Returns the weaker gradient out of two equal ones
Gradient weaker(Gradient a, Gradient b)
in {
	assert (a.gradientEquals(b));
}
body {
	return (a <= b) ? a : b;
}
