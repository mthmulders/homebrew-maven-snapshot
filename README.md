# Maven snapshot builds - Homebrew tap

![brew test-bot](https://github.com/mthmulders/homebrew-maven-snapshot/workflows/brew%20test-bot/badge.svg)

## Status
The tap seems to work quite well and is automatically updated with newer snapshot builds of Maven as soon as they are built.

**Note that this tap conflicts with the regular, stable Maven that is installed with `brew install maven`.**


If you prefer a stable version of Maven, use that one.
If you prefer a possibly less stable version of Maven with the latest features - _and possibly bugs_, you may choose to use this tap.

## Feedback and contributions
If you have feedback on the tap itself, please file an [issue](https://github.com/mthmulders/homebrew-maven-snapshot/issues) or even better, create a [pull request](https://github.com/mthmulders/homebrew-maven-snapshot/pulls).

Feedback on the Maven builds should **not** does not belong in this repository.
I will simply close such issues.
Instead, please report such feedback at [the Apache Software Foundation JIRA](https://issues.apache.org/jira/browse/MNG).

## How do I install these formulae?
`brew install mthmulders/maven-snapshot/maven-snapshot`

Or `brew tap mthmulders/maven-snapshot` and then `brew install maven-snapshot`.

## Documentation
`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Possible improvements
In order to not request too much data from Jenkins, it might be wise to [control the amount of data we fetch](https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master/api/).

## Development
Install [act](https://github.com/nektos/act/), then run `act -j update-formula`