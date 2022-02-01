resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

ui_page_preload "yes"
ui_page "html/index.html"

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	"server/*.lua"
}

client_scripts {
	"client/*.lua"
}

files {
	"html/*"
}


client_script '@esx_jobs/Shareds/ToLoad.lua'
