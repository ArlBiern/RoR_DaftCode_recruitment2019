# frozen_string_literal: true

module Carts
  class DiscountsController < ApplicationController
    def create
      cart.discounts.create!(discount_params)
      render json: cart
    end

    def update
      discount.update!(discount_params)

      render json: cart
    end

    private

    def cart
      @cart ||= Cart.first
    end

    def discount_params
      params.permit(:name, :kind, :price, :count, product_ids: [])
    end

    def discount
      @discount ||= Discount.find(params[:id])
    end
  end
end
