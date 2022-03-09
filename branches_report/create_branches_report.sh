#!/usr/bin/env bash
#parameters: 1=user name for Bitbucket api, 2=password for Bitbucket api, 3=packaging repository name
#output_csv.csv columns structure: Repository Name,Branch Name,Last commit date,Last merge to develop date,Last merge to develop (days ago),Author,Creation Date (an estimate),Commit Jira ticket,Branch Jira Ticket,sha1- last commit,sha1- last common commit with develop

prUser=$1
prPass=$2
packaging_repo_name=$3

chmod 755 ./branches_report/parse_PRs_list.sh
cd ..
rm PRs_list.json
current_date=$(date +"%Y-%m-%d")
days_limit=30


#parameters: 1=branches type, 2=current date, 3=days limit for branches to be displayed, 4=project name, 5=repository name
create_report_for_specific_type_of_branches(){
	branches_type=$1
	current_date=$2
	days_limit=$3
	project=$4
	repo_name=$5
	seconds_of_one_day=86400
	mapfile -t branches_array < <(git for-each-ref --sort=-committerdate refs/remotes/origin/$branches_type --format='%(committerdate:short) %(refname:short)')
	num_of_branches=${#branches_array[@]}
	for((i=0; i<$num_of_branches; i++))
	do
			current_branch=$(echo "${branches_array[$i]}" | cut -c12-)
			date_of_last_commit=$(echo "${branches_array[$i]}" | cut -c 1-10)
			diff_cur_date_and_last_commit=$((($(date -u -d $current_date +%s) - $(date -u -d $date_of_last_commit +%s)) / $seconds_of_one_day))
			last_commit_sha1=$(git rev-parse $current_branch 2>&1)
			author_name=$(git show -s --format='%an' $last_commit_sha1 2>&1)
			branch_creation_date=$(git rev-list --format=%ai develop..$current_branch |tail -n1 2>&1)
			if [[ "$branch_creation_date" != "" ]]; then
				branch_creation_date=$(echo "$branch_creation_date" | cut -c 1-10)
				diff_branch_creation_date=$((($(date -u -d $current_date +%s) - $(date -u -d $branch_creation_date +%s)) / $seconds_of_one_day))
			fi
			if [[ "$diff_cur_date_and_last_commit" -gt "$days_limit" ]]; then
					continue
			fi
			((branch_num=i+1))
			echo "$branch_num. Branch: $current_branch"
			echo -e "${repo_name},\c" >> ../output_csv.csv
			echo -e "${current_branch},\c" >> ../output_csv.csv
			echo -e "$date_of_last_commit ($diff_cur_date_and_last_commit days ago),\c" >> ../output_csv.csv
			sha1_of_last_common_commit_with_develop=$(git merge-base develop $current_branch 2>&1)
			date_of_last_common_commit_with_develop=$(git show -s --format=%ci $sha1_of_last_common_commit_with_develop 2>&1)
			date_of_last_common_commit_with_develop=$(echo "$date_of_last_common_commit_with_develop" | cut -c 1-10)
			diff_cur_date_and_last_common_commit_with_develop=$((($(date -u -d $current_date +%s) - $(date -u -d $date_of_last_common_commit_with_develop +%s)) / $seconds_of_one_day))
			commit_ticket_info=$(git log --format=%B -n 1 ${last_commit_sha1} | grep -m1 -o -e [A-Z]\\+-[0-9]\\+ | head -1 2>&1)
			branch_ticket_info=$(echo $current_branch | grep -m1 -o -e [A-Z]\\+-[0-9]\\+ | head -1 2>&1)
			if [[ "$last_commit_sha1" == "$sha1_of_last_common_commit_with_develop" ]]; then
					echo "Branch is synced!"
					echo -e "synced,\c" >> ../output_csv.csv
					echo -e "0,\c" >> ../output_csv.csv #for the number of days since last merge to develop in the csv file (sortting parameter).
			else
					curl -sS -u $prUser:$prPass -X GET -H Content-Type:application/json https://git.parallelwireless.net/rest/api/1.0/projects/$project/repos/$repo_name/commits/${sha1_of_last_common_commit_with_develop}/pull-requests?state=MERGED -o ../PRs_list.json
					bash ../common-packaging/branches_report/parse_PRs_list.sh $date_of_last_common_commit_with_develop $diff_cur_date_and_last_common_commit_with_develop
			fi
			echo "Author of last commit: $author_name"
			echo -e "${author_name},\c" >> ../output_csv.csv
			if [[ "$branch_creation_date" == "" ]]; then
					echo "Branch creation date (an estimate): Irrelevant"
					echo -e "Irrelevant,\c" >> ../output_csv.csv
			else
					echo "Branch creation date (an estimate): $branch_creation_date. ($diff_branch_creation_date days ago. Current date: $current_date)"
					echo -e "${branch_creation_date} ($diff_branch_creation_date days ago),\c" >> ../output_csv.csv
			fi
			if [[ "$commit_ticket_info" == "" ]]; then
					echo "Ticket information of last commit: jira ticket details could not be found in the commit message"
					echo -e "missing,\c" >> ../output_csv.csv
			else
					echo "Ticket information of last commit: $commit_ticket_info"
					echo -e "${commit_ticket_info},\c" >> ../output_csv.csv
			fi
			if [[ "$branch_ticket_info" == "" ]]; then
					echo "Branch Ticket information: jira ticket details could not be found"
					echo -e "missing,\c" >> ../output_csv.csv
			else
					echo "Branch Ticket information: $branch_ticket_info"
					echo -e "${branch_ticket_info},\c" >> ../output_csv.csv
			fi
			echo "sha1 of last commit on this branch: $last_commit_sha1. occurred at: $date_of_last_commit. ($diff_cur_date_and_last_commit days ago. Current date: $current_date)"
			echo "sha1 of last common commit with develop: $sha1_of_last_common_commit_with_develop. occurred at: $date_of_last_common_commit_with_develop. ($diff_cur_date_and_last_common_commit_with_develop days ago. Current date: $current_date)"
			echo ""
			echo -e "${last_commit_sha1},\c" >> ../output_csv.csv
			echo "${sha1_of_last_common_commit_with_develop}" >> ../output_csv.csv
	done
}

mapfile -t repos_names_array < <(jq -r '.[] | .[] | keys[]' ./$packaging_repo_name/manifest.json)
num_of_repos=${#repos_names_array[@]}
for((j=0; j<$num_of_repos; j++))
do	
	project="cd"
    if [[ "${repos_names_array[$j]}" == "access-iso" ]]; then
        project="pwis"
    elif [[ "${repos_names_array[$j]}" == "rt-monitoring" ]]; then
        project="da"
    elif [[ "${repos_names_array[$j]}" == "uniperf" ]]; then
        project="tool"
    elif [[ "${repos_names_array[$j]}" == "near_rtric" ]]; then
        project="near"
	fi
	echo ""
	echo ""
	echo "Repository Name: ${repos_names_array[$j]}"
	cd ${repos_names_array[$j]}
	echo ""
	echo ""
	echo "Branches Type: feature branches"
	echo ""
	create_report_for_specific_type_of_branches feature $current_date $days_limit $project ${repos_names_array[$j]}
	echo "Branches Type: integ branches"
	echo ""
	create_report_for_specific_type_of_branches integ $current_date $days_limit $project ${repos_names_array[$j]}
	cd ..
done

cat ./output_csv.csv >> ./full_csv.csv
rm -rf ./output_csv.csv

