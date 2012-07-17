require 'miletus'

class HomeController < ApplicationController
  def index
    @collections = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.all
  end
end
