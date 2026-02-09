-- ════════════════════════════════════════════════════════════
-- OPTIMISATION BASE DE DONNÉES - Panel Admin Fight League
-- Ajoute les index manquants pour améliorer les performances
-- ════════════════════════════════════════════════════════════

-- Index pour panel_bans (recherches rapides lors de la connexion)
CREATE INDEX IF NOT EXISTS idx_bans_identifier ON panel_bans(identifier);
CREATE INDEX IF NOT EXISTS idx_bans_steam ON panel_bans(steam_id);
CREATE INDEX IF NOT EXISTS idx_bans_discord ON panel_bans(discord_id);
CREATE INDEX IF NOT EXISTS idx_bans_license ON panel_bans(license);
CREATE INDEX IF NOT EXISTS idx_bans_expires ON panel_bans(expires_at);

-- Index pour panel_sanctions (historique et recherches)
CREATE INDEX IF NOT EXISTS idx_sanctions_target ON panel_sanctions(target_identifier);
CREATE INDEX IF NOT EXISTS idx_sanctions_staff ON panel_sanctions(staff_identifier);
CREATE INDEX IF NOT EXISTS idx_sanctions_type ON panel_sanctions(type);
CREATE INDEX IF NOT EXISTS idx_sanctions_status ON panel_sanctions(status);
CREATE INDEX IF NOT EXISTS idx_sanctions_created ON panel_sanctions(created_at);

-- Index pour panel_logs (filtrage et affichage)
CREATE INDEX IF NOT EXISTS idx_logs_staff ON panel_logs(staff_identifier);
CREATE INDEX IF NOT EXISTS idx_logs_target ON panel_logs(target_identifier);
CREATE INDEX IF NOT EXISTS idx_logs_category ON panel_logs(category);
CREATE INDEX IF NOT EXISTS idx_logs_created ON panel_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_logs_action ON panel_logs(action);

-- Index pour panel_staff
CREATE INDEX IF NOT EXISTS idx_staff_group ON panel_staff(staff_group);
CREATE INDEX IF NOT EXISTS idx_staff_last_access ON panel_staff(last_panel_access);

-- Index pour panel_player_notes
CREATE INDEX IF NOT EXISTS idx_notes_target ON panel_player_notes(target_identifier);
CREATE INDEX IF NOT EXISTS idx_notes_staff ON panel_player_notes(staff_identifier);
CREATE INDEX IF NOT EXISTS idx_notes_category ON panel_player_notes(category);

-- Index pour panel_announcements
CREATE INDEX IF NOT EXISTS idx_announcements_scheduled ON panel_announcements(is_scheduled, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_announcements_sent ON panel_announcements(is_sent);

-- Index pour panel_events
CREATE INDEX IF NOT EXISTS idx_events_status ON panel_events(status);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON panel_events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_scheduled ON panel_events(scheduled_at);

-- Index pour panel_event_participants
CREATE INDEX IF NOT EXISTS idx_participants_event ON panel_event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_participants_identifier ON panel_event_participants(identifier);
CREATE INDEX IF NOT EXISTS idx_participants_status ON panel_event_participants(status);

-- Index pour panel_event_matches
CREATE INDEX IF NOT EXISTS idx_matches_event ON panel_event_matches(event_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON panel_event_matches(status);

-- Index pour panel_player_connections
CREATE INDEX IF NOT EXISTS idx_connections_identifier ON panel_player_connections(identifier);
CREATE INDEX IF NOT EXISTS idx_connections_connected ON panel_player_connections(connected_at);

-- Index pour panel_saved_locations
CREATE INDEX IF NOT EXISTS idx_locations_created_by ON panel_saved_locations(created_by);
CREATE INDEX IF NOT EXISTS idx_locations_public ON panel_saved_locations(is_public);
CREATE INDEX IF NOT EXISTS idx_locations_category ON panel_saved_locations(category);

-- ════════════════════════════════════════════════════════════
-- Afficher un message de confirmation
-- ════════════════════════════════════════════════════════════

SELECT 'Optimisation terminée! Tous les index ont été créés.' AS message;
