class Page < ActiveRecord::Base
  attr_accessible :content, :created_at, :name, :updated_at

  def to_html
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::XHTML)
    @renderer.render(content)
  end
end
