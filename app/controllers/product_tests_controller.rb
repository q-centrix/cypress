class ProductTestsController < ApplicationController
  before_action :set_vendor_and_product, only: [:new, :create]

  def new
    @product_test = @product.product_tests.build
  end

  def create
    @product_test = ProductTest.new(product_test_params)
    @product_test.product = @product
    @product_test.name = Measure.top_level.where(hqmf_id: @product_test.measure_id).first.name
    # v v v DO NOT USE IN FINAL VERSION v v v #
    @product_test.bundle_id = Bundle.first.id
    @product_test.effective_date = 1
    # ^ ^ ^ DO NOT USE IN FINAL VERSION ^ ^ ^ #
    @product_test.save!
    flash_product_test_comment(@product_test, 'success', 'created')
    respond_to do |f|
      f.json {} # <-- must be fixed later
      f.html { redirect_to vendor_product_path(@vendor, @product) }
    end
  rescue Mongoid::Errors::Validations
    render :new
  end

  private

  def set_vendor_and_product
    @product = Product.find(params[:product_id])
    @vendor = @product.vendor
  end

  def product_test_params
    params[:product_test].permit(:name, :measure_id, :state)
  end

  def flash_product_test_comment(product_test_name, notice_type, action_type)
    flash[:notice] = "Product Test '#{product_test_name}' was #{action_type}."
    flash[:notice_type] = notice_type
  end
end
