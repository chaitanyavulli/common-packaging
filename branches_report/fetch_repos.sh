#!/usr/bin/env bash

#parameters: 1=ssh of the repository, 2=repository name
clone_repo(){
	rm -rf $2
	retries=2
	while ((retries > 0)); do
		GIT_LFS_SKIP_SMUDGE=1 git clone $1 -b develop && break
		echo "Cloning $2 failed. Retry"
		sleep 60
		((retries --))
	done
	if ((retries == 0 )); then
		echo "ERROR: Couldn't clone $2. Exiting"
		exit 1
	fi
}

#parameters: 1=repository name
create_path_and_clone_repo(){
	repo_name=$1
	git_url="ssh://git@git.parallelwireless.net:7999"
	project="cd"
    if [[ "$repo_name" == "access-iso" ]]; then
        project="pwis"
    elif [[ "$repo_name" == "rt-monitoring" ]]; then
        project="da"
    elif [[ "$repo_name" == "uniperf" ]]; then
        project="tool"
    elif [[ "$repo_name" == "near_rtric" ]]; then
        project="near"
	fi
	ssh_path="$git_url/$project/$repo_name.git"
	clone_repo $ssh_path $repo_name
}

mapfile -t repos_names_array < <(jq -r '.[] | .[] | keys[]' ./manifest.json)
num_of_repos=${#repos_names_array[@]}
cd ..
pwd
for((i=0; i<$num_of_repos; i++))
do
	echo "repo name is: ${repos_names_array[$i]}. cloning now..."
	create_path_and_clone_repo ${repos_names_array[$i]}
done


