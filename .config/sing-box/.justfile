default:
  sing-box run -c ./config.json

update url:
  wget "https://subc.wukaige.com/config/{{url}}&file=https://raw.wukaige.com/sing-box/config.json?token=changeme" -O config.json

add url name:
  wget "https://subc.wukaige.com/config/{{url}}&file=https://raw.wukaige.com/sing-box/config.json?token=changeme" -O {{name}}

use name:
  ln -s {{name}}.json config.json
