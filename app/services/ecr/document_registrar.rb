# Создает разные виды документов в ECR
class Ecr::DocumentRegistrar
  def initialize(form)
    @form = form
  end

  # Продажа
  def sale
    transaction do
      Ecr::SaleDocument.create!(
        vendor: form.vendor,
        cashier: form.cashier,
        order: form.order,
        comment: form.comment,
        amount: form.amount
      )
    end
  end

  # Возврат
  def refund
    transaction do
      Ecr::RefundDocument.create!(
        vendor: form.vendor,
        sale_document: form.sale_document,
        comment: form.comment,
        amount: form.amount
      )
    end
  end

  # Перемещение средств с одной кассы на другую
  def transfer
    transaction do
      Ecr::TransferDocument.create!(
        vendor: form.vendor,
        from_cashier: form.from_cashier,
        to_cashier: form.to_cashier,
        amount: form.amount,
        comment: form.comment
      )
    end
  end

  # Расход денег из кассы
  def expense
    transaction do
      Ecr::ExpenseDocument.create!(
        vendor: form.vendor,
        cashier: form.cashier,
        amount: form.amount,
        comment: form.comment
      )
    end
  end

  # Приход денег в кассу
  def receipt
    transaction do
      Ecr::ReceiptDocument.create!(
        vendor: form.vendor,
        cashier: form.cashier,
        amount: form.amount,
        comment: form.comment
      )
    end
  end

  def correct
    transaction do
      Ecr::CorrectDocument.create!(
        vendor: form.vendor,
        cashier: form.cashier,
        amount: form.amount
      )
    end
  end

  class << self
    %i[sale refund transfer expense receipt correct].each do |action|
      define_method action do |form|
        new(form).send action
      end
    end
  end

  private

  attr_reader :form

  def transaction
    Ecr::Document.transaction do
      raise ActiveRecord::RecordInvalid.new(form) unless form.valid?

      yield
    end
  end
end
