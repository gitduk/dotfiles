default:
  pkill sing-box; sing-box run -c ./config.json

update url:
  wget "https://subc.wukaige.com/sub?urls={{url}}&config=https://raw.wukaige.com/sing-box/config.json" -O config.json
  sing-box check -c config.json && systemctl --user restart sing-box.service

add name url:
  wget "https://subc.wukaige.com/sub?urls={{url}}&config=https://raw.wukaige.com/sing-box/config.json" -O {{name}}.json

use name:
  ln -sf {{name}}.json config.json
  sing-box check -c config.json && systemctl --user restart sing-box.service

reload:
  sing-box check -c config.json && systemctl --user restart sing-box.service
