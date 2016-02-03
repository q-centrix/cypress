FactoryGirl.define do
  factory :external_validation_product, class: Cypress::Product do
    user_ids  { [FactoryGirl.create(:external_validation_user).id] }
    vendor_id { FactoryGirl.create(:external_validation_vendor).id }

    name 'Dat App'
    version ''
    description ''
  end

  factory :product_1 do
    name "Vendor 1 Product 1"
    description "first product"
    user  { Factory(:bobby) }
  end

  factory :second do
    user  { Factory(:bobby) }
    description    "second product"
    name    "vendor2 product1"
    vendor_id    "4f636aba1d41c851eb00048c"
  end

  factory :passing do
    user  { Factory(:bobby) }
    description    "passing"
    name    "vendor1 product2"
  end

end
