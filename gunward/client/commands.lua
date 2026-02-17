Gunward.Client.Commands = {}

RegisterCommand('gw_leave', function()
    if not Gunward.Client.Teams.IsInGunward() then
        Gunward.Client.Utils.Notify(Lang('cmd_leave_not_in'), 'error')
        return
    end
    TriggerServerEvent('gunward:server:leaveGunward')
end, false)

RegisterCommand('gw_team', function()
    local team = Gunward.Client.Teams.GetCurrent()
    if not team then
        Gunward.Client.Utils.Notify(Lang('team_not_in'), 'error')
        return
    end
    Gunward.Client.Utils.Notify(Lang('team_current', Config.Teams[team].label), 'info')
end, false)
