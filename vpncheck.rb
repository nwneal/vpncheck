#!/usr/bin/env ruby

# script for monitoring if vpn connection is up

require 'net/http'

# user deifned settings
$check_server='https://google.com/'
$open_timeout=1
$read_timeout=1
$script_pause=1

vpnc_start=false
vpnc_fix=false
vpnc_home=""

if ARGV.length >= 1
	if ARGV[0] == '--fix'
		vpnc_fix = true
	else
		vpnc_start = true
		vpnc_home=ARGV[0]
	end	
else
	puts "No home dir was defined..."
end

if vpnc_fix
	ksysout = system('sudo iptables-restore < ./firewall-open')
	puts 'firewall open.'
elsif vpnc_start
	vpn_off = false
	firewall_on = false

	while true

		begin
			url = URI.parse($check_server)
			http = Net::HTTP.new(url.host, url.port)
			http.open_timeout = $open_timeout # timeout for connection to open
			http.read_timeout = $read_timeout # timeout for connection to read response
			res = http.get(url.path)
			if vpn_off
				vpn_off = false
				# set firewall rules back
				firewall_on = false
				fwcmd = "sudo iptables-restore < #{vpnc_home}/firewall-open"
				ksysout = system(fwcmd)
				puts 'VPN Connection Established, Disabling Firewall.'
			end
		rescue
			vpn_off = true
		end

		if vpn_off
			if not firewall_on
				# shut off connections at firewall
				fwcmd = "sudo iptables-restore < #{vpnc_home}/firewall-block"
				ksysout = system(fwcmd)
				puts 'VPN Connection Broken, Enabling Firewall.'
				firewall_on = true
				# alert user that VPN dropped
				#ksysout = system('zenity --error --text="You are disconnected from VPN. Security firewall enabled" --title="WARNING"')
			end
		end

		sleep($script_pause) # allow user to set sleep time

	end
end
