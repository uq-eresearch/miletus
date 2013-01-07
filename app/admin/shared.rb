
def view_delete_buttons(resource_path)
  links = ''.html_safe
  links << link_to(I18n.t('active_admin.view'), resource_path,
    :class => "member_link view_link")
  links << link_to(I18n.t('active_admin.delete'), resource_path,
    :method => :delete,
    :data => {:confirm => I18n.t('active_admin.delete_confirmation')},
    :class => "member_link delete_link")
  links
end
