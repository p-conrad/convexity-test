/// Function attributes
enum Curvature { unspecified, concave, convex, linear }
enum Monotonicity { unspecified, nondecreasing, nonincreasing, constant }

import std.typecons : Tuple;
/// A tuple having both attributes of a given expression
alias Result = Tuple!(Curvature, "curv", Monotonicity, "mono");

/// the "unknown" result to be returned when a certain case can not be handled by a rule
enum unknownResult = Result(Curvature.unspecified, Monotonicity.unspecified);

// Check for some properties of the Monotonicity or Curvature
bool isNonDecreasing(Monotonicity m) { return (m == Monotonicity.nondecreasing || m == Monotonicity.constant); }
bool isNonIncreasing(Monotonicity m) { return (m == Monotonicity.nonincreasing || m == Monotonicity.constant); }
bool isConstant(Monotonicity m) { return m == Monotonicity.constant; }
bool isConvex(Curvature c) { return (c == Curvature.convex || c == Curvature.linear); }
bool isConcave(Curvature c) { return (c == Curvature.concave || c == Curvature.linear); }
bool isLinear(Curvature c) { return c == Curvature.linear; }

bool isNonDecreasing(Result r) { return isNonDecreasing(r.mono); }
bool isNonIncreasing(Result r) { return isNonIncreasing(r.mono); }
bool isConstant(Result r) { return isConstant(r.mono); }
bool isConvex(Result r) { return isConvex(r.curv); }
bool isConcave(Result r) { return isConcave(r.curv); }
bool isLinear(Result r) { return isLinear(r.curv); }

/// Curvature complements
enum Curvature[Curvature] cComplement = [
	Curvature.concave		:	Curvature.convex,
	Curvature.convex		:	Curvature.concave,
	Curvature.linear		:	Curvature.linear,
	Curvature.unspecified	:	Curvature.unspecified
];

/// Monotonicity complements
enum Monotonicity[Monotonicity] mComplement = [
	Monotonicity.nondecreasing	:	Monotonicity.nonincreasing,
	Monotonicity.nonincreasing	:	Monotonicity.nondecreasing,
	Monotonicity.constant		:	Monotonicity.constant,
	Monotonicity.unspecified	:	Monotonicity.unspecified
];

/// Returns: the complement of a Result according to the rules specified above
Result complement(Result r) {
	return Result(cComplement[r.curv], mComplement[r.mono]);
}

/// Returns: the single complement of either a Curvature or a Monotonicity
Curvature complement(Curvature c) { return cComplement[c]; }
Monotonicity complement(Monotonicity m) { return mComplement[m]; }

/// Returns: true if two curvatures equal each other
bool curvatureEquals(Curvature a, Curvature b) {
	return (a.isConvex && b.isConvex || a.isConcave && b.isConcave);
}

/// Returns: true if two monotonocities equal each other
bool monotonicityEquals(Monotonicity a, Monotonicity b) {
	return (a.isNonIncreasing && b.isNonIncreasing || a.isNonDecreasing && b.isNonDecreasing);
}

bool curvatureEquals(Result a, Result b) { return curvatureEquals(a.curv, b.curv); }
bool monotonicityEquals(Result a, Result b) { return monotonicityEquals(a.mono, b.mono); }

/// Returns: true if two results equal each other
bool resultEquals(Result a, Result b) {
	return (a.curvatureEquals(b) && a.monotonicityEquals(b));
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

/// Returns: the stronger monotonicity out of two
/// When an nondecreasing and a nonincreasing monotonicity are given the result is assumed to be constant
Monotonicity stronger(Monotonicity a, Monotonicity b) {
	if (a.isNonDecreasing && b.isNonIncreasing || a.isNonIncreasing && b.isNonDecreasing) return Monotonicity.constant;
	return (a >= b) ? a : b;
}

/// Returns: the weaker monotonicity out of two
/// When an nondecreasing and a nonincreasing monotonicity are given the result will be unspecified
Monotonicity weaker(Monotonicity a, Monotonicity b) {
	if ((!a.isConstant && ! b.isConstant) && (a.isNonDecreasing && b.isNonIncreasing || a.isNonIncreasing && b.isNonDecreasing))
		return Monotonicity.unspecified;
	return (a <= b) ? a : b;
}

/// Returns: the stronger Result out of two
Result stronger(Result a, Result b) {
	return Result(stronger(a.curv, b.curv), stronger(a.mono, b.mono));
}

/// Returns: the weaker Result out of two
Result weaker(Result a, Result b) {
	return Result(weaker(a.curv, b.curv), weaker(a.mono, b.mono));
}
