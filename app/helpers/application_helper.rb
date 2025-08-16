module ApplicationHelper
  include Pagy::Frontend

  def nav_link_class(path)
    is_active = current_page?(path)
    base = "flex items-center px-3 py-2 rounded-md transition-colors"
    inactive = "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
    active = "bg-gray-200 text-gray-900 font-medium"
    [ base, (is_active ? active : inactive) ].join(" ")
  end
end
