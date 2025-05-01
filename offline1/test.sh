#!/bin/bash
evaluate(){
    run_command=$1
    out_file_dst=$2
    test_file_dst=$3
    ans_file_dst=$4
    match_count=0
    unmatch_count=0
    for i in "$test_folder"/*; do
        test_no=${i:(-5):1}
        eval $run_command < "$i" > "$out_file_dst/out$test_no.txt" 

        diff_output=$(diff -ZBw "$ans_file_dst/ans$test_no.txt" "$out_file_dst/out$test_no.txt")        
        if [ $? -eq 0 ]; then
            match_count=$((match_count + 1))
        else    
            unmatch_count=$((unmatch_count + 1))
        fi
    done
    result=("$match_count" "$unmatch_count")
    echo "${result[@]}"
}

file_type(){
    str=$1
    if [[ $str == "c" ]]; then
        echo "C"
    elif [[ $str == "java" ]]; then
        echo "Java"
    elif [[ $str == "cpp" ]]; then 
        echo "C++"
    elif [[ $str == "py" ]]; then
        echo "Python"
    else 
        echo "Invalid"
    fi
}

get_exec(){
    location=$1
    ext=$2
    if [[ $ext == "c" ]]; then
        gcc -o $location/main $location/main.$ext
        echo "$location/main"
    elif [[ $ext == "java" ]]; then
        javac $location/Main.java
        echo "java -cp $location Main"
    elif [[ $ext == "cpp" ]]; then 
        g++ -o $location/main $location/main.$ext
        echo "$location/main"
    elif [[ $ext == "py" ]]; then
        echo "python3 $location/main.py"
    else 
        echo "Invalid"
    fi
}

get_function_regex(){
        type=$1
        if [[ $type == "C" || $type == "C++" ]]; then
            echo '\b[a-zA-Z_][a-zA-Z0-9_]*(\s+|\s*\*\s*)[a-zA-Z_][a-zA-Z0-9_]*\s*\([^;{]*\)\s*\{'
        elif [[ $type == "Java" ]]; then
            echo '\b(public|private|protected|static|final|abstract)?\s+([a-zA-Z0-9_<>[\],\s]+)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^;{]*\)\s*(\{|throws)'
        elif [[ $type == "Python" ]]; then
            echo '\bdef\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\('
        fi
    }

usage(){
    echo "Usage $1 [ SUBMISSION FOLDER ] [ TARGET FOLDER ] [ TEST FOLDER ] [ ANSWER FOLDER ]"
    echo "Flags for this script are"
    echo "-v = gives verbose output while running"
    echo "-noexecute = prevents executing submitted scripts"
    echo "-nolc = prevents generating line count in the output csv"
    echo "-nocc = prevents generating line count in the output csv"
    echo "-nofc = prevents generating function count in the output csv"
    kill -INT $$
}

main(){
    if [ $# -lt 4 ]; then
        usage $0
    fi

    # pre-procesing
    submission_folder=$1
    target_folder=$2
    test_folder=$3
    answer_folder=$4
    v=0
    noexecute=0
    nolc=0
    nocc=0
    nofc=0
    i=5
    while [ $i -le $# ]; do
        eval "arg=\${$i}"
        case "$arg" in
            "-v")
                v=1
                ;;
            "-noexecute")
                noexecute=1
                ;;
            "-nolc")
                nolc=1
                ;;
            "-nocc")
                nocc=1
                ;;
            "-nofc")
                nofc=1
                ;;
            *)
                usage $0
        esac
        i=$((i+1))
    done


    # heading of csv with respect to the command passed 
    heading="student_id,student_name,language,matched,not_matched"
    if [ $nolc -eq 0 ]; then
        heading="$heading,line_count"
    fi

    if [ $nocc -eq 0 ]; then
        heading="$heading,comment_count"
    fi
    
    if [ $nofc -eq 0 ]; then
        heading="$heading,function_count"
    fi

    if [ !$noexecute ]; then 
        touch $target_folder/result.csv
        echo $heading > $target_folder/result.csv
    fi

    mkdir -p tmp
    ls "$submission_folder" | while read -r zip_file; do 
        unzip -oq -d tmp/ "$submission_folder/$zip_file"
        unzipped_folder=${zip_file%.zip}
        org=${unzipped_folder##*/}
        name=${org%%_*}
        roll=${org##*_}
        name="\"$name\""

        find "tmp/$unzipped_folder" | while read -r file; do
            ext=${file##*.}
            type=$(file_type $ext)

            if [[ $type != "Invalid" ]]; then
                # creating target foldr if not already created
                mkdir -p "$target_folder/$type/$roll"

                if [[ $type == "Java" ]];then
                    mv "$file" "$target_folder/$type/$roll/Main.$ext"
                else 
                    mv "$file" "$target_folder/$type/$roll/main.$ext"
                fi

                # if noexecute is passed then break out of the scope
                if [ $noexecute -eq 1 ]; then
                    break
                fi

                location="$target_folder/$type/$roll"
                exe=$(get_exec $location $ext)
                score=$(evaluate "$exe" "$location" "$test_folder" "$answer_folder")
                read match unmatch <<< $score

                # csv file data
                data="$roll,$name,$type,$match,$unmatch"

                # if nolc command not passed 
                if [ $nolc -eq 0 ]; then
                    line_count=$(wc -l < "$target_folder/$type/$roll/main.$ext")
                    data="$data,$line_count"
                fi

                # if nocc command not passed
                if [ $nocc -eq 0 ]; then 
                    comment_count=?
                    if [[ $type == "Python" ]]; then
                        comment_count=$(cat "$target_folder/$type/$roll/main.$ext" | grep "#" | wc -l)
                    else 
                        comment_count=$(cat "$target_folder/$type/$roll/main.$ext" | grep "//" | wc -l)
                    fi
                    data="$data,$comment_count"
                fi

                # if nofc command not passed
                if [ $nofc -eq 0 ]; then
                    regex=$(get_function_regex $type)
                    function_count=$(cat "$target_folder/$type/$roll/main.$ext" | grep -Pc $regex)
                    data="$data,$function_count"
                fi

                echo "$data" >> $target_folder/result.csv
            fi
        done
    done
    rm -rf tmp
}

main $@