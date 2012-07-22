require 'miletus/harvest/oaipmh_rifcs/record'
require 'miletus/output/oaipmh/record'

class RifcsRecordObserver < ActiveRecord::Observer

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

  def after_create(record)
    delay.process_change(:create, record)
  end

  def after_update(record)
    # TODO: Implement
  end

  def after_destroy(record)
    # TODO: Implement
  end

  def process_change(action, record)
    Miletus::Output::OAIPMH::Record.new(
      :metadata => record.to_rif
    ).save!
  end


end
