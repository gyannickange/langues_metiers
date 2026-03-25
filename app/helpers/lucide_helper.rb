module LucideHelper
  def lucide_icon(name, **options)
    classes = options.delete(:class) || "w-5 h-5"
    stroke_width = options.delete(:stroke_width) || 2

    # We use a simple SVG from Lucide (could be expanded to a full library if needed)
    # For now, we'll provide common ones used in the dashboard
    case name.to_sym
    when :home
      path = '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>'
    when :users
      path = '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>'
    when :skills, :puzzle
      path = '<path d="M20 7h-9"/><path d="M14 17H5"/><circle cx="17" cy="17" r="3"/><circle cx="7" cy="7" r="3"/>'
    when :careers, :compass
      path = '<circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/>'
    when :learning, :book
      path = '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z"/>'
    when :mentorship, :handshake
      path = '<path d="m11 17 2 2 6-6"/><path d="m8 14 2 2 2-2"/><path d="m5 11 2 2 2-2"/><path d="M19 10.5V14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-3.5"/><path d="M11 7h2"/><path d="M11 3h2"/><path d="M11 11h2"/>' # Simplified representation
    when :settings, :settings_2
      path = '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.1a2 2 0 0 1-1-1.72v-.51a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>'
    when :chevron_right
      path = '<polyline points="9 18 15 12 9 6"/>'
    else
      path = ""
    end

    content_tag(:svg,
                path.html_safe,
                { xmlns: "http://www.w3.org/2000/svg",
                  width: options[:width] || 24,
                  height: options[:height] || 24,
                  viewBox: "0 0 24 24",
                  fill: "none",
                  stroke: "currentColor",
                  "stroke-width": stroke_width,
                  "stroke-linecap": "round",
                  "stroke-linejoin": "round",
                  class: classes }.merge(options.except(:class, :width, :height, :stroke_width)))
  end
end
