ActiveAdmin.register Page do

  show do
    attributes_table do
      row :id
      row :name
      row "Raw Content" do |page|
        pre page.content, :class => 'prettyprint'
      end
      row 'Rendered Content' do |page|
        page.to_html.html_safe
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

end