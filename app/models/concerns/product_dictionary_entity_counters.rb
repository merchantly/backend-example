module ProductDictionaryEntityCounters
  extend ActiveSupport::Concern

  included do
    scope :by_dictionary_entity_id, ->(id) { where "#{table_name}.dictionary_entity_ids @> ARRAY[?]", id }
    before_save :update_dictionary_entity_ids
    after_commit :update_dictionary_entities_counters, on: %i[create update destroy]
  end

  def dictionary_entity_ids
    # TODO есть потенциал для оптимизации (не подгружать каждый раз dictionary,
    # чтобы узнать ее id)
    all_custom_attributes
      .select { |a| a.is_a?(AttributeDictionary) }
      .map(&:dictionary_entity_id)
      .select { |id| id.is_a? Numeric } # Каким-то образом могут просачиваться ID-шники в виде строк. Скорее всего это происходит, когда меняют тип Property со строки на Dictionary
      .uniq
  end

  private

  # TODO учитывать goods
  def update_dictionary_entities_counters
    return if vendor.disabled_dictionary_entity_counters?

    ids = if destroyed?
            dictionary_entity_ids
          elsif previous_changes[:dictionary_entity_ids].present?
            prev_ids = previous_changes[:dictionary_entity_ids].first
            new_ids = previous_changes[:dictionary_entity_ids].last

            # находим не повторяющиеся элементы
            # т.е. только добавленные + только удаленные
            # нет смысла обновлять те id которые были и остались
            (prev_ids - new_ids) | (new_ids - prev_ids)
          else
            []
          end

    return if ids.blank?

    DictionaryEntityCountersWorker.perform_async ids, (id if destroyed?)
  end

  def update_dictionary_entity_ids
    # TODO only when data changed
    self.dictionary_entity_ids = dictionary_entity_ids
  end
end
