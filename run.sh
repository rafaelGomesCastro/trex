#!/bin/bash

# MODE = 0: train_size resized to test_size; test_size resized to train_size
# MODE = 1: train/test with no resize, no extraction. Just copy
# MODE = 2: individually train/test (complete steps), no resize
# MODE = 3: individually train/test (complete steps), resize test to train
# MODE = 4: just extraction, no train/test (useful for update extracted paths)

MODE=1
#TRAIN_SIZE=(32 64 100 128 200 256 300)
#TEST_SIZE=(32 64 100 128 200 256 300)
TRAIN_SIZE=(128)
TEST_SIZE=(512)
CLASSES=("ft" "lu" "map" "allreduce")
EXTRACTORS=("DCTraCS_RLBP" "DCTraCS_ULBP" "Eerman" "Fahad" "Soysal" "Zhang")
RESULT_DIR="./results_black/"

if [ ! -d "${RESULT_DIR}" ]; then
    mkdir ${RESULT_DIR}
fi;

if [ -d "./training_scikit_out/" ]; then
    rm -r ./training_scikit_out/
fi;
mkdir ./training_scikit_out/
for k in "${EXTRACTORS[@]}"; do
    mkdir ./training_scikit_out/${k}
done;

if [ $MODE -eq 0 ]; then
    if [ ! -d "./results_resize_train/" ]; then
        mkdir "./results_resize_train/"
    fi;

    if [ ! -d "./results_resize_test/" ]; then
        mkdir "./results_resize_test/"
    fi;

    for i in "${TRAIN_SIZE[@]}"; do
        for j in "${TEST_SIZE[@]}"; do
            echo "tr${i}_r0_ts${j}_r${i}"

            python3 generate_definitions.py "["${i}"]" "[0]" "["${j}"]" "["${i}"]" &&
            python3 DCTraCSprocessing.py "tr${i}_r0_ts${j}_r${i}" &&
            python3 DCTraCSresults.py "tr${i}_r0_ts${j}_r${i}" > results_resize_test/resize_tr${i}_ts${j}.txt &&

            rm -r training_scikit_out/
        done;
    done;

    for i in "${TRAIN_SIZE[@]}"; do
        for j in "${TEST_SIZE[@]}"; do
            echo "tr${i}_r${j}_ts${j}_r0"

            python3 generate_definitions.py "["${i}"]" "["${j}"]" "["${i}"]" "[0]" &&
            python3 DCTraCSprocessing.py "tr${i}_r${j}_ts${j}_r0" &&
            python3 DCTraCSresults.py "tr${i}_r${j}_ts${j}_r0" > results_resize_train/resize_tr${i}_ts${j}.txt &&

            rm -r training_scikit_out/
        done;
    done;

elif [ $MODE -eq 1 ]; then
    for i in "${TRAIN_SIZE[@]}"; do
        for j in "${TEST_SIZE[@]}"; do
            if [ $i -eq $j ]; then
                for k in "${EXTRACTORS[@]}"; do
                    num_train=1
                    num_test=5
                    for l in "${CLASSES[@]}"; do
                        head -n 210 "extracted_"${i}/${k}/${l}.sck > ./training_scikit_out/${k}/class${num_train}.sck
                        tail -n 90 "extracted_"${j}/${k}/${l}.sck > ./training_scikit_out/${k}/class${num_test}.sck
                        num_train=$((num_train+1))
                        num_test=$((num_test+1))
                    done;
                done;
            else
                for k in "${EXTRACTORS[@]}"; do
                    num_train=1
                    num_test=5
                    for l in "${CLASSES[@]}"; do
                        cp "extracted_"${i}/${k}/${l}.sck ./training_scikit_out/${k}/class${num_train}.sck
                        cp "extracted_"${j}/${k}/${l}.sck ./training_scikit_out/${k}/class${num_test}.sck
                        num_train=$((num_train+1))
                        num_test=$((num_test+1))
                    done;
                done;
            fi;

            RESULT_FILE="${RESULT_DIR}result_tr${i}_ts${j}.txt"
            python3 generate_definitions.py "["${i}"]" "[0]" "["${j}"]" "[0]" &&
            python3 DCTraCSresults.py "tr${i}_r0_ts${j}_r0" > $RESULT_FILE

            echo $RESULT_FILE
        done;
    done;

elif [ $MODE -eq 2 ]; then
    for i in "${TRAIN_SIZE[@]}"; do
        for j in "${TEST_SIZE[@]}"; do
            RESULT_FILE="${RESULT_DIR}result_tr${i}_ts${j}.txt"
            python3 generate_definitions.py "["${i}"]" "[0]" "["${j}"]" "[0]" &&
            python3 DCTraCSprocessing.py "tr${i}_r0_ts${j}_r0" &&
            python3 DCTraCSresults.py "tr${i}_r0_ts${j}_r0" > $RESULT_FILE &&

            rm -r training_scikit_out/
            echo $RESULT_FILE
        done;
    done;

elif [ $MODE -eq 3 ]; then
    for i in "${TRAIN_SIZE[@]}"; do
        for j in "${TEST_SIZE[@]}"; do
            RESULT_FILE="${RESULT_DIR}result_tr${i}_ts${j}.txt"
            python3 generate_definitions.py "["${i}"]" "[0]" "["${j}"]" "["${i}"]" &&
            python3 DCTraCSprocessing.py "tr${i}_r0_ts${j}_r${i}" &&
            python3 DCTraCSresults.py "tr${i}_r0_ts${j}_r${i}" > $RESULT_FILE &&

            rm -r training_scikit_out/
            echo $RESULT_FILE
        done;
    done;

elif [ $MODE -eq 4 ]; then
    for i in "${TRAIN_SIZE[@]}"; do
        if [ -d extracted_${i} ]; then
            rm -r extracted_${i}
        fi;
        mkdir extracted_${i}

        python3 generate_definitions.py "["${i}"]" "[0]" "[32]" "[0]" &&
        python3 DCTraCSprocessing.py "tr${i}_r0_ts32_r0" &&

        for j in "${EXTRACTORS[@]}"; do
            mkdir extracted_${i}/${j}
            cp ./training_scikit_out/${j}/class1.sck extracted_${i}/${j}/ft.sck
            cp ./training_scikit_out/${j}/class2.sck extracted_${i}/${j}/lu.sck
            cp ./training_scikit_out/${j}/class3.sck extracted_${i}/${j}/map.sck
            cp ./training_scikit_out/${j}/class4.sck extracted_${i}/${j}/allreduce.sck
        done;
    done;
fi;

