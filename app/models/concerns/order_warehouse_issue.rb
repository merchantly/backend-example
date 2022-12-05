module OrderWarehouseIssue
  def issue_from_warehouse!
    transaction do
      items.find_each(&:issue_from_warehouse!)
    end
  end
end
