# frozen_string_literal: true

module Carts
  class ItemsController < ApplicationController
    def create
      if quantity_check
        render json: { message: 'Quantity should be at least 1' }, status: 400
      else
        data_validation
      end
    end

    def update
      if quantity_check
        item.destroy!
      else
        item.update!(item_params_update)
      end

      render json: cart
    end

    def destroy
      item.destroy!
    end

    private

    def cart
      @cart ||= Cart.first
    end

    def item
      @item ||= Item.find(params[:id])
    end

    def item_params_update
      params.permit(:quantity)
    end

    def item_params_create
      params.permit(:quantity, :product_id)
    end

    def quantity_check
      params[:quantity].zero?
    end

    def data_validation
      products_id = cart.items.map(&:product_id)
      if products_id.include? params[:product_id]
        item = Item.where(product_id: params[:product_id])
        item.update(quantity: item[0][:quantity] + params[:quantity])
        render json: item
      else
        cart.items.create!(item_params_create)
        render json: cart, status: 201
      end
    end
  end
end
