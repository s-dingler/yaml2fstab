#!/bin/bash

parse_yaml() {
    local yaml_file=$1

    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_.\/-]*'
    local r='*'
    local error=0
    declare -A content
    options=("default")
    commands=("")

    # Add header line
    echo "#Device  Mountpoint  FStype  Options Dump    Pass" > fstab.tmp

    while IFS= read -r line || [ -n "$line" ] ;
    do
        case $line in
        fstab:)
            # check for header line 
            ;;
        ${s}export:${r})
            content[0]+=":$( echo "$line" | sed -e 's#^ *export: *##' )" 
            ;;       
        ${s}mount:${r})
            content[1]="$( echo "$line" | sed -e 's#^ *mount: *##' )"   
            ;;
        ${s}type:${r})
            content[2]="$( echo "$line" | sed -e 's#^ *type: *##' )" 
            ;;    
        ${s}root-reserve:${r})
            commands+=("tune2fs -m$( echo "$line" | sed -e 's#^ *root-reserve: *##'| sed -e 's#%$##' ) "$content)
            ;;                                                    
        ${s}options:)
            options=()
            ;;            
        ${s}${w}:)
            if (( ${#content[@]} ))
            then
                content[3]=$(IFS=$'\t' ; shift; echo "${options[*]}")
                content[4]=0
                content[5]=0
                
                out=$(IFS=$'\t' ; echo "${content[*]}")
                content=()
                echo "$out" >> fstab.tmp
            fi
            content[0]="$( echo "$line" | sed -e 's#^ *##; s#:$##' )"
            ;;
        ${s}-${s}nosuid)
            options+=("nosuid")
            ;;
        ${s}-${s}noexec)
            options+=("noexec")
            ;;                 
          *)
            printf 'UNKNOWN LINE%s\n' "$line"
            error=$((error+1))
            ;;
        esac

    done < $yaml_file;

    # Output last entry as well
    content[3]=$(IFS=, ; shift; echo "${options[*]}")
    content[4]=0
    content[5]=0
    out=$(IFS=$'\t' ; echo "${content[*]}")
    echo "$out" >> fstab.tmp

    for command in "${commands[@]}" 
    do
        $command
        if [ $? -ne 0 ] 
        then
            echo "Could not execute command $command" >&2
            error=$((error+1))
        fi
    done

    if [ $error -gt 0 ]
    then
        echo "Unexpected error while processing the file"
        exit 1
    else 
        column -t fstab.tmp > fstab
        rm fstab.tmp
        exit 0
    fi
}

# Execute parse_yaml() direct from command line
parse_yaml "${1}"
