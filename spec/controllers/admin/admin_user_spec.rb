require 'spec_helper'
require File.join(File.dirname(__FILE__), 'shared_examples')

describe Admin::AdminUsersController do
  it_behaves_like "an admin page"
end