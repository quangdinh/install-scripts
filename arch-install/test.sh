  zsh_path=/usr/bin/zsh
  zsh_path_esc=$(echo $zsh_path | sed 's_/_\\/_g')
  echo $zsh_path_esc