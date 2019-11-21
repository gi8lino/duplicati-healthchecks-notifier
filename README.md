# Duplicati Healthchecks Notifier
Script to add as `run-script-after` in [Duplicati](https://www.duplicati.com). It notify [healthchecks](https://healthchecks.io) after running a backup job.<br>
If the backup was not successfully, it pings '\fail'.<br>

## How it works
The Script get a list of all existing Healthchecks checks. If there is a Healhcheck with the same Name as the Duplicati Job, it notify Healthchecks.

## Usage
`dhn.sh [-u|--url URL] [-t|--token TOKEN] [-jq|--jq-path PATH] [-l|--log-file PATH] [-d|--debug] | [-h|--help] | -v|--version]`

## Parameters
* `-u|--url [URL]` - healthchecks url
* `-t|--token [TOKEN]` - healthchecks API Access ('read-only' token does not work!)
* `-j|--jq-path [PATH]` - path to jq if not in 'PATH'
* `-l|--log-file [PATH]` - log to file. if not set log to console
* `-d|--debug` - set log level to 'debug'
* `-h|--help` - display this help and exit
* `-v|--version` - output version information and exit

If you want use parameters, you must create a separate script. Duplicati cannot pass arguments.
### Example
``` bash
#!/bin/bash
/opt/duplicati-healthchecks/dhn.sh -d -l /var/log/duplicati/dhn.log
```
## Environment variables
You can also use environment variables to set the healthchecks url and token.
* `HC_URL` - healthchecks url
* `HC_TOKEN` - healthchecks API Access ('read-only' token does not work!)

## Configuration
### Healthchecks
The Healthchecks Check Name must be equal the Duplicati Job Name. 
### Duplicati
* Goto `Setting` => `Add advanced option` => select `run-script-after: Run a script on exit`
* Add the path to the script
* click on `OK`
