require 'spec_helper'

describe Page do

  it "should return html by rendering Markdown" do
    page = Page.new(:content => "Markdown is *awesome*!")
    page.to_html.should == "<p>Markdown is <em>awesome</em>!</p>\n"
  end

  it "should return an empty string for nil content" do
    page = Page.new
    page.to_html.should == ""
  end

end
