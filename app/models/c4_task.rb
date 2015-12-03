class C4Task < Task

  def after_create
    # generate expected results here.  Will need to gen quailty report
    # for each of the measures in the product_test but constrainted to the
    # filter provided for test.  Filter data should live in the options field
    # that is defined in Task
    MeasureEvaluationJob.perform_now(self, 'filters' => patient_cache_filter)
  end

  def execute(_params)
  end

  # Final Rule defines 9 different criteria that can be filtered:
  #
  # (A) TIN .................... (F) Age
  # (B) NPI .................... (G) Sex
  # (C) Provider Type .......... (H) Race + Ethnicity
  # (D) Practice Site Address .. (I) Problem
  # (E) Patient Insurance
  #
  def patient_cache_filter
    input_filters = (options['filters'] || {}).dup
    filters = {}

    # QME can handle races, ethnicities, genders, (providers, languages) and patient_ids
    # so pass these through directly
    # is it really worth it to do this? does it make more sense to just do everything based on patient id
    # and simplify the logic here

    filters['races'] = input_filters.delete 'races' if input_filters['races']
    filters['ethnicities'] = input_filters.delete 'ethnicities' if input_filters['ethnicities']
    filters['genders'] = input_filters.delete 'genders' if input_filters['genders']

    # for the rest, manually filter to get the record IDs and pass those in
    if input_filters.count > 0
      filters['patients'] = Cypress::RecordFilter.filter(product_test.records, input_filters, effective_date: product_test.effective_date).pluck(:_id)
    end

    filters
  end

  # this will fetch the records associted with the product test but constrained
  # according to the filters configured for the task
  def records
    Cypress::RecordFilter.filter(product_test.records, options['filters'], effective_date: product_test.effective_date)
  end

  def partial_name
    self.model_name.name.underscore
  end
end
