# Aim Training Script pour FiveM ESX

## Installation

1. Copiez le dossier `Aim_training` dans votre dossier `resources` de votre serveur FiveM
2. Ajoutez `ensure Aim_training` dans votre `server.cfg`
3. Redémarrez votre serveur

## Configuration

Ouvrez le fichier `config.lua` pour configurer :

### Position du PED (instructeur)
```lua
Config.MenuPedPosition = {
    x = -5809.081542,  -- Coordonnée X
    y = -932.479126,   -- Coordonnée Y
    z = 501.489990,    -- Coordonnée Z
    heading = 351.496064
}
```

Vous pouvez également changer le modèle du PED :
```lua
Config.MenuPedModel = "a_m_m_business_01" -- Modèle du PED
```

### Position de départ du joueur
```lua
Config.PlayerStartPosition = {
    x = 0.0,       -- Coordonnée X où le joueur commence
    y = 0.0,       -- Coordonnée Y
    z = 72.0,      -- Coordonnée Z
    heading = 0.0  -- Direction (0-360)
}
```

### Positions des bots
Modifiez les 10 positions dans `Config.BotSpawnPositions` selon vos besoins.

## Comment obtenir les coordonnées

1. Allez dans le jeu à l'endroit souhaité
2. Tapez `/getcoords` ou utilisez un script de coordonnées
3. Copiez les coordonnées dans le `config.lua`

## Fonctionnalités

- **Système d'instances** : Chaque joueur est isolé dans sa propre dimension (routing bucket)
- Menu avec "Commencer la partie" et "Classement"
- Décompte de 3 secondes avant le début
- **Pistol .50** avec munitions illimitées (retiré automatiquement à la fin)
- Bots qui apparaissent et font une roulade à droite
- Durée de 2 minutes
- Récompense de 2000$ si la partie est terminée
- Touche X pour quitter sans récompense
- Classement des meilleurs scores
- Nettoyage automatique des instances en cas de déconnexion

## Utilisation

1. Allez voir le PED instructeur aux coordonnées (-5809.08, -932.48, 502.49)
2. Appuyez sur `E` pour parler avec l'instructeur
3. Sélectionnez "Commencer la partie" dans le menu
4. Tuez un maximum de bots en 2 minutes
5. Appuyez sur `X` pour quitter avant la fin (sans récompense)

## Dépendances

- ESX Legacy (version récente recommandée)
- es_extended
- ox_lib (https://github.com/overextended/ox_lib)

## Support

Pour toute question ou problème, consultez la documentation FiveM.
