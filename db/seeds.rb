# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if User.where(email: "admin@admin.com").blank?
  User.create!(email: "admin@admin.com", password: "password", password_confirmation: "password", role: :admin)
end

%w[soft digital language].each do |kind|
  Category.find_or_create_by!(name: kind.capitalize, kind: kind)
end

# Création de la filière Langues avec roadmap complète
field = Field.find_or_create_by!(name: "Langues et Communication") do |f|
  f.description = "Filière dédiée aux étudiants en langues souhaitant s'orienter vers les métiers de la relation client et du commerce international"
  f.status = :active
end

# Roadmap : De la Licence en Anglais au Poste de Responsable Relation Client
roadmap = Roadmap.find_or_create_by!(title: "Devenir Responsable Relation Client") do |r|
  r.description = "Parcours complet pour évoluer d'étudiant en anglais vers un poste de responsable ou chargé de relation client dans une entreprise multinationale"
end

# Associer la roadmap à la filière via la table de jointure
RoadmapField.find_or_create_by!(roadmap: roadmap, field: field)

# Étape 1 : Pendant la Licence en Anglais
roadmap.roadmap_steps.find_or_create_by!(title: "Licence en Anglais - Développement des compétences de base", order: 1) do |step|
  step.objective = "Développer des compétences linguistiques et relationnelles solides pour se préparer au monde professionnel."
  step.skills = "• Maîtrise parfaite de l'anglais oral et écrit
• Connaissance d'une deuxième langue (atout majeur)
• Pratique de la communication professionnelle (emails, appels, réunions)
• Sens de l'écoute, empathie, gestion de la relation client"
  step.activities = "• Stages ou jobs étudiants dans des centres d'appels, hôtellerie, service client
• Cours en ligne sur la communication client et les soft skills
• MOOC sur LinkedIn Learning, Coursera
• Pratique de conversations professionnelles en anglais"
end

# Étape 2 : À la Fin de la Licence
roadmap.roadmap_steps.find_or_create_by!(title: "Professionnalisation - Certifications spécialisées", order: 2) do |step|
  step.objective = "Se professionnaliser pour viser le monde des entreprises et acquérir des compétences techniques recherchées."
  step.skills = "• Gestion des réclamations
• Négociation et persuasion
• Gestion du stress et orientation client
• Maîtrise des outils CRM (Salesforce, Zendesk, HubSpot)"
  step.activities = "• Certificat en Relation Client (HubSpot Academy, Salesforce Trailhead)
• Certificat en CRM (Customer Relationship Management)
• Formations locales en service client
• Préparation aux entretiens dans les multinationales"
end

# Étape 3 : Expériences Professionnelles
roadmap.roadmap_steps.find_or_create_by!(title: "Première expérience professionnelle", order: 3) do |step|
  step.objective = "Gagner de l'expérience pratique et construire son réseau professionnel dans le domaine."
  step.skills = "• Résolution des problèmes clients
• Fidélisation et satisfaction client
• Utilisation des outils CRM pour le suivi
• Communication multicanale (email, chat, téléphone)"
  step.activities = "• Agent de service client dans une entreprise internationale
• Assistant commercial export
• Support client en ligne (email, chat, téléphone)
• Participation à des projets d'amélioration du service client"
end

# Étape 4 : Spécialisation et Montée en Compétence
roadmap.roadmap_steps.find_or_create_by!(title: "Spécialisation et leadership", order: 4) do |step|
  step.objective = "Devenir chargé/responsable de relation client avec des compétences avancées en management."
  step.skills = "• Gestion d'équipe de support client
• Analyse des données clients pour améliorer le service
• Gestion de la satisfaction client (NPS, feedback clients)
• Leadership et formation d'équipes"
  step.activities = "• Diplôme en commerce international ou marketing relationnel
• Spécialisation en customer success management
• Formation en management d'équipe
• Projets d'optimisation de l'expérience client"
end

# Étape 5 : Évolution de carrière
roadmap.roadmap_steps.find_or_create_by!(title: "Évolution vers des postes de direction", order: 5) do |step|
  step.objective = "Atteindre des postes de responsabilité et devenir expert en relation client au niveau stratégique."
  step.skills = "• Vision stratégique de l'expérience client
• Management d'équipes multiculturelles
• Gestion de budgets et KPIs
• Innovation en matière de service client"
  step.activities = "• Responsable service client
• Customer Success Manager senior
• Responsable expérience client
• Manager CRM
• Participation à la stratégie globale de l'entreprise"
end

puts "✅ Filière 'Langues et Communication' créée avec succès"
puts "✅ Roadmap 'Devenir Responsable Relation Client' avec 5 étapes créée"
