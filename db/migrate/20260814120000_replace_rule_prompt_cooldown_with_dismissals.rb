class ReplaceRulePromptCooldownWithDismissals < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :dismissed_rule_prompt_category_ids, :uuid, array: true, default: [], null: false
    remove_column :users, :rule_prompt_dismissed_at, :datetime
  end
end
