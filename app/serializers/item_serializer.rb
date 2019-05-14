# frozen_string_literal: true

class ItemSerializer < ActiveModel::Serializer
  belongs_to :product

  attributes :id, :quantity, :product
end
