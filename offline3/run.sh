g++ -pthread main.cpp -o a.out
if [ $? -ne 0 ]; then
    echo "Compilation failed"
    exit 1
else
    ./a.out in.txt out.txt
    rm a.out
    echo "Compilation successful"
fi