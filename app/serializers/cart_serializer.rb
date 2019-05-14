# frozen_string_literal: true

class CartSerializer < ActiveModel::Serializer
  has_many :items
  has_many :discounts
end
