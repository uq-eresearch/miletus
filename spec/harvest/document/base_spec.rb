require 'spec_helper'

describe Miletus::Harvest::Document::Base do

  it { should respond_to(:url, :document, :fetch, :managed?, :clear) }

end

