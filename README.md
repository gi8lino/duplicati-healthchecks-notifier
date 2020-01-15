# Duplicati Healthchecks Notifier

Script to add as `run-script-after` in [Duplicati](https://www.duplicati.com). It notifys [Healthchecks](https://healthchecks.io) after running a backup job.  
If the backup was not successfully, it pings '\fail'.

## How it works

The Script gets a list of all existing Healthchecks checks. If there is a Healhcheck with the same name as the Duplicati job, it notifys Healthchecks.

## Usage

`dhn.sh [-u|--url URL] [-t|--token TOKEN] [-a|--allowed-operations "TYPE ..."] [-s|--send-start] [-jq|--jq-path PATH] [-l|--log-file PATH] [-d|--debug] | [-h|--help] | -v|--version]`

## Parameters

| parameter                              | description                                                |
| -------------------------------------- | ---------------------------------------------------------- |
| `-u|--url [URL]`                       | healthchecks url                                           |
| `-t|--token [TOKEN]`                   | healthchecks API Access ('read-only' token does not work!) |
| `-a|--allowed-operations "[TYPE] ..."` | only notify if types of operations match list of strings   |
| `-s|--send-start`                      | notify healthchecks when operation starts                  |
| `-j|--jq-path [PATH]`                  | path to jq if not in '$PATH'                               |
| `-l|--log-file [PATH]`                 | log to file. if not set log to console                     |
| `-d|--debug`                           | set log level to 'debug'                                   |
| `-h|--help`                            | display this help and exit                                 |
| `-v|--version`                         | output version information and exit                        |

Because you cannot pass arguments in Duplicati, you need to create a additional script.

### Example

``` bash
#!/bin/bash

TOKEN=$(printenv HC_TOKEN)  # get Healthchecks token from environment variable 'HC_TOKEN'
URL="https://healthchecks.example.com"
/opt/duplicati-healthchecks-notifier/dhn.sh -d -l /var/log/duplicati/dhn.log -t $TOKEN -u $URL -s
```

## Configuration

### Healthchecks

The Healthchecks check name has to be equal to the Duplicati job name.

### Duplicati

* Goto `Settings` => `Add advanced option` => select `run-script-after: Run a script on exit`
* Add the path to the script
* click on `OK`

to notify when duplicati starts add `run-script-before: Run a script on startup`
