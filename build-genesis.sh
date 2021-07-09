#!/bin/bash

DENOM=ustarx
CHAIN_ID=cygnusx-1
ONE_HOUR=3600
ONE_DAY=$(($ONE_HOUR * 24))
ONE_YEAR=$(($ONE_DAY * 365))
VALIDATOR_COINS=1000000000000$DENOM

if [ "$1" == "mainnet" ]
then
    LOCKUP=ONE_YEAR
else
    LOCKUP=ONE_DAY
fi
echo "Lockup period is $LOCKUP"

rm -rf ~/.starsd

echo "Processing airdrop snapshot..."
if ! [ -f genesis.json ]; then
    curl -O https://archive.interchain.io/4.0.2/genesis.json
fi
starsd export-airdrop-snapshot uatom genesis.json snapshot.json
starsd init testmoniker --chain-id $CHAIN_ID
starsd prepare-genesis testnet $CHAIN_ID
starsd import-genesis-accounts-from-snapshot snapshot.json

echo "Adding vesting accounts..."
GENESIS_TIME=$(jq '.genesis_time' ~/.starsd/config/genesis.json | tr -d '"')
echo "Genesis time is $GENESIS_TIME"
if [[ "$OSTYPE" == "darwin"* ]]; then
    GENESIS_UNIX_TIME=$(TZ=UTC gdate "+%s" -d $GENESIS_TIME)
else
    GENESIS_UNIX_TIME=$(TZ=UTC date "+%s" -d $GENESIS_TIME)
fi
vesting_start_time=$(($GENESIS_UNIX_TIME + $LOCKUP))
vesting_end_time=$(($vesting_start_time + $LOCKUP))

starsd add-genesis-account stars1s4ckh9405q0a3jhkwx9wkf9hsjh66nmuu53dwe 350000000000000$DENOM
starsd add-genesis-account stars13nh557xzyfdm6csyp0xslu939l753sdlgdc2q0 250000000000000$DENOM
starsd add-genesis-account stars12yxedm78tpptyhhasxrytyfyj7rg7dcqfgrdk4 16666666666667$DENOM \
    --vesting-amount 16666666666667$DENOM \
    --vesting-start-time $vesting_start_time \
    --vesting-end-time $vesting_end_time
starsd add-genesis-account stars1nek5njjd7uqn5zwf5zyl3xhejvd36er3qzp6x3 16666666666667$DENOM \
    --vesting-amount 16666666666667$DENOM \
    --vesting-start-time $vesting_start_time \
    --vesting-end-time $vesting_end_time
starsd add-genesis-account stars1avlcqcn4hsxrds2dgxmgrj244hu630kfl89vrt 16666666666667$DENOM \
    --vesting-amount 16666666666667$DENOM \
    --vesting-start-time $vesting_start_time \
    --vesting-end-time $vesting_end_time
starsd add-genesis-account stars1wppujuuqrv52atyg8uw3x779r8w72ehrr5a4yx 50000000000000$DENOM \
    --vesting-amount 50000000000000$DENOM \
    --vesting-start-time $vesting_start_time \
    --vesting-end-time $vesting_end_time

# echo "Processing validators..."
# mkdir -p ~/.starsd/config/gentx
# # for i in $NETWORK/gentx/*.json; do
# for i in bellatrix-1/gentx/*.json; do
#     echo $i
#     starsd add-genesis-account $(jq -r '.body.messages[0].delegator_address' $i) $VALIDATOR_COINS \
#         --vesting-amount $VALIDATOR_COINS \
#         --vesting-start-time $vesting_start_time \
#         --vesting-end-time $vesting_end_time
#     cp $i ~/.starsd/config/gentx/
# done
# starsd collect-gentxs

yes | starsd keys add validator --keyring-backend test
starsd add-genesis-account $(starsd keys show validator -a --keyring-backend test) 10000000000000000$DENOM
starsd gentx validator 10000000000$DENOM --chain-id $CHAIN_ID --keyring-backend test
starsd collect-gentxs

starsd validate-genesis

cp ~/.starsd/config/genesis.json $CHAIN_ID
