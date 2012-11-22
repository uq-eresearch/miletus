class Page < ActiveRecord::Base
  attr_accessible :content, :created_at, :name, :updated_at

  def to_html
    content ? renderer.render(content) : ''
  end

  private

  def renderer
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::XHTML)
  end

end
