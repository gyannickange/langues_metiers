# app/services/diagnostics/generate_pdf_service.rb
require "prawn"

Prawn::Fonts::AFM.hide_m17n_warning = true

module Diagnostics
  class GeneratePdfService
    # Colors matching the design
    GOLD           = "E7C873"
    SECONDARY      = "1F4B43" # Use Dark Green instead of Navy
    SECONDARY_DARK = "14302B" # Use even darker Green for text consistency
    TEXT_DARK      = "111827" # Gray-900
    TEXT_GRAY      = "6B7280" # Gray-500
    BG_LIGHT       = "F8F9FA"
    WHITE          = "FFFFFF"

    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @d       = diagnostic
      @primary = diagnostic.primary_career
      @second  = diagnostic.complementary_career
      @user    = diagnostic.user

      # Helper to get score data
      @gsd = ->(key) { @d.score_data[key.to_s] || @d.score_data[key.to_sym] }

      @dominant_name = @primary&.title || @gsd.call(:dominant_profile)&.dig("name") || "Stratège de projet"
      @dominant_desc = @primary&.description || @gsd.call(:dominant_profile)&.dig("description") || "Votre profil indique une forte capacité à : structurer des initiatives, coordonner des projets, organiser des ressources et transformer des idées en actions concrètes."
      @secondary_name = @second&.title || @gsd.call(:secondary_profile)&.dig("name") || "Créateur de contenu"
    end

    def call
      # Use A4, no margins (we handle inner padding)
      pdf = Prawn::Document.new(page_size: "A4", margin: [ 40, 40 ])

      # Background color for the whole page
      pdf.canvas do
        pdf.fill_color BG_LIGHT
        pdf.fill_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height
      end

      build(pdf)
      attach(pdf.render)
    end

    private

    def build(pdf)
      header(pdf)
      pdf.move_down 15

      profile_row(pdf)
      pdf.move_down 15

      details_row(pdf)
      pdf.move_down 30

      quote_section(pdf)
    end

    def header(pdf)
      # Badge
      pdf.fill_color SECONDARY
      pdf.fill_rounded_rectangle [ 0, pdf.cursor ], 130, 20, 10
      pdf.fill_color GOLD
      pdf.text_box "RAPPORT DE DIAGNOSTIC", at: [ 0, pdf.cursor ], width: 130, height: 20, align: :center, valign: :center, size: 7, style: :bold
      pdf.move_down 25

      # Title
      pdf.fill_color SECONDARY
      pdf.text "REPOSITIONNEMENT", size: 32, style: :bold, leading: -5
      pdf.fill_color GOLD
      pdf.text "STRATÉGIQUE", size: 32, style: :bold

      pdf.fill_color TEXT_GRAY
      pdf.text "ÉMIS LE #{@d.completed_at&.strftime("%d.%m.%Y") || Date.current.strftime("%d.%m.%Y")}", size: 9, style: :bold

      pdf.move_down 20

      # Mini bento info
      y_mini = pdf.cursor
      width_mini = (pdf.bounds.width / 4) - 8

      [
        [ "PARTICIPANT", "#{@user.first_name} #{@user.last_name}" ],
        [ "LOCALISATION", "#{@user.city}, #{@user.country}" ],
        [ "DIPLÔME", @user.diploma.to_s ],
        [ "STATUT", @user.employment_status.to_s, true ]
      ].each_with_index do |(label, value, highlight), i|
        pdf.bounding_box([ i * (width_mini + 10), y_mini ], width: width_mini, height: 45) do
          participant_mini_card(pdf, label, value, highlight: highlight)
        end
      end
      pdf.move_down 10
    end

    def participant_mini_card(pdf, label, value, highlight: false)
      pdf.fill_color highlight ? "FFFBEB" : WHITE
      pdf.stroke_color highlight ? "FEF3C7" : "E5E7EB"
      pdf.fill_and_stroke_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 10

      pdf.indent(10) do
        pdf.move_down 10
        pdf.fill_color highlight ? "D97706" : TEXT_GRAY
        pdf.text label, size: 6, style: :bold
        pdf.move_down 2
        pdf.fill_color highlight ? "78350F" : SECONDARY
        pdf.text value.to_s, size: 9, style: :bold, overflow: :shrink_to_fit
      end
    end

    def profile_row(pdf)
      y_start = pdf.cursor
      width_main = (pdf.bounds.width * 0.65) - 10
      width_side = (pdf.bounds.width * 0.35) - 10

      # Dominant Card
      pdf.bounding_box([ 0, y_start ], width: width_main, height: 200) do
        pdf.fill_color SECONDARY
        pdf.fill_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20

        pdf.indent(25) do
          pdf.move_down 25
          pdf.fill_color GOLD
          pdf.text "PROFIL DOMINANT", size: 8, style: :bold, character_spacing: 1
          pdf.move_down 15
          pdf.fill_color WHITE
          pdf.text @dominant_name.upcase, size: 24, style: :bold, leading: -2
          pdf.move_down 15
          pdf.fill_color "D1D5DB"
          pdf.text @dominant_desc, size: 9, leading: 4
        end

        # Decorative tag footer
        pdf.bounding_box([ 25, 40 ], width: pdf.bounds.width - 50) do
          pdf.fill_color GOLD
          pdf.text "TERRAINS D'EXPRESSION FAVORISÉS", size: 7, style: :bold
          pdf.move_down 5
          # Just text tags
          pdf.fill_color WHITE
          pdf.text "ONG • INSTITUTIONS • ENTREPRISES • INTERNATIONAL", size: 8, style: :bold
        end
      end

      # Secondary Card
      pdf.bounding_box([ width_main + 20, y_start ], width: width_side, height: 200) do
        pdf.fill_color WHITE
        pdf.fill_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20
        pdf.stroke_color "E5E7EB"
        pdf.stroke_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20

        pdf.indent(20) do
          pdf.move_down 20
          pdf.fill_color TEXT_GRAY
          pdf.text "PROFIL SECONDAIRE", size: 7, style: :bold, character_spacing: 1
          pdf.move_down 30
          pdf.fill_color SECONDARY
          pdf.text @secondary_name.upcase, size: 18, style: :bold, leading: -1
          pdf.move_down 10
          pdf.fill_color TEXT_GRAY
          pdf.text "Votre profil secondaire apporte une capacité complémentaire analytique et stratégique majeure.", size: 8

          pdf.move_down 15
          pdf.fill_color GOLD
          pdf.text "SYNERGIE PUISSANTE", size: 7, style: :bold
          pdf.fill_color TEXT_GRAY
          pdf.text "Vision globale + Exigence", size: 8
        end
      end
    end

    def details_row(pdf)
      y_start = pdf.cursor
      width = (pdf.bounds.width / 2) - 10

      # Forces
      pdf.bounding_box([ 0, y_start ], width: width, height: 165) do
        pdf.fill_color WHITE
        pdf.fill_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20
        pdf.stroke_color "E5E7EB"
        pdf.stroke_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20

        pdf.indent(20) do
          pdf.move_down 15
          pdf.fill_color SECONDARY
          pdf.text "FORCES PRINCIPALES", size: 14, style: :bold
          pdf.move_down 15

          [ "Analyse Stratégique", "Structuration Projet", "Communication Impactante", "Intelligence Sociale" ].each do |force|
            pdf.fill_color "F9FAFB"
            pdf.fill_rounded_rectangle [ 0, pdf.cursor ], width - 40, 22, 5
            pdf.indent(10) do
              pdf.fill_color SECONDARY
              pdf.move_down 7
              pdf.text "• #{force.upcase}", size: 7, style: :bold
            end
            pdf.move_down 4
          end
        end
      end

      # Axes
      pdf.bounding_box([ width + 20, y_start ], width: width, height: 165) do
        pdf.fill_color GOLD
        pdf.fill_rounded_rectangle [ 0, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height, 20

        pdf.indent(20) do
          pdf.move_down 15
          pdf.fill_color SECONDARY
          pdf.text "AXES DE DÉVELOPPEMENT", size: 13, style: :bold
          pdf.move_down 15

          [ "Alignement du projet pro", "Maîtrise technologique", "Visibilité & Branding" ].each do |axe|
            pdf.fill_color "FDE68A" # Lighter gold
            pdf.fill_rounded_rectangle [ 0, pdf.cursor ], width - 40, 30, 8
            pdf.indent(10) do
              pdf.fill_color SECONDARY
              pdf.move_down 10
              pdf.text axe.upcase, size: 7, style: :bold
            end
            pdf.move_down 8
          end
        end
      end
    end

    def quote_section(pdf)
      pdf.move_down 15
      pdf.fill_color "D1D5DB"
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor
      pdf.move_down 20

      pdf.fill_color SECONDARY
      pdf.text "\"LE REPOSITIONNEMENT EST LE DÉBUT D'UNE EXPERTISE 4.0\"", size: 16, style: :bold, align: :center
      pdf.move_down 8
      pdf.fill_color TEXT_GRAY
      pdf.text "L'ÉQUIPE D'ANALYSE INSERTTRICE", size: 7, align: :center, character_spacing: 3
    end

    def attach(pdf_string)
      @d.pdf_report.attach(
        io:           StringIO.new(pdf_string),
        filename:     "diagnostic-#{@d.id}.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
