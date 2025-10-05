#!/bin/bash

vflag=false
rflag=false

# loop through cli options (flags)
while getopts ":vr" opt; do
  case $opt in
    v) vflag=true ;; 
    r) rflag=true ;;
  esac
done
# makes sure f=$1 is the file/folder not the flags
shift $((OPTIND - 1))

decompressed=0
failed=0

update_counter() {
  if (( $? == 0 )); then
    ((decompressed++))
  else
    ((failed++))
  fi
}

# -k=keeps original archive   -f/-o=force overwrite if exists   -d=dir to extract
declare -A decompressors=(
  ["Zip"]="unzip -o -d"
  ["gzip"]="gunzip"
  ["bzip2"]="bunzip2"
  ["compress'd"]="uncompress"
)

decompress_file() {
  local file="$1"
  local file_type=$(file -b "$file" | awk '{print $1}')
  
  # zip needs a -d <dir> to control output dir + no -c
  if [[ $file_type == "Zip" ]]; then
    [[ $vflag == true ]] && echo "Unpacking $(basename "$file")..."
    unzip -o -d "$(dirname "$file")" -- "$file" >/dev/null 2>&1
    update_counter
  
  # # gzip, bzip2, compress'd handled through the array
  elif [[ -n "${decompressors[$file_type]}" ]]; then
    local out="${file}.out"
    [[ $vflag == true ]] && echo "Unpacking $(basename "$file")..."
    ${decompressors[$file_type]} -c -- "$file" > "$out"
    update_counter

  else
    [[ $vflag == true ]] && echo "Ignoring $(basename "$file")"
    ((failed++))
  fi
}


decompress_path() {
  path=$1
  if [[ -d "$path" ]]; then
    if [[ $rflag == true ]];then
      while IFS= read -r file; do
        decompress_file "$file"
      done < <(find "$path" -type f)
    else
      for file in "$path"/*; do
        [[ -f "$file" ]] && decompress_file "$file"
      done
    fi
  else
    decompress_file "$path"
  fi
}


for arg in "$@"; do
  decompress_path "$arg"
done

echo "Decompressed $decompressed archive(s)"
exit $failed

