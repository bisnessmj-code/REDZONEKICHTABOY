# Installation et Configuration - Aim Training

## ⚠️ Prérequis

Ce script nécessite les dépendances suivantes :

1. **ESX Legacy** (version récente)
2. **ox_lib** - Téléchargez depuis : https://github.com/overextended/ox_lib

### Installation d'ox_lib (si pas déjà installé)

1. Téléchargez ox_lib depuis GitHub
2. Placez le dossier `ox_lib` dans votre dossier `resources/`
3. Ajoutez `ensure ox_lib` dans votre `server.cfg` **AVANT** Aim_training

## 📦 Installation Rapide

1. **Copiez le dossier** `Aim_training` dans votre dossier `resources/` de votre serveur FiveM

2. **Ouvrez** votre fichier `server.cfg` et ajoutez (dans cet ordre) :
   ```
   ensure ox_lib
   ensure Aim_training
   ```

3. **Redémarrez** votre serveur FiveM

4. **C'est prêt !** Le script est maintenant actif

---

## 🎯 Localisation des éléments

### PED Instructeur (Menu)
- **Position** : (-5809.08, -932.48, 502.49)
- Parlez avec le PED pour ouvrir le menu
- Appuyez sur **E** pour interagir

### Zone de jeu
- **Position de départ** : (13.08, -1097.34, 29.82)
- Les bots apparaissent automatiquement aux 10 positions configurées

---

## 🎮 Comment jouer

1. Allez voir le **PED instructeur** aux coordonnées indiquées
2. Appuyez sur **E** pour ouvrir le menu
3. Sélectionnez **"Commencer la partie"**
4. Un décompte de 3 secondes commence
5. Vous recevez un **Pistol .50** avec munitions illimitées
6. Tuez un maximum de bots pendant **2 minutes** (ils font une roulade!)
7. Appuyez sur **X** pour quitter à tout moment (pas de récompense)
8. Finissez la partie pour recevoir **2000$** dans votre banque

---

## ⚙️ Personnalisation (Optionnel)

### Changer le modèle du PED instructeur
Ouvrez `config.lua` et modifiez :
```lua
Config.MenuPedModel = "a_m_m_business_01"
```

Liste de modèles possibles :
- `s_m_m_armoured_01` - Agent de sécurité
- `s_m_y_ranger_01` - Ranger
- `s_m_y_sheriff_01` - Shérif
- `a_m_m_business_01` - Homme d'affaires (défaut)
- Plus sur : https://docs.fivem.net/docs/game-references/ped-models/

### Changer le modèle des bots
```lua
Config.BotModel = "a_m_y_skater_01"
```

### Modifier la récompense
```lua
Config.Reward = 2000 -- Changez le montant
```

### Modifier la durée de la partie
```lua
Config.GameDuration = 120 -- Durée en secondes (120 = 2 minutes)
```

---

## 🔧 Dépannage

### Le PED n'apparaît pas
- Vérifiez que la ressource est bien démarrée : `restart Aim_training`
- Vérifiez les logs de la console pour des erreurs

### Je ne reçois pas d'argent
- Vérifiez que vous avez bien **terminé la partie** (les 2 minutes complètes)
- Si vous quittez avec **X** avant la fin, vous ne recevez rien

### Les bots ne spawn pas
- Vérifiez que vous êtes bien dans une instance (message dans la console serveur)
- Redémarrez la ressource

---

## 📝 Notes importantes

- ✅ Chaque joueur joue dans sa **propre instance** (isolation totale)
- ✅ Plusieurs joueurs peuvent jouer **en même temps** sans interférence
- ✅ Le classement sauvegarde automatiquement votre **meilleur score**
- ✅ L'arme (Cal.50) disparaît automatiquement à la fin de la partie
- ✅ Les instances sont nettoyées automatiquement en cas de déconnexion

---

## 📞 Support

Pour toute question, consultez la documentation FiveM officielle ou vérifiez les logs de votre serveur.

Bon jeu ! 🎯
