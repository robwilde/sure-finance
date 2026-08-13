module User::RulePromptable
  extend ActiveSupport::Concern

  def needs_rule_prompt_for?(transaction)
    return false if rule_prompts_disabled?
    return false if transaction.category_id.blank?
    return false unless transaction.saved_change_to_category_id?
    return false if rule_prompt_dismissed_for?(transaction.category_id)

    transaction.eligible_for_category_rule?
  end

  def rule_prompt_dismissed_for?(category_id)
    dismissed_rule_prompt_category_ids.include?(category_id)
  end

  def dismiss_rule_prompt_for!(category_id)
    return if category_id.blank?

    with_lock do
      unless rule_prompt_dismissed_for?(category_id)
        update!(dismissed_rule_prompt_category_ids: dismissed_rule_prompt_category_ids + [ category_id ])
      end
    end
  end

  def enable_rule_prompts!
    update!(rule_prompts_disabled: false, dismissed_rule_prompt_category_ids: [])
  end

  def disable_rule_prompts!
    update!(rule_prompts_disabled: true)
  end
end
