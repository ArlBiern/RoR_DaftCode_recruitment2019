# frozen_string_literal: true

class DiscountSerializer < ActiveModel::Serializer
  attributes :id, :name, :kind, :product_ids
  attribute :price, if: :set_type?
  attribute :count, if: :extra_type?

  def set_type?
    object.kind == 'set'
  end

  def extra_type?
    object.kind == 'extra'
  end
end
