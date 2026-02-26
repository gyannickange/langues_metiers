# app/services/diagnostics/generate_pdf_service.rb
require "prawn"
require "prawn/table"

module Diagnostics
  class GeneratePdfService
    BRAND  = "1a365d"
    ACCENT = "2b6cb0"
    TEXT   = "2d3748"

    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @d       = diagnostic
      @primary = diagnostic.primary_profile
      @second  = diagnostic.complementary_profile
      @user    = diagnostic.user
    end

    def call
      pdf = Prawn::Document.new(page_size: "A4", margin: [40, 50])
      build(pdf)
      attach(pdf.render)
    end

    private

    def build(pdf)
      header(pdf)
      pdf.move_down 20
      primary_section(pdf)
      pdf.move_down 12
      secondary_section(pdf)
      pdf.move_down 12
      trajectories_section(pdf)
      pdf.move_down 12
      skills_section(pdf)
      pdf.move_down 12
      action_section(pdf)
      pdf.move_down 12
      upsell_section(pdf)
    end

    def header(pdf)
      pdf.fill_color BRAND
      pdf.text "Diagnostic de Repositionnement Stratégique", size: 18, style: :bold
      pdf.fill_color TEXT
      pdf.text "Rapport généré pour : #{@user.email}", size: 10
      pdf.text "Date : #{I18n.l(Date.current, format: :long) rescue Date.current.to_s}", size: 10
      pdf.stroke_horizontal_rule
    end

    def primary_section(pdf)
      return unless @primary
      heading(pdf, "Votre Profil Principal")
      score = @d.score_data[@primary.slug].to_i
      pdf.text "#{@primary.name} — #{score} point(s)", size: 12, style: :bold, color: TEXT
      pdf.text @primary.description.to_s, size: 11, color: TEXT
    end

    def secondary_section(pdf)
      return unless @second
      heading(pdf, "Profil Complémentaire")
      score = @d.score_data[@second.slug].to_i
      pdf.text "#{@second.name} — #{score} point(s)", size: 11, color: TEXT
    end

    def trajectories_section(pdf)
      trajectory = @primary&.active_trajectory
      return unless trajectory
      heading(pdf, "Vos 3 Axes Stratégiques")
      [
        ["Axe 1 — Institutionnel / ONG",      trajectory.axe_1],
        ["Axe 2 — Secteur privé / hybride",   trajectory.axe_2],
        ["Axe 3 — Spécialisation long terme", trajectory.axe_3]
      ].each_with_index do |(title, text), i|
        pdf.text "#{i + 1}. #{title}", size: 11, style: :bold, color: TEXT
        pdf.text text.to_s, size: 11, color: TEXT
        pdf.move_down 4
      end
    end

    def skills_section(pdf)
      skills = @primary&.key_skills || []
      return if skills.empty?
      heading(pdf, "Compétences Clés à Développer")
      skills.each { |s| pdf.text "• #{s}", size: 11, color: TEXT }
    end

    def action_section(pdf)
      return unless @primary&.first_action
      heading(pdf, "Première Action Concrète")
      pdf.text @primary.first_action, size: 11, color: TEXT
    end

    def upsell_section(pdf)
      return unless @primary&.premium_pitch
      heading(pdf, "Passez au Roadmap Premium")
      pdf.text @primary.premium_pitch, size: 11, color: TEXT
    end

    def heading(pdf, text)
      pdf.fill_color ACCENT
      pdf.text text, size: 13, style: :bold
      pdf.fill_color TEXT
    end

    def attach(pdf_string)
      @d.pdf_report.attach(
        io:           StringIO.new(pdf_string),
        filename:     "diagnostic-#{@d.id}.pdf",
        content_type: "application/pdf"
      )
      @d.update!(pdf_generated: true)
    end
  end
end
