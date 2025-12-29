Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/clear', 'Clear your chat messages', {})

    TriggerEvent('chat:addSuggestion', '/me', 'Send a message in the third person. (Proximity Chat)', {
        { name="Action", help="Action." }
    })

    TriggerEvent('chat:addSuggestion', '/do', 'Send an action message. (Proximity Chat)', {
    { name="Action", help="Action." }
    })

    TriggerEvent('chat:addSuggestion', '/news', 'Send a news headline. (Global Chat)', {
        { name="Message", help="News headline." }
    })
  
    TriggerEvent('chat:addSuggestion', '/ad', 'Send an advertisement message. (Global Chat)', {
      { name="Message", help="Product or service." }
    })
  
    TriggerEvent('chat:addSuggestion', '/twt', 'Send a Twitter message. (Global Chat)', {
      { name="Message", help="Twitter message." }
    })
  
    TriggerEvent('chat:addSuggestion', '/anon', 'Send an anonymous message. (Global Chat)', {
      { name="Message", help="Anonymous message." }
    })

    TriggerEvent('chat:addSuggestion', '/staffannounce', 'Send a staff announcement (Staff Only)', {
      { name="Message", help="Announcement message." }
    })
end)