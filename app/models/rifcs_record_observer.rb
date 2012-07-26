require 'nokogiri'
require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer
  include Miletus::Output::OAIPMH::NamespaceHelper

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

  def after_create(record)
    JobProcessor.new(:create, record).delay.run
  end

  def after_update(record)
    JobProcessor.new(:update, record).delay.run unless record.deleted
  end

  def after_destroy(record)
    #JobProcessor.new(:remove, record).delay.run
  end

  class JobProcessor < Struct.new(:action, :record)
    include Miletus::Output::OAIPMH::NamespaceHelper

    def run
      case action
      when :create
        Miletus::Output::OAIPMH::Record.new(
          :metadata => record.to_rif
        ).save!
      when :update
        key_nodes = Nokogiri::XML(record.metadata).xpath('//rif:key', ns_decl)
        existing = key_nodes.map do |e|
          tbl_name = Miletus::Output::OAIPMH::IndexedAttribute.table_name.to_sym
          Miletus::Output::OAIPMH::Record.joins(:indexed_attributes).where(
            tbl_name => {
              :key => 'rifcs_key',
              :value => e.content.strip
            }
          ).pluck(:record_id)
        end.flatten
        return JobProcessor.new(:create, record).run if existing.empty?
        existing_record = \
          Miletus::Output::OAIPMH::Record.find_by_id(existing.first)
        existing_record.metadata = record.to_rif
        existing_record.save!
      end
    end
  end

end
