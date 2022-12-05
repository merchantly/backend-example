class OpenbillCategory < OpenbillRecord
  has_many :accounts, class_name: 'OpenbillAccount', foreign_key: :category_id

  has_many :income_transactions, through: :accounts
  has_many :outcome_transactions, through: :accounts
end
