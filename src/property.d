/// Function properties
enum Curvature { unspecified, concave, convex, linear }
enum Gradient { unspecified, nondecreasing, nonincreasing, constant }

import std.typecons : Tuple;
/// A tuple containing both properties of a given expression
alias Property = Tuple!(Curvature, "curv", Gradient, "grad");

/// the "unknown" result to be returned when a certain case can not be handled by a rule
enum unknownResult = Property(Curvature.unspecified, Gradient.unspecified);

// Check for some properties of the Gradient or Curvature
bool isNonDecreasing(Gradient g) { return (g == Gradient.nondecreasing || g == Gradient.constant); }
bool isNonIncreasing(Gradient g) { return (g == Gradient.nonincreasing || g == Gradient.constant); }
bool isConstant(Gradient g) { return g == Gradient.constant; }
bool isConvex(Curvature c) { return (c == Curvature.convex || c == Curvature.linear); }
bool isConcave(Curvature c) { return (c == Curvature.concave || c == Curvature.linear); }
bool isLinear(Curvature c) { return c == Curvature.linear; }

bool isNonDecreasing(Property p) { return isNonDecreasing(p.grad); }
bool isNonIncreasing(Property p) { return isNonIncreasing(p.grad); }
bool isConstant(Property p) { return isConstant(p.grad); }
bool isConvex(Property p) { return isConvex(p.curv); }
bool isConcave(Property p) { return isConcave(p.curv); }
bool isLinear(Property p) { return isLinear(p.curv); }

/// Curvature complements
enum Curvature[Curvature] cComplement = [
	Curvature.concave		:	Curvature.convex,
	Curvature.convex		:	Curvature.concave,
	Curvature.linear		:	Curvature.linear,
	Curvature.unspecified	:	Curvature.unspecified
];

/// Gradient complements
enum Gradient[Gradient] gComplement = [
	Gradient.nondecreasing	:	Gradient.nonincreasing,
	Gradient.nonincreasing	:	Gradient.nondecreasing,
	Gradient.constant		:	Gradient.constant,
	Gradient.unspecified	:	Gradient.unspecified
];

/// Returns: the complement of a Property according to the rules specified above
Property complement(Property p) {
	return Property(cComplement[p.curv], gComplement[p.grad]);
}

/// Returns: the single complement of either a Curvature or a Gradient
Curvature complement(Curvature c) { return cComplement[c]; }
Gradient complement(Gradient g) { return gComplement[g]; }

/// Returns: true if two curvatures equal each other
bool curvatureEquals(Curvature a, Curvature b) {
	return (a.isConvex && b.isConvex || a.isConcave && b.isConcave);
}

/// Returns: true if two gradients equal each other
bool gradientEquals(Gradient a, Gradient b) {
	return (a.isNonIncreasing && b.isNonIncreasing || a.isNonDecreasing && b.isNonDecreasing);
}

bool curvatureEquals(Property a, Property b) { return curvatureEquals(a.curv, b.curv); }
bool gradientEquals(Property a, Property b) { return gradientEquals(a.grad, b.grad); }

/// Returns: true if two properties equal each other
bool propertyEquals(Property a, Property b) {
	return (a.curvatureEquals(b) && a.gradientEquals(b));
}

/// Returns: the stronger (i.e. the one having more information) curvature out of two
/// When a concave and a convex curvature are given the result is assumed to be linear
Curvature stronger(Curvature a, Curvature b) {
	if (a.isConcave && b.isConvex || a.isConvex && b.isConcave) return Curvature.linear;
	return (a >= b) ? a : b;
}

/// Returns: the weaker curvature out of two
/// When a concave and a convex curvature are given the result will be unspecified
Curvature weaker(Curvature a, Curvature b) {
	if ((!a.isLinear && !b.isLinear) && (a.isConcave && b.isConvex || a.isConvex && b.isConcave))
		return Curvature.unspecified;
	return (a <= b) ? a : b;
}

/// Returns: the stronger gradient out of two
/// When an nondecreasing and a nonincreasing gradient are given the result is assumed to be constant
Gradient stronger(Gradient a, Gradient b) {
	if (a.isNonDecreasing && b.isNonIncreasing || a.isNonIncreasing && b.isNonDecreasing) return Gradient.constant;
	return (a >= b) ? a : b;
}

/// Returns: the weaker gradient out of two
/// When an nondecreasing and a nonincreasing gradient are given the result will be unspecified
Gradient weaker(Gradient a, Gradient b) {
	if ((!a.isConstant && ! b.isConstant) && (a.isNonDecreasing && b.isNonIncreasing || a.isNonIncreasing && b.isNonDecreasing))
		return Gradient.unspecified;
	return (a <= b) ? a : b;
}

/// Returns: the stronger Property out of two
Property stronger(Property a, Property b) {
	return Property(stronger(a.curv, b.curv), stronger(a.grad, b.grad));
}

/// Returns: the weaker Property out of two
Property weaker(Property a, Property b) {
	return Property(weaker(a.curv, b.curv), weaker(a.grad, b.grad));
}
