class Expense < ActiveRecord::Base
  belongs_to :payer, class_name: "User"
  has_many :user_expenses
  has_many :users, through: :user_expenses
  has_one :dwelling, through: :payer

  validates :name, :amount, presence: true

  after_save :distribute_owed_amounts
  before_destroy :delete_owed_amounts

  # could belong to comment
  def total_paid
    self.user_expenses.reduce(0) { |sum, user_expense| user_expense.paid + sum }
  end

  def distribute_owed_amounts
    users = self.dwelling.users
    num_users = users.count
    users.each do |u|
      if u.user_expenses.where(expense_id: self.id).length > 0
        u.user_expenses.find_by(expense_id: self.id).update(portion: self.amount / num_users )
      else
        u.user_expenses.create(expense_id: self.id, portion: self.amount / num_users)
      end
    end
  end

  def delete_owed_amounts
    UserExpense.delete_all(expense_id: self.id)
  end
end
