module ApplicationHelper
  include Pagy::Frontend

  def nav_link_class(path)
    is_active = current_page?(path)
    base = "group flex items-center px-4 py-3 rounded-2xl transition-all duration-300 ease-out font-medium text-sm"
    inactive = "text-slate-500 hover:text-slate-900 hover:bg-slate-50 hover:shadow-sm"
    active = "bg-[var(--color-primary)]/10 text-[var(--color-primary)] shadow-sm font-bold border border-[var(--color-primary)]/20"
    [ base, (is_active ? active : inactive) ].join(" ")
  end
end
