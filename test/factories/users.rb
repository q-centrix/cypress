FactoryGirl.define do
  factory :external_validation_user, class: Cypress::User do
    product_ids []
    email { FFaker::Internet.email }
    encrypted_password 'supersecretencryptedpassword'
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    telephone ''
    reset_password_token 'supersecretresetpasswordtoken'
    remember_created_at nil
    sign_in_count 8
    current_sign_in_ip '192.168.1.1'
    last_sign_in_ip '192.168.1.1'
    admin true
    approved true
    staff_role nil
    disabled false
    failed_attempts 0
    locked_at nil
    password 'Passw0rd!'
    password_confirmation 'Passw0rd!'
    terms_and_conditions '1'
  end

  factory :bobby do
    first_name  "bobby"
    last_name  "tables"
    telephone "867-5309"
    email   "bobby@tables.org"
    # "product_ids":["4f6b77831d41c851eb0004a5""4f636ae01d41c851eb00048e""4f57a88a1d41c851eb000004"]
    #     product_test_ids :["4f6b78801d41c851eb0004a7""4f5a606b1d41c851eb000484""4f636b3f1d41c851eb000491""4f58f8de1d41c851eb000478"]
  end

end
