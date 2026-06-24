# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if User.where(email: "admin@admin.com").blank?
  User.create!(email: "admin@admin.com", password: "password", password_confirmation: "password", role: :admin)
end

# ===== FILIÈRES (8) =====
filieres_data = [
  { slug: "langues",  name: "Langues",                       position: 1 },
  { slug: "geo",       name: "Géographie & territoires",       position: 2 },
  { slug: "socio",     name: "Sociologie",                     position: 3 },
  { slug: "lettres",   name: "Lettres",                        position: 4 },
  { slug: "psycho",    name: "Psychologie",                    position: 5 },
  { slug: "philo",     name: "Philosophie",                    position: 6 },
  { slug: "histoire",  name: "Histoire",                       position: 7 },
  { slug: "edu",       name: "Sciences de l'éducation",        position: 8 }
]
filieres_data.each do |attrs|
  Filiere.find_or_create_by!(slug: attrs[:slug]) { |f| f.assign_attributes(attrs) }
end
puts "✓ #{Filiere.count} filières"

# ===== COMPÉTENCES (12) =====
competences_data = [
  { slug: "langues_etrangeres",   name: "Langues étrangères",            position: 1 },
  { slug: "communication_ecrite", name: "Communication écrite",          position: 2 },
  { slug: "communication_orale",  name: "Communication orale",           position: 3 },
  { slug: "analyse_donnees",      name: "Analyse de données",            position: 4 },
  { slug: "gestion_projet",       name: "Gestion de projet",             position: 5 },
  { slug: "numerique",            name: "Compétences numériques",        position: 6 },
  { slug: "negociation",          name: "Négociation",                   position: 7 },
  { slug: "creativite",           name: "Créativité",                    position: 8 },
  { slug: "ecoute",               name: "Écoute active",                 position: 9 },
  { slug: "rigueur_scientifique", name: "Rigueur et méthode",            position: 10 },
  { slug: "culture_generale",     name: "Culture générale",              position: 11 },
  { slug: "droit_politiques",     name: "Droit et politiques publiques", position: 12 }
]
competences_data.each do |attrs|
  Skill.find_or_create_by!(slug: attrs[:slug]) { |s| s.assign_attributes(attrs) }
end
puts "✓ #{Skill.count} compétences"

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

# ===== ASSESSMENT =====
assessment = Assessment.find_or_initialize_by(title: "Diagnostic Langues & Métiers")
assessment.assign_attributes(description: "Diagnostic d'orientation par filière, profil DISC, affinités métiers et compétences.", active: true)
assessment.save!

# ===== 37 MÉTIERS (Career) =====
careers_data = [
  { title: "Traducteur / Interprète",                  filiere_slug: "langues",   disc_types: %w[C S], required_competences: %w[langues_etrangeres communication_ecrite culture_generale],        affirmations: [ "Je suis passionné(e) par les nuances linguistiques entre les langues.", "Je peux reformuler un texte complexe sans en perdre le sens.", "Je suis à l'aise pour travailler seul(e) de façon concentrée et rigoureuse.", "J'aime décoder les subtilités culturelles derrière les mots.", "Je peux jongler entre plusieurs langues dans une même journée." ] },
  { title: "Chargé de communication internationale",   filiere_slug: "langues",   disc_types: %w[I D], required_competences: %w[communication_ecrite communication_orale langues_etrangeres],     affirmations: [ "J'aime concevoir des messages clairs pour des publics internationaux.", "Je maîtrise les codes culturels de différents pays.", "Je me sens à l'aise pour représenter une organisation à l'extérieur.", "Adapter un discours à différentes audiences m'intéresse.", "La communication interculturelle est une force que je veux développer." ] },
  { title: "Responsable export",                       filiere_slug: "langues",   disc_types: %w[D I], required_competences: %w[negociation langues_etrangeres gestion_projet],                    affirmations: [ "Je suis attiré(e) par le commerce international et les marchés étrangers.", "Négocier des contrats avec des partenaires étrangers m'attire.", "Je suis capable de gérer une équipe commerciale à distance.", "Les voyages professionnels fréquents ne me posent pas de problème.", "Je suis motivé(e) par les objectifs chiffrés et les résultats mesurables." ] },
  { title: "Localisation Manager",                     filiere_slug: "langues",   disc_types: %w[C S], required_competences: %w[langues_etrangeres gestion_projet numerique],                      affirmations: [ "Adapter un produit numérique à différentes cultures m'intéresse.", "Je comprends les enjeux techniques de la traduction logicielle.", "Gérer des projets multilingues avec plusieurs prestataires me plaît.", "La qualité et la cohérence des contenus sont primordiales pour moi.", "Je suis à l'aise avec les outils de gestion de la traduction (CAT tools)." ] },
  { title: "Diplomate",                                filiere_slug: "langues",   disc_types: %w[D C], required_competences: %w[langues_etrangeres negociation droit_politiques],                  affirmations: [ "Les relations internationales et la géopolitique me passionnent.", "Je suis capable de défendre une position complexe avec tact et conviction.", "Représenter un État ou une institution dans un contexte formel m'attire.", "Je maîtrise les règles du protocole diplomatique.", "Je suis prêt(e) à m'expatrier pour des missions de longue durée." ] },
  { title: "Urbaniste",                                filiere_slug: "geo",       disc_types: %w[C S], required_competences: %w[analyse_donnees gestion_projet droit_politiques],                  affirmations: [ "Concevoir des villes durables et inclusives est un projet qui me tient à cœur.", "J'aime analyser les usages des espaces publics.", "Je peux lire et produire des plans d'aménagement urbain.", "Équilibrer contraintes réglementaires et vision créative m'intéresse.", "Travailler avec des élus, des habitants et des techniciens me convient." ] },
  { title: "Cartographe / Géomaticien",                filiere_slug: "geo",       disc_types: %w[C S], required_competences: %w[analyse_donnees numerique rigueur_scientifique],                   affirmations: [ "La cartographie et la représentation spatiale des données m'enthousiasment.", "Je maîtrise ou souhaite maîtriser des outils SIG comme QGIS ou ArcGIS.", "Les données géographiques sont pour moi une source d'informations précieuse.", "Je peux synthétiser des informations complexes en une carte lisible.", "L'exactitude et la rigueur dans la représentation graphique sont essentielles." ] },
  { title: "Consultant en développement local",        filiere_slug: "geo",       disc_types: %w[D I], required_competences: %w[gestion_projet negociation analyse_donnees],                       affirmations: [ "Aider des territoires défavorisés à se redynamiser est une vocation pour moi.", "Je suis à l'aise pour mener des diagnostics territoriaux.", "Coordonner des acteurs publics, privés et associatifs me plaît.", "Je peux rédiger des rapports d'analyse pour des décideurs.", "Les enjeux de développement rural et péri-urbain m'intéressent." ] },
  { title: "Chargé de mission environnement",          filiere_slug: "geo",       disc_types: %w[S C], required_competences: %w[rigueur_scientifique communication_ecrite gestion_projet],         affirmations: [ "Les questions environnementales et écologiques sont au cœur de mes valeurs.", "Je peux rédiger des études d'impact et des plans d'action environnementaux.", "Sensibiliser des équipes à la démarche RSE m'enthousiasme.", "Je suis capable de suivre des indicateurs environnementaux sur le long terme.", "Collaborer avec des services techniques et des partenaires institutionnels me convient." ] },
  { title: "UX Researcher",                            filiere_slug: "socio",     disc_types: %w[C S], required_competences: %w[analyse_donnees communication_ecrite numerique],                   affirmations: [ "Comprendre les comportements humains face aux interfaces numériques m'intéresse.", "Je suis à l'aise pour concevoir et animer des entretiens utilisateurs.", "J'aime synthétiser des données qualitatives en recommandations actionnables.", "Les méthodologies de recherche (observation, test A/B, persona) me sont familières.", "Travailler en équipe avec des designers et des développeurs me plaît." ] },
  { title: "Statisticien social",                      filiere_slug: "socio",     disc_types: %w[C S], required_competences: %w[analyse_donnees rigueur_scientifique numerique],                   affirmations: [ "L'analyse statistique de données sociales est une activité qui m'enthousiasme.", "Je maîtrise ou veux maîtriser des outils comme R, SPSS ou Python.", "Transformer des chiffres bruts en insights exploitables est un défi qui me motive.", "Je suis rigoureux(se) dans le traitement et la vérification des données.", "Produire des rapports quantitatifs pour des décideurs m'intéresse." ] },
  { title: "Consultant D&I",                           filiere_slug: "socio",     disc_types: %w[I S], required_competences: %w[communication_orale negociation culture_generale],                 affirmations: [ "Promouvoir la diversité et l'inclusion au sein des organisations est une mission qui me tient à cœur.", "Je suis capable d'animer des formations sur la discrimination et les biais inconscients.", "Accompagner des changements culturels au sein des entreprises m'attire.", "Je peux concevoir des politiques RH inclusives.", "Travailler avec des directions générales sur des sujets sensibles ne me fait pas peur." ] },
  { title: "Chargé de projet ONG",                     filiere_slug: "socio",     disc_types: %w[S I], required_competences: %w[gestion_projet communication_orale langues_etrangeres],            affirmations: [ "Je suis motivé(e) par les causes humanitaires et sociales.", "Coordonner des projets de terrain dans des contextes difficiles m'attire.", "Je peux gérer un budget et rédiger des rapports pour des bailleurs de fonds.", "Travailler dans des environnements multiculturels et souvent précaires me convient.", "La mobilité internationale est compatible avec mon mode de vie." ] },
  { title: "Analyste en intelligence culturelle",      filiere_slug: "socio",     disc_types: %w[C I], required_competences: %w[analyse_donnees langues_etrangeres culture_generale],              affirmations: [ "L'analyse des identités culturelles dans un contexte globalisé m'intéresse.", "Je peux produire des études sur les comportements interculturels pour des entreprises.", "Je maîtrise des méthodologies mixtes (quantitatives et qualitatives).", "Conseiller des organisations sur leur stratégie interculturelle m'attire.", "Les questions d'appartenance, de représentation et de culture organisationnelle me passionnent." ] },
  { title: "UX Writer",                                filiere_slug: "lettres",   disc_types: %w[C S], required_competences: %w[communication_ecrite numerique creativite],                        affirmations: [ "Rédiger des contenus clairs pour des applications numériques m'intéresse.", "Je comprends les principes de l'expérience utilisateur (UX).", "Je peux adapter mon style d'écriture à différents tons et contextes.", "La cohérence éditoriale dans un produit digital est primordiale pour moi.", "Collaborer avec des designers et des chefs de produit me plaît." ] },
  { title: "Content Designer",                         filiere_slug: "lettres",   disc_types: %w[I C], required_competences: %w[creativite communication_ecrite numerique],                        affirmations: [ "Concevoir des expériences de contenu engageantes pour le numérique m'enthousiasme.", "Je mêle stratégie éditoriale et sens du design.", "Je peux créer des contenus interactifs et pédagogiques.", "Tester et itérer sur des formats de contenu est une démarche que j'apprécie.", "Je suis à l'aise avec les outils de prototypage et de création de contenu." ] },
  { title: "Correcteur / Réviseur éditorial",          filiere_slug: "lettres",   disc_types: %w[C S], required_competences: %w[communication_ecrite rigueur_scientifique culture_generale],       affirmations: [ "La relecture minutieuse de textes est une activité que je pratique avec plaisir.", "Je détecte instinctivement les erreurs de syntaxe, d'orthographe et de style.", "Je connais les normes typographiques et éditoriales professionnelles.", "Je peux travailler sur des volumes importants de textes avec concentration.", "La langue française et ses règles me fascinent." ] },
  { title: "Auteur / Scénariste",                      filiere_slug: "lettres",   disc_types: %w[I C], required_competences: %w[creativite communication_ecrite culture_generale],                 affirmations: [ "Écrire des histoires ou des scénarios est une passion qui me définit.", "Je peux développer des univers narratifs cohérents et originaux.", "La fiction comme outil de réflexion sur la société m'intéresse.", "Je suis prêt(e) à accepter l'incertitude économique liée à la carrière d'auteur.", "Les processus créatifs et la réécriture font partie intégrante de mon travail." ] },
  { title: "Responsable éditorial",                    filiere_slug: "lettres",   disc_types: %w[D C], required_competences: %w[gestion_projet communication_ecrite creativite],                   affirmations: [ "Piloter la ligne éditoriale d'une revue, d'un éditeur ou d'un média m'attire.", "Je peux gérer une équipe de rédacteurs et de correcteurs.", "L'identification de nouveaux talents et sujets éditoriaux m'enthousiasme.", "Je comprends les enjeux économiques de l'édition (ventes, droits, diffusion).", "Arbitrer entre créativité et contraintes commerciales est un défi que j'accepte." ] },
  { title: "Consultant RH / DRH",                      filiere_slug: "psycho",    disc_types: %w[D I], required_competences: %w[negociation communication_orale gestion_projet],                   affirmations: [ "Accompagner les organisations dans leur gestion des ressources humaines m'intéresse.", "Je peux mener des audits RH et proposer des plans d'amélioration.", "La négociation sociale et le dialogue avec les partenaires sociaux ne me font pas peur.", "Je suis à l'aise pour présenter des recommandations à des comités de direction.", "Les enjeux de transformation des organisations (digitalisation, RSE) m'animent." ] },
  { title: "Psychologue du travail",                   filiere_slug: "psycho",    disc_types: %w[S C], required_competences: %w[communication_orale rigueur_scientifique ecoute],                  affirmations: [ "Comprendre les dynamiques psychologiques au sein des organisations m'intéresse.", "Je peux réaliser des bilans de compétences et des évaluations psychométriques.", "Accompagner des personnes en souffrance au travail (burnout, conflits) m'attire.", "Je maîtrise ou veux maîtriser les outils d'évaluation psychologique (MBTI, 16PF…).", "Intervenir dans des contextes de crise organisationnelle me convient." ] },
  { title: "Coach professionnel",                      filiere_slug: "psycho",    disc_types: %w[I S], required_competences: %w[communication_orale ecoute negociation],                           affirmations: [ "Accompagner des individus dans leur développement personnel et professionnel est ma vocation.", "Je pose des questions puissantes plutôt que de donner des réponses toutes faites.", "Je suis à l'aise pour créer un espace de confiance et de bienveillance.", "Les techniques de coaching (PNL, analyse transactionnelle, pleine conscience) m'intéressent.", "Je suis prêt(e) à me certifier et à exercer en libéral." ] },
  { title: "Ingénieur pédagogique",                    filiere_slug: "psycho",    disc_types: %w[C S], required_competences: %w[gestion_projet numerique communication_ecrite],                    affirmations: [ "Concevoir des dispositifs de formation sur mesure m'enthousiasme.", "Je maîtrise ou veux maîtriser des logiciels de création e-learning (Articulate, Rise…).", "Adapter les contenus aux besoins des apprenants adultes m'intéresse.", "Je travaille de façon méthodique selon des référentiels pédagogiques reconnus.", "Collaborer avec des experts métier pour structurer leurs savoirs me plaît." ] },
  { title: "Ergonome",                                 filiere_slug: "psycho",    disc_types: %w[C S], required_competences: %w[analyse_donnees rigueur_scientifique numerique],                   affirmations: [ "Améliorer les conditions de travail et les interfaces homme-machine m'intéresse.", "Je peux réaliser des analyses d'activité et des études de poste.", "La prévention des risques professionnels (TMS, RPS) est un enjeu qui me mobilise.", "Je suis à l'aise pour observer, interviewer et synthétiser des données de terrain.", "Travailler à l'interface entre technique, humain et organisation me convient." ] },
  { title: "Éthicien en IA",                           filiere_slug: "philo",     disc_types: %w[C D], required_competences: %w[rigueur_scientifique communication_ecrite numerique],              affirmations: [ "Les enjeux éthiques liés à l'intelligence artificielle me préoccupent profondément.", "Je peux analyser des systèmes algorithmiques pour en déceler les biais.", "Rédiger des chartes éthiques et des cadres de gouvernance des données m'intéresse.", "Je suis capable de vulgariser des concepts complexes pour des publics non techniques.", "Travailler avec des équipes techniques, juridiques et managériales me convient." ] },
  { title: "Analyste en politiques publiques",         filiere_slug: "philo",     disc_types: %w[C D], required_competences: %w[analyse_donnees droit_politiques communication_ecrite],            affirmations: [ "L'évaluation des politiques publiques et leur impact social m'intéresse.", "Je peux produire des notes de synthèse pour des décideurs politiques.", "La modélisation des effets des réformes sur les populations m'attire.", "Je suis à l'aise avec les sources institutionnelles (rapports, données officielles).", "Travailler dans un think tank, un cabinet ou une administration centrale me motive." ] },
  { title: "Consultant en stratégie",                  filiere_slug: "philo",     disc_types: %w[D C], required_competences: %w[negociation analyse_donnees gestion_projet],                      affirmations: [ "Résoudre des problèmes complexes pour des organisations est ce qui me motive le plus.", "Je peux structurer un raisonnement en hypothèses et recommandations claires.", "Travailler dans des secteurs variés sur des missions courtes et intenses me convient.", "Les outils de la stratégie (SWOT, matrices de portefeuille, business cases) me sont naturels.", "Je suis prêt(e) à investir du temps dans des missions exigeantes à fort enjeu." ] },
  { title: "Rédacteur juridique",                      filiere_slug: "philo",     disc_types: %w[C S], required_competences: %w[communication_ecrite droit_politiques rigueur_scientifique],       affirmations: [ "La rédaction de textes juridiques précis et sans ambiguïté m'attire.", "Je comprends la structure et la logique des textes de droit.", "Adapter un langage technique à des non-juristes est une compétence que j'affectionne.", "Je peux rédiger des contrats, notes juridiques et supports de conformité.", "La rigueur terminologique dans le domaine juridique est une priorité pour moi." ] },
  { title: "Archiviste / Documentaliste",              filiere_slug: "histoire",  disc_types: %w[C S], required_competences: %w[rigueur_scientifique culture_generale numerique],                  affirmations: [ "La conservation et la valorisation des archives historiques me passionnent.", "Je peux classer, indexer et numériser des fonds documentaires.", "L'accès à la mémoire collective et institutionnelle est une mission qui a du sens pour moi.", "Je suis rigoureux(se) et méthodique dans le traitement des documents.", "Travailler en bibliothèque, aux Archives nationales ou en entreprise me convient." ] },
  { title: "Médiateur culturel",                       filiere_slug: "histoire",  disc_types: %w[I S], required_competences: %w[communication_orale culture_generale creativite],                  affirmations: [ "Mettre en relation le public avec le patrimoine culturel et artistique m'enthousiasme.", "Je peux concevoir et animer des visites, ateliers et événements culturels.", "La médiation entre les œuvres et les publics éloignés de la culture m'intéresse.", "Je suis à l'aise pour parler devant des groupes variés (enfants, adultes, scolaires).", "Travailler dans des musées, centres d'art ou territoires culturels me motive." ] },
  { title: "Guide touristique",                        filiere_slug: "histoire",  disc_types: %w[I S], required_competences: %w[communication_orale langues_etrangeres culture_generale],          affirmations: [ "Partager ma passion pour l'histoire et le patrimoine avec des visiteurs me comble.", "Je suis à l'aise pour parler en public de façon dynamique et pédagogique.", "Je peux m'adapter à des publics très différents (touristes, scolaires, professionnels).", "Maîtriser plusieurs langues pour guider des groupes internationaux m'attire.", "Travailler dans des sites patrimoniaux ou touristiques est un environnement qui me plaît." ] },
  { title: "Data analyst culturel",                    filiere_slug: "histoire",  disc_types: %w[C D], required_competences: %w[analyse_donnees numerique culture_generale],                       affirmations: [ "L'analyse de données culturelles (fréquentation, pratiques, tendances) m'intéresse.", "Je maîtrise ou veux maîtriser des outils comme Excel, Python ou Tableau.", "Trouver des insights dans les données pour éclairer des décisions culturelles m'attire.", "Je peux produire des tableaux de bord et des rapports analytiques.", "Travailler au service d'institutions culturelles (musées, collectivités, médias) me motive." ] },
  { title: "Instructional Designer",                   filiere_slug: "edu",       disc_types: %w[C S], required_competences: %w[gestion_projet numerique communication_ecrite],                    affirmations: [ "Concevoir des parcours de formation engageants et efficaces est ma vocation.", "Je travaille en étroite collaboration avec des experts pour structurer leurs connaissances.", "Les théories de l'apprentissage (cognitivisme, socioconstructivisme) me guident.", "Je peux produire des storyboards et des modules e-learning complets.", "L'évaluation de l'efficacité des formations est une étape que j'inclus systématiquement." ] },
  { title: "Formateur",                                filiere_slug: "edu",       disc_types: %w[I S], required_competences: %w[communication_orale ecoute creativite],                            affirmations: [ "Transmettre des compétences et des savoirs à des adultes est une passion.", "Je peux animer des sessions de formation de façon dynamique et inclusive.", "Adapter mon discours pédagogique à des profils et niveaux très différents me plaît.", "Je crée des supports de formation clairs et attractifs (slides, fiches, vidéos).", "Le feedback des apprenants m'aide à m'améliorer continuellement." ] },
  { title: "Chef de projet e-learning",                filiere_slug: "edu",       disc_types: %w[D C], required_competences: %w[gestion_projet numerique gestion_projet],                         affirmations: [ "Piloter des projets de formation en ligne de A à Z m'intéresse.", "Je coordonne des équipes pluridisciplinaires (pédagogues, développeurs, graphistes).", "Je maîtrise ou veux maîtriser des LMS comme Moodle, 360Learning ou Cornerstone.", "Respecter des délais, des budgets et des cahiers des charges est une discipline naturelle pour moi.", "L'innovation pédagogique (serious game, social learning, IA) m'enthousiasme." ] },
  { title: "Conseiller en orientation",                filiere_slug: "edu",       disc_types: %w[S I], required_competences: %w[ecoute communication_orale culture_generale],                      affirmations: [ "Accompagner des individus dans leurs choix de carrière est un métier qui a du sens pour moi.", "Je sais écouter sans juger et reformuler avec précision.", "Je connais les mécanismes du marché du travail et les dispositifs d'orientation.", "Aider une personne à identifier ses forces et ses valeurs est un exercice que j'apprécie.", "Travailler dans un lycée, une université ou un cabinet de conseil en évolution professionnelle me convient." ] },
  { title: "Consultant en transformation digitale",    filiere_slug: "edu",       disc_types: %w[D C], required_competences: %w[numerique gestion_projet negociation],                            affirmations: [ "Accompagner des organisations dans leur transformation numérique m'enthousiasme.", "Je comprends les enjeux stratégiques liés à la data, l'IA et les nouveaux usages.", "Je peux diagnostiquer la maturité digitale d'une organisation et proposer une feuille de route.", "La gestion du changement et l'accompagnement humain dans les projets digitaux m'intéressent.", "Travailler en transverse avec les directions métier, IT et RH me convient." ] }
]

Career.diagnostic.find_by(title: "Guide touristique / patrimonial")&.update!(title: "Guide touristique")

seeded_career_ids = careers_data.map do |attrs|
  career = Career.find_or_initialize_by(title: attrs[:title])
  career.assign_attributes(
    status: :published,
    kind: :profession,
    filiere_slug: attrs[:filiere_slug],
    disc_types: attrs[:disc_types],
    required_competences: attrs[:required_competences],
    affirmations: attrs[:affirmations]
  )
  career.save!
  career.trajectories.create!(axe_1: "Poste junior dans une organisation — première expérience terrain.", axe_2: "Montée en responsabilités — expert ou chef de projet.", axe_3: "Expert reconnu ou consultant indépendant — leadership sectoriel.") unless career.trajectories.exists?
  career.id
end
Career.diagnostic.where.not(id: seeded_career_ids).destroy_all
puts "✓ #{Career.diagnostic.count} métiers avec profil diagnostic"

# ===== 16 QUESTIONS FILIÈRE (Likert 1–5, 2 par filière) =====
interest_questions = [
  { text: "Les langues étrangères et la richesse des cultures qu'elles véhiculent me passionnent.",               filiere_slug: "langues",  position: 1  },
  { text: "Lire ou traduire des textes dans une autre langue est une activité qui me captive.",                    filiere_slug: "langues",  position: 2  },
  { text: "Les dynamiques des territoires, l'urbanisme et l'aménagement de l'espace m'intéressent profondément.", filiere_slug: "geo",      position: 3  },
  { text: "Analyser des cartes, comprendre les flux migratoires ou les inégalités spatiales me fascine.",          filiere_slug: "geo",      position: 4  },
  { text: "Observer et comprendre les comportements humains au sein des sociétés est ce qui me motive.",           filiere_slug: "socio",    position: 5  },
  { text: "Les questions de diversité, d'identité culturelle et d'inégalités sociales m'animent.",                filiere_slug: "socio",    position: 6  },
  { text: "Écrire, analyser des textes littéraires ou travailler la langue française est une vocation pour moi.", filiere_slug: "lettres",  position: 7  },
  { text: "La narration, la critique littéraire et le travail sur le style m'enthousiasment.",                     filiere_slug: "lettres",  position: 8  },
  { text: "Comprendre le fonctionnement de l'esprit humain, les émotions et les comportements me passionne.",     filiere_slug: "psycho",   position: 9  },
  { text: "Accompagner des personnes dans leur développement ou résoudre des problèmes psychologiques m'attire.", filiere_slug: "psycho",   position: 10 },
  { text: "Questionner les idées, débattre de concepts abstraits et construire des arguments rigoureux me plaît.", filiere_slug: "philo",    position: 11 },
  { text: "Les grandes questions éthiques, politiques ou existentielles stimulent ma réflexion.",                  filiere_slug: "philo",    position: 12 },
  { text: "Comprendre les événements passés et leur impact sur le monde actuel me passionne.",                    filiere_slug: "histoire", position: 13 },
  { text: "Explorer les civilisations anciennes, les archives et le patrimoine culturel est ce qui m'anime.",     filiere_slug: "histoire", position: 14 },
  { text: "Former, transmettre des savoirs et accompagner l'apprentissage des autres est une vocation.",          filiere_slug: "edu",      position: 15 },
  { text: "Les mécanismes de l'apprentissage, la pédagogie et la conception de formations m'intéressent.",       filiere_slug: "edu",      position: 16 }
]

seeded_question_ids = interest_questions.map do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "interest").tap do |dq|
    dq.text         = q[:text]
    dq.filiere_slug = q[:filiere_slug]
    dq.options      = []
    dq.active       = true
    dq.save!
  end.id
end

# ===== 16 QUESTIONS DISC =====
disc_questions = [
  { text: "Je prends facilement des décisions même sous pression.",                    disc_type: "D", position: 2 },
  { text: "J'aime diriger des projets et déléguer les tâches.",                         disc_type: "D", position: 3 },
  { text: "Je préfère agir vite plutôt que d'attendre la perfection.",                  disc_type: "D", position: 4 },
  { text: "J'assume la responsabilité des résultats, bons ou mauvais.",                 disc_type: "D", position: 5 },
  { text: "J'adore rencontrer de nouvelles personnes et élargir mon réseau.",           disc_type: "I", position: 6 },
  { text: "Je convaincs facilement mon entourage avec enthousiasme.",                   disc_type: "I", position: 7 },
  { text: "En groupe, j'aime animer et créer une bonne ambiance.",                      disc_type: "I", position: 8 },
  { text: "Je me motive par la reconnaissance et les encouragements.",                   disc_type: "I", position: 9 },
  { text: "Je préfère les environnements stables et prévisibles.",                       disc_type: "S", position: 10 },
  { text: "Je suis à l'écoute et j'aide volontiers mes collègues.",                     disc_type: "S", position: 11 },
  { text: "Je prends le temps d'analyser avant de changer mes habitudes.",               disc_type: "S", position: 12 },
  { text: "Je suis loyal(e) et m'implique sur le long terme dans mes engagements.",     disc_type: "S", position: 13 },
  { text: "Je travaille avec méthode et j'attache de l'importance aux détails.",        disc_type: "C", position: 14 },
  { text: "Je vérifie plusieurs fois avant de rendre un travail.",                       disc_type: "C", position: 15 },
  { text: "Je me documente en profondeur avant de prendre position.",                    disc_type: "C", position: 16 },
  { text: "Je préfère les règles claires et les processus bien définis.",                disc_type: "C", position: 17 }
]

disc_questions.each do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "disc").tap do |dq|
    dq.text       = q[:text]
    dq.disc_type  = q[:disc_type]
    dq.active     = true
    dq.save!
  end.then { |question| seeded_question_ids << question.id }
end

# ===== 12 QUESTIONS COMPÉTENCES =====
competence_texts = {
  "langues_etrangeres"   => "Je parle couramment au moins une langue étrangère.",
  "communication_ecrite" => "Je rédige des textes clairs, structurés et adaptés à mon audience.",
  "communication_orale"  => "Je m'exprime avec aisance en public ou face à des interlocuteurs variés.",
  "analyse_donnees"      => "Je sais collecter, traiter et interpréter des données (qualitatives ou quantitatives).",
  "gestion_projet"       => "Je peux planifier, coordonner et suivre un projet de A à Z.",
  "numerique"            => "Je maîtrise des outils numériques avancés (tableurs, logiciels métier, code…).",
  "negociation"          => "Je suis capable de défendre une position et trouver des compromis satisfaisants.",
  "creativite"           => "J'ai une forte capacité à imaginer des solutions ou des contenus originaux.",
  "ecoute"               => "Je comprends les besoins implicites de mes interlocuteurs avec empathie.",
  "rigueur_scientifique" => "Je travaille de façon précise, vérifiable et conforme aux standards de mon domaine.",
  "culture_generale"     => "J'ai une bonne connaissance historique, littéraire, artistique et géopolitique.",
  "droit_politiques"     => "Je comprends le cadre juridique, réglementaire et institutionnel de mon secteur."
}

competence_labels = Skill.pluck(:slug, :name).to_h
competence_questions = competence_texts.each_with_index.map do |(slug, text), index|
  { label: competence_labels.fetch(slug), text: text, competence_slug: slug, position: 18 + index }
end

competence_questions.each do |q|
  DiagnosticQuestion.find_or_initialize_by(assessment: assessment, position: q[:position], kind: "competence").tap do |dq|
    dq.text            = q[:text]
    dq.competence_slug = q[:competence_slug]
    dq.options         = [ { "label" => q[:label] } ]
    dq.active          = true
    dq.save!
  end.then { |question| seeded_question_ids << question.id }
end
assessment.diagnostic_questions.where.not(id: seeded_question_ids).destroy_all
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'interest').count} questions de filière"
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'disc').count} questions DISC"
puts "✓ #{DiagnosticQuestion.where(assessment: assessment, kind: 'competence').count} questions compétences"
