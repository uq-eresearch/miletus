module Miletus::Harvest::Atom
  module RDC
    require File.join(File.dirname(__FILE__),'atom_rdc','atom_entry_patch')
    require File.join(File.dirname(__FILE__),'atom_rdc','feed')
    require File.join(File.dirname(__FILE__),'atom_rdc','entry')
  end
end