# Duplicati Healthchecks Notifier

Script to add as 'run-script-before' and/or `run-script-after` in [Duplicati](https://www.duplicati.com).  
To measuring the Duplicati job execution time use `run-script-before` in Duplicati and start the script with the parameter `-s|--send-start`. The script will append `/start` to the Healthchecks ping url.  
To signal Healthchecks a Duplicati `Success` event add this script as `run-script-after` in Duplicati.  
If the Duplicati job was not successfully, it pings Healthchecks with `/fail`.

## How it works

The Script gets a list of all existing Healthchecks checks. If there is a Healhcheck with the same name as the Duplicati job, it notifies Healthchecks.

## Usage

```bash
dhn.sh [-u|--url URL]
       [-t|--token TOKEN]
       [-a|--allowed-operations "TYPE ..."]
       [-jq|--jq-path PATH]
       [-l|--log-file PATH]
       [-s|--send-start]
       [-p|--prefix [PREFIX]]
       [-d|--debug] | -v|--version] | [-h|--help]
```

## Parameters

| parameter                              | description                                                      |
| -------------------------------------- | ---------------------------------------------------------------- |
| `-u|--url [URL]`                       | Healthchecks url                                                 |
| `-t|--token [TOKEN]`                   | Healthchecks API Access token ('read-only' token does not work!) |
| `-a|--allowed-operations "[TYPE] ..."` | only notify if types of operations match list of strings         |
| `-j|--jq-path [PATH]`                  | path to jq if not in '$PATH'                                     |
| `-l|--log-file [PATH]`                 | log to file. if not set log to console (optional)                |
| `-s|--send-start`                      | notify Healthchecks when operation starts (optional)             |
| `-p|--prefix [TOKEN]`                  | prefix for Healthcheck job name (optional)                       |
| `-d|--debug`                           | set log level to 'debug'                                         |
| `-v|--version`                         | output version information and exit                              |
| `-h|--help`                            | display this help and exit                                       |

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

To measuring the Duplicati job execution time add this script as 'run-script-before: Run a script on startup'.
