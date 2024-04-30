#!/bin/bash
#
#
#
#           Created by A.Hodgson                     
#            Date: 2024-04-12                            
#            Purpose: Keep a json file up to date with N, N-1, and N-2 latest versions
#
#
#
#############################################################
# Variables
osN=14
osN1=13
osN2=12
#-----------------------------------------------------------#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
version_json_url="https://raw.githubusercontent.com/distorted-fields/nudge-json-updater/main/latest-os-versions.json"
curl -sL "$version_json_url" -o "$SCRIPT_DIR/latest-os-versions.json"
version_json_file="$SCRIPT_DIR/latest-os-versions.json"
#############################################################
# Functions
#############################################################
function get_latest_versions(){
	# Get latest versions
	os_releases=$(curl -sL https://gdmf.apple.com/v2/pmv)
	latest_versions=$(echo $os_releases | jq -r '.PublicAssetSets.macOS[].ProductVersion')
	#-----------------------------------------------------------#
	current_N=$(jq '.LatestVersions[].N.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
	current_N1=$(jq '.LatestVersions[].N1.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
	current_N2=$(jq '.LatestVersions[].N2.CurrentVersion' "$version_json_file" | sed -e 's|"||g')
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
				if [[ "$version_major" == "$osN" ]]; then
					cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
				elif [[ "$version_major" == "$osN1" ]]; then
					cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N1.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
				elif [[ "$version_major" == "$osN2" ]]; then
					cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N2.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
				fi
			else
				if [[ $version_point -gt $compare_version_point ]]; then
					echo "Updating $compare_version to $version"
					if [[ "$version_major" == "$osN" ]]; then
						cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
					elif [[ "$version_major" == "$osN1" ]]; then
						cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N1.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
					elif [[ "$version_major" == "$osN2" ]]; then
						cat "$version_json_file" | jq --arg updateVal "$version" '.LatestVersions[].N2.CurrentVersion = $updateVal' | tee "$version_json_file" > /dev/null
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
	echo "Latest $osN: $current_N"
	echo "Latest $osN1: $current_N1"
	echo "Latest $osN2: $current_N2"
}
#############################################################
# MAIN
#############################################################
get_latest_versions
echo "#############################################################"
echo "DONE!"
