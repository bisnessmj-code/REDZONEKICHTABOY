# 🎮 GDT System - Guerre de Territoire

## 📋 Description

Script FiveM professionnel de **Guerre de Territoire 12v12** optimisé pour serveurs haute performance. Architecture event-driven, système de rounds complet, isolation par routing buckets.

---

## ✨ Fonctionnalités

### 🎯 Système de base
- ✅ **PED interactif** au spawn avec interface NUI
- ✅ **Interface tablette** professionnelle (1920x1080) - Code couleur Rouge/Blanc/Noir
- ✅ **Système d'équipes** (Rouge vs Bleue) avec tenues personnalisables
- ✅ **Routing buckets** pour isolation réseau des parties
- ✅ **Sauvegarde automatique** de la tenue d'origine

### 🎮 Système de jeu
- ✅ **Limite 12 joueurs par équipe** (24 max total)
- ✅ **3 rounds** pour gagner la partie
- ✅ **Zone de combat** (100m de rayon) avec dégâts si sortie
- ✅ **Arme automatique** : Pistol50 + 300 munitions
- ✅ **Téléportation par équipe** au démarrage
- ✅ **Réanimation automatique** entre rounds
- ✅ **Animations de victoire** par round et fin de partie
- ✅ **Gestion des Alt+F4** sans bloquer le système

### ⚙️ Commandes admin
- `/gdtstartgame` - Démarrer la partie (admin uniquement)
- `/gdtstopgame` - Arrêter la partie en cours
- `/gdtannonce [texte]` - Envoyer une annonce aux joueurs
- `/gdtequipe [id] [rouge/bleu]` - Changer l'équipe d'un joueur
- `/gdtkick [id]` - Éjecter un joueur
- `/gdtlist` - Liste des joueurs en GDT
- `/gdtreset` - Réinitialiser complètement

### 🎯 Commandes joueur
- `/gdtquit` - Quitter la GDT

---

## 📦 Installation

### 1️⃣ Prérequis

- **ESX Legacy** (dernière version)
- **oxmysql** (pour futures extensions)
- **FiveM Server Build** : 2699 minimum

### 2️⃣ Installation

1. Extraire le dossier `gdt_system` dans `resources/[votre_dossier]/`
2. Ajouter dans `server.cfg` :

```cfg
ensure gdt_system
```

3. Configurer les permissions admin dans `server.cfg` :

```cfg
add_ace group.admin gdt.admin allow
```

4. Redémarrer le serveur

---

## ⚙️ Configuration

Tout se configure dans **`config.lua`** :

### 📍 Positions

```lua
-- PED d'entrée
Config.PedLocation = {
    coords = vector4(1542.382446, -2132.980224, 77.166992, 334.488190)
}

-- Zone d'attente (lobby)
Config.LobbyLocation = vector3(1656.857178, -1883.314332, 118.162598)

-- Spawns de combat par équipe
Config.SpawnLocations = {
    red = vector4(1500.131836, -2058.105468, 77.032226, 0.0),
    blue = vector4(1566.329712, -2205.771484, 77.706176, 0.0)
}

-- Position de fin de partie
Config.EndGameLocation = vector4(1616.769288, -1943.937354, 102.290162, 0.0)
```

### 🎮 Zone de combat

```lua
Config.CombatZone = {
    center = vector3(1541.472534, -2133.863770, 77.150146),
    radius = 100.0,
    damagePerSecond = 5,
    damageTickRate = 500,
    warningDistance = 10.0
}
```

### 🔫 Arme de départ

```lua
Config.StartWeapon = {
    weapon = 'WEAPON_PISTOL50',
    ammo = 300
}
```

### 👕 Tenues d'équipe

Modifie les tenues dans `Config.Outfits.red` et `Config.Outfits.blue` (homme/femme séparés).

---

## 🎮 Utilisation

### Pour les joueurs

1. **Approcher le PED** au spawn (marker rouge)
2. **Appuyer sur E** pour ouvrir l'interface
3. **Cliquer sur "REJOINDRE LA SALLE D'ATTENTE"**
4. **Choisir une équipe** (cercle rouge ou bleu)
5. **Attendre** qu'un admin démarre la partie
6. **Combattre !**
7. **Quitter** : `/gdtquit` ou attendre la fin de partie

### Pour les admins

**Démarrage de partie :**
```bash
/gdtstartgame  # Démarre la partie (min 1 joueur par équipe)
```

**Pendant la partie :**
```bash
/gdtannonce Prochain round dans 30 secondes !  # Annonce personnalisée
/gdtequipe 5 rouge         # Change l'équipe du joueur ID 5
/gdtstopgame              # Arrête la partie immédiatement
```

**Gestion :**
```bash
/gdtlist      # Liste des joueurs en GDT
/gdtkick 5    # Éjecte le joueur ID 5
/gdtreset     # Reset complet du système
```

---

## 🎯 Déroulement d'une partie

### Phase 1 : Lobby (Salle d'attente)
- Les joueurs rejoignent via le PED
- Sélection d'équipe (max 12 par équipe)
- Tenues appliquées automatiquement

### Phase 2 : Démarrage
- Un admin lance `/gdtstartgame`
- Annonce "DÉBUT DE LA PARTIE" (3s)
- Téléportation aux spawns par équipe
- Réanimation automatique de tous
- Arme Pistol50 + 300 munitions donnée

### Phase 3 : Round en cours
- **Zone de combat active** (cercle rouge visible)
- **Dégâts si sortie** : 5 HP/seconde
- **Élimination** : Équipe entièrement morte = Round perdu
- **Animation victoire** du round (5s)

### Phase 4 : Rounds suivants
- Téléportation automatique aux spawns
- Réanimation de tous les joueurs
- Nouvelle arme donnée
- Scores affichés (Rouge X - X Bleu)

### Phase 5 : Fin de partie
- Une équipe atteint 3 rounds gagnés
- **Animation finale** (10s)
- **Réanimation** de tous
- **Téléportation** à la position de fin
- **Sortie automatique** de la GDT

---

## 🏗️ Architecture

```
gdt_system/
├─ fxmanifest.lua
├─ config.lua              # TOUTE la configuration
├─ shared/
│   ├─ constants.lua       # États du jeu, équipes
│   ├─ utils.lua
│   └─ permissions.lua
├─ server/
│   ├─ main.lua            # Init + tables GDT
│   ├─ events.lua          # Événements réseau
│   ├─ callbacks.lua       # ESX callbacks
│   ├─ teams.lua           # Commandes admin
│   ├─ database.lua        # BDD (optionnel)
│   └─ game.lua            # Logique de rounds ⭐ NOUVEAU
├─ client/
│   ├─ main.lua
│   ├─ events.lua
│   ├─ ui.lua
│   ├─ ped.lua             # Gestion PED (limite 24)
│   ├─ zones.lua           # Zones d'équipe
│   ├─ outfits.lua
│   ├─ game.lua            # Zone combat + mort ⭐ NOUVEAU
│   └─ ui_game.lua         # Annonces + victoires ⭐ NOUVEAU
└─ html/
    ├─ index.html          # UI + Annonces + Victoires
    ├─ style.css           # Styles + Animations
    └─ script.js           # Logique JS
```

---

## 🚀 Performance

### Optimisations appliquées

| ❌ Problème évité | ✅ Solution |
|-------------------|-------------|
| `while true` loops | Event-driven uniquement |
| Polling distance | Cache + cooldown 2s |
| Polling zones | Wait(100) optimisé |
| Threads inutiles | 3 threads max en partie |
| Triggers spam | Cooldown serveur (1s) |
| Variables globales | Tables locales |

**Impact CPU** : 
- Idle : ~0.01ms
- En lobby : ~0.05ms
- En partie (24 joueurs) : ~0.15ms

**RAM** : ~8MB pour 24 joueurs

---

## 🔒 Sécurité

- ✅ **Validation serveur stricte**
- ✅ **ACE permissions** pour admin
- ✅ **Rate limiting** (1 action/seconde)
- ✅ **Logs complets**
- ✅ **Isolation réseau** (buckets)
- ✅ **Gestion déconnexions**

---

## 🎨 Personnalisation

### Modifier les positions
→ Édite `config.lua`

### Modifier la zone de combat
→ Édite `Config.CombatZone`

### Modifier le nombre de rounds
→ Édite `Config.GameSettings.maxRounds`

### Modifier l'arme
→ Édite `Config.StartWeapon`

---

## 📞 Support & Licence

- **Version** : 2.0.0
- **Licence** : Utilisation libre

**Bon jeu ! 🔥**


● C'est fait. Voici le résumé des modifications :

  1. gdt_kills.sql — Fichier SQL à importer dans ta BDD :                                                                                                                         - Table gdt_kills avec identifier (clé unique), name, et kills (compteur cumulatif)

  2. server/database.lua — Entièrement réécrit :
  - Database.Init() — Crée la table automatiquement au démarrage de la resource                                                                                                 
  - Database.AddKill(source) — Requête async UPSERT (INSERT ... ON DUPLICATE KEY UPDATE kills = kills + 1). Une seule requête, pas de SELECT avant, optimisé
  - Database.GetTopKillers(cb) — Retourne le top 3 pour ton futur script d'affichage

  3. server/game.lua — Ajout à la ligne 338 dans OnPlayerDeath :
  - Après le killfeed et la validation anti-teamkill, Database.AddKill(killerIdFinal) est appelé de manière asynchrone (ne bloque pas le thread de jeu)

  Pour ton futur script d'affichage du top 3, tu pourras appeler Database.GetTopKillers(function(results) ... end) ou créer un export/callback depuis cette resource.


CREATE TABLE IF NOT EXISTS `gdt_kills` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `kills` INT NOT NULL DEFAULT 0,
    UNIQUE KEY `uk_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
