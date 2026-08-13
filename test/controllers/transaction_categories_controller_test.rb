require "test_helper"

class TransactionCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @entry = entries(:transaction)
    @transaction = transactions(:one)
  end

  test "assigning a category touches its last_used_at" do
    category = categories(:income)
    assert_nil category.last_used_at

    patch transaction_category_url(@entry),
      params: { entry: { entryable_type: "Transaction", entryable_attributes: { id: @transaction.id, category_id: category.id } } },
      as: :turbo_stream

    assert_not_nil category.reload.last_used_at
  end

  test "clearing a category does not touch any category's last_used_at" do
    category = @transaction.category
    assert_nil category.last_used_at

    patch transaction_category_url(@entry),
      params: { entry: { entryable_type: "Transaction", entryable_attributes: { id: @transaction.id, category_id: nil } } },
      as: :turbo_stream

    assert_response :success
    assert_nil @transaction.reload.category_id
    assert_nil category.reload.last_used_at
  end

  test "rule prompt renders with a close control that does not submit the form" do
    patch transaction_category_url(@entry),
      params: { entry: { entryable_type: "Transaction", entryable_attributes: { id: @transaction.id, category_id: categories(:income).id } } },
      as: :turbo_stream

    assert_response :success
    assert_match "You can create a rule to automatically categorize transactions like this one", response.body
    assert_match "element-removal#remove", response.body
    assert_empty users(:family_admin).reload.dismissed_rule_prompt_category_ids
  end

  test "rule prompt is suppressed only for categories the user skipped" do
    skipped = categories(:income)
    users(:family_admin).update!(dismissed_rule_prompt_category_ids: [ skipped.id ])

    patch transaction_category_url(@entry),
      params: { entry: { entryable_type: "Transaction", entryable_attributes: { id: @transaction.id, category_id: skipped.id } } },
      as: :turbo_stream

    assert_response :success
    assert_no_match "You can create a rule to automatically categorize transactions like this one", response.body

    patch transaction_category_url(@entry),
      params: { entry: { entryable_type: "Transaction", entryable_attributes: { id: @transaction.id, category_id: categories(:food_and_drink).id } } },
      as: :turbo_stream

    assert_response :success
    assert_match "You can create a rule to automatically categorize transactions like this one", response.body
  end
end
