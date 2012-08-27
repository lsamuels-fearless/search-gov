class Form < ActiveRecord::Base
  DETAIL_FIELD_NAMES = [:title, :description, :file_size, :number_of_pages, :landing_page_url, :revision_date, :links].freeze
  attr_accessible :form_agency_id, :number, :url, :file_type, :govbox_enabled
  validates_presence_of :form_agency_id, :number, :url, :file_type
  serialize :details, Hash
  belongs_to :form_agency
  has_and_belongs_to_many :indexed_documents

  DETAIL_FIELD_NAMES.each do |name|
    define_method name do
      send(:details).send("[]", name)
    end

    define_method :"#{name}=" do |arg|
      send(:details).send("[]=", name, arg)
    end
  end

  searchable do
    integer :form_agency_id
    boolean :govbox_enabled
    text :number, :stored => true, :boost => 17.0, :as => 'number_text_form'
    text :title, :stored => true, :boost => 8.0, :as => 'title_text_form'
    text :description, :stored => true
  end

  class << self
    include QueryPreprocessor
  end

  def self.search_for(query, affiliate)
    sanitized_query = preprocess(query).to_s.gsub(/\bform\b/i, '').strip
    return nil if sanitized_query.blank?
    ActiveSupport::Notifications.instrument("solr_search.usasearch", :query => { :model => self.name, :term => sanitized_query, :affiliate => affiliate.name }) do
      begin
        search do
          with(:form_agency_id, affiliate.form_agencies.collect(&:id))
          with :govbox_enabled, true
          fulltext sanitized_query do
            highlight :number, :title, :frag_list_builder => 'single'
            highlight :description, :fragment_size => 255
          end
          paginate :page => 1, :per_page => 1
        end
      rescue RSolr::Error::Http => e
        Rails.logger.warn "Error Form.search_for: #{e.to_s}"
        nil
      end
    end
  end
end
