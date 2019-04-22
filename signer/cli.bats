#!/usr/bin/env bats

: ${EMERALD_VAULT:=$HOME/.cargo/bin/emerald-vault}


# Setup and teardown are called surrounding EACH @test.
setup() {
	export EMERALD_BASE_PATH=`mktemp -d`
}

teardown() {
	rm -rf $EMERALD_BASE_PATH
    unset EMERALD_BASE_PATH
}

@test "[meta] succeeds: set env var and tmp dir EMERALD_BASE_PATH" {
    run echo "$EMERALD_BASE_PATH"
    [ "$status" -eq 0 ]
	[ -d $EMERALD_BASE_PATH ]
    [ "$output" != "" ]
}

@test "succeeds: --version" {
	run $EMERALD_VAULT --version
	[ "$status" -eq 0 ]
	[[ "$output" == *"v"* ]]
}

@test "succeeds: --help" {
    run $EMERALD_VAULT --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"emerald"* ]]
    [[ "$output" == *"Command-line"* ]]
    [[ "$output" == *"USAGE"* ]]
    [[ "$output" == *"FLAGS"* ]]
    [[ "$output" == *"OPTIONS"* ]]
    [[ "$output" == *"SUBCOMMANDS"* ]]
}

@test "succeeds: --chain=morden account new [empty options]" {
    run $EMERALD_VAULT --chain=morden account new <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]
}

@test "succeeds: --chain=etc-main new --security=high --name='Test account' --description='Some description'" {
    run $EMERALD_VAULT --chain=etc-main \
        account new \
        --security-level=high \
        --name="Test account" \
        --description="Some description" \
        <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]
}

@test "succeeds: account list" {
    run $EMERALD_VAULT --chain=morden \
        account new \
        <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]

    # FIXME I'm ugly.
    local address=$(echo "$output" | perl -lane 'print $F[-1]' | tr -d '\n')
    local removeme='!passphrase:'
    local replacewith=''
    address="${address//$removeme/$replacewith}"
    [[ "$address" != "" ]]
    [[ "$address" == *"0x"* ]]

    run $EMERALD_VAULT --chain=morden account list
    echo "$output" # prints in case fails
    echo "$address"

    [ "$status" -eq 0 ]
    [[ "$output" == *"$address"* ]]
}

@test "succeeds: account update" {
    run $EMERALD_VAULT --chain=morden account new \
        <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]

    # FIXME I'm ugly.
    local address=$(echo "$output" | perl -lane 'print $F[-1]' | tr -d '\n')
    local removeme='!passphrase:'
    local replacewith=''
    address="${address//$removeme/$replacewith}"
    [[ "$address" != "" ]]
    [[ "$address" == *"0x"* ]]

    run $EMERALD_VAULT --chain=morden account update \
        "$address" \
        --name="new name" \
        --description="new description"
    [ "$status" -eq 0 ]

    run $EMERALD_VAULT --chain=morden account list

    [ "$status" -eq 0 ]
    [[ "$output" == *"new name"* ]]
}

@test "succeeds: account strip" {
    run $EMERALD_VAULT --chain=morden account new \
        <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]

    # FIXME I'm ugly.
    local address=$(echo "$output" | perl -lane 'print $F[-1]' | tr -d '\n')
    local removeme='!passphrase:'
    local replacewith=''
    address="${address//$removeme/$replacewith}"
    [[ "$address" != "" ]]
    [[ "$address" == *"0x"* ]]

    run $EMERALD_VAULT --chain=morden account strip \
        "$address" \
        <<< $'foo\n'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Private key: 0x"* ]]
}

@test "succeeds: account hide && unhide" {
    run $EMERALD_VAULT --chain=morden account new \
        <<< $'foo\n'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created new account"* ]]

    # FIXME I'm ugly.
    local address=$(echo "$output" | perl -lane 'print $F[-1]' | tr -d '\n')
    local removeme='!passphrase:'
    local replacewith=''
    address="${address//$removeme/$replacewith}"
    [[ "$address" != "" ]]
    [[ "$address" == *"0x"* ]]

    # Hide account.
    run $EMERALD_VAULT --chain=morden account hide \
        "$address"
    [ "$status" -eq 0 ]

    # Ensure is hidden; doesn't show up in list.
    run $EMERALD_VAULT --chain=morden account list \

    [ "$status" -eq 0 ]
    [[ "$output" != *"$address"* ]]

    # Unhide account.
    run $EMERALD_VAULT --chain=morden account unhide \
        "$address"

    # Ensure is not hidden; shows up in list.
    run $EMERALD_VAULT --chain=morden account list

    [ "$status" -eq 0 ]
    [[ "$output" == *"$address"* ]]
}
