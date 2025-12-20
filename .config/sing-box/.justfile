default:
  sing-box run -c ./config.json

update url:
  wget "https://subc.wukaige.com/config/{{url}}&file=https://raw.wukaige.com/sing-box/config.json" -O config.json

add name url:
  wget "https://subc.wukaige.com/config/{{url}}&file=https://raw.wukaige.com/sing-box/config.json" -O {{name}}.json

use name:
  ln -sf {{name}}.json config.json

reload:
  systemctl --user restart sing-box.service
