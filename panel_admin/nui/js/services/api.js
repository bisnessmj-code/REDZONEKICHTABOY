/**
 * API Service - Panel Admin Fight League
 * Communication avec le client Lua
 */

const API = {
    /**
     * Envoyer une requête au client Lua
     */
    async fetch(endpoint, data = {}) {
        try {
            const response = await fetch(`https://panel_admin/${endpoint}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (error) {
            console.error('API Error:', error);
            return { success: false, error: 'REQUEST_FAILED' };
        }
    },

    /**
     * Fermer le panel
     */
    close() {
        return this.fetch('close');
    },

    /**
     * Obtenir la liste des joueurs
     */
    getPlayers() {
        return this.fetch('getPlayers');
    },

    /**
     * Obtenir les détails d'un joueur
     */
    getPlayerDetails(playerId) {
        return this.fetch('getPlayerDetails', { playerId });
    },

    /**
     * Rechercher des joueurs
     */
    searchPlayers(query, includeOffline = false) {
        return this.fetch('searchPlayers', { query, includeOffline });
    },

    /**
     * Action sur un joueur
     */
    playerAction(action, targetId, data = {}) {
        return this.fetch('playerAction', { action, targetId, ...data });
    },

    /**
     * Action de sanction
     */
    sanctionAction(action, targetId, data = {}) {
        return this.fetch('sanctionAction', { action, targetId, ...data });
    },

    /**
     * Bannir par identifier (joueur hors-ligne)
     */
    banByIdentifier(identifier, reason, duration) {
        return this.fetch('banByIdentifier', { identifier, reason, duration });
    },

    /**
     * Action économique
     */
    economyAction(action, targetId, data = {}) {
        return this.fetch('economyAction', { action, targetId, ...data });
    },

    /**
     * Action de téléportation
     */
    teleportAction(action, targetId = null, data = {}) {
        return this.fetch('teleportAction', { action, targetId, ...data });
    },

    /**
     * Action de véhicule
     */
    vehicleAction(action, targetId = null, data = {}) {
        return this.fetch('vehicleAction', { action, targetId, ...data });
    },

    /**
     * Envoyer une annonce
     */
    announceAction(data) {
        return this.fetch('announceAction', data);
    },

    /**
     * Téléportation au marqueur
     */
    teleportToMarker() {
        return this.fetch('teleportToMarker');
    },

    /**
     * Spectate un joueur
     */
    spectate(targetId) {
        return this.fetch('spectate', { targetId });
    },

    /**
     * Arrêter le spectate
     */
    stopSpectate() {
        return this.fetch('stopSpectate');
    },

    /**
     * Obtenir les logs
     */
    getLogs(filters = {}, page = 1, perPage = 50) {
        return this.fetch('getLogs', { filters, page, perPage });
    },

    /**
     * Obtenir l'historique des sanctions
     */
    getSanctions(filters = {}, page = 1, perPage = 20) {
        return this.fetch('getSanctions', { filters, page, perPage });
    },

    /**
     * Obtenir les comptes des joueurs en ligne (Owner/Admin uniquement)
     */
    getAccounts() {
        return this.fetch('getAccounts');
    },

    /**
     * Obtenir la liste des bans
     */
    getBans() {
        return this.fetch('getBans');
    },

    /**
     * Debannir un joueur
     */
    unbanPlayer(identifier) {
        return this.fetch('unbanPlayer', { identifier });
    },

    /**
     * Obtenir la liste des reports
     */
    getReports() {
        return this.fetch('getReports');
    },

    /**
     * Action sur un report (claim, respond, resolve, delete)
     */
    reportAction(action, reportId, data = {}) {
        return this.fetch('reportAction', { action, reportId, ...data });
    },

    /**
     * Obtenir les statistiques des reports
     */
    getReportStats(timeFilter = 'all') {
        return this.fetch('getReportStats', { timeFilter });
    },

    /**
     * Envoyer une annonce d'événement (GDT/CVC)
     */
    sendEventAnnouncement(data) {
        return this.fetch('sendEventAnnouncement', data);
    },

    /**
     * Obtenir les statistiques des événements
     */
    getEventStats(timeFilter = 'all') {
        return this.fetch('getEventStats', { timeFilter });
    },

    /**
     * Réinitialiser les statistiques des événements (Admin/Owner)
     */
    resetEventStats() {
        return this.fetch('resetEventStats');
    },

    // ══════════════════════════════════════════════════════════════
    // STAFF CHAT
    // ══════════════════════════════════════════════════════════════

    /**
     * Obtenir les messages du chat staff
     */
    getStaffChatMessages() {
        return this.fetch('getStaffChatMessages');
    },

    /**
     * Envoyer un message dans le chat staff
     */
    sendStaffChatMessage(message) {
        return this.fetch('sendStaffChatMessage', { message });
    },

    /**
     * Supprimer un message du chat staff
     */
    deleteStaffChatMessage(messageId) {
        return this.fetch('deleteStaffChatMessage', { messageId });
    },

    /**
     * Supprimer tous les messages du chat staff (admin/owner)
     */
    clearStaffChat() {
        return this.fetch('clearStaffChat');
    },

    // ══════════════════════════════════════════════════════════════
    // ACTIVITY TIMELINE
    // ══════════════════════════════════════════════════════════════

    /**
     * Obtenir les activités récentes
     */
    getRecentActivity(limit = 20) {
        return this.fetch('getRecentActivity', { limit });
    },

    // ══════════════════════════════════════════════════════════════
    // STAFF ROLES MANAGEMENT
    // ══════════════════════════════════════════════════════════════

    /**
     * Obtenir la liste des membres du staff
     */
    getStaffMembers() {
        return this.fetch('getStaffMembers');
    },

    /**
     * Modifier le grade d'un membre
     */
    updateStaffGrade(identifier, newGrade) {
        return this.fetch('updateStaffGrade', { identifier, newGrade });
    },

    /**
     * Obtenir les joueurs connectés (pour promotion)
     */
    getConnectedUsers() {
        return this.fetch('getConnectedUsers');
    }
};

// Export pour utilisation globale
window.API = API;
