# frozen_string_literal: true

class Discount < ApplicationRecord
  KINDS = %w[set extra].freeze
  belongs_to :cart

  validates :name, presence: true, uniqueness: true
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :product_ids, presence: true

  validate :product_presence
  validate :set_check
  validate :extra_check

  private

  def product_presence
    all_products_ids = Product.all.map { |product| product[:id] }
    difference = product_ids - all_products_ids
    return unless difference != []
    errors.add(:product_ids, :invalid, message: "products with id('s) #{difference} are not available")
  end

  def set_check
    if kind == 'set' && product_ids.length < 2
      errors.add(:product_ids, :invalid, message: 'set discount should have at least two prducts')
    elsif kind == 'set' && count != 0
      errors.add(:count, :invalid, message: 'in set discount count should be equal to zero')
    elsif kind == 'set' && price.zero?
      errors.add(:price, :invalid, message: 'please check price, it should not be equal to zero')
    end
  end

  def extra_check
    if kind == 'extra' && count.zero?
      errors.add(:count, :invalid, message: 'please check count, it should not be equal to zero')
    elsif kind == 'extra' && price != 0
      errors.add(:price, :invalid, message: 'in extra discount price should be equal to zero')
    end
  end
end
