#!/bin/bashset -ePROJECTDIR=/app/mnt/data/fabk8shellARGS_NUMBER="$#"COMMAND=""NAMESPACE=""function verifyArg() {    if [ $ARGS_NUMBER -lt 4 ]; then       funHelp        exit 1;    fi}function funHelp(){    echo $@    cat << EOF    Usage:        -o <command>        操作选项        -n <namespace>      网络名称        -h <help>           帮助    启动 e.g:   返回值  1 成功  其他失败        $0 -o start -n myns -c mychannel    停止 e.g:   返回值  1 成功  其他失败        $0 -o stop -n mynsEOF}function generateCerts(){    echo    echo "##########################################################"    echo "##### Generate certificates using cryptogen tool #########"    echo "##########################################################"     mk crypto-config     $PROJECTDIR/bin/cryptogen generate --config=./crypto-config.yaml}function generateChannelArtifacts(){    mk channel-artifacts    echo    echo "#################################################################"    echo "### Generating channel configuration transaction 'channel.tx' ###"    echo "#################################################################"    $PROJECTDIR/bin/configtxgen -profile SampleMultiNodeEtcdRaft -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block}function startNetwork() {    echo    echo "================================================="    echo "---------- Starting the network -----------------"    echo "================================================="    echo    kubectl create namespace $NAMESPACE    sleep 1    cd $PROJECTDIR/$NAMESPACE    echo    echo "===================================================="    echo "----- deploy orderer ----"    echo "===================================================="    echo    kubectl apply -f orderer-service/    sleep 2    echo    echo "===================================================="    echo "----- deploy org1 ----"    echo "===================================================="    echo    kubectl apply -f org1/    sleep 1    echo    echo "===================================================="    echo "----- deploy org2 ----"    echo "===================================================="    echo    kubectl apply -f org2/    sleep 1    echo    echo "===================================================="    echo "----- deploy org3 ----"    echo "===================================================="    echo    kubectl apply -f org3/    sleep 1    echo    echo "===================================================="    echo "----- deploy org4 ----"    echo "===================================================="    echo    kubectl apply -f org4/    sleep 1    getserviceInfoJson}function cleanNetwork() {    echo    echo "================================================="    echo "---------- Stopping the network -----------------"    echo "================================================="    echo    cd $PROJECTDIR/$NAMESPACE    if [ -d ./channel-artifacts ]; then            rm -rf ./channel-artifacts/*    fi    if [ -d ./crypto-config ]; then            rm -rf ./crypto-config    fi    kubectl delete -f orderer-service/    kubectl delete -f org1/    kubectl delete -f org2/    kubectl delete -f org3/    kubectl delete -f org4/    kubectl delete -f explorer/explorer-service/    kubectl delete namespace $NAMESPACE    rm -rf $PROJECTDIR/$NAMESPACE    # rm -rf storage}function preConfig() {    mk $PROJECTDIR/$NAMESPACE    if [ ! -d $PROJECTDIR/$NAMESPACE/chaincode ]; then        cp -r $PROJECTDIR/chaincode  $PROJECTDIR/$NAMESPACE/    fi    echo "$(ccpConfig $NAMESPACE $PROJECTDIR/template/crypto-config-temp.yaml)" > $PROJECTDIR/$NAMESPACE/crypto-config.yaml    echo "$(ccpConfig $NAMESPACE $PROJECTDIR/template/configtx-temp.yaml)" > $PROJECTDIR/$NAMESPACE/configtx.yaml    cd $PROJECTDIR/$NAMESPACE    rm -rf crypto-config    generateCerts    generateChannelArtifacts    mk storage    mk orderer-service    ordererarr=(orderer1 orderer2 orderer3)    for var in ${ordererarr[@]};    do        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "" $PROJECTDIR/template/orderer-service/orderer-deployment-temp.yaml )" > $PROJECTDIR/$NAMESPACE/orderer-service/$var-deployment.yaml        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "" $PROJECTDIR/template/orderer-service/orderer-svc-temp.yaml)" > $PROJECTDIR/$NAMESPACE/orderer-service/$var-svc.yaml        echo        echo "===================================================="        echo "----- successfully generate $var in $NAMESPACE ----"        echo "===================================================="        echo	sleep 2    done    orgarr=(org1 org2 org3 org4)    for var in ${orgarr[@]};    do        mk $var        privName=""        cryptoFolder="crypto-config/peerOrganizations/$var/ca"        for file_a in ${cryptoFolder}/*        do            temp_file=`basename $file_a`            if [ ${temp_file##*.} != "pem" ];then               privName=$temp_file            fi        done        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var $privName "" $PROJECTDIR/template/org-service/org-ca-deployment-temp.yaml )" > $PROJECTDIR/$NAMESPACE/$var/$var-ca-deployment.yaml        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "" $PROJECTDIR/template/org-service/org-ca-svc-temp.yaml)" > $PROJECTDIR/$NAMESPACE/$var/$var-ca-svc.yaml        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "${var^}MSP" $PROJECTDIR/template/org-service/org-cli-deployment-temp.yaml )" > $PROJECTDIR/$NAMESPACE/$var/$var-cli-deployment.yaml        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "${var^}MSP" $PROJECTDIR/template/org-service/org-peer-deployment-temp.yaml )" > $PROJECTDIR/$NAMESPACE/$var/peer0-$var-deployment.yaml        echo "$(ccpYaml $PROJECTDIR/$NAMESPACE $NAMESPACE $var "" "" $PROJECTDIR/template/org-service/org-peer-svc-temp.yaml)" > $PROJECTDIR/$NAMESPACE/$var/peer0-$var-svc.yaml        echo        echo "==================================================="        echo "----- successfully generate $var in $NAMESPACE -------"        echo "==================================================="        echo    done}function ccpConfig(){    sed -e "s/\${NAMESPACE}/$1/g" \          $2  | sed -e $'s/\\\\n/\\\n          /g'}function ccpYaml(){    sed  -e "s#\${PROJECTDIR}#$1#" \    -e "s/\${NAMESPACE}/$2/g" \    -e "s/\${ORGNAME}/$3/g" \    -e "s/\${PRIVKEY}/$4/g" \    -e "s/\${ORGMSP}/$5/g" \    $6 | sed -e $'s/\\\\n/\\\n          /g'}function mk(){     if [ ! -d $1 ]; then        mkdir $1    fi}function getserviceInfoJson(){     echo     echo "==================================================="     echo "----- get service info in $NAMESPACE -------"     echo "==================================================="     echo    mk $PROJECTDIR/$NAMESPACE/service-info-json    kubectl get svc -n $NAMESPACE -o json > $PROJECTDIR/$NAMESPACE/service-info-json/service-info.json}function main(){    case ${COMMAND} in        start)            preConfig            startNetwork            exit 0;        ;;        stop)            cleanNetwork            exit 0;        ;;        *)            funHelp;            exit 0;        ;;    esac}function parse_params() {    while getopts "o:n:h" option;do        case $option in        o) [ ! -z $OPTARG ] && COMMAND=$OPTARG        ;;        n) [ ! -z $OPTARG ] && NAMESPACE=$OPTARG        ;;        h)            funHelp;            exit 0;        ;;        esac    done}verifyArgparse_params $@main $@