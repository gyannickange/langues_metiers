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

  # Map name to title for unified Career table
  title = attrs.delete(:name)

  career = Career.find_or_initialize_by(slug: attrs[:slug])
  career.assign_attributes(attrs.merge(title: title, status: :published, kind: :behavioral))
  career.save!

  unless career.trajectories.exists?
    career.trajectories.create!(axe_1: axe_1, axe_2: axe_2, axe_3: axe_3, active: true)
  end
end

puts "✓ #{Career.behavioral.count} behavioral profiles (careers), #{Trajectory.count} trajectoires"

# ===== CARRIÈRES / MÉTIERS (20) =====
careers_data = [
  {
    title: "Chargé d’études socio-économiques",
    description: "Ce professionnel analyse les dynamiques sociales, économiques et territoriales pour aider les organisations à prendre des décisions stratégiques. On le retrouve dans les ONG, les institutions publiques, les organisations internationales et les cabinets de conseil.",
    sector: "Sociologie – Géographie – Histoire – Sciences sociales"
  },
  {
    title: "Analyste de politiques publiques",
    description: "L’analyste de politiques publiques étudie les programmes gouvernementaux et les politiques publiques pour mesurer leur impact et proposer des améliorations. Ce métier est très présent dans les institutions publiques, les think tanks et les organisations internationales.",
    sector: "Histoire – Sociologie – Sciences politiques – Géographie"
  },
  {
    title: "Chargé de suivi-évaluation (Monitoring & Evaluation)",
    description: "Le spécialiste du suivi-évaluation analyse les résultats des projets et programmes pour mesurer leur efficacité et améliorer leur impact. C’est un métier très recherché dans les ONG, les agences de développement et les organisations internationales.",
    sector: "Sociologie – Géographie – Statistiques sociales – Développement"
  },
  {
    title: "Chef de projet développement",
    description: "Le chef de projet coordonne des projets dans les domaines du développement, de l’éducation, de la santé ou de l’environnement. Il planifie les activités, mobilise les équipes et s’assure que les objectifs sont atteints.",
    sector: "Histoire – Sociologie – Géographie – Langues – Sciences humaines"
  },
  {
    title: "Consultant en développement",
    description: "Le consultant accompagne les organisations, les ONG et les institutions dans la conception et l’amélioration de leurs programmes de développement. Ce métier demande des capacités d’analyse, de recherche et de stratégie.",
    sector: "Sociologie – Histoire – Géographie – Sciences sociales"
  },
  {
    title: "Responsable communication",
    description: "Le responsable communication conçoit et pilote la stratégie de communication d’une organisation. Il travaille sur les messages, les contenus, les campagnes et l’image publique.",
    sector: "Lettres – Communication – Langues – Sciences humaines"
  },
  {
    title: "Content strategist (stratégie de contenu)",
    description: "Le content strategist conçoit des stratégies de contenu pour les entreprises et les organisations. Il analyse les publics, définit les messages et structure les contenus pour atteindre les objectifs de communication.",
    sector: "Lettres – Langues – Communication – Journalisme"
  },
  {
    title: "Rédacteur stratégique",
    description: "Le rédacteur stratégique produit des contenus à forte valeur ajoutée pour les entreprises, les ONG et les institutions. Il peut rédiger des articles, des rapports, des contenus web ou des documents stratégiques.",
    sector: "Lettres – Langues – Journalisme – Communication"
  },
  {
    title: "Content manager digital",
    description: "Le content manager gère la création et la diffusion des contenus sur les plateformes digitales : sites web, blogs, réseaux sociaux. Ce métier combine rédaction, stratégie et marketing digital.",
    sector: "Langues – Lettres – Communication – Journalisme"
  },
  {
    title: "Concepteur e-learning",
    description: "Le concepteur e-learning crée des formations en ligne et des contenus pédagogiques digitaux. Ce métier est très demandé dans les universités, les entreprises et les plateformes d’apprentissage.",
    sector: "Langues – Lettres – Pédagogie – Sciences humaines"
  },
  {
    title: "Analyste de données sociales",
    description: "Ce professionnel analyse les données sociales pour comprendre les comportements, les tendances et les dynamiques sociales. Il intervient souvent dans les ONG, les instituts de recherche et les organisations internationales.",
    sector: "Sociologie – Géographie – Sciences sociales"
  },
  {
    title: "Chargé de coopération internationale",
    description: "Ce professionnel développe des partenariats entre organisations, institutions et pays. Il travaille sur les projets de coopération, les programmes éducatifs ou culturels.",
    sector: "Langues – Relations internationales – Histoire"
  },
  {
    title: "Responsable partenariats",
    description: "Le responsable partenariats développe des collaborations stratégiques entre organisations, entreprises ou institutions. Il identifie les opportunités et construit des relations durables.",
    sector: "Langues – Communication – Sciences humaines"
  },
  {
    title: "Médiateur culturel",
    description: "Le médiateur culturel conçoit des activités et des programmes pour valoriser la culture et faciliter l’accès du public aux œuvres et au patrimoine.",
    sector: "Histoire – Lettres – Langues – Arts"
  },
  {
    title: "Chargé de projets culturels",
    description: "Il conçoit et coordonne des projets culturels : festivals, expositions, programmes éducatifs ou événements artistiques.",
    sector: "Histoire – Lettres – Arts – Langues"
  },
  {
    title: "Chargé d’aménagement territorial",
    description: "Ce professionnel analyse les dynamiques territoriales et participe à la planification du développement des villes et des territoires.",
    sector: "Géographie – Urbanisme – Développement local"
  },
  {
    title: "Analyste développement local",
    description: "Il travaille sur les stratégies de développement économique et social des territoires.",
    sector: "Géographie – Sociologie – Développement"
  },
  {
    title: "Entrepreneur social",
    description: "L’entrepreneur social crée des projets ou entreprises visant à résoudre des problèmes sociaux ou environnementaux.",
    sector: "Toutes les filières des sciences humaines et sociales"
  },
  {
    title: "Concepteur de programmes éducatifs",
    description: "Il conçoit des programmes de formation et d’apprentissage pour les institutions éducatives, les ONG ou les entreprises.",
    sector: "Langues – Lettres – Pédagogie – Sciences sociales"
  },
  {
    title: "Chargé de plaidoyer",
    description: "Le chargé de plaidoyer défend des causes sociales ou environnementales auprès des institutions publiques et des décideurs.",
    sector: "Sociologie – Sciences politiques – Langues – Histoire"
  }
]

careers_data.each do |data|
  career = Career.find_or_initialize_by(title: data[:title])
  career.assign_attributes(data.merge(status: :published, kind: :profession))
  career.save!
end

puts "✓ #{Career.profession.count} métiers (careers)"
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
  { name: "T-Money",          code: "TOGOCEL_TG",        country_code: "TG" }
]

operators.each do |op|
  MobileOperator.find_or_create_by!(code: op[:code], country_code: op[:country_code]) do |m|
    m.assign_attributes(op.merge(active: true))
  end
end

puts "✓ #{MobileOperator.count} opérateurs mobiles"

# ===== QUESTIONS (25) =====
questions_data = [
  # BLOC 1 – IDENTITÉ PROFESSIONNELLE (5 questions)
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

  # BLOC 2 – RELATION AU MARCHÉ (5 questions)
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

  # BLOC 3 – DIMENSION DIGITALE (5 questions)
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

  # BLOC 4 – POTENTIEL STRATÉGIQUE (5 questions)
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

  # BLOC 5 – CLARTÉ & ACTION (5 questions)
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

questions_data.each do |q|
  Question.find_or_initialize_by(bloc: q[:bloc], position: q[:position]).tap do |question|
    question.text     = q[:text]
    question.kind     = q[:kind] || "mcq"
    question.options  = q[:options]
    question.scored   = true
    question.active   = true
    question.save!
  end
end


puts "✓ #{Question.count} questions de diagnostic"

# ===== DIAGNOSTIC COMPLET (rapport de repositionnement) =====

admin_user = User.find_by(email: "admin@admin.com")

if admin_user && Diagnostic.where(user: admin_user).blank?
  # Récupération des profils pour le diagnostic
  primary   = Career.behavioral.find_by(slug: "coordinateur-strategique")
  secondary = Career.behavioral.find_by(slug: "digital-strategie-contenu")

  # ────────────────────────────────────────────────────────────────────────────
  # RAPPORT DE DIAGNOSTIC – Repositionnement stratégique professionnel
  # Plateforme : Langues & Métiers 4.0
  # Ce score_data contient les 12 sections du rapport complet.
  # ────────────────────────────────────────────────────────────────────────────
  score_data = {

    # ── Section 1 : Informations du participant ──────────────────────────────
    participant_info: {
      nom_prenom:        "Admin Démo",
      email:             "admin@admin.com",
      pays_ville:        "Côte d'Ivoire / Abidjan",
      diplome_principal: "Master en Sciences du Langage",
      domaine_etude:     "Langues et Sciences Humaines",
      niveau_etude:      "Master",
      situation_actuelle: "Diplômé sans emploi",
      date_diagnostic:   Time.current.strftime("%d/%m/%Y")
    },

    # ── Section 2 : Résumé stratégique du diagnostic ─────────────────────────
    resume_strategique: {
      analyse_basee_sur: [
        "Votre formation",
        "Vos compétences",
        "Votre relation au marché",
        "Votre potentiel stratégique",
        "Votre capacité d'adaptation au numérique"
      ],
      objectifs: [
        "Mieux comprendre votre profil professionnel",
        "Identifier les trajectoires professionnelles pertinentes",
        "Structurer un repositionnement stratégique aligné avec le marché"
      ]
    },

    # ── Section 3 : Score global de positionnement ───────────────────────────
    score_legend: {
      "80_100" => { label: "Profil bien positionné",       key: "bien_positionne" },
      "60_79"  => { label: "Profil en construction",       key: "en_construction" },
      "40_59"  => { label: "Positionnement fragile",       key: "fragile" },
      "0_39"   => { label: "Repositionnement nécessaire",  key: "repositionnement_necessaire" }
    },

    clarity_score: {
      label: "Clarté professionnelle",
      raw_points: 7,
      max_points: 11,
      score: 64,
      level: "en_construction"
    },
    market_maturity: {
      label: "Relation au marché",
      raw_points: 5,
      max_points: 10,
      score: 50,
      level: "fragile"
    },
    strategic_potential: {
      label: "Potentiel stratégique",
      raw_points: 4,
      max_points: 5,
      score: 80,
      level: "bien_positionne"
    },
    digital_potential: {
      label: "Dimension digitale",
      raw_points: 5,
      max_points: 10,
      score: 50,
      level: "fragile"
    },
    global_score: {
      score: 61,
      level: "en_construction",
      label: "Score global de positionnement"
    },

    # ── Section 4 : Votre profil dominant ─────────────────────────────────────
    dominant_profile: {
      name: primary&.title || "x",
      slug: primary&.slug || "coordinateur-strategique",
      label: "Profil dominant",
      exemple: "Stratège de projet",
      description: "Votre profil indique une forte capacité à structurer des initiatives, " \
                   "coordonner des projets, organiser des ressources et transformer des idées en actions concrètes.",
      capacites: [
        "Structurer des initiatives",
        "Coordonner des projets",
        "Organiser des ressources",
        "Transformer des idées en actions concrètes"
      ],
      environnements: [
        "ONG",
        "Institutions",
        "Entreprises",
        "Organisations internationales",
        "Startups"
      ]
    },
    secondary_profile: {
      name: secondary&.title || "Digital & Stratégie Contenu",
      slug: secondary&.slug || "digital-strategie-contenu",
      label: "Profil secondaire",
      exemple: "Créateur de contenu",
      description: "Profil secondaire orienté vers la stratégie éditoriale, le e-learning et la communication numérique."
    },

    # ── Section 5 : Vos forces principales ────────────────────────────────────
    forces: {
      intro: "Selon votre diagnostic, vos principales forces sont :",
      liste: [
        "Capacité d'analyse",
        "Capacité de structuration",
        "Communication écrite",
        "Compréhension des dynamiques sociales"
      ],
      conclusion: "Ces forces constituent une base solide pour construire votre trajectoire professionnelle."
    },

    # ── Section 6 : Axes de développement ─────────────────────────────────────
    axes_developpement: {
      intro: "Pour renforcer votre positionnement, les compétences suivantes doivent être développées :",
      liste: [
        "Structuration d'un projet professionnel clair",
        "Maîtrise d'outils numériques stratégiques",
        "Spécialisation sectorielle",
        "Visibilité professionnelle"
      ]
    },

    # ── Section 7 : Trajectoires professionnelles recommandées ────────────────
    trajectoires: {
      liste: [
        {
          rang: 1,
          titre: "Chargé de projet / Coordinateur de programme",
          description: "Pilotage de projets multi-acteurs dans les ONG, institutions ou entreprises."
        },
        {
          rang: 2,
          titre: "Consultant junior en développement ou politiques publiques",
          description: "Accompagnement stratégique dans le secteur public ou les organisations internationales."
        },
        {
          rang: 3,
          titre: "Responsable communication / stratégie de contenu",
          description: "Conception et mise en œuvre de stratégies de communication institutionnelle ou digitale."
        }
      ],
      coherence: [
        "Votre formation",
        "Votre potentiel stratégique",
        "Les besoins actuels du marché"
      ]
    },

    # ── Section 8 : Combinaison stratégique recommandée ───────────────────────
    combinaison_strategique: {
      formule: "Formation académique + compétence digitale + gestion de projet",
      composantes: {
        formation:           "Langues ou sciences humaines",
        competence_digitale: "Communication digitale",
        gestion_projet:      "Gestion de projet"
      },
      note: "Cette combinaison augmente fortement votre employabilité."
    },

    # ── Section 9 : Secteurs professionnels à explorer ────────────────────────
    secteurs: {
      intro: "Les secteurs les plus pertinents pour votre profil sont :",
      liste: [
        "ONG et développement international",
        "Organisations publiques",
        "Communication institutionnelle",
        "Startups et innovation sociale",
        "Cabinets de conseil"
      ]
    },

    # ── Section 10 : Plan d'action – 90 jours ─────────────────────────────────
    plan_action_90_jours: {
      phase_1: {
        periode: "0 à 30 jours",
        objectif: "Clarifier votre trajectoire professionnelle et votre secteur cible.",
        actions: [
          "Identifier votre trajectoire professionnelle",
          "Définir votre secteur cible"
        ]
      },
      phase_2: {
        periode: "30 à 60 jours",
        objectif: "Développer une compétence stratégique complémentaire.",
        actions: [
          "Maîtriser un outil digital",
          "Acquérir une compétence en gestion de projet",
          "Renforcer votre communication professionnelle"
        ]
      },
      phase_3: {
        periode: "60 à 90 jours",
        objectif: "Construire votre visibilité professionnelle.",
        actions: [
          "Repositionner votre CV",
          "Structurer votre profil LinkedIn",
          "Cibler des opportunités concrètes"
        ]
      }
    },

    # ── Section 11 : Recommandation stratégique ────────────────────────────────
    recommandation_strategique: {
      message: "Pour aller plus loin dans votre repositionnement professionnel, " \
               "nous vous recommandons d'accéder à votre Roadmap professionnelle détaillée.",
      roadmap_inclut: [
        "Les compétences précises à développer",
        "Les outils à maîtriser",
        "Les secteurs à cibler",
        "Les stratégies d'insertion professionnelle"
      ]
    },

    # ── Section 12 : Conclusion ────────────────────────────────────────────────
    conclusion: {
      message: "Votre profil possède un potentiel réel. " \
               "Le principal enjeu n'est pas votre diplôme, " \
               "mais la manière dont vous positionnez vos compétences sur le marché.",
      accroche: "Un repositionnement stratégique peut transformer votre trajectoire professionnelle."
    },

    recommended_careers: Career.published.order(Arel.sql('RANDOM()')).limit(6).map do |c|
      { id: c.id, title: c.title, description: c.description, sector: c.sector }
    end
  }

  diagnostic = Diagnostic.create!(
    user:                   admin_user,
    status:                 :completed,
    payment_provider:       :stripe,
    primary_career:         primary,
    complementary_career:   secondary,
    score_data:             score_data,
    pdf_generated:          false,
    paid_at:                2.hours.ago,
    completed_at:           1.hour.ago
  )

  # ===== Réponses aux 25 questions =====
  # Chaque réponse correspond à une sélection cohérente avec le profil "Coordinateur Stratégique"
  sample_answers = [
    # BLOC 1 – IDENTITÉ PROFESSIONNELLE
    { bloc: 1, position: 1,  answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 1, position: 2,  answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 1, position: 3,  answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 1, position: 4,  answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 1, position: 5,  answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },

    # BLOC 2 – RELATION AU MARCHÉ
    { bloc: 2, position: 6,  answer_value: "B", profile_dimension: "market_maturity",          points: 1 },
    { bloc: 2, position: 7,  answer_value: "A", profile_dimension: "market_maturity",          points: 2 },
    { bloc: 2, position: 8,  answer_value: "B", profile_dimension: "market_maturity",          points: 1 },
    { bloc: 2, position: 9,  answer_value: "B", profile_dimension: "market_maturity",          points: 0 },
    { bloc: 2, position: 10, answer_value: "B", profile_dimension: "market_maturity",          points: 1 },

    # BLOC 3 – DIMENSION DIGITALE
    { bloc: 3, position: 11, answer_value: "B", profile_dimension: "digital_potential",        points: 1 },
    { bloc: 3, position: 12, answer_value: "B", profile_dimension: "digital_potential",        points: 0 },
    { bloc: 3, position: 13, answer_value: "C", profile_dimension: "digital_potential",        points: 2 },
    { bloc: 3, position: 14, answer_value: "B", profile_dimension: "digital_potential",        points: 1 },
    { bloc: 3, position: 15, answer_value: "B", profile_dimension: "digital_potential",        points: 1 },

    # BLOC 4 – POTENTIEL STRATÉGIQUE
    { bloc: 4, position: 16, answer_value: "C", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 4, position: 17, answer_value: "D", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 4, position: 18, answer_value: "B", profile_dimension: "impact-social-communautaire", points: 1 },
    { bloc: 4, position: 19, answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },
    { bloc: 4, position: 20, answer_value: "B", profile_dimension: "coordinateur-strategique", points: 1 },

    # BLOC 5 – CLARTÉ & ACTION
    { bloc: 5, position: 21, answer_value: "B", profile_dimension: "clarity_score",            points: 1 },
    { bloc: 5, position: 22, answer_value: "A", profile_dimension: "clarity_score",            points: 2 },
    { bloc: 5, position: 23, answer_value: "A", profile_dimension: "clarity_score",            points: 2 },
    { bloc: 5, position: 24, answer_value: "A", profile_dimension: "clarity_score",            points: 2 },
    { bloc: 5, position: 25, answer_value: "3", profile_dimension: "clarity_score",            points: 3 }
  ]

  sample_answers.each do |sa|
    question = Question.find_by(bloc: sa[:bloc], position: sa[:position])
    next unless question

    DiagnosticAnswer.find_or_create_by!(diagnostic: diagnostic, question: question) do |da|
      da.answer_value      = sa[:answer_value]
      da.profile_dimension = sa[:profile_dimension]
      da.points_awarded    = sa[:points]
    end
  end

  puts "✓ Diagnostic complet créé pour #{admin_user.email} (#{diagnostic.diagnostic_answers.count} réponses)"
else
  puts "⊘ Diagnostic seed ignoré (utilisateur admin absent ou diagnostic déjà existant)"
end
