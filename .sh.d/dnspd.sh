#!/usr/bin/env zsh

# ###  Args  ##################################################################
SHORT="r"
LONG="remove"

ARGS=`getopt -a -o $SHORT -l $LONG -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 ]]; then
  cat <<- EOF
Usage: dnspd.sh: -[`echo $SHORT|sed 's/,/|/g'`] --[`echo $LONG|sed 's/,/|/g'`]
EOF
  return 1
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -r|--remove) REMOVE="true" ;;
  --) shift ; break ;;
  esac
shift
done

# ###  Main  ##################################################################

source $HOME/.sh/pretty.sh

name="linux.org"
temp_file="/tmp/dns-speed.list"
dns_list="$HOME/.dns.list"

# Create a temporary file to store the results
[[ -f $temp_file ]] && rm $temp_file
touch $temp_file


# Test the dns servers listed on the dns-list.txt file
while read -r row; do
  sum=0
  for n_attempt in $(seq 1 3); do
    IFS=',' read ip dns <<< "$row"

    [[ -z "$ip" ]] && continue
    response=`dig +timeout=1 @$ip $name | grep 'Query time' | awk '{print $4}'`

    if [[ -z "$response"  ]]; then
      warn "$dns $ip not responding"
      if [[ "$REMOVE" = "true" ]];then
        cmdi "sed -i '/$ip/d' $dns_list"
      fi
      break;
    else
      info "$(printf "%-20s %-10s %s\n" "$ip" "${response} ms" "$dns")"

      sum=$((sum + response))
    fi

    if [[ "$n_attempt" -eq "3" ]]; then
      printf "%-20s %-10s %s\n" "$ip" "$((sum/3)) ms" "$dns" >> $temp_file
    fi
  done
done < $dns_list
sed -i '/^$/d' $dns_list

# Print your fastest DNS
bar "Sorted DNS List"
sort -n -k 2 $temp_file | head -n 10

