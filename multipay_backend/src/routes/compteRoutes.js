const express = require('express');
const router = express.Router();
const { consulterSolde, verifierPin, verrouiller, deverrouiller, configurerCompteOperateur } = require('../controllers/compteController');
const verifierToken = require('../middlewares/authMiddleware');
const prisma = require('../config/prisma');

router.get('/solde', verifierToken, consulterSolde);
router.get('/operateurs', verifierToken, async (req, res) => {
  const comptes = await prisma.compteOperateur.findMany({
    where: { revendeurId: req.revendeur.id }
  });
  res.status(200).json({ comptes });
});
router.post('/verifier-pin', verifierToken, verifierPin);
router.patch('/verrouiller', verifierToken, verrouiller);
router.patch('/deverrouiller', verifierToken, deverrouiller);
router.post('/operateurs', verifierToken, configurerCompteOperateur);
module.exports = router;
