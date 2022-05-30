#!/usr/bin/env bash
#full_csv.csv columns structure: Repository Name,Branch Name,Last commit date,Last merge to develop date,Last merge to develop (days ago),Author,Creation Date (an estimate),Commit Jira ticket,Branch Jira Ticket,sha1- last commit,sha1- last common commit with develop

cd .. 
current_date=$(date +"%Y-%m-%d")
echo "<!DOCTYPE html>
	<html>
	<body>
	<b>Date: $current_date</b><br>
	<style>
	table, th, td {
	  border:1px solid black;
	}
	</style>
	<table style='width:100%'>
			<tr>
					<th>Repository Name</th>
					<th>Banch</th>
					<th>Last commit</th>
					<th>Last merge to develop</th>
					<th>Author</th>
					<th>Creation Date (an estimate)</th>
					<th>Commit Jira Ticket</th>
					<th>Branch Jira Ticket</th>
					<th>sha1- last commit</th>
					<th>sha1- last common commit with develop</th>
			</tr>" >> ./output_summary.html			
sort -t, -k5,5 -nr ./full_csv.csv >> ./temp_csv.csv #sorting the csv file according to the 5th column (Last merge to develop (days ago))
INPUT=./temp_csv.csv
OLDIFS=$IFS
IFS=','
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 1; }
while read repository_name branch_name last_commit_date last_merge_to_develop sort_param author creation_date commit_jira_ticket branch_jira_ticket sha1_last_commit sha1_last_common_commit_with_develop
do
	if [[ "$last_merge_to_develop" != "synced" ]]; then
		date=$(echo "$last_commit_date" | cut -c 1-10)
		days_ago=$(echo "$last_commit_date" | cut -c12-)
		echo "<tr>" >> ./output_summary.html
		echo "<td>$repository_name</td>" >> ./output_summary.html
		echo "<td>$branch_name</td>" >> ./output_summary.html
		echo "<td>$date <span style='color:Tomato;'>$days_ago</span></td>" >> ./output_summary.html #last_commit_date
		date=$(echo "$last_merge_to_develop" | cut -c 1-10)
		days_ago=$(echo "$last_merge_to_develop" | cut -c12-)
		if [[ "$last_merge_to_develop" == *"unstable"* ]]; then
			last_merge_to_develop=$(echo "$last_merge_to_develop" | cut -c 1-24) #remove the word unstable from the html output file (and use orange color to mark the date as unstable)
			echo "<td><span style='color:#E8A317;'>$last_merge_to_develop</span></td>" >> ./output_summary.html
		else
			echo "<td>$date <span style='color:Tomato;'>$days_ago</span></td>" >> ./output_summary.html #last_merge_to_develop
		fi
		echo "<td>$author</td>" >> ./output_summary.html
		date=$(echo "$creation_date" | cut -c 1-10)
		days_ago=$(echo "$creation_date" | cut -c12-)
		echo "<td>$date <span style='color:Tomato;'>$days_ago</span></td>" >> ./output_summary.html #creation_date
		if [[ "$commit_jira_ticket" == "missing" ]]; then
			echo "<td>$commit_jira_ticket</td>" >> ./output_summary.html
		else
			echo "<td>$commit_jira_ticket<br> Link: https://jira.parallelwireless.net/browse/$commit_jira_ticket</td>" >> ./output_summary.html
		fi
		if [[ "$branch_jira_ticket" == "missing" ]]; then
			echo "<td>$branch_jira_ticket</td>" >> ./output_summary.html
		else
			echo "<td>$branch_jira_ticket<br> Link: https://jira.parallelwireless.net/browse/$branch_jira_ticket</td>" >> ./output_summary.html
		fi
		echo "<td>$sha1_last_commit</td>" >> ./output_summary.html
		echo "<td>$sha1_last_common_commit_with_develop</td>" >> ./output_summary.html
		echo "</tr>" >> ./output_summary.html
	fi
done < $INPUT
IFS=$OLDIFS
echo "</table>
	<br><br>
	</body>
	</html>" >> ./output_summary.html	
echo "Repository Name,Branch Name,Last commit date,Last merge to develop date,Last merge to develop (days ago),Author,Creation Date (an estimate),Commit Jira ticket,Branch Jira Ticket,sha1- last commit,sha1- last common commit with develop" >> ./sorted_csv.csv
cat ./temp_csv.csv >> ./sorted_csv.csv
rm -rf ./full_csv.csv
rm -rf ./temp_csv.csv
