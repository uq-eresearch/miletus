require 'spec_helper'

describe Miletus::Merge::RifcsDocs do

  it { should respond_to(:content_from_nodes, :merge) }

end

describe Miletus::Merge::RifcsDoc do

  it { should respond_to(:sort_key, :titles, :types, :group=, :key=) }

end
