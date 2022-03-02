#!/usr/bin/env bash

branch_checked=$1
current_repo=$2
rm -rf output.html
touch output.html

#parameters: 1=ssh of the repository, 2=repository name
clone_repo(){
	rm -rf $2
	retries=2
	while ((retries > 0)); do
		git lfs clone $1 -b develop && break
		echo "Cloning $2 failed. Retry"
		sleep 60
		((retries --))
	done
	if ((retries == 0 )); then
		echo "ERROR: Couldn't clone $2. Exiting"
		exit 1
	fi
	cd $2
	git status
}

#parameters: 1=parent repo name, 2=submodule name, 3=sha1 of submodule commit, 4=branch checked
check_match () {
echo "checking- parent repo is: $1 and submodule is: $2"
branch_of_submodule=$(git branch -r --contains $3 2>&1)
echo "branch_of_submodule is: ${branch_of_submodule}"
if [[ "$4" == "develop" ]]; then 
	if [[ "$branch_of_submodule" == *"/develop"* ]]; then
		echo "$1 and $2 submodule: no mismatch!"
		echo -e "$1 is on: $4, \nwhereas $2 submodule is on: \n$branch_of_submodule"
		echo "sha1 of submodule commit is: $3"
		echo "<b>$1 and $2 submodule: no mismatch!</b><br>" >> ../output.html
		echo "<b>$1 is on: $4, <br><br>whereas $2 submodule is on: <br>$branch_of_submodule</b><br>" >> ../output.html
		echo "<b>sha1 of submodule commit is: $3</b><br>" >> ../output.html
	else
		echo "ERROR - $1 and $2 submodule: mismatch found!"
		echo -e "$1 is on: $4, \nwhereas $2 submodule is on: \n$branch_of_submodule"
		echo "sha1 of submodule commit is: $3"
		echo "<b>ERROR - $1 and $2 submodule: mismatch found!</b><br>" >> ../output.html
		echo "<b>$1 is on: $4, <br><br>whereas $2 submodule is on: <br>$branch_of_submodule</b><br>" >> ../output.html
		echo "<b>sha1 of submodule commit is: $3</b><br>" >> ../output.html
		
	fi
else #in this case, the checked branch of the parent repository is a release branch
	if [[ "$branch_of_submodule" == *"release/"* || "$branch_of_submodule" == *"/develop"* ]]; then
		echo "$1 and $2 submodule: no mismatch!"
		echo -e "$1 is on: $4, \nwhereas $2 submodule is on: \n$branch_of_submodule"
		echo "sha1 of submodule commit is: $3"
		echo "<b>$1 and $2 submodule: no mismatch!</b><br>" >> ../output.html
		echo "<b>$1 is on: $4, <br><br>whereas $2 submodule is on: <br>$branch_of_submodule</b><br>" >> ../output.html
		echo "<b>sha1 of submodule commit is: $3</b><br>" >> ../output.html
	else
		echo "ERROR - $1 and $2 submodule: mismatch found!"
		echo -e "$1 is on: $4, \nwhereas $2 submodule is on: \n$branch_of_submodule"
		echo "sha1 of submodule commit is: $3"
		echo "<b>ERROR - $1 and $2 submodule: mismatch found!</b><br>" >> ../output.html
		echo "<b>$1 is on: $4, <br><br>whereas $2 submodule is on: <br>$branch_of_submodule</b><br>" >> ../output.html
		echo "<b>sha1 of submodule commit is: $3</b><br>" >> ../output.html
		
	fi
fi
echo "<br><br>" >> ../output.html
}

mapfile -t submodules_status_array < <(git submodule status)
num_of_submodules=${#submodules_status_array[@]}
echo "The number of submodules is: $num_of_submodules"
for((i=0; i<$num_of_submodules; i++))
do
	current_submodule=$(echo "${submodules_status_array[$i]}" | cut -c54-)
	echo "current submodule is: $current_submodule"
    sha1_current_submodule=$(echo "${submodules_status_array[$i]}" | cut -c 2-41)
	echo "current sha1 is: $sha1_current_submodule"
	#submodules checking:
	clone_repo ssh://git@git.parallelwireless.net:7999/cd/${current_submodule}.git $current_submodule
	check_match $current_repo $current_submodule $sha1_current_submodule $branch_checked
	cd .. #for returning to the directory of the parent repo
	rm -rf $current_submodule
done

#replace new lines with <br> in html output file
sed -i 's/$/<br>/' ./output.html
