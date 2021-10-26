fx_version 'cerulean'

game 'gta5'

lua54 'yes'
use_fxv2_oal 'yes'

client_script 'cl.lua'

server_script 'sv.lua'

ui_page 'ui/ui.html'

files {
    'ui/fonts/*.otf',
    'ui/css/index.css',
    'ui/js/script.js',
    'ui/default.png',
    'ui/ui.html'
}

dependency 'oxmysql'