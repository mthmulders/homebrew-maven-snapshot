# Maven snapshot - Homebrew tap

![brew test-bot](https://github.com/mthmulders/homebrew-maven-snapshot/workflows/brew%20test-bot/badge.svg)

## ⚠️ Status ⚠️
Doesn't work (yet).
I'm still figuring out how to actually _make_ it work.

## How do I install these formulae?
`brew install mthmulders/maven-snapshot/<formula>`

Or `brew tap mthmulders/maven-snapshot` and then `brew install <formula>`.

## Documentation
`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Possible improvements
In order to not request too much data from Jenkins, it might be wise to [control the amount of data we fetch](https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master/api/).

## Development
Install [act](https://github.com/nektos/act/), then run `act -j update-formula`