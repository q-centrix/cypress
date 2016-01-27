# gems
require 'aasm'
require 'carrierwave'
require 'carrierwave/mongoid'
require 'health-data-standards'
require 'quality-measure-engine'

module Cypress; end
module Validators; end

def load_into_cypress_namespace(absolute_path)
  Cypress.module_eval File.read(absolute_path)
end

def absolute_cypress_path(relative_path)
  File.expand_path(relative_path, File.dirname(__FILE__))
end

def load_external_validation_dependency(relative_path)
  load_into_cypress_namespace(absolute_cypress_path(relative_path))
end

[
  # validators
  './validators/validator.rb',
  './validators/smoking_gun_validator.rb',
  './cypress/qrda_file_constants.rb',
  './validators/qrda_file_validator.rb',

  # product tests
  '../app/models/product.rb',
  '../app/models/product_test.rb',
  '../app/models/calculated_product_test.rb',
  '../app/models/inpatient_product_test.rb',
  '../app/models/qrda_product_test.rb',

  # execution
  '../app/models/test_execution.rb',
  '../app/uploaders/document_uploader.rb',
  '../app/models/artifact.rb',
  '../app/models/execution_error.rb'
].each { |relative_path| load_external_validation_dependency(relative_path) }
