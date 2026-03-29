# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if User.where(email: "admin@admin.com").blank?
  User.create!(email: "admin@admin.com", password: "password", password_confirmation: "password", role: :admin)
end

# ===== PROFILES (7) =====
profiles_data = [
  {
    name: "Coordinateur Stratégique",
    slug: "coordinateur-strategique",
    description: "Pilotage et gestion de projets multi-acteurs.",
    key_skills: [ "Gestion de projet", "Leadership", "Communication", "Planification stratégique" ],
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
    key_skills: [ "Analyse de données", "Recherche documentaire", "Rédaction de rapports", "Pensée critique" ],
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
    key_skills: [ "Storytelling", "Rédaction", "Réseaux sociaux", "Plaidoyer" ],
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
    key_skills: [ "Diagnostic territorial", "Gestion de projets locaux", "Cartographie", "Partenariats publics-privés" ],
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
    key_skills: [ "Animation communautaire", "Gestion de programmes sociaux", "Mobilisation des ressources", "Évaluation d'impact" ],
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
    key_skills: [ "Marketing digital", "Création de contenu", "SEO", "Gestion de communauté" ],
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
    key_skills: [ "Excel avancé", "Visualisation de données", "Suivi-évaluation", "Bases de données" ],
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
  title = attrs.delete(:name)
  career = Career.find_or_initialize_by(slug: attrs[:slug])
  career.assign_attributes(attrs.merge(title: title, status: :published, kind: :behavioral))
  career.save!
  unless career.trajectories.exists?
    career.trajectories.create!(axe_1: axe_1, axe_2: axe_2, axe_3: axe_3, active: true)
  end
end

puts "✓ #{Career.behavioral.count} profiles comportementaux (careers), #{Trajectory.count} trajectoires"

# ===== CARRIÈRES / MÉTIERS (20) =====
careers_data = [
  { title: "Chargé d’études socio-économiques", description: "Ce professionnel analyse les dynamiques sociales, économiques et territoriales pour aider les organisations à prendre des décisions stratégiques.", sector: "Sociologie – Géographie – Histoire" },
  { title: "Analyste de politiques publiques", description: "L’analyste de politiques publiques étudie les programmes gouvernementaux et les politiques publiques.", sector: "Histoire – Sociologie – Sciences politiques" },
  { title: "Chargé de suivi-évaluation (Monitoring & Evaluation)", description: "Le spécialiste du suivi-évaluation analyse les résultats des projets et programmes.", sector: "Sociologie – Géographie – Statistiques sociales" },
  { title: "Chef de projet développement", description: "Le chef de projet coordonne des projets dans les domaines du développement, de l’éducation, de la santé ou de l’environnement.", sector: "Histoire – Sociologie – Géographie" },
  { title: "Consultant en développement", description: "Le consultant accompagne les organisations, les ONG et les institutions dans la conception.", sector: "Sociologie – Histoire – Géographie" },
  { title: "Responsable communication", description: "Le responsable communication conçoit et pilote la stratégie de communication d’une organisation.", sector: "Lettres – Communication – Langues" },
  { title: "Content strategist (stratégie de contenu)", description: "Le content strategist conçoit des stratégies de contenu pour les entreprises.", sector: "Lettres – Langues – Communication" },
  { title: "Rédacteur stratégique", description: "Le rédacteur stratégique produit des contenus à forte valeur ajoutée.", sector: "Lettres – Langues – Journalisme" },
  { title: "Content manager digital", description: "Le content manager gère la création et la diffusion des contenus sur les plateformes digitales.", sector: "Langues – Lettres – Communication" },
  { title: "Concepteur e-learning", description: "Le concepteur e-learning crée des formations en ligne et des contenus pédagogiques digitaux.", sector: "Langues – Lettres – Pédagogie" },
  { title: "Analyste de données sociales", description: "Ce professionnel analyse les données sociales pour comprendre les comportements.", sector: "Sociologie – Géographie – Sciences sociales" },
  { title: "Chargé de coopération internationale", description: "Ce professionnel développe des partenariats entre organisations, institutions et pays.", sector: "Langues – Relations internationales" },
  { title: "Responsable partenariats", description: "Le responsable partenariats développe des collaborations stratégiques.", sector: "Langues – Communication – Sciences humaines" },
  { title: "Médiateur culturel", description: "Le médiateur culturel conçoit des activités et des programmes pour valoriser la culture.", sector: "Histoire – Lettres – Langues" },
  { title: "Chargé de projets culturels", description: "Il conçoit et coordonne des projets culturels : festivals, expositions.", sector: "Histoire – Lettres – Arts" },
  { title: "Chargé d’aménagement territorial", description: "Ce professionnel analyse les dynamiques territoriales et participe à la planification.", sector: "Géographie – Urbanisme – Développement local" },
  { title: "Analyste développement local", description: "Il travaille sur les stratégies de développement économique et social des territoires.", sector: "Géographie – Sociologie – Développement" },
  { title: "Entrepreneur social", description: "L’entrepreneur social crée des projets ou entreprises visant à résoudre des problèmes sociaux.", sector: "SHS" },
  { title: "Concepteur de programmes éducatifs", description: "Il conçoit des programmes de formation et d’apprentissage.", sector: "Langues – Lettres – Pédagogie" },
  { title: "Chargé de plaidoyer", description: "Le chargé de plaidoyer défend des causes sociales ou environnementales.", sector: "Sociologie – Sciences politiques" }
]

careers_data.each do |data|
  career = Career.find_or_initialize_by(title: data[:title])
  career.assign_attributes(data.merge(status: :published, kind: :profession))
  career.save!
end
puts "✓ #{Career.profession.count} métiers (careers)"

# ===== MOBILE OPERATORS =====
operators = [
  { name: "Orange Money",     code: "ORANGE_CI",      country_code: "CI" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CI",    country_code: "CI" },
  { name: "Wave",             code: "WAVE_CI",         country_code: "CI" },
  { name: "Moov Money",       code: "MOOV_CI",         country_code: "CI" },
  { name: "Orange Money",     code: "ORANGE_SN",       country_code: "SN" },
  { name: "Wave",             code: "WAVE_SN",          country_code: "SN" },
  { name: "Free Money",       code: "FREE_SN",          country_code: "SN" },
  { name: "Orange Money",     code: "ORANGE_CM",       country_code: "CM" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_CM",     country_code: "CM" },
  { name: "MTN Mobile Money", code: "MTN_MOMO_BJ",     country_code: "BJ" },
  { name: "Moov Money",       code: "MOOV_BJ",          country_code: "BJ" },
  { name: "MTN MoMo",         code: "MTN_MOMO_GH",     country_code: "GH" },
  { name: "Vodafone Cash",    code: "VODAFONE_GH",      country_code: "GH" },
  { name: "AirtelTigo Money", code: "AIRTELTIGO_GH",    country_code: "GH" },
  { name: "Flooz",            code: "MOOV_TG",          country_code: "TG" },
  { name: "T-Money",          code: "TOGOCEL_TG",        country_code: "TG" }
]
operators.each do |op|
  MobileOperator.find_or_create_by!(code: op[:code], country_code: op[:country_code]) do |m|
    m.assign_attributes(op.merge(active: true))
  end
end
puts "✓ #{MobileOperator.count} opérateurs mobiles"

# ===== QUESTIONS (25) =====
assessment_questions_data = [
  {
    bloc: 1, position: 1, text: "Lorsque vous décrivez votre profil, vous mettez en avant :",
    options: [
      { value: "A", label: "A", text: "Votre capacité d’analyse", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Votre sens de l’organisation", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Votre créativité", profile_slug: "digital-strategie-contenu", points: 1 },
      { value: "D", label: "D", text: "Votre leadership", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "E", label: "E", text: "Votre capacité à accompagner les autres", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 1, position: 2, text: "Vous vous sentez le plus à l’aise lorsque vous :",
    options: [
      { value: "A", label: "A", text: "Analysez un problème complexe", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Structurez un projet", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Concevez du contenu ou des idées", profile_slug: "communication-influence", points: 1 },
      { value: "D", label: "D", text: "Coordonnez une équipe", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "E", label: "E", text: "Soutenez un projet social", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 1, position: 3, text: "Votre formation vous a principalement appris à :",
    options: [
      { value: "A", label: "A", text: "Rechercher et synthétiser", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Structurer des processus", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Produire des contenus", profile_slug: "communication-influence", points: 1 },
      { value: "D", label: "D", text: "Argumenter et convaincre", profile_slug: "communication-influence", points: 1 },
      { value: "E", label: "E", text: "Comprendre les dynamiques humaines", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 1, position: 4, text: "Face à un défi professionnel, vous :",
    options: [
      { value: "A", label: "A", text: "Faites des recherches approfondies", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Planifiez méthodiquement", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Cherchez une solution innovante", profile_slug: "digital-strategie-contenu", points: 1 },
      { value: "D", label: "D", text: "Prenez une décision rapidement", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "E", label: "E", text: "Consultez les parties prenantes", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 1, position: 5, text: "Votre ambition principale est :",
    options: [
      { value: "A", label: "A", text: "Devenir expert reconnu", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Manager des projets", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Créer des initiatives", profile_slug: "impact-social-communautaire", points: 1 },
      { value: "D", label: "D", text: "Influencer des décisions", profile_slug: "communication-influence", points: 1 },
      { value: "E", label: "E", text: "Avoir un impact social fort", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 2, position: 6, text: "Avez-vous une idée claire des métiers accessibles avec votre diplôme ?",
    options: [
      { value: "A", label: "A", text: "Oui, très claire", profile_slug: "market_maturity", points: 2 },
      { value: "B", label: "B", text: "Partiellement", profile_slug: "market_maturity", points: 1 },
      { value: "C", label: "C", text: "Non", profile_slug: "market_maturity", points: 0 }
    ]
  },
  {
    bloc: 2, position: 7, text: "Avez-vous déjà identifié 3 secteurs précis qui vous intéressent ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "market_maturity", points: 2 },
      { value: "B", label: "B", text: "Non", profile_slug: "market_maturity", points: 0 }
    ]
  },
  {
    bloc: 2, position: 8, text: "Votre CV met-il en valeur des compétences concrètes recherchées ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "market_maturity", points: 2 },
      { value: "B", label: "B", text: "Partiellement", profile_slug: "market_maturity", points: 1 },
      { value: "C", label: "C", text: "Non", profile_slug: "market_maturity", points: 0 }
    ]
  },
  {
    bloc: 2, position: 9, text: "Avez-vous déjà adapté votre profil à un secteur spécifique ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "market_maturity", points: 2 },
      { value: "B", label: "B", text: "Non", profile_slug: "market_maturity", points: 0 }
    ]
  },
  {
    bloc: 2, position: 10, text: "Vous considérez que votre profil est :",
    options: [
      { value: "A", label: "A", text: "Bien positionné", profile_slug: "market_maturity", points: 2 },
      { value: "B", label: "B", text: "Sous-exploité", profile_slug: "market_maturity", points: 1 },
      { value: "C", label: "C", text: "Mal positionné", profile_slug: "market_maturity", points: 0 }
    ]
  },
  {
    bloc: 3, position: 11, text: "Vous utilisez régulièrement des outils numériques professionnels ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "digital_potential", points: 2 },
      { value: "B", label: "B", text: "Occasionnellement", profile_slug: "digital_potential", points: 1 },
      { value: "C", label: "C", text: "Très peu", profile_slug: "digital_potential", points: 0 }
    ]
  },
  {
    bloc: 3, position: 12, text: "Vous maîtrisez au moins un outil digital stratégique (ex : gestion projet, data, création contenu) ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "digital_potential", points: 2 },
      { value: "B", label: "B", text: "Non", profile_slug: "digital_potential", points: 0 }
    ]
  },
  {
    bloc: 3, position: 13, text: "Vous avez déjà travaillé sur :",
    options: [
      { value: "A", label: "A", text: "Analyse de données", profile_slug: "data-transformation", points: 2 },
      { value: "B", label: "B", text: "Création de contenu digital", profile_slug: "digital-strategie-contenu", points: 2 },
      { value: "C", label: "C", text: "Gestion de projet digital", profile_slug: "digital_potential", points: 2 },
      { value: "D", label: "D", text: "Aucun", profile_slug: "digital_potential", points: 0 }
    ]
  },
  {
    bloc: 3, position: 14, text: "Votre présence professionnelle en ligne (LinkedIn ou autre) est :",
    options: [
      { value: "A", label: "A", text: "Structurée et active", profile_slug: "digital_potential", points: 2 },
      { value: "B", label: "B", text: "Basique", profile_slug: "digital_potential", points: 1 },
      { value: "C", label: "C", text: "Inexistante", profile_slug: "digital_potential", points: 0 }
    ]
  },
  {
    bloc: 3, position: 15, text: "Êtes-vous à l’aise avec l’apprentissage d’outils numériques ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "digital_potential", points: 2 },
      { value: "B", label: "B", text: "Moyennement", profile_slug: "digital_potential", points: 1 },
      { value: "C", label: "C", text: "Non", profile_slug: "digital_potential", points: 0 }
    ]
  },
  {
    bloc: 4, position: 16, text: "Vous prenez des décisions plutôt :",
    options: [
      { value: "A", label: "A", text: "Basées sur les données", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Basées sur l’intuition", profile_slug: "communication-influence", points: 1 },
      { value: "C", label: "C", text: "Basées sur l’expérience", profile_slug: "coordinateur-strategique", points: 1 }
    ]
  },
  {
    bloc: 4, position: 17, text: "Vous préférez :",
    options: [
      { value: "A", label: "A", text: "Analyser", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Exécuter", profile_slug: "developpement-territorial", points: 1 },
      { value: "C", label: "C", text: "Concevoir", profile_slug: "digital-strategie-contenu", points: 1 },
      { value: "D", label: "D", text: "Coordonner", profile_slug: "coordinateur-strategique", points: 1 }
    ]
  },
  {
    bloc: 4, position: 18, text: "Vous êtes plus motivé par :",
    options: [
      { value: "A", label: "A", text: "Expertise", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Impact", profile_slug: "impact-social-communautaire", points: 1 },
      { value: "C", label: "C", text: "Influence", profile_slug: "communication-influence", points: 1 },
      { value: "D", label: "D", text: "Innovation", profile_slug: "digital-strategie-contenu", points: 1 }
    ]
  },
  {
    bloc: 4, position: 19, text: "Vous vous projetez dans :",
    options: [
      { value: "A", label: "A", text: "Conseil / stratégie", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "B", label: "B", text: "Gestion / coordination", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Digital / innovation", profile_slug: "digital-strategie-contenu", points: 1 },
      { value: "D", label: "D", text: "Secteur social / ONG", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 4, position: 20, text: "Face à un échec, vous :",
    options: [
      { value: "A", label: "A", text: "Analysez les causes", profile_slug: "analyste-veille", points: 1 },
      { value: "B", label: "B", text: "Ajustez rapidement", profile_slug: "coordinateur-strategique", points: 1 },
      { value: "C", label: "C", text: "Cherchez du soutien", profile_slug: "impact-social-communautaire", points: 1 }
    ]
  },
  {
    bloc: 5, position: 21, text: "Avez-vous un plan professionnel à 2 ans ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "clarity_score", points: 2 },
      { value: "B", label: "B", text: "Partiellement", profile_slug: "clarity_score", points: 1 },
      { value: "C", label: "C", text: "Non", profile_slug: "clarity_score", points: 0 }
    ]
  },
  {
    bloc: 5, position: 22, text: "Savez-vous quelles compétences développer dans les 6 prochains mois ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "clarity_score", points: 2 },
      { value: "B", label: "B", text: "Non", profile_slug: "clarity_score", points: 0 }
    ]
  },
  {
    bloc: 5, position: 23, text: "Avez-vous identifié un secteur prioritaire ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "clarity_score", points: 2 },
      { value: "B", label: "B", text: "Non", profile_slug: "clarity_score", points: 0 }
    ]
  },
  {
    bloc: 5, position: 24, text: "Êtes-vous prêt à vous repositionner stratégiquement ?",
    options: [
      { value: "A", label: "A", text: "Oui", profile_slug: "clarity_score", points: 2 },
      { value: "B", label: "B", text: "J’hésite", profile_slug: "clarity_score", points: 1 },
      { value: "C", label: "C", text: "Non", profile_slug: "clarity_score", points: 0 }
    ]
  },
  {
    bloc: 5, position: 25, text: "Sur une échelle de 1 à 5, votre clarté professionnelle actuelle est :",
    kind: "likert",
    options: [
      { value: "1", text: "Très floue",  profile_slug: "clarity_score", points: 1 },
      { value: "2", text: "Floue",       profile_slug: "clarity_score", points: 2 },
      { value: "3", text: "Moyenne",     profile_slug: "clarity_score", points: 3 },
      { value: "4", text: "Assez claire", profile_slug: "clarity_score", points: 4 },
      { value: "5", text: "Très claire",  profile_slug: "clarity_score", points: 5 }
    ]
  }
]

assessment_questions_data.each do |q|
  AssessmentQuestion.find_or_initialize_by(bloc: q[:bloc], position: q[:position]).tap do |aq|
    aq.text     = q[:text]
    aq.kind     = q[:kind] || "mcq"
    aq.options  = q[:options]
    aq.scored   = true
    aq.active   = true
    aq.save!
  end
end
puts "✓ #{AssessmentQuestion.count} questions d'évaluation"

admin_user = User.find_by(email: "admin@admin.com")
if admin_user && Diagnostic.where(user: admin_user).blank?
  primary   = Career.behavioral.find_by(slug: "coordinateur-strategique")
  secondary = Career.behavioral.find_by(slug: "digital-strategie-contenu")
  score_data = {
    participant_info: { nom_prenom: "Admin Démo", email: "admin@admin.com", pays_ville: "CI", diplome_principal: "Master", domaine_etude: "Langues", niveau_etude: "Master", situation_actuelle: "Diplômé", date_diagnostic: Time.current.strftime("%d/%m/%Y") },
    dominant_profile: { name: primary&.title, slug: primary&.slug, label: "Profil dominant" },
    secondary_profile: { name: secondary&.title, slug: secondary&.slug, label: "Profil secondaire" },
    global_score: { score: 75, level: "bien_positionne", label: "Score global" }
  }
  diagnostic = Diagnostic.create!(user: admin_user, status: :completed, payment_provider: :stripe, primary_career: primary, complementary_career: secondary, score_data: score_data, paid_at: 2.hours.ago, completed_at: 1.hour.ago)

  (1..25).each do |pos|
    aq = AssessmentQuestion.find_by(position: pos)
    next unless aq
    DiagnosticAnswer.create!(diagnostic: diagnostic, assessment_question: aq, answer_value: "B", profile_dimension: "coordinateur-strategique", points_awarded: 1)
  end
  puts "✓ Diagnostic complet créé pour #{admin_user.email}"
end
