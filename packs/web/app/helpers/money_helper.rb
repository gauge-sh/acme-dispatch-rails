module MoneyHelper
  # All domain money is integer cents; only the view layer turns it into
  # dollars-and-cents strings.
  def cents(amount_cents)
    number_to_currency(amount_cents / 100.0)
  end
end
