# Maven snapshot builds - Homebrew tap

![brew test-bot](https://github.com/mthmulders/homebrew-maven-snapshot/workflows/brew%20test-bot/badge.svg)

## Status
The tap seems to work quite well and is automatically updated with newer snapshot builds of Maven as soon as they are built.

**Note that this tap conflicts with the regular, stable Maven that is installed with `brew install maven`.**
**If you prefer a stable version of Maven, use that one.**

If you prefer a possibly less stable version of Maven with the latest features - _and possibly bugs_, you may choose to use this tap.

## Feedback and contributions
If you have feedback on the tap itself, please file an [issue](https://github.com/mthmulders/homebrew-maven-snapshot/issues) or even better, create a [pull request](https://github.com/mthmulders/homebrew-maven-snapshot/pulls).
See under [Development](#development) for how to debug, troubleshoot or test.

Feedback on the Maven builds should **not** does not belong in this repository.
I will simply close such issues.
Instead, please report such feedback at [the Apache Software Foundation JIRA](https://issues.apache.org/jira/browse/MNG).

## How do I install this formula?
`brew install mthmulders/maven-snapshot/maven-snapshot`

Or `brew tap mthmulders/maven-snapshot` and then `brew install maven-snapshot`.

## Switching between "stable" and "snapshot"
To use the latest stable Maven version installed that Brew installed for you, issue
```sh
brew unlink maven-snapshot && brew link maven
```

To go back to the (possibly unstable) snapshot, issue
```sh
brew unlink maven && brew link maven-snapshot
```

## Keeping up-to-date
Simple: issue `brew upgrade` and you'll receive the latest build that passed the extensive [Maven integration test suite](https://github.com/apache/maven-integration-testing/).

## Possible improvements
* [ ] In order to not request too much data from Jenkins, it might be wise to [control the amount of data we fetch](https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master/api/).
* [ ] Instead of polling Jenkins for data, it might be more elegant and efficient to _push_ changes to the formula.
But that requires changes to how Jenkins is working and that might be a bit hard to achieve.
* [ ] Eventually, this formula might be merged with the [official `maven` formula](https://github.com/Homebrew/homebrew-core/blob/master/Formula/maven.rb), leveraging its `--head` option.

## Development
First, install [act](https://github.com/nektos/act/).
Since the images used by _act_ do not include Ruby or Git, you may want to add an additional step to **.github/workflows/update-formula.yml**, right after the **Checkout** step:

```yml
    - name: Install Ruby and Git
      run: |
        sudo apt-get update
        sudo apt-get install -y ruby git
        echo ""
        ruby -v
        git --version
```

Now you can run `act -j update-formula` to simulate a GitHub Action run.
The `git push` will fail, alternatively replace it with `cat Formula/maven-snapshot.rb` to inspect the updated Homebrew formula.
