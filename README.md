### Nudge Setup
I use https://github.com/macadmins/nudge in Jamf Pro. You're free to your own devices to install/configure. But below are some general assumptions in my setup.
* I use a policy to install Nudge and a LaunchAgent that runs on a schedule
* My policy works with a number of script parameters that configure the update channel (strict, default, relaxed), the LA schedule (M-F, 0-24hr prompts)
* To change the channel or schedule of a device - scope it to the appropriate policy and/or flush the policy logs
* The LA is looking for a json URL (the raw github URL - which must be public). It's also possible to host the file in a private repo and then when it changes have that trigger a workflow that uploads to a public AWS bucket or similar. 

---
### Repo Actions
* Check if "Read and write permissions" are enabled in Settings -> Actions -> General -> Workflow permissions
<img width="603" alt="workflow-permissions" src="https://github.com/distorted-fields/nudge-json-updater/assets/18072053/47c8e66b-2500-4398-b588-0f429182e471">

---
### GitHub Workflow
check-for-updated-macos-versions.yml is set to run with a manual trigger and on a 4hr cron. 
* Use a different schedule - https://crontab.guru/
