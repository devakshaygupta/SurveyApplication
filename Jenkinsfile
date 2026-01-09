pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 120, unit: 'MINUTES')
    }

    stages {
        stage('Clone repository') {
            environment {
                REPOSITORY_URL = "${params.REPOSITORY_URL}"
                SOURCE_BRANCH = "${params.SOURCE_BRANCH}"
                TARGET_BRANCH = "${params.TARGET_BRANCH}"
            }
            steps {
                // ensure SSH key + known_hosts are available for cloning
                sshagent (credentials: ['GITHUB_SSH_CREDENTIAL_ID']) {
                    sh '''
                    mkdir -p ~/.ssh && chmod 700 ~/.ssh
                    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
                    '''
                checkout scmGit(
                    branches: [[name: TARGET_BRANCH]],
                    userRemoteConfigs: [[credentialsId: 'GITHUB_SSH_CREDENTIAL_ID',
                        url: REPOSITORY_URL]]
                    )
                }
            }
        }

        stage('Obtain authorization') {
            environment {
                SALESFORCE_SERVER_URL = "${params.SALESFORCE_SERVER_URL}"
                TARGET_ALIAS = "${params.TARGET_ALIAS}"
                CLIENT_ID_CREDENTIAL_ID = "${params.CLIENT_ID_CREDENTIAL_ID}"
                CLIENT_SECRET_CREDENTIAL_ID = "${params.CLIENT_SECRET_CREDENTIAL_ID}"
            }
            steps {
                // bind secret text credentials explicitly to environment variables and obtain access token
                withCredentials([
                    string(credentialsId: CLIENT_ID_CREDENTIAL_ID, variable: 'CLIENT_ID'),
                    string(credentialsId: CLIENT_SECRET_CREDENTIAL_ID, variable: 'CLIENT_SECRET')
                ]) {
                    sh '''
                    curl -X POST "${SALESFORCE_SERVER_URL}/services/oauth2/token" \
                      --data-urlencode "grant_type=client_credentials" \
                      --data-urlencode "client_id=${CLIENT_ID}" \
                      --data-urlencode "client_secret=${CLIENT_SECRET}" >> output.json \
                      || { echo "Error: Failed to get access token from ${TARGET_ALIAS}"; exit 1; }

                    jq -r '.access_token' output.json | sf org login access-token \
                      --instance-url "${SALESFORCE_SERVER_URL}" \
                      --set-default \
                      --alias "${TARGET_ALIAS}" || { echo "Error: Failed to login to ${TARGET_ALIAS}"; exit 1; }

                    sf config set target-org "${TARGET_ALIAS}" \
                      || { echo "Error: Failed to set default org to ${TARGET_ALIAS}"; exit 1; }
                    '''
                }
            }
        }

        stage('Build') {
            environment {
                TIMEOUT_IN_SECONDS = "${params.TIMEOUT_IN_SECONDS}"
            }
            steps {
                // Run the same build/deploy command as before
                sh '''
                DELTA_DIR="delta_src"
                directory="$(pwd)"
                source="${SOURCE_BRANCH}"
                target="${TARGET_BRANCH}"
                CHANGED_SRC_LIST_FILE="changed_src_files.txt"
                DIR_NAME_META_FILE_JSON_DATA="DirectoryNameMetafile_v56.json"
                TEST_CLASS_MAPPING_JSON_DATA="TestClassMapping.json"

                declare -A dir_meta_file_exist_array
                declare -A test_class_mapping_array
                declare -a apex_classes_list=()

                git checkout "$target" || { echo "Error checking out target branch $target"; exit 1; }
                git pull || { echo "Error pulling latest changes for target branch $target"; exit 1; }
                git checkout "$source" || { echo "Error checking out source branch $source"; exit 1; }
                git pull || { echo "Error pulling latest changes for source branch $source"; exit 1; }

                eval "$(jq -r 'to_entries[] | @sh "dir_meta_file_exist_array[\\(.key|tostring)]=\\(.value)"' < "$DIR_NAME_META_FILE_JSON_DATA")"

                eval "$(jq -r 'to_entries[] | @sh "test_class_mapping_array[\\(.key|tostring)]=\\(.value)"' < "$TEST_CLASS_MAPPING_JSON_DATA")"

                if [[ -d "$DELTA_DIR" ]]
                then
                    rm -Rfv "$DELTA_DIR" || { echo "Error removing directory $DELTA_DIR"; exit 1; }
                fi

                mkdir -pv "$DELTA_DIR" || { echo "Error creating directory $DELTA_DIR"; exit 1; }

                { pushd "$directory" && git pull && git checkout "$target" && git pull && git checkout "$source" && git pull && git diff "$(git merge-base "$source" "$target")" "$source" --name-only --diff-filter=ACMR > "${CHANGED_SRC_LIST_FILE}" && popd; } || { echo "Error getting changed files list"; exit 1; }

                while read -r line; do
                    if [[ "$line" == *"force-app/main/default"* ]] && [[ "$line" != *"package.xml"* ]]
                    then
                        directory_name=$(echo "${line}" | cut -d'/' -f4)
                        parent_folder_name=$(echo "${line}" | cut -d'/' -f1)
                        meta_file_exist=${dir_meta_file_exist_array[$directory_name]}

                        install -Dv "${line}" "$DELTA_DIR/${line}" || { echo "Error copying file $line to $DELTA_DIR"; exit 1; }

                        if [[ "$meta_file_exist" == true ]]
                        then
                            install -Dv "${line}-meta.xml" "${DELTA_DIR}/${line}-meta.xml" || { echo "Error copying meta file $line-meta.xml to $DELTA_DIR"; exit 1; }
                        fi

                        file_name=$(echo "${line}" | cut -d'/' -f5 | cut -d'.' -f1)

                        if [[ "$directory_name" == "classes" ]]
                        then
                            apex_classes_list+=("$file_name")
                        fi
                    fi

                done < "${CHANGED_SRC_LIST_FILE}"

                test_classes_list=""

                for class_name in "${!test_class_mapping_array[@]}"
                do
                    if [[ -v apex_classes_list ]] && [[ -d "$DELTA_DIR/force-app/main/default/classes" ]]
                    then
                        # Read test class for given apex class and append to build.xml
                        if [[ "${apex_classes_list[*]}" =~ "$class_name" ]]
                        then
                            test_class_name=${test_class_mapping_array[$class_name]}
                        # If there are multiple test class for a given apex class
                        if [[ "$test_class_name" == *","* ]]
                        then
                            IFS="," read -ra test_classes_array <<< "$test_class_name"
                            test_classes_list+="$(printf "%s " "${test_classes_array[@]}")"
                        else
                            test_classes_list+="${test_class_name} "
                        fi
                    fi
                fi
                done

                for test_class_name in "${!test_class_list[@]}"
                do
                    # If the given class itself is test class
                    if [[ -f "$DELTA_DIR/force-app/main/default/classes/${test_class_list[test_class_name]}.cls" ]]
                    then
                        test_classes_list+="${test_class_list[test_class_name]} "
                    fi
                done

                if [[ -d "$DELTA_DIR/force-app/main/default/classes" ]]
                then
                    sf project deploy start --source-dir "${DELTA_DIR}/force-app" \
                      --wait "${TIMEOUT_IN_SECONDS}" \
                      --dry-run \
                      --test-level RunSpecifiedTests \
                      --tests $(echo "${test_classes_list[*]}") "Test With Space" \
                      --junit \
                      --results-dir "${directory}" \
                      --coverage-formatters clover \
                      --coverage-formatters html \
                      --coverage-formatters text
                else
                    sf project deploy start --source-dir "${DELTA_DIR}/force-app" \
                      --wait "${TIMEOUT_IN_SECONDS}" \
                      --dry-run \
                      --test-level NoTestRun
                fi
                '''
            }
        }
        stage('Report') {
            steps {
                clover(cloverReportDir: 'coverage', cloverReportFileName: 'clover.xml',
                    // optional, default is: method=70, conditional=80, statement=80
                    healthyTarget: [methodCoverage: 75, conditionalCoverage: 80, statementCoverage: 80],
                    // optional, default is none
                    unhealthyTarget: [methodCoverage: 50, conditionalCoverage: 50, statementCoverage: 50],
                    // optional, default is none
                    failingTarget: [methodCoverage: 0, conditionalCoverage: 0, statementCoverage: 0]
                )
            }
        }
    }

    post {
        always {
            deleteDir()
        }
    }
}
