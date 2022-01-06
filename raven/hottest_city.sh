#! /bin/bash



if [[ -z "$GET_CURRENT_WEATHER_BIN" ]]; then
    # GET_CURRENT_WEATHER_BIN="./bin/net6.0/RavenTrials.GetCurrentWeather"
    echo "    GET_CURRENT_WEATHER_BIN is unset, please set this variable propertly
    It should be defined in this way:
    export GET_CURRENT_WEATHER_BIN=\"<path to GetCurrentWeather C# application binary>\"
    For example:
    export GET_CURRENT_WEATHER_BIN=\"./bin/net6.0/RavenTrials.GetCurrentWeather\""
    exit -1
fi
# GET_CURRENT_WEATHER_BIN="./bin/net6.0/RavenTrials.GetCurrentWeather"
# echo "$GET_CURRENT_WEATHER_BIN"


if [[ $# -lt 1 ]]; then
    echo "You must transfer at least one argument of cities.txt file
    For example:
    ./hottest_city.sh cities.txt"
    exit -1
fi

export k
export titleToPrint
if [[ $# -gt 1 ]]; then
    k=$2
    titleToPrint="The $k most hottest cities are:"
else
    k=3
    titleToPrint="Three hottest cities are:"
fi


cities_txt_file=$1  #  "cities.txt"
cities_data_txt_file="city_tmp_data.txt"

fecth_data() {
    local city
    local output
    local exit_status

    city=$1
    output=$("${GET_CURRENT_WEATHER_BIN}" -c "$city" 2>/dev/null)
    exit_status=$?

    if [ $exit_status != 0 ]; then
        echo "Could not pull the weather info for ${city}"
    elif [[ ! -z $output ]]; then
        output_arr=()
        while read val; do
            output_arr+=( "$val" )
        done < <(echo "$output" | sed 's/|/\n/g')
        echo ${output_arr[0]}$'\n'${output_arr[1]} 1>> "$cities_data_txt_file" # ECHO IS ATOMIC - PROCESS SAFE 
    fi
}

generate_data_file(){
    while read city; do
        fecth_data "${city}" &
    done < <(cat "$cities_txt_file")
    wait
    echo "" >> "$cities_data_txt_file"
}

getKhottestCities(){
    local city temp k i
    k=$1 
    i=0
    while read val; do
        if [[ $(( $i%2 )) == 0 ]];then
            city="$val"
        else
            temp=$val
            if (( $(echo ""$(( $i/2 ))" < $k" |bc -l) )); then
                city_arr+=("$city")
                temp_arr+=($temp)
            else
                updateArrays "${city}" $temp
            fi
        fi
        i=$(( $i+1 ))
    done < <(cat "$cities_data_txt_file")
}

updateArrays (){
    local city temp min_t min_index
    city=$1
    temp=$2
    #find min temp index
    min_t=${temp_arr[0]}
    min_index=0
    for j in "${!temp_arr[@]}"; do # run on all array indices
        if (( $(echo "${temp_arr[$j]} < $min_t" |bc -l) )); then
            min_t=${temp_arr[$j]}
            min_index=$j
        fi
    done
    
    if (( $(echo "$min_t < $temp" |bc -l) )); then
        temp_arr[$min_index]=$temp
        city_arr[$min_index]="$city"
    fi
}

sortArrays (){
    local n flag i
    n=${#city_arr[@]}
    flag=1;
    for (( i = 0; i < $n-1; i++ ))
    do
        flag=0;
        for ((j = 0; j < $n-1-$i; j++ ))
        do
            if (( $(echo "${temp_arr[$j]} < ${temp_arr[$j+1]}" |bc -l) )); then
                temp=${temp_arr[$j]};
                temp_arr[$j]=${temp_arr[$j+1]};
                temp_arr[$j+1]=$temp;

                city=${city_arr[$j]};
                city_arr[$j]=${city_arr[$j+1]};
                city_arr[$j+1]=$city;

                flag=1;
            fi
        done

        if [[ $flag -eq 0 ]]; then
            break;
        fi
    done
}

main (){
    # create tmp file
    touch "$cities_data_txt_file"

    generate_data_file
    getKhottestCities $1
    sortArrays

    # echo "The $k most hottest cities are:"
    # echo "Three hottest cities are:"

    echo "${titleToPrint}"
    # print hottest cities
    # i. {city} ({temp}C)
    for i in "${!city_arr[@]}"; do 
        echo "$(($i+1)). ${city_arr[$i]} (${temp_arr[$i]}C)"
    done

    # remove the tmp file
    rm "$cities_data_txt_file"
}


export temp_arr=()
export city_arr=()
main $k