require 'test_helper'

class ImportTasksControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get import_tasks_create_url
    assert_response :success
  end

end
