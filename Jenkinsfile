#!groovy
@Library(['github.com/cloudogu/ces-build-lib@1.62.0'])
import com.cloudogu.ces.cesbuildlib.*

node('vagrant') {
    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)
    Docker docker = new Docker(this)
    Gpg gpg = new Gpg(this, docker)
    Markdown markdown = new Markdown(this)

    project = 'github.com/cloudogu/ces-commons'
    projectName = 'ces-commons'
    branch = "${env.BRANCH_NAME}"

    timestamps {
        stage('Checkout') {
            checkout scm
        }

        stage('Check Markdown Links') {
            markdown.check()
        }

        stage('Build') {
            make 'clean debian signature'
            archiveArtifacts 'target/**/*.deb'
            archiveArtifacts 'target/**/*.sha256sum'
        }

        stage('Sign'){
            gpg.createSignature()
            archiveArtifacts 'target/**/*.sha256sum.asc'
        }

        stage('SonarQube') {
            def scannerHome = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
            withSonarQubeEnv {
                sh "git config 'remote.origin.fetch' '+refs/heads/*:refs/remotes/origin/*'"
                gitWithCredentials("fetch --all")

                if (branch == "master") {
                    echo "This branch has been detected as the master branch."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName}"
                } else if (branch == "develop") {
                    echo "This branch has been detected as the develop branch."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.branch.name=${env.BRANCH_NAME} -Dsonar.branch.target=master  "
                } else if (env.CHANGE_TARGET) {
                    echo "This branch has been detected as a pull request."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.pullrequest.key=${env.CHANGE_ID} -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} -Dsonar.pullrequest.base=develop    "
                } else if (branch.startsWith("feature/")) {
                    echo "This branch has been detected as a feature branch."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.branch.name=${env.BRANCH_NAME} -Dsonar.branch.target=develop"
                } else if (branch.startsWith("bugfix/")) {
                    echo "This branch has been detected as a bugfix branch."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.branch.name=${env.BRANCH_NAME} -Dsonar.branch.target=develop"
                } else {
                    echo "This branch has been detected as a miscellaneous branch."
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.branch.name=${env.BRANCH_NAME} -Dsonar.branch.target=develop"
                }
            }
            timeout(time: 2, unit: 'MINUTES') { // Needed when there is no webhook for example
                def qGate = waitForQualityGate()
                if (qGate.status != 'OK') {
                    unstable("Pipeline unstable due to SonarQube quality gate failure")
                }
            }
        }

        if (gitflow.isReleaseBranch()) {
            String releaseVersion = git.getSimpleBranchName();

            stage('Finish Release') {
                gitflow.finishRelease(releaseVersion)
            }

            stage('Build after Release') {
                git.checkout(releaseVersion)
                make 'clean debian signature'
            }

            stage('Push to apt') {
                withAptlyCredentials{
                    make 'deploy'
                }
            }

            stage('Sign after Release'){
                gpg.createSignature()
            }

            stage('Add Github-Release') {
                releaseId=github.createReleaseWithChangelog(releaseVersion, changelog)
                github.addReleaseAsset("${releaseId}", "target/ces-commons.sha256sum")
                github.addReleaseAsset("${releaseId}", "target/ces-commons.sha256sum.asc")
            }
        }
    }
}