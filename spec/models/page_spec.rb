require 'spec_helper'

describe Page do

  it "should return html by rendering Markdown" do
    page = Page.new(:content => "Markdown is *awesome*!")
    page.to_html.should == "<p>Markdown is <em>awesome</em>!</p>\n"
  end

end
