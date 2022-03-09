#!/usr/bin/env bash
#parameters: 1=date of last common commit with develop, 2=difference current date and last common commit with develop

seconds_of_one_day=86400
save_last_closed_date=0
line_before=0
current_date=$(date +"%Y-%m-%d")
found_merge_date=0
while read -r val ; do
    if [[ "$val" == *"closedDate"* ]]; then #val should be for example (seconds since Unix epoch): "closedDate": 1651514602047,
        save_last_closed_date=$(echo "$val" | cut -c15-) #save_last_closed_date should be for example: 1651514602047,
        save_last_closed_date=${save_last_closed_date::-1} #save_last_closed_date should be for example (removing the ','): 1651514602047
        save_last_closed_date=$(date -d @$((($save_last_closed_date + 500)/1000)) +'%Y-%m-%d %H:%M:%S')
    fi
    if [[ "$val" == *"toRef"* ]]; then
        line_before=1
    fi
    if [[ "$line_before" == 1 && "$val" == *"refs/heads/develop"* ]]; then
		save_last_closed_date=$(echo "$save_last_closed_date" | cut -c 1-10)
		diff_cur_date_and_closed_date=$((($(date -u -d $current_date +%s) - $(date -u -d $save_last_closed_date +%s)) / $seconds_of_one_day))
        echo "Last merge to develop occurred at: $save_last_closed_date. ($diff_cur_date_and_closed_date days ago. Current date: $current_date)"
		echo -e "$save_last_closed_date ($diff_cur_date_and_closed_date days ago),\c" >> ../output_csv.csv
		echo -e "$diff_cur_date_and_closed_date,\c" >> ../output_csv.csv #for sorting the csv file (sorting parameter)
        line_before=0
		found_merge_date=1
        break
    fi
done < <(jq -r '.values[]' ../PRs_list.json)

if [[ "$found_merge_date" == 0 ]]; then
	echo "Last merge to develop occurred at (*Based on last common commit with develop instead of PRs list): $1. ($2 days ago. Current date: $current_date)"
	echo -e "$1 ($2 days ago)-unstable,\c" >> ../output_csv.csv
	echo -e "$2,\c" >> ../output_csv.csv #for sorting the csv file (sorting parameter)
fi

