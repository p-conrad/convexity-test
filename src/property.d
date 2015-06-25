// Function properties
enum Curvature { concave, convex, linear, unspecified }
enum Gradient { increasing, decreasing, constant, unspecified }

// A tuple, describing both properties of a given expression
import std.typecons : Tuple;
alias Property = Tuple!(Curvature, "curv", Gradient, "grad");

// Check for some properties of the Gradient or Curvature
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

// wrapper functions
bool isNonDecreasing(Property p) { return isNonDecreasing(p.grad); }
bool isNonIncreasing(Property p) { return isNonIncreasing(p.grad); }
bool isConvex(Property p) { return isConvex(p.curv); }
bool isConcave(Property p) { return isConcave(p.curv); }

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
