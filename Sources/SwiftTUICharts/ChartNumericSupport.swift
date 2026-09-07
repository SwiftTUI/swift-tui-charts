/// A finite fraction, including domains whose finite endpoints have an infinite difference.
func chartUnitFraction(_ value: Double, in domain: ClosedRange<Double>) -> Double {
  let lower = domain.lowerBound
  let upper = domain.upperBound
  guard value.isFinite, lower.isFinite, upper.isFinite, upper > lower else { return 0 }
  if value <= lower { return 0 }
  if value >= upper { return 1 }
  let span = upper - lower
  if span.isFinite { return (value - lower) / span }
  let scale = max(abs(lower), abs(upper))
  return (value / scale - lower / scale) / (upper / scale - lower / scale)
}

func chartInterpolatedValue(_ fraction: Double, in domain: ClosedRange<Double>) -> Double {
  guard fraction.isFinite, domain.lowerBound.isFinite, domain.upperBound.isFinite else { return 0 }
  if fraction <= 0 { return domain.lowerBound }
  if fraction >= 1 { return domain.upperBound }
  let span = domain.upperBound - domain.lowerBound
  if span.isFinite { return domain.lowerBound + fraction * span }
  return domain.lowerBound * (1 - fraction) + domain.upperBound * fraction
}

func chartCellOffset(
  _ fraction: Double, maximum: Int, rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
) -> Int {
  guard maximum > 0, fraction.isFinite, fraction > 0 else { return 0 }
  if fraction >= 1 { return maximum }
  let rounded = (fraction * Double(maximum)).rounded(rounding)
  return min(maximum, Int(exactly: rounded) ?? maximum)
}
