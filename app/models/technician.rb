class Technician < ApplicationRecord
  normalizes :name, with: ->(value) { value.strip }
  normalizes :phone, with: ->(value) { value.strip.presence }
  # Tags are a plain word list: lower-cased, deduplicated, stored sorted so
  # two technicians with the same skills serialize identically.
  normalizes :skill_tags, with: ->(tags) { Array(tags).filter_map { |tag| tag.to_s.strip.downcase.presence }.uniq.sort }

  validates :name, presence: true, length: { maximum: 120 }
  validates :phone, length: { in: 7..32 }, allow_nil: true
  validates :hourly_cost_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :skill_tags_fit

  private

  def skill_tags_fit
    return unless skill_tags.any? { |tag| tag.length > 40 }

    errors.add(:skill_tags, "tags must be at most 40 characters")
  end
end
