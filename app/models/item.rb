# frozen_string_literal: true

class Item < ApplicationRecord
  belongs_to :cart, optional: true
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product, presence: true
end
