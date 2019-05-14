# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :items, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
