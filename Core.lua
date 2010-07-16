--
-- $Date$ $Revision$
--

-- module setup
SUO = LibStub("AceAddon-3.0"):NewAddon(
    "StuckUpOfficers",
    "AceConsole-3.0",
    "AceComm-3.0",
    "AceEvent-3.0",
    "AceTimer-3.0",
    "AceHook-3.0"
)

-- state
SUO.guildreceived = 0
SUO.officerreceived = 0
SUO.guildsent = 0
SUO.officersent = 0
SUO.guildsentself = 0
SUO.officersentself = 0

-- local vars
local myname

-- options
SUO.optionsSlash = {
    name = "suo",
    handler = SUO,
    type = 'group',
    args = {
        report = {
            type = 'execute',
            name = 'report',
            desc = 'report statistics',
            func = 'ReportForced',
        },
        dump = {
            type = 'execute',
            name = 'dump',
            desc = 'dump raw stats',
            func = 'Dump',
        },
        reset = {
            type = 'execute',
            name = 'reset',
            desc = 'reset statistics',
            func = 'Reset',
        },
        reportinterval = {
          type = 'range',
          name = 'report interval',
          desc = 'set report interval in seconds',
          min = 10,
          max = 3600,
          set = 'SetReportInterval',
          get = function() return SUO.db.profile.reportinterval end,
        },
    },
}

-- init
function SUO:OnInitialize()
    -- load saved variables
    self.db = LibStub("AceDB-3.0"):New("SUODB", self.defaults, 'Default')
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SUOSlashCommand", self.optionsSlash, "suo")
end

-- default profile
SUO.defaults = {
    profile = {
	    reportinterval = 600,
    },
}

-- enable
function SUO:OnEnable()
  self:Reset()
  self:RegisterEvent("CHAT_MSG_OFFICER")
  self:RegisterEvent("CHAT_MSG_GUILD")
  self:Hook("SendChatMessage", true)
  self.timer = self:ScheduleRepeatingTimer("Report", self.db.profile.reportinterval)
  myname = UnitName("player")
end

-- disable
function SUO:OnDisable()
	self:CancelAllTimers()
  self:UnregisterAllEvents()
	self:UnhookAll()
end

-- reset stats
function SUO:Reset()
  self.guildreceived = 0
  self.officerreceived = 0
  self.guildsent = 0
  self.officersent = 0
end

-- report stats
function SUO:Report()
   -- if we haven't seen any officer messages, there's nothing to report
   if 0 == self.officerreceived then
      return
   end
   -- calculate ratios
   local receivedratio = 0
   local sentratio = 0
   local trafficratio = 0
   if self.guildreceived > 0 then
    receivedratio = self.officerreceived / self.guildreceived
   end
   if self.guildsent > 0 then
    sentratio = self.officersent / self.guildsent
   end
   local guildtotal = self.guildreceived + self.guildsent
   local officertotal = self.officerreceived + self.officersent
   if guildtotal > 0 then
    trafficratio = officertotal / guildtotal
   end
   self:Print(string.format("o:g received ratio: %.2f:1", receivedratio))
   self:Print(string.format("o:g sent ratio: %.2f:1", sentratio))
   self:Print(string.format("o:g traffic ratio: %.2f:1", trafficratio))
end
function SUO:ReportForced()
   if 0 == self.officerreceived then
       self:Print("no officer messages received; nothing to report")
   end
   self:Report()
end

-- dump raw stats
function SUO:Dump()
  self:Print("officer received", self.officerreceived)
  self:Print("officer sent", self.officersent)  
  self:Print("guild received", self.guildreceived)
  self:Print("guild sent", self.guildsent)
end

-- set report interval
function SUO:SetReportInterval(info, value)
  self.db.profile.reportinterval = value
  self:CancelTimer(self.timer)
  self.timer = self:ScheduleRepeatingTimer("Report", self.db.profile.reportinterval)
end

-- catch receipt of an officer msg
function SUO:CHAT_MSG_OFFICER(event, msg, author)
  if myname ~= author then
    self.officerreceived = self.officerreceived + 1
  end
end

-- catch receipt of a guild msg
function SUO:CHAT_MSG_GUILD(event, msg, author)
  if myname ~= author then
    self.guildreceived = self.guildreceived + 1
  end
end

-- catch sending a chat message
function SUO:SendChatMessage(msg, chatType)
  if "OFFICER" == chatType then
    self.officersent = self.officersent + 1
  elseif "GUILD" == chatType then
    self.guildsent = self.guildsent + 1
  end
end

--
-- EOF