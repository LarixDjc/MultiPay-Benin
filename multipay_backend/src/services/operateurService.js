const simulerOperateur = async (operateur, numero, montant, type) => {
  // Simule un délai réseau
  await new Promise(resolve => setTimeout(resolve, 300));

  // Simule succès 90% du temps
  const succes = Math.random() > 0.1;

  const reference = `REF-${operateur.toUpperCase()}-${Date.now()}`;

  if (!succes) {
    return {
      statut: 'echec',
      reference,
      message: 'Transaction échouée - Solde insuffisant ou numéro invalide'
    };
  }

  // Taux de frais par opérateur et type
  const taux = {
    MTN: { depot: 0.006, retrait: 0.03, credit: 0.05, forfait: 0.05 },
    MOOV: { depot: 0.006, retrait: 0.03, credit: 0.05, forfait: 0.05 },
    CELTIIS: { depot: 0.007, retrait: 0.04, credit: 0.05, forfait: 0.05 }
  };

  const operateurUpper = operateur.toUpperCase();
  const pourcentage = taux[operateurUpper]?.[type] || 0.01;
  const frais = montant * pourcentage;

  return {
    statut: 'succes',
    reference,
    frais,
    montantNet: type === 'depot' ? montant - frais : montant + frais,
    message: 'Transaction réussie'
  };
};

module.exports = { simulerOperateur };