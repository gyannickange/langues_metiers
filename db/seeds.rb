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

# ===== PROFILES (7) =====
profiles_data = [
  {
    name: "Coordinateur Stratégique",
    slug: "coordinateur-strategique",
    description: "Pilotage et gestion de projets multi-acteurs.",
    key_skills: ["Gestion de projet", "Leadership", "Communication", "Planification stratégique"],
    first_action: "Rejoignez une organisation et proposez-vous sur un projet transversal.",
    premium_pitch: "Le Roadmap Premium construit votre plan de montée en compétences sur 6 mois avec des jalons concrets.",
    axe_1: "Coordinateur dans une institution internationale ou ONG — pilotage de projets multi-acteurs.",
    axe_2: "Chef de projet dans le secteur privé ou hybride — direction, conseil, management.",
    axe_3: "Expert en gestion de projets complexes — certifications PMP, Prince2, Agile."
  },
  {
    name: "Analyste & Veille",
    slug: "analyste-veille",
    description: "Analyse stratégique, études, recherche appliquée.",
    key_skills: ["Analyse de données", "Recherche documentaire", "Rédaction de rapports", "Pensée critique"],
    first_action: "Réalisez une analyse sectorielle et publiez-la sur LinkedIn.",
    premium_pitch: "Le Roadmap Premium vous guide vers les certifications analytiques les plus reconnues.",
    axe_1: "Analyste dans une organisation internationale, un think tank, ou une administration.",
    axe_2: "Consultant en stratégie ou chargé d'études dans le secteur privé.",
    axe_3: "Expert en intelligence économique ou recherche appliquée à long terme."
  },
  {
    name: "Communication & Influence",
    slug: "communication-influence",
    description: "Narration, plaidoyer, communication institutionnelle.",
    key_skills: ["Storytelling", "Rédaction", "Réseaux sociaux", "Plaidoyer"],
    first_action: "Lancez un blog ou une page LinkedIn dédiée à un sujet de votre domaine.",
    premium_pitch: "Le Roadmap Premium vous aide à construire votre personal brand avec un plan éditorial sur mesure.",
    axe_1: "Chargé de communication dans une organisation internationale, ONG ou institution publique.",
    axe_2: "Responsable communication ou content manager dans le secteur privé ou une startup.",
    axe_3: "Consultant en communication stratégique et personal branding — expert reconnu."
  },
  {
    name: "Développement Territorial",
    slug: "developpement-territorial",
    description: "Climat, urbanisation, aménagement local.",
    key_skills: ["Diagnostic territorial", "Gestion de projets locaux", "Cartographie", "Partenariats publics-privés"],
    first_action: "Identifiez un projet de développement local dans votre commune et rédigez une note de présentation.",
    premium_pitch: "Le Roadmap Premium vous connecte aux réseaux de développement territorial et aux financements.",
    axe_1: "Chargé de développement territorial dans une collectivité locale ou une ONG de développement.",
    axe_2: "Consultant en développement local ou en planification urbaine dans le secteur privé.",
    axe_3: "Expert en aménagement du territoire, urbanisme durable ou gestion environnementale."
  },
  {
    name: "Impact Social & Communautaire",
    slug: "impact-social-communautaire",
    description: "Inclusion, programmes sociaux, mobilisation.",
    key_skills: ["Animation communautaire", "Gestion de programmes sociaux", "Mobilisation des ressources", "Évaluation d'impact"],
    first_action: "Lancez une initiative locale et documentez son impact sur 30 jours.",
    premium_pitch: "Le Roadmap Premium vous aide à créer et financer votre propre projet à impact social.",
    axe_1: "Gestionnaire de programmes sociaux dans une ONG ou une organisation humanitaire.",
    axe_2: "Responsable RSE ou chef de projet impact dans une entreprise ou un fonds social.",
    axe_3: "Fondateur ou directeur d'une structure à impact social — ONG, coopérative, entreprise sociale."
  },
  {
    name: "Digital & Stratégie Contenu",
    slug: "digital-strategie-contenu",
    description: "Stratégie éditoriale, e-learning, communication numérique.",
    key_skills: ["Marketing digital", "Création de contenu", "SEO", "Gestion de communauté"],
    first_action: "Créez un compte professionnel sur une plateforme et publiez 3 contenus en 1 semaine.",
    premium_pitch: "Le Roadmap Premium inclut une formation aux outils digitaux les plus demandés du marché.",
    axe_1: "Community manager ou chargé de communication digitale dans une institution ou ONG.",
    axe_2: "Stratège de contenu ou responsable marketing digital dans une entreprise ou agence.",
    axe_3: "Expert en stratégie digitale, e-learning ou growth hacking — consultant indépendant."
  },
  {
    name: "Data & Transformation",
    slug: "data-transformation",
    description: "Analyse de données sociales, suivi-évaluation digitalisé.",
    key_skills: ["Excel avancé", "Visualisation de données", "Suivi-évaluation", "Bases de données"],
    first_action: "Téléchargez un dataset public et réalisez une analyse simple avec Excel ou Google Sheets.",
    premium_pitch: "Le Roadmap Premium vous guide vers les certifications data (Power BI, Python, Tableau).",
    axe_1: "Chargé de suivi-évaluation ou data analyst dans une ONG, institution ou projet de développement.",
    axe_2: "Analyste de données dans une entreprise, une startup ou un cabinet de conseil.",
    axe_3: "Data scientist ou expert en transformation digitale — spécialisation IA appliquée au secteur social."
  }
]

profiles_data.each do |attrs|
  axe_1 = attrs.delete(:axe_1)
  axe_2 = attrs.delete(:axe_2)
  axe_3 = attrs.delete(:axe_3)

  profile = Profile.find_or_create_by!(slug: attrs[:slug]) do |p|
    p.assign_attributes(attrs)
  end

  unless profile.trajectories.exists?
    profile.trajectories.create!(axe_1: axe_1, axe_2: axe_2, axe_3: axe_3, active: true)
  end
end

puts "✓ #{Profile.count} profils, #{Trajectory.count} trajectoires"

# ===== MOBILE OPERATORS =====
operators = [
  # Côte d'Ivoire
  { name: "Orange Money",     code: "ORANGE_CI",      country_code: "CI" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CI",    country_code: "CI" },
  { name: "Wave",             code: "WAVE_CI",         country_code: "CI" },
  { name: "Moov Money",       code: "MOOV_CI",         country_code: "CI" },
  # Sénégal
  { name: "Orange Money",     code: "ORANGE_SN",       country_code: "SN" },
  { name: "Wave",             code: "WAVE_SN",          country_code: "SN" },
  { name: "Free Money",       code: "FREE_SN",          country_code: "SN" },
  # Cameroun
  { name: "Orange Money",     code: "ORANGE_CM",       country_code: "CM" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CM",     country_code: "CM" },
  # Bénin
  { name: "MTN Mobile Money", code: "MTN_MOMO_BJ",     country_code: "BJ" },
  { name: "Moov Money",       code: "MOOV_BJ",          country_code: "BJ" },
  # Ghana
  { name: "MTN MoMo",         code: "MTN_MOMO_GH",     country_code: "GH" },
  { name: "Vodafone Cash",    code: "VODAFONE_GH",      country_code: "GH" },
  { name: "AirtelTigo Money", code: "AIRTELTIGO_GH",    country_code: "GH" },
  # Togo
  { name: "Flooz",            code: "MOOV_TG",          country_code: "TG" },
  { name: "T-Money",          code: "TOGOCEL_TG",        country_code: "TG" },
]

operators.each do |op|
  MobileOperator.find_or_create_by!(code: op[:code], country_code: op[:country_code]) do |m|
    m.assign_attributes(op.merge(active: true))
  end
end

puts "✓ #{MobileOperator.count} opérateurs mobiles"
