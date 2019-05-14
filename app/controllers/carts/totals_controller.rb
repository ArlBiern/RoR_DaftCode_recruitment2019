# frozen_string_literal: true

module Carts
  class TotalsController < ApplicationController
    def show
      render json: final_output.to_json
    end

    private

    # ==== GENERAL ====
    def cart
      @cart ||= Cart.first
    end

    # ==== PRODUCTS METHODS ====

    # Getting all products including repetitions
    def ordered_products_total_arr
      ordered_products_arr = cart.items.map { |item| item[:product_id] }
      ordered_products_arr.map { |id| [id] * Item.where(product_id: id)[0].quantity }.flatten
    end

    # ==== DISCOUNTS METHODS ====

    # Array of all "set" discounts
    def set_discounts_arr
      cart.discounts.where(kind: 'set').map { |set| set[:product_ids].push(set[:id].to_s + 's') }
    end

    # Array of all "set" discounts
    def extra_discounts_arr
      extras = cart.discounts.where(kind: 'extra').map do |extra|
        extra[:product_ids].each_slice(1).map { |e| (e * extra[:count]).push(extra[:id].to_s + 'e') }
      end
      extras.flatten(1)
    end

    # Veryfication whether discount can be used
    def discount_veryfication(arr1, arr2, nbr)
      (arr1 & arr2).flat_map { |n| [n] * [arr1.count(n), arr2.count(n)].min }.length == (arr1.length - nbr)
    end

    # Array of possible discounts (in terms of products list)
    def possible_discounts
      possible_discounts = []
      discounts_all = set_discounts_arr + extra_discounts_arr
      discounts_all.map do |discount|
        next unless discount_veryfication(discount, ordered_products_total_arr, 1)

        discount_ids = discount[0..discount.length - 2]
        product_ids = ordered_products_total_arr
        result = discount_count(discount_ids, product_ids)
        for i in 1..result[1] do
          possible_discounts.push(discount)
        end
      end
      possible_discounts
    end

    # ==== OPTIMUM DISCOUNT ====

    # Price calculation of products ids array
    def regular_price(arr)
      arr.map { |id| Product.find(id).price }.sum
    end

    # Calculation how many times given discount can be used
    def discount_count(arr1, arr2)
      count = 0
      loop do
        arr1.map { |e| arr2.delete_at(arr2.index(e)) }
        count += 1
        break unless discount_veryfication(arr1, arr2, 0)
      end
      [arr2, count]
    end

    # Main function defining all possible discount usage
    def order_options_calculation
      options = possible_discounts.permutation.to_a.uniq
      option_result = []

      options.map do |discount_set|
        set_discounts_used = []
        extra_discounts_used = []
        extra_products = []
        discount_price = 0
        products_all = ordered_products_total_arr

        discount_set.map do |discount|
          discount_products = discount[0..discount.length - 2]
          discount_info = discount.last
          discount_id = discount_info.slice(0, discount_info.length - 1)

          while discount_veryfication(discount_products, products_all, 0)
            if discount_info.last == 'e'
              extra_products.push(discount[0])
              extra_discounts_used.push(discount)
              discount_price += (Product.where(id: discount[0])[0][:price] * (discount.length - 1))
            elsif discount_info.last == 's'
              discount_price += Discount.where(id: discount_id)[0][:price]
              set_discounts_used.push(discount)
            end

            discount_products.map do |product|
              products_all.delete_at(products_all.index(product))
            end
          end
        end
        normal_price = regular_price(products_all)
        total_price = (discount_price + normal_price).round(2)
        option_result.push([set_discounts_used, extra_discounts_used, products_all, extra_products, total_price])
      end
      option_result
    end

    # Defining cheapest option of cart products
    def optimum_discount
      options = order_options_calculation
      prices = options.map(&:last)
      index = prices.index(prices.min)
      options[index]
    end

    # Discount summarize
    def print_discount(arr)
      arr.map do |e|
        discount = Discount.where(id: e.last.slice(0, e.length - 1))[0]
        if discount[:kind] == 'set'
          products = print_products(discount[:product_ids])
        else
          products = print_products(discount[:product_ids]) * discount[:count]
        end
        {
          'name': discount[:name],
          'products': products
        }
      end
    end

    # Product summarize
    def print_products(arr)
      arr.map { |product_id| Product.where(id: product_id)[0][:name] }
    end

    # Response for render in show action
    def final_output
      data = optimum_discount
      {
        'sets': print_discount(data[0]),
        'extras': print_discount(data[1]),
        'product without discount': print_products(data[2]),
        'product for free': print_products(data[3]),
        'regular price': regular_price(ordered_products_total_arr),
        'dicount price': data[4]
      }
    end
  end
end
