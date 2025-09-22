module Dispatch
  module Money
    # Round to a whole cent, halves away from zero. Kernel#round defaults to
    # banker's rounding on ties and floats can land a hair under the half, so
    # everything goes through an exact Rational first: 2666.5 must become
    # 2667, and -0.5 must become -1.
    def self.round_cents(amount)
      amount.to_r.round(half: :up)
    end
  end
end
