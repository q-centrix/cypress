# gems
require 'aasm'
require 'devise'
require 'devise/orm/mongoid'
require 'carrierwave'
require 'carrierwave/mongoid'
require 'health-data-standards'
require 'health-data-standards/hqmf-parser'
require 'quality-measure-engine'

module Cypress
  Bundle = HealthDataStandards::CQM::Bundle
end

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
  './validators/qrda_cat1_validator.rb',
  './validators/qrda_cat3_validator.rb',
  './validators/expected_results_validator.rb',
  './validators/measure_period_validator.rb',

  # product tests
  '../app/models/product.rb',
  '../app/models/product_test.rb',
  '../app/models/vendor.rb',
  '../app/models/user.rb',
  '../app/models/note.rb',
  '../app/models/patient_population.rb',
  '../app/models/calculated_product_test.rb',
  '../app/models/inpatient_product_test.rb',
  '../app/models/qrda_product_test.rb',

  # execution
  '../app/models/test_execution.rb',
  '../app/uploaders/document_uploader.rb',
  '../app/models/artifact.rb',
  '../app/models/execution_error.rb',

  # monkey patches :(
  './ext/measure.rb'
].each { |relative_path| load_external_validation_dependency(relative_path) }

Measure = Cypress::Measure
QRDAProductTest = Cypress::QRDAProductTest
InpatientProductTest = Cypress::InpatientProductTest
module Validators
  include Cypress::Validators
end

# load HQMF from health-data-standards' lib folder
Gem.find_files('hqmf-parser.rb').each { |f| require f }

APP_CONFIG = {
  'file_upload_root' => File.absolute_path('./tmp'),
  'effective_date'   => {
    'year' => '2013'
  }
}
