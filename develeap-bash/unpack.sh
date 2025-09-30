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

# -k=keeps original archive   -f/-o=force overwrite if exists
declare -A decompressors=(
  ["gzip"]="gunzip -k -f"
  ["bzip2"]="bunzip2 -k -f"
  ["Zip"]="unzip -o -d"
  #["compress'd"]="uncompress -f"
)

decompress_file() {
  file=$1
  file_type=$(file -b "$file" | awk '{print $1}')
  
  if [[ ${file_type} == "compress'd" ]]; then
    base="${file%.*}"
    out="$base"
    # if archived name without extension, adds .out
    [[ "$out" = "$file" ]] && out="${base}.out"
    uncompress -c "$file" > "$out"
    (( $? = 0 )) && ((decompressed++)) || ((failed++))
  elif [[ "${decompressors[${file_type}]}" ]]; then
    ${decompressors[${file_type}]} "$file"
    (( $? = 0 )) && ((decompressed++)) || ((failed++))
  else
    [[ $vflag == true ]] && echo "Ignoring $(basename "$f")"
    ((fasiled++))
  fi
     
   
  
}









