// Function properties
enum Curvature { concave, convex, linear, unspecified }
enum Gradient { increasing, decreasing, constant, unspecified }

// A tuple, describing both properties of a given expression
import std.typecons : Tuple;
alias Property = Tuple!(Curvature, "curv", Gradient, "grad");

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
bool isNonDecreasing(Property p) { return isNonDecreasing(p.gradient); }
bool isNonIncreasing(Property p) { return isNonIncreasing(p.gradient); }
bool isConvex(Property p) { return isConvex(p.curv); }
bool isConcave(Property p) { return isConcave(p.curv); }
