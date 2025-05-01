# dir=Workspace
# rm -rf tmp
# rm -rf tempo
# mkdir -p tmp
# mkdir -p tempo/C++
# mkdir -p tempo/Python
# mkdir -p tempo/java
# mkdir -p tempo/C
# touch result.csv
# touch test.sh
# echo "Roll,Language,Match,Unmatch,Line Count,Comment Count" > result.csv

# evaluate(){
#     run=$1
#     dst=$2
#     match_count=0
#     unmatch_count=0
#     for i in "$dir/tests"/*; do
#         test_no=${i:(-5):1}
#         eval $run < "$i" > "$dst/out$test_no.txt" 

#         diff_output=$(diff -ZBw "$dir/answers/ans$test_no.txt" "$dst/out$test_no.txt")        
#         if [ $? -eq 0 ]; then
#             match_count=$((match_count + 1))
#         else    
#             unmatch_count=$((unmatch_count + 1))
#         fi
#     done
#     result=("$match_count" "$unmatch_count")
#     echo "${result[@]}"
# }

# file_type(){
#     str=$1
#     if [ $str -eq "c" ]; then
#         echo "Python"
#     elif [ $str -eq "java" ]; then
#         echo "Java"
#     elif [ $str -eq "cpp" ]; then 
#         echo "C++"
#     elif [ $str -eq "py" ]; then
#         echo "Python"
# }



# files=$(ls $dir/submissions)
# ls "$dir/submissions" | while read -r i; do 
#     unzip -oq -d tmp/ "$dir/submissions/$i"
#     i=${i%.zip}
#     roll=${i:(-7)}
#     find "tmp/$i" | while read -r j; do
#         if [[ ${j:(-2)} == ".c" ]]; then
#             mkdir -p "tempo/C/$roll"
#             mv "$j" "tempo/C/$roll"/main.c
#             comment_count=$(cat "tempo/C/$roll"/main.c | grep -c "//" )
#             line_count=$(wc -l < "tempo/C/$roll"/main.c)
#             gcc "tempo/C/$roll"/main.c -o "tempo/C/$roll/main"
#             score=$(evaluate "./tempo/C/$roll/main" "tempo/C/$roll")
#             read match unmatch <<< $score
#             echo "$roll,C,$match,$unmatch,$line_count,$comment_count" >> result.csv
#         elif [[ ${j:(-4)} == ".cpp" ]]; then
#             mkdir -p "tempo/C++/$roll"
#             mv "$j" "tempo/C++/$roll"/main.cpp
#             comment_count=$(cat "tempo/C++/$roll"/main.cpp | grep -c "//" )
#             line_count=$(wc -l < "tempo/C++/$roll"/main.cpp)
#             g++ "tempo/C++/$roll"/main.cpp -o "tempo/C++/$roll"/main
#             score=$(evaluate "./tempo/C++/$roll/main" "tempo/C++/$roll")
#             read match unmatch <<< $score
#             echo "$roll,C++,$match,$unmatch,$line_count,$comment_count" >> result.csv
#         elif [[ ${j:(-5)} == ".java" ]]; then
#             mkdir -p "tempo/java/$roll"
#             mv "$j" "tempo/java/$roll"/Main.java
#             comment_count=$(cat "tempo/java/$roll"/Main.java | grep -c "//" )
#             line_count=$(wc -l < "tempo/java/$roll"/Main.java)
#             javac "tempo/java/$roll"/Main.java
#             score=$(evaluate "java -cp tempo/java/$roll Main"  "tempo/java/$roll")
#             read match unmatch <<< $score
#             echo "$roll,Java,$match,$unmatch,$line_count,$comment_count" >> result.csv
#         elif [[ ${j:(-3)} == ".py" ]]; then
#             mkdir -p "tempo/Python/$roll"
#             mv "$j" "tempo/Python/$roll"/main.py 
#             comment_count=$(cat "tempo/Python/$roll"/main.py | grep -c "#" )
#             line_count=$(wc -l < "tempo/Python/$roll"/main.py)
#             score=$(evaluate "python tempo/Python/$roll/main.py" "tempo/Python/$roll")
#             read match unmatch <<< $score
#             echo "$roll,Python,$match,$unmatch,$line_count,$comment_count" >> result.csv
#         fi 
#     done
# done



./test.sh Workspace/submissions target Workspace/tests Workspace/answers 