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
  if (( $?==0 )); then
    ((decompressed++))
  else
    ((failed++))
  fi
}

# -k=keeps original archive   -f/-o=force overwrite if exists   -d=dir to extract
declare -A decompressors=(
  ["gzip"]="gunzip -k -f"
  ["bzip2"]="bunzip2 -k -f"
  ["Zip"]="unzip -o -d"
)

decompress_file() {
  file=$1
  file_type=$(file -b "$file" | awk '{print $1}')
  
  # no -k option in uncompress
  if [[ $file_type == "compress'd" ]]; then
    base="${file%.*}"
    out="$base"
    ## if archived name without extension, adds .out to decompressed name
    [[ "$out" = "$file" ]] && out="${base}.out"
    [[ $vflag == true ]] && echo "Unpacking $(basename "$file")..."
    uncompress -c "$file" > "$out"
    update_counter
  
  # zip needs a -d <dir> to control output dir 
  elif [[ $file_type == "Zip" ]]; then
    [[ $vflag == true ]] && echo "Unpacking $(basename "$file")..."
    unzip -o -d "$(dirname "$file")" -- "$file" >/dev/null 2>&1
    update_counter
  
  # by default output next to file path
  elif [[ -n "${decompressors[$file_type]}" ]]; then
    [[ $vflag == true ]] && echo "Unpacking $(basename "$file")..."
    ${decompressors[$file_type]} -- "$file" >/dev/null 2>&1
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
        find "$path" -type f | while read -r file; do
          decompress_file "$file"
        done
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

