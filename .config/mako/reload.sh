#!/usr/bin/env zsh

makoctl reload
# to test a 'high' urgency notification add '-u critical '
notify-send -a "Reload notify app" -t 3000 "Here is some summary" "Reloaded mako config"
