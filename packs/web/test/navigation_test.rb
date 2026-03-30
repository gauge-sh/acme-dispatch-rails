require_relative "web_case"

class NavigationTest < WebCase
  INDEXES = {
    "/" => "Dispatch board",
    "/jobs" => "Jobs",
    "/schedule" => nil,
    "/customers" => "Customers",
    "/technicians" => "Technicians",
    "/parts" => "Parts & stock",
    "/invoice_records" => "Invoice records"
  }

  test "every screen renders for a dispatcher" do
    sign_in_dispatcher
    INDEXES.each do |path, heading|
      get path
      assert_response :success, path
      assert_select "h1", text: heading, count: 1 if heading
    end
  end

  test "every screen renders when the tables are empty" do
    sign_in_admin
    [ InvoiceLineItem, InvoiceRecord, StockAdjustment, JobPart, Appointment, Job,
      StockLevel, Part, Technician, Customer ].each(&:delete_all)

    (INDEXES.keys + [ "/users" ]).each do |path|
      get path
      assert_response :success, path
    end
    assert_select "h1", "Users"
  end

  test "new forms render everywhere" do
    sign_in_admin
    [ "/jobs/new", "/customers/new", "/technicians/new", "/parts/new", "/users/new" ].each do |path|
      get path
      assert_response :success, path
      assert_select "form.stacked", 1
    end
  end
end
