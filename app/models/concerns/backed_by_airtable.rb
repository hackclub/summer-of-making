module BackedByAirtable
  extend ActiveSupport::Concern

  included do
    validates :airtable_fields, presence: true
    validates :airtable_id, presence: true, uniqueness: true
    attr_reader :filter
  end

  class_methods do
    def all_records
      self::AirtableRecord.records(filter: @filter)
    end

    def backed_by_filter(filter_by_formula)
      @filter = filter_by_formula
    end

    def pull_all_from_airtable!
      all_records.each do |record|
        airtable_record = self.find_or_initialize_by(airtable_id: record.id)
        airtable_record.airtable_fields = record.fields
        airtable_record.save!
      end
    end

    def destructive_pull_all_from_airtable!
      self.transaction do
        self.delete_all
        self.pull_all_from_airtable!
      end
    end
  end
end
