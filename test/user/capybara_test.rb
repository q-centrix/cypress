require 'test_helper'
require 'capybara'
require 'capybara-webkit'
require 'capybara/poltergeist'
require 'show_me_the_cookies'
require 'capybara/rails'
require 'rake'
#require 'capybara/accessible'

## Test suite using Capybara to simulate user actions.
## This set of tests is intended to perform the same tests as
## measure_evaluation_validator.rb , but via the frontend
##
## 
## OPEN QUESTIONS/ISSUES/CONCERNS:
##  - File download doesn't work using Poltergeist driver
##    * Workaround: use curl
##  - File upload doesn't work on our current page
##    * Workaround: use curl
##
##  - Concern: will curl be available if running on CI server?
##    Looks like it is on Travis, not sure if we use anything else
##
##
##  - Currently doesn't work using test fixture data and doing things the "right way",
##    "Create Test" page doesn't load correctly.
##     - It does work with the real data though
##     - Workaround is to manually add the necessary data to the DB.
##     - See run_delayed_job
##
##  - Do we want to test all measures or just a [randomly?]
##    selected subset? I don't think testing all measures
##    adds much value when using mock data (fixtures).
##
##  - Relies on cat_3_calculator.rb to process cat3s.
##    It works ok with real bundles loaded but not sure about test data.
##    - As of latest, it just uploads a cat 3 file from fixtures.
##      It won't pass validation for various reasons but it gets us through the navigation.
##
##  - Need to add assertions/validation. Currently the navigation serves
##    as the only verification that things are working
##
##  - Some kind of caching issue: randomly the tests will fail at a very simple step
##    because the page is missing something that was just added.
##    For instance, on the vendor page, adding a product, then going back to the vendor page,
##    and the new product that was just added isn't there, the page says "No products for this vendor"
##    - Analysis so far, I think it's actually Rails caching the page or partial, 
##      even though it isn't supposed to. I added a print statement in the page, so
##      when it renders I see that in the log. On successful runs, I see it twice, but
##      when it fails I only see it once. The rails log also shows some differences
##      between successful and failed runs. 
##    - If we can't figure out why it's not working, the only workaround I've seen
##      is to force reset the session, which requires it to then log back in again.
##      Navigating to another page then back might work but not guaranteed.
##    - Another possible clue, running this via "rake test" fails much more frequently
##      with this caching error than when running it by itself "ruby -I test test/user/capybara_test.rb"
##



class CapybaraTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
  include ShowMeTheCookies


  # setup runs before each test case, not just once per file
  setup do

    # starts the server when necessary
    Capybara.run_server = true

    # wait longer for page to finish loading, default is 2 I think
    Capybara.default_max_wait_time = 5

    
    ## uncomment these and remove the regular poltergeist
    ## when ready for accessibility testing
    
    # Capybara.default_driver = :accessible_poltergeist
    # Capybara.javascript_driver = :accessible_poltergeist

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, :timeout => 5000 )
         #  for debugging add:     :debug => true , :inspector => true
    end

    Capybara.default_driver = :poltergeist


    ## make sure there is no proxy in the way for this test; we're connecting to localhost
    ENV['HTTP_PROXY'] = ENV['http_proxy'] = nil

    ## allow connections to be made to the local running test server
    WebMock.disable_net_connect!(:allow_localhost => true)



    dump_database

    load_code_sets

    collection_fixtures('query_cache', 'test_id')
    collection_fixtures('bundles', '_id')
    collection_fixtures('measures',"_id",'bundle_id')
    #collection_fixtures('products','_id','vendor_id')
    collection_fixtures('records', '_id','test_id','bundle_id')
    #collection_fixtures('product_tests', '_id','bundle_id')
    collection_fixtures('patient_populations', '_id')
    #collection_fixtures('test_executions', '_id')
    collection_fixtures2('patient_cache','value', '_id' ,'test_id','bundle_id')
    collection_fixtures('users', '_id')
    #collection_fixtures('vendors', '_id')

    Mongoid.default_session['product_tests'].drop
    Mongoid.default_session['products'].drop
    Mongoid.default_session['vendors'].drop


    
      
    # do we want these to be randomized or constant?
    @vendor_name = "MeasureEvaluationVendor"
    @product_name = "MeasureEvaluationProduct"



    @test_links = Hash.new
    @test_measures = []

    puts "start test"
  end


  teardown do
    # reset = logout/clear cookies
    Capybara.reset_sessions!

    puts "done test"
  end



#################################
##### TEST CASES
#################################

  ## Generates cat3 tests as single tests, then generates a cat1 test for each,
  ## then downloads a Cat1 zip and uploads it to Cypress
  test 'evaluate cat1' do

    login("bobby@tables.org" , "Password!")

    assert page.html.include? 'Signed in successfully.'

    create_vendor(@vendor_name)
    create_product(@product_name)

    create_cat3_tests
    run_delayed_jobs
    create_cat1_tests


    hack_fix_cat1_tests

    execute_cat1_tests
  end

  # Runs all the single-measure QRDA Cat 3 tests
  test 'evaluate cat3 single measures' do

    login("bobby@tables.org" , "Password!")

    assert page.html.include? 'Signed in successfully.'

    create_vendor(@vendor_name)
    create_product(@product_name)

    create_cat3_tests
    run_delayed_jobs

    execute_cat3_tests
  end

  # Runs multi-measure QRDA Cat 3 tests
  test 'evaluate cat3 multi measures' do

    login("bobby@tables.org" , "Password!")

    assert page.html.include? 'Signed in successfully.'

    create_vendor(@vendor_name)
    create_product(@product_name)

    # TODO - make this number based on something
    # right now it picks 3 random measures per test
    create_cat3_tests_multi_measure(3)
    run_delayed_jobs

    execute_cat3_tests
  end



  ## other tests we want here?
  ##  my thoughts
  # - failed login
  # - something on account page
  # - things on master patient list page


#################################
##### HELPER & NAVIGATION METHODS
#################################


  def visit_homepage
    visit '/'
  end



  def login(email, password)
    visit_homepage

    fill_in("user_email", with: email)
    fill_in("user_password", with: password)

    click_on('Login')
  end




  def create_vendor(vendor_name)
    visit_homepage

    click_link "Add EHR Vendor"
    fill_in("vendor_name", with: vendor_name)
    click_on "Create"

    click_on vendor_name
  end


  def create_product(product_name)
    start_html = page.html
    click_link("Add Product", match: :first)

    fill_in("product_name", with: product_name)
    click_on "Create"

    # if page.html.include? "There are no products for this vendor"
    #   click_link("Add Product", match: :first)

    #   fill_in("product_name", with: "dummy second product why is this necessary")
    #   click_on "Create"
    # end
    # for some reason the page sometimes loads and says "There are no products for this vendor"
    # need to look into why that is happening
    # if you try to create it a second time, when the page loads you get 2 of the same product name
    finish_html = page.html

    begin
      click_on product_name
    rescue
      puts start_html
      puts finish_html
      raise
    end
  end





  def create_cat3_tests

    @test_categories = Hash.new

    i = 0
    test_hqmf, test_name = create_test("EP", i)
    @test_links[test_name] = test_hqmf


    #puts page.html

    # while test_hqmf
    #   i += 1
    #   @test_links[test_name] = test_hqmf
    #   test_hqmf, test_name = create_test("EP", i)
    # end

    @test_categories = Hash.new

    #The test measure picker loads the measures via AJAX (for some reason)
    #So we have to wait for these to load
    #wait_for_ajax


    #click_link @product_name

    i += 1
    test_hqmf, test_name = create_test("EH", i)
    @test_links[test_name] = test_hqmf
    # while test_hqmf
    #   i += 1
    #   @test_links[test_name] = test_hqmf
    #   test_hqmf, test_name = create_test("EH", i)
    # end
  end


#TODO - want to combine these different functions into single functions
# with a param to differentiate

  def create_cat3_tests_multi_measure(measures_per_test)
    
    @test_categories = Hash.new

    i = 0
    test_hqmf, test_name = create_test_multi_measure("EP", i, measures_per_test)
    @test_links[test_name] = test_hqmf


    #puts page.html

    # while test_hqmf
    #   i += 1
    #   @test_links[test_name] = test_hqmf
    #   test_hqmf, test_name = create_test("EP", i)
    # end

    @test_categories = Hash.new

    #The test measure picker loads the measures via AJAX (for some reason)
    #So we have to wait for these to load
   # wait_for_ajax


   # click_link @product_name

    i += 1
    test_hqmf, test_name = create_test_multi_measure("EH", i, measures_per_test)
    @test_links[test_name] = test_hqmf
    # while test_hqmf
    #   i += 1
    #   @test_links[test_name] = test_hqmf
    #   test_hqmf, test_name = create_test("EH", i)
    # end
  end



  def create_cat1_tests
    visit_homepage
    click_link @vendor_name
    click_link @product_name

    @test_links.each do |test_name, hqmf|
      click_link test_name
      click_link "Generate"
    end
  end



  # These tests are expected to be able to run on a CI server
  # where the delayed jobs won't actually be running,
  # so we need to manually "run" the jobs here
  def run_delayed_jobs
    visit_homepage
    click_link @vendor_name
    click_link @product_name
    wait_for_ajax
    #puts page.html

    @test_links.each do |test_name, hqmf|

      #begin

        link = find_link('a', :text => /\A#{test_name}\z/i)
        test_id = link['href'].split("/").last
      # rescue
      #   puts page.html
      #   abort("bad page")
      # end

      run_delayed_job(test_id)
    end

  end

  def run_delayed_job(test_id)

    #puts "running delayed job for test id #{test_id}"

    ## with this fixture data, who knows what we will get if we run the real job
    ## so at least to start, we'll fake running the job by manually performing a few steps

    ## 1. insert some records with this test id
    ## 2. product_test.state -> "ready"
    ## 3. product_test.expected_results?

    test = ProductTest.find(test_id)

    random_patients = Record.where(:test_id => nil).sample(3).collect {|p| p.medical_record_number }

    #puts random_patients.inspect

    pcj = Cypress::PopulationCloneJob.new({'patient_ids' =>random_patients, 'test_id' => test_id, "randomize_names"=> true})
    pcj.perform


    test.state = "ready"
    test.status_message = "Ready"

    test.expected_results = {}
    test.measures.each_with_index do |measure,index|

        test.expected_results[measure.key] = {
          "population_ids" => {},
          "measure_id" => measure.key
        }
    end
    ## TODO do this better


    test.save!

   ## this would be the more official way to do it
   #Cypress::MeasureEvaluationJob.new({"test_id" => test_id}).perform 
  end


  def hack_fix_cat1_tests
    visit_homepage
    click_link @vendor_name
    click_link @product_name

    #puts page.html

    @test_links.each do |test_name, hqmf|
      link = find_link('a', :text => /#{test_name} -/i)
      test_id = link['href'].split("/").last

      run_delayed_job(test_id)

    end
  end


  def execute_cat1_tests
    visit_homepage
    click_link @vendor_name
    click_link @product_name

    @test_links.each do |test_name, hqmf|
      click_link('a', :text => /#{test_name} -/i)
      zip = download_qrda(page.current_url)

      results_zip = process_cat1_file(zip)

      upload_results_file(results_zip, "application/x-zip-compressed", page.current_url)

      # finally return to the product overview page
      click_link @product_name
    end

  end


  def process_cat1_file(zip)

    # TODO - add real processing here.
    # it looks like the current measure_evaluation_validator
    # just sends the same file back

    zip
  end



  def execute_cat3_tests
    visit_homepage
    click_link @vendor_name
    click_link @product_name

    @test_links.each do |test_name, measures|
      click_link('a', :text => /#{test_name}/i)
      zip = download_qrda(page.current_url)

      results_xml = process_cat3_file(zip, measures)

      upload_results_file(results_xml, "text/xml", page.current_url)

      # finally return to the product overview page 
      click_link @product_name
    end


  end



  # This represents the user loading the test data into their calculator
  def process_cat3_file(zip, measure)

    #  measure might either be a string (single measure) or array (multi-measure)

    #xml = `bundle exec ruby ./script/cat_3_calculator.rb  #{measure_args_for(measure)}  --zipfile #{zip.path}`

    #file = Tempfile.new(['qrda_upload', '.xml'])
    #file.write(xml)

    ## TODO real world we process the file, such as above i guess
    ## for this test, just upload one of our fixtures
    file = File.open(File.join(Rails.root, "test", "fixtures", "qrda", "ep_test_qrda_cat3_good.xml"))

    file
  end

  def measure_args_for(measure)
    case measure
    when String
     return "--measure " + measure
    when Array
     return "--measure " + measure.join(" --measure ")
    end
  end




  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end



  def create_test(test_type, i)
    click_link "Add Test", match: :first

    choose test_type

    test_name = "MeasureEvaluationTest-#{test_type} #{i}"

    fill_in "product_test_name", with: test_name
    click_on "Next"
    
    return pick_test_measure_single_sequential, test_name
  end



  def pick_test_measure_single_sequential
    begin
      wait_for_ajax
      # loop through the measures in the first category
      all("input.measure_cb").each do |input|
        if !@test_measures.include? input['id']
          id = input['id']
          check id
          click_on "Done"
          @test_measures << id
          return id
        end
      end


      # if we get here then we already have a test for the measures in the current category
      # so click the link for the next one and recurse

      @test_categories["#{find('li.ui-state-active a')['id']}"] = "done"
      # binding.pry
      all("a.ui-tabs-anchor").each do |input|
        if !@test_categories.include?(input['id'])
          click_link input['id'] 
          return pick_test_measure_single_sequential 
        end
      end

      # that's it, we selected all the measures
      return nil
    rescue Exception => e
      # binding.pry
    end
  end



  def create_test_multi_measure(test_type, i, measure_count)
    click_link "Add Test", match: :first

    choose test_type

    test_name = "MeasureEvaluationTest-#{test_type} #{i}"

    fill_in "product_test_name", with: test_name
    click_on "Next"
    
    return pick_test_measure_random(measure_count), test_name
  end



  def pick_test_measure_random(measure_count)
    begin
      # we just want to pick some number of measures
      # so loop through, pick a random category then random measure

      #puts "trying to pick #{measure_count} measures"

      selected_measures = []

      try_number = 0

      loop do

        wait_for_ajax

        #puts "try number #{try_number}"

        #puts page.html

        category = all("a.ui-tabs-anchor").sample

        #puts "category #{category.inspect}"

        click_link category['id'] 

        wait_for_ajax

        measure = all("input.measure_cb").sample

        #puts "measure #{category.inspect}"

        if !selected_measures.include? measure['id']
          id = measure['id']
          check id
        
          @test_measures << id
          selected_measures << id
        end



        ## TODO - prevent infinite loops if there aren't enough measures
        break if selected_measures.count == measure_count
      end


     # puts "done selecting measures"

      click_on "Done"

      return selected_measures

    rescue Exception => e
      puts e
    end
  end





  # Download the QRDA zip from a test page.
  # The poltergeist driver cannot download files so we use cURL.
  def download_qrda(test_url)
    session_cookie = get_me_the_cookie("_cypress_session")

    cookie = "#{session_cookie[:name]}=#{session_cookie[:value]}"

    #  use the array form to force the extension to be .zip
    #  if you just give it a string "qrda.zip" the name turns out 
    #  to be something like "qrda.zip.2015-3892..." with random chars at the end
    #  and that seems to mess up something in the upload handling logic

    output_file = Tempfile.new(['qrda','.zip'])


    ## some notes on the curl command
    ##  -v               == verbose, add when debugging
    ##  -s               == silent, remove when debugging
    ## --noproxy '*'     == used to avoid the MITRE proxy, if necessary
    ##  -o <filename>    == destination file
    ## --cookie <cookie> == cypress session cookie, format name=value

    `curl -s --noproxy '*' -o #{output_file.path} --cookie #{cookie}  #{test_url}/download.qrda`


    ### note: here we are downloading a binary file (zip) so we are forced to use curl.
    ## if downloading a text file, like a csv or xml or something, you can get the content
    ## without an external process call by creating a JS function to get content by ajax
    ## see:  http://stackoverflow.com/questions/15739423/downloading-file-to-specific-folder-using-capybara-and-poltergeist-driver

    output_file
  end


  ## Upload the results for a test.
  def upload_results_file(file, file_type, test_url)

    # this commented stuff should work but capybara is not attaching the file
    # click_link("Upload Results")
    # page.attach_file('test_execution_results', file.path)


    session_cookie = get_me_the_cookie("_cypress_session")
  
    cookie = "--cookie #{session_cookie[:name]}=#{session_cookie[:value]}"

    old_val = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false

    #  this element is both display:none and input type="hidden"
    # so we have to force capybara to look at hidden elements to find it
    # also it may not even be there in the test environment
    auth_token = first(:xpath, "//input[@name='authenticity_token']")
     
    token_form = ""

    if !auth_token.nil?
      token_value = auth_token.value

      token_form = "--form \"authenticity_token=#{token_value}\""

    end
    Capybara.ignore_hidden_elements = old_val


    ## some notes on the curl command
    ##  -v               == verbose, add when debugging
    ##  -s               == silent, remove when debugging
    ## --noproxy '*'     == used to avoid the MITRE proxy, if necessary
    ## --cookie <cookie> == cypress session cookie, format name=value
    ## --form <value>    == form entry, format is name=value;attr=value

    utf8 = "--form \"utf8=✓\""

    results = "--form \"test_execution[results]=@#{file.path};type=#{file_type}\""

    noproxy = "--noproxy '*'"


    ### DO NOT REMOVE THIS LINE
    file_length = file.size
    # I don't know why but this makes the request work,
    # without it then the curl command sends no data

    `curl -s  #{utf8} #{results} #{token_form} #{noproxy} #{cookie} #{test_url}/test_executions`


    # finally reload the test page, like it would if 
    # we actually uploaded the file in the browser
    
    visit test_url

  end






end