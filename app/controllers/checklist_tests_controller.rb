class ChecklistTestsController < ProductTestsController
  include HealthDataStandards::Export::Helper::ScoopedViewHelper

  before_action :set_product, only: [:create, :show, :update, :destroy]
  before_action :set_test, only: [:show, :update, :destroy]
  before_action :set_measures, only: [:show]

  def create
    # bundle ATTRIBUTE IS NOT CHOSEN CORRECTLY. MUST FIX LATER ~ JAEBIRD
    @product.product_tests.build({ name: 'c1 visual', measure_ids: all_measure_ids,
                                   bundle_id: @product.measure_tests.first.bundle_id }, ChecklistTest).save!
    create_checked_criteria
    redirect_to "/vendors/#{@product.vendor.id}/products/#{@product.id}"
  end

  def show
  end

  def update
    # set_status_no_if_both
    @test.update_attributes(checklist_test_params)
    @test.save!
    respond_to do |format|
      format.html { redirect_to "/products/#{@product.id}/checklist_tests/#{@test.id}" }
    end
  rescue Mongoid::Errors::Validations
    render :show
  end

  def destroy
    @test.destroy
    respond_to do |format|
      format.html { redirect_to "/vendors/#{@product.vendor.id}/products/#{@product.id}" }
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_test
    @test = @product.checklist_test
  end

  def set_measures
    @measures = all_measures
  end

  def all_measures
    Measure.top_level.where(:hqmf_id.in => all_measure_ids)
  end

  def all_measure_ids
    @product.measure_tests.map { |test| test.measure_ids.first }
  end

  # CHOOSE INTERESTING CRITERIA HERE - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
  def create_checked_criteria
    checked_criterias = []
    measures = all_measures.sort_by { rand }.first(5) # PROBABLY NOT HOW WE WANT TO PICK THESE ~ Jaebird
    measures.each do |measure|
      criterias = measure['hqmf_document']['source_data_criteria'].sort_by { rand }.first(5)
      criterias.each do |criteria_key, _criteria_value|
        checked_criterias.push(measure_id: measure.id.to_s, source_data_criteria: criteria_key, completed: false)
      end
    end
    test = @product.checklist_test
    test.checked_criteria = checked_criterias
    test.save!
  end

  def checklist_test_params
    params[:product_test].permit(checked_criteria_attributes: [:id, :_destroy, :completed])
  end

  # will probably remove function soon
  def set_status_no_if_both
    params[:product_test][:checked_criteria_attributes].values.each do |criteria|
      if criteria.key?('status') && criteria[:status].include?('yes') && criteria[:status].include?('no')
        criteria[:status].delete_if { |status| status == 'yes' }
      end
    end
  end
end
