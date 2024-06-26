#!/bin/bash
#
#
#
#           Created by A.Hodgson                     
#            Date: 2024-04-12                            
#            Purpose: Automatically update nudge JSON files
#
#
#
#############################################################
run_local='n'
#-----------------------------------------------------------#
SLACK_URL="$1"
#-----------------------------------------------------------#
# Variables
osN=14
about_N_url="https://support.apple.com/en-us/HT213895"
osN1=13
about_N1_url="https://support.apple.com/en-us/HT213268"
osN2=12
about_N2_url="https://support.apple.com/en-us/HT212585"
#-----------------------------------------------------------#
# JSON files must be in a folder called 'JSON', add/remove as necessary
json_files=("strict" "default" "relaxed" "jc-default")

#############################################################
# 			DO NOT EDIT BELOW !!!
#############################################################

#-----------------------------------------------------------#
# System Variables - 
#-----------------------------------------------------------#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#-----------------------------------------------------------#
version_json_file="$SCRIPT_DIR/latest-os-versions.json"
json_file_updated=false
#-----------------------------------------------------------#
startingDate=$(date +"%Y-%m-%d") # today
#############################################################
# Functions
#############################################################
function update_repo(){
	git add "$1"
}

function commit_repo(){
	echo "#############################################################"
	git commit -m "Updating the repo with new files"
	git status
	git push origin main
	echo "#############################################################"
}

function get_latest_versions(){
	# Get latest versions from Apple
	os_releases=$(curl -sL https://gdmf.apple.com/v2/pmv)
	latest_versions=$(echo $os_releases | jq -r '.PublicAssetSets.macOS[].ProductVersion')
	echo "Results from Apple:"
	echo "$latest_versions"
	echo "#############################################################"
	#-----------------------------------------------------------#
	current_N=$(jq -r '.LatestVersions[].N.CurrentVersion' "$version_json_file" )
	current_N1=$(jq -r '.LatestVersions[].N1.CurrentVersion' "$version_json_file")
	current_N2=$(jq -r '.LatestVersions[].N2.CurrentVersion' "$version_json_file")
	echo "Pre-flight JSON version check:"
	echo "Latest $osN: $current_N"
	echo "Latest $osN1: $current_N1"
	echo "Latest $osN2: $current_N2"
	echo "#############################################################"
	#-----------------------------------------------------------#
	# Compare latest to current, and update current
	while IFS= read -r version
	do
		version_major=$(echo "$version" | cut -d '.' -f1)
		version_minor=$(echo "$version" | cut -d '.' -f2)
		version_point=$(echo "$version" | cut -d '.' -f3)

		if [[ "$version_major" == "$osN" ]] || [[ "$version_major" == "$osN1" ]] || [[ "$version_major" == "$osN2" ]]; then

			if [[ "$version_major" == "$osN" ]]; then
				compare_version="$current_N"
			elif [[ "$version_major" == "$osN1" ]]; then
				compare_version="$current_N1"
			elif [[ "$version_major" == "$osN2" ]]; then
				compare_version="$current_N2"
			fi

			compare_version_minor=$(echo "$compare_version" | cut -d '.' -f2)
			compare_version_point=$(echo "$compare_version" | cut -d '.' -f3)

			if [[ $version_minor -gt $compare_version_minor ]]; then
				echo "Updating $compare_version to $version"
				json_file_updated=true
				tmp=$(mktemp)
				if [[ "$version_major" == "$osN" ]]; then
		   			jq --arg updateVal "$version" '.LatestVersions[].N.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
				elif [[ "$version_major" == "$osN1" ]]; then
					jq --arg updateVal "$version" '.LatestVersions[].N1.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
				elif [[ "$version_major" == "$osN2" ]]; then
					jq --arg updateVal "$version" '.LatestVersions[].N2.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
				fi
			else
				if [[ $version_point -gt $compare_version_point ]]; then
					echo "Updating $compare_version to $version"
					json_file_updated=true
					tmp=$(mktemp)
					if [[ "$version_major" == "$osN" ]]; then
						jq --arg updateVal "$version" '.LatestVersions[].N.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
					elif [[ "$version_major" == "$osN1" ]]; then
						jq --arg updateVal "$version" '.LatestVersions[].N1.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
					elif [[ "$version_major" == "$osN2" ]]; then
						jq --arg updateVal "$version" '.LatestVersions[].N2.CurrentVersion = $updateVal' "$version_json_file" > "$tmp" && mv "$tmp" "$version_json_file"
					fi
				else
					echo "Latest version: $version matches current version: $compare_version"
				fi
			fi
		fi

	done <<< "$latest_versions"
	#-----------------------------------------------------------#
	# Refetch latest versions
	current_N=$(jq '.LatestVersions[].N.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
	current_N1=$(jq '.LatestVersions[].N1.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
	current_N2=$(jq '.LatestVersions[].N2.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
	echo "#############################################################"
	echo "Post-flight JSON version check:"
	echo "Latest $osN: $current_N"
	echo "Latest $osN1: $current_N1"
	echo "Latest $osN2: $current_N2"
	echo "#############################################################"
	echo "latest-os-versions.json contents:"
	cat "$version_json_file"
	echo "#############################################################"
	echo "Did the JSON change: $json_file_updated"
}

function backup_json_files(){
	for current_file_name in ${json_files[@]}; do
		json_file="$SCRIPT_DIR/json/$current_file_name.json"
		echo "Backing up $json_file"
		cp "$json_file" "$SCRIPT_DIR/backups/$current_file_name-$startingDate.json"
		if [ "$run_local" != "y" ]; then
			update_repo "$SCRIPT_DIR/backups/$current_file_name-$startingDate.json"
		fi
	done
}

function calculate_new_deadline_dates(){
	echo "#############################################################"
	echo "	New Tuesday Deadlines"
	echo "#############################################################"
	#-----------------------------------------------------------#
	strict_timeline=14
	default_timeline=30
	relaxed_timeline=60
	#-----------------------------------------------------------#
	strict_dday=$(date -j -v +"$strict_timeline"d -f "%Y-%m-%d" "$startingDate" +"%a %Y-%m-%d")
	default_dday=$(date -j -v +"$default_timeline"d -f "%Y-%m-%d" "$startingDate" +"%a %Y-%m-%d")
	relaxed_dday=$(date -j -v +"$relaxed_timeline"d -f "%Y-%m-%d" "$startingDate" +"%a %Y-%m-%d")
	#-----------------------------------------------------------#
	strict_tuesday_dday=$(calculate_tuesday_deadline "$strict_dday")
	default_tuesday_dday=$(calculate_tuesday_deadline "$default_dday")
	relaxed_tuesday_dday=$(calculate_tuesday_deadline "$relaxed_dday")
	#-----------------------------------------------------------#
	echo " Strict  = $strict_tuesday_dday"
	echo " Default = $default_tuesday_dday"
	echo " Relaxed = $relaxed_tuesday_dday"
	#-----------------------------------------------------------#
	echo ""
}

function calculate_tuesday_deadline(){
	new_date="$1"
	# Add appropriate amount of days to make the following Tuesday of X date the actual deadline
	if [[ "$new_date" == *"Wed"* ]]; then	
		new_date=$(date -j -v +6d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	elif [[ "$new_date" == *"Thu"* ]]; then
		new_date=$(date -j -v +5d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	elif [[ "$new_date" == *"Fri"* ]]; then
		new_date=$(date -j -v +4d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	elif [[ "$new_date" == *"Sat"* ]]; then
		new_date=$(date -j -v +3d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	elif [[ "$new_date" == *"Sun"* ]]; then
		new_date=$(date -j -v +2d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	elif [[ "$new_date" == *"Mon"* ]]; then
		new_date=$(date -j -v +1d -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	else
		new_date=$(date -j -f "%a %Y-%m-%d" "$new_date" +"%Y-%m-%d")
	fi

	echo "$new_date"
}

function calculate_previous_latest_versions(){
	echo "#############################################################"
	echo "	PREVIOUS TARGET VERSIONS"
	echo "#############################################################"
	#-----------------------------------------------------------#
	previous_N=""
	previous_N1=""
	previous_N2=""
	#-----------------------------------------------------------#
	current_N_major=$(echo "$current_N" | cut -d '.' -f1)
	current_N1_major=$(echo "$current_N1" | cut -d '.' -f1)
	current_N2_major=$(echo "$current_N2" | cut -d '.' -f1)
	#-----------------------------------------------------------#
	versions=$(jq -r '.osVersionRequirements[].requiredMinimumOSVersion' "$json_file")
	while IFS= read -r version
	do
		version_major=$(echo "$version" | cut -d '.' -f1)
		version_minor=$(echo "$version" | cut -d '.' -f2)
		version_point=$(echo "$version" | cut -d '.' -f3)
		if [[ "$version_major" == *"$current_N_major"* ]]; then
			if [ "$previous_N" == "" ]; then
				previous_N="$version"
			else
				previous_N_minor=$(echo "$previous_N" | cut -d '.' -f2)
				if [ $version_minor -gt $previous_N_minor ]; then
					previous_N=$version
				else
					previous_N_point=$(echo "$previous_N" | cut -d '.' -f3)
					if [ $version_point -gt $previous_N_point ]; then
						previous_N=$version
					fi
				fi
			fi
		elif [[ "$version_major" == *"$current_N1_major"* ]]; then
			if [ "$previous_N1" == "" ]; then
				previous_N1="$version"
			else
				previous_N1_minor=$(echo "$previous_N1" | cut -d '.' -f2)
				if [ $version_minor -gt $previous_N1_minor ]; then
					previous_N1=$version
				else
					previous_N1_point=$(echo "$previous_N1" | cut -d '.' -f3)
					if [ $version_point -gt $previous_N1_point ]; then
						previous_N1=$version
					fi
				fi
			fi
		else
			if [ "$previous_N2" == "" ]; then
				previous_N2="$version"
			else
				previous_N2_minor=$(echo "$previous_N2" | cut -d '.' -f2)
				if [ $version_minor -gt $previous_N2_minor ]; then
					previous_N2=$version
				else
					previous_N2_point=$(echo "$previous_N2" | cut -d '.' -f3)
					if [ $version_point -gt $previous_N2_point ]; then
						previous_N2=$version
					fi
				fi
			fi
		fi
	done <<< "$versions"
	#-----------------------------------------------------------#
	echo " N   = $previous_N"
	echo " N-1 = $previous_N1"
	echo " N-2 = $previous_N2"
	#-----------------------------------------------------------#
	echo ""

}

function delete_expired_rules(){
	echo "#############################################################"
	echo "	Deleting Expired Rules"
	echo "#############################################################"
	#-----------------------------------------------------------#
	# get install dates
	install_dates_times=$(jq -r '.osVersionRequirements[].requiredInstallationDate' "$json_file")

	while IFS= read -r install_date_time
	do
		# get just the date portion
		install_date=$(echo "$install_date_time" | cut -d 'T' -f1)
		# if date is older than new target, delete
	   	if [[ "$startingDate" > "$install_date" ]] ; then
	   		# get target rule based on date
	   		target_rules=$(jq -r --arg target_date "${install_date}T16:00:00Z" '.osVersionRequirements[] | select(.requiredInstallationDate == $target_date) | .targetedOSVersionsRule' "$json_file")
	   		while IFS= read -r current_rule
			do
				tmp=$(mktemp)
		   		if [ "$current_rule" != "default" ]; then
		   			if [[ "$current_rule" == *"$current_N_major"* ]] && [[ "$current_rule" != "$current_N_major" ]] && [[ "$current_N_major" != "" ]]; then
		   				echo "Rule $current_rule expired on $install_date - Deleting..."
		   				#-----------------------------------------------------------#
		   				jq --arg rule "$current_rule" 'del(.osVersionRequirements[] | select(.targetedOSVersionsRule == $rule))' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
					fi
					if [[ "$current_rule" == *"$current_N1_major"* ]] && [[ "$current_rule" != "$current_N1_major" ]] && [[ "$current_N1_major" != "" ]]; then
		   				echo "Rule $current_rule expired on $install_date - Deleting..."
		   				#-----------------------------------------------------------#
						jq --arg rule "$current_rule" 'del(.osVersionRequirements[] | select(.targetedOSVersionsRule == $rule))' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
					fi
					if [[ "$current_rule" == *"$current_N2_major"* ]] && [[ "$current_rule" != "$current_N2_major" ]] && [[ "$current_N2_major" != "" ]]; then
		   				echo "Rule $current_rule expired on $install_date - Deleting..."
		   				#-----------------------------------------------------------#
		   				jq --arg rule "$current_rule" 'del(.osVersionRequirements[] | select(.targetedOSVersionsRule == $rule))' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
					fi
				fi
			done <<< "$target_rules"
	   	fi
	done <<< "$install_dates_times"
	#-----------------------------------------------------------#
	echo ""
}

function update_min_os_requirements(){
	echo "#############################################################"
	echo "	Target OS Version Rules"
	echo "#############################################################"
	#-----------------------------------------------------------#
	target_rules=$(jq -r '.osVersionRequirements[].targetedOSVersionsRule' "$json_file")
	
	while IFS= read -r current_rule
	do
		tmp=$(mktemp)
		echo "Current Rule: $current_rule"
		if [[ "$current_rule" == *"$current_N_major"* ]] && [[ "$current_N_major" != "" ]]; then
			echo "	Updating Rule: $current_rule to require $current_N"
			#-----------------------------------------------------------#
			jq --arg rule "$current_rule" --arg updateVal "$current_N" \
	 			'.osVersionRequirements = [.osVersionRequirements[] | if (.targetedOSVersionsRule == $rule) then (.requiredMinimumOSVersion |= $updateVal) else . end]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	 	elif [[ "$current_rule" == *"$current_N1_major"* ]] && [[ "$current_N1_major" != "" ]]; then
	 		echo "	Updating Rule: $current_rule to require $current_N1"
			#-----------------------------------------------------------#
			jq --arg rule "$current_rule" --arg updateVal "$current_N1" \
	 			'.osVersionRequirements = [.osVersionRequirements[] | if (.targetedOSVersionsRule == $rule) then (.requiredMinimumOSVersion |= $updateVal) else . end]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	 	elif [[ "$current_rule" == *"$current_N2_major"* ]] && [[ "$current_N2_major" != "" ]]; then
	 		echo "	Updating Rule: $current_rule to require $current_N2"
			#-----------------------------------------------------------#
			jq --arg rule "$current_rule" --arg updateVal "$current_N2" \
	 			'.osVersionRequirements = [.osVersionRequirements[] | if (.targetedOSVersionsRule == $rule) then (.requiredMinimumOSVersion |= $updateVal) else . end]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	 	else
	 		if [ "$current_file_name" == "strict" ] || [ "$current_file_name" == "jc-default" ]; then
	 			new_default="$current_N"
	 		elif [ "$current_file_name" == "default" ]; then
	 			new_default="$current_N1"
	 		else
	 			new_default="$current_N2"
	 		fi
	 		if [ "$new_default" != "" ]; then
	 			#-----------------------------------------------------------#
	 			echo "	Updating Rule: $current_rule to require $new_default"
				#-----------------------------------------------------------#
	 			jq --arg rule "$current_rule" --arg updateVal "$new_default" \
					'.osVersionRequirements = [.osVersionRequirements[] | if (.targetedOSVersionsRule == $rule) then (.requiredMinimumOSVersion |= $updateVal) else . end]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
			fi
	 	fi
	done <<< "$target_rules"
	#-----------------------------------------------------------#
	echo ""
}

function create_new_deadline_rule(){
	tmp=$(mktemp)
	echo "#############################################################"
	echo "	Creating NEW Target OS Version Rules"
	echo "#############################################################"
	#-----------------------------------------------------------#
	if [ "$current_file_name" == "strict" ]; then
		required_tuesday_dday="${strict_tuesday_dday}T16:00:00Z"
	elif [ "$current_file_name" == "default" ] || [ "$current_file_name" == "jc-default" ]; then
		required_tuesday_dday="${default_tuesday_dday}T16:00:00Z"
	else
		required_tuesday_dday="${relaxed_tuesday_dday}T16:00:00Z"
	fi
	if [ "$current_N" != "" ] && [[ "$previous_N" != "" ]] && [[ "$current_N" != "$previous_N" ]]; then
		echo "Creating Rule: $current_N"
		echo "	Install Deadline: $required_tuesday_dday"
		echo " 	About URL: $about_N_url"
		echo "	Targeted OS: $previous_N"
		#-----------------------------------------------------------#
		jq --arg url "$about_N_url" \
			--arg required_date "$required_tuesday_dday" \
			--arg required_minOS "$current_N" \
			--arg targetOS_rule "$previous_N" \
			'.osVersionRequirements += [{
     			"aboutUpdateURL": $url,
     			"requiredInstallationDate": $required_date, 
     			"requiredMinimumOSVersion": $required_minOS, 
     			"targetedOSVersionsRule": $targetOS_rule
			}]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	fi
	if [ "$current_N1" != "" ] && [[ "$previous_N1" != "" ]] && [[ "$current_N1" != "$previous_N1" ]]; then
		echo "Creating Rule: $current_N1"
		echo "	Install Deadline: $required_tuesday_dday"
		echo " 	About URL: $about_N1_url"
		echo "	Targeted OS: $previous_N1"
		#-----------------------------------------------------------#
		jq --arg url "$about_N1_url" \
			--arg required_date "$required_tuesday_dday" \
			--arg required_minOS "$current_N1" \
			--arg targetOS_rule "$previous_N1" \
			'.osVersionRequirements += [{
     			"aboutUpdateURL": $url,
     			"requiredInstallationDate": $required_date, 
     			"requiredMinimumOSVersion": $required_minOS, 
     			"targetedOSVersionsRule": $targetOS_rule
			}]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	fi
	if [ "$current_N2" != "" ] && [[ "$previous_N2" != "" ]] && [[ "$current_N2" != "$previous_N2" ]]; then
		echo "Creating Rule: $current_N2"
		echo "	Install Deadline: $required_tuesday_dday"
		echo " 	About URL: $about_N2_url"
		echo "	Targeted OS: $previous_N2"
		#-----------------------------------------------------------#
		jq --arg url "$about_N2_url" \
			--arg required_date "$required_tuesday_dday" \
			--arg required_minOS "$current_N2" \
			--arg targetOS_rule "$previous_N2" \
			'.osVersionRequirements += [{
     			"aboutUpdateURL": $url,
     			"requiredInstallationDate": $required_date, 
     			"requiredMinimumOSVersion": $required_minOS, 
     			"targetedOSVersionsRule": $targetOS_rule
			}]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
	fi
	#-----------------------------------------------------------#
	echo ""
}

function sort_rules(){
	new_rules_array=$(cat "$json_file" | jq '.osVersionRequirements | sort_by(.targetedOSVersionsRule | ascii_downcase)' )
	cat "$json_file" | jq --argjson new_array "$new_rules_array" '.osVersionRequirements = $new_array' | tee "$json_file" > /dev/null
}

#############################################################
# MAIN
#############################################################
get_latest_versions
if $json_file_updated; then
	backup_json_files
	if [ "$run_local" != "y" ]; then
		update_repo "$version_json_file"
	fi

	for current_file_name in ${json_files[@]}; do
		json_file="$SCRIPT_DIR/json/$current_file_name.json"
		echo "#############################################################"
		echo "#############################################################"
		echo "	Current JSON File = $current_file_name"
		echo ""
	  	calculate_previous_latest_versions
	  	delete_expired_rules
		update_min_os_requirements
		calculate_new_deadline_dates
		create_new_deadline_rule
		sort_rules
		if [ "$run_local" != "y" ]; then
			update_repo "$SCRIPT_DIR/json/$current_file_name.json"
		fi
	done
	if [ "$run_local" != "y" ]; then
		commit_repo
		#ping slack
   		curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"New versions of macOS have been updated. Please review the changes: https://github.com/distorted-fields/nudge-json-updater \"}" $SLACK_URL
	fi
else
	echo "#############################################################"
	echo "Nothing changed, skipping repo update"
fi
echo "#############################################################"
echo "DONE!"
