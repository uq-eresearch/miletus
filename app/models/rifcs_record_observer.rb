require 'miletus'

class RifcsRecordObserver < ActiveRecord::Observer

  observe Miletus::Harvest::OAIPMH::RIFCS::Record

  def after_create(record)
    JobProcessor.new(:create, record).delay.run
  end

  def after_update(record)
    # TODO: Implement
  end

  def after_destroy(record)
    # TODO: Implement
  end

  class JobProcessor < Struct.new(:action, :record)
    def run
      Miletus::Output::OAIPMH::Record.new(
        :metadata => record.to_rif
      ).save!
    end
  end

end
