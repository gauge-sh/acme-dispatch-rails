require_relative "api_case"

class PaginationTest < ApiCase
  test "the list envelope has exactly four keys, in order" do
    get_api "/customers"
    assert_response :success
    assert_equal %w[items page per_page total], body.keys
    assert_equal 1, body["page"]
    assert_equal 20, body["per_page"]
    assert_equal Customer.count, body["total"]
  end

  test "page and per_page slice the collection" do
    30.times { |i| Customer.create!(name: "Customer #{i}", service_address: "#{i} Elm St") }

    get_api "/customers", page: 2, per_page: 10
    assert_equal 10, body["items"].size
    assert_equal 2, body["page"]
    assert_equal 10, body["per_page"]
    assert_equal Customer.count, body["total"]

    get_api "/customers", per_page: 10
    first_page_ids = body["items"].map { |c| c["id"] }
    get_api "/customers", page: 2, per_page: 10
    assert_empty first_page_ids & body["items"].map { |c| c["id"] }
  end

  test "per_page above the cap is clamped, not an error" do
    get_api "/customers", per_page: 500
    assert_response :success
    assert_equal 100, body["per_page"]
  end

  test "a page beyond the end is empty with the real total" do
    get_api "/customers", page: 99
    assert_response :success
    assert_empty body["items"]
    assert_equal Customer.count, body["total"]
  end

  test "non-positive-integer paging is refused" do
    [ { page: 0 }, { page: -1 }, { page: "abc" }, { per_page: "1.5" }, { per_page: 0 } ].each do |query|
      get_api "/customers", **query
      assert_response :bad_request, query.inspect
      assert_api_error "validation_failed", "page and per_page must be positive integers"
    end
  end

  test "items come back in id order" do
    get_api "/customers"
    ids = body["items"].map { |c| c["id"] }
    assert_equal ids.sort, ids
  end
end
