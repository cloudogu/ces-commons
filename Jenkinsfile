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
            make 'clean debian checksum'
            archiveArtifacts 'target/**/*.deb'
            archiveArtifacts 'target/**/*.sha256sum'
        }

        stage('Sign'){
            gpg.createSignature()
            archiveArtifacts 'target/**/*.sha256sum.asc'
        }

        if (gitflow.isReleaseBranch()) {
            String releaseVersion = git.getSimpleBranchName();

            stage('Finish Release') {
                gitflow.finishRelease(releaseVersion)
            }

            stage('Build after Release') {
                git.checkout(releaseVersion)
                make 'clean debian checksum'
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

void make(String makeArgs) {
    sh "make ${makeArgs}"
}

void gitWithCredentials(String command) {
    withCredentials([usernamePassword(credentialsId: 'cesmarvin', usernameVariable: 'GIT_AUTH_USR', passwordVariable: 'GIT_AUTH_PSW')]) {
        sh(
                script: "git -c credential.helper=\"!f() { echo username='\$GIT_AUTH_USR'; echo password='\$GIT_AUTH_PSW'; }; f\" " + command,
                returnStdout: true
        )
    }
}

void withAptlyCredentials(Closure closure){
    withCredentials([usernamePassword(credentialsId: 'websites_apt-api.cloudogu.com_aptly-admin', usernameVariable: 'APT_API_USERNAME', passwordVariable: 'APT_API_PASSWORD')]) {
        withCredentials([string(credentialsId: 'misc_signphrase_apt-api.cloudogu.com', variable: 'APT_API_SIGNPHRASE')]) {
            closure.call()
        }
    }
}
