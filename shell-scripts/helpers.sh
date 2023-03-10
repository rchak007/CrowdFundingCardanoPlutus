#!/usr/bin/env bash
set -e
set -o pipefail

. "$(dirname $0)"/env # soure env variables


function getInputTx() {
	#echo "inHelpers - getInputtx"
	BALANCE_FILE=$BASE/tx/walletBalances.txt

#   Allows removing root-owned files and directories. rm - Linux command for removing files or directories. 
#   -r - The option indicates recursive removal and helps remove non-empty directories. 
#   -f - The option allows removal without confirmation, even if a file does not exist.
	rm -f $BALANCE_FILE
	if [ -z "$1" ]
	     # [ -z STRING ]	True of the length if "STRING" is zero.
	     # $1 - The first argument sent to the script. $2 - The second argument sent to the script. 
	     # $3 - The third argument... and so forth. 
	then
		read -p 'Wallet Name: ' SELECTED_WALLET_NAME
	else
		echo 'Wallet Name: ' $1
		SELECTED_WALLET_NAME=$1
	fi
	#echo "after if in helper"
	./balance.sh $SELECTED_WALLET_NAME > $BALANCE_FILE
	#echo "after balance call in helper"
	SELECTED_WALLET_ADDR=$(cat $BASE/.priv/Wallets/$SELECTED_WALLET_NAME/$SELECTED_WALLET_NAME.addr)
	cat $BALANCE_FILE
	read -p 'TX row number starting in 1: ' TMP
	TX_ROW_NUM="$(($TMP+2))"
    echo "TX_ROW_NUM= ${TX_ROW_NUM}"
	# https://www.geeksforgeeks.org/sed-command-in-linux-unix-with-examples/
	# i think it just shows that whole like - the UTXO with lovelace and tokens.
	TX_ROW=$(sed "${TX_ROW_NUM}q;d" $BALANCE_FILE)
    echo "TX_ROW= ${TX_ROW}"
	# https://www.geeksforgeeks.org/awk-command-unixlinux-examples/

	SELECTED_UTXO="$(echo $TX_ROW | awk '{ print $1 }')#$(echo $TX_ROW | awk '{ print $2 }')"
	SELECTED_UTXO_LOVELACE=$(echo $TX_ROW | awk '{ print $3 }')
	SELECTED_UTXO_TOKENS=$(echo $TX_ROW | awk '{ print $6 }')
	#SELECTED_UTXO_POLICYID=$(echo $TX_ROW | awk '{ print $7 }')
	SELECTED_UTXO_POLICYID=$(echo $TX_ROW | awk '{ print $7 }' | awk -F '.' '{print $1}')
    SELECTED_UTXO_TOKEN_NAME_HEX=$(echo $TX_ROW | awk '{ print $7 }' | awk -F '.' '{print $2}')
}

walletAddress() {
	WALLET_ADDRESS=$(cat $BASE/.priv/Wallets/$1/$1.payment.addr)
}

setDatumHash() {
	DATUM_HASH=$(cardano-cli transaction hash-script-data --script-data-value $DATUM_VALUE)
	#return $(cardano-cli transaction hash-script-data --script-data-value $1)
}

getScriptAddress() {
	SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $BASE/plutus-scripts/${SCRIPT_NAME}.plutus --testnet-magic $TESTNET_MAGIC)
        mkdir -p $BASE/.priv/Wallets/${SCRIPT_NAME}
        echo $SCRIPT_ADDRESS > $BASE/.priv/Wallets/${SCRIPT_NAME}/${SCRIPT_NAME}.addr
}

function section {
  echo "============================================================================================"
  echo $1
  echo "============================================================================================"
}

function removeTxFiles() {
  rm -f tx.raw
  rm -f tx.signed
}
