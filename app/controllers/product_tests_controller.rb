class ProductTestsController < ApplicationController

  def new
    @product = Product.find(params[:product_id])
    @vendor = @product.vendor
    @product_test = @product.product_tests.build
  end

end